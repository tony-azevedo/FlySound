classdef EpiOrLEDRig < Rig
    
    properties (Constant,Abstract)
        rigName
        IsContinuous;
    end
    
    properties (Constant)
    end

    properties (Hidden, SetAccess = protected)
    end
    
    properties (SetAccess = protected)
    end
    
    events
        %InsufficientFunds, notify(BA,'InsufficientFunds')
    end
    
    methods
        function obj = EpiOrLEDRig(varargin)
            ...
        end
                    
        function turnOffEpi(obj,callingobj,evntdata,varargin)
            % Now set the abort channel on briefly before turning it back
            % off
            
            output = obj.aoSession.UserData;
            if isempty(output)
                output = zeros(1,length(obj.outputchannelidx));
                
            else
                output = output.CurrentOutput;
                
            end
            output_a = output;
            for chidx = 1:length(obj.outputchannelidx)
                if contains(obj.aoSession.Channels(obj.outputchannelidx(chidx)).Name,'abort')
                    output_a(chidx) = 1;
                end
                if contains(obj.aoSession.Channels(obj.outputchannelidx(chidx)).Name,'epittl')
                    output_a(chidx) = 0;
                    output(chidx) = 0;
                end
            end
            obj.aoSession.outputSingleScan(output_a);
            obj.aoSession.outputSingleScan(output);
            
            fprintf(1,'LED Off\n')
        end
        
        function turnOnEpi(obj,callingobj,evntdata,varargin)
            % Now set epittl channel on
            
            output = obj.aoSession.UserData;
            if isempty(output)
                output = zeros(1,length(obj.outputchannelidx));
            else
                output = output.CurrentOutput;
            end
            output_a = output;
            for chidx = 1:length(obj.outputchannelidx)
                if contains(obj.aoSession.Channels(obj.outputchannelidx(chidx)).Name,'epittl')
                    output_a(chidx) = 1;
                end
            end
            obj.aoSession.outputSingleScan(output_a);
            obj.aoSession.outputSingleScan(output);
            fprintf(1,'LED On\n')
        end
        
        
        function setArduinoControl(obj,callingobj,evntdata,varargin)
            % Now set the control channel
            
            output = obj.aoSession.UserData;
            if isempty(output)
                output = zeros(1,length(obj.outputchannelidx));
                
            else
                output = output.CurrentOutput;
                
            end
            output_a = output;
            ardparams = callingobj.getParams;
            for chidx = 1:length(obj.outputchannelidx)
                if contains(obj.aoSession.Channels(obj.outputchannelidx(chidx)).Name,'control')
                    output_a(chidx) = ardparams.controlToggle;
                end
            end
            obj.aoSession.outputSingleScan(output_a);
            % obj.aoSession.outputSingleScan(output);
        end
    end
end
