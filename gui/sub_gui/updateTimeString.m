function updateTimeString(timeRemaining, edit_handle)

    if timeRemaining < 60; 
        set(edit_handle, 'String', ['00:00:' sprintf('%0.2d',timeRemaining)]);
        set(edit_handle, 'BackgroundColor', [0.4 0.4 1]);
    elseif (3600 > timeRemaining) && (timeRemaining > 60);
        min = floor(timeRemaining/60);
        sec = rem(timeRemaining, 60);
        set(edit_handle, 'String', ['00:' sprintf('%0.2d',min) ':' sprintf('%0.2d',sec)]);
        set(edit_handle, 'BackgroundColor', [1 1 1]);
    elseif timeRemaining > 3600;
        hr = floor(timeRemaining/3600);
        min = floor(rem(timeRemaining, 3600)/60);
        sec = timeRemaining - hr*3600 - min*60;
        set(edit_handle, 'String', [sprintf('%0.2d', hr) ':' sprintf('%0.2d',min) ':' sprintf('%0.2d',sec)]);
        set(edit_handle, 'BackgroundColor', [1 1 1]);
    end
    
end