function fDir = autoDir

try
    margo_dir = which('margo');
    idx=strfind(margo_dir,'margo');
    margo_dir = margo_dir(1:idx(1)-1);
    startDir = [margo_dir 'margo_data'];
    fDir = uigetdir(startDir,'Select a directory');
catch
    fDir = uigetdir('Select a directory');
end