function handedness = getHandedness(trackProps,varargin)

%% Set default values and parse inputs

bins = 0:2*pi/25:2*pi;
speedthresh = 0.8;
nf = size(trackProps.speed,2);
empty = single(NaN(size(trackProps.speed)));

handedness = struct('include',~isnan(empty),'mu',NaN(1,nf),'angle_histogram',NaN(length(bins),nf),...
    'circum_vel',empty,'bins',bins);


for i = 1:length(varargin)

    arg = varargin{i};

    if ischar(arg)
        switch arg
            case 'Include'
                
                i = i+1;
                include = varargin{i};
                
                if size(include,2) ~= nf
                    include = repmat(include,1,nf);
                end
                
            case 'SpeedThresh'
                i = i+1;
                speedthresh = varargin{i};
        end
    end
end

%%

if ~exist('include','var')
    include = trackProps.speed > speedthresh;
end


for j=1:nf
    handedness.circum_vel(include(:,j),j) = trackProps.theta(include(:,j),j)-...
        trackProps.direction(include(:,j),j);

    % shift negative range (-2pi to 0) up to positive (0 to 2pi)
    handedness.circum_vel(handedness.circum_vel(:,j)<0,j) = ...
        handedness.circum_vel(handedness.circum_vel(:,j)<0,j)+(2*pi);

    % bin circumferential velocity into histogram
    h = histc(handedness.circum_vel(:,j),bins);
    h = h./sum(h);

    % save to expmt data struct
    handedness.angle_histogram(:,j) = h;
    handedness.mu(j) = -sin(sum(h .* bins(1:length(bins))'));
    handedness.include(:,j) = include(:,j);
end

