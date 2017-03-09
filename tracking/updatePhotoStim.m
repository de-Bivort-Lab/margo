function [trackDat, expmt] = updatePhotoStim(trackDat, expmt, gui_handles)

      % Update the stimuli and trigger new stimulation period if stim
        % time is exceeded
        if stim_tStamp+stim_duration < tElapsed || exp_start
            
            exp_start = boolean(0);
            active_tex = ~active_tex;     % Alternate between baseline and stimulation periods
            
            stim_tStamp=tElapsed;         % Record the time of new stimulation period
            
            % convert current fly position to stimulus coords
            proj_centroid=NaN(size(ROI_coords,1),2);
            proj_centroid(:,1)=Fx(lastCentroid(:,1),lastCentroid(:,2));
            proj_centroid(:,2)=Fy(lastCentroid(:,1),lastCentroid(:,2));
            
            % determine which half of the arena is l
            
            % Find the angle between stim_centers and proj_cen and the horizontal axis.
            stim_angles = atan2(proj_centroid(:,2)-stim_centers(:,2),proj_centroid(:,1)-stim_centers(:,1)).*180./pi;
            
            % Rotate stim image and generate stim texture
            rot_dir = rand(size(ROI_coords,1),1)>0.5;
            stim_angles(rot_dir) = stim_angles(rot_dir)+180;
            
            if active_tex
                % Pass photo stimulation textures to screen
                Screen('DrawTextures', scrProp.window, photo_stimTex, srcRect', stim_coords', stim_angles,...
                [], [], [],[], []);
            else
                % Pass blank textures to screen
                Screen('DrawTextures', scrProp.window, blank_stimTex, srcRect', stim_coords', stim_angles,...
                [], [], [],[], []);
            end
            % Flip to the screen
            scrProp.vbl = Screen('Flip', scrProp.window, scrProp.vbl + (scrProp.waitframes - 0.5) * scrProp.ifi);
        end