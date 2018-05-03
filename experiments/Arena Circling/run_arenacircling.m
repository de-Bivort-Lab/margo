function varargout = run_arenacircling(expmt,gui_handles,varargin)
%
% This is a blank experimental template to serve as a framework for new
% custom experiments. The function takes the master experiment struct
% (expmt) and the handles to the gui (gui_handles) as inputs and outputs
% the data assigned to out. In this example, object centroid, pixel area,
% and the time of each frame are output to file.

%% Parse variable inputs

for i = 1:length(varargin)
    
    arg = varargin{i};
    
    if ischar(arg)
        switch arg
            case 'Trackdat'
                i=i+1;
                trackDat = varargin{i};     % manually pass in trackDat rather than initializing
        end
    end
end

%% Initialization: Get handles and set default preferences

gui_notify(['executing ' mfilename '.m'],gui_handles.disp_note);

% clear memory
clearvars -except gui_handles expmt trackDat

% get handles
gui_fig = gui_handles.gui_fig;                            % gui figure handle
imh = findobj(gui_handles.axes_handle,'-depth',3,'Type','image');   % image handle


%% Experimental Setup
    
% Initialize reference stack
ref_stack = repmat(expmt.ref, 1, 1, gui_handles.edit_ref_depth.Value);

% properties of the tracked objects to be recorded
trackDat.fields={'Centroid';'Time'};                 

% initialize labels, files, and cam/video
[trackDat,expmt] = autoInitialize(trackDat,expmt,gui_handles);

% lastFrame = false until last frame of the last video file is reached
trackDat.lastFrame = false;


%% Main Experimental Loop


% run experimental loop until duration is exceeded or last frame
% of the last video file is reached
while ~trackDat.lastFrame
    
    % update time stamps and frame rate
    [trackDat] = autoTime(trackDat, expmt, gui_handles);

    % query next frame and optionally correct lens distortion
    [trackDat,expmt] = autoFrame(trackDat,expmt,gui_handles);

    % track, sort to ROIs, output optional fields set during intialization
    % and compare noise to the noise distribution measured during sampling
    trackDat = autoTrack(trackDat,expmt,gui_handles);


    % output data tracked fields to binary files
    [trackDat,expmt] = autoWriteData(trackDat, expmt, gui_handles);

    % update ref at the reference frequency or reset if noise thresh is exceeded
    [trackDat, expmt] = autoReference(trackDat, expmt, gui_handles);  

    % set image data
    trackDat = autoDisplay(trackDat, expmt, imh, gui_handles);
 
    
end


%% post-experiment wrap-up

if expmt.Finish
    
    % % auto process data and save master struct
    expmt = autoFinish(trackDat, expmt, gui_handles);

end

for i=1:nargout
    switch i
        case 1, varargout(i) = {expmt};
        case 2, varargout(i) = {trackDat};
    end
end