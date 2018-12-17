function psychometrics = ledymaze_psychometrics(pwm,light_choice)
% Compute individual and population psychometric curves for phototactic choice 
% as a function of LED intensity.
%
% Inputs
%   pwm             (nframes x ntraces) intensity for the current frame and trace
%   light_choice    (nframes x ntraces) phototaxis choice for current frame and
%                   trace (1 = positive, -1 = negative, 0 = none)

% get pwm values tested
pwm_vals = unique(pwm(:));

% get frames where turns occured
is_turn = light_choice ~= 0;

% filter data for inactivity
ntrials = sum(is_turn);

% shift indices up by one
pwm = [zeros(1,size(pwm,2)); pwm];
pwm(end,:) = [];
choice_cell = num2cell(light_choice,1);

% initialize placeholder for psychmetric curves
psy_curv = NaN(numel(pwm_vals),size(pwm,2));
all_trials = cell(numel(pwm_vals),1);

% iterate over values
for i=1:numel(pwm_vals)
    
    % get mask for turn at current pwm
    mask = is_turn & (pwm==pwm_vals(i));
    
    % calculate individual means
    psy_curv(i,:) = cellfun(@(lc,m) nanmean(lc(m)), choice_cell, num2cell(mask,1));
    
    % filter out low sampling
    psy_curve(i,sum(mask)<10) = NaN;
    
    % get all trials at current pwm
    all_trials{i} = light_choice(mask);
end

%% plot results

% get averages and 95 % confidence intervals
[mu,~,ci95,~] = cellfun(@(psy) normfit(psy(~isnan(psy))), ...
    num2cell(psy_curv,2), 'UniformOutput', false);
mu = cat(1,mu{:});
ci95 = cat(2,ci95{:});

% create average of individuals plot
pwm_vals = log2(double(pwm_vals))';

% plot
figure; hold on;
plot(pwm_vals(2:end),mu(2:end),'k','LineWidth',1.5);
vx = [pwm_vals(2:end) fliplr(pwm_vals(2:end)) pwm_vals(2)];
vy = [ci95(1,2:end) fliplr(ci95(2,2:end)) ci95(1,2)];
ph = patch(vx,vy,[.85 .85 .85],'EdgeColor','none');
set(gca(),'YLim',[-1 1]);
title('LED Y-maze psychometric curves');
xlabel('log(LED intensity)');
ylabel('phototactic index');
plot([0 12],[0 0],'k--', 'LineWidth', 0.25);
legend({'mean';'95% CI';'no preference'},'Location','Northwest');
uistack(ph,'down');

% plot individual traces
figure;
nrows = ceil(sqrt(size(pwm,2)));
ncols = ceil(size(pwm,2)/nrows);
for i=1:nrows*ncols

    subplot(nrows,ncols,i); hold on;
    if i<= size(pwm,2)
        plot(pwm_vals(2:end),psy_curv(2:end,i),'k','LineWidth',1);
    end
    plot([0 12],[0 0],'k--', 'LineWidth', 0.25);
    set(gca,'XLim',[0 12],'YLim',[-1 1],'XTick',[],'YTick',[]);
    if mod(i,ncols)==1
        set(gca,'YTick',[-1 0 1]);
        ylabel('index');
    end
    if ceil(i/ncols) == nrows
        set(gca,'XTick',[0 6 12]);
        xlabel('log2(PWM)');
    end
end

% assign output data
psychometrics.curves = psy_curv;
psychometrics.mean = mu;
psychometrics.CI95 = ci95;
psychometrics.log2_pwm = pwm_vals;



