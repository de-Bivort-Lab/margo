
#include <SPI.h>  // include the SPI library:

const int slaveSelectPin = 10;
uint8_t lat[]={19,4,18,3,2,17,1,16,0};
uint16_t data[24];
uint16_t target[24];
uint8_t evenChannel_LSB=0;
int b=0;
uint16_t level=0;
uint8_t board = 0;
uint8_t LED=0;
uint8_t previousBoard = 1;
uint8_t readCount=0;
byte buf[4];
int counter=0;
uint8_t LEDramp=0;

SPISettings settingsA(30000000, MSBFIRST, SPI_MODE0);

// Initialize the teensy with all LEDs OFF
void setup() {
  Serial.begin(76800);

  for(int i=0; i<sizeof(lat); i++){
    pinMode(lat[i],OUTPUT);
  }
          
  pinMode(slaveSelectPin, OUTPUT);
  
  SPI.begin(); 
  SPI.setBitOrder(MSBFIRST);
  digitalWrite(slaveSelectPin,LOW);

  SPI.beginTransaction(settingsA);
  for(int i=0; i<sizeof(lat); i++){
    digitalWrite(lat[i],LOW);
  }

  for (int i=0; i<36; i++){
  uint16_t init=65535;
  SPI.transfer(init);
  }
  for(int j=0; j<sizeof(lat); j++){
    digitalWrite(lat[j],HIGH);
    digitalWrite(lat[j],LOW);
  }
  SPI.endTransaction();
}



// Main loop to be executed again and again
void loop() {
  
  delay(1);
      // Ramp the LED up and down
    for(int i=0; i<sizeof(data)/sizeof(data[0]); i++){
      data[i]=LEDramp;
    }
    Serial.println(LEDramp);
    if(LEDramp>=0&&LEDramp<255)LEDramp++;
    else LEDramp--;
    
  //Initialize the SPI transaction
  
  SPI.beginTransaction(settingsA);

  //Iterate through the data writing process for each driver board
  //for(int j=0; j<sizeof(lat); j++){

      //Read 24 new PWM values in from labview
      while(LED!=23){
         if (Serial.available()>3){ // Wait for characters
         Serial.readBytes((char*)buf,4);
         level=buf[0];
         level=level<<8;
         level|=buf[1];
         readCount++;
         board=buf[2];
         LED=buf[3];
         data[LED]=level;
         }
      }


      
      digitalWrite(lat[board],LOW);
      // Write the new data to the appropriate board
        for (uint8_t i=0; i<24; i++){
          /*To write a 12-bit value to LED driver board, write the first 8 MSB in one byte for an even channel.
           Then write the remaining 4 LSB of the even channel and the 4 MSB of the following odd channel in the next byte.
           The final 8 MSB of an odd channel are written in the third byte. This process repeats until all 24 of the
           12-bit integers are written (24 channels * 12 bits each = 288 bits; => 36 bytes in total are written to each board).
           */
     
           // Check to see if the channel is odd
          if(i%2){
            uint8_t oddChannel_MSB=((data[i]>>8)&0x0F);               // Bitshift and mask to grab odd MSB
            uint8_t evenLSB_oddMSB=evenChannel_LSB|oddChannel_MSB;    // Combine even 4 LSB and odd 4 MSB into single byte
            uint8_t oddChannel_LSB=data[i];                           // Grab remaining odd 8 LSB
            SPI.transfer(evenLSB_oddMSB);
            SPI.transfer(oddChannel_LSB);

          }
          else{
            uint8_t evenChannel_MSB=(data[i]>>4);                     // Grab bits 12-5
            evenChannel_LSB=(data[i]<<4);                             // Bitshift to grab remaining even LSB 4-1 and pad with zeros
            SPI.transfer(evenChannel_MSB);                            // Write even MSB
          }
        }

        // Latch the correct board to set the newly written PWM values
        // Note: Only the latched board will update to the new values
        digitalWrite(lat[board],HIGH);
        digitalWrite(lat[board],LOW);

        //Reset the read counter
        LED=0;
  //}

  //Close the SPI session
  SPI.endTransaction();
 }
