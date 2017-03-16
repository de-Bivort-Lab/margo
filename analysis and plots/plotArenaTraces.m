function out=plotArenaTraces(expmt,varargin)

for i = 1:length(varargin)
    f = varargin{i};
end

ppf = 10;                                   % plots per figure window
nFigs = ceil(expmt.nTracks/10);             % num figures to generate w/ ppf plots per fig


for i = 1:expmt.nTracks
    
    % display plot number since plot generation can be slow
   disp([num2str(i) ' of ' num2str(expmt.nTracks) ' complete'])
   
   % generate a new fig window every ppf plots
   if mod(i-1,ppf)==0
       figure();
       k=0;
   end
   
   % update subplot number
    subP = mod(i-1,5) + 1 + k * ppf;
    hold on
    subplot(5,5,subP);

    
    %Plot fly trace
    if exist('f','var')
        
        xTrace = expmt.Centroid.data(expmt.(f).include(:,i),1,i) - expmt.ROI.corners(i,1);
        yTrace = expmt.Centroid.data(expmt.(f).include(:,i),2,i) - expmt.ROI.corners(i,2);
        mu = -sin(expmt.(f).data(i,expmt.(f).include(:,i)));
        z=zeros(sum(expmt.(f).include(:,i)),1);
        
    else
        
        xTrace = expmt.Centroid.data(expmt.handedness.include(:,i),1,i) - expmt.ROI.corners(i,1);
        yTrace = expmt.Centroid.data(expmt.handedness.include(:,i),2,i) - expmt.ROI.corners(i,2);
        mu = -sin(expmt.handedness.circum_vel(expmt.handedness.include(:,i),i));
        z=zeros(sum(expmt.handedness.include(:,i)),1);
        
    end
    
    if ~isempty(xTrace)
        surface([xTrace';xTrace'],[yTrace';yTrace'],[z';z'],[mu';mu'],...
            'facecol','no','edgecol','interp','linew',0.5);
    end
    
    % scale the axes
    if ~isempty(xTrace)
        axis([0,max(xTrace),0,max(yTrace)]);
    end
    
    clearvars xTrace yTrace mu z
    
    if exist('f','var')
        % Plot angle histogram
        hold on
        subplot(5,5,subP+5);
        h1=plot(expmt.(f).bins, expmt.(f).hist(:,i),'color',[1 0 1]);
        xLabels={'-pi/2';'-pi/4';'0';'pi/4';'pi/2'};
        set(gca,'Xtick',-pi/2:pi/4:pi/2,'XtickLabel',xLabels)
        set(h1,'Linewidth',2)
        legend(['u=' num2str(round(expmt.handedness.mu(i)*100)/100)],'Location','northeast')
        legend('boxoff')
        axis([0,2*pi,0,0.25]);
        
    else
        % Plot angle histogram
        hold on
        subplot(5,5,subP+5);
        h1=plot(expmt.handedness.bins, expmt.handedness.angle_histogram(:,i),'color',[1 0 1]);
        xLabels={'0';'pi/2';'pi';'3pi/2'};
        set(gca,'Xtick',[0:pi/2:3*pi/2],'XtickLabel',xLabels)
        set(h1,'Linewidth',2)
        legend(['u=' num2str(round(expmt.handedness.mu(i)*100)/100)],'Location','northeast')
        legend('boxoff')
        axis([0,2*pi,0,0.25]);
    end

    if subP==5
        k=k+1;
    end 
    
end

end



