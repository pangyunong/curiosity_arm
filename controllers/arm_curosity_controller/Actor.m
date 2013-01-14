classdef Actor < handle
  properties 
    sensory_t
    effect_t
    
    target_effect_t
  end





  methods
  %% ****************************************
  %% CONSTRUCTOR
  %%  Do the init job
  %% ****************************************
    function obj = Actor()
      obj.sensory_t = [];
      obj.effect_t = [];
      obj.target_effect_t = [];
    end


  %% ****************************************
  %% TWO setter, to update s(t), y(t)
  %% ****************************************
    function update_sensory(obj, new_sensory)
      obj.sensory_t = new_sensory;
    end

    function update_effect(obj, new_effect)
       obj.effect_t = new_effect;
    end

    %% ****************************************
    %% According to current
    %%   s(t), y(t), status(t)
    %%   choosing OR approximating
    %%      Next y_next(t)
    %%   (it will be sent to the inverse model
    %%     predicitor)
    %% ****************************************
    function next_effect = get_next_effect(obj)
        next_effect = obj.effect_t * 0.3;
    end
  end

end
