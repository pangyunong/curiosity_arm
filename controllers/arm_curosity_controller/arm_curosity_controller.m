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

%create and initialize Predictor
%pred = Predictor(SENSORY_SIZE, MOTOR_SIZE, SENSORY_SIZE, 1, 255, 255);

% choosing the random 2 motors
rng shuffle;
randmotormask1 = ceil(rand*7);
randmotormask2 = ceil(rand*7);


randsensormask1 = ceil(rand*7);
randsensormask2 = ceil(rand*7);

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


pred = Predictor( 2 , 2 , 2, 1, sensormask, motormask);

predicted_sensories = [];

%Create the actors, init them
actor = Actor(SENSORY_SIZE, MOTOR_SIZE, 0.6, motormask);
motormask
actor.id = 1;

%FOR visualization
plotsteps = 1000;
prediction_errors = zeros(plotsteps,2);

plotweights = zeros(60, plotsteps);

%a counter to record the step
stepnum = 0;

% main loop:
% perform simulation steps of TIME_STEP milliseconds
% and leave the loop when Webots signals the termination
%

% Matlab-related function
% to create the good-looking window
figure;
%set(gcf,'outerposition',get(0,'screensize'));
% create progress bar to monitor
pbar = waitbar(0,'Simulating>>>');


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
     error =  pred.getError(regulated_angles, predicted_sensories);
     pred.updateWeights(error);
     prediction_errors(stepnum, :) = error.^2;
  end
  %************** Motor Selection **********************
  %motion selection from the current input sensory state
  motors = actor.motion_selection(regulated_angles,SENSORY_SIZE ,MOTOR_SIZE);
  motors

  % Execute the motor commands
  motormask = dec2bin(actor.mask, 8);
  
  for i=1:MOTOR_SIZE
    if motormask(i) == '1'
      wb_servo_set_position(servos(1,i),inf);
      wb_servo_set_velocity(servos(1,i),motors(i));
    else
      wb_servo_set_position(servos(1,i),inf);
      wb_servo_set_velocity(servos(1,i),0);

    end
  end
  
  
  % prediction from current sensory state and motor state
  predicted_sensories = pred.prediction(regulated_angles, motors);
  latest_inputs = [1, regulated_angles, motors];
  pred.latest_inputs = latest_inputs;
  
  % if your code plots some graphics, it needs to flushed like this:
  if (stepnum == plotsteps)
    close(pbar);
    smooth_param = 20;
    plotlen = uint16(stepnum/smooth_param); 
    plotarray = zeros(plotlen, 2);
    for i=1:plotlen
      plotarray(i,:) = mean(prediction_errors((i-1)*10+1:i*10,:), 1);
    end
    
    plotarray = sum(plotarray, 2);
    subplot(2,1,1);
    plot((0:plotlen-1)*smooth_param, plotarray);
    xlabel('Step');
    ylabel('Prediction Error');

    %plot the weight change over time
    %% subplot(2,1,2);
    %% plot(1:plotsteps, plotweights);
    %% xlabel('Step');
    %% ylabel('Weight');
    


  
  end
  
  if (stepnum < plotsteps)
    % The progress bar to monitor the status
    showstr = ['running',num2str(stepnum),'/',num2str(plotsteps)];
    waitbar(stepnum/plotsteps, pbar, showstr);
  end
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
