function [trail_x, trail_y] = update_trail_coords(x,y,trail_x,trail_y)

% shift the trail positions back by one
trail_x = circshift(trail_x,1);
trail_y = circshift(trail_y,1);

% replace the first element of each with the current position
trail_x(1) = x;
trail_y(1) = y;

% remove points that are effectively duplicate
mask = ~isnan(trail_x);
distance = sqrt(diff(trail_x(mask)).^2 + diff(trail_y(mask)).^2);
mask = find(mask);
mask = mask([false; distance<0.05]);
trail_x(mask) = NaN;
trail_y(mask) = NaN;
        