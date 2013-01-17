classdef Predictor < handle
  properties
    ALPHA_FM                    % learning rate
    ALPHA_IM                    % im learning rate
    ITERNUM                     % iteration number

    fm_weights
    im_weights

    encode_weights
    decode_weights

    im_pred_errors
    im_pred_i
    fm_pred_errors              
    fm_pred_i

    ssize                       % Sensory size (e.g. no. of joint angles)
    esize                       % Effect size (e.g. The predicting parameters)
    msize                       % Motor command size (e.g. motor of the joints)
  end


  methods
    function obj = Predictor(ssize, esize, msize);
        %% attributes
        obj.ssize = ssize;      % sensor size
        obj.esize = esize;      % effect size
        obj.msize = msize;      % motor size
        %% weights
        obj.fm_weights = rand(esize, 1+ssize );
        obj.im_weights = rand(ssize, 1+esize );
        %% weights of decoder and encoder
        obj.encode_weights = rand(1+ssize, msize);
        obj.decode_weights = rand(1+mszie, ssize);
        
        
        obj.im_pred_errors = zeros(1000,1);
        obj.im_pred_i = 1;
        obj.fm_pred_errors = zeros(1000,1);
        obj.fm_pred_i = 1;
        
        
    end

    %% ****************************************
    %% Predict using the inverse model
    %%   
    %% ****************************************

    function action = inverse_predict(obj, target_effect, st, yt)
      target_delta_effect = target_effect - yt;
      target_delta_sensor = obj.im_weights * [1;target_delta_effect];
      
      action = obj.decode(target_delta_sensor);
      
    end

    function action = decode(obj, delta_s)
      action = obj.decode_weights * [1; delta_s];
    end

    %% ****************************************
    %% Predict using the forward model
    %%   
    %% ****************************************
    function next_effect = forward_predict(obj, yt, st, action)
       delta_s = obj.encode(action);
       delta_y = obj.fm_weights * [1; delta_s];
       
       next_effect = yt + delta_y;
    end

    function deltas = encode(obj, action)
      deltas = obj.encode_weights * [1;action];
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
      delta_y = yt - yt_1;
      delta_s = st - st_1;
      
      action = obj.inverse_predict(yt, st_1, yt_1);
      error = sum((action - at_1) .^2);
      obj.im_pred_errors(im_pred_i) = error;
      
    %% training start
      for i = 1:ITERNUM
          for 
      end
      
      

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
