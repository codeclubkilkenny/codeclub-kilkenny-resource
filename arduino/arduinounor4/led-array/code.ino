// LED Array – simple chase pattern
// Adjust the pins to match how your LED array is wired

int leds[] = {2, 3, 4, 5, 6, 7, 8, 9};
int ledCount = 8;

void setup() {
  // Set all LED pins as outputs
  for (int i = 0; i < ledCount; i++) {
    pinMode(leds[i], OUTPUT);
  }
}

void loop() {
  // Turn LEDs on one by one
  for (int i = 0; i < ledCount; i++) {
    digitalWrite(leds[i], HIGH);
    delay(200);
    digitalWrite(leds[i], LOW);
  }

  // And back the other way
  for (int i = ledCount - 1; i >= 0; i--) {
    digitalWrite(leds[i], HIGH);
    delay(200);
    digitalWrite(leds[i], LOW);
  }
}
