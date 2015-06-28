#!/bin/bash
#####################################################################
# genucgpages.sh for ucg
#
# This script will generate ucg c files for specified fonts
#
# Copyright 2015 Yunhui Fu
# License: GPL/BSD
#####################################################################
my_getpath () {
  PARAM_DN="$1"
  shift
  #readlink -f
  DN="${PARAM_DN}"
  FN=
  if [ ! -d "${DN}" ]; then
    FN=$(basename "${DN}")
    DN=$(dirname "${DN}")
  fi
  cd "${DN}" > /dev/null 2>&1
  DN=$(pwd)
  cd - > /dev/null 2>&1
  echo "${DN}/${FN}"
}
#DN_EXEC=`echo "$0" | ${EXEC_AWK} -F/ '{b=$1; for (i=2; i < NF; i ++) {b=b "/" $(i)}; print b}'`
DN_EXEC=$(dirname $(my_getpath "$0") )
if [ ! "${DN_EXEC}" = "" ]; then
    DN_EXEC="$(my_getpath "${DN_EXEC}")/"
else
    DN_EXEC="${DN_EXEC}/"
fi
#####################################################################
EXEC_GENUCGPAGES=${DN_EXEC}/genucgpages
if [ ! -x "${EXEC_GENUCGPAGES}" ]; then
    EXEC_GENUCGPAGES="$(my_getpath ${DN_EXEC}/../../../genucgpages)"
fi
if [ ! -x "${EXEC_GENUCGPAGES}" ]; then
    echo "Error: not found genucgpages!"
    exit 1
fi
echo "EXEC_GENUCGPAGES=${EXEC_GENUCGPAGES}"

EXEC_BDF2UCG=${DN_EXEC}/bdf2ucg
if [ ! -x "${EXEC_BDF2UCG}" ]; then
    EXEC_BDF2UCG="$(my_getpath ${DN_EXEC}/../../../bdf2ucg)"
fi
if [ ! -x "${EXEC_BDF2UCG}" ]; then
    EXEC_BDF2UCG=$(which bdf2ucg)
fi
if [ ! -x "${EXEC_BDF2UCG}" ]; then
    echo "Error: not found bdf2ucg!"
    exit 1
fi

#####################################################################
FN_FONT_BASE=unifont
#FN_FONT_BASE=wenquanyi_12pt
FN_FONT=${DN_EXEC}/${FN_FONT_BASE}.bdf
if [ ! -f "${FN_FONT}" ]; then
    if [ -f "/usr/share/fonts/wenquanyi/${FN_FONT_BASE}.bdf" ]; then
        FN_FONT="/usr/share/fonts/wenquanyi/${FN_FONT_BASE}.bdf"
    else if [ -f "/usr/share/fonts/wenquanyi/${FN_FONT_BASE}.pcf" ]; then
        EXEC_PCF2BDF=$(which pcf2bdf)
        if [ ! -x "${EXEC_PCF2BDF}" ]; then
            echo "Error: not found pcf2bdf!"
            exit 1
        fi
        ${EXEC_PCF2BDF} -o "${FN_FONT}" "/usr/share/fonts/wenquanyi/${FN_FONT_BASE}.pcf"
    fi fi
fi
if [ ! -f "${FN_FONT}" ]; then
    if [ -f "/usr/share/fonts/misc/${FN_FONT_BASE}.bdf" ]; then
        FN_FONT="/usr/share/fonts/misc/${FN_FONT_BASE}.bdf"
    else if [ -f "/usr/share/fonts/misc/${FN_FONT_BASE}.pcf" ]; then
        EXEC_PCF2BDF=$(which pcf2bdf)
        if [ ! -x "${EXEC_PCF2BDF}" ]; then
            echo "Error: not found pcf2bdf!"
            exit 1
        fi
        ${EXEC_PCF2BDF} -o "${FN_FONT}" "/usr/share/fonts/misc/${FN_FONT_BASE}.pcf"
    fi fi
fi
if [ ! -f "${FN_FONT}" ]; then
    echo "Error: not found font ${FN_FONT}!"
    exit 1
fi

#####################################################################

DN_CUR=$(pwd)

#(cd ${DN_EXEC}; gcc -o genucgpages genucgpages.c getline.c)

rm tmpa tmpb
#rm -f ${DN_EXEC}/fontpage_*.h
rm -f fontpage_*.h

cat << EOF > tmp-proc-page.awk
BEGIN {
    cur_page=0;
    val_begin=0;
    val_pre=0;
}{
    page=\$1;
    val_real=\$2;
    # assert (val_real < 128);
    val=val_real + 128;
    if (cur_page != page) {
        if (cur_page != 0) {
            if (val_begin != 0) {
                print cur_page " " val_begin " " val_pre;
            }
        }
        cur_page=page;
        val_begin=val;
        val_pre=val;
    } else {
        if (val_pre + 1 != val) {
            if (cur_page != 0) {
                print cur_page " " val_begin " " val_pre;
            }
            val_begin=val;
            val_pre=val;
        } else {
            val_pre = val;
        }
    }
} END {
    if (cur_page != 0) {
        print cur_page " " val_begin " " val_pre;
    }
}
EOF

grep -Hrn _UCGT . | grep -v "#define" | grep '"' | \
  sed 's/^.*_UCGT([ \w\t]*"\([^)]*\)"[ \w\t]*).*$/\1/' | \
  ${EXEC_GENUCGPAGES} | \
  sort -k 1n -k 2n | uniq | \
  gawk -v EXEC_PREFIX=${DN_EXEC} -f tmp-proc-page.awk | \
  while read PAGE BEGIN END; do \
    if [ ! -f ${DN_EXEC}/fontpage_${PAGE}_${BEGIN}_${END}.h ]; then \
      ${EXEC_BDF2UCG} -u ${PAGE} -b ${BEGIN} -e ${END} ${FN_FONT} fontpage_${PAGE}_${BEGIN}_${END} ${DN_EXEC}/fontpage_${PAGE}_${BEGIN}_${END}.h > /dev/null 2>&1 ;
      #sed -i 's|#include "ucg.h"|#include "utility/ucg.h"|' ${DN_EXEC}/fontpage_${PAGE}_${BEGIN}_${END}.h ;
    fi ;\
    grep -A 10000000000 ucg_fntpgm_uint8_t ${DN_EXEC}/fontpage_${PAGE}_${BEGIN}_${END}.h >> tmpa ;\
    echo "    FONTDATA_ITEM(${PAGE}, ${BEGIN}, ${END}, fontpage_${PAGE}_${BEGIN}_${END})," >> tmpb ;\
  done

rm -f fontutf8-data.h
echo "#include <ucg.h>" >> fontutf8-data.h
#echo "#include \"fontutf8ucg.h\"" >> fontutf8-data.h
echo "" >> fontutf8-data.h
cat tmpa >> fontutf8-data.h
echo "" >> fontutf8-data.h
echo "#define FONTDATA_ITEM(page, begin, end, data) {page, begin, end, NUM_ARRAY(data), data}" >> fontutf8-data.h
echo "ucg_fontinfo_t g_fontinfo[] = {" >> fontutf8-data.h
cat tmpb >> fontutf8-data.h
echo "};" >> fontutf8-data.h

rm -f tmpa tmpb tmp-proc-page.awk
