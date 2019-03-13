function [expmt, num_excluded, frac_total] = excludeTrialBoundaryBouts(expmt)

% get trial lower and upper boundaries
lb = expmt.meta.Light.blocks(:,1);
ub = expmt.meta.Light.blocks(:,2);
ub = ub+1;
bounds = [lb';ub'];
bounds = bounds(:);

% get movement bout start/stops
all_bouts = expmt.meta.speed.bouts.idx;
num_excluded = cell(expmt.meta.num_traces,1);
frac_total = cell(expmt.meta.num_traces,1);

% identify bouts that span stimulus transitions and exclude from data
for i=1:length(all_bouts)  
    bouts = num2cell(all_bouts{i},2);
    exclude = cellfun(@(b) any(b(1)<bounds(:) & b(2)>bounds(:)), bouts);
    exclude = cellfun(@(b) (b(1):b(2))', bouts(exclude), 'UniformOutput', false);
    exclude = cat(1, exclude{:});
    num_excluded{i} = [sum(expmt.meta.Light.include{i}) ...
                    sum(expmt.meta.Blank.include{i})];
    expmt.meta.Light.include{i}(exclude) = false;
    expmt.meta.Blank.include{i}(exclude) = false;
    n = num_excluded{i} - ...
        [sum(expmt.meta.Light.include{i}) sum(expmt.meta.Blank.include{i})];
    frac_total{i} = n ./ num_excluded{i};
    num_excluded{i} = ...
        [sum(expmt.meta.Light.include{i}) sum(expmt.meta.Blank.include{i})];

end






