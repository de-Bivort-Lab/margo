% Creates a movie with tracking overlay from an expmt master struct and raw
% movie file of the tracking. Set overlay parameters. Set parameters for
% the tracking over. Browse to the expmt .mat file, accompanying movie
% file, and select a save path for output video.

% Parameters
cen_marker = 'o';           % centroid marker style
cen_color = 'b';        % centroid marker color
trail_marker = '-';           % centroid marker style
trail_color = 'c';        % centroid marker color
trail_length = 120;        % centroid trail length (number of frames)
frame_rate = 60;        % output frame rate

%% get file paths

[ePath,eDir] = uigetfile('*.mat','Select a expmt .mat file containing centroid traces');
load([eDir,ePath]);
[movPath,movDir] = uigetfile({'*.avi;*.mp4;*.mov'},'Select accompanying raw movie file',eDir);
savePath = [movDir expmt.fLabel '_track_overlay'];
[SaveName,SaveDir] = uiputfile({'*.avi';'*.mov';'*.mp4'},'Select path and file name for output movie',savePath);



%%

% intialize video objects
rVid = VideoReader([movDir,movPath]);
wVid = VideoWriter([SaveDir,SaveName],'Motion JPEG AVI');
wVid.FrameRate = frame_rate;
wVid.Quality = 75;
if expmt.nFrames ~= rVid.NumberOfFrames
    error('frame number mismatch between tracking and video files');
end

% intialize axes and image
fh = figure('units','normalized','outerposition',[0 0 1 1]);
fh.Units = 'pixels';
fh.MenuBar = 'none';
fh.Name = 'Video Preview';
open(wVid);
fr = readFrame(rVid);
imh = image(fr);
imh.CDataMapping = 'scaled';
colormap('gray');
ah = gca;
ah.Units = 'normalized';
ah.Position = [0 0 1 1];
set(ah,'Xtick',[],'YTick',[],'Units','pixels');
dim = ah.Position(3:4);
ah.Position(3) = ah.Position(4)*(rVid.Width/rVid.Height);
fh.Position(3) = ah.Position(3);
ah.Units = 'normalized';
%ah.PlotBoxAspectRatioMode = 'manual';
ah.CLim = [0 255];
fh.Resize = 'off';

% initialize centroid markers
c = [squeeze(expmt.Centroid.map.Data.raw(:,1,2)),...
    squeeze(expmt.Centroid.map.Data.raw(:,2,2))];
trail = repmat(c,1,1,trail_length);
trail = permute(trail,[3,1,2]);
xidx = 1:numel(trail)/2;
yidx = numel(trail)/2+1:numel(trail);
hold on
th = plot(trail(xidx),trail(yidx),trail_marker,'Color',trail_color,'Parent',ah,'LineWidth',2);
pause(0.01);
eh = th.Edge;
eh.ColorType = 'truecoloralpha';
trail_cdata = repmat(eh.ColorData,1,trail_length);
trail_cdata(4,:) = uint8(linspace(255,1,trail_length));
trail_cdata(4,1) = 0;
trail_cdata = repmat(trail_cdata,1,1,expmt.nTracks);
trail_cdata = reshape(trail_cdata(:),4,numel(trail_cdata)/4);
set(eh,'ColorBinding','interpolated','ColorData',trail_cdata);
ch = plot(c(:,1),c(:,2),cen_marker,'Color',cen_color,'Parent',ah,'LineWidth',2.5);
pause(0.01);
ceh = ch.MarkerHandle;
ceh.EdgeColorType = 'truecoloralpha';
ceh.FaceColorData = ceh.EdgeColorData;
ceh.EdgeColorData = uint8([0;0;0;0]);
hold off



ct = 1;

while hasFrame(rVid)
    ct = ct+1;
    fr = readFrame(rVid);
    if size(fr,3)>1
        fr = fr(:,:,2);
    end
    imh.CData = fr;
    c = [squeeze(expmt.Centroid.map.Data.raw(:,1,ct)),...
    squeeze(expmt.Centroid.map.Data.raw(:,2,ct))];
    ceh.VertexData(1,:) = c(:,1)';
    ceh.VertexData(2,:) = c(:,2)';
    trail = circshift(trail,1,1);
    trail(1,:,1) = c(:,1);
    trail(1,:,2) = c(:,2);
    th.XData = trail(xidx);
    th.YData = trail(yidx);
    drawnow
    im_out = getframe(ah);
    writeVideo(wVid,im_out.cdata);
end

close(wVid);
