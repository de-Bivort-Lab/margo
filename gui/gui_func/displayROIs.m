function hPatch = displayROIs(hPatch,corners)

% get current patch face coordinates
vx = hPatch.XData;
vy = hPatch.YData;

% query new x vertices
r = repmat(1:size(corners,1),5,1);
c = repmat([1 1 3 3 1]',1,size(corners,1));
vxi = corners(sub2ind(size(corners),r(:),c(:)));
vxi = reshape(vxi,5,numel(vxi)/5);

% query new y vertices
c = repmat([2 4 4 2 2]',1,size(corners,1));
vyi = corners(sub2ind(size(corners),r(:),c(:)));
vyi = reshape(vyi,5,numel(vyi)/5);

% update patch vertices if num ROIs changed or 
% if any coordinates have changed
if numel(vxi) ~= numel(vx) || any(vx(:)~=vxi(:)) || any(vy(:)~=vyi(:))
    hPatch.XData = vxi;
    hPatch.YData = vyi;
end

