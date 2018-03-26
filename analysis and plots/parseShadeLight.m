function [div_dist,in_light] = parseShadeLight(stim_angles,proj_x,proj_y,stim_centers,mode)

% Perform all operations in projector space to get the position of the fly
% in relative to the stimulus


if mode==0
    
    px = num2cell(proj_x,2);
    py = num2cell(proj_y,2);
    sa = num2cell(stim_angles,2);
    sc = num2cell(stim_centers,2);
    
    clearvars proj_x proj_y stim_angles stim_centers
    
    [div_dist,in_light] = arrayfun(@getDistStatus,px,py,sa,sc,'UniformOutput',false);

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
        in_light=~tmp_lightStat;
end



function [div_dist,in_light] = getDistStatus(x,y,ang,stimcen)

        x = x{:};
        y = y{:};
        ang = ang{:};
        stimcen = stimcen{:};

        % Convert stim_angle values to range -180 to 180
        ang(ang>180)=ang(ang>180)-360;

        % Find the range of angles that encompass the light
        bound1 = 180 + ang;
        bound1(bound1>180) = - 180 + ang(bound1>180);
        bound2 = 0 + ang;

        % Get the four-quadrant inverse tangent at each frame relative to arena center
        fly_angle = atan2(y-stimcen(2),x-stimcen(1)).*180./pi;

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
        center_distance = sqrt((stimcen(1)-x).^2+(stimcen(2)-y).^2);
        div_dist = center_distance.*sin(da);
        div_dist(tmp_lightStat)=div_dist(tmp_lightStat);
        in_light = ~tmp_lightStat;
    
    