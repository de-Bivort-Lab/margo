function [trackDat, expmt] = updatePhotoStim(trackDat, expmt)

        % Update the stimuli and trigger new stimulation period if stim
        % time is exceeded
        stim = expmt.meta.stim;
        scr = expmt.hardware.screen;
        if trackDat.Texture
            update = ...
                stim.t + expmt.parameters.stim_duration*60 < trackDat.t;
        else
            update = ...
                stim.t + expmt.parameters.blank_duration*60 < trackDat.t;
        end
        
        
        if  update || trackDat.ct == 1
            
            % Alternate between baseline and stimulation periods
            trackDat.Texture = ~trackDat.Texture;       
            stim.t = trackDat.t;
            
            % convert current fly position to stimulus coords
            proj_centroid = NaN(size(expmt.meta.roi.corners,1),2);
            c = double(trackDat.centroid);
            proj_centroid(:,1) = expmt.hardware.projector.Fx(c(:,1),c(:,2));
            proj_centroid(:,2) = expmt.hardware.projector.Fy(c(:,1),c(:,2));
            
            % Find the angle between stim_centers and proj_cen and the horizontal axis.
            trackDat.StimAngle = ...
                single(atan2(proj_centroid(:,2) -stim.centers(:,2), ...
                    proj_centroid(:,1) - stim.centers(:,1)).*180./pi);
            
            % Rotate stim image and generate stim texture
            stim.dir = rand(size(expmt.meta.roi.corners,1),1) > 0.5;
            trackDat.StimAngle(stim.dir) = ...
                trackDat.StimAngle(stim.dir) + 180;
            
            if trackDat.Texture
                % Pass photo stimulation textures to screen
                Screen('DrawTextures', scr.window, ...
                    stim.lightTex, stim.source', ...
                    stim.corners', trackDat.StimAngle, [], [], [],[], []);
            else
                % Pass blank textures to screen
                Screen('DrawTextures', scr.window, ...
                    stim.darkTex, stim.source', ...
                    stim.corners', trackDat.StimAngle, [], [], [],[], []);
            end
            % Flip to the screen
            scr.vbl = Screen('Flip', scr.window,scr.vbl + ...
                        (scr.waitframes - 0.5)* scr.ifi);
            
        end
        
        % re-assign stim
        expmt.meta.stim = stim;
        expmt.hardware.screen = scr;