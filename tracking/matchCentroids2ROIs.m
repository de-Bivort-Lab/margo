function [varargout]=matchCentroids2ROIs(raw_cen,trackDat,expmt,gui_handles)

%   SORT CENTROID COORDINATES BASED ON DISTANCE TO KNOWN REFERENCE COORDINATES
%   This function sorts centroid coordinates based on the pairwise distance to one or two 
%   sets of reference coordinates and outputs a permutation vector for
%   sorting the input centroids.
%
%   MODES: Single Sort, Double Sort
%
%           Single Sort - [P,U] = matchCentroids2ROIs(CEN,C1)
%
%               Takes an Nx2 dimensional array of unsorted centroid 
%               coordinates (CEN) and an Mx2 array of reference coordinates
%               (C1) as inputs and finds the reference coordinate with the 
%               shortest distance to each unsorted centroid. The function 
%               outputs up to a permutation vector (P) that can be as large as 
%               Mx1 but will be Nx1 if N < M. This vector is a mapping of the 
%`              indices of CEN to their nearest neighbors in C1. If more
%               than one centroid is matched to the same reference
%               coordinate, the centroids are then restricted such that only 
%               the nearest neighbor of each reference coordinate will be
%               matched, thus ensuring that only one input centroid is
%               sorted to each reference centroid. In addition to the
%               permutation vector, an Mx1 logical update vector (U) is also 
%               output that is TRUE where a reference coordinate has been
%               matched to an unsorted centroid and false where no match
%               was found.
%
%           INPUTS
%
%               CEN - unsorted Nx2 centroid coordinates output from region 
%               props where N is the number of detected centroids
%
%               C1 - Mx2 reference coordinates where M is the expected
%               number of tracked objects. Works best if C1 is the last known
%               coordinates of a tracked object(s).
%
%           OUTPUTS
%
%               P - permutation vector that is Nx1 if N < M and Mx1 if
%               N >= M. For example: P = [2 5 1] specifies that the second
%               centroid in CEN is matched to the first coordinate of C1(U).
%               The fifth centroid of CEN is matched to the second
%               coordinate of C(U) etc. Indices 3 and 4 of CEN were not 
%               matched with any reference coordinate and are thus
%               excluded.
%
%               U - Mx1 logical update vector true where a reference
%               coordinate has been matched to an unsorted centroid. The
%               combination of P and U serves as a mapping between the
%               input centroids and the reference coordinates.
%
%                   eg. C(U,:) = CEN(P,:)
%
%           Double Sort - [P,U] = matchCentroids2ROIs(cen,C1,C2,thresh)
%
%               Double Sort has all the same core functionality of single
%               sort but undergoes an additional round of filtering using a
%               distance threshold to exclude unsorted centroids that are
%               too far from a known landmark (eg. the center of an ROI).
%
%           INPUTS
%                       
%               C2 - Mx2 reference coordinates where M is the expected
%               number of tracked objects. Works best if C2 are the
%               coordinates of known landmarks (eg. ROI coordinates).
%               Must be the same dimensions as C1. Paired coordinates
%               between C1 and C2 must be matched in order (eg. the index
%               of the last known position of an object must be matched to
%               the index of its the ROI position).
%
%               thresh - a scalar threshold value that serves as an upper
%               bound on the allowed distance from an unsorted centroid to
%               its matched coordinate in C2.
%

% get user data from gui
udat = gui_handles.gui_fig.UserData;

% Define placeholder data variables equal to number ROIs
tempCenDat=NaN(size(trackDat.Centroid,1),2);

% Initialize temporary centroid variables
tempCenDat(1:size(raw_cen,1),:)=raw_cen;

% Find nearest Last Known Centroid for each current centroid
% Replicate temp centroid data into dimensions compatible with dot product
% with the last known centroid of each fly
tD=repmat(tempCenDat,1,1,size(trackDat.Centroid,1));
c=repmat(trackDat.Centroid,1,1,size(tempCenDat,1));
c=permute(c,[3 2 1]);

% Use dot product to calculate pairwise distance between all coordinates
g=sqrt(dot((c-tD),(tD-c),2));
g=abs(g);

% Returns minimum distance to each previous centroid and the indces (j)
% Of the temp centroid with that distance
[primary_distance,j]=min(g);

% Initialize empty placeholders for permutation and inclusion vectors
sorting_permutation=[];
update_centroid = logical(zeros(size(trackDat.Centroid,1),1));

    % For the centroids j, calculate speed and distance to ROI center for thresholding
    if size(raw_cen,1)>0 
        
        if strcmp(udat.sort_mode,'distance')
            % Calculate distance to known landmark such as the ROI center
            secondary_distance=abs(sqrt(dot(raw_cen(j,:)'-expmt.ROI.centers',expmt.ROI.centers'-raw_cen(j,:)')))';

            % Exclude centroids that move too fast or are too far from the ROI center
            % corresponding to the previous centroid each item in j, was matched with
            mismatch = secondary_distance .* expmt.parameters.mm_per_pix > udat.distance_thresh;
            j(mismatch)=NaN;
            primary_distance(mismatch)=NaN;
        elseif strcmp(udat.sort_mode,'bounds')
            
        end

        % If the same ROI is matched to more than one coordinate, find the nearest
        % one and exclude the others
        u=unique(j(~isnan(j)));                                         % Extract the unique values of the ROIs
        duplicateCen=u(squeeze(histc(j,u))>1);
        duplicateROIs=find(ismember(j,u(squeeze(histc(j,u))>1)));       % Find the indices of duplicate ROIs

        % Calculate pairwise distances between duplicate ROIs and temp centroids
        % using the same method above
        tD=repmat(tempCenDat(duplicateCen,:),1,1,size(trackDat.Centroid,1));
        c=repmat(trackDat.Centroid,1,1,size(tempCenDat(duplicateCen,:),1));
        c=permute(c,[3 2 1]);
        g=sqrt(dot((c-tD),(tD-c),2));
        g=abs(g);
        [~,k]=min(g,[],3);
        j(duplicateROIs)=NaN;
        j(k)=duplicateCen;

        % Update last known centroid and orientations
        sorting_permutation = j(~isnan(j));
        sorting_permutation = squeeze(sorting_permutation);
        update_centroid=~isnan(j);
    end
    
    out{1} = sorting_permutation;
    out{2} = squeeze(update_centroid);
    
    for i=1:nargout
        varargout{i}=out{i};
    end
        

end
%{
function vars=parseinputvars(invars)

    switch length(invars)
        
        case 2
            % Single sorting mode with no distance thresholding
            vars.cenDat=invars{1};                          % Raw centroid invars
            vars.sort_coords_primary=invars{2};             % Coordinate basis to sort invars to
            vars.sort_num = 'single sort';                        % Specifies only one round of sorting
            vars.thresh_mode_dist=0;                        % No centroids excluded by distance
        case 4
            % Double sorting mode with no distance thresholding
            vars.cenDat=invars{1};                          % Raw centroid invars
            vars.sort_coords_primary=invars{2};             % Primary coordinate basis to sort invars to
            expmt = invars{3};
            vars.sort_coords_secondary=expmt.ROI.centers;   % Secondary coordinate basis to sort invars to
            vars.mmpx = expmt.parameters.mm_per_pix;      % mm/pix conversion factor
            vars.dist_thresh = invars{4}.gui_fig.UserData.distance_thresh;  % threshold for max dist from roi center
            vars.sort_mode = invars{4}.gui_fig.UserData.sort_mode;
            vars.sort_num = 'double sort';                        % Specifies two rounds of sorting
    end
end
    %}    

