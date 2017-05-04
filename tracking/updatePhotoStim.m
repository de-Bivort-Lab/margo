function [trackDat, expmt] = updatePhotoStim(trackDat, expmt)

        % Update the stimuli and trigger new stimulation period if stim
        % time is exceeded
        if trackDat.Texture
            update = expmt.stim.t + expmt.parameters.stim_duration*60 < trackDat.t;
        else
            update = expmt.stim.t + expmt.parameters.blank_duration*60 < trackDat.t;
        end
        
        
        if  update || trackDat.ct == 1
            
            trackDat.Texture = ~trackDat.Texture;       % Alternate between baseline and stimulation periods
            
            expmt.stim.t = trackDat.t;                  % Record the time of new stimulation period
            
            % convert current fly position to stimulus coords
            proj_centroid = NaN(size(expmt.ROI.corners,1),2);
            proj_centroid(:,1) = expmt.projector.Fx(trackDat.Centroid(:,1),trackDat.Centroid(:,2));
            proj_centroid(:,2) = expmt.projector.Fy(trackDat.Centroid(:,1),trackDat.Centroid(:,2));
            
            % Find the angle between stim_centers and proj_cen and the horizontal axis.
            trackDat.StimAngle = atan2(proj_centroid(:,2) - expmt.stim.centers(:,2), proj_centroid(:,1)-expmt.stim.centers(:,1)).*180./pi;
            
            % Rotate stim image and generate stim texture
            expmt.stim.dir = rand(size(expmt.ROI.corners,1),1) > 0.5;
            trackDat.StimAngle(expmt.stim.dir) = trackDat.StimAngle(expmt.stim.dir) + 180;
            
            if trackDat.Texture
                % Pass photo stimulation textures to screen
                Screen('DrawTextures', expmt.scrProp.window, expmt.stim.lightTex,...
                    expmt.stim.source', expmt.stim.corners', trackDat.StimAngle, [], [], [],[], []);
            else
                % Pass blank textures to screen
                Screen('DrawTextures', expmt.scrProp.window, expmt.stim.darkTex, ...
                    expmt.stim.source', expmt.stim.corners', trackDat.StimAngle, [], [], [],[], []);
            end
            % Flip to the screen
            expmt.scrProp.vbl = Screen('Flip', expmt.scrProp.window, ...
                expmt.scrProp.vbl + (expmt.scrProp.waitframes - 0.5) * expmt.scrProp.ifi);
            
        end