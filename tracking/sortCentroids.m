function [varargout]= sortCentroids(raw_cen, trackDat, expmt)

%   This function sorts centroid coordinates based on the pairwise distance to  
%   respective ROIs and outputs a permutation vector
%
%   MODES: 'distance', 'grid'
%
%   'distance'  ->  refines centroid/ROI assignments by distance to ROI center
%
%   'bounds'    ->  refines centroid/ROI assignments by inclusion in the
%                   bounds of the ROI. Bound inclusion is further
%                   sub-divided into different modes depending on ROI shape  
%
%   SYNTAX 
%               ->  [permutation,update,raw] = sortCentroids(raw, trackDat, expmt)
%
%   INPUTS
%
%   raw_cen     ->  unsorted Nx2 centroid coordinates output from region props
%
%   trackDat    ->  tracking data struct containing last recorded position of 
%                   each ROI trace
%
%   expmt       -> 	master ExperimentData container containing ROI coordinates
%                   and mode parameters
%
%   OUTPUTS
%
%   permutation ->  permutation vector of indices of raw_cen to sort by ROI number
%
%   update      ->  logical nROIx1 vector specifying which ROIs were
%                   matched with a raw_cen coordinate
%
%   raw_cen     ->  updated raw_cen vector with elements unmatched to any 
%                   ROI removed            
%
%

% Define placeholder data variables equal to number ROIs
tempCenDat=NaN(size(trackDat.centroid,1),2);

% Initialize temporary centroid variables
tempCenDat(1:size(raw_cen,1),:)=raw_cen;

% Find nearest Last Known centroid for each current centroid
% Replicate temp centroid data into dimensions compatible with dot product
% with the last known centroid of each fly
tD=repmat(tempCenDat,1,1,size(trackDat.centroid,1));
c=repmat(trackDat.centroid,1,1,size(tempCenDat,1));
c=permute(c,[3 2 1]);

% Use dot product to calculate pairwise distance between all coordinates
g=sqrt(dot((c-tD),(tD-c),2));
g=abs(g);

% Returns minimum distance to each previous centroid and the indces (j)
% Of the temp centroid with that distance
[~,j]=min(g);

% Initialize empty placeholders for permutation and inclusion vectors
sorting_permutation=[];
update_centroid = false(size(trackDat.centroid,1),1);

    % For the centroids j, calculate speed and distance to ROI center for thresholding
    if size(raw_cen,1)>0 
        
        switch expmt.parameters.sort_mode
            
          case 'distance'
                
            % Calculate distance to known landmark such as the ROI center
            secondary_distance = ...
                abs(sqrt(dot(raw_cen(j,:)'-expmt.meta.roi.centers',...
                    expmt.meta.roi.centers'-raw_cen(j,:)')))';

            % Exclude centroids that move too fast or are too far from the ROI center
            % corresponding to the previous centroid each item in j, was matched with
            mismatch = ...
                secondary_distance .* expmt.parameters.mm_per_pix >...
                    expmt.parameters.distance_thresh;
            j(mismatch)=NaN;
            
            % If the same ROI is matched to more than one coordinate,
            %  find the nearest one and exclude the others
            u=unique(j(~isnan(j)));                                        
            duplicateCen = u(squeeze(histc(j,u))>1);
            duplicateROIs = ismember(j,u(squeeze(histc(j,u))>1));    

            % Calculate pairwise distances between duplicate ROIs and temp centroids
            % using the same method above
            tD=repmat(tempCenDat(duplicateCen,:),1,1,size(trackDat.centroid,1));
            c=repmat(trackDat.centroid,1,1,size(tempCenDat(duplicateCen,:),1));
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
        
        
          case 'bounds'  
              
            switch expmt.parameters.roi_mode    
               case 'grid'
                 % find candidate ROIs for each centroid
                 ROI_num = arrayfun(@(x) ...
                     gridAssignROI(x,expmt.meta.roi.vec,expmt.meta.roi.shape,expmt.meta.roi.tform),...
                     num2cell(raw_cen,2),'UniformOutput',false);
                 
               case 'auto'
                 ROI_num = cellfun(@(x) ...
                     autoAssignROI(x,expmt.meta.roi.corners),...
                     num2cell(raw_cen,2),'UniformOutput',false);
            end
             
             % remove centroids out of bounds of any ROI
             filt = cellfun(@isempty,ROI_num);
             raw_cen(filt,:)=[];
             ROI_num(filt)=[];            
             
             % check for centroids with more than one ROI assigned
             dupROIs = cellfun(@length,ROI_num)>1;
             if any(dupROIs)
                 
                 % find ROI with nearest last centroid to each raw_cen                
                 ROI_num(dupROIs) = ...
                     cellfun(@(x,y) closestCentroid(x,y,trackDat.centroid),...
                        num2cell(raw_cen(dupROIs,:),2),...
                        ROI_num(dupROIs),'UniformOutput',false);
                 
             end   
              
             % find ROIs with more than one centroid assignment
             ROI_num = cat(2,ROI_num{:});    
             hasDupCen = find(histc(ROI_num,1:expmt.meta.roi.n)>1);
             if ~isempty(hasDupCen)
                dupCenIdx = arrayfun(@(x) find(ismember(ROI_num,x)),...
                                hasDupCen,'UniformOutput',false);
                [~,discard] = cellfun(@(x,y) closestCentroid(x,y,raw_cen),...
                                    num2cell(trackDat.centroid(hasDupCen,:),2),...
                                    dupCenIdx','UniformOutput',false);
                ROI_num(cat(2,discard{:}))=[];
                raw_cen((cat(2,discard{:})),:)=[];
             end
             
             % assign outputs for sorting data
             [~,sorting_permutation] = sort(ROI_num);
             update_centroid = ismember((1:expmt.meta.roi.n)',ROI_num);
           
        end
    end
   
    % assign outputs
    varargout = cell(3,1);
    for i=1:nargout
        switch i
            case 1, varargout(i) = {sorting_permutation};
            case 2, varargout(i) = {squeeze(update_centroid)};
            case 3, varargout(i) = {raw_cen};
        end
    end
        

end


function ROI_num = gridAssignROI(cen,gv,shape,tf)

    % get the bounds for each ROI at
    % current x and y position
    cen=cen{1};
    xL = cen(1) > gv(:,2,1).*cen(2) + gv(:,2,2);
    xR = cen(1) < gv(:,4,1).*cen(2) + gv(:,4,2);
    yT = cen(2) > gv(:,1,1).*cen(1) + gv(:,1,2);
    yB = cen(2) < gv(:,3,1).*cen(1) + gv(:,3,2);
    
    % identify matching ROI, if any
    in_bounds = xL & xR & yT & yB;
    ROI_num = find(in_bounds);

    % use projective transform if roi shape is circular
    iscirc = strcmp(shape(ROI_num),'Circular');
    if any(iscirc)
        uc = cellfun(@(x) ...
            transformPointsForward(x,cen),...
            tf(ROI_num(iscirc)),'UniformOutput',false);
        uc = cat(1,uc{1});
        if sqrt((uc(1)-0.5).^2 + (uc(2)-0.5).^2) > 0.5
            ROI_num = [];
        end
    end

end


function ROI_num = autoAssignROI(cen,b)

    % get the bounds for each ROI at
    % current x and y position
    xL = cen(1) > b(:,1);
    xR = cen(1) < b(:,3);
    yT = cen(2) > b(:,2);
    yB = cen(2) < b(:,4);
    
    % identify matching ROI, if any
    in_bounds = xL & xR & yT & yB;
    ROI_num = find(in_bounds);   

end


function [candidate_idx,no_match] = closestCentroid(target_cen,candidate_idx,candidate_cen)
    
% find the candidate centroid closest to the target centroid

% restrict the list of candidates to the indices in candidate idx
candidate_cen = candidate_cen(candidate_idx,:);

% find index for candidate with minimum distance to target
[~,j] = min(sqrt((target_cen(1)-candidate_cen(:,1)).^2 +...
    (target_cen(2)-candidate_cen(:,2)).^2));
no_match = candidate_idx(candidate_idx~=candidate_idx(j));
candidate_idx = candidate_idx(j);

end

