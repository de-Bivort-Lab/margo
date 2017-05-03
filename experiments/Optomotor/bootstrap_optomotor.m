function bootstrap_optomotor(expmt,nReps,field)

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

for k = 1:nReps
    
    n = expmt.(field).n(randi([1 nf],nf,1));
    ids = arrayfun(@(k) drawIDs(k,nf), n, 'UniformOutput',false);
     
end
    
fly_sub = randi([1 expmt.nTracks],nb*expmt.nTracks*nReps,1);
block_sub = randi([1 nb],nb*expmt.nTracks*nReps,1);
data = cell2mat(expmt.(field).occ);
idx = sub2ind(size(data),block_sub,fly_sub);
occ = data(idx);
occ = reshape(occ,nb,expmt.nTracks,nReps);
occ = squeeze(nanmean(occ,1));

% create histogram of occupancy scores
bins = 0:0.05:1;
c = histc(occ,bins) ./ repmat(sum(histc(occ,bins)),numel(bins),1);
[mu,~,ci95,~] = normfit(c');

%% generate plots

figure();
hold on

% plot bootstrapped trace
plot(mu,'b','LineWidth',2);
set(gca,'Xtick',1:2:length(mu),'XtickLabel',bins(mod(1:length(bins),2)==1),...
    'XLim',[1 length(mu)],'YLim',[0 ceil(max(ci95(:))*100)/100]);

% plot observed data
c = histc(mean(data),bins) ./ sum(sum(histc(mean(data),bins)));
plot(c,'r','LineWidth',2);
legend({['bootstrapped (nReps = ' num2str(nReps) ')'];'observed'});
title([field ' occupancy histogram']);

% add confidence interval patch
vx = [1:length(bins) fliplr(1:length(bins))];
vy = [ci95(1,:) fliplr(ci95(2,:))];
ph = patch(vx,vy,[0 0.9 0.9],'FaceAlpha',0.3);
uistack(ph,'bottom');




function ids = drawIDs(n,nf)
    
    ids = randi([1 nf],n,1);





function drawTrials(id)








