classdef Buffer < handle

  properties 
    buffer_content
    isEmpty
  end



  methods
    function obj = Buffer()
      obj.buffer_content = [];
      obj.isEmpty
    end
    
    %% **************** FUNCTION  ********************
    %%  send the content into the buffer, the buffer will 
    %%  update the content immediately
    %% ***********************************************
    function send2Buffer(obj, content)
      obj.buffer_content = content;
    end

    
    %% **************** FUNCTION  ********************
    %%  Retrieve the content from the buffer 
    %%   and keep the content
    %% ***********************************************
    function content = getBufferContent(obj)
      content = obj.buffer_content;
    end

    

  end
end
