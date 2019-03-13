function expmt = analyze_slowphototaxis(expmt,varargin)
%
% This function provides a sample analysis function to run after the
% sample bare-bones template 'experimental_template.m'. It takes the
% experimental master data struct (expmt) as an input, processes the data
% to extract features and store them to file. This sample also shows how to
% automatically zip the raw data files after analysis to reduce file size.

%% Parse inputs, read data from hard disk, format in master struct, process centroid data

[expmt,options] = autoDataProcess(expmt,varargin{:});

clearvars -except expmt options

%% Analyze stimulus response

% Convert centroid data to projector space
x=double(expmt.data.centroid.raw(:,1,:));
y=double(expmt.data.centroid.raw(:,2,:));
proj_x = expmt.hardware.projector.Fx(x,y);
proj_y = expmt.hardware.projector.Fy(x,y);
clearvars x y
[div_dist,in_Light] = ...
    parseShadeLight(expmt.data.StimAngle.raw, ...
        proj_x, proj_y, expmt.meta.stim.centers, 0);

% Calculate mean distance to divider for each fly
avg_d = cellfun(@mean,div_dist);

% get stimulus transitions
stim_trans = diff([1;expmt.data.Texture.raw(:)]);
expmt.meta.Light.blocks = find(stim_trans==1);
expmt.meta.Light.nBlocks = length(expmt.meta.Light.blocks);
expmt.meta.Blank.blocks = find(stim_trans==-1);
expmt.meta.Blank.nBlocks = length(expmt.meta.Blank.blocks);

% get indices of stim endings
iOFF = expmt.meta.Blank.blocks - 1;
iOFF = iOFF(iOFF>1);
if iOFF(end) < expmt.meta.Light.blocks(end)
    iOFF = [iOFF;length(stim_trans)];
end
expmt.meta.Light.blocks = [expmt.meta.Light.blocks iOFF];
lb = num2cell(expmt.meta.Light.blocks,2);

iOFF = expmt.meta.Light.blocks(:,1) - 1;
iOFF = iOFF(iOFF>0);
if iOFF(end) < expmt.meta.Blank.blocks(end)
    iOFF = [iOFF;length(stim_trans)];
end
expmt.meta.Blank.blocks = [expmt.meta.Blank.blocks iOFF];
bb = num2cell(expmt.meta.Blank.blocks,2);


% get divider distance threshold for each ROI
div_thresh = ...
    (mean(expmt.meta.roi.bounds(:,[3 4]),2) .* ...
        expmt.parameters.divider_size * 0.5)';

% Initialize light occupancy variables
expmt.meta.Light.include = cell(expmt.meta.num_traces,1);
expmt.meta.Light.occ = cell(expmt.meta.num_traces,1);
expmt.meta.Light.tOcc = cell(expmt.meta.num_traces,1);
expmt.meta.Light.tInc = cell(expmt.meta.num_traces,1);
expmt.meta.Light.tDiv = cell(expmt.meta.num_traces,1);

% Initialize blank stimulus occupancy variables
expmt.meta.Blank.include = cell(expmt.meta.num_traces,1);
expmt.meta.Blank.occ = cell(expmt.meta.num_traces,1);
expmt.meta.Blank.tOcc = cell(expmt.meta.num_traces,1);
expmt.meta.Blank.tInc = cell(expmt.meta.num_traces,1);
expmt.meta.Blank.tDiv = cell(expmt.meta.num_traces,1);

reset(expmt);
% Calculate occupancy for each fly in both blank and photo_stim conditions
for i=1:expmt.meta.num_traces
    
    % When one half of the arena is lit
    off_divider = abs(div_dist{i})>div_thresh(i)*2;      
    include = off_divider & expmt.data.Texture.raw(:);
    [occ,tOcc,tInc,tDiv,~] = ...
        arrayfun(@(k) parseBlocks(k,include,... 
            in_Light{i},expmt.data.time.raw(:)), lb, 'UniformOutput',false);
    expmt.meta.Light.include{i} = include;                                
    expmt.meta.Light.tOcc{i} = cat(1,tOcc{:});                              
    expmt.meta.Light.tInc{i} = cat(1,tInc{:});              
    expmt.meta.Light.tDiv{i} = cat(1,tDiv{:});         
    expmt.meta.Light.occ{i} = cat(1,occ{:});       
    clearvars occ tOcc tInc tDiv inc
    
    % When both halfs of the arena are unlit
    include = off_divider & ~expmt.data.Texture.raw(:);
    [occ,tOcc,tInc,tDiv,~] = ...
        arrayfun(@(k) parseBlocks(k,include,...  
            in_Light{i},expmt.data.time.raw(:)), bb, 'UniformOutput',false);
    expmt.meta.Blank.include{i} = include;                                
    expmt.meta.Blank.tOcc{i} = cat(1,tOcc{:});                              
    expmt.meta.Blank.tInc{i} = cat(1,tInc{:});              
    expmt.meta.Blank.tDiv{i} = cat(1,tDiv{:});         
    expmt.meta.Blank.occ{i} = cat(1,occ{:});  
    clearvars occ tOcc tInc tDiv inc
end

tTotal = cellfun(@nansum, expmt.meta.Light.tInc);
btTotal = cellfun(@nansum, expmt.meta.Blank.tInc);
locc = cellfun(@nanmean, expmt.meta.Light.occ);
locc = (locc - (1-locc));
bocc = cellfun(@nanmean, expmt.meta.Blank.occ);
bocc = (bocc - (1-bocc));
min_active_period = 0.2 * ...
    nansum(expmt.data.time.raw(expmt.data.Texture.raw(:)))/3600; 
clearvars -except expmt tTotal btTotal locc bocc options min_active_period


%% Get centroid relative to stimulus

has_radius = any(strcmpi(expmt.meta.fields,'Radius'));
has_theta = any(strcmpi(expmt.meta.fields,'Theta'));

if has_radius && has_theta
    
    
    stimang = expmt.data.StimAngle.raw();
    stimang(stimang>180)=stimang(stimang>180)-360;
    stimang = stimang * pi ./ 180;
    cen_theta = expmt.data.Theta.raw() - stimang;
    clearvars stimang

    stim_cen = NaN(size(expmt.data.centroid.raw()));
    stim_cen(:,1,:) = expmt.data.Radius.raw() .* cos(cen_theta);
    stim_cen(:,2,:) = expmt.data.Radius.raw() .* sin(cen_theta);
    stim_cen = squeeze(num2cell(stim_cen,[1 2]));
    light_sc = cellfun(@(sc,inc,r) sc(inc,:)./r, ...
        stim_cen, expmt.meta.Light.include, ...
        num2cell(max(expmt.data.Radius.raw()))',...
        'UniformOutput',false);
    blank_sc = cellfun(@(sc,inc,r) sc(inc,:)./r, ...
        stim_cen, expmt.meta.Blank.include, ...
        num2cell(max(expmt.data.Radius.raw()))',...
        'UniformOutput',false);
    clear stim_cen
    
    gridpts = linspace(-1,1,25);
    [x y] = meshgrid(gridpts, gridpts);
    gridpts = [x(:) y(:)];
    active = tTotal > min_active_period &  btTotal > min_active_period*.1;
    %active = true(48,1);
    light_densities = cellfun(@(sc) ksdensity(sc,gridpts),...
                    light_sc(active), 'UniformOutput',false);
    blank_densities = cellfun(@(sc) ksdensity(sc,gridpts),...
                    blank_sc(active), 'UniformOutput',false);
      
    
    if isfield(expmt.meta,'speed') && isfield(expmt.meta.speed,'bouts')
        [expmt, n, ft] = excludeTrialBoundaryBouts(expmt);
        n = cat(1,n{:});
        ft = cat(1,ft{:});
        [fh1, fh2, expmt] = stimBoutDistibutions(expmt);
        
        fname = [expmt.meta.path.fig expmt.meta.date '_boutlength_dist'];
        if ~isempty(expmt.meta.path.fig) && options.save
            hgsave(fh1,fname);
            close(fh1);
        end
        
        fname = [expmt.meta.path.fig expmt.meta.date '_boutnum_dist'];
        if ~isempty(expmt.meta.path.fig) && options.save
            hgsave(fh2,fname);
            close(fh2);
        end

    end
    
    
    stim_cen = NaN(size(expmt.data.centroid.raw()));
    stim_cen(:,1,:) = expmt.data.Radius.raw() .* cos(cen_theta);
    stim_cen(:,2,:) = expmt.data.Radius.raw() .* sin(cen_theta);
    stim_cen = squeeze(num2cell(stim_cen,[1 2]));
    light_sc = cellfun(@(sc,inc,r) sc(inc,:)./r, ...
        stim_cen, expmt.meta.Light.include, ...
        num2cell(max(expmt.data.Radius.raw()))',...
        'UniformOutput',false);
    blank_sc = cellfun(@(sc,inc,r) sc(inc,:)./r, ...
        stim_cen, expmt.meta.Blank.include, ...
        num2cell(max(expmt.data.Radius.raw()))',...
        'UniformOutput',false);
    clear stim_cen
    
    ld = cellfun(@(sc) ksdensity(sc,gridpts),...
                    light_sc(active), 'UniformOutput',false);
    bd = cellfun(@(sc) ksdensity(sc,gridpts),...
                    blank_sc(active), 'UniformOutput',false);
    
    
    nCol = ceil(sqrt(numel(light_densities))*1.8);
    nRow = ceil(numel(light_densities)/nCol);
    fh = figure;
    colormap('jet');
    idx = find(active);
    for i=1:numel(idx)
        ah = subplot(nRow,nCol,i);
        lhm = light_densities{i};
        lhm = lhm ./ sum(lhm);
        lhm = reshape(lhm,sqrt(numel(lhm)),sqrt(numel(lhm)));
        bhm = blank_densities{i};
        bhm = bhm ./ sum(bhm);
        bhm = reshape(bhm,sqrt(numel(bhm)),sqrt(numel(bhm)));
        ldhm = ld{i};
        ldhm = ldhm ./ sum(ldhm);
        ldhm = reshape(ldhm,sqrt(numel(ldhm)),sqrt(numel(ldhm)));
        bdhm = bd{i};
        bdhm = bdhm ./ sum(bdhm);
        bdhm = reshape(bdhm,sqrt(numel(bdhm)),sqrt(numel(bdhm)));
        imagesc([lhm bhm; ldhm bdhm]);
        ah.XTick = [];
        ah.YTick = [];
        %title(sprintf('%i',idx(i)));
        ylabel(sprintf('%0.2f',locc(idx(i))));
        xlabel(sprintf('%0.2f \t %0.2f\n(%0.1G) \t (%0.1G)',...
            ft(idx(i),1),ft(idx(i),2),n(idx(i),1),n(idx(i),2)));
        axis tight equal;
    end  
    
    fname = [expmt.meta.path.fig expmt.meta.date '_heatmaps'];
    if ~isempty(expmt.meta.path.fig) && options.save
        hgsave(fh,fname);
        close(fh);
    end
end


%% Bootstrap data to measure overdispersion

nReps = 1000;
[expmt.meta.Light.bs,f] = bootstrap_slowphototaxis(expmt,nReps,'Light');
fname = [expmt.meta.path.fig expmt.meta.date '_light_bs'];
if ~isempty(expmt.meta.path.fig) && options.save
    hgsave(f,fname);
    close(f);
end

if isfield(expmt.parameters,'blank_duration') && ...
        expmt.parameters.blank_duration > 0
    
    [expmt.meta.Blank.bs,f] = bootstrap_slowphototaxis(expmt,nReps,'Blank');
    fname = [expmt.meta.path.fig expmt.meta.date '_dark_bs'];
    if ~isempty(expmt.meta.path.fig) && options.save
        hgsave(f,fname);
        close(f);
    end
    
end


%% Generate plots

% Minimum time spent off the boundary divider (hours)       
active = tTotal > min_active_period;

fh = autoPlotDist(locc, active);

if isfield(expmt.parameters,'blank_duration') && ...
        expmt.parameters.blank_duration > 0
    
    active = btTotal > min_active_period;
    fh = autoPlotDist(bocc, active, gca);
end

% Generate legend labels
strain='';
treatment='';
if isfield(expmt,'Strain')
    strain=expmt.meta.strain;
end
if isfield(expmt,'Treatment')
    treatment=expmt.meta.treatment;
end

% light ON label
active = tTotal > min_active_period;
light_avg = mean(locc(active));
light_mad = mad(locc(active));
n = sum(active);
legendLabel = cell(2,1);
legendLabel(2)={...
    sprintf('Stim ON: %s (u=%0.2f, MAD=%0.2f, n=%i)',...
        strain, light_avg, light_mad, n)...
    };

if isfield(expmt.parameters,'blank_duration') && ...
        expmt.parameters.blank_duration > 0
    
    % light OFF label
    active = btTotal > min_active_period;
    blank_avg = mean(bocc(active));
    blank_mad = mad(bocc(active));
    n = sum(active);
    legendLabel(1)={...
        sprintf('Stim OFF: %s (u=%0.2f, MAD=%0.2f, n=%i)',...
            strain, blank_avg, blank_mad, n)...
        };
end
legend(legendLabel);
shg
xlabel('phototactic index');
ylabel('probability density');

fname = [expmt.meta.path.fig expmt.meta.date '_histogram'];
if ~isempty(expmt.meta.path.fig) && options.save
    hgsave(fh,fname);
    close(fh);
end


% Save data to struct
expmt.meta.Light.avg_occ = locc;
expmt.meta.Blank.avg_occ = bocc;
expmt.meta.Light.active = tTotal>min_active_period & active;
expmt.meta.Blank.active = btTotal>min_active_period & active;

%% Extract handedness from lights ON and lights OFF periods
%{
% blank period
first_half = false(size(trackProps.speed));
first_half(1:round(length(first_half)/2),:) = true;
inc = first_half & trackProps.speed >0.8;
expmt.handedness_First = getHandedness(trackProps,'Include',inc);
inc = repmat(~expmt.data.Texture.raw,1,expmt.meta.num_traces) & trackProps.speed >0.8;
expmt.handedness_Blank = getHandedness(trackProps,'Include',inc);
 inc = ~first_half & trackProps.speed >0.8;
expmt.handedness_Second = getHandedness(trackProps,'Include',inc);
inc = repmat(expmt.data.Texture.raw,1,expmt.meta.num_traces) & trackProps.speed >0.8;
expmt.handedness_Light = getHandedness(trackProps,'Include',inc);

if isfield(options,'plot') && options.plot
    if isfield(options,'handles')
        gui_notify('generating plots',options.handles.disp_note)
    end
    plotArenaTraces(expmt,'handedness_Blank');
    plotArenaTraces(expmt,'handedness_Light');
end


f=figure(); 
a = expmt.Light.active;
[r,p]=corrcoef([expmt.handedness_First.mu(a)' expmt.handedness_Second.mu(a)'],'rows','pairwise');
sh=scatter(expmt.handedness_First.mu(a),expmt.handedness_Second.mu(a),...
    'MarkerEdgeColor',[0 0 0],'MarkerFaceColor',[0.5 0.5 0.5]);
sh.Parent.XLim = [-1 1];
sh.Parent.YLim = [-1 1];
xlabel('stimulus first half \mu');
ylabel('stimulus second half \mu');
dim = [.65 .78 .1 .1];
str = ['r = ' num2str(round(r(2,1)*100)/100) ', p = ' num2str(round(p(2,1)*10000)/10000)...
    ' (n=' num2str(sum(a)) ')'];
annotation('textbox',dim,'String',str,'FitBoxToText','on');
title('slow phototaxis - handedness');

fname = [expmt.meta.path.fig expmt.meta.date '_handedness'];
if ~isempty(expmt.meta.path.fig) && options.save
    hgsave(f,fname);
    close(f);
end
%}

%% Generate plots

if isfield(options,'plot') && options.plot
    if isfield(options,'handles')
        gui_notify('generating plots',options.handles.disp_note)
    end
    plotArenaTraces(expmt);
end

clearvars -except expmt options

%% Clean up files and wrap up analysis

autoFinishAnalysis(expmt,options);



function [occ,tOcc,tInc,tDiv,include] = parseBlocks(idx,include,in_light,t)

    % extract block
    include = include(idx{:}(1):idx{:}(2));
    t = t(idx{:}(1):idx{:}(2));
    in_light = in_light(idx{:}(1):idx{:}(2));

    % When one half of the arena is lit
    tmp_t = t(include);                         % ifi for included frames
    tOcc = sum(t(in_light & include))./3600;    % time in the light
    tInc = sum(tmp_t)./3600;                    % time of included frames
    tDiv = (sum(t) - tInc)./3600 ;              % time spent on the divider
    occ = tOcc/tInc;                            % fraction of included time spent in light
    

