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

% Assign default outputs
sorting_permutation=[];
update_centroid = false(size(trackDat.centroid,1),1);
varargout = cell(3,1);

% skip sorting if no blobs are detected
if isempty(raw_cen)
    for i=1:nargout
        switch i
            case 1, varargout(i) = {sorting_permutation};
            case 2, varargout(i) = {squeeze(update_centroid)};
            case 3, varargout(i) = {raw_cen};
        end
    end
    return
end

% assign an ROI number to each blob
ROI_num = assignROI(raw_cen, expmt);
             
% remove centroids out of bounds of any ROI
filt = cellfun(@isempty,ROI_num);
raw_cen(filt,:)=[];
ROI_num(filt)=[];            

% check for centroids with more than one ROI assigned
dupROIs = cellfun(@length,ROI_num)>1;
if any(dupROIs)

% find ROI with nearest last centroid to each raw_cen                
ROI_num(dupROIs) = ...
     cellfun(@(x,y) closestCentroid(x,y,expmt.meta.roi.centers),...
        num2cell(raw_cen(dupROIs,:),2),...
        ROI_num(dupROIs),'UniformOutput',false);

end   

% find ROIs with more than one centroid assignment
ROI_num = cat(1,ROI_num{:});    
hasDupCen = find(histc(ROI_num,1:expmt.meta.roi.n)>1);
if ~isempty(hasDupCen)
    dupCenIdx = arrayfun(@(x) find(ismember(ROI_num,x)),...
                    hasDupCen,'UniformOutput',false);
    [~,discard] = cellfun(@(x,y) closestCentroid(x,y,raw_cen),...
                        num2cell(trackDat.centroid(hasDupCen,:),2),...
                        dupCenIdx,'UniformOutput',false);
    ROI_num(cat(1,discard{:}))=[];
    raw_cen((cat(1,discard{:})),:)=[];
end

% assign outputs for sorting data
[~,sorting_permutation] = sort(ROI_num);
update_centroid = ismember((1:expmt.meta.roi.n)',ROI_num);
           
   
% assign outputs
for i=1:nargout
    switch i
        case 1, varargout(i) = {sorting_permutation};
        case 2, varargout(i) = {squeeze(update_centroid)};
        case 3, varargout(i) = {raw_cen};
    end
end
        


function [can_idx,no_match] = closestCentroid(tar_cen,can_idx,can_cen)
    
% find the candidate centroid closest to the target centroid

% restrict the list of candidates to the indices in candidate idx
can_cen = can_cen(can_idx,:);

% find index for candidate with minimum distance to target
[~,j] = min(sqrt((tar_cen(1)-can_cen(:,1)).^2 + (tar_cen(2)-can_cen(:,2)).^2));
no_match = can_idx(can_idx ~= can_idx(j));
can_idx = can_idx(j);



