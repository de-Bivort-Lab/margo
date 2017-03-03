function [threshold, activity_fieldname] = thresh_activity(fieldname)

switch fieldname
    case 'rBias'
        threshold = 55;
        activity_fieldname = 'numTurns';
    case 'pBias'
        threshold = 60;
        activity_fieldname = 'numTurns';
    case 'pBias_flyvac'
        threshold = 25;
        activity_fieldname = 'numTurns';
    case 'mu'
        threshold = 0.005;
        activity_fieldname = 'speed';
    case 'light_occupancy'
        threshold = 0.005;
        activity_fieldname = 'speed';
    case 'blank_occupancy'
        threshold = 0.005;
        activity_fieldname = 'speed';
end