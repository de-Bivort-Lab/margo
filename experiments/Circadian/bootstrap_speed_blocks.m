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
nf = expmt.nTracks;
active = expmt.Speed.avg>expmt.Speed.thresh;
speed = expmt.Speed.map.Data.raw(active,:);
blocks = blocks(active);
nBouts = cell2mat(cellfun(@size,blocks,'UniformOutput',false));
nBouts = nBouts(:,1);
blocks(nBouts==0) = [];
nBouts(nBouts==0)=[];

% get bout lengths
bout_length = cellfun(@(x) diff(x,[],2)+1,blocks,'UniformOutput',false);

avg = nanmean(cat(1,bout_length{:}));       % mean bout length
target = expmt.nFrames*nf;                  % target frame num
draw_sz = round(target/avg);

bs_speeds = NaN(nReps,nf);

% create waitbar object
h = waitbar(0,['iteration 0 out of ' num2str(nReps)]);
h.Name = 'Bootstrap resampling speed data';

%%
disp(['resampling data with ' num2str(nReps) ' replicates'])
disp('may a take a while with if number of replications is > 1000')
for j = 1:nReps
    
    % draw IDs
    ids = randi([1 numel(blocks)],draw_sz,1);
    bouts = ceil(rand(size(ids)).*nBouts(ids));
    frame_num = sum(arrayfun(@(x,y) bout_length{x}(y),ids, bouts));
    
    % get linear indices 
    while frame_num < target
        
        d = target-frame_num;
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
    tmp_speed = single(NaN(frame_num,1));
    ct=0;
    for i=1:length(ids)
        k1=blocks{ids(i)}(bouts(i),1);
        k2=blocks{ids(i)}(bouts(i),2);
        tmp_speed(ct+1:ct+bout_length{ids(i)}(bouts(i)))=speed(ids(i),k1:k2);
        ct=ct+bout_length{ids(i)}(bouts(i));
    end
    
    tmp_speed(target+1:end)=[];
    tmp_speed = reshape(tmp_speed,target/nf,nf);
    bs_speeds(j,:) = nanmean(tmp_speed);
    
    if ishghandle(h)
        waitbar(j/nReps,h,['iteration ' num2str(j) ' out of ' num2str(nReps)]);
    end

    clearvars ids bouts tmp_speed lin_ind
    
end

if ishghandle(h)
    close(h);
end
    

%%

dim = find(size(expmt.Speed.map.Data.raw) == expmt.nFrames);
bs.obs = log(nanmean(expmt.Speed.map.Data.raw,dim));
bs.include = active;
bs.sim = log(bs_speeds);


%% generate plots

f=figure();
hold on

% get range for density estimation
range = [min([bs.sim(~isinf(bs.sim));bs.obs(~isinf(bs.obs))]) ...
        max([bs.sim(~isinf(bs.sim));bs.obs(~isinf(bs.obs))])];
range(1) = floor(range(1));
range(2) = ceil(range(2));


[bs_kde,x1] = ksdensity(bs.sim(:),linspace(range(1),range(2),1000));
bs_kde = bs_kde./sum(bs_kde);

% plot bootstrapped trace
plot(x1,bs_kde,'Color',[0 .45 .55],'LineWidth',2);

% plot observed trace
[obs_kde,x2] = ksdensity(bs.obs(:),linspace(range(1),range(2),1000));
obs_kde = obs_kde./sum(obs_kde);
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

for i=1:nargout
    switch i
        case 1, varargout{i} = bs;
        case 2, varargout{i} = f;
    end
end







