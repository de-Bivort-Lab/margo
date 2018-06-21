function [varargout] = blockActivity(s_raw)

% blockActivity divides autotracker speed traces into discreet bouts
%
% input:
%   s_map           ->  memmap to raw speed data file (ie. expmt.Speed.map)
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
s = s_raw;
s = s';
[ac] = autocorr(s(:),250);
lag_thresh = find(diff(ac)>-0.01,1) + 1;

% median filter data by lag_thresh/2 to discretize bouts
if (lag_thresh>1)
    s = medfilt1(s,round(lag_thresh/2),[],1);
end

% find speed threshold cutoff from log speed
[intersect] = fitBimodalHist(log(s(:)));
speed_thresh = exp(intersect);

% find frames where transitioned from 
moving = s_raw > speed_thresh;
transitions = diff(moving,1,2);
transitions = cat(2,zeros(size(transitions,1),1,1),transitions);
transitions = num2cell(transitions,2);

% get activity bout stops and starts
stops = cellfun(@(x,y) find(x==-1), transitions,'UniformOutput',false);
starts = cellfun(@(x,y) find(x==1), transitions,'UniformOutput',false);

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
        idx = [starts{:}(long_bout)' stops{:}(long_bout)'];

        if size(idx,1)>1
            % ensure that lower index comes first
            [~,i]=min(idx,[],2);
            idx(i==2,:) = idx(i==2,[2 1]);

            % shift indices to get bouts
            idx = [idx;[idx(1:length(idx)-1,2) idx(2:end,1)]];

            bout_length = idx(:,2)-idx(:,1);
            idx(bout_length<duration,:)=[];
        end
    else
        idx = [];
    end
    
    
    

        
        