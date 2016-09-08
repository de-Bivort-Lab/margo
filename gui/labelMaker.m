function out = labelMaker(labels, varargin)

%Turns labels cell array with sex, strain, treatment, maze start/end
%columns into 120x3 label cell array for Y-maze

r = sum(~cellfun('isempty',labels(:,4)));
newLabel = cell(120,5);
mazeStarts=str2double(labels(:,4));
mazeEnds=str2double(labels(:,5));

for i = 1:r;
    d = mazeEnds(i) - mazeStarts(i);
    newLabel(mazeStarts(i):mazeEnds(i),1) = repmat(labels(i,1), d+1, 1);
    if isempty(labels(i,2)) == 0;
        newLabel(mazeStarts(i):mazeEnds(i),2) = repmat(labels(i,2), d+1, 1);
    end
    if isempty(labels(i,3)) == 0;
        newLabel(mazeStarts(i):mazeEnds(i),3) = repmat(labels(i,3), d+1, 1);
    end
    if ~isempty(labels(i,6)) && ~isempty(labels(i,7))
    newLabel(mazeStarts(i):mazeEnds(i),4)=num2cell(str2double(labels{i,6}):str2double(labels{i,7}));
    end
    if size(labels,2)==8
    newLabel(mazeStarts(i):mazeEnds(i),5)=repmat({str2double(labels(i,8))},d+1,1);
    end
end

out = newLabel;