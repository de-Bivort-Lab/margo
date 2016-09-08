function LEDs=decUpdateLEDs(changedArm,turnArm,LEDs,permuteLEDs);

% Randomly select a new LED to turn on
iShift=0:3:(sum(changedArm)-1)*3;
turnArm=turnArm(changedArm);
turnArm=turnArm+iShift;                     % Convert arm to index #
newArm=rand(sum(changedArm)*3,1);           % Randomly select new LED
newArm(turnArm)=0;                          % Exclude LED in the arm they just turned to
newArm=reshape(newArm,3,sum(changedArm))';               
[v c]=max(newArm,[],2);                          % Select new arm by picking highest random number in each row (maze)
                                                 % Output c and use changed ARM to output to file for whole
                                                 % list of flies. To be
                                                 % combined with previous
                                                 % arm for comparison
                                                
newArm=c'+iShift;
newLEDs=zeros(size(newArm,2)*3,1);
newLEDs(newArm)=1;
newLEDs=reshape(newLEDs,3,sum(changedArm))';
LEDs(changedArm,:)=newLEDs;
LEDs=reshape(LEDs',size(LEDs,1)*3,1);
LEDs=LEDs(permuteLEDs);