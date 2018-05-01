function parseCeilingBouts(a_map,s_map,nt,nf)

% query available memory to determine how many batches to process data in
[umem,msz] = memory;
msz = msz.PhysicalMemory.Available;
switch a_map.Format{1}
    case 'single', prcn = 4;
    case 'double', prcn = 8;
end
nbatch = msz / (prcn * nf * nt * 8);
if nbatch < 1
    bsz = floor(nf * nbatch);
else
    bsz = nf;
end

idx = randi(nf,[bsz 1]);

hwb = waitbar(0,['processing trace 1 of ' num2str(nt)],'Name','Parsing floor/ceiling bouts');
thresh = NaN(nt,1);


for i = 1:nt
    
    if ishghandle(hwb)
        waitbar(i/nt,hwb,...
            ['processing trace ' num2str(i) ' of ' num2str(nt)]);
    end
    tic
    % find threshold for each individual
    moving = s_map.Data.raw(i,:) > 0.8; 
    moving = moving > 0.8;
    a= a_map.Data.raw(i,:);
    a(~moving) = NaN;
    toc

    [ints,means,sigmas] = fitBimodalHist(a);
    [ints,means,sigmas] = cellfun(@fitBimodalHist,a,'UniformOutput',false);
    
    expmt.Area.thresh(~cellfun(@isempty,ints)) = [ints{:}];
    expmt.Area.modeMeans = NaN(nt,2);
    expmt.Area.modeMeans(~cellfun(@isempty,means),:) = [means{:}]';
    expmt.Area.modeSigmas = NaN(nt,2);
    expmt.Area.modeSigmas(~cellfun(@isempty,sigmas),:) = [sigmas{:}]';
    
    % parse data into arena ceiling and floor frames
    ints(cellfun(@isempty,ints))={NaN};
    expmt.Area.ceiling = cellfun(@(x,y) x>y, a,ints,'UniformOutput',false);
    expmt.Area.ceiling = cat(1,expmt.Area.ceiling{:});
    expmt.Area.floor = cellfun(@(x,y) x<y, a,ints,'UniformOutput',false);
    expmt.Area.floor = cat(1,expmt.Area.floor{:});
    clear a moving
    
    % get gravity index
    expmt.Gravity.index = (sum(expmt.Area.ceiling,2)-sum(expmt.Area.floor,2))./...
        (sum(expmt.Area.ceiling,2)+sum(expmt.Area.floor,2));   
end
toc