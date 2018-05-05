function label_table = labelMaker(expmt)

%%
varnames = {'Strain' 'Sex' 'Treatment' 'ID' 'Day' 'Box' 'Tray' 'Comments'};
labels = expmt.labels;

%Turns labels cell array with sex, strain, treatment, maze start/end
%columns into 120x3 label cell array for Y-maze

% query which cells have entries
hasData = ~cellfun('isempty',labels);

% create default labels and label ranges if none are entered
if any(any(hasData)) && ~any(hasData(:,4))
    labels(1,4) = {1};
    labels(1,5) = {size(expmt.ROI.centers,1)};
    labels(1,6) = {1};
    labels(1,7) = {size(expmt.ROI.centers,1)};
    hasData = ~cellfun('isempty',labels);
end

nRows = sum(any(hasData,2));            % num rows with data
active_fields = any(hasData);                  % logical vector showing which fields have entries

if ischar(labels{1,4})
    mazeStarts=str2num(labels{1:nRows,4});
else
    mazeStarts=[labels{1:nRows,4}];
end
mazeStarts(isnan(mazeStarts)) = [];

if ischar(labels{1,5})
    mazeEnds=str2num(labels{1:nRows,5});
else
    mazeEnds=[labels{1:nRows,5}];
end

mazeEnds(isnan(mazeEnds)) = [];
newLabel = cell(sum(mazeEnds-mazeStarts+1),sum(active_fields)-3);
active_fields(4:6)=[];
iCol = 1;


for i = 1:nRows;
    
    d = mazeEnds(i) - mazeStarts(i);
    newLabel(mazeStarts(i):mazeEnds(i),iCol) = repmat(labels(i,1), d+1, 1);
    iCol = iCol+1;
    if ~isempty(labels{i,2})
        newLabel(mazeStarts(i):mazeEnds(i),iCol) = repmat(labels(i,2), d+1, 1);
        iCol = iCol+1;
    end
    
    
    if ~isempty(labels{i,3})
        newLabel(mazeStarts(i):mazeEnds(i),iCol) = repmat(labels(i,3), d+1, 1);
        iCol = iCol+1;
    end
    
    
    if ~isempty(labels{i,6}) && ~isempty(labels{i,7})
        if ischar(labels{i,6})
            f = str2num(labels{i,6});
        else
            f = labels{i,6};
        end
        if ischar(labels{i,7})
            t = str2num(labels{i,7});
        else
            t = labels{i,7};
        end
        newLabel(mazeStarts(i):mazeEnds(i),iCol)=num2cell(f:t);
        iCol = iCol+1;
    end
    
    
    if ~isempty(labels{i,8})
        if ischar(labels{i,8})
            f = str2num(labels{i,8});
        else
            f = labels{i,8};
        end
        newLabel(mazeStarts(i):mazeEnds(i),iCol)=num2cell(repmat(f,d+1,1));
        iCol = iCol+1;
    end
    
    if ~isempty(labels{i,9})
        if ischar(labels{i,9})
            f = str2num(labels{i,9});
        else
            f = labels{i,9};
        end
        newLabel(mazeStarts(i):mazeEnds(i),iCol) = repmat({f},d+1,1);
        iCol = iCol+1;
    end
    
    if ~isempty(labels{i,10})
        if ischar(labels{i,10})
            f = str2num(labels{i,10});
        else
            f = labels{i,10};
        end
        newLabel(mazeStarts(i):mazeEnds(i),iCol) = repmat({f},d+1,1);
        iCol = iCol+1;
    end
    
    if ~isempty(labels{i,11})
        newLabel(mazeStarts(i):mazeEnds(i),iCol) = repmat(labels(i,11),d+1,1);
        iCol = iCol+1;
    end
    
    iCol = 1;
end

label_table = cell2table(newLabel,'VariableNames',varnames(active_fields));