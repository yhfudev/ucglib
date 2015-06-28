/**
 * @file    fontutf8.cpp
 * @brief   font api test for ucg lib
 * @author  Yunhui Fu (yhfudev@gmail.com)
 * @version 1.0
 * @date    2015-04-19
 * @copyright GPL
 */
#define USE_SDL 0
#if defined(ARDUINO)

#if ARDUINO >= 100
#include <Arduino.h>
#else
#include <WProgram.h>
#endif

#elif defined(UCG_RASPBERRY_PI)
#include <unistd.h>
//#define delay(a) usleep((a) * 1000)

#else
#undef USE_SDL
#define USE_SDL 0
#define delay(a) SDL_Delay((a)*1000)
#endif

//#include <Ucglib.h>
#include "Ucglib.h"

#include "fontutf8-data.h"

#if defined(ARDUINO) || defined(UCG_RASPBERRY_PI)

#if 0
#define OLED_MOSI   9 // SDA
#define OLED_CLK   10 // SCL
#define OLED_DC    11 // D/C (data or command)
#define OLED_CS    12 // no such pin
#define OLED_RESET 13 // RST
#else
#define OLED_MOSI   4 // SDA
#define OLED_CLK    5 // SCL
#define OLED_DC     2 // D/C (data or command)
#define OLED_CS    12 // no such pin
#define OLED_RESET  3 // RST
#endif

// SW SPI Com: SCK = 10, MOSI = 9, CS = 12, A0 = 11, reset=13
#define UCGVAL_SCK   OLED_CLK
#define UCGVAL_MOSI  OLED_MOSI
#define UCGVAL_CS    OLED_CS
#define UCGVAL_A0    OLED_DC
#define UCGVAL_RESET OLED_RESET
//Ucglib_SSD1331_18x96x64_UNIVISION_SWSPI ucg(UCGVAL_SCK, UCGVAL_MOSI, UCGVAL_CS, UCGVAL_A0, UCGVAL_RESET);
Ucglib_SSD1331_18x96x64_UNIVISION_SWSPI ucg(/*sclk=*/ 13, /*data=*/ 11, /*cd=*/ 9 , /*cs=*/ 10, /*reset=*/ 8);

#else
// SDL
Ucglib ucg(&ucg_sdl_dev_cb);
#endif

void ucg_prepare(void) {
  ucg.setFont(UCG_DEFAULT_FONT);
  ucg.setFontRefHeightExtendedText();
  //ucg.setDefaultForegroundColor();
  ucg.setFontPosTop();
}

void setup(void) {
#if 0
  Serial.begin(9600);
  pinMode(13, OUTPUT);
  digitalWrite(13, HIGH);
#endif
  ucg.begin(UCG_FONT_MODE_TRANSPARENT);
  ucg.setFont(ucg_font_ncenR14_hr);
  ucg.clearScreen();
  ucg_SetUtf8Fonts (g_fontinfo, NUM_ARRAY(g_fontinfo));
}

void ucg_chinese() {
  char s1[] = _UCGT("黄沙百戰穿金甲，");
  char s2[] = _UCGT("不破樓蘭終不還。");
  char buf[20] = _UCGT("Chinese Glyph");
  sprintf (buf, "u32=%d,w=%d,s=%d",sizeof(uint32_t),sizeof(wchar_t),sizeof(size_t));
  //sprintf (buf, "i=%d,l=%d,u=%d",sizeof(int),sizeof(long),sizeof(unsigned));
  ucg.drawUtf8String (0, 11, 0, buf);
  ucg.drawUtf8String (5, 30, 0, s1);
  ucg.drawUtf8String (5, 48, 0, s2);
}

void draw(void) {
  ucg_prepare();
  ucg_chinese();
}

// calculate new output values
void uiStep(void) {
#if USE_SDL
    int key = ucg_sdl_get_key();
    switch (key) {
    case 'q':
    case ' ':
        exit(0);
    }
#endif
}

void loop(void) {
  // picture loop
  //ucg.firstPage();
  //do {
    draw();
    //delay(500);
  //} while( ucg.nextPage() );
  uiStep();
  // rebuild the picture after some delay
  delay(500);

}

#if 0 // #if ! defined(ARDUINO)
int
main(void)
{
  setup();
  while (1) {
    loop();
  }
  return 0;
}

#endif

