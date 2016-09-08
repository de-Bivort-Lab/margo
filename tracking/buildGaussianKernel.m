function gaussianKernel=buildGaussianKernel(xDim,yDim,sigma,kernelWeight)

gaussianKernel=zeros(yDim,xDim);
xCenter=xDim/2;
yCenter=yDim/2;
sigma=sigma*yDim;

for i=1:xDim
    for j=1:yDim
        gaussianKernel(j,i)=(1/(2*pi*sigma^2))*exp(-((i-xCenter)^2+(j-yCenter)^2)/(2*sigma^2));
    end
end

% Normalize kernel
gaussianKernel=gaussianKernel./max(max(gaussianKernel));

% Invert kernel
gaussianKernel=1-(gaussianKernel.*kernelWeight);
