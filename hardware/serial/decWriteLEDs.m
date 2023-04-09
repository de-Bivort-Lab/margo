function [numActive]=decWriteLEDs(serialObject,trackDat)


led_pwm= repmat(trackDat.led_pwm,1,3);
led_pwm(~trackDat.LEDs)=0;
led_pwm = reshape(led_pwm',size(led_pwm,1)*3,1);
led_pwm(trackDat.pLED) = led_pwm;
trackDat.LEDs=reshape(trackDat.LEDs',size(trackDat.LEDs,1)*3,1);
trackDat.LEDs(trackDat.pLED)=trackDat.LEDs;

led_pwm=repmat(led_pwm,1,12);

bitMath = repmat(uint16(2.^(12:-1:1)),size(led_pwm,1),1);
led_pwm = mod(led_pwm,bitMath)./bitMath;%./bitMath;
binaryConv=mod(led_pwm,2);

% Split binary values into bytes to be sent over serial
byte1=[zeros(size(binaryConv,1),4) binaryConv(:,1:4)];
byte2=binaryConv(:,5:12);
bytes=zeros(size(byte1,1)*2,8);
bytes(mod(1:size(byte1,1)*2,2)==1,:)=byte1;
bytes(mod(1:size(byte1,1)*2,2)==0,:)=byte2;

% Convert each byte into its corresponding uint8 decimal value
bitMath=2.^(7:-1:0);
bitMath=repmat(bitMath,size(bytes,1),1);
bitMath(~bytes)=0;
pwmBytes=sum(bitMath,2);

% Initial board and LED vector
boards=reshape(repmat(0:8,24,1),24*9,1);
ledNums=repmat(0:23,1,9);

% Format data string to be written to the teensy
dataString=zeros(size(pwmBytes,1)*2,1);
dataString(mod(1:size(dataString,1),4)==1)=pwmBytes(mod(1:size(pwmBytes,1),2)==1);
dataString(mod(1:size(dataString,1),4)==2)=pwmBytes(mod(1:size(pwmBytes,1),2)==0);
dataString(mod(1:size(dataString,1),4)==3)=boards;
dataString(mod(1:size(dataString,1),4)==0)=ledNums;
dataString=char(dataString);                            % Convert to ASCII character array

% Write the data in 2 different batches so that the Serial Buffer does not overflow
fwrite(serialObject,dataString(1:size(dataString,1)/2),'uchar');
fwrite(serialObject,dataString(size(dataString,1)/2+1:end),'uchar');

numActive=sum(trackDat.LEDs);




