function traces_per_roi = estTracesperROI

vidPath = ['C:\Users\debivortlab\Documents\MATLAB\autotracker_data\Gary\48_well_sample\07-19-2018-13-40-55__Basic_Tracking__1-48_Day1_VideoData.mp4'];
vid = VideoReader(vidPath);

load('C:\Users\debivortlab\Documents\MATLAB\autotracker_data\Gary\48_well_sample\07-19-2018-13-40-55__Basic_Tracking__1-48_Day1.mat');

% get reference image
ref = expmt.meta.ref.im;
% num_frames = vid.NumberOfFrames;
% sample_frames = randperm(num_frames,10);
% ref_stack =  arrayfun(@(x) read(vid,x), ...
%                         sample_frames, 'UniformOutput',false);
% ref_stack = cat(3,ref_stack{:});
% ref = median(ref_stack,3);
% 
% expmt.ROI.n = 48;
% expmt.ROI.centers = repmat([vid.Height/2 vid.Width/2], expmt.ROI.n ,1);
% expmt.ROI.corners = [1 1 vid.Width vid.Height];
% expmt.parameters.track_thresh = 30;
% expmt.parameters.mm_per_pix = 1;
% expmt.parameters.area_min = 5;
% expmt.parameters.area_max = 1000;

traces_per_roi = 50;
ROI_cen = arrayfun(@(x) repmat(expmt.meta.roi.centers(x,:),traces_per_roi,1),...
                        1:expmt.meta.roi.n, 'UniformOutput',false)';

max_trace_count = 40;
trace_init = {ones(traces_per_roi,1).*max_trace_count};
trace_duration = repmat(trace_init, expmt.meta.roi.n, 1);

thresh = expmt.parameters.track_thresh;
spd_thresh = 150;

ct = 0;
% initialize graphics handles
ih = imagesc(ref);
colormap('gray');
hold on
init_cen = cat(1,ROI_cen{:});
ph = plot(init_cen(:,1),init_cen(:,2), 'ro');
%{
th = text(init_cen(:,1),init_cen(:,2),...
        cellfun(@num2str,num2cell(1:length(init_cen)),...
        'UniformOutput',false),'Color',[1 0 1], ...
        'HorizontalAlignment','center');
%}
text_shift = -15;
th_fps = text(size(ref,2)*0.1,size(ref,1)*0.1,'0',...
             'Color',[1 0 1],'HorizontalAlignment','center');
hold off

% set time variables
tic
t_elapsed = 0;
t_update = cell(expmt.meta.roi.n,1);
t_update(:) = {zeros(traces_per_roi,1)};
t_prev = toc;
pause(0.2);

can_t_update = cell(expmt.meta.roi.n,1);
can_newtrace = cell(expmt.meta.roi.n,1);
can_duration = cell(expmt.meta.roi.n,1);

%%
area_bounds = [expmt.parameters.area_min expmt.parameters.area_max];
[area_samples, cen_dist] = ...
    sampleAreaDist(vid,ref,area_bounds,thresh,50);
area_thresh = median(area_samples).*1.5;
%% tracking loop
% read video, get threshold image
while ct <= ceil(expmt.meta.num_frames * 1)

    % update time-keeping
    ct = ct+1;
    t_curr = toc;
    t_elapsed = t_elapsed + t_curr - t_prev;
    t_prev = t_curr;

    frame = read(vid,ct);
    if size(frame,3)>1
        frame = frame(:,:,2);
    end
    diffim = ref-frame;
    thresh_im = diffim > thresh;
    ih.CData = frame;
    
    % plot threshold image
    s = regionprops(thresh_im,'Centroid','Area','PixelList');

    %[centroids, new_area] = erodeDoubleBlobs(s, area_thresh);
    centroids = cat(1,s.Centroid);
    new_area = cat(1,s.Area);

    % apply area threshold before assigning centroids
    above_min = new_area .* (expmt.parameters.mm_per_pix^2) > ...
        expmt.parameters.area_min;
    below_max = new_area .* (expmt.parameters.mm_per_pix^2) < ...
        expmt.parameters.area_max;
    centroids(~(above_min & below_max),:) = [];

    candidate_ROI_cen = assignROI(centroids, expmt);

    [ROI_cen, t_update, trace_updated, blob_assigned] = ...
        cellfun(@(x,y,z) sortROI_multitrack(x, y, z, ...
                t_curr, spd_thresh), ROI_cen, ...
                candidate_ROI_cen, t_update, ...
                'UniformOutput',false);          
    
    trace_duration = cellfun(@(x,y) updateTraceDuration(x, y, ...
                             max_trace_count), trace_duration, ...
                             trace_updated, 'UniformOutput', false);
            
    [ROI_cen, t_update] = cellfun(@(x,y,z) deleteLostTraces(x,y,z), ...
                                  ROI_cen, trace_duration, t_update, ...
                                  'UniformOutput', false);
                              
    unassigned_blobs = cellfun(@(x,y) x(~y,:), candidate_ROI_cen, ... 
                           blob_assigned, 'UniformOutput', false);
    
                       
    [can_newtrace, can_t_update, trace_updated, blob_assigned] = ...
        cellfun(@(x,y,z) sortROI_multitrack(x, y, z, t_curr, ...
                spd_thresh), can_newtrace, unassigned_blobs, can_t_update, ...
                'UniformOutput', false);  
            
    can_duration = cellfun(@(x,y) updateTraceDuration(x, y, ...
                           max_trace_count), can_duration, ...
                           trace_updated, 'UniformOutput', false);
                               
    [new_traces, can_newtrace, can_duration, can_t_update] = ...
                      cellfun(@(x,y,z,ba,t) getNewTraces(x, y, z, ba, ...
                      max_trace_count, t, t_elapsed), unassigned_blobs,...
                      can_duration, can_newtrace, blob_assigned, ...
                      can_t_update, 'UniformOutput', false);
                  
    [ROI_cen, trace_duration, t_update] = cellfun(@(x,y,z,t) ...
                      addNewTraces(x,y,z,t, max_trace_count, ...
                      t_elapsed), new_traces, ROI_cen, trace_duration, ...
                      t_update, 'UniformOutput', false);

    all_cen = cat(1,ROI_cen{:});


    % update centroid markers
    ph.XData = all_cen(:,1);
    ph.YData = all_cen(:,2);

    % update text markers
    %arrayfun(@updateText,all_cen(:,1), all_cen(:,2) + text_shift, th);
    th_fps.String = num2str(1/(toc-t_curr),3);
    drawnow limitrate

end

traces_per_roi = cellfun(@(x) sum(~isnan(x)), t_update, ...
                         'UniformOutput', false);
    
                     
function updateText(x,y,text_handle)
%% update text handles   
text_handle.Position([1 2]) = [x y];


