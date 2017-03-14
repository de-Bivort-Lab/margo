function [expmt]=autoROIs(gui_handles, expmt)
%
% Automatically detects light ROIs on a dark background and extracts
% their centroid coordinates and bounds. This function also detects
% and outputs the orientation of arenas with asymmetry about the
% horizontal axis (eg. Y shaped arenas). The function takes autotracker
% gui gui_handles as an input 
% Inputs

clearvars -except gui_handles expmt
colormap('gray')

gui_notify('running ROI detection',gui_handles.disp_note);

%% Define parameters - adjust parameters here to fix tracking and ROI segmentation errors

gui_fig = gui_handles.gui_fig;

% ROI detection parameters
ROI_thresh=get(gui_handles.ROI_thresh_slider,'value');    % Binary image threshold from zero (black) to one (white) for segmentation  
sigma=0.47;                                 % Sigma expressed as a fraction of the image height
kernelWeight=0.34;                          % Scalar weighting of kernel when applied to the image

%% Setup the camera and/or video object

if strcmp(expmt.source,'camera') && strcmp(expmt.camInfo.vid.Running,'off')
    
    % Clear old video objects
    imaqreset
    pause(0.2);

    % Create camera object with input parameters
    expmt.camInfo = initializeCamera(expmt.camInfo);
    start(expmt.camInfo.vid);
    pause(0.1);
    
elseif strcmp(expmt.source,'video') 
    
    % set current file to first file in list
    gui_handles.vid_select_popupmenu.Value = 1;
    
    if isfield(expmt.video,'fID')
        
        % ensure that the current position of the file is set to 
        % the beginning of the file (bof) + an offset of 32 bytes
        % (the first 32 bytes store info on resolution and precision)
        fseek(expmt.video.fID, 32, 'bof');
        
    else
        
        % open video object from file
        expmt.video.vid = ...
            VideoReader([expmt.video.fdir ...
            expmt.video.fnames{gui_handles.vid_select_popupmenu.Value}]);

        % get file number in list
        expmt.video.ct = gui_handles.vid_select_popupmenu.Value;

        % estimate duration based on video duration
        gui_handles.edit_exp_duration.Value = expmt.video.total_duration * 1.15 / 3600;
        
    end
    
end


%% Grab image for ROI detection and segment out ROIs

clean_gui(gui_handles.axes_handle);
imh = findobj(gui_handles.axes_handle,'-depth',3,'Type','Image');

if isempty(imh)
        % Take single frame
    switch expmt.source
        case 'camera'
            trackDat.im = peekdata(expmt.camInfo.vid,1);
        case 'video'
            [trackDat.im, expmt.video] = nextFrame(expmt.video,gui_handles);
    end
    imh = imagesc(trackDat.im);
elseif strcmp(imh.CDataMapping,'direct')
   imh.CDataMapping = 'scaled';
end

stop=get(gui_handles.accept_ROI_thresh_pushbutton,'value');

% Waits for "Accept Threshold" button press from user before accepting
% automatic ROI segmentation

clearvars hRect hText

hRect(1) = rectangle('Position',[0 0 0 0],'EdgeColor','r');
hText(1) = text(0,0,'1','Color','b');

while stop~=1;
    
    tic
    stop=get(gui_handles.accept_ROI_thresh_pushbutton,'value');
    pause(0.1);

    % Take single frame
    switch expmt.source
        case 'camera'
            trackDat.im = peekdata(expmt.camInfo.vid,1);
        case 'video'
            [trackDat.im, expmt.video] = nextFrame(expmt.video,gui_handles);
    end
    
    % Extract green channel if image is RGB
    if size(trackDat.im,3) > 1
        trackDat.im=trackDat.im(:,:,2);
    end

    % Update threshold value
    ROI_thresh=get(gui_handles.ROI_thresh_slider,'value');

    switch expmt.vignette.mode
        case 'manual'
            % subtract the vignette correction off of the raw image
            trackDat.im = trackDat.im - expmt.vignette.im;
        case 'auto'
            % approximate light source as guassian to smooth vignetting
            % for more even illumination and better ROI detection
            gauss = buildGaussianKernel(size(trackDat.im,2),...
                size(trackDat.im,1),sigma,kernelWeight);
            trackDat.im=(uint8(double(trackDat.im).*gauss));
    end

    % Extract ROIs from thresholded image
    [ROI_bounds,ROI_coords,~,~,binaryimage] = detect_ROIs(trackDat.im,ROI_thresh);
    nROIs = size(ROI_coords,1);

    % Calculate coords of ROI centers
    [xCenters,yCenters]=ROIcenters(binaryimage,ROI_coords);
    centers=[xCenters,yCenters];

    % Define a permutation vector to sort ROIs from top-right to bottom left
    [centers,ROI_coords,ROI_bounds] = sortROIs(centers,ROI_coords,ROI_bounds);
  
    % detect assymetry about vertical axis
    mazeOri = getMazeOrientation(binaryimage,ROI_coords);
    
    % Display ROIs
    imh.CData = binaryimage;
    hold on

    if length(hRect) > nROIs
        nDraw = length(hRect);
    else
        nDraw = nROIs;
    end

    idel = [];
    
    for i = 1:nDraw
        
        if i <= nROIs && i <= length(hRect)
            hRect(i).Position = ROI_bounds(i,:);
            hText(i).Position = [centers(i,1)-10 centers(i,2) 0];
            if mazeOri(i)
                hText(i).Color = [1 0 1];
            else
                hText(i).Color = [0 0 1];
            end
            
        elseif i > nROIs
            delete(hRect(i));
            delete(hText(i));
            idel = [idel i];
            
        elseif i > length(hRect)
            hRect(i) = rectangle('Position',ROI_bounds(i,:),'EdgeColor','r');
            if mazeOri(i)
                hText(i) = text(centers(i,1)-5,centers(i,2),int2str(i),'Color','m');
            else
                hText(i) = text(centers(i,1)-5,centers(i,2),int2str(i),'Color','b');
            end
        end
    end

    hRect(idel) = [];
    hText(idel) = [];
    hold off
    drawnow


    % Report frames per sec to GUI
    set(gui_handles.edit_frame_rate,'String',num2str(round(1/toc)));
end

gui_notify([num2str(size(centers,1)) ' ROIs detected'],gui_handles.disp_note);

% Reset the accept threshold button
set(gui_handles.accept_ROI_thresh_pushbutton,'value',0);

% create a vignette correction image if mode is set to auto
if strcmp(expmt.vignette.mode,'auto');
    expmt.vignette.im = filterVignetting(trackDat.im,ROI_coords(end,:));
end

% assign outputs
expmt.ROI.corners = ROI_coords;
expmt.ROI.centers = centers;
expmt.ROI.orientation = mazeOri;
expmt.ROI.bounds = ROI_bounds;
expmt.ROI.im = binaryimage;
