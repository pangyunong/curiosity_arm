classdef Predictor < handle
  properties
    ALPHA_DECODE                % learning rate
    ALPHA_IM                    % im learning rate
    PLOT_LENGTH                 % plot length
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
        rng shuffle;
        obj.fm_weights = (rand(1+esize, 1+ssize ) - 0.5)*2*0.3;
        rng shuffle;
        obj.im_weights = (rand(1+ssize, 1+esize ) - 0.5)*2*0.3;
        %% weights of decoder and encoder
        rng shuffle;
        rng shuffle;
        obj.encode_weights = (rand(1+ssize, 1+msize) - 0.5)*2*0.3;
        obj.decode_weights = (rand(1+msize, 1+ssize) - 0.5)*2*0.3;
        
        %% for monitor the error
        obj.PLOT_LENGTH = 100;
        obj.im_pred_errors = zeros(obj.PLOT_LENGTH,1);
        obj.im_pred_i = 1;
        obj.fm_pred_errors = zeros(obj.PLOT_LENGTH,1);
        obj.fm_pred_i = 1;
        
        obj.ALPHA_DECODE = 0.05;
        obj.ALPHA_IM = 0.08;
    end

    %% ****************************************
    %% Predict using the inverse model
    %%   INPUT: The original y(t)s(t), NOT delta ONE
    %%   OUTPUT: The action a(t)
    %% ****************************************

    function [action, delta_sensor] = inverse_predict(obj, target_effect, st, yt)
      target_delta_effect = target_effect - yt;
      target_delta_sensor = obj.im_weights * [1;target_delta_effect];
      %% delete the bias item
      delta_sensor = target_delta_sensor(2:obj.ssize+1);
      action = obj.decode(delta_sensor);
      
    end

    function action = decode(obj, delta_s)
      action = obj.decode_weights * [1; delta_s];
      action = action(2:obj.msize+1); % delete the bia item
    end

    %% ****************************************
    %% Predict using the forward model
    %%   INPUT: The current y(t) and s(t), and a(t)
    %%   OUTPUT: The y_next
    %% ****************************************
    function [next_effect, pred_delta_y] = forward_predict(obj, yt, st, action)
       delta_s = obj.encode(action);
       delta_y = obj.fm_weights * [1;delta_s];
       pred_delta_y = delta_y(2:obj.esize+1); % delete the bia item
       next_effect = yt + pred_delta_y;
    end

    function deltas = encode(obj, action)
      deltas = obj.encode_weights * [1;action];
      deltas = deltas(2:obj.ssize+1);
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
         
         %%  train IM , by its way, train FM
         obj.train_im(st_1, yt_1, at_1, st, yt);
  
         
      end
      
    end

    %% ****************************************
    %%  Training the Inverse Model
    %%    By its way, it use pseudo-inverse to 
    %%     get the FM-related weights!
    %% ****************************************
    function train_im(obj, st_1, yt_1, at_1, st, yt)
      delta_y = yt - yt_1;
      delta_s = st - st_1;
      
      [action, pred_delta_s] = obj.inverse_predict(yt, st_1, yt_1);
      [next_y, pred_delta_y] = obj.forward_predict(yt_1, st_1, at_1);
      
      delta_s_errors = pred_delta_s - delta_s;
      %% Obtain the decode error here
      pred_action = obj.decode(delta_s);
      pred_action
      at_1
      decode_errors = pred_action - at_1;

      im_error = sum((action - at_1) .^2);
      %     im_error                  % monitor error 
      obj.im_pred_errors(obj.im_pred_i) = im_error;
      obj.im_pred_i = obj.im_pred_i + 1;

      fm_error = sum((next_y - yt).^2);
%      fm_error                  % monitor error
      obj.fm_pred_errors(obj.fm_pred_i) = fm_error;
      obj.fm_pred_i = obj.fm_pred_i + 1;
      
      %% Draw the diagram to show the error change
      if obj.fm_pred_i == obj.PLOT_LENGTH
         figure(2);
         plot( 1:obj.PLOT_LENGTH, obj.im_pred_errors,1:obj.PLOT_LENGTH, obj.fm_pred_errors);
         legend('IM error', 'FM error');
      end
    %% training start
      %% linear regression (online version)
      %%  Training IM model
      obj.im_weights = obj.im_weights - obj.ALPHA_IM * [1;delta_s_errors] * [1;delta_y]';

      %% Training Decode model
      obj.decode_weights = obj.decode_weights - obj.ALPHA_DECODE *[1;decode_errors] * [1;delta_s]'; 
      

      %% USE the pseudo-inverse to get the FM-related weights
      obj.fm_weights = pinv(obj.im_weights);
      obj.encode_weights = pinv(obj.decode_weights);
      
    end


    %% %% ****************************************
    %% %%  Training the Forward Model (NOT USED, as the pinv())
    %% %%   Using the old-fashion simple 
    %% %%    Linear Regression!
    %% %% ****************************************
    %% function train_fm(obj, st_1, yt_1, at_1, st, yt)
    %%   delta_y = yt - yt_1;
    %%   delta_s = st - st_1;
      
    %%   [next_y, pred_delta_y] = obj.forward_predict(yt_1 , st_1, at_1);
    %%   delta_y_errors = pred_delta_y - delta_y;
      
    %% %% we have the errors, now train it
    %%   obj.
    %% end

  end


end
