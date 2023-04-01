function varargout = bootstrap_slowphototaxis(expmt,nReps,field)

% Create bootstrapped distribution of occupancy from slow phototaxis data.
% For each bootstrap iteration:
%   1. Choose a fly at random
%   2. Then select a stimulus bout at random
%   3. Repeat the process until the sequence of bouts equals the duration
%      of the experiment.
%   4. Repeat steps 1-3 to create a bootstrapped score for each animal in
%      the experiment to create a distribution of scores to measure both 
%      mean and dispersion.
%   5. Repeat steps 1-4 nReps time to assess the likeliness of the data by
%      random chance.

%% bootstrap sample data
nb = expmt.meta.(field).nBlocks;
fly_sub = randi([1 expmt.meta.num_traces],nb*expmt.meta.num_traces*nReps,1);
block_sub = randi([1 nb],nb*expmt.meta.num_traces*nReps,1);
obs = cat(2,expmt.meta.(field).occ{:});
obs = obs - (1-obs);
idx = sub2ind(size(obs),block_sub,fly_sub);
occ = obs(idx);
occ = reshape(occ,nb,expmt.meta.num_traces,nReps);
occ = squeeze(nanFilteredMean(occ,1));

% create histogram of occupancy scores
bins = -1:0.05:1;
%c = histc(occ,bins) ./ repmat(sum(histc(occ,bins)),numel(bins),1);

%% generate plots

f=figure();
hold on

% plot bootstrapped trace
[bs_kde, x1] = ksdensity(occ(:));
plot(x1, bs_kde,'b','LineWidth',2);
set(gca,'Xtick',-1:0.5:1,'XLim',[-1 1],'YLim',[0 max(bs_kde(:))]);

% plot observed data
obs = nanFilteredMean(obs);
[obs_kde, x2] = ksdensity(obs(:));
plot(x2, obs_kde,'r','LineWidth',2);
legend({['bootstrapped (nReps = ' num2str(nReps) ')'];'observed'});
title([field ' occupancy histogram']);

% add bs and obs patch
vx = [x1 x1(end) x1(1)];
vy = [bs_kde 0 bs_kde(1)];
ph = patch(vx,vy,[0 0.75 0.85],'FaceAlpha',0.3);
uistack(ph,'bottom');
vx = [x2 x2(end) x2(1)];
vy = [obs_kde 0 obs_kde(1)];
ph = patch(vx,vy,[.85  0 .75],'FaceAlpha',0.3);
uistack(ph,'bottom');

% save output variablie
bs.obs_data = obs;
bs.bs_data = occ;
bs.nReps = nReps;
bs.bins = bins;

% parse outputs
for i = 1:nargout
    switch i
        case 1, varargout(i) = {bs};
        case 2, varargout(i) = {f};
    end
end




