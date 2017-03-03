function scrProp=drawCircles(x,y,r,color,scrProp)
%
% This function draws circles of the specified color and radius "r" at the 
% points by x and y. Requires screen properties (scrProp) output by
% initialze_projector.m


dst_rect=[x-r y-r x+r y+r];
Screen('FillOval', scrProp.window, color, dst_rect');

% Flip our drawing to the screen
scrProp.vbl = Screen('Flip', scrProp.window);%, scrProp.vbl + (scrProp.waitframes - 0.5) * scrProp.ifi);
end
