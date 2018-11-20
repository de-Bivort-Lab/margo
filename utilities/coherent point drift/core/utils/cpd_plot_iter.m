%   CPD_PLOT(X, Y, C); plots 2 data sets. Works only for 2D and 3D data sets.
%
%   Input
%   ------------------ 
%   X           Reference point set matrix NxD;
%   Y           Current postions of GMM centroids;
%   C           (optional) The correspondence vector, such that Y corresponds to X(C,:) 
%
%   See also CPD_REGISTER.

% Copyright (C) 2007 Andriy Myronenko (myron@csee.ogi.edu)
%
%     This file is part of the Coherent Point Drift (CPD) package.
%
%     The source code is provided under the terms of the GNU General Public License as published by
%     the Free Software Foundation version 2 of the License.
% 
%     CPD package is distributed in the hope that it will be useful,
%     but WITHOUT ANY WARRANTY; without even the implied warranty of
%     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%     GNU General Public License for more details.
% 
%     You should have received a copy of the GNU General Public License
%     along with CPD package; if not, write to the Free Software
%     Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA

function [line_handles,text_handles] = cpd_plot_iter(X, Y, C, varargin)

line_handles=[];
text_handles=[];
for i=1:numel(varargin)
    switch i
        case 1, line_handles = varargin{i};
        case 2, text_handles = varargin{i};
        case 3, iter = varargin{i};
    end
end

if nargin<2, error('cpd_plot.m error! Not enough input parameters.'); end;
[m, d]=size(Y);

if d>3, error('cpd_plot.m error! Supported dimension for visualizations are only 2D and 3D.'); end;
if d<2, error('cpd_plot.m error! Supported dimension for visualizations are only 2D and 3D.'); end;

% for 2D case
if d==2,
    if ~isempty(line_handles)
        line_handles(1).XData = X(:,1);
        line_handles(1).YData = X(:,2);
        line_handles(2).XData = Y(:,1);
        line_handles(2).YData = Y(:,2);
        text_handles.String = sprintf('iteration = %04.0f',iter);
    else
       line_handles = plot(X(:,1), X(:,2),'r*',Y(:,1), Y(:,2),'b.');
       ah = gca;
       text_handles = text(ah.XLim(2)*0.95,ah.YLim(1)*0.9,sprintf('iteration = %04.0f',1),...
           'FontSize',14,'HorizontalAlignment','right');
       title('Coherent Point Drift - Projector Registration');
       legend({'imaged points';'projector points'});
       set(ah,'XTick',[],'YTick',[]);
       set(ah,'XColor',[1,1,1],'YColor',[1,1,1],'TickDir','out')
    end
else
% for 3D case
   plot3(X(:,1),X(:,2),X(:,3),'r.',Y(:,1),Y(:,2),Y(:,3),'bo'); % title('X data (red). Y GMM centroids (blue)');set(gca,'CameraPosition',[15 -50 8]);
end

% plot correspondences
if nargin>2 && ~isempty(C)
    hold on;
    if d==2,
        for i=1:m,
            plot([X(C(i),1) Y(i,1)],[X(C(i),2) Y(i,2)]);
        end
    else
        for i=1:m,
            plot3([X(C(i),1) Y(i,1)],[X(C(i),2) Y(i,2)],[X(C(i),3) Y(i,3)]);
        end
    end
    hold off;
end

drawnow;