function [fh1, fh2, expmt] = stimBoutDistibutions(expmt)

expmt.meta.Light.bouts = cell(expmt.meta.num_traces,1);
expmt.meta.Blank.bouts = cell(expmt.meta.num_traces,1);

% split bouts by stimulus identity
for i=1:expmt.meta.num_traces
    
    bouts = expmt.meta.speed.bouts.idx{i};
    inc = expmt.meta.Light.include{i};
    expmt.meta.Light.bouts{i} = bouts(inc(bouts(:,1)),:);
    inc = expmt.meta.Blank.include{i};
    expmt.meta.Blank.bouts{i} = bouts(inc(bouts(:,1)),:);
    
end

expmt.meta.Light.bout_lengths = cellfun(@(lb) diff(lb,1,2), ...
    expmt.meta.Light.bouts, 'UniformOutput', false);
expmt.meta.Blank.bout_lengths = cellfun(@(bb) diff(bb,1,2), ...
    expmt.meta.Blank.bouts, 'UniformOutput', false);

all_light = cat(1,expmt.meta.Light.bout_lengths{:});
all_blank = cat(1,expmt.meta.Blank.bout_lengths{:});

fh1 = autoPlotDist(all_light, true(size(all_light)));
autoPlotDist(all_blank, true(size(all_blank)),fh1.Children);
xlabel('bout length');
legend({'full light';'light/dark'});

expmt.meta.Light.bout_num = cellfun(@(lb) size(lb,1), ...
    expmt.meta.Light.bouts);
expmt.meta.Blank.bout_num = cellfun(@(bb) size(bb,1), ...
    expmt.meta.Blank.bouts);

fh2 = autoPlotDist(expmt.meta.Light.bout_num, true(size(expmt.meta.Light.bout_num)));
autoPlotDist(expmt.meta.Blank.bout_num, true(size(expmt.meta.Blank.bout_num)),fh2.Children);
xlabel('bout number');
legend({'full light';'light/dark'});