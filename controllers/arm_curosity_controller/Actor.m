classdef Actor

  properties 
    id
    
  end

  methods
    function motors = motion_selection(obj, sensors, ssize, msize)

	RANDOM_RANGE = 1.1;
	motors = (rand(1,msize) - 0.5)*2*RANDOM_RANGE;
    end
  end
end
