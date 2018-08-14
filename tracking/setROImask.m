function expmt = setROImask(expmt)

%% create a single mask for all ROIs in the image
switch expmt.meta.roi.mode    
    case 'grid'
       
        nGrids = max(unique(expmt.meta.roi.grid));
        pixList = [];
        xdat = [];
        ydat = [];
        hAdd = findobj('Tag','add_ROI_pushbutton');

        for i=1:nGrids
            
            % vertices
            xdat = [xdat hAdd.UserData.grid(i).XData];
            ydat = [ydat hAdd.UserData.grid(i).YData];

        end
        
        % get pixel indices for each individual ROI
        xdat = num2cell(xdat,1);
        ydat = num2cell(ydat,1);
        expmt.meta.roi.pixIdx = cellfun(@(x,y,z) ...
            getGridROIPixels(x,y,z,size(expmt.meta.roi.im)), xdat,ydat,...
            num2cell(expmt.meta.roi.vec,[2 3])','UniformOutput',false)';  

    case 'auto'
        
       expmt.meta.roi.pixIdx = cellfun(@(x) getBoundsPixels(x,...
           size(expmt.meta.roi.im)),num2cell(expmt.meta.roi.corners,2),...
           'UniformOutput',false);

end

mask = false(size(expmt.meta.roi.im));
pii = cat(1,expmt.meta.roi.pixIdx{:});
mask(pii)=true;

expmt.meta.roi.mask = mask;



function pL = getBoundsPixels(corners,dim)

 corners = [floor(corners(1:2)) ceil(corners(3:4))];
 corners(corners==0) = 1;
 [x,y] = meshgrid(corners(1):corners(3),corners(2):corners(4));
 pL = [x(:) y(:)];
 pL = sub2ind(dim,pL(:,2), pL(:,1));
 
 
 function pi = getGridROIPixels(x,y,vec,dim)

pi = [];
     
% get corners
c = NaN(4,2);
c(:,1) = x([1,4,2,3]);
c(:,2) = y([1,4,2,3]);

% get pixel lists for each vector    
y = (floor(c(1,2)):ceil(c(3,2)))';      % left line
xL = round(vec(1,2,1).*y + vec(1,2,2));
pi = [pi; xL y];

y = (floor(c(2,2)):ceil(c(4,2)))';      % right line
xR = round(vec(1,4,1).*y + vec(1,4,2));
pi = [pi; xR y];

x = (floor(c(1,1)):ceil(c(2,1)))';      % upper line
yT = round(vec(1,1,1).*x + vec(1,1,2));
pi = [pi; x yT];

x = (floor(c(3,1)):ceil(c(4,1)))';      % bottom line
yB = round(vec(1,3,1).*x + vec(1,3,2));
pi = [pi; x yB];
pi(pi<1)=1;
oob = pi(:,2) > dim(1);
pi(oob,2) = dim(1);
oob = pi(:,1) > dim(2);
pi(oob,1) = dim(2);
pi = sub2ind(dim,pi(:,2),pi(:,1));

mask = false(dim);
mask(pi)=true;
mask = imfill(mask,'holes');
pi = regionprops(mask,'PixelIdxList');
pi = pi.PixelIdxList;



