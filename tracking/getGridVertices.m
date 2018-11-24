function [XData, YData, varargout] = ...
    getGridVertices(xPlate, yPlate, nRow, nCol, roi_scale)

%Get vertices coordinates
uR=[xPlate(1) yPlate(1)];
bR=[xPlate(2) yPlate(2)];
bL=[xPlate(3) yPlate(3)];
uL=[xPlate(4) yPlate(4)];

% initialize boundary vectors
L = NaN(nRow+1,2);
L(:,1) = linspace(uL(1),bL(1),nRow+1);
L(:,2) = linspace(uL(2),bL(2),nRow+1);
R = NaN(nRow+1,2);
R(:,1) = linspace(uR(1),bR(1),nRow+1);
R(:,2) = linspace(uR(2),bR(2),nRow+1);

% convert to cell
R=num2cell(R,2);
L=num2cell(L,2);

vertCoords = cellfun(@(x,y) initializeVectors(x,y,nCol+1),L,R,'UniformOutput',false);
[xVecs,yVecs] = cellfun(@(x) ...
    getVertices(x,vertCoords,nCol),num2cell(1:nRow*nCol),'UniformOutput',false);

% rescale rois
if roi_scale < 1
   [xVecs, yVecs] = cellfun(@(x,y) scale_roi_vertices(x, y, roi_scale), xVecs, yVecs,...
       'UniformOutput',false);
end

XData = cat(2,xVecs{:});
YData = cat(2,yVecs{:});

% output slope and bounds for calculating bounds for each ROI
if nargout==3
    
    T = NaN(nCol+1,2);
    T(:,1) = linspace(uL(1),uR(1),nCol+1);
    T(:,2) = linspace(uL(2),uR(2),nCol+1);
    B = NaN(nCol+1,2);
    B(:,1) = linspace(bL(1),bR(1),nCol+1);
    B(:,2) = linspace(bL(2),bR(2),nCol+1);
    
    % convert to cell
    B=num2cell(B,2);
    T=num2cell(T,2);
    
    % calculate change in x and y for each vector
    vr = cellfun(@(x,y) initializeVectors(x,y,2),L,R,'UniformOutput',false);
    dr = cellfun(@(x) diff(x,1),vr,'UniformOutput',false);
    dr = cat(1,dr{:});   
    vc = cellfun(@(x,y) initializeVectors(x,y,2),T,B,'UniformOutput',false);
    dc = cellfun(@(x) diff(x,1),vc,'UniformOutput',false);
    dc = cat(1,dc{:});
    
    % slope
    mRow = dr(:,2)./dr(:,1);
    mCol = dc(:,1)./dc(:,2);
    
    % intercepts
    vr=cat(1,vr{:});
    vr=vr(mod(1:size(vr,1),2)==1,:);
    bRow = vr(:,2)-mRow.*vr(:,1);
    vc=cat(1,vc{:});
    vc=vc(mod(1:size(vc,1),2)==1,:);
    bCol = vc(:,1)-mCol.*vc(:,2);
    
    gridVec.row = [mRow bRow];
    gridVec.col = [mCol bCol];
    
    [m,b] = arrayfun(@(x) getLinearParams(x,gridVec.row,gridVec.col,nCol),...
        1:nRow*nCol,'UniformOutput',false);
    gridVec = cat(1,m{:});
    gridVec(:,:,2)=cat(1,b{:});
    
    varargout(1)={gridVec};
end


function vec = initializeVectors(c1,c2,n)

% c1    - first xy pair
% c2    - second xy pair
% n     - num points to generate

vec = NaN(n,2);
vec(:,1) = linspace(c1(1),c2(1),n);
vec(:,2) = linspace(c1(2),c2(2),n);


function [xData,yData] = getVertices(n,vc,nc)

% n     - ROI number within it's grid (not absolute ROI num)
% vc    - vertices coordinates
% nc    - num columns in the grid

row = ceil(n/nc);
col = mod(n-1,nc)+1;
xData = [vc{row}(col,1); vc{row+1}(col,1); ...
    vc{row+1}(col+1,1); vc{row}(col+1,1); vc{row}(col,1)];
yData = [vc{row}(col,2); vc{row+1}(col,2); ...
    vc{row+1}(col+1,2); vc{row}(col+1,2); vc{row}(col,2)];


function [x, y] = scale_roi_vertices(x,y,scale_factor)

center = [mean(x(1:4)) mean(y(1:4))];
x = scale_factor.*(x-center(1)) + center(1);
y= scale_factor.*(y-center(2)) + center(2);



function [slope,intercepts] = getLinearParams(n,rp,cp,nc)

% n     - ROI number within it's grid (not absolute ROI num)
% rp    - row vector slope and intercepts
% cp    - col vector slope and intercepts
% nc    - num columns in the grid

row = ceil(n/nc);
col = mod(n-1,nc)+1;
slope = [rp(row,1) cp(col,1) rp(row+1,1) cp(col+1,1)];
intercepts = [rp(row,2) cp(col,2) rp(row+1,2) cp(col+1,2)];




    


