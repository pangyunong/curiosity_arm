classdef Predictor
  properties
    id
    weights
    latest_inputs
    alpha=0.05       %learning rate
    iternum = 15   
  end


  methods
    function pred_sensors=prediction(obj, sensors, motors)
      % add the bias
      sensors = [1, sensors];
      inputs = [sensors, motors];
      pred_sensors = inputs*obj.weights;     
    end


    function updateWeights(obj, errors)
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
