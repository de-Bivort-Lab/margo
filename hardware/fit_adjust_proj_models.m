function [fx, fy] = fit_adjust_proj_models(x, y, proj_x, proj_y)

% fit preliminary models
fx = fit([x y],proj_x,'poly22');
fy = fit([x y],proj_y,'poly22');

% identify model outliers
z = proj_x;

% fit new fx model excluding outliers
for i=1:50
    z_hat = fx(x,y);
    err = abs(z-z_hat);
    include = err < std(err)*.2;
    fx = fit([x(include) y(include)],z(include),'poly22');
end

% identify model outliers
z = proj_y;
for i=1:50
    z_hat = fy(x,y);
    err = abs(z-z_hat);
    include = err < std(err)*.2;
    fy = fit([x(include) y(include)],z(include),'poly22');
end
