classdef Device < handle
        
    properties (Constant,Abstract)
        deviceName;
    end
    
    properties (SetAccess = protected)
        params
        inputLabels % consider from point of view of daq,
        inputUnits %
        inputPorts % consider from point of view of daq, 
        outputLabels
        outputUnits %
        outputPorts % consider from point of view of cell, input to amp are lines out
        mode
        gain
    end
    
    events
        ParamChange
    end
    
    methods
        function obj = Device(varargin)
            % This and the transformInputs function are hard coded
            obj.inputLabels = {};
            obj.inputUnits = {};
            obj.inputPorts = [];
            obj.outputLabels = {};
            obj.outputUnits = {};
            obj.outputPorts = 0;
            obj.defineParameters();
            obj.params = obj.getDefaults();
        end
                        
        function p = getParams(obj)
            p = obj.params;
        end
        
        function setParams(obj,varargin)
            p = inputParser;
            names = fieldnames(obj.params);
            for i = 1:length(names)
                p.addParamValue(names{i},obj.params.(names{i}),@(x) strcmp(class(x),class(obj.params.(names{i}))));
            end
            parse(p,varargin{:});
            results = fieldnames(p.Results);
            for r = 1:length(results)
                obj.params.(results{r}) = p.Results.(results{r});
            end
            obj.showParams
            notify(obj,'ParamChange');
        end
        
        function showParams(obj,varargin)
            disp('')
            disp(obj.deviceName)
            disp(obj.params);
        end
        
        function defaults = getDefaults(obj)
            defaults = getpref(['defaults',obj.deviceName]);
            if isempty(defaults)
                defaultsnew = [fieldnames(obj.params),struct2cell(obj.params)]';
                obj.setDefaults(defaultsnew{:});
                defaults = obj.params;
            end
        end
        
        function setDefaults(obj,varargin)
            p = inputParser;
            names = fieldnames(obj.params);
            for i = 1:length(names)
                addOptional(p,names{i},obj.params.(names{i}));
            end
            parse(p,varargin{:});
            results = fieldnames(p.Results);
            for r = 1:length(results)
                setpref(['defaults',obj.deviceName],...
                    [results{r}],...
                    p.Results.(results{r}));
            end
        end

    end
    
    methods (Abstract)
        inputstruct = transformInputs(obj,inputstruct)
        outputstruct = transformOutputs(obj,outputstruct)
    end
    
    methods (Abstract,Access = protected)
        defineParameters(obj)
    end
end
