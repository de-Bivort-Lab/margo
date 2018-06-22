function [trackDat] = detectArmChange(trackDat,expmt)

% cenDat is centroid data with flies matched to ROIs
% Calculate distance to each arm of the maze and determine nearest arm
cenDat = repmat(trackDat.centroid,1,1,size(trackDat.arm,3));
d=sqrt(dot((cenDat-trackDat.arm),(trackDat.arm-cenDat),2));
d=abs(d);

% Record which arm the fly is in and the distance to the end of the arm
curr_arm = zeros(size(trackDat.arm,1),1);
[d0,curr_arm_0] = ...
    min(permute(d(~expmt.meta.roi.orientation,:,1:3),[3 2 1]));    % Closest arm for right-side down maze
[d1,curr_arm_1] = ...
    min(permute(d(expmt.meta.roi.orientation,:,4:6),[3 2 1]));     % Closest arm for right-side up maze
curr_arm(~expmt.meta.roi.orientation) = curr_arm_0;
curr_arm(expmt.meta.roi.orientation) = curr_arm_1;
curr_arm=squeeze(curr_arm);

d=NaN(size(trackDat.arm,1),1);
d(~expmt.meta.roi.orientation) = d0;
d(expmt.meta.roi.orientation) = d1;

% If distance to end of the arm < arm_thresh pixels and the fly is in a new arm of
% the maze, record the choice
dThresh = squeeze(d < expmt.parameters.arm_thresh);
trackDat.changed_arm = (curr_arm ~= trackDat.prev_arm) & dThresh;

% Define new previous_arm vector and threshold turns that occur too quickly
% in sequence
dt= trackDat.t - trackDat.turntStamp;
trackDat.changed_arm(dt < 0.5) = 0;
trackDat.changed_arm=logical(trackDat.changed_arm);

% Record both the time and new arm for flies that changed arms
trackDat.turntStamp(trackDat.changed_arm) = trackDat.t;
trackDat.prev_arm(trackDat.changed_arm) = curr_arm(trackDat.changed_arm);

end