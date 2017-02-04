function [varargout]=autoROIs(handles)
%
% Automatically detects light ROIs on a dark background and extracts
% their centroid coordinates and bounds. This function also detects
% and outputs the orientation of arenas with asymmetry about the
% horizontal axis (eg. Y shaped arenas). The function takes autotracker
% gui handles as an input 
% Inputs

clearvars -except handles
colormap('gray')

%% Define parameters - adjust parameters here to fix tracking and ROI segmentation errors

% import data from gui
expmt = getappdata(handles.figure1,'expmt');

% ROI detection parameters
ROI_thresh=get(handles.ROI_thresh_slider,'value');    % Binary image threshold from zero (black) to one (white) for segmentation  
sigma=0.47;                                 % Sigma expressed as a fraction of the image height
kernelWeight=0.34;                          % Scalar weighting of kernel when applied to the image

%% Setup the camera and video object

if strcmp(expmt.camInfo.vid.Running,'off')
    % Clear old video objects
    imaqreset
    pause(0.2);

    % Create camera object with input parameters
    expmt.camInfo = initializeCamera(expmt.camInfo);
    vid = expmt.camInfo.vid;
    start(vid);
    pause(0.1);
else
    vid = expmt.camInfo.vid;
end



%% Grab image for ROI detection and segment out ROIs

cla reset
res = vid.videoResolution;
blank = zeros(res(2),res(1));
axh = imagesc(blank);

stop=get(handles.accept_ROI_thresh_pushbutton,'value');

% Waits for "Accept Threshold" button press from user before accepting
% automatic ROI segmentation

clearvars hRect hText
hRect(1) = rectangle('Position',[0 0 0 0],'EdgeColor','r');
hText(1) = text(0,0,'','Color','m');

while stop~=1;
    
    tic
    stop=get(handles.accept_ROI_thresh_pushbutton,'value');

    % Take single frame
    imagedata=peekdata(vid,1);

    if size(imagedata,3) > 2
        % Extract green channel
        imagedata=imagedata(:,:,2);
    end

    % Update threshold value
    ROI_thresh=get(handles.ROI_thresh_slider,'value');

    % Build a kernel to smooth vignetting for more even ROI segmentation
    gaussianKernel=buildGaussianKernel(size(imagedata,2),size(imagedata,1),sigma,kernelWeight);
    imagedata=(uint8(double(imagedata).*gaussianKernel));

    % Extract ROIs from thresholded image
    [ROI_bounds,ROI_coords,ROI_widths,ROI_heights,binaryimage] = detect_ROIs(imagedata,ROI_thresh);
    nROIs = size(ROI_coords,1);

    % Create orientation vector for mazes (upside down Y = 0, right-side up = 1)
    mazeOri=logical(zeros(nROIs,1));

    % Calculate coords of ROI centers
    [xCenters,yCenters]=ROIcenters(imagedata,binaryimage,ROI_coords);
    centers=[xCenters,yCenters];

    % Define a permutation vector to sort ROIs from top-right to bottom left
    [ROI_coords,mazeOri,ROI_bounds,centers]=sortROIs(ROI_coords,mazeOri,centers,ROI_bounds);

    % Report number of ROIs detected to GUI
    set(handles.edit_object_num,'String',num2str(size(ROI_bounds,1)));

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
    set(handles.edit_frame_rate,'String',num2str(round(1/toc)));
end

% Reset the accept threshold button
set(handles.accept_ROI_thresh_pushbutton,'value',0);

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