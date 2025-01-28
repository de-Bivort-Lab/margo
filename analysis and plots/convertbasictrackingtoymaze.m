function expmt=convertbasictrackingtoymaze(varargin)
%% function exmpt=convertbasictrackingtoymaze(expmt) is a function to reanalyze y-maze data that was tracked with basic tracking.
numArgs = length(varargin);

if numArgs == 1
%the number of arguments is the number of items put within the () of the
%function that you wrote in your command window
    if isa(varargin{1}, 'ExperimentData')
        expmt = varargin{1};
     % this command allows the expmt file to be manually loaded into the
     % fuction
    elseif isa(varargin{1}, 'char') | isa(varargin{1}, 'string')
        filepath=varargin{1};
        loadedfiles=load(filepath, 'expmt');
        expmt=loadedfiles.expmt;
        %this command allows files that are not expmt to be added to the
        %path so they can be inputed into the fuction
    else
        error("Expected either an ExperimentData file or path to MARGO .mat file.")
    end
else
    error("Expected either an ExperimentData file or path to MARGO .mat file.")
end


%% Experimental Setup
%this is duplicated from run_ymaze.m

% properties of the tracked objects to be recorded
% trackDat.fields={'centroid';'dropped_frames';'time';'Turns';};

% initialize labels, files, and cam/video
% [trackDat,expmt] = autoInitialize(trackDat,expmt,gui_handles);
trackDat = initializeTrackDat(expmt);
% trackDat.fields={'centroid';'time';'dropped_frames'}; %removing area
% lastFrame = false until last frame of the last video file is reached
trackDat.lastFrame = false;
trackDat.fields={'centroid';'dropped_frames';'time';'Turns';};

%% Y-maze specific parameters


% Calculate coordinates of end of each maze arm
trackDat.arm = zeros(expmt.meta.roi.n,2,6);                              % Placeholder
w = expmt.meta.roi.bounds(:,3);                                  % width of each ROI
h = expmt.meta.roi.bounds(:,4);                                  % height of each ROI

% Offsets to shift arm coords in from edge of ROI bounding box
xShift = w.*0.15;
yShift = h.*0.15;

% Coords 1-3 are for upside-down Ys
trackDat.arm(:,:,1) = ...
    [expmt.meta.roi.corners(:,1)+xShift expmt.meta.roi.corners(:,4)-yShift];
trackDat.arm(:,:,2) = ...
    [expmt.meta.roi.centers(:,1) expmt.meta.roi.corners(:,2)+yShift];
trackDat.arm(:,:,3) = ...
    [expmt.meta.roi.corners(:,3)-xShift expmt.meta.roi.corners(:,4)-yShift];

% Coords 4-6 are for right-side up Ys
trackDat.arm(:,:,4) = ...
    [expmt.meta.roi.corners(:,1)+xShift expmt.meta.roi.corners(:,2)+yShift];
trackDat.arm(:,:,5) = ...
    [expmt.meta.roi.centers(:,1) expmt.meta.roi.corners(:,4)-yShift];
trackDat.arm(:,:,6) = ...
    [expmt.meta.roi.corners(:,3)-xShift expmt.meta.roi.corners(:,2)+yShift];

% time stamp of last scored turn for each object
trackDat.turntStamp = zeros(expmt.meta.roi.n,1);
trackDat.prev_arm = zeros(expmt.meta.roi.n,1);

% calculate arm threshold as fraction of width and height
expmt.parameters.arm_thresh = mean([w h],2) .* 0.2;
nTurns = zeros(size(expmt.meta.roi.centers,1),1);

%% Run through each data point.
experiment_len=expmt.data.time.dim(1); %numtime stamps;
% experiment_len=1000;
expmt.data.Turns = RawDataField('Parent',expmt);
turn_path=char(strcat(expmt.meta.path.dir, "raw_data",filesep,expmt.meta.date, "_Turns.bin"));
expmt.data.Turns.path=turn_path;
expmt.data.Turns.fID=fopen(turn_path,'W');

tic
% figure(1)
% clf


tlendiagnostic=zeros(4,1);

% Seeing if it helps to put the centroid data in memory
allcentroid=expmt.data.centroid.raw(:,:,:);
alltime=cumsum(expmt.data.time.raw(:));
for i=1:experiment_len

    t=toc;
    
    % disp(toc-t)
    if 0==mod(i,ceil(experiment_len/20)) %Progress bar (can take some amount of time)
        pd=i/ceil(experiment_len/20);
        fprintf("%d%% done. \n",pd*5)
        toc
        fprintf("Estimated done in %f seconds \n", (toc/pd)*(20-pd))
        % disp(diff(tlendiagnostic))
    end
    % update the Trackdat based on the experiment.
    trackDat.centroid=squeeze(allcentroid(i, :,:))';
    tlendiagnostic(1)=tlendiagnostic(1)+toc-t;

    trackDat.t=alltime(i);
    % Determine if fly has changed to a new arm
    trackDat = detectArmChange(trackDat,expmt);
    tlendiagnostic(2)=tlendiagnostic(2)+toc-t;
    % if sum(trackDat.changed_arm)>0
    %     disp("changed arm")
    % end
    % Create placeholder for arm change vector to write to file
    trackDat.Turns=int8(zeros(expmt.meta.roi.n,1));
    trackDat.Turns(trackDat.changed_arm) = ...
        trackDat.prev_arm(trackDat.changed_arm);
    nTurns(trackDat.changed_arm) = nTurns(trackDat.changed_arm)+1;

    %% From autowritedata to make binary data
    tlendiagnostic(3)=tlendiagnostic(3)+toc-t;
    if i== 1

        % record the dimensions of data in each recorded field
        expmt.data.Turns.dim = ...
            size(trackDat.Turns);
        expmt.data.Turns.precision = ...
            class(trackDat.Turns);

        expmt.meta.fields = trackDat.fields;
        save([expmt.meta.path.dir expmt.meta.path.name '.mat'],'expmt','-v7.3');
        precision = class(trackDat.Turns);
        if islogical(precision)
        % if strcmpi(precision,'logical')
            precision = 'ubit1';
        end
    end
    % disp(toc-t)
    % t=toc;
    % write raw data to binary files
    % for i = 1:length(trackDat.fields)

    fwrite(expmt.data.Turns.fID,...
        trackDat.Turns,precision);
    % end
    % disp(toc-t)
    % t=toc;
    % return
    turns(i,:)=trackDat.Turns;
    % if (sum(turns,"all")>0)
    %     disp("Found a turn")
    % end
    tlendiagnostic(4)=tlendiagnostic(4)+toc-t;

end

expmt=analyze_ymaze(expmt);

disp('Done')
