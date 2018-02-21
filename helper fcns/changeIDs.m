function changeIDs(oldIDs,newIDs)

fDir = autoDir;
fPaths = getHiddenMatDir(fDir,'ext','.mat');

hwb = waitbar(0,'loading files');

for j = 1:length(fPaths)
    
    hwb = waitbar(j/length(fPaths),hwb,['loading file ' num2str(j) ' of ' num2str(length(fPaths))]);
    load(fPaths{j},'expmt');
    name = expmt.Name;                  % query expmt name
    
    switch name
        case 'Olfaction'
            tmp_ID = expmt.ID';
            idx=arrayfun(@(x) find(oldIDs==x),tmp_ID);
            tmp_ID = newIDs(idx);
            expmt.ID = tmp_ID';
                    
        otherwise
            tmp_ID = expmt.labels_table.ID;
            idx=arrayfun(@(x) find(oldIDs==x),tmp_ID,'UniformOutput',false);
            idx_mask = ~cellfun(@isempty,idx);
            idx(~idx_mask)=[];
            idx=cell2mat(idx);
            tmp_ID(idx_mask) = newIDs(idx);
            if size(tmp_ID,2) > size(tmp_ID,1)
                tmp_ID = tmp_ID';
            end
            expmt.labels_table.ID = tmp_ID;
                    
    end
    
    % Query label fields and set label for file
    lab_fields = expmt.labels_table.Properties.VariableNames;
    expmt.fLabel = [expmt.date '_' expmt.Name];
    for i = 1:length(lab_fields)
        switch lab_fields{i}
            case 'Strain'
                expmt.fLabel = [expmt.fLabel '_' expmt.Strain];
            case 'Sex'
                expmt.fLabel = [expmt.fLabel '_' expmt.Sex];
            case 'Treatment'
                expmt.fLabel = [expmt.fLabel '_' expmt.Treatment];
            case 'Day'
                expmt.fLabel = [expmt.fLabel '_Day' num2str(expmt.Day)];
            case 'ID'
                ids = expmt.labels_table.ID;
                expmt.fLabel = [expmt.fLabel '_' num2str(ids(1)) '-' num2str(ids(end))];
        end
    end
    
    % rename directory and file
    [old_dir,old_name,~] = fileparts(fPaths{j});
    new_dir = old_dir;
    new_dir(find(old_dir=='\',1,'last')+1:end)=[];
    new_dir = [new_dir expmt.fLabel '\'];
    new_path = [new_dir expmt.fLabel];
    [status,~]=movefile(old_dir,new_dir);
    [status,~]=movefile([new_dir old_name '.mat'],[new_path '.mat']);
    [status,~]=movefile([new_dir old_name '_RawData.zip'],[new_path '_RawData.zip']);
    
    % update file directory
    expmt.fdir = new_dir;
    
    % save the expmt struct
    save([expmt.fdir expmt.fLabel '.mat'],'expmt');

    
end

delete(hwb);
   
    
    
    