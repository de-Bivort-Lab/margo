function expmt = modelLensDistortion(expmt)

% query available memory to determine how many batches to process data in
msz = memory;
msz = msz.MaxPossibleArrayBytes;
switch expmt.data.centroid.precision
    case 'double'
        cen_prcn = 8;
    case 'single'
        cen_prcn = 4;
end
rsz = expmt.meta.num_traces * expmt.meta.num_frames * cen_prcn * 8;

if rsz > msz
    warning(['file size too large to read into memory' ...
    ' - lens correction skipped'])
    return
end

detach(expmt);
attach(expmt.data.centroid);

% intialize cam center coords for distance calculation
cc = [size(expmt.meta.ref,2)/2 size(expmt.meta.ref,1)/2]; 
cam_dist = squeeze(sqrt((expmt.data.centroid.raw(:,1,:)-cc(1)).^2 +...
    (expmt.data.centroid.raw(:,2,:)-cc(2)).^2));

detach(expmt.data.centroid);
attach(expmt.data.speed);

spd_table = table(cam_dist(:),expmt.data.speed.raw(:),...
    'VariableNames',{'Center_Distance';'speed'});
lm = fitlm(spd_table,'speed~Center_Distance');

if (lm.Coefficients{2,4})<0.05
    expmt.meta.speed.adjusted = expmt.data.speed.raw - lm.Coefficients{2,1}.*cam_dist;
end
clear lm

if isfield(expmt,'Gravity') && isfield(expmt.Gravity,'index')
    spd_table = table(expmt.meta.roi.cam_dist,expmt.Gravity.index',...
        'VariableNames',{'Center_Distance';'Gravity'});
    lm = fitlm(spd_table,'Gravity~Center_Distance');
    if (lm.Coefficients{2,4})<0.05
        expmt.Gravity.index = expmt.Gravity.index' - lm.Coefficients{2,1}.*expmt.meta.roi.cam_dist;
    end
        
end

% re-initialize raw data maps to free memory
detach(expmt);
attach(expmt);

clear spd_table cam_dist lm



