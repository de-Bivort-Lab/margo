function [im, video] = nextFrame(video,gui_handles)

% queries the next frame in a video file list
im = [];
if isfield(video,'fID')
    
    if ~feof(video.fID)       
        im = fread(video.fID,video.res',[video.precision '=>uint8']);
    end
    
else
    
    if video.current_frame < video.nFrames
        
        im = read(video.vid,video.current_frame);
        video.current_frame = video.current_frame + 1;
        
    else
       % increment to next video
       video.ct = video.ct + 1;

       % create new video object
       video.vid = ...
           VideoReader([video.fdir video.fnames{mod(video.ct,video.nVids)+1}]);
       video.current_frame = 1;

       % update gui popupmenu with current file
       gui_handles.vid_select_popupmenu.Value = mod(video.ct,video.nVids)+1;

       im = read(video.vid,1);

    end
    
end