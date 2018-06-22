function expmt = parseCeilingBouts(expmt)

% query available memory to determine how many batches to process data in
[umem,msz] = memory;
msz = msz.PhysicalMemory.Available;
switch expmt.area.map.Format{1}
    case 'single', prcn = 4;
    case 'double', prcn = 8;
end

nbatch = msz / (prcn * expmt.meta.num_frames * expmt.meta.num_traces * 8 * 10);
if nbatch < 1
    bsz = floor(expmt.meta.num_frames * nbatch);
else
    bsz = expmt.meta.num_frames;
end

idx = round(linspace(1,expmt.meta.num_frames,bsz));


hwb = waitbar(0,['processing trace 1 of ' num2str(expmt.meta.num_traces)],'Name','Parsing floor/ceiling bouts');
thresh = NaN(expmt.meta.num_traces,1);
ints = NaN(expmt.meta.num_traces,1);
means = NaN(expmt.meta.num_traces,2)';
sigmas = NaN(expmt.meta.num_traces,2)';
expmt.area.ceiling = false(expmt.meta.num_frames,expmt.meta.num_traces);
expmt.area.floor = false(expmt.meta.num_frames,expmt.meta.num_traces);


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
        ints(i) = tmp_i;
        means(:,i) = tmp_means;
        sigmas(:,i) = tmp_sig;
    end
    
    % parse data into arena ceiling and floor frames
    expmt.area.ceiling(:,i) = a > ints(i);
    expmt.area.floor(:,i) = a < ints(i);
    clear a moving

end

if ishghandle(hwb)
    delete(hwb);
end

% get gravity index
expmt.Gravity.index = (sum(expmt.area.ceiling,1)-sum(expmt.area.floor,1))'./...
    (sum(expmt.area.ceiling,1)+sum(expmt.area.floor,1))';   

