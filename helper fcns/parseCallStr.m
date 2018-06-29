function fpath = parseCallStr(callStr)

    i = strfind(callStr,'load(');
    i=i(1)+4;
    nest = find(callStr=='(');
    nest_idx = find(nest == i);
    j = find(callStr==')');
    j = j(numel(nest)-nest_idx+1);
    callInput = callStr(i+1:j-1);
    input_str = regexp(callInput,'''(.[^'']*)''','tokens');
    if ~isempty(input_str)
        isfile = cellfun(@(p) exist(p,'file'),input_str{:});
        if any(isfile)
            fpath = input_str{find(isfile)};
            return
        end
    end
    
    callArgs = regexp(callInput,',','split');
    arg_splits = find(callInput==',');
    arg_splits = [0 arg_splits numel(callInput)+1];
    open_idx = find(callInput=='(');
    close_idx = find(callInput==')');
    for i = 1:numel(open_idx)
        sub_arg = open_idx(i) < arg_splits &...
                    arg_splits < close_idx(numel(open_idx)-i+1);
        if any(sub_arg)
            arg_splits(sub_arg)=[];
        end
    end
    
    callArgs = cell(numel(arg_splits)-1,1);
    for i=1:length(arg_splits)-1
        callArgs{i} = callInput(arg_splits(i)+1:arg_splits(i+1)-1);
    end
    callArgs = cellfun(@strtrim,callArgs,'UniformOutput',false);
    
    for i=1:length(callArgs)
        tmp_var = evalin('caller',callArgs{i});
        if exist(tmp_var,'file')==2
            fpath = tmp_var;
            return
        end
    end       
end