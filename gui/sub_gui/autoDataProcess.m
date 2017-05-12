function [varargout] = autoDataProcess(expmt,varargin)

% This function does basic data processing common to all autotracker
% experiments such as reading the data from the hard disk, formating it into
% the master data struct, and processing centroid coordinates and time
% variables.

%% parse inputs

meta.save = true;

for i = 1:length(varargin)
    
    arg = varargin{i};
    
    if ischar(arg)
    	switch arg
            case 'Plot'
                i=i+1;
                meta.plot = varargin{i};
            case 'Dir'
                i=i+1;
                expmt.fdir = varargin{i};
            case 'Save'
                i=i+1;
                meta.save = varargin{i};
            case 'Handles'
                i=i+1;
                meta.handles = varargin{i};
            case 'Decimate'
                i=i+1;
                meta.decimate = varargin{i};
            case 'DecFac'
                i=i+1;
                meta.decfac = varargin{i};
                meta.decmask = mod(1:expmt.nFrames,meta.decfac)==1;
        end
    end
end

%% Pull in ASCII data, format into vectors/matrices

if isfield(meta,'handles')
    gui_notify('importing and processing data...',meta.handles.disp_note)
end

expmt.nTracks = size(expmt.ROI.centers,1);

% read in data files sequentially and store in data struct
for i = 1:length(expmt.fields)
    
 
    f = expmt.fields{i};
        
    if ~isfield(expmt.(f),'data')
        
        % get subfields
        path = expmt.(f).path;
        dim = expmt.(f).dim;
        prcn = expmt.(f).precision;
        prcn = [prcn '=>' prcn];

        % read .bin file
        expmt.(f).fID = fopen(path,'r');


        % if field is centroid, reshape to (frames x dim x nTracks)
        if strcmp(f,'Centroid')
            expmt.(f).data = fread(expmt.(f).fID,prcn);
            expmt.(f).data = reshape(expmt.(f).data,dim(1),dim(2),expmt.nFrames);
            expmt.(f).data = permute(expmt.(f).data,[3 2 1]);
            expmt.drop_ct = expmt.drop_ct ./ expmt.nFrames;
            
            if isfield(meta,'decimate') && any(strcmp(f,meta.decimate))
                expmt.(f).data = expmt.(f).data(meta.decmask,:,:);
            end
%{
        elseif strcmp(f,'Time')
            expmt.(f).data = fread(expmt.(f).fID,prcn);
%}
        elseif ~strcmp(f,'VideoData') || ~strcmp(f,'VideoIndex')
            expmt.(f).data = fread(expmt.(f).fID,[expmt.(f).dim(1) expmt.nFrames],prcn);
            
            if isfield(meta,'decimate') && any(strcmp(f,meta.decimate))
                expmt.(f).data = expmt.(f).data(:,meta.decmask);
            end
            
            expmt.(f).data = expmt.(f).data';

        end
    
        fclose(expmt.(f).fID);
    
    end
    
end

% In the example, the centroid is being processed to extract circling
% handedness for each track. Resulting handedness scores are stored in
% the master data struct.
[expmt,trackProps] = processCentroid(expmt);

if isfield(meta,'handles')
    gui_notify('processing complete',meta.handles.disp_note)
end


for i=1:nargout
    switch i
        case 1, varargout{i} = expmt;
        case 2, varargout{i} = trackProps;
        case 3, varargout{i} = meta;
    end
end

            
            
            
            