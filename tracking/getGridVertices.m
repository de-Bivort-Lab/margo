function [XData,YData,varargout]=getGridVertices(xPlate,yPlate,nRow,nCol)

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
XData = cat(2,xVecs{:});
YData = cat(2,yVecs{:});

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
    mCol = dc(:,2)./dc(:,1);
    
    % intercepts
    vr=cat(1,vr{:});
    vr=vr(mod(1:size(vr,1),2)==1,:);
    bRow = vr(:,2)-mRow.*vr(:,1);
    vc=cat(1,vc{:});
    vc=vc(mod(1:size(vc,1),2)==1,:);
    bCol = vc(:,2)-mCol.*vc(:,1);
    
    gridVec.row = [mRow bRow];
    gridVec.col = [mCol bCol];
    
    
    varargout(1)={gridVec};
end


function vec = initializeVectors(c1,c2,n)

vec = NaN(n,2);
vec(:,1) = linspace(c1(1),c2(1),n);
vec(:,2) = linspace(c1(2),c2(2),n);

function [xData,yData] = getVertices(n,vc,nc)

row = ceil(n/nc);
col = mod(n-1,nc)+1;
xData = [vc{row}(col,1); vc{row+1}(col,1); ...
    vc{row+1}(col+1,1); vc{row}(col+1,1); vc{row}(col,1)];
yData = [vc{row}(col,2); vc{row+1}(col,2); ...
    vc{row+1}(col+1,2); vc{row}(col+1,2); vc{row}(col,2)];



    

