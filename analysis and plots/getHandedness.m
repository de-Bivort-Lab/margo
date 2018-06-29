function handedness = getHandedness(trackProps,varargin)

%% Set default values and parse inputs

bw = 2*pi/25;                                   % bin width
bins = 0:bw:2*pi;                          % handedness bins
speedthresh = 0.8;
nf = min(size(trackProps.speed));
empty = single(NaN(size(trackProps.speed)));

handedness = struct('include',~isnan(empty),'mu',NaN(1,nf),...
    'angle_histogram',NaN(length(bins),nf),'bins',bins,'bin_width',bw);


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
                
            case 'speedThresh'
                i = i+1;
                speedthresh = varargin{i};
        end
    end
end

%%

if ~exist('include','var')
    include = trackProps.speed > speedthresh;
end
handedness.include = include;
include = num2cell(include,1);
body_ang = num2cell(trackProps.Theta,1);
Direction = num2cell(trackProps.Direction,1);

[mu,ang_hist] = cellfun(@(x,y,z) mu_score(x,y,z,bins),...
    include,body_ang,Direction,'UniformOutput',false);
handedness.mu = cat(1,mu{:});
handedness.angle_histogram = cat(2,ang_hist{:});


function [mu,hist] = mu_score(filt,Theta,dir,bins)

circum_vel = Theta(filt) - dir(filt);

% shift negative range (-2pi to 0) up to positive (0 to 2pi)
circum_vel(circum_vel<0) = circum_vel(circum_vel<0)+(2*pi);

% bin circumferential velocity into histogram
h = histc(circum_vel,bins);
h = h./sum(h);

bw = bins(2)-bins(1);

% save to expmt data struct
hist = h;
mu = -sin(sum(h .* (bins' + bw/2)));


