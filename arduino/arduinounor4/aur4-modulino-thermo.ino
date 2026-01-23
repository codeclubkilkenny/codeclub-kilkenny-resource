#include "Modulino.h"
#include "ArduinoGraphics.h"
#include "Arduino_LED_Matrix.h"

ModulinoThermo thermo;
ArduinoLEDMatrix matrix;

void showScroll(const char* msg) {
  matrix.beginDraw();
  matrix.stroke(0xFFFFFFFF);
  matrix.textFont(Font_5x7);
  matrix.textScrollSpeed(70);
  matrix.beginText(0, 1, 0xFFFFFF);
  matrix.println(msg);
  matrix.endText(SCROLL_LEFT);
  matrix.endDraw();
}

void setup() {
  matrix.begin();
  Modulino.begin();
  thermo.begin();
}

void loop() {
  float t = thermo.getTemperature();
  char msg[16];
  snprintf(msg, sizeof(msg), "%.1fC ", t);
  showScroll(msg);
  delay(250);
}
