classdef PiezoRig < handle
    
    properties (Constant, Abstract)
        rigName;
    end
    
    properties (Hidden, SetAccess = protected)
        deviceParameters
    end
    
    properties (SetAccess = protected)
        aiSession
        aoSession
        recgain        % amp gain
        recmode        % amp mode
    end
    
    events
        %InsufficientFunds, notify(BA,'InsufficientFunds')
    end
    
    methods
        function obj = PiezoRig(varargin)
            
        end
    end
    
    methods (Access = protected)
        
        
        function createDeviceParameters(obj)
            dbp.recgain = readGain();
            dbp.recmode = readMode();
            dbp.filter = 1e4;
            dbp.headstagegain = 1;
            
            dbp.daqCurrentOffset = 0.0000; % 0.006; %nA There is some current offset when Vdaq = 0
            % to get this number, run  the zeroDAQOut routine and mess with
            % ext_offset
            
            % Current Injection = DAQ_voltage*m+b
            % DAQ_out_voltage = (nA-b)/m;  % to get these numbers, run the
            % currentInputCalibration routine
            dbp.daqout_to_current = 2/dbp.headstagegain; % m, multiply DAQ voltage to get nA injected
            dbp.daqout_to_current_offset = 0;  % b, add to DAQ voltage to get the right offset
            
            dbp.daqout_to_voltage = .02; % m, multiply DAQ voltage to get mV injected (combines voltage divider and input factor) ie 1 V should give 2mV
            dbp.daqout_to_voltage_offset = 0;  % b, add to DAQ voltage to get the right offset
            
            dbp.rearcurrentswitchval = 1; % [V/nA];
            dbp.hardcurrentscale = 1/(dbp.rearcurrentswitchval*dbp.headstagegain); % [V]/current scal gives nA;
            dbp.hardcurrentoffset = -6.6238/1000;
            dbp.hardvoltagescale = 1/(10); % reads 10X Vm, mult by 1/10 to get actual reading in V, multiply in code to get mV
            dbp.hardvoltageoffset = -6.2589/1000; % in V, reads 10X Vm, mult by 1/10 to get actual reading in V, multiply in code to get mV
            
            dbp.scaledcurrentscale = 1000/(dbp.recgain*dbp.headstagegain); % [mV/V]/gainsetting gives pA
            dbp.scaledcurrentoffset = 0; % [mV/V]/gainsetting gives pA
            dbp.scaledvoltagescale = 1000/(dbp.recgain); % mV/gainsetting gives mV
            dbp.scaledvoltageoffset = 0; % mV/gainsetting gives mV
            
            obj.deviceParameters = dbp;
        end
    end
end
