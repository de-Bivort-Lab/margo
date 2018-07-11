function lightChoice = detectLightChoice(trackDat)

lightChoice=int8(zeros(size(trackDat.changed_arm)));

if sum(trackDat.changed_arm)>0
    
    iShift=0:3:(sum(trackDat.changed_arm)-1)*3;
    turnArm=trackDat.prev_arm(trackDat.changed_arm);
    turnArm=turnArm+iShift';
    armVec=zeros(sum(trackDat.changed_arm)*3,1);
    armVec(turnArm)=1;
    tmpLED=trackDat.LEDs(trackDat.changed_arm,:);
    tmpLED=reshape(tmpLED',sum(trackDat.changed_arm)*3,1);
    photoPos=tmpLED&armVec;
    photoPos=sum(reshape(photoPos,3,sum(trackDat.changed_arm))',2);
    lightChoice(trackDat.changed_arm)=photoPos;
    
end
