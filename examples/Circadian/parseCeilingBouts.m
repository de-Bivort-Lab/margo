function expmt = parseCeilingBouts(expmt)

% initialize waitbar
hwb = waitbar(0,['processing trace 1 of ' num2str(expmt.meta.num_traces)],'Name','Parsing floor/ceiling bouts');

% initialize placeholder values
area_thresholds = cell(expmt.meta.num_traces,1);
mode_means = cell(expmt.meta.num_traces,1);
Area = cell(expmt.meta.num_traces,1);

% add new properties to area
props = {'ceiling';'floor';'thresh';'mean';'sigma';'gravity_index'};
addprops(expmt.data.area, props);
expmt.data.area.ceiling = false(expmt.meta.num_frames,expmt.meta.num_traces);
expmt.data.area.floor = false(expmt.meta.num_frames,expmt.meta.num_traces);


[spd_thresh,~] = kthresh_distribution(log(expmt.data.speed.raw(:)));
spd_thresh = exp(spd_thresh);

% reset maps
reset(expmt);

% find area threshold for each trace separately
for i = 1:expmt.meta.num_traces
    
    if ishghandle(hwb)
        waitbar(i/expmt.meta.num_traces,hwb,...
            ['processing trace ' num2str(i) ' of ' num2str(expmt.meta.num_traces)]);
    end
    

    % find threshold for each individual
    moving = autoSlice(expmt,'speed',i) > spd_thresh;
    a= autoSlice(expmt,'area',i);
    if ~any(mod(a,1))
        a = a.*expmt.parameters.mm_per_pix^2;     
    end
    moving = moving & a > 180*expmt.parameters.mm_per_pix^2;
    a(~moving) = NaN;
    Area{i} = a(~isnan(a));

    % find upper and lower area modes
    [thresh,means] = kthresh_distribution(a);
    if isempty(thresh)
       thresh = NaN;
       means = [NaN NaN];
    end
    area_thresholds{i} = thresh;
    mode_means{i} = means;
    
    % parse data into arena ceiling and floor frames
    expmt.data.area.ceiling(:,i) = a > thresh;
    expmt.data.area.floor(:,i) = a < thresh;
    clear a moving

end

if ishghandle(hwb)
    delete(hwb);
end

% plot individual distributions
f=figure;
nCols = ceil(0.125*expmt.meta.num_traces);
nRows = ceil(expmt.meta.num_traces/nCols);
for i=1:expmt.meta.num_traces
    subplot(nRows,nCols,i);
    if ~isempty(area_thresholds{i}) && ~isnan(area_thresholds{i})
        [kde,x] = ksdensity(Area{i});
        plot(x,kde,'k','LineWidth',1);
        hold on
        y = get(gca,'YLim');
        vx = [repmat([mode_means{i}(1) mode_means{i}(2)],2,1); NaN(1,2)];
        vy = repmat([y'; NaN],1,2);
        plot(vx(:),vy(:),'b','LineWidth',0.5);
        plot([area_thresholds{i} area_thresholds{i}],y,'r','LineWidth',0.5);
        hold off
    end
    if mod(i,nCols)==1
        ylabel('density');
    end
    if i>nCols*(nRows-1)
        xlabel('area');
    end
end
f.Position = [1 1 1280 960];

% save fig
fname = [expmt.meta.path.fig expmt.meta.date '_individual_area_thresholds'];
if ~isempty(expmt.meta.path.fig)
    hgsave(f,fname);
    close(f);
end

% record means and standard deviations
expmt.data.area.mean = mode_means;
expmt.data.area.thresh = area_thresholds;

% get gravity index
expmt.data.area.gravity_index =...
    (sum(expmt.data.area.ceiling,1)-sum(expmt.data.area.floor,1))'./...
    (sum(expmt.data.area.ceiling,1)+sum(expmt.data.area.floor,1))';   

