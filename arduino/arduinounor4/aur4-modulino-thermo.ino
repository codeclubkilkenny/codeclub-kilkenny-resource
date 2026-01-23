#include "Modulino.h"                 // Gives us easy control of all Modulino sensors
#include "ArduinoGraphics.h"          // Lets us draw text and shapes
#include "Arduino_LED_Matrix.h"       // Controls the little LED screen on the Arduino

ModulinoThermo thermo;                // Create the temperature sensor
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
  thermo.begin();                     // Turn on the temperature sensor
}
void loop() {
  float t = thermo.getTemperature();  // Read the temperature in degrees Celsius

  char msg[16];                       // Make a space to store the message
  snprintf(msg, sizeof(msg), "%.1fC ", t); // Turn the number into text like 21.4C

  showScroll(msg);                    // Show the temperature on the screen
  delay(250);                         // Wait a short time before updating again
}
