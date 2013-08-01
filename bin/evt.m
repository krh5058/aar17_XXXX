classdef evt < event.EventData
    properties
        RT
        dur
        code
    end
    
  methods
    function this = evt(data)
      try
          f = fieldnames(data);
          for i = 1:length(f)
              this.(f{i}) = data.(f{i});
          end
      catch ME
          throw(ME);
      end
    end
  end
    
end

