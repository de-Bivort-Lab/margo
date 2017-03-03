function label_table = labelMaker(expmt)

%
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

mazeStarts=str2num(labels{1:nRows,4});
mazeStarts(isnan(mazeStarts)) = [];
mazeEnds=str2num(labels{1:nRows,5});
mazeEnds(isnan(mazeEnds)) = [];
newLabel = cell(sum(mazeEnds-mazeStarts+1),sum(active_fields)-3);
active_fields(4:6)=[];

for i = 1:nRows;
    
    d = mazeEnds(i) - mazeStarts(i);
    newLabel(mazeStarts(i):mazeEnds(i),1) = repmat(labels(i,1), d+1, 1);
    if ~isempty(labels{i,2})
        newLabel(mazeStarts(i):mazeEnds(i),2) = repmat(labels(i,2), d+1, 1);
    end
    
    
    if ~isempty(labels{i,3})
        newLabel(mazeStarts(i):mazeEnds(i),3) = repmat(labels(i,3), d+1, 1);
    end
    
    
    if ~isempty(labels{i,6}) && ~isempty(labels{i,7})
        newLabel(mazeStarts(i):mazeEnds(i),4)=num2cell(str2num(labels{i,6}):str2num(labels{i,7}));
    end
    
    
    if ~isempty(labels{i,8})
        newLabel(mazeStarts(i):mazeEnds(i),5)=num2cell(repmat(str2num(labels{i,8}),d+1,1));
    end
    
    if ~isempty(labels{i,9})
        newLabel(mazeStarts(i):mazeEnds(i),6) = repmat({labels{i,9}},d+1,1);
    end
    
    if ~isempty(labels{i,10})
        newLabel(mazeStarts(i):mazeEnds(i),7) = repmat({labels{i,10}},d+1,1);
    end
    
    if ~isempty(labels{i,11})
        newLabel(mazeStarts(i):mazeEnds(i),8) = repmat(labels(i,11),d+1,1);
    end
end

label_table = cell2table(newLabel,'VariableNames',varnames(active_fields));