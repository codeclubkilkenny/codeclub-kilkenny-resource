// ============================================================
// Live Sensor Web Page
// Arduino UNO R4 WiFi + Modulino Thermo
// The Arduino hosts a web page on your WiFi showing live
// temperature and humidity from the Thermo module.
// Open a browser on the same WiFi, type in the IP address
// shown in the Serial Monitor, and see the live readings.
// ============================================================

#include <WiFiS3.h>     // The WiFi library — built into the UNO R4 board package
#include <Modulino.h>   // The Modulino library for all sensor modules

// ---- Enter your details here ----
const char ssid[]    = "YOUR_WIFI_NAME";       // Replace with your WiFi network name
const char pass[]    = "YOUR_WIFI_PASSWORD";   // Replace with your WiFi password
const char station[] = "YOUR_STATION_NAME";    // Replace with your weather station name

ModulinoThermo thermo;   // Creates a thermo object so we can talk to the sensor
WiFiServer server(80);   // Creates a web server listening on port 80
                         // Port 80 is the standard port for web pages (HTTP)

// ============================================================
// setup() runs once when the Arduino is switched on
// ============================================================
void setup() {
  Serial.begin(9600);    // Start Serial Monitor — used to show the IP address
  Modulino.begin();      // Start the Modulino system so sensors can be used
  thermo.begin();        // Wake up the Thermo sensor

  // Connect to WiFi
  Serial.print("Connecting to WiFi");
  WiFi.setHostname(station);  // Give this board a name on the network
  WiFi.begin(ssid, pass);     // Tell the Arduino to connect using our details

  // Keep looping here until the WiFi connects
  // WiFi.status() checks the connection — WL_CONNECTED means success
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");    // Print a dot each attempt so we can see progress
  }

  Serial.println("");
  Serial.println("WiFi connected!");

  // Wait until the board has been assigned a real IP address
  // 0.0.0.0 means the router has not given us an address yet
  while (WiFi.localIP() == IPAddress(0, 0, 0, 0)) {
    delay(500);
    Serial.print(".");
  }

  Serial.println("");
  Serial.print("Open your browser and go to:  http://");
  Serial.println(WiFi.localIP());  // This is the address to type in your browser

  server.begin();  // Start the web server — ready to receive browser requests
}

// ============================================================
// loop() runs over and over forever
// It checks if a browser has connected and sends back a page
// ============================================================
void loop() {

  // Check if a browser has connected
  // server.available() returns a client if someone connected, otherwise nothing
  WiFiClient client = server.available();

  if (client) {   // A browser has connected — time to send it a web page

    // Read and discard the browser's request
    // Every browser sends a block of text asking for the page
    // We do not need to read it — we always send the same page back
    String request = "";
    while (client.connected()) {
      if (client.available()) {
        char c = client.read();
        request += c;
        if (request.endsWith("\r\n\r\n")) break;  // Blank line = end of request
      }
    }

    // Read fresh sensor values right now
    float temperature = thermo.getTemperature();  // Degrees Celsius
    float humidity    = thermo.getHumidity();     // Percentage 0-100

    // ---- HTTP response header ----
    // This must be sent before any HTML
    // It tells the browser what kind of content is coming
    client.println("HTTP/1.1 200 OK");         // 200 OK means the request worked
    client.println("Content-Type: text/html"); // Tells browser to expect HTML
    client.println("Connection: close");       // Close connection after sending
    client.println();                          // Blank line = end of headers

    // ---- HTML page starts here ----
    // HTML is the language all web pages are written in
    // Every tag that opens must be closed — <h1> opens, </h1> closes
    client.println("<!DOCTYPE html>");         // Tells the browser this is HTML5
    client.println("<html><head>");            // Start of the page, then the head section
                                               // The head contains settings — not visible content

    // The viewport tag makes the page fit correctly on phones and tablets
    // Without it, mobile browsers zoom out and everything looks tiny
    client.println("<meta name='viewport' content='width=device-width, initial-scale=1'>");

    // The title appears in the browser tab at the top of the screen
    // We use the station name variable so it updates automatically
    client.print("<title>");
    client.print(station);
    client.println("</title>");

    // Meta refresh tells the browser to reload the page every 5 seconds
    // This is how the readings stay live — the page keeps fetching new data
    // Change the number 5 to reload faster or slower
    client.println("<meta http-equiv='refresh' content='5'>");

    // ---- CSS styles ----
    // CSS controls how everything looks — colours, sizes, spacing
    // Styles are written between <style> and </style> tags in the head
    client.println("<style>");

    // body — styles the whole page
    // font-family: the font to use
    // background: the page background colour (#f5f5f5 is light grey)
    // text-align: center puts everything in the middle
    // padding: adds space around the edges so content is not right against the screen
    client.println("body { font-family: Arial, sans-serif; background: #f5f5f5;");
    client.println("       text-align: center; padding: 40px; color: #1C2833; }");

    // h1 — styles the main heading
    // #005C5F is a dark teal colour
    client.println("h1 { color: #005C5F; }");

    // .box — styles each reading card
    // A class name starting with . applies to any element with that class
    // border-radius rounds the corners
    // border adds the teal outline
    // max-width stops the box getting too wide on large screens
    client.println(".box { background: white; border-radius: 12px;");
    client.println("       border: 2px solid #00979D; padding: 24px;");
    client.println("       margin: 20px auto; max-width: 340px; }");

    // .val — styles the big number inside each box
    // font-size: 3em means 3 times the normal text size
    client.println(".val { font-size: 3em; color: #00979D; font-weight: bold; }");

    // .lbl — styles the small label below each number (Temperature, Humidity)
    client.println(".lbl { font-size: 1em; color: #888; margin-top: 6px; }");

    // .note — styles the small grey text at the bottom
    client.println(".note { font-size: 0.8em; color: #aaa; margin-top: 28px; }");

    client.println("</style>");    // End of CSS styles
    client.println("</head>");     // End of the head section
    client.println("<body>");      // Start of the body — this is the visible page content

    // The main heading — uses the station name variable
    client.print("<h1>");
    client.print(station);
    client.println("</h1>");

    // ---- Temperature card ----
    // <div class='box'> creates a box using the .box style we defined above
    client.println("<div class='box'>");
    // <div class='val'> makes the number big and teal
    client.print("  <div class='val'>");
    client.print(temperature, 1);             // Print temperature to 1 decimal place
    client.println(" &deg;C</div>");           // &deg; is the HTML code for the degree symbol °
    // <div class='lbl'> adds the small label underneath
    client.println("  <div class='lbl'>Temperature</div>");
    client.println("</div>");                  // Close the box div

    // ---- Humidity card ----
    // Same structure as the temperature card
    client.println("<div class='box'>");
    client.print("  <div class='val'>");
    client.print(humidity, 1);                // Print humidity to 1 decimal place
    client.println(" %</div>");               // % is the unit for humidity
    client.println("  <div class='lbl'>Humidity</div>");
    client.println("</div>");

    // ---- Footer notes ----
    // <p> is a paragraph tag — used for small blocks of text
    client.println("<p class='note'>Updates every 5 seconds</p>");

    // Show the IP address on the page so you can find it again easily
    client.println("<p class='note'>");
    client.println(WiFi.localIP());
    client.println("</p>");

    client.println("</body></html>");  // Close the body and html tags — page is complete

    client.stop();  // Disconnect — the browser will reconnect automatically on the next refresh
  }
}