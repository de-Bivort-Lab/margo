function varargout = getSlidingWindow(expmt,f,win_sz,stp_sz,sampling_rate,varargin)

% extracts time averaged trace of expmt field (f) by sliding a window of length
% win_sz over the data at intervals of stp_sz from the data

%% parse inputs

fh = str2func('nanFilteredMean');
frame_range = [1 expmt.meta.num_frames];
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
            case 'FrameRange'
                i=i+1;
                frame_range = varargin{i};
        end
    end
end


%%

% create waitbar object
h = waitbar(0,['iteration 0 out of ' num2str(expmt.meta.num_traces)]);
h.Name = ['Sliding ' f ' window'];

% calculate frame_rate
fr = nanFilteredMedian(expmt.data.time.raw(1:1000));
win_sz = round(win_sz/fr*60);
stp_sz = round(stp_sz/fr*60);
s = round(sampling_rate/fr*60);

nframes = diff(frame_range)+1;
first_idx = round(nframes/win_sz)+frame_range(1);
r = floor(win_sz/2);
win_idx = r+first_idx:stp_sz:frame_range(2)-r;
idx = repmat(win_idx',1,floor(win_sz/s)+1);
idx = idx + repmat(-r:s:r,size(idx,1),1);

% clear open data maps
detach(expmt);


% perform the operation
win_dat = NaN(size(idx,1),expmt.meta.num_traces);
for i = 1:size(idx,1)
    
    if ishghandle(h)
        waitbar(i/size(idx,1),h,...
            sprintf('iteration %i of %i',i,size(idx,1)));
    end
    
    %dat = autoSlice(expmt,f,i);
    dat = expmt.data.(f).raw(idx(i,:),:);
    dat = num2cell(dat,1);
    win_dat(i,:) = cellfun(fh,dat);
    
    if mod(i,10)==0
        reset(expmt.data.(f));
    end
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







