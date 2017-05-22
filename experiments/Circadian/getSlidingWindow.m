function varargout = getSlidingWindow(expmt,f,win_sz,stp_sz,varargin)

% extracts time averaged trace of expmt field (f) by sliding a window of length
% win_sz over the data at intervals of stp_sz from the data

%% parse inputs

fh = str2func('nanmean');

for i = 1:length(varargin)
    
    arg = varargin{i};
    
    if ischar(arg)
    	switch arg
            case 'Decimate'
                i=i+1;
                dec_fac = varargin{i};
            case 'Func'
                i=i+1;
                fh = str2func(varargin{i});
        end
    end
end


%%

% create waitbar object
h = waitbar(0,['iteration 0 out of ' num2str(expmt.nTracks)]);
h.Name = ['Sliding ' f ' window'];

first_idx = round(length(expmt.(f).data)/win_sz)+1;
r = floor(win_sz/2);
idx = r+1:stp_sz:length(expmt.(f).data);


% perform the operation
win_dat = NaN(length(idx),expmt.nTracks);
for i = 1:expmt.nTracks
    
    if ishghandle(h);
        waitbar(i/expmt.nTracks,h,['iteration ' num2str(i) ' out of ' num2str(expmt.nTracks)]);
    end
    
    win_dat(:,i) = arrayfun(@(k) slide_win(expmt.(f).data(:,i),k,r,fh), idx);
end

if ishghandle(h)
    close(h);
end

% assign outputs
for i = 1:nargout
    switch i
        case 1, varargout(i) = {win_dat};
        case 2, varargout(i) = {idx};
        case 3, varargout(i) = {r};
    end
end




function out = slide_win(dat,idx,r,fh)

    out = feval(fh,dat(idx-r:idx+1,:));







