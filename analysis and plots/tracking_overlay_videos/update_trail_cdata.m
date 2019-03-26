function trail_cdata = update_trail_cdata(has_coord, base_color)

if size(base_color,2) > 1
    base_color = base_color';
end

% initialize trail color and alpha values
trail_length = numel(has_coord);
trail_alpha = uint8([linspace(255,0,trail_length) 0]);
trail_alpha = trail_alpha(has_coord);
trail_color = repmat(base_color,1,trail_length);
trail_color = trail_color(:,has_coord);

% ensure trail starts and ends with 0 alpha
if ~isempty(trail_alpha)
    trail_alpha(1) = 0;
    trail_alpha(end) = 0;
end

trail_cdata = [trail_color; trail_alpha];

