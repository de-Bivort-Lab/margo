function changeDayLabel(newDayLabels,varargin)

% This function is for re-writing the day information associated with all
% files in the directory. The only required input is a list of new day
% labels that is the same length as the number of expmt structs to be
% renamed

for i = 1:length(varargin)
    
    arg=varargin{i};
    if ischar(arg)
        switch arg
            case 'Dir'
                i=i+1;
                Dir = varargin{i};
        end
    end
end

%% prompt user for directory if none is specified

% Get paths to data files
[fDir] = uigetdir('C:\Users\debivort\Documents\MATLAB\Decathlon Raw Data',...
    'Select directory containing expmt files and folders to be renamed');

fPaths = getHiddenMatDir(fDir);
dir_idx = i+1;
fDir=cell(size(fPaths));
for j=1:length(fPaths)
    [tmp_dir,~,~]=fileparts(fPaths{j});
    fDir(j) = {[tmp_dir '\']};
end


%% rename each directory according to newDayLabels vector


for i = 1:length(newDayLabels)
    
    disp(i)
    
    load(fPaths{i});    % load expmt struct
    
    
    % alter name in labels table if it exists
    if isfield(expmt,'labels_table') && any(strcmp(expmt.labels_table.Properties.VariableNames,'Day'))
        expmt.labels_table.Day = repmat(newDayLabels(i),size(expmt.labels_table.Day));
    end
    
    % rename directory
    dir_start = find(fPaths{i}=='\',2,'last');
    day_idx = strfind(fPaths{i},'Day');
    day_idx = day_idx(day_idx>dir_start(1) & day_idx<dir_start(2))+3;
    nDigits = floor(log10(newDayLabels(i)));
    [old_dir,~,~] = fileparts(fPaths{i});
    fPaths{i}(day_idx:day_idx+nDigits)=num2str(newDayLabels(i));
    [new_dir,~,~] = fileparts(fPaths{i});
    [status,~]=movefile(old_dir,new_dir);
    
    % rename fLabel
    day_idx = strfind(expmt.fLabel,'Day')+3;
    if day_idx   
        expmt.fLabel(day_idx:day_idx+nDigits)=num2str(newDayLabels(i));
    end
    
    % update file directory if necessary
    if ~strcmp(expmt.fdir,fPaths{i})
        [d,f,e]=fileparts(fPaths{i});
        expmt.fdir = [d '\'];
    end
    
    in_dir = dir(expmt.fdir);
    for j=1:length(in_dir)
        
        if ~in_dir(j).isdir
            [~,f,e] = fileparts(in_dir(j).name);
            if any(strfind(f,'Day'))
                day_idx = strfind(f,'Day')+3;
                new_label = f;
                new_label(day_idx:day_idx+nDigits) = num2str(newDayLabels(i));
                [status,~]=movefile([expmt.fdir '\' f e],[expmt.fdir '\' new_label e]);
            end
        end
        
    end
    
    % save the expmt struct
    save([expmt.fdir expmt.fLabel '.mat'],'expmt');
    
            
    
end
    
    
    