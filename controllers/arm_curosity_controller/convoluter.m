% convoluter is a function do the convolution of IMGMATRIX with specified
% kernel. it returns the convoluted matrix with the same dimension of
% original matrix

function convoluted = convoluter(imgmatrix, kernel)

imgsize = size(imgmatrix);
kernelsize = size(kernel);

% Border condition
% ignore the border

range = (kernelsize(1)-1) /2 ;
for i=1+range:(imgsize(1)-range)
    for j=1+range:(imgsize(2)-range)
        convoluted(i,j,1) = uint8(sum(sum(   double(imgmatrix(i-range:i+range,j-range:j+range,1)).* kernel)));
        convoluted(i,j,2) = uint8(sum(sum(   double(imgmatrix(i-range:i+range,j-range:j+range,2)).* kernel)));
        convoluted(i,j,3) = uint8(sum(sum(   double(imgmatrix(i-range:i+range,j-range:j+range,3)).* kernel)));        
    end
end

