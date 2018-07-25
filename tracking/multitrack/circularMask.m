function imHandle = circularMask(radius, imSize)
%%
bw = false(imSize);
bw_cen = [randi(size(bw,2)) randi(size(bw,1))];
bw(bw_cen) = 1;
bw(bwdist(bw)<=radius) = true;
imHandle = bw;
imshow(imHandle)

%%
for y = 1:size(bw,1)
    for x = 1:size(bw,2)
        d = sqrt((x-bw_cen(1)).^2 + (y-bw_cen(2)).^2);
        if d <= radius
            bw(y,x) = true;
        end
    end
end

%%
x = repmat(1:size(bw,2), size(bw,1), 1);
y = repmat(1:size(bw,1), size(bw,2), 1)';
d = sqrt((x-bw_cen(1)).^2 + (y-bw_cen(2)).^2);
bw(d<=radius) = true;
imHandle = imshow(bw);



