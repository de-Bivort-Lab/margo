function X_tform = cpd_margo(X,Y)
% Co-register projected random dots from projector display field to the
% camera FOV iva coherent point drift (CPD). CPD was developed by Andriy
% Myronenko et al. Registers points (Y) to a set of reference points (X)
% via a transform (T)

% More information on CPD can be found in the original publication
%   Myronenko A., Song X. (2010): "Point-Set Registration: Coherent Point 
%   Drift", IEEE Trans. on Pattern Analysis and Machine Intelligence, 
%   vol. 32, issue 12, pp. 2262-2275



% Init full set of options %%%%%%%%%%
opt.method='rigid';     % use nonrigid registration
opt.beta=2;            % the width of Gaussian kernel (smoothness)
opt.lambda=.01;          % regularization weight

opt.viz=0;              % show every iteration
opt.outliers=0.7;       % use 0.7 noise weight
opt.fgt=0;              % do not use FGT (default)
opt.normalize=1;        % normalize to unit variance and zero mean before registering (default)
opt.corresp=1;          % compute correspondence vector at the end of registration (not being estimated by default)

opt.max_it=1000;         % max number of iterations
opt.tol=1e-10;          % tolerance

[T, ~]=cpd_register(X,Y, opt);
X_tform = T.Y;