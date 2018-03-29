function expmt = setROImask(expmt)


switch expmt.ROI.mode    
    case 'grid'
       
        nGrids = max(unique(expmt.ROI.grid));
        pixList = [];

        for i=1:nGrids

            % get ROI indices for corner ROIs
            idx = NaN(4,1);
            idx(1) = find(expmt.ROI.grid==i,1,'first');
            idx(4) = find(expmt.ROI.grid==i,1,'last');
            nCol = max(unique(expmt.ROI.col(idx(1):idx(4))));
            idx(2) = find(expmt.ROI.col(idx(1):idx(4))==nCol,1,'first') - (idx(1)-1);
            idx(3) = find(expmt.ROI.col(idx(1):idx(4))==1,1,'last') - (idx(1)-1);

            % vertices coordinates
            c = NaN(4,2);
            c(:,1) = expmt.ROI.corners(sub2ind(size(expmt.ROI.corners),idx,[1;3;1;3]));
            c(:,2) = expmt.ROI.corners(sub2ind(size(expmt.ROI.corners),idx,[2;2;4;4]));

            % vectors
            [~,~,vec]=getGridVertices(c([2,4,3,1],1),c([2,4,3,1],2),1,1);
            vec = squeeze(vec);

            % get pixel lists for each vector    
            y = (floor(c(1,2)):ceil(c(3,2)))';      % left line
            xL = round(vec(2,1).*y + vec(2,2));
            pixList = [pixList; xL y];

            y = (floor(c(2,2)):ceil(c(4,2)))';      % right line
            xR = round(vec(4,1).*y + vec(4,2));
            pixList = [pixList; xR y];

            x = (floor(c(1,1)):ceil(c(2,1)))';      % upper line
            yT = round(vec(1,1).*x + vec(1,2));
            pixList = [pixList; x yT];

            x = (floor(c(3,1)):ceil(c(4,1)))';      % bottom line
            yB = round(vec(3,1).*x + vec(3,2));
            pixList = [pixList; x yB];

        end

    case 'auto'
        
       pixList = cellfun(@getROIpixels,num2cell(expmt.ROI.corners,2),...
           'UniformOutput',false);
       pixList = cat(1,pixList{:});
end

mask = false(size(expmt.ROI.im));
mask(sub2ind(size(expmt.ROI.im),pixList(:,2), pixList(:,1)))=true;
mask = imfill(mask,'holes');

expmt.ROI.mask = mask;


function pL = getROIpixels(corners)

 corners = [floor(corners(1:2)) ceil(corners(3:4))];
 [x,y] = meshgrid(corners(1):corners(3),corners(2):corners(4));
 pL = [x(:) y(:)];



