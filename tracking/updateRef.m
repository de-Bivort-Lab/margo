function [trackDat, expmt] = updateRef(trackDat,expmt,gui_handles)

    % if num pixels above thresh exceeds nine stdev
    reset = mean(trackDat.px_dev) > 8;

    % If noise is above threshold: reset reference stack,
    if reset

        ref_stack = repmat(trackDat.im ,1, 1, gui_handles.edit_ref_depth.Value);
        trackDat.ref.im=uint8(mean(ref_stack,3));

        note = gui_handles.disp_note.String{1};
        i = find(note==')');
        subnote = note(i(1)+3:end);
        if length(subnote)>23 && strcmp(subnote(1:24),'noise threshold exceeded')
            i = find(subnote=='(');
            j = find(subnote==')');
            subnote = subnote(i+1:j-1);
            nmsgs = num2str(str2double(subnote(subnote~='x')) + 1);
            note = gui_handles.disp_note.String{1};
            i = find(note==')');
            gui_handles.disp_note.String(1) = ...
                {[note(1:i(1)) '  noise threshold exceeded, references reset (' nmsgs 'x)']};
        else
            gui_notify('noise threshold exceeded, references reset (1x)',gui_handles.disp_note);
        end
        
        % Reference vars
        nROIs = size(expmt.ROI.corners, 1);                     % total number of ROIs
        depth = gui_handles.edit_ref_depth.Value;               % number of rolling sub references
        trackDat.ref.cen = NaN(nROIs,2,depth);                  % placeholder for cen. coords where references are taken
        trackDat.ref.ct = zeros(nROIs, 1);                      % Reference number placeholder
        trackDat.ref.t = 0;                                     % reference time stamp
                
           
    % add a reference to the reference stack if time since last reference
    % exceeds the reference period
    elseif trackDat.ref.update
       
           % reset timer
           trackDat.ref.t = 0;   
           [expmt,trackDat] = refUpdateIdx(expmt,trackDat);

           trackDat.ref.update = false;
   
    end
            