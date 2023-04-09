uint8_t WHITE_LIGHT_PIN = 9;
uint8_t IR_LIGHT_PIN = 10;
const size_t NUM_READ_BYTES = 2;
byte readBuf[NUM_READ_BYTES];
uint8_t HANDSHAKE_PIN_FLAG = 2;
uint8_t HANDSHAKE_LEVEL_FLAG = 2;
byte handshake[7] = {1, 1, 0, 0, 1, 0, 1};


// initialize serial port and write intermediate pwm value to both channels
void setup() {
  Serial.begin(9600);
  pinMode(WHITE_LIGHT_PIN, OUTPUT);
  pinMode(IR_LIGHT_PIN, OUTPUT);
  //analogWriteFrequency(WHITE_LIGHT_PIN, 187500);
  //analogWriteFrequency(IR_LIGHT_PIN, 187500);

  analogWrite(WHITE_LIGHT_PIN, 40);
  analogWrite(IR_LIGHT_PIN, 40);
}

void loop() {

  // while at least 2 bytes are available at serial port
  while(Serial.available() >= NUM_READ_BYTES) {

    // read in first byte as pwm level and second byte as light channel pin number
    Serial.readBytes((char*) readBuf, NUM_READ_BYTES);
    byte level = readBuf[0];
    byte pin = readBuf[1];

    // update the illuminator
    if(isLightPanelPin(pin)) {
      analogWrite(pin, level);
    }
    // perform handshake with margo to identify illuminator COM port
    else if(isHandshakeFlag(pin, level)) {
      writeHandshake();
    }
  }
  
}

bool isLightPanelPin(byte pin) {
  return pin == WHITE_LIGHT_PIN || pin == IR_LIGHT_PIN;
}

bool isHandshakeFlag(byte pin, byte level) {
  return pin == HANDSHAKE_PIN_FLAG && level == HANDSHAKE_LEVEL_FLAG;
}

void writeHandshake() {
  for(int i = 0; i <= 6; i++) {
    Serial.write(handshake[i]);
  }
  return;
}

