function [centers]=getGridCoords(xPlate,yPlate,nRow,nCol)

%Get vertices coordinates
uR=[xPlate(1) yPlate(1)];
bR=[xPlate(2) yPlate(2)];
bL=[xPlate(3) yPlate(3)];
uL=[xPlate(4) yPlate(4)];

% initialize boundary vectors
vec = NaN(4,2);
vec(1,:) = [(uR(1)-uL(1)) (uR(2)-uL(2))];   % top vector
vec(2,:) = [(bR(1)-bL(1)) (bR(2)-bL(2))];   % bottom vector
vec(3,:) = [(bL(1)-uL(1)) (bL(2)-uL(2))];   % left vector
vec(4,:) = [(bR(1)-uR(1)) (bR(2)-uR(2))];   % right vector
    
% get col vectors
topx = linspace(0,vec(1,1),nCol);
botx = vec(3,1) + linspace(0,vec(2,1),nCol);
topy = linspace(0,vec(1,2),nCol);
boty = vec(3,2) + linspace(0,vec(2,2),nCol);
cVecs = [(botx-topx)' (boty-topy)'];

% get row vector
rVec = vec(1,:);

% fraction of width and height for each well
wfrac = linspace(0,1,nCol);
hfrac = linspace(0,1,nRow);

centers = NaN(nRow*nCol,2);
x = NaN(nRow,nCol);
x = uL(1) + repmat(cVecs(:,1)',nRow,1).*repmat(hfrac',1,nCol) + ...
    repmat(rVec(1),nRow,nCol).*repmat(wfrac,nRow,1);
x = x';
y = NaN(nRow,nCol);
y = uL(2) + repmat(cVecs(:,2)',nRow,1).*repmat(hfrac',1,nCol) + ...
    repmat(rVec(2),nRow,nCol).*repmat(wfrac,nRow,1);
y = y';

centers(:,1) = x(:);
centers(:,2) = y(:);


