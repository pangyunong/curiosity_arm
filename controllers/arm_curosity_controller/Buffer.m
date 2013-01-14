classdef Buffer < handle


%% **************** Properties ********************
%% |--------------------|--------------------|
%% |   Buffer_content   |   Ready_content    |
%% |--------------------|--------------------|
%% ****************************************
  properties 
    buffer_content
    ready_content
    isUpdated
  end



  methods
    function obj = Buffer()
      obj.buffer_content = [];
      obj.ready_content = [];
      obj.isUpdated = 0;
    end
    
    %% **************** FUNCTION  ********************
    %%  send the content into the buffer, the buffer will 
    %%  update the content immediately
    %% ***********************************************
    function send2Buffer(obj, content)
      obj.ready_content = obj.buffer_content;
      obj.buffer_content = content;
      obj.isUpdated = 1;
    end

    
    %% **************** FUNCTION  ********************
    %%  Retrieve the content from the buffer 
    %%   and keep the content
    %% ***********************************************
    function content = getBufferContent(obj)
      content = obj.ready_content;
      obj.isUpdated = 0;
    end

    %% ***************** Function *******************
    %%  It is an important function to ensure the data
    %%   should be synchronized
    %% **********************************************
    function flag = isOutputReady(obj)
      if (length(obj.ready_content) == 0)
         flag = 0;
      else
          flag = 1;
      end
    end
    

  end
end
