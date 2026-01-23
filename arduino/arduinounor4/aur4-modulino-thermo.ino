#include "Modulino.h"                 // Gives us easy control of Modulino sensors
#include "ArduinoGraphics.h"          // Lets us draw text like words and numbers
#include "Arduino_LED_Matrix.h"       // Controls the tiny LED screen on the Arduino

ModulinoThermo thermo;                // Create the temperature + humidity sensor
ArduinoLEDMatrix matrix;              // Create the LED matrix screen

void showScroll(const char* msg) {    // This function shows scrolling text on the screen
  matrix.beginDraw();                 // Start drawing on the LED screen
  matrix.stroke(0xFFFFFFFF);          // Turn LEDs on in white
  matrix.textFont(Font_5x7);          // Choose a simple readable font
  matrix.textScrollSpeed(70);         // Set how fast the text moves
  matrix.beginText(0, 1, 0xFFFFFF);   // Start writing text at this position
  matrix.println(msg);                // Write the message
  matrix.endText(SCROLL_LEFT);        // Make the text scroll to the left
  matrix.endDraw();                   // Show everything on the screen
}
void setup() {
  matrix.begin();                     // Turn on the LED matrix
  Modulino.begin();                   // Turn on the Modulino system
  thermo.begin();                     // Turn on the Thermo sensor
}
void loop() {
  float t = thermo.getTemperature();  // Read the temperature in degrees Celsius
  float h = thermo.getHumidity();     // Read the humidity as a percentage

  char msg[20];                       // Make space to store text

  snprintf(msg, sizeof(msg), "TEMP %.1fC ", t); // Turn temperature into text
  showScroll(msg);                    // Show temperature on the screen
  delay(1500);                        // Wait so kids can read it

  snprintf(msg, sizeof(msg), "HUM %.0f%% ", h); // Turn humidity into text
  showScroll(msg);                    // Show humidity on the screen
  delay(1500);                        // Wait again before looping
}
