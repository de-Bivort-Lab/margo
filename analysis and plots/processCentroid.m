function [expmt,trackProps] = processCentroid(expmt)

    % initialize tracking properties struct
    nFrames = size(expmt.Centroid.data,1);
    empty = single(NaN(nFrames, expmt.nTracks));
    trackProps = struct('r',empty,'theta',empty,'direction',empty,...
        'turning',empty,'speed',empty,'center',empty(1,:));
        
    e=1 + 1E-5;
    
    clearvars empty

    % calculate track properties
for j = 1:expmt.nTracks
    
    % get x and y coordinates of the centroid and normalize to upper left ROI corner
    inx = expmt.Centroid.data(:,1,j)-expmt.ROI.centers(j,1);
    iny = expmt.Centroid.data(:,2,j)-expmt.ROI.centers(j,2);
    center=0;
    
    % calculate the radial distance from the ROI center
    trackProps.r(:,j) = sqrt((inx).^2+(iny).^2);
    trackProps.theta(:,j) = atan2(iny,inx);
    trackProps.direction(:,j) = zeros(size(inx,1),1);
    trackProps.turning(:,j) = zeros(size(inx,1),1);
    trackProps.center(j) = center;
    trackProps.direction(2:end,j) = atan2(diff(iny),diff(inx));
    trackProps.turning(2:end,j) = diff(trackProps.direction(:,j));
    trackProps.turning(trackProps.turning(:,j)>pi*e,j) =...
        trackProps.turning(trackProps.turning(:,j)>pi*e,j) - 2*pi;
    trackProps.turning(trackProps.turning(:,j)<-pi*e,j) = ...
        trackProps.turning(trackProps.turning(:,j)<-pi*e,j) + 2*pi;
    
    trackProps.speed(:,j) = zeros(size(inx,1),1);
%     if isfield(expmt,'tStamps')
%         trackProps.speed(2:end,j) = sqrt(diff(inx).^2+diff(iny).^2) ./ diff(expmt.tStamps);
%     else
        trackProps.speed(2:end,j) = sqrt(diff(inx).^2+diff(iny).^2);
%     end
    
    trackProps.speed(trackProps.speed(:,j) > 12, j) = NaN;
    
    clearvars mu h inx iny
    
end

% restrict frames for handedness measures to set criteria
expmt.handedness = getHandedness(trackProps);

if ~isfield(expmt,'Speed') && isfield(expmt,'tStamps')
    expmt.Speed = trackProps.speed;
end

