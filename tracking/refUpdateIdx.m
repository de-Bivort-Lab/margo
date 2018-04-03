function [expmt,trackDat] = refUpdateIdx(expmt,trackDat)


% Calculate distance to previous locations where references were taken
tcen = repmat(trackDat.Centroid,1,1,expmt.parameters.ref_depth);
d = abs(sqrt(dot((tcen-trackDat.ref.cen),(trackDat.ref.cen-tcen),2)));
include = sum(d > trackDat.ref.thresh,3)>trackDat.ref.ct-1;
[~,refIdx]=min(d,[],3);
refIdx(trackDat.ref.ct<expmt.parameters.ref_depth) = ...
    trackDat.ref.ct(trackDat.ref.ct<expmt.parameters.ref_depth) + 1;
refIdx(~include)=0;
trackDat.ref.ct(include) = trackDat.ref.ct(include)+1;
trackDat.ref.ct(trackDat.ref.ct>expmt.parameters.ref_depth) = ...
    expmt.parameters.ref_depth;

% group pixel indices by which sub reference they update
pixLists = arrayfun(@(x) getPixIdxLists(x,refIdx,expmt.ROI.pixIdx),1:size(d,3),...
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
    trackDat.ref.cen(updateIdx)=trackDat.Centroid(include,:);
end



function pL = getPixIdxLists(refNum,refIdx,pixIdx)

pL = pixIdx(refIdx==refNum);
pL = cat(1,pL{:});


function ref = updateSubRef(pL,ref,im)

ref(pL) = im(pL);
