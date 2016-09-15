function lightChoice=detectLightChoice(changedArm,current_arm,LEDs)

lightChoice=NaN(size(changedArm));
if sum(changedArm)>0
iShift=0:3:(sum(changedArm)-1)*3;
turnArm=current_arm(changedArm);
turnArm=turnArm+iShift';
armVec=zeros(sum(changedArm)*3,1);
armVec(turnArm)=1;
tmpLED=LEDs(changedArm,:);
tmpLED=reshape(tmpLED',sum(changedArm)*3,1);
photoPos=tmpLED&armVec;
photoPos=sum(reshape(photoPos,3,sum(changedArm))',2);
lightChoice(changedArm)=photoPos;
end
