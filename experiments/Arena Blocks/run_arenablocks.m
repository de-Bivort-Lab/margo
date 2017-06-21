function varargout = run_arenablocks(expmt,gui_handles)
%
% This is a blank experimental template to serve as a framework for new
% custom experiments. The function takes the master experiment struct
% (expmt) and the handles to the gui (gui_handles) as inputs and outputs
% the data assigned to out. In this example, object centroid, pixel area,
% and the time of each frame are output to file.

%% Initialization: Get handles and set default preferences

gui_notify(['executing ' mfilename '.m'],gui_handles.disp_note);

% clear memory
clearvars -except gui_handles expmt

% get handles
gui_fig = gui_handles.gui_fig;                            % gui figure handle
imh = findobj(gui_handles.axes_handle,'-depth',3,'Type','image');   % image handle

%% Create a new directory

expmt.date = datestr(clock,'mm-dd-yyyy-HH-MM-SS_');         % get date string
expmt.labels_table = labelMaker(expmt);                           % convert labels cell into table format

% Query label fields and set label for file
lab_fields = expmt.labels_table.Properties.VariableNames;
expmt.fLabel = [expmt.date '_' expmt.Name];
for i = 1:length(lab_fields)
    switch lab_fields{i}
        case 'Strain'
            expmt.(lab_fields{i}) = expmt.labels_table{1,i}{:};
            expmt.fLabel = [expmt.fLabel '_' expmt.labels_table{1,i}{:}];
        case 'Sex'
            expmt.(lab_fields{i}) = expmt.labels_table{1,i}{:};
            expmt.fLabel = [expmt.fLabel '_' expmt.labels_table{1,i}{:}];
        case 'Treatment'
            expmt.(lab_fields{i}) = expmt.labels_table{1,i}{:};
            expmt.fLabel = [expmt.fLabel '_' expmt.labels_table{1,i}{:}];
        case 'Day'
            expmt.(lab_fields{i}) = expmt.labels_table{1,i};
            expmt.fLabel = [expmt.fLabel '_Day' num2str(expmt.labels_table{1,i})];
        case 'ID'
            ids = expmt.labels_table{:,i};
            expmt.fLabel = [expmt.fLabel '_' num2str(ids(1)) '-' num2str(ids(end))];
    end
end

% make a new directory for the files
expmt.fpath = [expmt.fpath '\' expmt.fLabel '\'];
mkdir(expmt.fpath);

%% setup experiment blocks

exp_names = expmt.block.fields;
nExp = length(exp_names);

% initialize the experiment master structs for each experiment
expmt.Finish = false;
expmt.Initialize = true;
expmt.block.t = 0;

% assign expmt specific parameters
rep_dur = 0;
if any(strcmp(exp_names,'Arena Circling'))
    circle = expmt;
    circle.Name = 'Arena Circling';
    circle.light.white = uint8(255);
    rep_dur = rep_dur + expmt.block.arena_duration;
end

if any(strcmp(exp_names,'Optomotor'))
    opto = expmt;
    opto.Name = 'Optomotor';
    opto.parameters = expmt.opto_parameters;
    rep_dur = rep_dur + expmt.block.opto_duration;
end

if any(strcmp(exp_names,'Slow Phototaxis'))
    photo = expmt;
    photo.Name = 'Slow Phototaxis';
    photo.parameters = expmt.photo_parameters;
    rep_dur = rep_dur + expmt.block.photo_duration;
end

rep_dur = rep_dur/60;   % convert from minutes to hours

% set duration of each experiment block in hrs
nReps = ceil(gui_handles.edit_exp_duration.Value/rep_dur);
gui_handles.edit_exp_duration.Value = rep_dur * nReps;

% randomize experiment blocks
perm = perms(1:nExp);                           % query all permutations of 1:nExp
perm = repmat(perm,ceil(nReps/nExp),1);         % scale number of permutations up to match nReps    
perm = perm(randperm(size(perm,1),nReps),:)';   % randomly select nReps permuations
perm = perm(:);                                 % linearize

%% Randomize experimental blocks

try

t=0;
exp_ct=0;

while t < gui_handles.edit_exp_duration.Value * 3600 
    
    % grab a randomized block
    exp_ct = exp_ct + 1;
    
    % switch experiment blocks
    switch exp_names{perm(exp_ct)}
        
        case 'Arena Circling'
            
            % set projector to black
            bg_color=[0 0 0];          
            expmt.scrProp=initialize_projector(expmt.reg_params.screen_num,bg_color);
            pause(0.5);
            
            % move mouse cursor
            robot = java.awt.Robot;
            robot.mouseMove(1, 1);            

            % initialize on the first iteration, otherwise, pass in trackDat
            if exp_ct <= nExp
                
                [circle, trackDat_circle] = run_arenacircling(circle,gui_handles);
                circle.Initialize = false;
                
                t = t + trackDat_circle.t;
                
            else
                
                % update experiment timer
                trackDat_circle.t = t;
                circle.block.t = t;
                
                % run experiment block
                [circle, trackDat_circle] = run_arenacircling(circle,gui_handles,...
                    'Trackdat',trackDat_circle);
                
                t = trackDat_circle.t;
                
            end            
            
            
        case 'Optomotor'
           
            
            % initialize on the first iteration, otherwise, pass in trackDat
            if exp_ct <= nExp
                
                [opto, trackDat_opto] = run_optomotor(opto,gui_handles);
                opto.Initialize = false;
                
                t = t + trackDat_opto.t;
                
            else
                
                % update experiment timer
                trackDat_opto.t = t;
                opto.block.t = t;
                
                % run experiment block
                [opto, trackDat_opto] = run_optomotor(opto,gui_handles,...
                    'Trackdat',trackDat_opto);
                
                t = trackDat_opto.t;
                
            end           
            
            
        case 'Slow Phototaxis'            
           
            
            % initialize on the first iteration, otherwise, pass in trackDat
            if exp_ct <= nExp
                
                [photo, trackDat_photo] = run_slowphototaxis(photo,gui_handles);
                photo.Initialize = false;
                
                t = t + trackDat_photo.t;
                
            else
                
                % update experiment timer
                trackDat_photo.t = t;
                photo.block.t = t;
                
                % run experiment block
                [photo, trackDat_photo] = run_slowphototaxis(photo,gui_handles,...
                    'Trackdat',trackDat_photo);
                
                t = trackDat_photo.t;
                
            end           
    end   
end

catch ME
    sca;
    disp('whoops');
    rethrow(ME);
end

%% Post-experiment processing and clean-up

% wrap up experiment and save master struct
circle = autoFinish(trackDat_circle, circle, gui_handles);
opto = autoFinish(trackDat_opto, opto, gui_handles);
photo = autoFinish(trackDat_photo, photo, gui_handles);

for i=1:nargout
    switch i
        case 1, varargout(i) = {circle};
        case 2, varargout(i) = {opto};
        case 3, varargout(i) = {photo};
    end
end

