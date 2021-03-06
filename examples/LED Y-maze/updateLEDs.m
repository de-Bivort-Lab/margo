function trackDat = updateLEDs(trackDat)

% Randomly select a new LED to turn on
LEDs = trackDat.LEDs;
if any(trackDat.changed_arm)
    iShift = 0:3:(sum(trackDat.changed_arm)-1)*3;
    turns = trackDat.Turns;
    turns = turns(trackDat.changed_arm)';
    
    % Convert arm to index #
    turns = double(turns) + iShift;   
    
    % Randomly select new LED and exclude the currently occupied arm
    newArm = rand(sum(trackDat.changed_arm)*3,1); 
    newArm(turns)=0;                     % 
    newArm = reshape(newArm,3,sum(trackDat.changed_arm))'; 
    
    % Select new arm by picking highest random number in each row (roi)
    [~,c] = max(newArm,[],2);                      
    newArm = c'+iShift;
    newLEDs = zeros(size(newArm,2)*3,1);
    newLEDs(newArm) = 1;
    newLEDs = reshape(newLEDs,3,sum(trackDat.changed_arm))';
    LEDs(trackDat.changed_arm,:)=newLEDs;
    
    % update trackDat
    trackDat.LEDs = LEDs;
    
    switch trackDat.led_mode
        case 'random'
            pwm_idx = randi(numel(trackDat.pwm_scale),[sum(trackDat.changed_arm) 1]);
            trackDat.led_pwm(trackDat.changed_arm) = trackDat.pwm_scale(pwm_idx);
    end
end



