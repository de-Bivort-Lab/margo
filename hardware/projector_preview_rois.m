function projector_preview_rois(expmt)

% Initialize the psychtoolbox window and query projector properties
bg_color=[0 0 0];          
expmt = initialize_projector(expmt, bg_color);
Fx = expmt.hardware.projector.Fx;
Fy = expmt.hardware.projector.Fy;
pause(0.5);

% Calculate ROI coords in the projector space and expand the edges 
nROIs = expmt.meta.roi.n;
scor = NaN(size(expmt.meta.roi.corners));
rcor = expmt.meta.roi.corners;
scen = NaN(nROIs,2);
rcen = expmt.meta.roi.centers;

% convert ROI centers to projector coordinates for stimulus targeting
scen(:,1) = Fx(rcen(:,1),rcen(:,2));
scen(:,2) = Fy(rcen(:,1),rcen(:,2));

% convert ROI corners
scor(:,1) = Fx(rcor(:,1), rcor(:,2));   
scor(:,2) = Fy(rcor(:,1), rcor(:,2));
scor(:,3) = Fx(rcor(:,3), rcor(:,4));
scor(:,4) = Fy(rcor(:,3), rcor(:,4));

% add a buffer to stim bounding box to ensure entire ROI is covered
sbbuf = nanmean([scor(:,3)-scor(:,1), scor(:,4)-scor(:,2)],2)*0.05;
scor(:,[1 3]) = [scor(:,1)-sbbuf, scor(:,3)+sbbuf];
scor(:,[2 4]) = [scor(:,2)-sbbuf, scor(:,4)+sbbuf];

% Determine stimulus size by calculating mean ROI edge length
stim.sz=round(nanmean(nanmean([scor(:,3)-scor(:,1) scor(:,4)-scor(:,2)])));
src_edge_length = stim.sz;
stim.sz=ceil(sqrt(stim.sz^2+stim.sz^2));

% Initialize the stimulus image
stim.im = zeros(stim.sz);
stim.im(:,1:10)=1;
stim.im(1:10,:)=1;
stim.im(:,stim.sz-9:stim.sz)=1;
stim.im(stim.sz-9:stim.sz,:)=1;

% Initialize source rect and scaling factors
stim.base = [0 0 stim.sz stim.sz];
stim.source = CenterRectOnPointd(stim.base,stim.sz/2,stim.sz/2);

% make the texture from stimuls image
stim.Tex = Screen('MakeTexture', expmt.hardware.screen.window, stim.im);
stim.corners = scor;
stim.centers = scen;

% Pass photo stimulation textures to screen
scr = expmt.hardware.screen;
Screen('DrawTextures', scr.window, stim.Tex, stim.source', ...
    stim.corners', [], [], [], [],[], []);

% Flip to the screen
scr.vbl = Screen('Flip', scr.window,scr.vbl +(scr.waitframes - 0.5)* scr.ifi);