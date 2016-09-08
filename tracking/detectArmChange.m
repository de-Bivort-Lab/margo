function [current_arm,previous_arm,changedArm,rightTurns,turntStamp]=detectArmChange(lastCentroid,arm_coords,previous_arm,mazeOri,armThresh,turntStamp,tElapsed)

% cenDat is centroid data with flies matched to ROIs
% Calculate distance to each arm of the maze and determine nearest arm
cenDat=repmat(lastCentroid,1,1,size(arm_coords,3));
d=sqrt(dot((cenDat-arm_coords),(arm_coords-cenDat),2));
d=abs(d);

% Record which arm the fly is in and the distance to the end of the arm
current_arm=zeros(size(arm_coords,1),1);
[d0,current_arm_0]=min(permute(d(~mazeOri,:,1:3),[3 2 1]));    % Closest arm for right-side down maze
[d1,current_arm_1]=min(permute(d(mazeOri,:,4:6),[3 2 1]));     % Closest arm for right-side up maze
current_arm(~mazeOri)=current_arm_0;
current_arm(mazeOri)=current_arm_1;
current_arm=squeeze(current_arm);
%current_arm=current_arm;
d=NaN(size(arm_coords,1),1);
d(~mazeOri)=d0;
d(mazeOri)=d1;

% If distance to end of the arm < armThresh pixels and the fly is in a new arm of
% the maze, record the choice
dThresh=squeeze(d<armThresh);
changedArm=(current_arm~=previous_arm)&dThresh;

% Maze arms are numbered 1-3 (mazeOri=0) or 4-6 (mazeOri=1) from left to right of a Y
rightTurns=NaN(size(current_arm));
armDiff=previous_arm-current_arm;

% Define new previous_arm vector and threshold turns that occur too quickly
% in sequence
dt=tElapsed-turntStamp;
changedArm(dt<0.5)=0;
changedArm=logical(changedArm);

% Right turns recorded as transition (difference) from previous - current arm (1-3=-2; 3-2=1; 2-1=1)
rightTurns(logical(changedArm&~mazeOri))=...
    (armDiff(logical(changedArm&~mazeOri))==-2)+(armDiff(logical(changedArm&~mazeOri))==1);
rightTurns(logical(changedArm&mazeOri))=...
    (armDiff(logical(changedArm&mazeOri))==2)+(armDiff(logical(changedArm&mazeOri))==-1);

turntStamp(changedArm)=tElapsed;
previous_arm(changedArm)=current_arm(changedArm);
end