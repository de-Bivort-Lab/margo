function [centers]=getGridVertices(xPlate,yPlate,nRow,nCol)

%Get vertices coordinates
uR=[xPlate(1) yPlate(1)];
bR=[xPlate(2) yPlate(2)];
bL=[xPlate(3) yPlate(3)];
uL=[xPlate(4) yPlate(4)];

% initialize boundary vectors
nRow = 8;
nCol = 12;
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
[xData,yData] = cellfun(@(x) ...
    getVertices(x,vertCoords,nCol),num2cell(1:nRow*nCol),'UniformOutput',false);



function vec = initializeVectors(c1,c2,n)

vec = NaN(n,2);
vec(:,1) = linspace(c1(1),c2(1),n);
vec(:,2) = linspace(c1(2),c2(2),n);

function [xData,yData] = getVertices(n,vc,nc)

row = ceil(n/nc);
col = mod(n-1,12)+1;
xData = [vc{row}(col,1); vc{row+1}(col,1); ...
    vc{row+1}(col+1,1); vc{row}(col+1,1); vc{row}(col,1)];
yData = [vc{row}(col,2); vc{row+1}(col,2); ...
    vc{row+1}(col+1,2); vc{row}(col+1,2); vc{row}(col,2)];

    


