function expmt = scoreGraviChoice(expmt,trackProps)

%% find horizontal trajectories perpendicular to the wall
dThresh = 0.15 .* mean(expmt.ROI.bounds(:,3:4),2);
centered = trackProps.r < repmat(dThresh',length(trackProps.r),1);
horizontal = sin(abs(trackProps.direction)) < 0.3;
moving = trackProps.speed > 0.6;
approaches = centered & horizontal & moving;
approaches = [zeros(1,size(approaches,2));diff(approaches)];

% identify the start of each approach
% if approach starts are too close together, keep the earliest one
[fr,id] = find(approaches==1);
appr_idx = cell(expmt.nTracks,1);
for i = 1:length(appr_idx)
    appr_idx(i) = {fr(id==i)};
    if ~isempty(appr_idx{i})
        interval = [100;diff(appr_idx{i})];
        appr_idx(i) = {appr_idx{i}(interval>40)};
    end
end


% find frames where flies were close to the wall
dThresh = 0.8 .* mean(expmt.ROI.bounds(:,3:4),2)/2;
perimeter = trackProps.r > repmat(dThresh',length(trackProps.r),1);
perimeter = [zeros(1,size(perimeter,2));diff(perimeter)];
[fr,id] = find(perimeter==1);
retr_idx = cell(expmt.nTracks,1);
for i = 1:length(retr_idx)
    retr_idx(i) = {fr(id==i)};
    if ~isempty(retr_idx{i})
        interval = [100;diff(retr_idx{i})];
        retr_idx(i) = {retr_idx{i}(interval>40)};
    end
end

% tag nearest wall approach as end of wall approach
% find the smallest positive difference between retr_idx and appr_idx
contactIdx = cell(size(appr_idx));
for i=1:length(appr_idx)
    
    tmp_idx = zeros(size(appr_idx{i}));
    for j=1:length(appr_idx{i})
        if ~isempty(appr_idx{i})
            tmpdiff = retr_idx{i} - appr_idx{i}(j);
            if any(tmpdiff>0)
                tmp_idx(j) = retr_idx{i}(find(tmpdiff>0,1));
            end
        end
    end
    
    if any(~isnan(tmp_idx))
        uIdx = unique(tmp_idx);                     % unique contact indices
        dupIdx = uIdx(histc(tmp_idx,uIdx)>1);       % indices appearing more than once
        cndIdx = ismember(tmp_idx,dupIdx);         % candidate indices to be replaced
        dupIdx = num2cell(dupIdx);                  

        % find highest index for each unique value
        lastIdx = cellfun(@(x) find(tmp_idx==x,1,'last'),dupIdx);   
        cndIdx(lastIdx) = false;
        appr_idx{i}(cndIdx) = [];
        tmp_idx(cndIdx) = [];
        tmp_idx = tmp_idx+15;
        tmp_idx(tmp_idx>length(trackProps.direction))=length(trackProps.direction);
        contactIdx(i) = {tmp_idx};

    end
    
    tmp_apr = appr_idx{i};
    tmp_apr(tmp_apr > max(tmp_idx))=[];
    appr_idx(i) = {tmp_apr};
    
end

dTheta = [zeros(1,size(trackProps.direction,2));diff(trackProps.direction)];
dTheta(~moving) = 0;
dTheta(dTheta>3/2*pi) = dTheta(dTheta>3/2*pi) - 2*pi;
dTheta(dTheta<-3/2*pi) = dTheta(dTheta<-3/2*pi) + 2*pi;

gIndex = cell(expmt.nTracks,1);
for i = 1:length(appr_idx)
    if ~isempty(appr_idx{i})
        tmp_ang=NaN(size(appr_idx{i}));
        for j=1:length(appr_idx{i})
            tmp_ang(j) = nansum(dTheta(appr_idx{i}(j):contactIdx{i}(j),i))>0;
        end
    gIndex(i) = {tmp_ang};
    end
end

expmt.Gravitaxis.nApproach = cellfun(@length,gIndex);
expmt.Gravitaxis.prob = cellfun(@nanmean,gIndex);
expmt.Gravitaxis.dir = gIndex;

