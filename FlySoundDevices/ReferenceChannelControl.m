
classdef ReferenceChannelControl < Device
    
    properties (Constant)
    end
    
    properties (Hidden, SetAccess = protected)
    end
    
    properties 
        deviceName = 'ReferenceChannelControl';
    end
    
    properties (SetAccess = protected)
    end
    
    events
    end
    
    methods
        function obj = ReferenceChannelControl(varargin)
            obj.outputLabels = {'refchan'};
            obj.outputUnits = {'V'};
            obj.outputPorts = [1];
            
        end
        
        function in = transformInputs(obj,in,varargin)
            %multiply Inputs by micron/volts
        end
        
        function out = transformOutputs(obj,out,varargin)
            % Encode the trial number on this channel
            if nargin>1
               rig = varargin{1}; 
               n = rig.params.trialnum;
               ds = 10;
               d = 1;
               rc = out.refchan;
               while n>0
                   r = rem(n,10);
                   rc(ds*2*d+1:ds*2*d+ds) = rc(ds*2*d+1:ds*2*d+ds) - 0.1;
                   rc(ds*2*d+ds+1:ds*2*d+2*ds) = rc(ds*2*d+ds+1:ds*2*d+2*ds) + r*.1;
                   n = floor(n/10);
                   d = d+1;
               end
               rc(ds*2*d+1:ds*2*d+ds) = rc(ds*2*d+1:ds*2*d+ds) - 0.1;
               out.refchan = rc;
            end
        end
        
    end
    
    methods (Access = protected)
        function setupDevice(obj)
        end
                
        function defineParameters(obj)
            obj.params.refchanval = 0;
        end
    end
end
