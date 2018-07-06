function updateTimeString(timeRemaining, edit_handle)
% converts timeRemaining (sec) into hr, min, and sec and updates the GUI timer

    hr = floor(timeRemaining/3600);
    min = floor(rem(timeRemaining, 3600)/60);
    sec = floor(timeRemaining - hr*3600 - min*60);
    
    % append third digit if hr > 99
    if hr > 99
        edit_handle.String = sprintf('%0.3d:%0.2d:%0.2d',hr,min,sec);
    else
        edit_handle.String = sprintf('%0.2d:%0.2d:%0.2d',hr,min,sec);
    end

    % change time display to blue if tracking is ending
    if timeRemaining < 60; 
        edit_handle.BackgroundColor = [0.4 0.4 1];
    else 
        edit_handle.BackgroundColor = [1 1 1];
    end
    
end