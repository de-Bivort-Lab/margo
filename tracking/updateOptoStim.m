function [trackDat, expmt] = updateOptoStim(trackDat, expmt)

        % Calculate radial distance for each fly
        r = sqrt((trackDat.Centroid(:,1)-expmt.ROI.centers(:,1)).^2 +...
            (trackDat.Centroid(:,2)-expmt.ROI.centers(:,2)).^2);
        
        % Update which stimuli (if any) need to be turned on
        local_spd(mod(trackDat.ct-1,15)+1,:) = trackDat.Speed;
        moving = nanmean(local_spd)' > 2;
        in_center = r < (expmt.ROI.bounds(:,4)./4);
        timeup = trackDat.t - expmt.stim.timer > expmt.parameters.stim_int;
        
        % Activate the stimulus when flies are: moving, away from the 
        % edges, have exceeded the mandatory wait time between subsequent
        % presentations, and are not already being presented with a stimulus
        activate_stim = moving & in_center & timeup & ~trackDat.StimStatus;
        trackDat.Texture(activate_stim) = rand(sum(activate_stim),1)>0.5;      % Randomize the rotational direction
        trackDat.StimStatus(activate_stim) = true;                          % Set stim status to ON
        expmt.stim.t(activate_stim)=trackDat.t;                        % Record the time
        
        
        if any(trackDat.StimStatus)
            
            expmt.stim.ct = expmt.stim.ct+1;
            
            % Rotate stim image and generate stim texture
            p_rotim = imrotate(expmt.stim.im, expmt.stim.angle, 'bilinear', 'crop');
            p_rotim = p_rotim(expmt.stim.bounds(2):expmt.stim.bounds(4),...
                expmt.stim.bounds(1):expmt.stim.bounds(3));
            n_rotim = imrotate(expmt.stim.im, -expmt.stim.angle, 'bilinear', 'crop');
            n_rotim = n_rotim(expmt.stim.bounds(2):expmt.stim.bounds(4),...
                expmt.stim.bounds(1):expmt.stim.bounds(3));

            % Calculate the displacement from the ROI center in projector space
            p_cen = NaN(sum(trackDat.StimStatus),2);
            p_cen(:,1) = expmt.projector.Fx(trackDat.Centroid(trackDat.StimStatus,1),...
                trackDat.Centroid(trackDat.StimStatus,2));
            p_cen(:,2) = expmt.projector.Fy(trackDat.Centroid(trackDat.StimStatus,1),...
                trackDat.Centroid(trackDat.StimStatus,2));
            p_dist = [p_cen(:,1) - expmt.stim.centers(trackDat.StimStatus,1),...
                p_cen(:,2) - expmt.stim.centers(trackDat.StimStatus,2)];
            p_dist = p_dist .* expmt.stim.scale(trackDat.StimStatus,:);
            src_rects = NaN(size(expmt.stim.corners(trackDat.StimStatus,:)));
            src_rects(:,[1 3]) = [expmt.stim.cen_src(1)-p_dist(:,1),...
                expmt.stim.cen_src(3)-p_dist(:,1)];
            src_rects(:,[2 4]) = [expmt.stim.cen_src(2)-p_dist(:,2),...
                expmt.stim.cen_src(4)-p_dist(:,2)];
            
            Screen('Close', expmt.stim.pinTex_pos);
            Screen('Close', expmt.stim.pinTex_neg);
            expmt.stim.pinTex_pos = Screen('MakeTexture',expmt.scrProp.window, p_rotim);
            expmt.stim.pinTex_neg = Screen('MakeTexture',expmt.scrProp.window, n_rotim);

            % Pass textures to screen
            if any(trackDat.Texture(trackDat.StimStatus))
                Screen('DrawTextures', expmt.scrProp.window, expmt.stim.pinTex_pos,...
                    src_rects(trackDat.Texture(trackDat.StimStatus),:)', ...
                    expmt.stim.corners(trackDat.StimStatus & trackDat.Texture,:)', [],...
                    [], [], [],[], []);
            end
            if any(~trackDat.Texture(trackDat.StimStatus))
                Screen('DrawTextures', expmt.scrProp.window, expmt.stim.pinTex_neg,...
                    src_rects(~trackDat.Texture(trackDat.StimStatus),:)', ...
                    expmt.stim.corners(trackDat.StimStatus & ~trackDat.Texture,:)', [],...
                    [], [], [],[], []);
            end

            % Flip to the screen
            expmt.scrProp.vbl = Screen('Flip', expmt.scrProp.window, ...
                expmt.scrProp.vbl + (expmt.scrProp.waitframes - 0.5) * expmt.scrProp.ifi);

            % Advance the stimulus angle
            expmt.stim.angle=expmt.stim.angle+expmt.parameters.ang_per_frame;
            if expmt.stim.angle >= 360
                expmt.stim.angle=expmt.stim.angle-360;
            end
        
        end
        
        % Turn off stimuli that have exceed the display duration
          stim_OFF = trackDat.t-expmt.stim.t >= expmt.parameters.stim_int & trackDat.StimStatus;
          trackDat.StimStatus(stim_OFF) = false;         % Set stim status to OFF
                    
        % Update stim timer for stimulus turned off
        if any(stim_OFF)
            
            % Reset the stimulus timer
            expmt.stim.timer(stim_OFF)=trackDat.t;
        end