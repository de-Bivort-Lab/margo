function out=processCentroid(data,numFlies,ROI_coords)

    out=[];

for j=1:numFlies
    inx=data(:,2*j)-ROI_coords(j,1);
    iny=data(:,2*j+1)-ROI_coords(j,2);
    width=mean([ROI_coords(j,3)-ROI_coords(j,1) ROI_coords(j,4)-ROI_coords(j,2)],2);
    
    out(j).r=sqrt((inx-width/2).^2+(iny-width/2).^2);
    out(j).theta=atan2(iny-width/2,inx-width/2);
    out(j).direction=zeros(size(inx,1),1);
    out(j).turning=zeros(size(inx,1),1);
    out(j).speed=zeros(size(inx,1),1);
    out(j).width=width;
    out(j).direction(2:end)=atan2(diff(iny),diff(inx));
    out(j).turning(2:end) = diff(out(j).direction);
    out(j).speed(2:end)=sqrt(diff(iny).^2+diff(iny).^2);
    out(j).speed(out(j).speed>12)=NaN;
end

