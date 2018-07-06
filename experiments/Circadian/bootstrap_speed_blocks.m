function [varargout]=bootstrap_speed_blocks(expmt,blocks,nReps)

% Create bootstrapped distribution of occupancy from slow phototaxis data.
% For each bootstrap iteration:
%   1. Choose a fly at random
%   2. Then select a stimulus bout at random
%   3. Repeat the process until the sequence of bouts equals the duration
%      of the experiment.
%   4. Repeat steps 1-3 to create a bootstrapped score for each animal in
%      the experiment to create a distribution of scores to measure both 
%      mean and dispersion.
%   5. Repeat steps 1-4 nReps times to assess the likeliness of the data by
%      random chance.

%% bootstrap sample data

% restrict based on minimum activity
nf = expmt.meta.num_traces;
spd = expmt.data.speed.raw();
reset(expmt.data.speed);
active = nanmean(spd) > expmt.meta.speed.thresh;
active_ids = find(active);
blocks = blocks(active);
nBouts = cellfun(@size,blocks,'UniformOutput',false);
nBouts = cat(1,nBouts{:});
nBouts = nBouts(:,1);
blocks(nBouts==0) = [];
nBouts(nBouts==0)=[];

% get bout lengths
bout_length = cellfun(@(x) diff(x,[],2)+1,blocks,'UniformOutput',false);

avg = nanmean(cellfun(@nanmean,bout_length));       % mean bout length   
target = expmt.meta.num_frames*nf;                  % target frame num


bs_speeds = NaN(nReps,nf);

% get batch info
[bsz, nBatch] = getBatchSize(expmt, 8);
draw_sz = round(target/avg/nBatch);

% create waitbar object
h = waitbar(0,['iteration 0 out of ' num2str(nReps)]);
h.Name = 'Bootstrap resampling speed data';

%%

disp(['resampling data with ' num2str(nReps) ' replicates'])
disp('may a take a while with if number of replications is > 1000')
for i = 1:nReps
    
    batch_spd = NaN(nBatch,nf);
    for j=1:nBatch
        
        % draw IDs
        ids = randi([1 numel(blocks)],draw_sz,1);
        bouts = ceil(rand(size(ids)).*nBouts(ids));
        frame_num = sum(arrayfun(@(x,y) bout_length{x}(y),ids, bouts));

        % get linear indices 
        while frame_num < target/nBatch

            d = target/nBatch-frame_num;
            sz = ceil(d/avg*1.2);

            % draw IDs
            tmp_ids = randi([1 length(blocks)],sz,1);
            tmp_bouts = ceil(rand(size(tmp_ids)).*nBouts(tmp_ids));
            frame_num = sum(arrayfun(@(x,y) bout_length{x}(y),tmp_ids, tmp_bouts));

            ids = [ids;tmp_ids];
            bouts = [bouts;tmp_bouts];

            clearvars tmp_ids tmp_bouts
        end

        % create speed vector
        tmp_speed = arrayfun(@(id,b) ...
            spd(blocks{id}(b,1):blocks{id}(b,2), active_ids(id)),...
                ids, bouts, 'UniformOutput',false);
        tmp_speed = cat(1,tmp_speed{:});
        tmp_speed=tmp_speed(1:floor(target/nBatch/nf)*nf);
        tmp_speed = reshape(tmp_speed,numel(tmp_speed)/nf,nf);
        batch_spd(j,:) = nanmean(tmp_speed);
        clear tmp_speed
    end
    bs_speeds(i,:) = nanmean(batch_spd);
    
    if ishghandle(h)
        waitbar(i/nReps,h,['iteration ' num2str(i) ' out of ' num2str(nReps)]);
    end

    clearvars ids bouts tmp_speed lin_ind
    
end

if ishghandle(h)
    close(h);
end
    

%%

dim = find(size(expmt.data.speed.raw) == expmt.meta.num_frames);
bs.obs = log(nanmean(expmt.data.speed.raw(),dim));
bs.include = active;
bs.sim = log(bs_speeds);


%% generate plots

f=figure();
hold on

% get range for density estimation
range = [min([bs.sim(~isinf(bs.sim));bs.obs(~isinf(bs.obs))']) ...
        max([bs.sim(~isinf(bs.sim));bs.obs(~isinf(bs.obs))'])];
range(1) = floor(range(1));
range(2) = ceil(range(2));


[bs_kde,x1] = ksdensity(bs.sim(:),linspace(range(1),range(2),1000));
%bs_kde = bs_kde./sum(bs_kde);

% plot bootstrapped trace
plot(x1,bs_kde,'Color',[0 .45 .55],'LineWidth',2);

% plot observed trace
[obs_kde,x2] = ksdensity(bs.obs(:),linspace(range(1),range(2),1000));
%obs_kde = obs_kde./sum(obs_kde);
plot(x2,obs_kde,'Color',[.85 0 .75],'LineWidth',2);
set(gca,'XLim',range,'YLim',[0 max(bs_kde)*1.1]);
xlabel('log(speed)');
legend({['bootstrapped (nReps = ' num2str(nReps) ')'];'observed'},...
            'Location','NorthWest');
title('speed (obs v. bootstrapped)');

% add bs and obs patch
vx = [x1 x1(end) x1(1)];
vy = [bs_kde 0 bs_kde(1)];
ph = patch(vx,vy,[0 0.75 0.85],'FaceAlpha',0.3);
uistack(ph,'bottom');
vx = [x2 x2(end) x2(1)];
vy = [obs_kde 0 obs_kde(1)];
ph = patch(vx,vy,[.85  0 .75],'FaceAlpha',0.3);
uistack(ph,'bottom');

for k=1:nargout
    switch k
        case 1, varargout{k} = bs;
        case 2, varargout{k} = f;
    end
end







