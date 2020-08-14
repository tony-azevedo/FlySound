classdef Position_Arduino < Device
    
    properties (Constant)
    end
    
    properties (Hidden, SetAccess = protected)
    end
    
    properties 
        deviceName = 'Position_Arduino';
    end
    
    properties (SetAccess = protected)
    end
    
    events
        Abort
        ControlFlag
    end
    
    methods
        function obj = Position_Arduino(varargin)
            obj.digitalInputLabels = {'b_0','b_2','b_4','b_8','b_16','b_32','b_64','b_128','b_256','b_512','b_1024','b_sign'};
            obj.digitalInputUnits = {'Bit','Bit','Bit','Bit','Bit','Bit','Bit','Bit','Bit','Bit','Bit','Bit'};
            obj.digitalInputPorts = (8:19);
        end
        
        function in = transformInputs(obj,in,varargin)
            % 
            if nargin > 2
                typeswitch = varargin{1};
            else
                typeswitch = 'scaled';
            end
            in.probe_position = zeros(size(in.b_0),'double');
            in.probe_position =...
                in.b_0 + ...
                2^1 * in.b_2 + ...
                2^2 * in.b_4 + ...
                2^3 * in.b_8 + ...
                2^4 * in.b_16 + ...
                2^5 * in.b_32 + ...
                2^6 * in.b_64 + ...
                2^7 * in.b_128 + ...
                2^8 * in.b_256 + ...
                2^9 * in.b_512 + ...
                2^10 * in.b_1024;
            in.probe_position = in.probe_position .* (in.b_sign*2 - 1);
            switch typeswitch
                case 'scaled'
                    in.probe_position = (in.probe_position + obj.params.offset)* obj.params.gain;
                case 'int12'
                    in.probe_position = in.probe_position + obj.params.offset;
            end            
            keys = fieldnames(in);
            in = rmfield(in, keys(startsWith(keys,'b')));
            
        end
        
        function out = transformOutputs(obj,out,varargin)
            %multiply outputs by volts/micron
        end
        
        function setParams(obj,varargin)
            setParams@Device(obj,varargin{:})
            % notify(obj,'ControlFlag')
        end

        function abort(obj,varargin)
            % notify(obj,'Abort')
        end

        
    end
    
    methods (Access = protected)
        function setupDevice(obj)
        end
                
        function defineParameters(obj)
            obj.params.gain = 1280/4096; % this assumes a window width of 1280, should actually poll a 
            obj.params.offset = 4096/2; % this assumes a window width of 1280, should actually poll a 
        end
    end
end
