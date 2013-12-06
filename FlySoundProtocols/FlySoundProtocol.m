classdef FlySoundProtocol < handle
    % CurrentSine.m
    % CurrentStep.m
    % FlySoundProtocol.m
    % PiezoBWCourtshipSong.m
    % PiezoCourtshipSong.m
    % PiezoSine.m
    % PiezoSquareWave.m
    % PiezoStep.m
    % SealAndLeak.m
    % SealTest.m
    % Sweep.m

    properties (Constant, Abstract) 
        protocolName;
    end
    properties (SetAccess = protected, Abstract)
        requiredRig
        analyses
    end
            
    properties (Hidden, SetAccess = protected)
        target
        current
        paramsToIter
        paramIter
        randomizeIter
    end
    
    % The following properties can be set only by class methods
    properties (SetAccess = protected)
        modusOperandi   % simulate or run?
        params
        rig
        x
        y
        out
    end
    
    % Define an event called InsufficientFunds
    events
        RigChange
        StimulusProblem
    end
    
    methods
        
        function obj = FlySoundProtocol(varargin)
            p = inputParser;
            p.addParamValue('modusOperandi','Run',...
                @(x) any(validatestring(x,{'Run','Stim','Cal'})));
            parse(p,varargin{:});
            obj.modusOperandi = p.Results.modusOperandi;
            
            obj.params.protocol = obj.protocolName;
            obj.params.mode = '';
            obj.params.gain = [];
            obj.params.secondary_gain = [];
            obj.defineParameters();
            obj.setupStimulus();
            obj.queryCameraState

            % obj.showParams;
            obj.target = 1;
            obj.randomizeIter = 0;
            obj.current = 1;
        end        
        
        function stim = next(obj)
            % for this, have to adhere to the convention that multiple
            % value params have an s at the end.
            if ~isempty(obj.paramIter)
                for pn = 1:length(obj.paramsToIter)
                    name = obj.paramsToIter{pn};
                    obj.params.(name(1:end-1)) = obj.paramIter(pn,obj.current);
                end
            end
            stim = obj.getStimulus();
            obj.current = obj.current+1;
        end
        
        function l = hasNext(obj)
            l = obj.current <= obj.target;
        end
                
        function reset(obj)
            obj.current = 1;
        end

        function setParams(obj,varargin)
            quiet = false;
            if nargin>1
                optionstr = varargin{1};
                if strcmp(optionstr(1),'-')
                    for c = 2:length(optionstr)
                        switch optionstr(c)
                            case 'q'
                                quiet = true;
                        end
                    end
                    varargin = varargin(2:end);
                end
            end
            
            if nargin>1
                definedpstruct = varargin{1};
                if isa(definedpstruct,'struct')
                    if isfield(definedpstruct,'trial')
                        definedpstruct = rmfield(definedpstruct,'trial');
                    end
                    if isfield(definedpstruct,'trialBlock')
                        definedpstruct = rmfield(definedpstruct,'trialBlock');
                    end
                    
                    varargin = reshape([fieldnames(definedpstruct),struct2cell(definedpstruct)]',1,[]);
                end
            end
            
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
            obj.setupStimulus
            obj.queryCameraState;
            if ~quiet
                obj.showParams
            end
        end
        
        function showParams(obj,varargin)
            disp('')
            disp(obj.protocolName)
            disp(obj.params);
        end

        function defaults = getDefaults(obj)
            defaults = getpref(['defaults',obj.protocolName]);
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
                setpref(['defaults',obj.protocolName],...
                    [results{r}],...
                    p.Results.(results{r}));
            end
        end
        
        function showDefaults(obj)
            disp('');
            disp('DefaultParameters');
            disp(getpref(['defaults',obj.protocolName]));
        end
        
        function randomize(obj,varargin)
            sl = ~logical(obj.randomizeIter);
            if isempty(sl)
                sl = false;
            end
            if nargin>1
                sl = logical(varargin{1});
            end
            switch sl
                case true
                    obj.randomizeIter = true;
                case false
                    obj.randomizeIter = false;
            end
            obj.setupStimulus
        end

    end % methods
    
    methods (Abstract, Static, Access = protected)
        defineParameters
    end
    
    methods (Abstract,Static)
        % displayTrial
    end
    
    methods (Abstract)
        getStimulus(obj)
    end

    
    methods (Access = protected)
                
        function setupStimulus(obj,varargin)            
            names = fieldnames(obj.params);
            multivals = {};
            obj.paramsToIter = {};
            obj.target = 1;
            for pn = 1:length(names)
                plurality = names{pn};                
                if strcmp(plurality(end),'s') && ...
                        ~ischar(obj.params.(names{pn})) &&...
                        length(obj.params.(names{pn})) > 1
                    obj.paramsToIter{end+1} = names{pn};
                    multivals{end+1} = obj.params.(names{pn});
                    obj.target = obj.target*length(obj.params.(names{pn}));
                end
            end
            obj.paramIter = permsFromCell(multivals);

            if obj.randomizeIter
                rvec = randperm(size(obj.paramIter,2));
                obj.paramIter = obj.paramIter(:,rvec);
            end
            obj.current = 1;
        end
        
        function trialdata = runtimeParameters(obj,varargin)
            p = inputParser;
            addOptional(p,'repeats',1);
            addOptional(p,'vm_id',obj.params.Vm_id);
            parse(p,varargin{:});
            
            trialdata = appendStructure(obj.dataBoilerPlate,obj.params);
            trialdata.Vm_id = p.Results.vm_id;
            trialdata.repeats = p.Results.repeats;
        end
                           
        function queryCameraState(obj,varargin)
            campref = getpref('AcquisitionHardware','cameraToggle');
            if strcmp('on',campref)
                cameraRigMap = getpref('AcquisitionHardware','cameraRigMap');
                obj.requiredRig = cameraRigMap.(obj.requiredRig);  %CameraEPhysRig BasicEPhysRig
                obj.out.trigger = 7.5*(obj.x >= obj.x(1)+.002-eps & obj.x < obj.x(1)+.003+eps);
                obj.out.shutter = 10/7.5*obj.out.trigger + 10*(obj.x >= obj.x(end)-.003-eps & obj.x < obj.x(end)-.002+eps);
            end
        end

        
    end % protected methods
    
    methods (Static)
    end
end % classdef