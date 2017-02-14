function [varargout]=autoROIs(gui_handles)
%
% Automatically detects light ROIs on a dark background and extracts
% their centroid coordinates and bounds. This function also detects
% and outputs the orientation of arenas with asymmetry about the
% horizontal axis (eg. Y shaped arenas). The function takes autotracker
% gui gui_handles as an input 
% Inputs

clearvars -except gui_handles
colormap('gray')

%% Define parameters - adjust parameters here to fix tracking and ROI segmentation errors

gui_fig = gui_handles.gui_fig;

% import data from gui
expmt = getappdata(gui_fig,'expmt');

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
    
    % open video object from file
    expmt.video.vid = ...
        VideoReader([expmt.video.fdir expmt.video.fnames{gui_handles.vid_select_popupmenu.Value}]);
    
    % get file number in list
    expmt.video.ct = gui_handles.vid_select_popupmenu.Value;
    
end



%% Grab image for ROI detection and segment out ROIs

cla reset
if strcmp(expmt.source,'camera')
    res = expmt.camInfo.vid.videoResolution;
else
    res(1) = expmt.video.vid.Width;
    res(2) = expmt.video.vid.Height;
end
blank = zeros(res(2),res(1));
axh = imagesc(blank);

stop=get(gui_handles.accept_ROI_thresh_pushbutton,'value');

% Waits for "Accept Threshold" button press from user before accepting
% automatic ROI segmentation

clearvars hRect hText
hRect(1) = rectangle('Position',[0 0 0 0],'EdgeColor','r');
hText(1) = text(0,0,'1','Color','b');

while stop~=1;
    
    tic
    stop=get(gui_handles.accept_ROI_thresh_pushbutton,'value');

    % Take single frame
    if strcmp(expmt.source,'camera')
        trackDat.im = peekdata(expmt.camInfo.vid,1);
    else
        [trackDat.im, expmt.video] = nextFrame(expmt.video,gui_handles);
    end
    
    % Extract green channel if image is RGB
    if size(trackDat.im,3) > 1
        trackDat.im=trackDat.im(:,:,2);
    end

    % Update threshold value
    ROI_thresh=get(gui_handles.ROI_thresh_slider,'value');

    % Build a kernel to smooth vignetting for more even ROI segmentation
    gaussianKernel=buildGaussianKernel(size(trackDat.im,2),size(trackDat.im,1),sigma,kernelWeight);
    trackDat.im=(uint8(double(trackDat.im).*gaussianKernel));

    % Extract ROIs from thresholded image
    [ROI_bounds,ROI_coords,~,~,binaryimage] = detect_ROIs(trackDat.im,ROI_thresh);
    nROIs = size(ROI_coords,1);

    % Create orientation vector for mazes (upside down Y = 0, right-side up = 1)
    mazeOri = logical(zeros(nROIs,1));

    % Calculate coords of ROI centers
    [xCenters,yCenters]=ROIcenters(trackDat.im,binaryimage,ROI_coords);
    centers=[xCenters,yCenters];

    % Define a permutation vector to sort ROIs from top-right to bottom left
    [ROI_coords,mazeOri,ROI_bounds,centers]=sortROIs(ROI_coords,mazeOri,centers,ROI_bounds);

    % Report number of ROIs detected to GUI
    set(gui_handles.edit_object_num,'String',num2str(size(ROI_bounds,1)));

    % Display ROIs
    axh.CData = binaryimage;
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
            hText(i).Position = [centers(i,1)-5 centers(i,2) 0];
            
        elseif i > nROIs
            delete(hRect(i));
            delete(hText(i));
            idel = [idel i];
            
            
        elseif i > length(hRect)
            hRect(i) = rectangle('Position',ROI_bounds(i,:),'EdgeColor','r');
            if i > length(mazeOri) || mazeOri(i)
                hText(i) = text(centers(i,1)-5,centers(i,2),int2str(i),'Color','m');
            else
                hText(i) = text(centers(i,1)-5,centers(i,2),int2str(i),'Color','b');
            end
        end
        
    end
    hRect(idel) = [];
    hText(idel) = [];
    hold off
    set(gca,'Xtick',[],'Ytick',[]);
    drawnow


    % Report frames per sec to GUI
    set(gui_handles.edit_frame_rate,'String',num2str(round(1/toc)));
end

% Reset the accept threshold button
set(gui_handles.accept_ROI_thresh_pushbutton,'value',0);

% assign outputs
for i = 1:nargout  
    switch i
        case 1
            varargout{i} = ROI_coords;
        case 2
            varargout{i} = centers;
        case 3
            varargout{i} = mazeOri;
        case 4
            varargout{i} = ROI_bounds;
        case 5
            varargout{i} = binaryimage;
    end
end