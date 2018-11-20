function centers = random_dots(max_x, max_y, n_dots, radius)

% generate pts
x = randi(max_x,[n_dots 1]);
y = randi(max_y,[n_dots 1]);

% calculate pw dist
dx = repmat(x,1,numel(x)) - repmat(x,1,numel(x))';
dy = repmat(y,1,numel(y)) - repmat(y,1,numel(y))';
d = sqrt(dx.^2 + dy.^2);
d(d==0)=NaN;

% find points that are too close together and remove
[row_idx,~]=find(d<(radius*3));
x(row_idx)=[];
y(row_idx)=[];

centers =[x y];