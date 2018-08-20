function makeExperiment(name, handles)

expmt_dir = [handles.gui_dir 'experiments/' name];

if exist(expmt_dir,'dir')==7
    error('directory already exists, cannot create: %s', expmt_dir);
end

mkdir(expmt_dir);
name(name == ' ') = '';
name(name>64&name<91) = name(name>64&name<91) + 32;
run_src = [handles.gui_dir 'experiments/Basic Tracking/run_basictracking.m'];
run_dest = [expmt_dir '/run_' name '.m'];
analyze_src = [handles.gui_dir 'experiments/Basic Tracking/analyze_basictracking.m'];
analyze_dest = [expmt_dir '/analyze_' name '.m'];
copyfile(run_src, run_dest); 
copyfile(analyze_src, analyze_dest);
editFuncName(run_dest, 'basictracking', name);
editFuncName(analyze_dest, 'basictracking', name);




function editFuncName(path, oldname, newname)

fid = fopen(path,'r');
i = 1;
tline = fgetl(fid);
all_lines{i} = tline;
while ischar(tline)
    i = i+1;
    tline = fgetl(fid);
    all_lines{i} = tline;
end
fclose(fid);

% get line num
func_def_line = find(cellfun(@(line) ...
    any(strfind(line, 'function')) & any(strfind(line, oldname)), all_lines));
line_txt = all_lines{func_def_line};
idx = strfind(line_txt, oldname);
line_txt(idx:idx+numel(oldname)-1) = [];
line_txt = [line_txt(1:idx-1) newname line_txt(idx:end)];
all_lines{func_def_line} = line_txt;

fid = fopen(path, 'w');
for i = 1:numel(all_lines)
    if all_lines{i+1} == -1
        fprintf(fid,'%s', all_lines{i});
        break
    else
        fprintf(fid,'%s\n', all_lines{i});
    end
end
fclose(fid);