function gaussianKernel=buildGaussianKernel(xDim,yDim,sigma,kernelWeight)

gaussianKernel=zeros(yDim,xDim);
xcen=xDim/2;
ycen=yDim/2;
sigma=sigma*yDim;
i = repmat(1:xDim,yDim,1);
j = repmat((1:yDim)',1,xDim);
gaussianKernel = (1/(2*pi*sigma^2))*exp(-((i-xcen).^2+(j-ycen).^2)/(2*sigma^2));

%{
for i=1:xDim
    for j=1:yDim
        gaussianKernel(j,i)=(1/(2*pi*sig^2))*exp(-((i-xcen)^2+(j-ycen)^2)/(2*sig^2));
    end
end
%}

% Normalize kernel
gaussianKernel=gaussianKernel./max(max(gaussianKernel));

% Invert kernel
gaussianKernel=1-(gaussianKernel.*kernelWeight);