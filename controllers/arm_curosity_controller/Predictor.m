classdef Predictor < handle
  properties (GetAccess=public)
    id
    weights
    latest_inputs
    alpha=0.00001       %learning rate
    iternum = 15   
    subsetmask_sensor
    subsetmask_motor
    history_sensory = []
  end


  methods

  % ===========  CONSTRUCTOR ===================
  % Mask is for producing different subset
  function obj = Predictor(sensory_size, motor_size, output_sensory_size, range, sensormask, motormask)
     inputsize = sensory_size +  motor_size + 1;
     outputsize = output_sensory_size;
     obj.weights = rand(inputsize, outputsize)*range-0.5;

     % Randomly choose the subset of sensory and motor input
     % choosing the random 2 motors
     rng shuffle;
     randmotormask1 = ceil(rand*7);
     randmotormask2 = ceil(rand*7);
     randsensormask1 = ceil(rand*7);
     randsensormask2 = ceil(rand*7);
     % produce two different masks
     while randmotormask2 == randmotormask1
        randmotormask2 = ceil(rand*7);
     end

     while randsensormask2 == randsensormask1
        randsensormask2 = ceil(rand*7);
     end

     fullmask = dec2bin(0,8);
     fullmask(randmotormask1) = '1';
     fullmask(randmotormask2) = '1';
     motormask = bin2dec(fullmask);

     fullmask = dec2bin(0,8);
     fullmask(randsensormask1) = '1';
     fullmask(randsensormask2) = '1';
     sensormask = bin2dec(fullmask);
     obj.subsetmask_sensor = sensormask;
     obj.subsetmask_motor = motormask;
  end

  %% ============== Method: prediction ======================
  %% Predictor.prediction()
  %% get the predicted sensory state
  %% Input: SENSORS (without bias), MOTORS, the COMPELETE sensory and motor vector
  %% Output: masked predicted sensory states
  %% ==========================================================
  function pred_sensors = prediction(obj, sensors, motors)
      %do the masking
      maskarray = dec2bin(obj.subsetmask_sensor, 8);
      maskarray_motor = dec2bin(obj.subsetmask_motor, 8);
      masksensors = [];
      maskmotors = [];
      for i=1:7
         if maskarray(i) == '1'
            masksensors = [masksensors, sensors(i)];
         end
         if maskarray_motor(i) == '1'
             maskmotors = [maskmotors, motors(i)];
         end
         
      end
      inputs = [1, masksensors, maskmotors];
      pred_sensors = inputs*obj.weights;     
  end

  %% ================= Method: updateWeights ===================
  %% Predictor.updateWeights
  %% update the weights by the errors ( predicted result - true result )
  %% INPUT: ERRORS ( masked error (sensory mask) )
  %% OUTPUT: no output
  %% ===========================================================
  function obj = updateWeights(obj, errors)
      len = length(errors);
      %mask the latest_input
      maskarray_sensor = dec2bin(obj.subsetmask_sensor, 8);
      mask_input = [];
      for i=2:9
             if maskarray_sensor(i-1) == '1'
               mask_input = [mask_input, obj.latest_inputs(i)];
             end
      end


      maskarray_motor = dec2bin(obj.subsetmask_motor, 8);
      maskmotors = [];
      for i=1:8
        if maskarray_motor(i) == '1'
          maskmotors = [maskmotors, obj.latest_inputs(i+7)];
        end
      end

      
      mask_input = [1, mask_input, maskmotors];
      
      for j = 1:obj.iternum
        for i = 1:len
          w = obj.weights(:,i)';
          error = errors(i);
          obj.weights(:,i) = w + obj.alpha*error*mask_input;
        end
      end

    end
 
  %% =========== Predcitor.getError ====================
  %%  retrieve the error array by REAL sensory - last PRED sensory
  %% ===================================================
  function perror = getError(obj, sensory_input, pred_input)
     mask_sensory_input = [];
     maskarray = dec2bin(obj.subsetmask_sensor, 8);
      for i=1:7
         if maskarray(i) == '1'
            mask_sensory_input = [mask_sensory_input, sensory_input(i)];
         end
      end
     perror = mask_sensory_input - pred_input;
  end

  %% ===================================================
  %% some GETTER and SETTERs
  %% ===================================================
  function addhistorySensory(obj, sensory)
     obj.history_sensory = [obj.history_sensory; sensory];
     
  end

  function isensory = gethistorySensory(obj, n)
     isensory = obj.history_sensory(n, :);
  end
  
  function lenS = getLenofHistSensory(obj)
    lenS = size(obj.history_sensory);
    lenS = lenS(1);
           
  end
  
  end
end


