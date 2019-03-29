function [video] = uigetvids(expmt)

% get files from UI
[fName,fDir,fFilter] = uigetfile('*.avi;*.mp4;*.m4v;*.mov;*.wmv;*.mpg;*.bin;*.mj2',...
    'Select video files','Multiselect','on');

if ~iscell(fName)
    fName = {fName};
end

ext = find(fName{1}=='.');
ext = fName{1}(ext+1:end);


% set default current video object to first file
if fDir
    
    if strcmp(ext,'bin')
        
        video.fID = fopen([fDir fName{1}],'r');
        video.res = fread(video.fID,2,'double');
        prcn = fread(video.fID,1,'double');
        signed = fread(video.fID,1,'double');
        video.fdir = fDir;
        video.fnames = fName;
        video.nVids = length(fName);
        video.ct = 1;
        
        switch prcn
            case 8
                byte_depth = 1;
                if signed
                    video.precision = 'int8';
                else
                    video.precision = 'uint8';
                end
            case 16
                byte_depth = 2;
                if signed
                    video.precision = 'int16';
                else
                    video.precision = 'uint16';
                end
            case 32
                byte_depth = 4;
                if signed
                    video.precision = 'int32';
                else
                    video.precision = 'uint32';
                end
        end
        
        file_info = dir([fDir fName{1}]);
        video.nFrames = file_info.bytes/prod([byte_depth;video.res]);
        
        
    else
        
        video.vid = VideoReader([fDir fName{1}]);
        video.fdir = fDir;
        video.fnames = fName;
        video.nVids = length(fName);
        video.ct = 1;

        % get cummulative video length
        dur = 0;
        nFrames = 0;
        for i = 1:length(fName)
            v = VideoReader([fDir fName{i}]);
            dur = dur + v.Duration;
            nFrames = nFrames + v.NumberOfFrames;
            delete(v);
        end

        delete(video.vid);
        video.vid = VideoReader([fDir fName{1}]);
        video.current_frame = 1;
        video.total_duration = dur;
        video.nFrames = nFrames;
    end
    
else
    
    video = [];
    
end



