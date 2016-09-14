function [varargout]=matchCentroids2ROIs(cenDat,centers,speedThresh,distanceThresh,lastCentroid,centStamp,tElapsed)

% Define placeholder data variables equal to number ROIs
tempCenDat=NaN(size(centers,1),2);

% Initialize temporary centroid and orientation variables
tempCenDat(1:size(cenDat,1),:)=cenDat;


% Find nearest Last Known Centroid for each current centroid
% Replicate temp centroid data into dimensions compatible with dot product
% with the last known centroid of each fly
tD=repmat(tempCenDat,1,1,size(lastCentroid,1));
c=repmat(lastCentroid,1,1,size(tempCenDat,1));
c=permute(c,[3 2 1]);

% Use dot product to calculate pairwise distance between all coordinates
g=sqrt(dot((c-tD),(tD-c),2));
g=abs(g);

% Returns minimum distance to each previous centroid and the indeces (j)
% Of the temp centroid with that distance
[lastCenDistance,j]=min(g);
speed=NaN(size(centers,1),1);

    % For the centroids j, calculate speed and distance to ROI center for thresholding
    if size(cenDat,1)>0
    centerDistance=abs(sqrt(dot(cenDat(j,:)'-centers',centers'-cenDat(j,:)')))';
    dt=tElapsed-centStamp;

    % Exclude centroids that move to fast or are to far from the ROI center
    % corresponding to the previous centroid each item in j, was matched with
    speed=squeeze(lastCenDistance)./dt;
    mismatch=speed>speedThresh|centerDistance>distanceThresh;
    j(mismatch)=NaN;
    lastCenDistance(mismatch)=NaN;

    % If the same ROI is matched to more than one coordinate, find the nearest
    % one and exclude the others
    u=unique(j(~isnan(j)));                                         % Extract the unique values of the ROIs
    duplicateCen=u(squeeze(histc(j,u))>1);
    duplicateROIs=find(ismember(j,u(squeeze(histc(j,u))>1)));       % Find the indices of duplicate ROIs
    % Calculate pairwise distances between duplicate ROIs and temp centroids
    % using the same method above
    tD=repmat(tempCenDat(duplicateCen,:),1,1,size(lastCentroid,1));
    c=repmat(lastCentroid,1,1,size(tempCenDat(duplicateCen,:),1));
    c=permute(c,[3 2 1]);
    g=sqrt(dot((c-tD),(tD-c),2));
    g=abs(g);
    [~,k]=min(g,[],3);
    j(duplicateROIs)=NaN;
    j(k)=duplicateCen;

    % Update time stamp for when each centroid was last updated
    centStamp(~isnan(j))=tElapsed;

    % Update last known centroid and orientations
    lastCentroid(~isnan(j),:)=cenDat(j(~isnan(j)),:);
    end
    
    out{1}=lastCentroid;
    out{2}=centStamp;
    out{3}=speed;
    
    for i=1:nargout
        varargout{i}=out{i};
    end
        

end

