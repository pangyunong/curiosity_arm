function edgeimg = edge_detection(img)
kernelA = [1,2,1;2,4,2;1,2,1];
kernelA = kernelA / sum(sum(kernelA));

kernelB = [0,1,0;1,-4,1; 0,1,0];

edgeimg = convoluter(img, kernelB);
edgeimg = convoluter(edgeimg, kernelA);

end
