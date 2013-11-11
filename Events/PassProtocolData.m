classdef PassProtocolData < event.EventData
    properties (Constant)
    end
    
    properties
        protocol
    end
    methods
        function obj = PassProtocolData(protin)
            if ~isa(protin,'FlySoundProtocol')
                error('Trying to pass something other than a protocol');
            end
            obj.protocol = protin;
        end
    end
end
