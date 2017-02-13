function [expmt] = processCentroid(expmt)

    % initialize tracking properties struct
    nFrames = size(expmt.Centroid,1);
    empty = single(NaN(nFrames, expmt.nTracks));
    trackProps = struct('r',empty,'theta',empty,'direction',empty,...
        'turning',empty,'speed',empty,'turn_d',empty,...
        'center',empty(1,:));
    
    % initialize handedness struct
    bins = 0:2*pi/25:2*pi;
    handedness = struct('angle_histogram',single(NaN(length(bins)-1,expmt.nTracks)),...
        'mu',single(NaN(expmt.nTracks,1)),'bins',bins,'circum_vel',empty,'include',~isnan(empty));
    
    clearvars empty

    % calculate track properties
for j = 1:expmt.nTracks
    
    % get x and y coordinates of the centroid and normalize to upper left ROI corner
    inx = expmt.Centroid(:,1,j)-expmt.ROI.corners(j,1);
    iny = expmt.Centroid(:,2,j)-expmt.ROI.corners(j,2);
    center=mean([expmt.ROI.corners(j,3)-expmt.ROI.corners(j,1) expmt.ROI.corners(j,4)-expmt.ROI.corners(j,2)],2);
    
    % calculate the radial distance from the ROI center
    trackProps.r(:,j) = sqrt((inx-center/2).^2+(iny-center/2).^2);
    trackProps.theta(:,j) = atan2(iny-center/2,inx-center/2);
    trackProps.direction(:,j) = zeros(size(inx,1),1);
    trackProps.turning(:,j) = zeros(size(inx,1),1);
    trackProps.center(j) = center;
    trackProps.direction(2:end,j) = atan2(diff(iny),diff(inx));
    trackProps.turning(2:end,j) = diff(trackProps.direction(:,j));
    
    trackProps.speed(:,j) = zeros(size(inx,1),1);
    if isfield(expmt,'tStamps')
        trackProps.speed(2:end,j) = sqrt(diff(iny).^2+diff(iny).^2) ./ diff(expmt.tStamps);
    else
        trackProps.speed(2:end,j) = sqrt(diff(iny).^2+diff(iny).^2);
    end
    
    trackProps.turn_d(:,j) = trackProps.speed(:,j).*sin(trackProps.turning(:,j));
    trackProps.speed(trackProps.speed(:,j) > 12, j) = NaN;
    
    % restrict frames for handedness measures to set criteria
    moving = trackProps.speed(:,j) > 0.02;
    in_center = trackProps.r(:,j) < 0.5 * trackProps.center(j);
    include = boolean(moving & in_center);
    handedness.circum_vel(include,j) = trackProps.theta(include,j)-trackProps.direction(include,j);
    
    % shift negative range (-2pi to 0) up to positive (0 to 2pi)
    handedness.circum_vel(handedness.circum_vel(include,j)<0,j) = ...
        handedness.circum_vel(handedness.circum_vel(include,j)<0,j)+(2*pi);
    
    % bin circumferential velocity into histogram
    h = histc(handedness.circum_vel(:,j),bins);
    h = h/sum(h);
    h(1) = h(1) + h(end);
    h(end)=[];
    
    % calculate average mu
    mu = ([0;diff(trackProps.theta(include,j))] .* trackProps.r(include,j)./ trackProps.speed(include,j));
    mu(isinf(mu))=NaN;
    mu = nanmean(mu);
    
    % save to expmt data struct
    handedness.angle_histogram(:,j) = h;
    handedness.mu(j) = mu;
    handedness.include(:,j) = include;
    
    clearvars mu h inx iny
    
end

bins(end) = [];
handedness.bins = bins;

expmt.handedness = handedness;

if ~isfield(expmt,'Speed') && isfield(expmt,'tStamps')
    expmt.Speed = trackProps.speed;
end

