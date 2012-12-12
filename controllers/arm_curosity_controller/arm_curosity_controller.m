% MATLAB controller for Webots
% File:      arm_curiosity_controller.m
% Date:          
% Description:   A matlab controller to operate the arm
% Author:        Pang Yunong


% uncomment the next two lines if you want to use
% MATLAB's desktop to interact with the controller:
%desktop;
%keyboard;


%Initialization Process
TIME_STEP = 128;
SENSORY_SIZE = 7;
MOTOR_SIZE = 7;

% get and enable devices, e.g.:
base = wb_robot_get_device('base');
upperarm = wb_robot_get_device('upperarm');
forearm = wb_robot_get_device('forearm');
wrist = wb_robot_get_device('wrist');
rotationalwrist = wb_robot_get_device('rotationalwrist');
rightgripper = wb_robot_get_device('right_gripper');
leftgripper =  wb_robot_get_device('left_gripper');

camera =  wb_robot_get_device('camera');

servos = [base, upperarm, forearm, wrist, rotationalwrist, rightgripper, leftgripper];
for i=1:length(servos)
  wb_servo_enable_position(servos(1,i), TIME_STEP);
end

wb_camera_enable(camera,TIME_STEP);


motors = zeros(1, MOTOR_SIZE);

%create Predictor
pred = Predictor;
pred.id = 1;
pred.weights = rand(1+SENSORY_SIZE+MOTOR_SIZE, SENSORY_SIZE)-0.5;

predicted_sensories = [];

%Create the actors, init them
actor = Actor;
actor.id = 1;

%FOR visualization
plotsteps = 16000;
prediction_errors = zeros(plotsteps,SENSORY_SIZE);

plotweights = zeros(3, plotsteps);

%a counter to record the step
stepnum = 0;

% main loop:
% perform simulation steps of TIME_STEP milliseconds
% and leave the loop when Webots signals the termination
%
while wb_robot_step(TIME_STEP) ~= -1
  stepnum = stepnum + 1;
  %Obtain sensory input here 
  %s(t)
  
  %****** CAUTION!************
  % No joint sensor in the robot
  % simulate the joint sensor by the webot function
  %******* END ***************
  base_angle =  wb_servo_get_position(servos(1,1));
  upperarm_angle = wb_servo_get_position(servos(1,2));
  forearm_angle = wb_servo_get_position(servos(1,3));
  wrist_angle = wb_servo_get_position(servos(1,4));
  rotationalwrist_angle = wb_servo_get_position(servos(1,5));
  rightgripper_angle = wb_servo_get_position(servos(1,6));
  leftgripper_angle = wb_servo_get_position(servos(1,7));

  image = wb_camera_get_image(camera);
  

  % regulate the angle into range [0,2*pi]
  angles =  [base_angle, upperarm_angle, forearm_angle,...
             wrist_angle, rotationalwrist_angle,...
              rightgripper_angle, leftgripper_angle];
  regulated_angles = mod(angles, 2*pi);
  
  % when the real future state comes, get the prediction error
  if (length(predicted_sensories) ~= 0 && stepnum <= plotsteps)
     error = regulated_angles - predicted_sensories;
     plotweights(:,stepnum) = pred.weights(2:4,2);
     pred.updateWeights(error);
     prediction_errors(stepnum, :) = error.^2;
  end
  %************** Motor Selection **********************
  %motion selection from the current input sensory state
  motors = actor.motion_selection(regulated_angles,SENSORY_SIZE ,MOTOR_SIZE);
  


  for i=1:MOTOR_SIZE
    wb_servo_set_position(servos(1,i),inf);
    wb_servo_set_velocity(servos(1,i),motors(i));
  end
  
  
  % prediction from current sensory state and motor state
  predicted_sensories = pred.prediction(regulated_angles, motors);
  latest_inputs = [1, regulated_angles, motors];
  pred.latest_inputs = latest_inputs;
  
  % if your code plots some graphics, it needs to flushed like this:
  if (stepnum == plotsteps)
    smooth_param = 20;
    plotlen = uint16(stepnum/smooth_param); 
    plotarray = zeros(plotlen, SENSORY_SIZE);
    for i=1:plotlen
      plotarray(i,:) = mean(prediction_errors((i-1)*10+1:i*10,:), 1);
    end
    
    plotarray = sum(plotarray, 2);
    figure(1);
    plot((0:plotlen-1)*smooth_param, plotarray);
    xlabel('Step');
    ylabel('Prediction Error');
    print('-dpng', 'prediction_errors');

    %plot the weight change over time
    save plotweights;

  end
  stepnum
  %*********For show image of the camera*****
  %  figure(1);
  % imshow(image);

  %******** For edge detection **************
  %  edge_img = edge_detection(image);
  %  figure(2);
  % imshow(edge_img);
  drawnow;
end

% cleanup code goes here: write data to files, etc.
