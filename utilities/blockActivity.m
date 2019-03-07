function [varargout] = blockActivity(expmt)

% blockActivity divides margo speed traces into discreet bouts
%
% input:
%   s_map           ->  memmap to raw speed data file (ie. expmt.data.speed.map)
%
% outputs:
%
%   block_indices   ->  nBouts x 2 cell array of frame indices where bout
%                       transitions occurred
%   lag_thresh      ->  autocorrelation lag threshold value in number of
%                       frames for defining duration of movement bouts
%   speed_thresh    ->  threshold value acquired by fitting two-component 
%                       gmm to log(speed) and computing intersection
%
% compute autocorrelation and find conservative 
% cutoff for bout discretization
% 

spd = expmt.data.speed;
reset(spd);

if spd.dim(1) < 50000
    smpl = 1:spd.dim(1);
else
    smpl = 1:50000;
end

% compute autocorrelation
s = spd.raw(smpl,:);
ac = acf(s(~isnan(s)),250);
lag_thresh = find(meanFilter(diff(ac),20)>-0.01,1)*1.8 + 1;


% median filter data by lag_thresh/2 to discretize bouts
if (lag_thresh>1)
    s = medfilt1(s,round(lag_thresh/2),[],1);
end

% free memory from the memory map
reset(spd);

% find speed threshold cutoff from log speed
[intersect,~] = kthresh_distribution(log(s(:)));
speed_thresh = exp(intersect);

% find frames where transitioned from 
[bsz, nBatch] = getBatchSize(expmt, 2);
moving = false(spd.dim);
for j=1:nBatch
    if j==nBatch
        idx = (j-1)*bsz+1:expmt.meta.num_frames;
    else
        idx = (j-1)*bsz+1:j*bsz;
    end
    s = spd.raw(idx,:);
    moving(idx,:) = s > speed_thresh;
    reset(spd);
    clear s idx
end

moving = int8(moving);
shift_mov = [moving(2:size(moving,1),:); int8(zeros(1,size(moving,2)))];
transitions = shift_mov - moving;
clear moving shift_mov
transitions = cat(1,zeros(1,size(transitions,2)),transitions);
transitions = num2cell(transitions,1);

% get activity bout stops and starts
stops = cellfun(@(x,y) find(x==-1), transitions,'UniformOutput',false);
starts = cellfun(@(x,y) find(x==1), transitions,'UniformOutput',false);

% free speed map
clear s moving transitions

% filter by bout lengths
block_indices = arrayfun(@(x,y) ...
                filterShortBouts(x,y,lag_thresh),...
                starts,stops,'UniformOutput',false);
            
            
for i=1:nargout
    switch i
        case 1, varargout{i} = block_indices;
        case 2, varargout{i} = lag_thresh;
        case 3, varargout{i} = speed_thresh;
    end
end



    
function idx = filterShortBouts(starts,stops,duration)

    % discard last bout if it starts but doesn't end
    if any(size(starts{:}) ~= size(stops{:}))

        start_end = length(starts{:}) > length(stops{:});
       
        if start_end
            starts{:}(end) = [];
        else
            stops{:}(end) = [];
        end
    end
    

    if ~isempty(starts) && ~isempty(stops)
        bout_length = abs(starts{:}-stops{:});
        long_bout = bout_length > duration;
        idx = [starts{:}(long_bout) stops{:}(long_bout)];

        if size(idx,1)>1
            % ensure that lower index comes first
            [~,i]=min(idx,[],2);
            idx(i==2,:)=[];
        end
    else
        idx = [];
    end
    
    idx = uint32(idx);
    
    
    

        
        