classdef rawData < handle
   properties (SetAccess = private, GetAccess = public)
      path;
      fID;
      size;
      precision;
      Name;
   end
   methods
    function rd = rawData(fpath,varargin)
        
        rd.path = fpath;
        rd.precision = 'single';
        
        % parse input vars
        for i=1:numel(varargin)
        	arg = varargin{i};
            if ischar(arg)
                switch arg
                    case 'Size'
                        i=i+1;
                        rd.size = varargin{i};
                    case 'Precision'
                        i=i+1;
                        rd.precision = varargin{i};
                end
            end
        end
        
        rd.fID = fopen(fpath);

    end
    function varargout = subsref(obj,s)
        switch obj.precision
            case 'uint8',   nb = 1;
            case 'int8',    nb = 1;
            case 'uint16',  nb = 2;
            case 'int16',   nb = 2;
            case 'uint32',  nb = 4;
            case 'int32',   nb = 4;
            case 'single',  nb = 4;
            case 'double',  nb = 8;
            otherwise
                error('unsupported data precision');
        end
        
        switch s.type
            case '()'
                % query reading format
                format = [obj.precision '=>' obj.precision];
        
                if numel(s.subs) == 1
                    varargout = fread(obj.fID,s.subs{1}(end),format);
                    
                elseif numel(s.subs) == 2
                    skip_bytes = obj.size(1)-1;
                    row_idx = floor(s.subs{2}(1)/obj.size(1));
                    ii = row_idx + s.subs{1}(1);
                    L = s.subs{2}(end) - s.subs{2}(1) + 1;
                    fseek(obj.fID, (ii-1)*nb, 'bof');
                    varargout{1} = fread(obj.fID,L,format,skip_bytes*nb);
                    
                end
                
            otherwise
                % Use built-in for any other expression
                [varargout{1:nargout}] = builtin('subsref',obj,s);
        end
    end
   end
end
