function [fx, fy] = fit_adjust_proj_models(x, y, proj_x, proj_y)

% fit preliminary models
fx = fit([x y],proj_x,'poly22');
fy = fit([x y],proj_y,'poly22');

% identify model outliers
z = proj_x;
z_hat = fx(x,y);
err = abs(z-z_hat);
include = err < 80;

% fit new fx model excluding outliers
fx = fit([x(include) y(include)],z(include),'poly22');

% identify model outliers
z = proj_y;
z_hat = fy(x,y);
err = abs(z-z_hat);
include = err<80;

% fit new fx model excluding outliers
fy = fit([x(include) y(include)],z(include),'poly22');