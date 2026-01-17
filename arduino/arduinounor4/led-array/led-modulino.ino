#include <Modulino.h>

// “LED Array” in the Plug and Make kit = Modulino Pixels (8 RGB LEDs)
ModulinoPixels leds;

const int BRIGHTNESS = 10; // % (they’re bright)

void setup() {
  Serial.begin(115200);

  // Start the Modulino I2C system, then the Pixels module
  Modulino.begin();
  leds.begin();

  // Clear everything once at boot
  leds.clear();
  leds.show();
}

void loop() {
  // A few built-in colours from the library
  const ModulinoColor colors[] = { RED, GREEN, BLUE, VIOLET, WHITE };
  const int nColors = sizeof(colors) / sizeof(colors[0]);

  for (int c = 0; c < nColors; c++) {
    // “Knight Rider” scan left -> right
    for (int i = 0; i < 8; i++) {
      leds.clear();
      leds.set(i, colors[c], BRIGHTNESS);
      leds.show();
      delay(120);
    }

    // …and back right -> left
    for (int i = 6; i >= 1; i--) {
      leds.clear();
      leds.set(i, colors[c], BRIGHTNESS);
      leds.show();
      delay(120);
    }
  }
}

