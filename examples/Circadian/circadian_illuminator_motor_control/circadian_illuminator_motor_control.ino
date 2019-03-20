uint8_t isVibOn = 0;
uint8_t nbPulses = 0;
uint8_t pulseDur = 0;
uint8_t interPulseDur = 0;
uint8_t pulseStrength = 0;
byte handshake[7]={1,1,0,0,1,0,1};
byte readBuf[2];
byte motorBuf[7];

// initialize serial port and write intermediate pwm value to both channels
void setup() {
  Serial.begin(9600);
  pinMode(10,OUTPUT);
  pinMode(9,OUTPUT);
  pinMode(6,OUTPUT);
  analogWriteFrequency(10,187500);
  analogWrite(10,40);
  analogWrite(9,40);
  analogWrite(6,0);
}

void loop() {

  // while at least 2 bytes are available at serial port
  while(Serial.available()>=2){

    // read in first byte as pwm level and second byte as light channel pin number
    Serial.readBytes((char*)readBuf,2);
    byte level=readBuf[0];
    byte pin=readBuf[1];

    // update the illuminator
    if(pin==9||pin==10){
      analogWrite(pin,level);
    }
    // write vibrational motors
    else if(pin==6){
      delay(10);
      Serial.readBytes((char*)motorBuf,5);
      isVibOn = motorBuf[0];
      nbPulses = motorBuf[1];
      pulseDur = motorBuf[2];
      interPulseDur = motorBuf[3];
      pulseStrength = motorBuf[4];

      if(isVibOn==1){
        for(int j = 0; j < nbPulses; j++){
          analogWrite(pin,pulseStrength);
          delay(pulseDur*1000);
          analogWrite(pin,0);
          delay(interPulseDur*1000);
        }
      }
    }
    // perform handshake with margo to identify illuminator COM port
    else if(pin==2&&level==2){
      for(int i=0; i<=6; i++){
        Serial.write(handshake[i]);
    }
   }  
   
  }
  
}
