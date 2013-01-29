% MATLAB controller for Webots
% File:      arm_curiosity_controller.m
% Date:          Everyday
% Description:   A matlab controller to operate the arm
% Author:        Pang Yunong


% uncomment the next two lines if you want to use
% MATLAB's desktop to interact with the controller:
%desktop;
%keyboard;

%% ****************************************
% Constant Definition
%% ****************************************
TIME_STEP = 128;
MAX_MOTOR_NUM = 7;
MAX_SENSOR_NUM = 7;
JOINT_RANGE = [-3.14, 3.14; -2.3562, 2.3562; -2, 2; -2,2; -2.5, 2.5; 0, 1.2771; -1.2771, 0];
SERVO_SPEED_RANGE = [2.20894; 1.1908; 1.38927; 2.20894; 2.20894; 2.20894; 2.20894];

RANDOM_PERIOD = 150;
START_TO_PREDICT = 50;

%% ****************************************
%% Variable Definition
%% ****************************************

global lwprs;                   % LWPR model. learning the non-linear function
                                %  it is shared by every actor and predictor
sensory_buffer = Buffer;
effect_buffer  = Buffer;
target_action_buffer = Buffer;

actor = Actor;
predictor = Predictor(7, 2, 7, 1, lwprs); % predictor here

% *********************************************
% get the reference and enable devices, e.g.:
%% ********************************************
base = wb_robot_get_device('base');
upperarm = wb_robot_get_device('upperarm');
forearm = wb_robot_get_device('forearm');
wrist = wb_robot_get_device('wrist');
rotationalwrist = wb_robot_get_device('rotationalwrist');
rightgripper = wb_robot_get_device('right_gripper');
leftgripper =  wb_robot_get_device('left_gripper');

camera =  wb_robot_get_device('camera');

servos = [base, upperarm, forearm, wrist, rotationalwrist, rightgripper, leftgripper];

% Enable the devices
for i=1:length(servos)
  wb_servo_enable_position(servos(1,i), TIME_STEP);
end
wb_camera_enable(camera,TIME_STEP);




%% ****************************************
%% Initialize GLOBAL status of ROBOT
%%  STATUS : 0 -> init( random move, learning)
%%           1 -> generate targe (learning)
%% ****************************************
status = 0;
robot_step = 0;

figwin = figure('Visible', 'off');





% main loop:
% perform simulation steps of TIME_STEP milliseconds
% and leave the loop when Webots signals the termination
%


while wb_robot_step(TIME_STEP) ~= -1

  %% ***************************************
  %   ROBOT status
  %  ***************************************
 

  %% ***************************************
  %  Obtain sensory input here 
  %  S(t)
  %% ***************************************
  base_angle =  wb_servo_get_position(servos(1,1));
  upperarm_angle = wb_servo_get_position(servos(1,2));
  forearm_angle = wb_servo_get_position(servos(1,3));
  wrist_angle = wb_servo_get_position(servos(1,4));
  rotationalwrist_angle = wb_servo_get_position(servos(1,5));
  rightgripper_angle = wb_servo_get_position(servos(1,6));
  leftgripper_angle = wb_servo_get_position(servos(1,7));

  %% Simple Image processing
  image = wb_camera_get_image(camera); 
  gimg = image(:,:,2) - image(:,:,1) - image(:,:,3);
  bwimg = im2bw(gimg, 0.05);
  labels = bwlabel(bwimg, 8);
  
  blobMeasurements = regionprops(labels, 'all');
  top_x = blobMeasurements(1).Centroid(1);
  top_y = blobMeasurements(1).Centroid(2);
  %% location of hand 
  hand_loc = [top_x; top_y];
  norm_hand_loc = hand_loc/256;
  

  %% ****************************************
  %% Data normalization & regularation 
  %% ****************************************
  angles =  [base_angle;  upperarm_angle; forearm_angle;...
             wrist_angle; rotationalwrist_angle;...
              rightgripper_angle; leftgripper_angle];

  %normalize the angle by the range
  norm_angles = (angles - JOINT_RANGE(:,1) ) ./ (JOINT_RANGE(:,2) - JOINT_RANGE(:,1));
    
  
  %% ****************************************
  %% Sending to Buffer (1 period delay)
  %%   (it will update the buffer to be 
  %%     latest!)
  %% ****************************************
  sensory_buffer.send2Buffer(norm_angles);
  effect_buffer.send2Buffer(norm_hand_loc);
  
  



  %% ****************************************
  %% Sending to the Actor
  %% ****************************************
  actor.update_sensory(norm_angles);
  actor.update_effect(norm_hand_loc);


  %% Preparation -> random move 
  if (status == 0)
      action_command = (rand(MAX_MOTOR_NUM, 1)-0.5)*1;
      robot_step = robot_step + 1;
      indicate_str = ['Random exploration step no: ',num2str(robot_step)];
      disp(indicate_str);
      if (robot_step == RANDOM_PERIOD)
         status = 1;
      end
      if (robot_step == START_TO_PREDICT)
         predictor.status = 1;
      end
      target_action_buffer.send2Buffer(action_command);
      

  %% Finish preparation, produce target
  %%   (the place containing largest competence)
  elseif (status == 1)
      %% Matlab drawing operation
      set(figwin, 'Visible', 'on');
      axis([0,1,0,1]);
      axis manual;
      set(gca,'YDir','reverse');
      hold on;

      plot(norm_hand_loc(1),norm_hand_loc(2), '.r');

      target_effect = actor.get_next_effect();

      plot(target_effect(1), target_effect(2), '.b');
      legend('Y', 'target Y');

      %% ****************************************
      %% Use the Inverse Model in Predictor
      %%   to predict the action command
      %% ****************************************
      action_command = predictor.inverse_predict(target_effect, norm_angles, norm_hand_loc);

      %%  sending the action command to buffer
      target_action_buffer.send2Buffer(action_command);
  end

  %% ****************************************
  %% All data for training is ready
  %%  training here
  %% ****************************************
  predictor.train(sensory_buffer, effect_buffer, target_action_buffer, norm_angles, norm_hand_loc);  % training






  %% ****************************************
  %  MOTOR EXECUTION
  %%   (Information about motor)
  %%   Restrict the servo movement range here
  %%  ------------------------------
  %%   Servo_1 base: [-pi, pi]
  %%   Servo_2 upperarm: [-2.3562, 2.3562]
  %%   Servo_3 forearm: [-2, 2]
  %%   Servo_4 wrist: [-2, 2]
  %%   Servo_5 rotational wrist:[-2.5,2.5] 
  %%   Servo_6 right gripper: [0, 1.2771]
  %%   Servo_7 left gripper: [-1.2771, 0]
  %%  
  %%   MAX velocity of each servo
  %%  ------------------------------
  %%   Servo_1 base: 2.20894
  %%   Servo_2 upperarm: 1.1908
  %%   Servo_3 forearm: 1.38927
  %%   Servo_4 wrist: 2.20894
  %%   Servo_5 ratational wrist: 2.20894
  %%   Servo_6 right gripper: 2.20894
  %%   Servo_7 left gripper: 2.20894
  %% ****************************************
  norm_motor_command_array = action_command;
  %% Denormalize the motor command into the real servo speed
  motor_command_array = norm_motor_command_array.*SERVO_SPEED_RANGE;

  for motor_index = 1:MAX_MOTOR_NUM
    if (motor_command_array(motor_index) >= 0)
      wb_servo_set_position(servos(1,motor_index),JOINT_RANGE(motor_index, 2));
    else
      wb_servo_set_position(servos(1,motor_index),JOINT_RANGE(motor_index, 1));
    end
      wb_servo_set_velocity(servos(1,motor_index),abs(motor_command_array(motor_index)));
  end



  %% MATLAB Graphics control statement
  drawnow;
end

% cleanup code goes here: write data to files, etc.
