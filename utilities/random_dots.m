function centers = random_dots(max_x, max_y, n_dots, radius)

% generate pts
x = randi(max_x,[n_dots 1]);
y = randi(max_y,[n_dots 1]);

% calculate pw dist
dx = dot((x-x')',x'-x,3);
dy = dot((y-y')',y'-y,3);
d = sqrt(dx+dy);
d(d==0)=NaN;

% find points that are too close together and remove
[row_idx,~]=find(d<radius*1.5);
x(row_idx)=[];
y(row_idx)=[];

centers =[x y];