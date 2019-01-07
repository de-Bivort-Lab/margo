function [trackDat, expmt] = updateTemporalPhotoStim(trackDat, expmt)

        % Update the stimuli and trigger new stimulation period if stim
        % get light status
        stim = expmt.meta.stim;
        scr = expmt.hardware.screen;
        
        % convert current fly position to stimulus coords
        pcen = NaN(size(expmt.meta.roi.corners,1),2);
        c = double(trackDat.centroid);
        c(isnan(c(:,1)),:) = expmt.meta.roi.centers(isnan(c(:,1)),:);
            
        pcen(:,1) = expmt.hardware.projector.Fx(c(:,1),c(:,2));
        pcen(:,2) = expmt.hardware.projector.Fy(c(:,1),c(:,2));

        [div_dist,in_light] = ...
            parseShadeLight(trackDat.StimAngle,pcen(:,1),...
                pcen(:,2),stim.centers,1);
        off_divider = abs(div_dist) > expmt.parameters.divider_size';
        changed = trackDat.LightStatus ~= in_light;
        update = changed & off_divider;
        trackDat.LightStatus(update) = in_light(update);
        
        
        if  any(update) || trackDat.ct == 1
            
            % Record the time of new stimulation period
            stim.t = trackDat.t;                  
            
            if any(trackDat.LightStatus)
                % Pass photo stimulation textures to screen
                Screen('DrawTextures', scr.window, ...
                    stim.lightTex, stim.source', ...
                    stim.corners(trackDat.LightStatus,:)',...
                    0, [], [], [],[], []);
            end
            if any(~trackDat.LightStatus)
                % Pass blank textures to screen
                Screen('DrawTextures', scr.window, ...
                    stim.darkTex, stim.source', ...
                    stim.corners(~trackDat.LightStatus,:)',...
                    0, [], [], [],[], []);
            end
            
            % Flip to the screen
            scr.vbl = ...
                Screen('Flip', scr.window, ...
                    scr.vbl + ...
                    (scr.waitframes - 0.5) * ...
                    scr.ifi);
            
        end
        
        expmt.hardware.screen = scr;
        expmt.meta.stim = stim;
        trackDat.update = update;