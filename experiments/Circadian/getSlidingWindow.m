function varargout = getSlidingWindow(expmt,f,win_sz,stp_sz,sampling_rate,varargin)

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
h = waitbar(0,['iteration 0 out of ' num2str(expmt.meta.num_traces)]);
h.Name = ['Sliding ' f ' window'];

% calculate frame_rate
fr = nanmedian(expmt.data.time.raw);
win_sz = round(win_sz/fr*60);
stp_sz = round(stp_sz/1/fr*60);
s = round(sampling_rate/1/fr*60);


first_idx = round(length(expmt.(f).raw)/win_sz)+1;
r = floor(win_sz/2);
win_idx = r+1:stp_sz:length(expmt.(f).raw)-r;
idx = repmat(win_idx',1,floor(win_sz/s)+1);
idx = idx + repmat(-r:s:r,size(idx,1),1);


% perform the operation
win_dat = NaN(size(idx,1),expmt.meta.num_traces);
for i = 1:expmt.meta.num_traces
    
    if ishghandle(h)
        waitbar(i/expmt.meta.num_traces,h,['iteration '...
            num2str(i) ' out of ' num2str(expmt.meta.num_traces)]);
    end
    
    dat = autoSlice(expmt,f,i);
    dat = num2cell(reshape(dat(idx(:)),size(idx)),2);
    win_dat(:,i) = cellfun(fh,dat);
    clear dat
    
end

if ishghandle(h)
    close(h);
end

% assign outputs
for i = 1:nargout
    switch i
        case 1, varargout(i) = {win_dat};
        case 2, varargout(i) = {win_idx};
        case 3, varargout(i) = {r};
    end
end




function out = slide_win(dat,fh)

    out = feval(fh,dat);







