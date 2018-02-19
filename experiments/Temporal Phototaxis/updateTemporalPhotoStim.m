function [trackDat, expmt] = updateTemporalPhotoStim(trackDat, expmt)

        % Update the stimuli and trigger new stimulation period if stim
        % get light status
        pcen(:,1) = expmt.projector.Fx(trackDat.Centroid(:,1),trackDat.Centroid(:,2));
        pcen(:,2) = expmt.projector.Fy(trackDat.Centroid(:,1),trackDat.Centroid(:,2));

        [div_dist,in_light] = parseShadeLight(trackDat.StimAngle,pcen(:,1),pcen(:,2),expmt.stim.centers,1);
        off_divider = abs(div_dist) > expmt.parameters.div_thresh';
        changed = trackDat.LightStatus ~= in_light;
        update = changed & off_divider;
        trackDat.LightStatus(update) = in_light(update);
        
        
        if  any(update) || trackDat.ct == 1
            
            expmt.stim.t = trackDat.t;                  % Record the time of new stimulation period
            
            % convert current fly position to stimulus coords
            proj_centroid = NaN(size(expmt.ROI.corners,1),2);
            proj_centroid(:,1) = expmt.projector.Fx(trackDat.Centroid(:,1),trackDat.Centroid(:,2));
            proj_centroid(:,2) = expmt.projector.Fy(trackDat.Centroid(:,1),trackDat.Centroid(:,2));
            
            
            if any(trackDat.LightStatus)
                % Pass photo stimulation textures to screen
                Screen('DrawTextures', expmt.scrProp.window, expmt.stim.lightTex,...
                    expmt.stim.source', expmt.stim.corners(trackDat.LightStatus,:)',...
                    0, [], [], [],[], []);
            end
            if any(~trackDat.LightStatus)
                % Pass blank textures to screen
                Screen('DrawTextures', expmt.scrProp.window, expmt.stim.darkTex, ...
                    expmt.stim.source', expmt.stim.corners(~trackDat.LightStatus,:)',...
                    0, [], [], [],[], []);
            end
            
            % Flip to the screen
            expmt.scrProp.vbl = Screen('Flip', expmt.scrProp.window, ...
                expmt.scrProp.vbl + (expmt.scrProp.waitframes - 0.5) * expmt.scrProp.ifi);
            
        end
        
        trackDat.update = update;