function [expmt,trackDat] = refUpdateIdx(expmt,trackDat)

% Calculate distance to previous locations where references were taken
nref = expmt.parameters.ref_depth;
tcen = arrayfun(@(c) repmat(c.cen,1,1,nref),...
    trackDat.traces,'UniformOutput',false);

d = cellfun(@(x,y) abs(sqrt(dot((x-y),...
           (y-x),2))),tcen,trackDat.ref.cen,'UniformOutput',false);
include = cellfun(@(dist,ct) median(sum(dist > trackDat.ref.thresh,3)) > ...
    ct, d, num2cell(trackDat.ref.ct-1));
[~,refIdx] = cellfun(@(x) min(x,[],3), d, 'UniformOutput', false);
refIdx = cellfun(@mode,refIdx);
refIdx(trackDat.ref.ct<nref) = ...
    trackDat.ref.ct(trackDat.ref.ct<nref)+ 1;

% look for individually noisy ROIs
if isfield(expmt.meta.noise,'dist') && isfield(expmt.meta.noise,'roi_mean')
    above_thresh = cellfun(@(x) sum(trackDat.thresh_im(x)),expmt.meta.roi.pixIdx) >...
        (expmt.meta.noise.roi_mean + expmt.meta.noise.roi_std * 4);
    trackDat.ref.ct(above_thresh & ...
        trackDat.ref.ct == nref) = 0;
%     include = cellfun(@(x) x | above_thresh, include, 'UniformOutput',...
%                       false);
    include = include | above_thresh;
    
    force_update = ...
        trackDat.ref.last_update >  expmt.parameters.ref_freq * 60 * 3; 
    if any(force_update) && expmt.parameters.ref_freq > 1/120
        include = include | force_update;
        trackDat.ref.ct(force_update & ...
            trackDat.ref.ct == nref) = 0;
    end
end

refIdx(~include)=0;
trackDat.ref.ct(include) = trackDat.ref.ct(include)+1;
trackDat.ref.ct(trackDat.ref.ct > nref) = nref;
                      
trackDat.ref.last_update(include) = 0;
                                   
% group pixel indices by which sub reference they update

pixLists = arrayfun(@(x) ...
    getPixIdxLists(x,refIdx,expmt.meta.roi.pixIdx), 1:nref,...
    'UniformOutput',false);

trackDat.ref.stack = cellfun(@(x,y) updateSubRef(x,y,trackDat.im),pixLists',...
    trackDat.ref.stack,'UniformOutput',false);

trackDat.ref.im = median(cat(3,trackDat.ref.stack{:}),3);

% update reference centroid positions
if any(include)

    trackDat.ref.cen = arrayfun(@(rc, t, inc, ref_idx) ...
        updateRefCen(rc, t, inc, ref_idx),...
            trackDat.ref.cen, trackDat.traces, include, refIdx,...
            'UniformOutput', false);
end

    
function pL = getPixIdxLists(refNum,refIdx,pixIdx)
    pL = pixIdx(refIdx==refNum);
    pL = cat(1,pL{:});


function ref = updateSubRef(pL,ref,im)
        ref(pL) = im(pL);
        
function ref_cen = updateRefCen(ref_cen, trace, inc, ref_idx)

ref_cen = ref_cen{1};
if inc
    ref_cen(:,:,ref_idx) = trace.cen;
end



