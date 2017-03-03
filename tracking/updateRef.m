function [trackDat, ref_stack, expmt] = updateRef(trackDat,ref_stack,expmt,gui_handles)

    % if num pixels above thresh exceeds nine stdev
    reset = mean(trackDat.px_dev) > 9;

    % If noise is above threshold: reset reference stack,
    if reset

           ref_stack = repmat(trackDat.im ,1, 1, gui_handles.edit_ref_depth.Value);
           expmt.ref=uint8(mean(ref_stack,3));

           disp('LARGE NOISE SPIKE DETECTED, REFERENCES RESET')
           
    % add a reference to the reference stack if time since last reference
    % exceeds the reference period
    elseif trackDat.t_ref > gui_handles.edit_ref_freq.Value * 60
        
           trackDat.ref_ct = trackDat.ref_ct + 1;
           ref_stack(:,:,mod(trackDat.ref_ct, gui_handles.edit_ref_depth.Value)+1) = trackDat.im;
           expmt.ref=uint8(mean(ref_stack,3));
           
           % reset timer
           trackDat.t_ref = 0;
   
    end
            