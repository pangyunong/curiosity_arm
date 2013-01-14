classdef Predictor < handle
  properties
    fm_weights
  end


  methods
    function obj = Predictor(ssize, esize, impredsize, fmpredsize);
        obj.fm_weights = rand(1+ssize+esize, fmpredsize);
    end

    %% ****************************************
    %% Predict using the inverse model
    %%   
    %% ****************************************

    function action = inverse_predict(obj, effect, sensor)
      action =  (rand(7,1) - 0.5)*2;
    end

    %% ****************************************
    %% Predict using the forward model
    %%   
    %% ****************************************
    function effect = forward_predict(obj, effect, sensor, action)
      inputs = [1; sensor; effect];
      effect = inputs'*fm_weights;
    end



    %% ****************************************
    %% Training the Inverse Model and Forward Model
    %%   (if the buffer is avalible and synchronized)
    %% ****************************************

    function train(obj, sensory_buffer, effect_buffer, target_action_buffer,sensory_t , effect_t)

      %% Checking the status of the buffer
      %% To ensure the data is avalible and synchronized
      isReady2Train = 0;
      if (sensory_buffer.isOutputReady() & effect_buffer.isOutputReady() & target_action_buffer.isOutputReady()) == 1
         if (sensory_buffer.isUpdated & effect_buffer.isUpdated & target_action_buffer.isOutputReady) == 1
            isReady2Train = 1;
         end
      end
      
      %% IF the buffer is avalible THEN start training
      if isReady2Train == 1
         st_1 = sensory_buffer.getBufferContent;
         yt_1 = effect_buffer.getBufferContent;
         at_1 = target_action_buffer.getBufferContent;
         st = sensory_t;
         yt = effect_t;
         
         obj.train_im(st_1, yt_1, at_1, st, yt);
         obj.train_fm(st_1, yt_1, at_1, st, yt);
         
      end
      
    end

    %% ****************************************
    %%  Training the Inverse Model
    %% ****************************************
    function train_im(obj, st_1, yt_1, at_1, st, yt)
      st_1
      yt_1
      at_1
      st
      yt
    end


    %% ****************************************
    %%  Training the Forward Model
    %%   Using the old-fashion simple 
    %%    Linear Regression!
    %% ****************************************
    function train_fm(obj, st_1, yt_1, at_1, st, yt)

    end

  end


end
