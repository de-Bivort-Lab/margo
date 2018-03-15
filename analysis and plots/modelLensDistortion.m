function expmt = modelLensDistortion(expmt)

% query available memory to determine how many batches to process data in
msz = memory;
msz = msz.MaxPossibleArrayBytes;
switch expmt.Centroid.precision
    case 'double'
        cen_prcn = 8;
    case 'single'
        cen_prcn = 4;
end
rsz = expmt.nTracks * expmt.nFrames * cen_prcn *16;

if rsz > msz
    warning(['file size too large to read into memory' ...
    ' - lens correction skipped'])
    return
end

% intialize cam center coords for distance calculation
cc = [size(expmt.ref,2)/2 size(expmt.ref,1)/2]; 
cam_dist = squeeze(sqrt((expmt.Centroid.map.Data.raw(:,1,:)-cc(1)).^2 +...
    (expmt.Centroid.map.Data.raw(:,2,:)-cc(2)).^2));

spd_table = table(cam_dist(:),expmt.Speed.map.Data.raw(:),...
    'VariableNames',{'Center_Distance';'Speed'});
lm = fitlm(spd_table,'Speed~Center_Distance');

if (lm.Coefficients{2,4})<0.05
    expmt.Speed.map.Writable = true;
    expmt.Speed.map.Data.raw= expmt.Speed.map.Data.raw- lm.Coefficients{2,1}.*cam_dist;
end
clear lm

if isfield(expmt,'Gravity') && isfield(expmt.Gravity,'index')
    spd_table = table(expmt.ROI.cam_dist,expmt.Gravity.index',...
        'VariableNames',{'Center_Distance';'Gravity'});
    lm = fitlm(spd_table,'Gravity~Center_Distance');
    if (lm.Coefficients{2,4})<0.05
        expmt.Gravity.index = expmt.Gravity.index' - lm.Coefficients{2,1}.*expmt.ROI.cam_dist;
    end
        
end




