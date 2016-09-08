function [numActive]=decWriteLEDs(LEDs,targetPWM,serialObject,permuteLEDs)

LEDs=reshape(LEDs',size(LEDs,1)*3,1);
LEDs(permuteLEDs)=LEDs;

targetPWM=ones(size(LEDs,1),1)*targetPWM;
targetPWM(~LEDs)=0;
targetPWM=repmat(targetPWM,1,12);

% Convert 12 bit PWM value to binary
for i=2:size(targetPWM,2)
    targetPWM(:,i)=floor(targetPWM(:,i-1)./2);
end
binaryConv=fliplr(mod(targetPWM,2));

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

numActive=sum(LEDs);




