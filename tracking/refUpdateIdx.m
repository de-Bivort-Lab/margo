function [expmt,trackDat] = refUpdateIdx(expmt,trackDat)


% Calculate distance to previous locations where references were taken
tcen = repmat(trackDat.centroid,1,1,expmt.parameters.ref_depth);
d = abs(sqrt(dot((tcen-trackDat.ref.cen),(trackDat.ref.cen-tcen),2)));
include = sum(d > trackDat.ref.thresh,3)>trackDat.ref.ct-1;
[~,refIdx]=min(d,[],3);
refIdx(trackDat.ref.ct<expmt.parameters.ref_depth) = ...
    trackDat.ref.ct(trackDat.ref.ct<expmt.parameters.ref_depth) + 1;

% look for individually noisy ROIs
if isfield(expmt.noise,'dist') && isfield(expmt.meta.noise,'roi_mean')
    above_thresh = cellfun(@(x) sum(trackDat.thresh_im(x)),expmt.meta.roi.pixIdx) >...
        (expmt.meta.noise.roi_mean + expmt.meta.noise.roi_std * 4);
    trackDat.ref.ct(above_thresh & ...
        trackDat.ref.ct == expmt.parameters.ref_depth) = 0;
    include = include | above_thresh;
    
    ref_freq = findobj('Tag','edit_ref_freq');
    force_update = trackDat.ref.last_update >  ref_freq.Value * 60 * 3; 
    force_update = force_update & ~include;
    if any(force_update) && ref_freq.Value > 1/120
        include = include | force_update;
        trackDat.ref.ct(force_update & ...
            trackDat.ref.ct == expmt.parameters.ref_depth) = 0;
    end
end


    



refIdx(~include)=0;
trackDat.ref.ct(include) = trackDat.ref.ct(include)+1;
trackDat.ref.ct(trackDat.ref.ct>expmt.parameters.ref_depth) = ...
    expmt.parameters.ref_depth;
trackDat.ref.last_update(include)  = 0;

% group pixel indices by which sub reference they update
pixLists = arrayfun(@(x) getPixIdxLists(x,refIdx,expmt.meta.roi.pixIdx),1:size(d,3),...
    'UniformOutput',false);

trackDat.ref.stack = cellfun(@(x,y) updateSubRef(x,y,trackDat.im),pixLists',...
    trackDat.ref.stack,'UniformOutput',false);

trackDat.ref.im = median(cat(3,trackDat.ref.stack{:}),3);

% update reference centroid positions
if any(include)
    n = sum(include);
    updateIdx = repmat([find(include) ones(n,1).*2 refIdx(include)],2,1);
    updateIdx(1:n,2)=1;
    updateIdx = sub2ind(size(trackDat.ref.cen),updateIdx(:,1),updateIdx(:,2),updateIdx(:,3));
    trackDat.ref.cen(updateIdx)=trackDat.centroid(include,:);
end



function pL = getPixIdxLists(refNum,refIdx,pixIdx)

pL = pixIdx(refIdx==refNum);
pL = cat(1,pL{:});


function ref = updateSubRef(pL,ref,im)

ref(pL) = im(pL);
