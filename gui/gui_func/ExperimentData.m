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
                            'labels',[],'labels_table',table);
            obj.hardware = struct('cam',es,'COM',es,...
                                'light',es,'projector',es);
            obj.meta.fields = fieldnames(obj.data);
            obj.parameters = initialize_parameters(obj);
            obj.meta.roi.mode = 'grid';

        end
        
        % automatically repair master container and raw data file paths
        function obj = updatepaths(obj,fpath)
            
            if ~exist('fpath','var')
                fpath = [obj.meta.path.dir obj.meta.path.name];
            end
            [dir,name,~] = fileparts(fpath);
            obj.meta.path.dir   =   [dir '\'];
            obj.meta.path.name  =   name;

            % get binary files
            rawpaths = recursiveSearch(dir,'ext','.bin');
            [~,rawnames] = cellfun(@fileparts, rawpaths, ...
                                        'UniformOutput',false);
            
            for i=1:length(obj.meta.fields)
                
                % match to time/date and field name
                f = obj.meta.fields{i};
                fmatch = cellfun(@(x) any(strfind(x,f)),rawnames);
                tmatch = cellfun(@(x) any(strfind(x,obj.meta.date)),rawnames);
                
                if any(fmatch & tmatch)
                    match_idx = find(fmatch & tmatch,1,'first');
                    obj.data.(f).path = rawpaths{match_idx};
                else
                    warning('off','backtrace');
                    warning('raw data file for field %s not found',f);
                    warning('on','backtrace');
                end
                
            end
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
                obj.data.(fn{i}).map = [];
            end
        end
        
        % reset experiment specific properties for new session
        function obj = reset(obj)
            
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
            
            % auto update path         
            if isvalid(obj)
                try
                    error('DummyError');
                catch ME
                    callStackDetails = getReport(ME);
                end
                callLine = regexp(callStackDetails,'(?<=Error in [^\n]*\n)[^\n]*','match','once');
                
                if any(strfind(callLine,'load('))
                    i = strfind(callLine,'load(');
                    i=i(1)+5;
                    i = [i find(callLine==')',1,'first')];
                    callVar = callLine(i(1):i(2)-1);
                    fpath = evalin('caller',callVar);
                else
                    callVars = evalin('caller','whos');
                    for i=1:numel(callVars)
                        varName = callVars(i).name;
                        switch varName
                            case 'filename'
                                fpath = evalin('caller',varName);
                            case 'fileAbsolutePath'
                                fpath = evalin('caller',varName);
                        end
                    end
                end
                
                if exist('fpath','var')
                    obj = updatepaths(obj,fpath);
                end
            else
                warning('automatic filepath update failed');
            end

            warning('on','MATLAB:m_missing_operator');
        end
        
    end
    
    
    
    
    
end