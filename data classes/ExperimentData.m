classdef ExperimentData < handle
% class definition for the expmt master data container which contains
% experiment meta data and memmaps for raw data files
    
    properties
        data;
        meta;
        parameters;
        hardware;
    end
    methods
        % construct new ExperimentData obj with default values
        function obj = ExperimentData
            
            es = struct();
            obj.data = struct('centroid',RawDataField('Parent',obj),...
                'time',RawDataField('Parent',obj));
            obj.meta = struct('name','Basic Tracking','fields',[],'path',es,...
                            'source','camera','roi',es,'ref',es,'noise',es,...
                            'date','','strain','','treatment','','sex','',...
                            'labels',[],'labels_table',table,'video',es,...
                            'vignette',es);
            obj.hardware = struct('cam',es,'COM',es,...
                                'light',es,'projector',es);
            obj.meta.fields = fieldnames(obj.data);
            obj.parameters = initialize_parameters(obj);
            
            % assign default meta data
            obj.meta.path.dir = '';
            obj.meta.path.name = '';
            obj.meta.roi.mode = 'grid';
            obj.meta.vignette.mode = 'auto';
            obj.meta.initialize = true;
            obj.meta.finish = true;
            obj.meta.exp_id = 1;

        end
        
        % automatically repair master container and raw data file paths
        function obj = updatepaths(obj,fpath,varargin)
            
            if ~exist('fpath','var')
                fpath = [obj.meta.path.dir obj.meta.path.name];
            end
            [dir,name,~] = fileparts(fpath);
            obj.meta.path.dir   =   [dir '/'];
            obj.meta.path.name  =   name;

            % get binary files
            rawpaths = recursiveSearch(dir,'ext','.bin','keyword',obj.meta.date);
            [~,rawnames] = cellfun(@fileparts, rawpaths, ...
                                        'UniformOutput',false);
            
            for i=1:length(obj.meta.fields)
                
                % match to time/date and field name
                f = obj.meta.fields{i};
                match = cellfun(@(x) ...
                    any(strcmpi(x,[obj.meta.date '_' f])),rawnames);
                
                if any(match)
                    match_idx = find(match,1,'first');
                    obj.data.(f).path = rawpaths{match_idx};
                else
                    warning('off','backtrace');
                    warning('raw data file for field %s not found',f);
                    warning('on','backtrace');
                end
            end
            
            if ~isempty(varargin) && ~varargin{1}
                return
            end
            
            % attach obj by default
            attach(obj);
        end
        
        % initialize all raw data maps
        function obj = attach(obj) 
            fn = fieldnames(obj.data);
            for i=1:length(obj.meta.fields)
                attach(obj.data.(fn{i}));
            end
        end
        % de-initialize all raw data maps
        function obj = detach(obj) 
            fn = fieldnames(obj.data);
            for i=1:length(obj.meta.fields)
                obj.data.(fn{i}).raw.map = [];
            end
        end
        % re-initialize all raw data maps
        function obj = reset(obj)
            detach(obj);
            attach(obj);
        end
        
        % reset experiment specific properties for new session
        function obj = reInitialize(obj)
            
            % remove roi, reference, noise and vignette data
            if ~isempty(obj.meta.roi)
                m = obj.meta.roi.mode;
                obj.meta.roi = [];
                obj.meta.roi.mode = m;
            end
            if ~isempty(obj.meta.ref)
                obj.meta.ref= [];
            end
            if ~isempty(obj.meta.noise)
                obj.meta.noise = [];
            end
            if ~isempty(obj.meta.vignette)
                m = obj.meta.vignette.mode;
                obj.meta.vignette = [];
                obj.meta.vignette.mode = m;
            end
            if ~isempty(obj.meta.labels)
                obj.meta.labels = [];
            end
            
            % re-initialize data fields
            f = obj.meta.fields;
            new_fields = cell(2,numel(f));
            new_fields(1,:) = f;
            obj.data = struct(new_fields{:});
            for i = 1:numel(f)
                obj.data.(f{i}) = RawDataField('Parent',obj);
            end
        end
        
        function p = initialize_parameters(~)
            p = struct();
            p.duration          = 2;
            p.ref_depth         = 3;
            p.ref_freq          = 0.5000;
            p.roi_thresh        = 45.5000;
            p.track_thresh      = 15;
            p.speed_thresh      = 95;
            p.distance_thresh   = 60;
            p.vignette_sigma    = 0.4700;
            p.vignette_weight   = 0.3500;
            p.area_min          = 4;
            p.area_max          = 100;
            p.target_rate       = 30;
            p.mm_per_pix        = 1;
            p.units             = 'pixels';
            p.roi_mode          = 'grid';
            p.sort_mode         = 'bounds';
            p.roi_tol           = 2.5000;
            p.edit_rois         = 0;
            p.dilate_sz         = 0;
        end
            
    end
    methods(Static)
        
        function obj = loadobj(obj)
            
            warning('off','MATLAB:m_missing_operator');
            if ~isfield(obj.meta.path,'dir')
                return
            end
            if exist([obj.meta.path.dir obj.meta.path.name],'file') ~= 2
                msg = sprintf(['\tFile path change detected, attempting to '...
                    'repair path meta data for raw data files\n'...
                    '\t\t\tUnsuccessful repair will result in non-functional raw '...
                    'data maps']);
                
                if ~strcmp(lastwarn,msg)
                    warning('off','backtrace');
                    disp(sprintf('\n'))
                    warning(msg);
                    disp(sprintf('\n'))
                    warning('on','backtrace');
                end
            end

            
            % auto update path         
            if isvalid(obj)
                try
                    error('DummyError');
                catch ME
                    callStackDetails = getReport(ME);
                end
                if any(strfind(callStackDetails,'uiimport')) &&...
                     ~any(strfind(callStackDetails,'runImportdata'))
                    return
                end
                callStr = regexp(callStackDetails,...
                    '(?<=Error in [^\n]*\n)[^\n]*','match','once');
                callStr = strtrim(callStr);
                
                if any(strfind(callStr,'load('))
                    i = strfind(callStr,'load(');
                    i=i(1)+4;
                    nest = find(callStr=='(');
                    nest_idx = find(nest == i);
                    j = find(callStr==')');
                    j = j(numel(nest)-nest_idx+1);
                    callInput = callStr(i+1:j-1);
                    input_str = regexp(callInput,'''(.[^'']*)''','tokens');
                    isfile = cellfun(@(p) exist(p,'file'),input_str{:});

                    if any(isfile)
                        fpath = input_str{find(isfile)};
                        if testPath(fpath, obj.meta.date)
                            obj = updatepaths(obj,fpath);
                            return
                        end
                    end

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
                            if testPath(fpath, obj.meta.date)
                                obj = updatepaths(obj,fpath);
                                return
                            end
                        end
                    end    
                else
                    try
                        callVars = evalin('caller','whos');
                        for i=1:numel(callVars)
                            varName = callVars(i).name;
                            tmp = evalin('caller',varName);
                            if exist(tmp,'file')
                                fpath = tmp;
                                if testPath(fpath, obj.meta.date)
                                    obj = updatepaths(obj,fpath);
                                    return
                                end
                            end
                        end
                    catch
                        callVars = evalin('base','whos');
                        for i=1:numel(callVars)
                            varName = callVars(i).name;
                            tmp = evalin('caller',varName);
                            if exist(tmp,'file')
                                fpath = tmp;
                                if testPath(fpath, obj.meta.date)
                                    obj = updatepaths(obj,fpath);
                                    return
                                end
                            end
                        end
                    end
                    
                    historypath = ...
                        com.mathworks.mlservices. ...
                        MLCommandHistoryServices.getSessionHistory;
                    callStr = historypath(end);
                    fpath = parseCommand(callStr, obj.meta.date);
                    if ~isempty(fpath)
                        if iscell(fpath)
                            fpath = fpath{:};
                        end
                        obj = updatepaths(obj,fpath);
                    end
                end
            else
                warning('automatic filepath update failed');
            end
            sprintf('dir: %s\n',fpath);
            warning('on','MATLAB:m_missing_operator');
        end
        
        
    end
end


function status = testPath(fpath, date_label)

    % check for date label in path
    if iscell(fpath)
        fpath = fpath{1};
    end
    [~,name,~] = fileparts(fpath);
    status = ~isempty(strfind(name, date_label));
    
end


function fpath = parseCommand(callStr, date_label)

callStr = callStr.toCharArray;
callStr = callStr';
fpath=[];
if any(strfind(callStr,'load('))
    i = strfind(callStr,'load(');
    i=i(1)+4;
    nest = find(callStr=='(');
    nest_idx = find(nest == i);
    j = find(callStr==')');
    j = j(numel(nest)-nest_idx+1);
    callInput = callStr(i+1:j-1);
    input_str = regexp(callInput,'''(.[^'']*)''','tokens');
    isfile = cellfun(@(p) exist(p,'file'),input_str{:});

    if any(isfile)
        tmp_path = input_str{find(isfile)};
        if testPath(tmp_path, date_label)
            fpath = tmp_path;
            return
        end
    end

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
        tmp_var = callArgs{i};
        if exist(tmp_var,'file')==2
            if testPath(tmp_var, date_label)
                fpath = tmp_var;
                return
            end
        end
    end  
end

end