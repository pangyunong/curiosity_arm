classdef Predictor < handle
  properties
    ALPHA_DECODE                % learning rate
    ALPHA_IM                    % im learning rate
    ALPHA_FM                    % FM rate
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
    ID                          % ID of this predictor

    status 
    
    
  end


  methods
    function obj = Predictor(ssize, esize, msize, ID, lwprs);
        %% attributes
        obj.ssize = ssize;      % sensor size
        obj.esize = esize;      % effect size
        obj.msize = msize;      % motor size
        obj.ID    = ID;
        obj.status = 0;         % 0 is training ,no output prediction


        %% weights
        rng shuffle;
        obj.fm_weights = (rand(esize, 1+ssize*2)  - 0.5)*2*0.3;
        obj.im_weights = (rand(ssize, 1+esize*2 ) - 0.5)*2*0.3;
        %% weights of decoder and encoder
        obj.encode_weights = rand();
        obj.decode_weights = rand();
        
        %% for monitor the error
        obj.PLOT_LENGTH = 8500;
        obj.im_pred_errors = zeros(obj.PLOT_LENGTH,1);
        obj.im_pred_i = 1;
        obj.fm_pred_errors = zeros(obj.PLOT_LENGTH,1);
        obj.fm_pred_i = 1;
        
        obj.ALPHA_DECODE = 0.05;
        obj.ALPHA_IM = 0.08;
        obj.ALPHA_FM = 0.03;

        %% ****************************************
        %% initialize the LWPR module
        %% ****************************************
        %%  INIT the Forward module
        global lwprs;
        lwpr('Init',obj.ID*2-1, obj.ssize, obj.esize,1,0,0,1e-7,50,ones(obj.ssize,1),[1],'lwpr_fm');

        kernel = 'Gaussian';

        lwpr('Change',ID*2-1,'init_D',eye(obj.ssize)*25); 
        lwpr('Change',ID*2-1,'init_alpha',ones(obj.ssize)*450);     % this is a safe learning rate
        lwpr('Change',ID*2-1,'w_gen',0.2);                  % more overlap gives smoother surfaces
        lwpr('Change',ID*2-1,'meta',1);                     % meta learning can be faster, but numerical more dangerous
        lwpr('Change',ID*2-1,'meta_rate',250);

        %%  INIT the Reverse Module
        lwpr('Init',obj.ID*2, obj.ssize+obj.esize, obj.ssize,1,0,0,1e-7,50,ones(obj.ssize+obj.esize,1),[1],'lwpr_im');

        kernel = 'Gaussian';

        lwpr('Change',ID*2,'init_D',eye(obj.ssize+obj.esize)*25); 
        lwpr('Change',ID*2,'init_alpha',ones(obj.ssize+obj.esize)*20);     % this is a safe learning rate
        lwpr('Change',ID*2,'w_gen',0.2);                  % more overlap gives smoother surfaces
        lwpr('Change',ID*2,'meta',1);                     % meta learning can be faster, but numerical more dangerous
        lwpr('Change',ID*2,'meta_rate',250);

        

        
    end

    %% ****************************************
    %% Predict using the inverse model
    %%   INPUT: The original y(t)s(t), NOT delta ONE
    %%   OUTPUT: The action a(t)
    %% ****************************************

    function [action, delta_sensor] = inverse_predict(obj, target_effect, st, yt)
      target_delta_effect = target_effect - yt;
      global lwprs;
      predict_input = [target_delta_effect; st];

      [yp,w]=lwpr('Predict',obj.ID*2,predict_input,0.001);
      predict_target_sensor = yp;
      
      %% delete the bias item
      delta_sensor = yp;
      action = obj.decode(delta_sensor);
      
    end

    %% Decode module
    %%   in this example,
    %%    We use only the very simple linear relation
    %%   M(t) = a * Delta_s;
    function action = decode(obj, delta_s)
      action = obj.decode_weights * delta_s;
    end

    %% ****************************************
    %% Predict using the forward model
    %%   INPUT: The current y(t) and s(t), and a(t)
    %%   OUTPUT: The y_next
    %% ****************************************
    function [next_effect, pred_delta_y] = forward_predict(obj, yt, st, action)
       delta_s = obj.encode(action);
       global lwprs;
       
       [yp,w]=lwpr('Predict',obj.ID*2-1,st,0.001);
       delta_y = yp - yt;
       pred_delta_y = delta_y; % delete the bia item
       next_effect = yt + pred_delta_y;
    end

    function deltas = encode(obj, action)
      deltas = obj.encode_weights * action;
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
         obj.train_fm(st_1, yt_1, at_1, st, yt);

         %% Draw the diagram to show the error change
         if obj.fm_pred_i == obj.PLOT_LENGTH
           h = figure(2);
           subplot(2,1,1);
           plot (1:obj.PLOT_LENGTH, obj.fm_pred_errors);
           subplot(2,1,2);
           plot( 1:obj.PLOT_LENGTH, obj.im_pred_errors);
           saveas(h,'prediction_error.fig');
         end
         
      end
      
    end

    %% ****************************************
    %%  Training the Inverse Model
    %%    
    %% ****************************************
    function train_im(obj, st_1, yt_1, at_1, st, yt)
      delta_y = yt - yt_1;
      delta_s = st - st_1;
      
      if(obj.status == 1)

          [action, pred_delta_s] = obj.inverse_predict(yt, st_1, yt_1);

          delta_s_errors = pred_delta_s - delta_s;
          %% Obtain the decode error here
          pred_action = obj.decode(delta_s);


          im_error = sum((action - at_1) .^2)/7;
          %     im_error                  % monitor error 
          obj.im_pred_errors(obj.im_pred_i) = im_error;
          obj.im_pred_i = obj.im_pred_i + 1;

      end

    %% training start
      %% linear regression (online version)
      %%  Training IM model
      global lwprs;
      train_input = [delta_y; st_1];
      train_result = delta_s;
      for i = 1:3
          [yp,w] = lwpr('Update',obj.ID*2,train_input,train_result);
      end
      %% Training Decode model
      obj.decode_weights = at_1(1)/delta_s(1); 
      

      %% USE the pseudo-inverse to get the FM-related weights
      obj.encode_weights = 1/obj.decode_weights;
      
    end


    %% ****************************************
    %%  Training the Forward Model (NOT USED, as the pinv())
    %%   Using the old-fashion simple 
    %%    Linear Regression!
    %% ****************************************
    function train_fm(obj, st_1, yt_1, at_1, st, yt)
      delta_y = yt - yt_1;
      delta_s = st - st_1;
      
      if(obj.status == 1)
        [next_y, pred_delta_y] = obj.forward_predict(yt_1 , st_1, at_1);
        delta_y_errors = pred_delta_y - delta_y;

        fm_error = sum((next_y - yt).^ 2)/obj.esize;

        obj.fm_pred_errors(obj.fm_pred_i) = fm_error;
        obj.fm_pred_i = obj.fm_pred_i +1;

      end

      %% training
      global lwprs;
      train_input = st_1;
      train_result= yt_1;
      for i = 1:2
         [yp,w] = lwpr('Update',obj.ID*2-1,train_input,train_result);
      end
      train_input = st;
      train_result = yt;
      for i = 1:2
         [yp,w] = lwpr('Update',obj.ID*2-1,train_input,train_result);
      end
    end

  end


end
