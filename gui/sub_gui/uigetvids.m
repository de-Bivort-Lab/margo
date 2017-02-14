function [video] = uigetvids(expmt)

% get files from UI
[fName,fDir,fFilter] = uigetfile('*.avi;*.mp4;*.m4v;*.mov;*.wmv;*.mpg;','Select video files',...
    'C:\Users\werkh\Documents\Prototyping Data\autotracker update testing','Multiselect','on');

% set default current video object to first file
video.vid = VideoReader([fDir fName{1}]);
video.fdir = fDir;
video.fnames = fName;
video.nVids = length(fName);
video.ct = 1;

% get cummulative video length
dur = 0;
for i = 1:length(fName)
    v = VideoReader([fDir fName{i}]);
    dur = dur + v.Duration;
    delete(v);
end

video.total_duration = dur;


