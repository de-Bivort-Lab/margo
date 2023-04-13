function label_table = labelMaker(expmt)

%%
COLUMN_HEADERS = {'Strain' 'Sex' 'Treatment' 'ID' 'Day' 'Box' 'Tray' 'Comments'};
COLUMN_DEFAULTS = {'' '' '' NaN NaN NaN NaN ''};
labels = expmt.meta.labels;

%Turns labels cell array with sex, strain, treatment, maze start/end
%columns into 120x3 label cell array for Y-maze

% query which cells have entries
hasData = ~cellfun('isempty',labels);
labels(~any(hasData,2),:) = [];
hasData(~any(hasData,2),:) = [];

% create default labels and label ranges if none are entered
if any(any(hasData)) && ~any(hasData(:,4))
    labels(1,4) = {1};
    labels(1,5) = {size(expmt.meta.roi.centers,1)};
    labels(1,6) = {1};
    labels(1,7) = {size(expmt.meta.roi.centers,1)};
    hasData = ~cellfun('isempty',labels);
end

nRows = sum(any(hasData,2));            % num rows with data
active_fields = any(hasData,1);                  % logical vector showing which fields have entries

if ischar(labels{1,4})
    mazeStarts=str2double(labels{1:nRows,4});
else
    mazeStarts=[labels{1:nRows,4}];
end
mazeStarts(isnan(mazeStarts)) = [];

if ischar(labels{1,5})
    mazeEnds=str2double(labels{1:nRows,5});
else
    mazeEnds=[labels{1:nRows,5}];
end

mazeEnds(isnan(mazeEnds)) = [];
active_fields(4:6)=[];
newLabel = repmat(COLUMN_DEFAULTS(active_fields), expmt.meta.roi.n, 1);
iCol = 1;
nRows = numel(mazeStarts);  

for i = 1:nRows
    
    % specify range
    d = mazeEnds(i) - mazeStarts(i);
    
    % strain info
    if any(strcmpi('Strain',COLUMN_HEADERS(active_fields)))
        newLabel(mazeStarts(i):mazeEnds(i),iCol) = repmat(labels(i,1), d+1, 1);
        iCol = iCol+1;
    end
    % sex
    if any(strcmpi('Sex',COLUMN_HEADERS(active_fields)))
        newLabel(mazeStarts(i):mazeEnds(i),iCol) = repmat(labels(i,2), d+1, 1);
        iCol = iCol+1;
    end
    % treatment
    if any(strcmpi('Treatment',COLUMN_HEADERS(active_fields)))
        newLabel(mazeStarts(i):mazeEnds(i),iCol) = repmat(labels(i,3), d+1, 1);
        iCol = iCol+1;
    end
    
    % IDs
    if ~isempty(labels{i,6}) && ~isempty(labels{i,7}) &&...
            any(strcmpi('ID',COLUMN_HEADERS(active_fields)))
        if ischar(labels{i,6})
            f = str2double(labels{i,6});
        else
            f = labels{i,6};
        end
        if ischar(labels{i,7})
            t = str2double(labels{i,7});
        else
            t = labels{i,7};
        end
        newLabel(mazeStarts(i):mazeEnds(i),iCol)=num2cell(f:t);
        iCol = iCol+1;
    end
    
    
    if any(strcmpi('Day',COLUMN_HEADERS(active_fields)))
        if ischar(labels{i,8})
            f = str2double(labels{i,8});
        else
            f = labels{i,8};
        end
        newLabel(mazeStarts(i):mazeEnds(i),iCol)=num2cell(repmat(f,d+1,1));
        iCol = iCol+1;
    end
    
    if ~isempty(labels{i,9}) && any(strcmpi('Box',COLUMN_HEADERS(active_fields)))
        if ischar(labels{i,9})
            f = str2double(labels{i,9});
        else
            f = labels{i,9};
        end
        newLabel(mazeStarts(i):mazeEnds(i),iCol) = repmat({f},d+1,1);
        iCol = iCol+1;
    end
    
    if any(strcmpi('Tray',COLUMN_HEADERS(active_fields)))
        if ischar(labels{i,10})
            f = str2double(labels{i,10});
        else
            f = labels{i,10};
        end
        newLabel(mazeStarts(i):mazeEnds(i),iCol) = repmat({f},d+1,1);
        iCol = iCol+1;
    end
    
    if any(strcmpi('Comments',COLUMN_HEADERS(active_fields)))
        newLabel(mazeStarts(i):mazeEnds(i),iCol) = repmat(labels(i,11),d+1,1);
        iCol = iCol+1;
    end
    
    iCol = 1;
end

emptyRows = all(cellfun(@isempty, newLabel), 2);
newLabel(emptyRows, :) = [];

label_table = cell2table(newLabel,'VariableNames',COLUMN_HEADERS(active_fields));