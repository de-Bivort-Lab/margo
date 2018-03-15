classdef rawDataStore < matlab.io.Datastore
 
     properties(Access = private)
        CurrentFileIndex double
        FileSet matlab.io.datastore.DsFileSet
        Precision char
     end
      
  methods % begin methods section
          
    function rawds = rawDataStore(location,varargin)
        
        % set default properties
        splitSize = 1E9/2;
        prcn = 'double';
        for i=1:length(varargin)
            arg = varargin{i};
            if ischar(arg)
                switch arg
                    case 'SplitSize'
                        i=i+1;
                        splitSize = varargin{i};
                    case 'Precision'
                        i=i+1;
                        prcn = varargin{i};
                end
            end
        end
                        
        
        rawds.FileSet = matlab.io.datastore.DsFileSet(location,...
                                    'FileExtensions','.bin', ... 
                                    'FileSplitSize',splitSize);
        rawds.Precision = prcn;
        rawds.CurrentFileIndex = 1;
        reset(rawds); 
    end
   
    function tf = hasdata(rawds) 
        % Return true if more data is available.
        tf = hasfile(rawds.FileSet);
    end
   
    function [data,info] = read(rawds)
       % Read data and information about the extracted data.
       if ~hasdata(rawds)
           error('No more data');
       end

       fileInfoTbl = nextfile(rawds.FileSet);
       data = rawRead(fileInfoTbl,rawds);
       info.Size = size(data);
       info.FileName = fileInfoTbl.FileName;
       info.Offset = fileInfoTbl.Offset;

       % Update CurrentFileIndex for tracking progress
       if fileInfoTbl.Offset + fileInfoTbl.SplitSize >= ...
            fileInfoTbl.FileSize
             rawds.CurrentFileIndex = rawds.CurrentFileIndex + 1 ; 
       end


    end
   
    function reset(rawds)  
      % Reset to the start of the data.
      reset(rawds.FileSet);
      rawds.CurrentFileIndex = 1; 
    end
   
                      	
    function frac = progress(rawds)
      % Determine percentage of data that you have read 
      % from a datastore
      frac = (rawds.CurrentFileIndex-1)/rawds.Location.NumFiles;
    end
   
  end
      
      	
    methods(Access = protected)
        % If you use the DsFileSet object as a property,
        % then you must define the copyElement method. The
        % copyElement method allows the methods such as readall
        % and preview to remain stateless 
        function dscopy = copyElement(ds)
            dscopy = copyElement@matlab.mixin.Copyable(ds);
            dscopy.FileSet = copy(ds.FileSet);
        end
    end
      
end


function data = rawRead(fileInfoTbl,ds)
    % create a reader object using the FileName
    reader = matlab.io.datastore.DsFileReader(fileInfoTbl.FileName);

    % seek to the offset
    seek(reader,fileInfoTbl.Offset,'Origin','start-of-file');

    % read fileInfoTbl.SplitSize amount of data
    data = read(reader,fileInfoTbl.SplitSize,'OutputType',ds.Precision);
end

