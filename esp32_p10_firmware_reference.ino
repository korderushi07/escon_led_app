/*
 * ESCON Electronics & Electricals
 * ESP32 P10 LED Controller (64 x 16, 2 panels)
 *
 * Flutter App <--Wi-Fi--> ESP32 <--> P10
 *
 * API:
 *   GET  /api/v1/status
 *   GET  /api/v1/prices
 *   POST /api/v1/prices   {"petrol":"104.50","diesel":"92.30"}
 *
 * Display scanning runs in a FreeRTOS task (not a hardware-timer ISR),
 * so Wi-Fi start-up and NVS/flash writes cannot crash the board.
 * Wi-Fi is started BEFORE the display scan task.
 *
 * Works on ESP32 Arduino core 2.x and 3.x.
 */

#include <Arduino.h>
#include <WiFi.h>
#include <WebServer.h>
#include <Preferences.h>
#include <ArduinoJson.h>
#include <ESPmDNS.h>

#include <DMD32.h>
#include "fonts/Arial_black_16.h"   // use "Arial_black_16.h" if your library keeps it in the root


// ============================================================
// P10 CONFIGURATION (64 x 16)
// ============================================================

#define DISPLAYS_ACROSS 2
#define DISPLAYS_DOWN   1

#define PIN_A      19
#define PIN_B      21
#define PIN_SCLK   2
#define PIN_nOE    22
#define PIN_CLK    18
#define PIN_MOSI   23

DMD dmd(DISPLAYS_ACROSS, DISPLAYS_DOWN,
        PIN_A, PIN_B, PIN_SCLK, PIN_nOE, PIN_CLK, PIN_MOSI);

SemaphoreHandle_t dmdMutex = NULL;


// ============================================================
// GLOBALS
// ============================================================

WebServer server(80);
Preferences preferences;

String deviceId;
String deviceName;
const char* firmwareVersion = "1.1.0";

String petrolPrice = "00.00";
String dieselPrice = "00.00";

// Fixed messages that rotate with the price message
const char* LINE1 = "Welcome To BPCL....";
const char* LINE2 = "ESCON PETROLPUMP, NAGPUR";

int currentMessage = 0;          // 0 = line1, 1 = line2, 2 = prices
bool scrolling = false;

unsigned long lastMarqueeStep = 0;
unsigned long lastMessageFinished = 0;

const unsigned long MARQUEE_INTERVAL = 35;
const unsigned long MESSAGE_PAUSE = 500;

String apSSID;
const char* AP_PASSWORD = "12345678";


// ============================================================
// FUNCTION DECLARATIONS
// ============================================================

void scanTask(void *param);
void setupDisplay();
void startMessage(int number);
void updateDisplay();
String getPriceMessage();

void setupWiFi();
void setupServer();
void setupMDNS();

String getMacSuffix();
String getDeviceId();

bool validatePrice(String price);
String normalizePrice(String price);

void loadPrices();
void savePrices();

void handleStatus();
void handleGetPrices();
void handleUpdatePrices();

void sendJson(int statusCode, JsonDocument &doc);
void sendError(int statusCode, const String &message);


// ============================================================
// SETUP
// ============================================================

void setup() {

  Serial.begin(115200);
  delay(500);

  Serial.println();
  Serial.println("=================================");
  Serial.println(" ESCON ESP32 P10 CONTROLLER");
  Serial.println("=================================");

  deviceId = getDeviceId();
  deviceName = "ESCON LED " + deviceId;
  Serial.println("Device ID: " + deviceId);

  // Saved prices
  preferences.begin("escon", false);
  loadPrices();

  // 1) Wi-Fi first (nothing time-critical is running yet)
  setupWiFi();
  setupServer();
  setupMDNS();

  // 2) Display scan task starts last
  setupDisplay();

  Serial.println();
  Serial.println("=================================");
  Serial.println(" ESCON CONTROLLER READY");
  Serial.println("=================================");
  Serial.println("Device ID : " + deviceId);
  Serial.println("AP SSID   : " + apSSID);
  Serial.println("IP        : " + WiFi.softAPIP().toString());
  Serial.println();
  Serial.println("API:");
  Serial.println("GET  /api/v1/status");
  Serial.println("GET  /api/v1/prices");
  Serial.println("POST /api/v1/prices");
  Serial.println();

  currentMessage = 0;
  startMessage(currentMessage);
}


// ============================================================
// LOOP
// ============================================================

void loop() {
  server.handleClient();
  updateDisplay();
  delay(1);   // let the Wi-Fi / idle tasks breathe
}


// ============================================================
// DEVICE ID
// ============================================================

String getMacSuffix() {
  uint64_t chipId = ESP.getEfuseMac();
  char buffer[7];
  snprintf(buffer, sizeof(buffer), "%06X", (uint32_t)(chipId & 0xFFFFFF));
  return String(buffer);
}

String getDeviceId() {
  return "ESCON-" + getMacSuffix();
}


// ============================================================
// DISPLAY SCAN TASK (replaces the hardware timer ISR)
// ============================================================

void scanTask(void *param) {
  for (;;) {
    if (xSemaphoreTake(dmdMutex, portMAX_DELAY) == pdTRUE) {
      dmd.scanDisplayBySPI();
      xSemaphoreGive(dmdMutex);
    }
    // ~1 ms per scan step. One full refresh = 4 steps (~4 ms, ~250 Hz).
    vTaskDelay(1 / portTICK_PERIOD_MS > 0 ? 1 / portTICK_PERIOD_MS : 1);
  }
}

void setupDisplay() {

  dmdMutex = xSemaphoreCreateMutex();

  dmd.clearScreen(true);
  dmd.selectFont(Arial_Black_16);

  xTaskCreatePinnedToCore(
    scanTask,       // function
    "dmdScan",      // name
    4096,           // stack
    NULL,           // param
    2,              // priority (above loop task)
    NULL,           // handle
    1               // core 1 (Wi-Fi runs on core 0)
  );
}


// ============================================================
// MESSAGES
// ============================================================

String getPriceMessage() {
  return "PETROL : " + petrolPrice + "   DIESEL : " + dieselPrice;
}

void startMessage(int number) {

  String text;

  if (number == 0)      text = LINE1;
  else if (number == 1) text = LINE2;
  else                  text = getPriceMessage();

  if (dmdMutex && xSemaphoreTake(dmdMutex, portMAX_DELAY) == pdTRUE) {
    dmd.clearScreen(true);
    dmd.selectFont(Arial_Black_16);
    dmd.drawMarquee(text.c_str(), text.length(), (32 * DISPLAYS_ACROSS) - 1, 0);
    xSemaphoreGive(dmdMutex);
  }

  scrolling = true;
  lastMarqueeStep = millis();

  Serial.println("Display message: " + text);
}

void updateDisplay() {

  if (!scrolling) {
    if (millis() - lastMessageFinished >= MESSAGE_PAUSE) {
      currentMessage++;
      if (currentMessage > 2) currentMessage = 0;
      startMessage(currentMessage);
    }
    return;
  }

  if (millis() - lastMarqueeStep >= MARQUEE_INTERVAL) {

    lastMarqueeStep = millis();

    bool finished = false;
    if (xSemaphoreTake(dmdMutex, portMAX_DELAY) == pdTRUE) {
      finished = dmd.stepMarquee(-1, 0);
      xSemaphoreGive(dmdMutex);
    }

    if (finished) {
      scrolling = false;
      lastMessageFinished = millis();
    }
  }
}


// ============================================================
// WIFI / ACCESS POINT
// ============================================================

void setupWiFi() {

  WiFi.persistent(false);
  WiFi.disconnect(true, true);
  delay(100);

  WiFi.mode(WIFI_AP);
  delay(200);

  apSSID = "ESCON_LED_" + getMacSuffix();

  // channel 6, visible, max 4 clients
  bool result = WiFi.softAP(apSSID.c_str(), AP_PASSWORD, 6, 0, 4);

  if (result) {
    Serial.println("WiFi AP started successfully.");
  } else {
    Serial.println("ERROR: Failed to start WiFi AP.");
  }

  delay(300);

  Serial.println("SSID: " + apSSID);
  Serial.println("Password: " + String(AP_PASSWORD));
  Serial.println("IP: " + WiFi.softAPIP().toString());
}


// ============================================================
// mDNS
// ============================================================

void setupMDNS() {

  String host = "escon-" + getMacSuffix();

  if (MDNS.begin(host.c_str())) {
    Serial.println("mDNS started.");
    Serial.println("Hostname: " + host + ".local");
    MDNS.addService("http", "tcp", 80);
  } else {
    Serial.println("mDNS failed.");
  }
}


// ============================================================
// WEB SERVER
// ============================================================

void setupServer() {

  server.on("/api/v1/status", HTTP_GET, handleStatus);
  server.on("/api/v1/prices", HTTP_GET, handleGetPrices);
  server.on("/api/v1/prices", HTTP_POST, handleUpdatePrices);

  // Health check
  server.on("/", HTTP_GET, []() {
    StaticJsonDocument<256> doc;
    doc["device"] = "ESCON LED Controller";
    doc["deviceId"] = deviceId;
    doc["status"] = "online";
    sendJson(200, doc);
  });

  server.onNotFound([]() {
    sendError(404, "Endpoint not found");
  });

  server.begin();
  Serial.println("HTTP server started.");
}


// ============================================================
// GET /api/v1/status
// ============================================================

void handleStatus() {

  StaticJsonDocument<512> doc;

  doc["deviceId"] = deviceId;
  doc["deviceName"] = deviceName;
  doc["connected"] = true;
  doc["firmwareVersion"] = firmwareVersion;
  doc["displaySize"] = "64x16";
  doc["displayType"] = "P10";
  doc["controller"] = "ESP32";
  doc["ip"] = WiFi.softAPIP().toString();
  doc["mode"] = "AP";

  sendJson(200, doc);
}


// ============================================================
// GET /api/v1/prices
// ============================================================

void handleGetPrices() {

  StaticJsonDocument<256> doc;

  doc["petrol"] = petrolPrice;
  doc["diesel"] = dieselPrice;
  doc["updated"] = true;

  sendJson(200, doc);
}


// ============================================================
// POST /api/v1/prices
// ============================================================

void handleUpdatePrices() {

  Serial.println();
  Serial.println("Received price update.");

  if (!server.hasArg("plain")) {
    sendError(400, "Request body missing");
    return;
  }

  String body = server.arg("plain");
  Serial.println("Body: " + body);

  StaticJsonDocument<512> doc;
  DeserializationError error = deserializeJson(doc, body);

  if (error) {
    sendError(400, "Invalid JSON");
    return;
  }

  if (doc["petrol"].isNull() || doc["diesel"].isNull()) {
    sendError(400, "petrol and diesel are required");
    return;
  }

  String newPetrol = doc["petrol"].as<String>();
  String newDiesel = doc["diesel"].as<String>();

  if (!validatePrice(newPetrol)) {
    sendError(400, "Invalid petrol price");
    return;
  }

  if (!validatePrice(newDiesel)) {
    sendError(400, "Invalid diesel price");
    return;
  }

  petrolPrice = normalizePrice(newPetrol);
  dieselPrice = normalizePrice(newDiesel);

  // Reply first so the app gets its answer quickly,
  // then do the (slower) flash write and display change.
  StaticJsonDocument<256> response;
  response["success"] = true;
  response["message"] = "Prices updated successfully";
  response["petrol"] = petrolPrice;
  response["diesel"] = dieselPrice;
  sendJson(200, response);

  savePrices();

  // Show the new prices immediately
  currentMessage = 2;
  startMessage(currentMessage);

  Serial.println("Prices updated successfully.");
}


// ============================================================
// PRICE VALIDATION
// ============================================================

bool validatePrice(String price) {

  price.trim();

  if (price.length() == 0) return false;
  if (price.length() > 6) return false;

  float value = price.toFloat();

  if (value <= 0) return false;
  if (value > 999.99) return false;

  bool dotFound = false;
  int decimalPlaces = 0;

  for (uint16_t i = 0; i < price.length(); i++) {

    char c = price.charAt(i);

    if (c == '.') {
      if (dotFound) return false;
      dotFound = true;
      continue;
    }

    if (c < '0' || c > '9') return false;

    if (dotFound) {
      decimalPlaces++;
      if (decimalPlaces > 2) return false;
    }
  }

  return true;
}


// ============================================================
// NORMALIZE PRICE
// ============================================================

String normalizePrice(String price) {

  price.trim();
  float value = price.toFloat();

  char buffer[12];
  snprintf(buffer, sizeof(buffer), "%.2f", value);

  return String(buffer);
}


// ============================================================
// NVS LOAD / SAVE
// ============================================================

void loadPrices() {

  petrolPrice = preferences.getString("petrol", "00.00");
  dieselPrice = preferences.getString("diesel", "00.00");

  Serial.println("Saved Petrol: " + petrolPrice);
  Serial.println("Saved Diesel: " + dieselPrice);
}

void savePrices() {

  preferences.putString("petrol", petrolPrice);
  preferences.putString("diesel", dieselPrice);

  Serial.println("Prices saved to NVS.");
}


// ============================================================
// RESPONSE HELPERS
// ============================================================

void sendJson(int statusCode, JsonDocument &doc) {

  String response;
  serializeJson(doc, response);

  server.send(statusCode, "application/json", response);
}

void sendError(int statusCode, const String &message) {

  StaticJsonDocument<256> doc;
  doc["success"] = false;
  doc["error"] = message;

  sendJson(statusCode, doc);
}
