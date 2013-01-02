%% Actor is a policy producer
%% it maps the specified sensory state to the action
%% action = Actor(Sensory) 



classdef Actor < handle

  properties 
    id
    ssize
    msize
    
  end

  methods
    function motors = motion_selection(obj, sensors, ssize, msize)
    obj.ssize = ssize;
    obj.msize = msize;
	RANDOM_RANGE = 1.1;
	motors = (rand(1,msize) - 0.5)*2*RANDOM_RANGE;
    end
  end
end
