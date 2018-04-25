function [tforms,circDat] = transformROI(xdat,ydat)

uSqr = [0 0; 0 1; 1 1; 1 0];
uCirc = [cos(linspace(-pi,pi,30)); sin(linspace(-pi,pi,30))]'./2+0.5;
uCirc = [uCirc; uCirc(end,1) uCirc(end,2)];
[tforms,circDat] = arrayfun(@(x,y) circTrans(x,y,uSqr,uCirc),...
    num2cell(xdat,1),num2cell(ydat,1),'UniformOutput',false);
circDat = permute(cat(3,circDat{:}),[1 3 2]);


function [tform,circDat] = circTrans(x,y,us,uc)

tform = fitgeotrans([x{1}(1:4) y{1}(1:4)],us,'projective');
circDat = transformPointsInverse(tform,uc);

