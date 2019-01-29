function expmt = parseCeilingBouts(expmt)

% initialize waitbar
hwb = waitbar(0,['processing trace 1 of ' num2str(expmt.meta.num_traces)],'Name','Parsing floor/ceiling bouts');

% initialize placeholder values
thresh = NaN(expmt.meta.num_traces,1);
means = NaN(expmt.meta.num_traces,2)';
sigmas = NaN(expmt.meta.num_traces,2)';

% add new properties to area
props = {'ceiling';'floor';'thresh';'mean';'sigma';'gravity_index'};
addprops(expmt.data.area, props);
expmt.data.area.ceiling = false(expmt.meta.num_frames,expmt.meta.num_traces);
expmt.data.area.floor = false(expmt.meta.num_frames,expmt.meta.num_traces);

% find area threshold for each trace separately
for i = 1:expmt.meta.num_traces
    
    if ishghandle(hwb)
        waitbar(i/expmt.meta.num_traces,hwb,...
            ['processing trace ' num2str(i) ' of ' num2str(expmt.meta.num_traces)]);
    end

    % find threshold for each individual
    moving = autoSlice(expmt,'speed',i) > 0.8;
    a= autoSlice(expmt,'area',i);
    a(~moving) = NaN;

    % find upper and lower area modes
    [tmp_i,tmp_means,tmp_sig] = fitBimodalHist(a);
    if ~isempty(tmp_i)
        thresh(i) = tmp_i;
        means(:,i) = tmp_means;
        sigmas(:,i) = tmp_sig;
    end
    
    % parse data into arena ceiling and floor frames
    expmt.data.area.ceiling(:,i) = a > thresh(i);
    expmt.data.area.floor(:,i) = a < thresh(i);
    clear a moving

end

if ishghandle(hwb)
    delete(hwb);
end

% record means and standard deviations
expmt.data.area.mean = means;
expmt.data.area.sigma = sigmas;
expmt.data.area.thresh = thresh;

% get gravity index
expmt.data.area.gravity_index =...
    (sum(expmt.data.area.ceiling,1)-sum(expmt.data.area.floor,1))'./...
    (sum(expmt.data.area.ceiling,1)+sum(expmt.data.area.floor,1))';   

