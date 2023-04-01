function bs = bootstrap_bout_length(bout_length, nReps, ifi)

avg_bout = cellfun(@nanFilteredMean,bout_length);
nBouts = cellfun(@numel,bout_length,'UniformOutput',false);
nBouts = cat(1,nBouts{:});
nf = numel(nBouts);
bout_length(nBouts<2)=[];
bs.include = nBouts<2;
nBouts(nBouts<2)=[];
na = numel(nBouts);

bs.sim = NaN(nReps,nf);

% create waitbar object
h = waitbar(0,['iteration 0 out of ' num2str(nReps)]);
h.Name = 'Bootstrap resampling speed data';

for i=1:nReps
    
    if ishghandle(h)
        waitbar(i/nReps,h,['iteration ' num2str(i) ' out of ' num2str(nReps)]);
    end
    
    bs_n = nBouts(randi(na,[nf, 1]));
    bs_ids = arrayfun(@(x) randi(na,[x, 1]), bs_n, 'UniformOutput',false);
    bs_idx = cell(nf,1);
    for j=1:nf
        bs_idx{j} = arrayfun(@(x) randi(nBouts(x),[1, 1]), bs_ids{j}, 'UniformOutput',false);
    end
    bs_len = cellfun(@(x,y) arrayfun(@(a,b) ...
        bout_length{a}(b),x,cat(1,y{:})), ...
        bs_ids, bs_idx, 'UniformOutput',false);
    bs.sim(i,:) = cellfun(@nanFilteredMean,bs_len)';
    
end

if ishghandle(h)
    close(h);
end

%% convert bout length (frames) to bout length (sec)

bs.obs = log(avg_bout .* ifi);
bs.sim = log(bs.sim .* ifi);


%% generate plots

f=figure();
hold on

range = [min([bs.sim(:);bs.obs(:)]) max([bs.sim(:);bs.obs(:)])];
range(1) = floor(range(1));
range(2) = ceil(range(2));
[bs_kde,x1] = ksdensity(bs.sim(:),linspace(range(1),range(2),1000));
bs_kde = bs_kde./sum(bs_kde);

% plot bootstrapped trace
plot(x1,bs_kde,'Color',[0 0 .85],'LineWidth',2);

% plot observed trace
[obs_kde,x2] = ksdensity(bs.obs(:),linspace(range(1),range(2),1000));
obs_kde = obs_kde./sum(obs_kde);
plot(x2,obs_kde,'Color',[.85 0 0],'LineWidth',2);
set(gca,'XLim',range,'YLim',[0 max(bs_kde)*1.1]);
xlabel('log(bout length)');
legend({['bootstrapped (nReps = ' num2str(nReps) ')'];'observed'},...
            'Location','NorthWest');
title(['bout lengths (obs v. bootstrapped)']);

% add bs and obs patch
vx = [x1 x1(end) 0 x1(1)];
vy = [bs_kde 0  0 bs_kde(1)];
ph = patch(vx,vy,[0 0 0.85],'FaceAlpha',0.3);
uistack(ph,'bottom');
vx = [x2 x2(end) 0 x2(1)];
vy = [obs_kde 0 0 obs_kde(1)];
ph = patch(vx,vy,[.85  0 0],'FaceAlpha',0.3);
uistack(ph,'bottom');
    
