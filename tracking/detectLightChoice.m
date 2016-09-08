function out=detectLightChoice(changedArm,currentArm,LEDs)

iShift=0:3:(sum(changedArm)-1)*3;
turnArm=currentArm(changedArm);
turnArm=turnArm+iShift';
armVec=zeros(sum(changedArm)*3,1);
armvec(turnArm)=1;
tmpLED=LEDs(changedArm,:);
tmpLED=reshape(tmpLED',sum(changedArm)*3,1);
photoPos=tmpLED&armVec;
photoPos=sum(reshape(photoPos,3,sum(changedArm))',2);
lightChoice=NaN(size(changedArm));
lightChoice(changedArm)=photoPos;
