% Example 4. 3D Affine CPD point-set registration. Full options intialization.


% add outliers and delete some points
X=c1;
Y=c2;



% Set the options
opt.method='affine'; % use rigid registration
opt.viz=1;          % show every iteration
opt.outliers=6;   % use 0.6 noise weight to add robustness 

opt.normalize=0;    % normalize to unit variance and zero mean before registering (default)
opt.scale=1;        % estimate global scaling too (default)
opt.rot=1;          % estimate strictly rotational matrix (default)
opt.corresp=0;      % do not compute the correspondence vector at the end of registration (default)

opt.max_it=1000;     % max number of iterations
opt.tol=1e-10;       % tolerance


% registering Y to X
[Transform, Correspondence]=cpd_register(X,Y,opt);

figure,cpd_plot_iter(X, Y); title('Before');

% X(Correspondence,:) corresponds to Y
figure,cpd_plot_iter(X, Transform.Y);  title('After registering Y to X');
