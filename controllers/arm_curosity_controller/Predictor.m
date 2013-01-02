classdef Predictor < handle
  properties (GetAccess=public)
    id
    weights
    latest_inputs
    alpha=0.0001       %learning rate
    iternum = 15   
  end


  methods
  %constructor
  function obj = Predictor(sensory_size, motor_size, output_sensory_size, range)
     inputsize = sensory_size +  motor_size + 1;
     outputsize = output_sensory_size;
     obj.weights = rand(inputsize, outputsize)*range-0.5;
  end


    function pred_sensors=prediction(obj, sensors, motors)
      % add the bias
      sensors = [1, sensors];
      inputs = [sensors, motors];
      pred_sensors = inputs*obj.weights;     
    end


    function obj = updateWeights(obj, errors)
      
      len = length(errors);
      for j = 1:obj.iternum
        for i = 1:len
          w = obj.weights(:,i)';
          error = errors(i);
          obj.weights(:,i) = w + obj.alpha*error*obj.latest_inputs;
        end
      end


    end

  end

end
