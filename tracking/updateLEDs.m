function LEDs = updateLEDs(trackDat)

% Randomly select a new LED to turn on
LEDs = trackDat.LEDs;
if any(trackDat.changed_arm)
    iShift=0:3:(sum(trackDat.changed_arm)-1)*3;
    trackDat.Turns=trackDat.Turns(trackDat.changed_arm)';
    trackDat.Turns=trackDat.Turns+iShift;                     % Convert arm to index #
    newArm=rand(sum(trackDat.changed_arm)*3,1);           % Randomly select new LED
    newArm(trackDat.Turns)=0;                          % Exclude LED in the arm they just turned to
    newArm=reshape(newArm,3,sum(trackDat.changed_arm))';               
    [v c]=max(newArm,[],2);                          % Select new arm by picking highest random number in each row (maze)
    newArm=c'+iShift;
    newLEDs=zeros(size(newArm,2)*3,1);
    newLEDs(newArm)=1;
    newLEDs=reshape(newLEDs,3,sum(trackDat.changed_arm))';
    LEDs(trackDat.changed_arm,:)=newLEDs;
end