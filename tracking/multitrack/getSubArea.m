function [sub_area, sub_length] = getSubArea(erode_ims, ref)
% initialize graphics handles
ih = imagesc(ref);
colormap('gray');
hold on
init_cen = cat(1,ROI_cen{:});
ph = plot(init_cen(:,1),init_cen(:,2), 'ro');
th = text(init_cen(:,1),init_cen(:,2),...
        cellfun(@num2str,num2cell(1:length(init_cen)),...
        'UniformOutput',false),'Color',[1 0 1], ...
        'HorizontalAlignment','center');
text_shift = -10;
th_fps = text(size(ref,2)*0.1,size(ref,1)*0.1,'0',...
             'Color',[1 0 1],'HorizontalAlignment','center');
hold off

% set time variables
tic
t_elapsed = 0;
t_update = cell(expmt.ROI.n,1);
t_update(:) = {zeros(traces_per_roi,1)};
t_prev = toc;
pause(0.2);

%% apply thresholds
    % read video, get threshold image
    while ct <= num_frames

        % update time-keeping
        ct = ct+1;
        t_curr = toc;
        t_elapsed = t_elapsed + t_curr - t_prev;
        t_prev = t_curr;

        frame = read(vid,ct);
        if size(frame,3)>1
            frame = frame(:,:,2);
        end
        diffim = frame-ref;
        thresh_im = diffim > thresh;
        ih.CData = frame;

        % apply area threshold before assigning centroids
        above_min = [s.Area] .* (expmt.parameters.mm_per_pix^2) > ...
            expmt.parameters.area_min;
        below_max = [s.Area] .* (expmt.parameters.mm_per_pix^2) < ...
            expmt.parameters.area_max;
        s(~(above_min & below_max)) = [];

        centroids = cat(1, s.Centroid);

        candidate_ROI_cen = assignROI(centroids, expmt);

        [ROI_cen, t_update] = ...
            cellfun(@(x,y,z) sortROI_multitrack(x, y, z, t_curr, ...
                    spd_thresh), ROI_cen, candidate_ROI_cen, t_update,...
                    'UniformOutput',false);
        all_cen = cat(1,ROI_cen{:});

        % update centroid markers
        ph.XData = all_cen(:,1);
        ph.YData = all_cen(:,2);

        % update text markers
        arrayfun(@updateText,all_cen(:,1), all_cen(:,2) + text_shift, th);
        th_fps.String = num2str(1/(toc-t_curr),3);
        drawnow limitrate

    end
%% find blob areas and major axis lengths in sub-images
props = cellfun(@(x) regionprops(x,'Area', 'MajorAxisLength'), erode_ims, ...
                  'UniformOutput', false);
sub_area = cat(1,props{:}.Area);
sub_length = cat(1,props{:}.MajorAxisLength);
                
                
                
                
                