function array = smooth_result( array, width )

    len = length(array);
    bins = ceil(len/width);
    
    for i=1:bins
        start = (i-1)*width +1;
        endx  = (i)*width;
        if endx > len
            endx = len;
        end
        temp = mean(array(start:endx));
        for j = start:endx          
           array(j) = temp;
        end
    end 

end

