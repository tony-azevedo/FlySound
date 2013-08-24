%  Copyright (c) 2012 Howard Hughes Medical Institute.
%  All rights reserved.
%  Use is subject to Janelia Farm Research Campus Software Copyright 1.1 license terms.
%  http://license.janelia.org/license/jfrc_copyright_1_1.html

classdef RigConfigurationSUI < handle
    
    properties (Constant, Abstract)
        displayName
    end
    
    
    properties
        controller
        allowMultiClampDevices = true
    end
    
    
    properties (Dependent)
        sampleRate
    end
    
    
    properties (GetAccess = private)
        hekaDigitalOutDevice = []
        hekaDigitalOutNames = {}
        hekaDigitalOutChannels = []
    end
    
    
    properties (Hidden)
        proxySampleRate                 % numeric, in Hz
    end
    
    
    methods
        
        function obj = RigConfiguration(allowMultiClampDevices)
        end
        
        
        function daq = createDAQ(obj)
            
            %             % Make sure the unit conversions we need are available.
            %             if ~Converters.Test('V', 'V')
            %                 Converters.Register('V', 'V', @(m) m);
            %             end
            %             if ~Converters.Test('mV', 'V')
            %                 Converters.Register('mV', 'V', @(m) m * 1e-3);
            %             end
            %             if ~Converters.Test('V', 'mV')
            %                 Converters.Register('V', 'mV', @(m) m * 1e3);
            %             end
            %             if ~Converters.Test('A', 'A')
            %                 Converters.Register('A', 'A', @(m) m);
            %             end
            %             if ~Converters.Test('pA', 'A')
            %                 Converters.Register('pA', 'A', @(m) m * 1e-12);
            %             end
            %             if ~Converters.Test('A', 'pA')
            %                 Converters.Register('A', 'pA', @(m) m * 1e12);
            %             end
        end
        
        
        function input = loopbackSimulation(obj, output, ~, outStream, inStream)
        end
        
        
        function set.sampleRate(obj, rate)
        end
        
        
        function rate = get.sampleRate(obj)
        end
        
        
        function stream = streamWithName(obj, streamName, isOutput)
        end
        
        
        function addStreams(obj, device, outStreamName, inStreamName)
            % Create and bind any output stream.
            if ~isempty(outStreamName)
                stream = obj.streamWithName(outStreamName, true);
                device.BindStream(stream);
            end
            
            % Create and bind any input stream.
            if ~isempty(inStreamName)
                stream = obj.streamWithName(inStreamName, false);
                device.BindStream(stream);
            end
        end
        
        
        function addDevice(obj, deviceName, outStreamName, inStreamName, units)
            import Symphony.Core.*;
            import Symphony.ExternalDevices.*;
            
            if isa(obj.controller.DAQController, 'Heka.HekaDAQController') && strncmp(outStreamName, 'DIGITAL_OUT', 11)
                % The digital out channels for the Heka ITC share a single device.
                if isempty(obj.hekaDigitalOutDevice)
                    obj.hekaDigitalOutDevice = UnitConvertingExternalDevice('Heka Digital Out', 'HEKA Instruments', obj.controller, Measurement(0, units));
                    obj.hekaDigitalOutDevice.MeasurementConversionTarget = units;
                    obj.hekaDigitalOutDevice.Clock = obj.controller.DAQController;
                    
                    stream = obj.streamWithName('DIGITAL_OUT.1', true);
                    obj.hekaDigitalOutDevice.BindStream(stream);
                end
                
                % Keep track of which virtual device names map to which channel of the real device.
                obj.hekaDigitalOutNames{end + 1} = deviceName;
                obj.hekaDigitalOutChannels(end + 1) = str2double(outStreamName(end));
            else
                dev = UnitConvertingExternalDevice(deviceName, 'unknown', obj.controller, Measurement(0, units));
                dev.MeasurementConversionTarget = units;
                dev.Clock = obj.controller.DAQController;
                
                obj.addStreams(dev, outStreamName, inStreamName);
            end
        end
        
        
        function mode = multiClampMode(obj, deviceName)
            %
        end
        
        
        function addMultiClampDevice(obj, deviceName, channel, outStreamName, inStreamName)
            %
        end
        
        
        function d = devices(obj)
            %
        end
        
        
        function [device, digitalChannel] = deviceWithName(obj, name)
        end
        
        
        function desc = describeDevices(obj)
        end
        
        
        function setDeviceBackground(obj, deviceName, background)
        end
        
        
        function prepared(obj)
        end
        
        
        function close(obj)
        end
        
    end
    
    
    methods (Abstract)
        
        createDevices(obj);
        
    end
    
end


%% To support units coversion:
%
% fromUnits = 'foo'
% toUnits = 'V'
% Converters.Register(fromUnits, toUnits, @conversionProc);
% 
% 
% function measurementOut = conversionProc(measurementIn)
%   ...
% end
