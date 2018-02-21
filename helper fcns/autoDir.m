function fDir = autoDir

startDir = 'D:\Decathlon Raw Data';

if ~exist(startDir,'dir')==7
    
    autotracker_dir = which('autotracker');
    idx=strfind(autotracker_dir,'autotracker');
    autotracker_dir = autotracker_dir(1:idx(1)-1);
    startDir = [autotracker_dir 'autotracker_data'];
end

fDir = uigetdir(startDir,'Select a directory');