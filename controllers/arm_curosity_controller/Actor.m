%% Actor is a policy producer
%% it maps the specified sensory state to the action
%% action = Actor(Sensory) 



classdef Actor < handle

  properties 
    id
    ssize
    msize
    weights
    mask
  end

  methods
    function obj = Actor(sensory_size, motor_size, range, mask)
       obj.ssize = sensory_size;
       obj.msize = motor_size;
       rng shuffle;
       obj.weights = rand(sensory_size+1, motor_size)*range-0.5*range;
       obj.mask = mask;
    end
    function motors = motion_selection(obj, sensors, ssize, msize)
      obj.ssize = ssize;
      obj.msize = msize;
	  RANDOM_RANGE = 1.1;
    
      sensors = [1, sensors];
      motors = sensors*obj.weights;
    end
  end
end
