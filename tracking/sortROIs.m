function [ROI_coords,mazeOri,ROI_bounds,centers]=sortROIs(ROI_coords,mazeOri,centers,ROI_bounds)

%% Separate right-side down ROIs (0) from right to left

tmpCoords_0=centers(~mazeOri,:);     % Center coords for upside down maze
x=tmpCoords_0(:,1).^2;               % Square coordinates in x to exaggerate distance between ROIs
[val,xSorted]=sort(x);               % Sort ROI xCoords from left to right
numRows=mode(diff(find(diff(val)>std(diff(val))==1))); % Get estimate from number of rows of mazes

if isnan(numRows)
    numRows=1;
end
if mod(length(xSorted),numRows)~=0
    % Add placeholders if there are an unequal number of ROIs in each ROI
    xSorted=[xSorted;ones(numRows-mod(length(xSorted),numRows),1)];
end

% Reshape xCoords so that mazes in the same column on the tray
% are in the same column of the matrix
xSorted=reshape(xSorted,numRows,floor(length(xSorted)/numRows));

permutation_0=[];    % Initialize permutation vector for upside down Ys

% Repeat sorting process one by one for each column to sort
% ROIs by their y coordinates
for i=1:size(xSorted,2)
y=tmpCoords_0(xSorted(:,i),2).^2;
[~,ySorted]=sort(y);
xSorted(:,i)=xSorted(ySorted,i);
    if sum(xSorted(ySorted,i)==1)>1
    xSorted(xSorted(:,i)==1,i)=NaN;
    end
end

% Linearize permutation vector and delete placeholder entries
permutation_0=reshape(xSorted',numel(xSorted),1);
permutation_0(isnan(permutation_0))=[];

%% Separate right-side up ROIs (1) from right to left
permutation_1=[];

if sum(mazeOri)>0
tmpCoords_1=centers(mazeOri,:);                         % Center coords for rightside-up Y
x=tmpCoords_1(:,1).^2;                                  % Square coordinates in x to exaggerate distance between ROIs
[val,xSorted]=sort(x);                                  % Sort ROI xCoords from left to right
numRows=mode(diff(find(diff(val)>std(diff(val))==1)));  % Get estimate from number of rows of mazes

if isnan(numRows)
    numRows=1;
end
if mod(length(xSorted),numRows)~=0
    % Add placeholders if there are an unequal number of ROIs in each ROI
    xSorted=[xSorted;ones(numRows-mod(length(xSorted),numRows),1)];
end

% Reshape xCoords so that mazes in the same column on the tray
% are in the same column of the matrix
xSorted=reshape(xSorted,numRows,floor(length(xSorted)/numRows));

% Repeat sorting process one by one for each column to sort
% ROIs by their y coordinates
for i=1:size(xSorted,2)
y=tmpCoords_1(xSorted(:,i),2).^2;
[~,ySorted]=sort(y); 
xSorted(:,i)=xSorted(ySorted,i);
end
permutation_1=reshape(xSorted',numel(xSorted),1);
permutation_1=permutation_1+size(permutation_0,1);

% Sort coordinates into mazeOri=0 and mazeOri=1 categories for
% to align with permutation_0 and permutation_0 vectors when they are
% concatenated
centers=[tmpCoords_0;tmpCoords_1];
tmpROI_0=ROI_coords(~mazeOri,:);
tmpROI_1=ROI_coords(mazeOri,:);
ROI_coords=[tmpROI_0;tmpROI_1];
tmpBounds_0=ROI_bounds(~mazeOri,:);
tmpBounds_1=ROI_bounds(mazeOri,:);
ROI_bounds=[tmpBounds_0;tmpBounds_1];
end

% Define master permutation vector and sort ROI_coords
permutation=[permutation_0;permutation_1];

% Delete any excess placeholder ROIs
excess=find(permutation==1);
    if length(excess)>1
        permutation(excess(2:end))=[];
    end
permutation(permutation>size(ROI_coords,1))=permutation(permutation>size(ROI_coords,1))-(max(permutation)-size(ROI_coords,1));

% Sort ROI and center coords by the permutation vector defined
ROI_coords=ROI_coords(permutation,:);
ROI_bounds=ROI_bounds(permutation,:);
centers=centers(permutation,:);

% Sort mazeOri to match new ROI_coords permutation
mazeOri(1:size(permutation_0,1))=0;
mazeOri(size(permutation_0,1)+1:size(permutation,1))=1;
mazeOri=logical(mazeOri);

end



