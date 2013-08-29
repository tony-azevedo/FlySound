classdef RigChangeData < event.EventData
    
    properties
        rigName;
    end
    methods
        function obj = RigChangeData(rigstr)
            obj.rigName = rigstr;
        end
    end
end
