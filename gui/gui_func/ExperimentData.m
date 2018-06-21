classdef ExperimentData < handle
% class definition for the expmt master data container which contains
% experiment meta data and memmaps for raw data files
    
    properties
        data;
        meta;
        hardware;
    end
    methods
        function obj = ExperimentData
            
            es = struct();
            obj.data = struct('Centroid',RawDataField('Parent',obj),...
                'Time',RawDataField('Parent',obj));
            obj.meta = struct('name','Basic Tracking','fields',[],'path',es,...
                            'date','','strain','','treatment','','sex','');   
            obj.meta.fields = fieldnames(obj.data);
            
        end
        
        
        function obj = updatepaths(obj,fpath)
            
            [dir,name,~] = fileparts(fpath);
            obj.meta.path.dir   =   [dir '\'];
            obj.meta.path.name  =   name;

            % get binary files
            rawpaths = getHiddenMatDir(dir,'ext','.bin');
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
                    warning(sprintf('raw data file for field %s not found\n',f));
                end
                
            end
        end
        
        
    end
    methods(Static)
        
        function obj = loadobj(obj)
            
            % auto update path         
            if isvalid(obj)
                try
                    fpath = evalin('caller','filename');
                catch
                    fpath = evalin('caller','fileAbsolutePath');
                end
                obj = updatepaths(obj,fpath);
            else
                warning('automatic filepath update failed');
            end

            
        end
        
    end
    
    
    
    
    
end