function [varargout]=sortROIs(tolerance,varargin)

for i = 1:nargin-1
    switch i
        case 1
            centers = varargin{i};
        case 2
            ROI_coords = varargin{i};
        case 3
            ROI_bounds = varargin{i};
    end
end

% Separate right-side down ROIs (0) from right to left
y = centers(:,2);
[val,perm_y] = sort(y);                                % Sort ROI yCoords
row_breaks = find([0;diff(val)>std(diff(val))*tolerance]);    % Find breaks between rows


% find a final permutation by sorting each clustered set of y 
% coords by their respective x coordinates
if ~isempty(row_breaks)
for i = 1:length(row_breaks)+1
    switch i
        case 1
            
            py_subset = perm_y(1:row_breaks(i)-1);          % get subset of perm vector for current row
            [~,perm_x] = sort(centers(py_subset,1));      % sort x coords for current row
            perm_y(1:row_breaks(i)-1) = py_subset(perm_x);    % reassign the permuted permutation to full perm vector

            
        case length(row_breaks)+1
            
            py_subset = perm_y(row_breaks(i-1):end);
            [~,perm_x] = sort(centers(py_subset,1));
            perm_y(row_breaks(i-1):end) = py_subset(perm_x);
            
        otherwise
            
            py_subset = perm_y(row_breaks(i-1):row_breaks(i)-1);
            [~,perm_x] = sort(centers(py_subset,1));
            perm_y(row_breaks(i-1):row_breaks(i)-1) = py_subset(perm_x);
    end
end
end

% Sort ROI and center coords by the permutation vector defined
for i = 1:nargout
    switch i
        case 1
            varargout{i} = centers(perm_y,:);
        case 2
            varargout{i} = ROI_coords(perm_y,:);
        case 3
            varargout{i} = ROI_bounds(perm_y,:);
        case 4
            varargout{i} = perm_y;
    end

end


end



