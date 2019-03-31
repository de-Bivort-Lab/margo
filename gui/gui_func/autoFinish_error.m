function expmt = autoFinish_error(expmt, gui_handles, error_msg)

% close open data files
fclose('all');

% close .avi file if one exists
if isfield(expmt.meta,'VideoData') && ...
        isfield(expmt.meta.VideoData,'obj') 
    close(expmt.meta.VideoData.obj);
end

            
try
    sca;               % close any open psychtoolbox windows
catch
    % do nothing
end

   
% temporarily remove vid obj/source from struct for saving
if isfield(expmt.hardware.cam,'vid')
    camcopy = expmt.hardware.cam;
    expmt.hardware.cam = rmfield(expmt.hardware.cam,'src');
    expmt.hardware.cam = rmfield(expmt.hardware.cam,'vid');
end
if isfield(expmt.meta,'video') && isfield(expmt.meta.video,'vid')
    vidcopy = expmt.meta.video.vid;
    expmt.meta.video = rmfield(expmt.meta.video,'vid');
end

% update meta data before exiting
gui_notify('updating file meta data',gui_handles.disp_note);

% re-save updated expmt data struct to file
f_path = [expmt.meta.path.dir expmt.meta.path.name];
save([f_path '_error.mat'],'expmt','-v7.3');

% query log files
error_logs = recursiveSearch(expmt.meta.path.dir,'keyword','error','ext','.txt');

% log eror to file
new_log_path = sprintf('%s%s_error_log_%i.txt',expmt.meta.path.dir,...
    expmt.meta.date,numel(error_logs)+1);
fid = fopen(new_log_path,'W');
fprintf(fid, '%s', error_msg) ;
fclose(fid);

if exist('camcopy','var')
    expmt.hardware.cam = camcopy;
end
if exist('vidcopy','var')
    expmt.meta.video.vid = vidcopy;
end
            
