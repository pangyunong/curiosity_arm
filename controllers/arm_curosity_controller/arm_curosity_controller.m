% MATLAB controller for Webots
% File:      arm_curiosity_controller.m
% Date:          
% Description:   A matlab controller to operate the arm
% Author:        Pang Yunong


% uncomment the next two lines if you want to use
% MATLAB's desktop to interact with the controller:
%desktop;
%keyboard;

TIME_STEP = 32;

% get and enable devices, e.g.:
base = wb_robot_get_device('base');
upperarm = wb_robot_get_device('upperarm');
forearm = wb_robot_get_device('forearm');
wrist = wb_robot_get_device('wrist');
rotationalwrist = wb_robot_get_device('rotationalwrist');
rightgripper = wb_robot_get_device('right_gripper');
leftgripper =  wb_robot_get_device('left_gripper');

servos = [base, upperarm, forearm, wrist, rotationalwrist, rightgripper, leftgripper];
for i=1:length(servos)
  wb_servo_enable_position(servos(1,i), TIME_STEP);
end

disp('Initializing');

% main loop:
% perform simulation steps of TIME_STEP milliseconds
% and leave the loop when Webots signals the termination
%
while wb_robot_step(TIME_STEP) ~= -1
  
  %Obtain sensory input here 
  %s(t)
  

  wb_servo_set_position(servos(1,2),inf);
  wb_servo_set_velocity(servos(1,2),-1);


  
  % if your code plots some graphics, it needs to flushed like this:
  drawnow;

end

% cleanup code goes here: write data to files, etc.
