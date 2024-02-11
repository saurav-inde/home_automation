#include <ESP8266WiFi.h>
#include <WiFiClient.h>
#include <ESP8266WebServer.h>
#include <ArduinoJson.h>
#include <string>

#ifndef APSSID
#define APSSID "ESP32_ACP"
#define APPSK "ece@123ece"
#endif

/* Declare the pins for the leds and their status var */
int ledPins[] = { D8, D7, D6, D5, D4, D4, D3, D2 };
bool ledOn = false;


/* Set these to your desired credentials. */
const char *ssid = APSSID;
const char *password = APPSK;

ESP8266WebServer server(80);

/* Just a little test message.  Go to http://192.168.4.1 in a web browser
   connected to this access point to see it.
*/
void handleRoot() {
  server.send(200, "text/html", "<h1>You are connected</h1>");
}


/*
  Function to control the led status
  Turns on and off all the leds as of now whenever /led point is hit
*/

// Toggle LED handler
#include <ArduinoJson.h>  // Include the ArduinoJson library

void toggleLed() {
  StaticJsonDocument<200> jsonDoc;  // Adjust the size according to your needs

  if (!ledOn) {
    for (auto led : ledPins) {
      digitalWrite(led, HIGH);
    }
  } else {
    for (auto led : ledPins) {
      digitalWrite(led, LOW);
    }
  }
  ledOn = !ledOn;  // Toggle the LED state

  // Build the JSON response
  jsonDoc["status"] = "success";
  jsonDoc["message"] = "LED state toggled";
  jsonDoc["ledStatus"] = ledOn ? true : false;

  // Convert the JSON document to a string
  String jsonResponse;
  serializeJson(jsonDoc, jsonResponse);

  // Send the JSON response
  server.send(200, "application/json", jsonResponse);
}

/* 
  Change the leds that are on and off to show the binary num
  */

void changeLedsBool() {
  String requestBody = server.arg("plain");
  DynamicJsonDocument jsonDoc(200);

  deserializeJson(jsonDoc, requestBody);
  Serial.println("String got: " + String(jsonDoc["variable"]));
  
  // int variableNumber = jsonDoc["variable"];

  // Serial.println("Number got: " + String(variableNumber));
  
  // for (short i = 0; i < 8; i++) {
  //   auto m = variableNumber % 2;
  //   variableNumber /= 2;

  //   Serial.println(m);

  //   if (m == 1) {
  //     digitalWrite(ledPins[i], HIGH);
  //   } else {
  //     digitalWrite(ledPins[i], LOW);
  //   }
  // }

  // Build the JSON response
  jsonDoc["status"] = "success";

  // Convert the JSON document to a string
  String jsonResponse;
  serializeJson(jsonDoc, jsonResponse);

  // Send the JSON response
  server.send(200, "application/json", jsonResponse);
}

/*
  Setup function to initialize the initial state 
*/
void setup() {
  // LED pin mode setup and initialization to LOW
  for (auto pin : ledPins) {
    pinMode(pin, OUTPUT);
    digitalWrite(pin, LOW);
  }


  delay(1000);
  Serial.begin(115200);
  Serial.println();
  Serial.print("Configuring access point...");
  /* You can remove the password parameter if you want the AP to be open. */
  WiFi.softAP(ssid, password);

  IPAddress myIP = WiFi.softAPIP();
  Serial.print("AP IP address: ");
  server.on("/", handleRoot);
  server.on("/led", toggleLed);
  server.on("/var", changeLedsBool);
  server.begin();
  Serial.println("HTTP server started");
}

void loop() {
  server.handleClient();
}