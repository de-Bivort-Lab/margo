function [varargout]=bootstrap_speed(expmt,trackProps,nReps)

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

nf = expmt.nTracks;
active = nanmean(trackProps.speed)>0.01;
trackProps.speed = trackProps.speed(:,active);
batch_sz = 5000;
max_idx = numel(trackProps.speed);


bs_speeds = NaN(nReps,nf);

disp(['resampling data with ' num2str(nReps) ' replicates'])
disp('may a take a while with if number of replications is > 1000')
tic
for j = 1:nReps
    
    rand_frames = uint32(randi([1 max_idx],batch_sz*nf,1));
    rand_speeds = reshape(trackProps.speed(rand_frames),batch_sz,nf);
    bs_speeds(j,:) = nanmean(rand_speeds);

    clearvars rand_frames rand_speeds
    
end
toc
    

%%

data = log(nanmean(trackProps.speed));

lg_speeds = log(bs_speeds);

% create histogram of occupancy scores
binmin=min(lg_speeds(:));
binmax=max(lg_speeds(:));
w = binmax - binmin;
plt_res = w/(10^floor(log10(nf)));
bins = binmin:plt_res:binmax;
c = histc(lg_speeds,bins) ./ repmat(sum(histc(lg_speeds,bins)),numel(bins),1);
[mu,~,ci95,~] = normfit(c');

%% generate plots

f=figure();
hold on

range = [min([lg_speeds(:);data(:)]) max([lg_speeds(:);data(:)])];
range(1) = floor(range(1));
range(2) = ceil(range(2));

% plot bootstrapped trace
plot(bins,mu,'b','LineWidth',2);

datbins = linspace(min(data(:)),max(data(:)),length(bins));
% plot observed data
c = histc(data,datbins) ./ sum(sum(histc(data,datbins)));
c = [0 c 0];
datbins = [range(1) datbins range(2)];
plot(datbins,c,'r','LineWidth',2);
set(gca,'XLim',range,'YLim',[0 max(mu)]);
legend({['bootstrapped (nReps = ' num2str(nReps) ')'];'observed'});
title(['speed histogram (obs v. bootstrapped)']);

% add confidence interval patch
vx = [bins fliplr(bins)];
vy = [ci95(1,:) fliplr(ci95(2,:))];
ph = patch(vx,vy,[0 0.9 0.9],'FaceAlpha',0.3);
uistack(ph,'bottom');

for i=1:nargout
    switch i
        case 1, varargout{i} = mu;
        case 2, varargout{i} = data;
        case 3, varargout{i} = f;
    end
end







