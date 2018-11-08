function [ref, ref_stack, vid_obj] = makeVidReference(vid_obj, method, ref_stack_depth)
% Generate a background reference from a video
%
% Inputs
%   vid_obj     video object to build reference from
%   method      method of computing reference (mean or median)
%
% Outputs
%   ref         background reference image
%   ref_stack   rolling stack of background images

path = [vid_obj.Path '/' vid_obj.Name];
delete(vid_obj);
vid_obj = VideoReader(path);
n_frames = floor(vid_obj.Duration*vid_obj.FrameRate);
n_sample = 20;
stp_sz = floor(n_frames/n_sample);

if stp_sz < 1
    sample_idx = 1:n_frames;
else
    sample_idx = 1:stp_sz:n_frames;
end

test_fr = read(vid_obj,1);
frames = uint8(zeros(size(test_fr,1),size(test_fr,2),n_sample));
for i=1:numel(sample_idx)
    tmp_fr = read(vid_obj,sample_idx(i));
    if size(tmp_fr,3)>1
        tmp_fr = tmp_fr(:,:,2);
    end
    frames(:,:,i) = tmp_fr;
end

% compute ref im
switch method
    case 'mean'
        ref = uint8(mean(double(frames),3));
    case 'median'
        ref = uint8(median(frames,3));
end

ref_stack = squeeze(num2cell(repmat(ref,1,1,ref_stack_depth),[1 2]));

% re-intialize video object
delete(vid_obj);
vid_obj = VideoReader(path);


