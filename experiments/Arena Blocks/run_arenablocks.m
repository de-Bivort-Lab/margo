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

%% setup experiment blocks

exp_names = {'basictracking';'optomotor';'slowphototaxis'};
nExp = length(exp_names);

% initialize the experiment master structs for each experiment
expmt.Finish = false;
basic = expmt;
opto = expmt;
photo = expmt;

% set basic tracking to full illumination
basic.light.white = uint8(255);

% set duration of each experiment block in hrs
rep_dur = 0.5;     
nReps = ceil(gui_handles.edit_exp_duration.Value/rep_dur);
gui_handles.edit_exp_duration.Value = rep_dur * nReps;

% randomize experiment blocks
perm = perms(1:nExp);                           % query all permutations of 1:nExp
perm = perm(randperm(size(perm,1),nReps),:)';   % randomly select nReps permuations
perm = perm(:);                                 % linearize

%% Randomize experimental blocks

t=0;
exp_ct=0;

while t < gui_handles.edit_exp_duration.Value * 3600
    
    % grab a randomized block
    exp_ct = exp_ct + 1;
    
    % switch experiment blocks
    switch exp_names{perm(exp_ct)}
        
        case 'basictracking'
            
            % initialize on the first iteration, otherwise, pass in trackDat
            if exp_ct < nExp
                
                [basic, trackDat_basic] = run_basictracking(basic,gui_handles);
                basic.Initialize = false;
                
            else
                
                % update experiment timer
                trackDat_basic.t = t;
                
                % run experiment block
                [basic, trackDat_basic] = run_basictracking(basic,gui_handles,...
                    'Trackdat',trackDat_basic);
                
            end
            
            t = trackDat_basic.t;
            
        case 'optomotor'
            
            % initialize on the first iteration, otherwise, pass in trackDat
            if exp_ct < nExp
                
                [opto, trackDat_opto] = run_optomotor(opto,gui_handles);
                opto.Initialize = false;
                
            else
                
                % update experiment timer
                trackDat_opto.t = t;
                
                % run experiment block
                [opto, trackDat_opto] = run_optomotor(opto,gui_handles,...
                    'Trackdat',trackDat_opto);
                
            end
            
            t = trackDat_opto.t;
            
        case 'slowphototaxis'
            
            % initialize on the first iteration, otherwise, pass in trackDat
            if exp_ct < nExp
                
                [photo, trackDat_photo] = run_slowphototaxis(photo,gui_handles);
                photo.Initialize = false;
                
            else
                
                % update experiment timer
                trackDat_photo.t = t;
                
                % run experiment block
                [photo, trackDat_photo] = run_slowphototaxis(photo,gui_handles,...
                    'Trackdat',trackDat_photo);
                
            end
            
            t = trackDat_photo.t;
            
    end
    
end


%% Post-experiment processing and clean-up

% wrap up experiment and save master struct
basic = autoFinish(trackDat_basic, basic, gui_handles);
opto = autoFinish(trackDat_opto, opto, gui_handles);
photo = autoFinish(trackDat_photo, photo, gui_handles);

for i=1:nargout
    switch i
        case 1, varargout(i) = {basic};
        case 2, varargout(i) = {opto};
        case 3, varargout(i) = {photo};
    end
end

