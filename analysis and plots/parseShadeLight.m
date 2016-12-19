function [div_dist,lightStat] = parseShadeLight(stim_angles,proj_x,proj_y,stim_centers,mode)

% Perform all operations in projector space to get the position of the fly
% in relative to the stimulus

nFlies=size(stim_angles,2);
lightStat = boolean(zeros(size(stim_angles)));
div_dist = zeros(size(stim_angles));

if mode==0
    for i = 1:nFlies

        tmp_angles = stim_angles(:,i);
        tmp_x = proj_x(:,i);
        tmp_y = proj_y(:,i);

        % Convert stim_angle values to range -180 to 180
        tmp_angles(tmp_angles>180)=tmp_angles(tmp_angles>180)-360;

        % Find the range of angles that encompass the light
        bound1 = 180 + tmp_angles;
        bound1(bound1>180) = - 180 + tmp_angles(bound1>180);
        bound2 = 0 + tmp_angles;

        % Get the four-quadrant inverse tangent at each frame relative to arena center
        fly_angle = atan2(tmp_y-stim_centers(i,2),tmp_x-stim_centers(i,1)).*180./pi;

        % Determine if the fly was in the light or dark
        tmp_lightStat = boolean(zeros(size(fly_angle)));
        tmp_lightStat(bound1>0) = fly_angle(bound1>0) < bound1(bound1>0) & fly_angle(bound1>0) > bound2(bound1>0);
        tmp_lightStat(bound1<0) = fly_angle(bound1<0) < bound1(bound1<0) | fly_angle(bound1<0) > bound2(bound1<0);

        % Calculate the distance from the light dark boundary
        near_angle = zeros(size(fly_angle));
        bound1_closer = abs(fly_angle - bound1) < abs(fly_angle - bound2);
        bound2_closer = abs(fly_angle - bound2) < abs(fly_angle - bound1);
        near_angle(bound1_closer) = bound1(bound1_closer);
        near_angle(bound2_closer) = bound2(bound2_closer);
        da = abs(fly_angle - near_angle);
        da(da>90) = 180 - da(da>90);
        da = da.*pi./180;
        center_distance = sqrt((stim_centers(i,1)-tmp_x).^2+(stim_centers(i,2)-tmp_y).^2);
        div_dist(:,i) = center_distance.*sin(da);
        div_dist(tmp_lightStat,i)=div_dist(tmp_lightStat,i);
        lightStat(:,i)=~tmp_lightStat;
    end
end

if mode==1
    
        nFlies=size(stim_angles,1);
        lightStat = boolean(zeros(size(stim_angles)));
        div_dist = zeros(size(stim_angles));
        
        tmp_angles = stim_angles;
        tmp_x = proj_x;
        tmp_y = proj_y;

        % Convert stim_angle values to range -180 to 180
        tmp_angles(tmp_angles>180)=tmp_angles(tmp_angles>180)-360;

        % Find the range of angles that encompass the light
        bound1 = 180 + tmp_angles;
        bound1(bound1>180) = - 180 + tmp_angles(bound1>180);
        bound2 = 0 + tmp_angles;

        % Get the four-quadrant inverse tangent at each frame relative to arena center
        fly_angle = atan2(tmp_y-stim_centers(:,2),tmp_x-stim_centers(:,1)).*180./pi;

        % Determine if the fly was in the light or dark
        tmp_lightStat = boolean(zeros(size(fly_angle)));
        tmp_lightStat(bound1>0) = fly_angle(bound1>0) < bound1(bound1>0) & fly_angle(bound1>0) > bound2(bound1>0);
        tmp_lightStat(bound1<0) = fly_angle(bound1<0) < bound1(bound1<0) | fly_angle(bound1<0) > bound2(bound1<0);

        % Calculate the distance from the light dark boundary
        near_angle = zeros(size(fly_angle));
        bound1_closer = abs(fly_angle - bound1) < abs(fly_angle - bound2);
        bound2_closer = abs(fly_angle - bound2) < abs(fly_angle - bound1);
        near_angle(bound1_closer) = bound1(bound1_closer);
        near_angle(bound2_closer) = bound2(bound2_closer);
        da = abs(fly_angle - near_angle);
        da(da>90) = 180 - da(da>90);
        da = da.*pi./180;
        center_distance = sqrt((stim_centers(:,1)-tmp_x).^2+(stim_centers(:,2)-tmp_y).^2);
        div_dist = center_distance.*sin(da);
        div_dist(tmp_lightStat)=-div_dist(tmp_lightStat);
        lightStat=~tmp_lightStat;
end
    
    