classdef M2852TRig < TwoAmpRig
    
    properties
        latestData
    end
    
    properties (Constant)
        rigName = 'M2852TRig';
        IsContinuous = false;
    end
    
    methods
        function obj = M2852TRig(varargin)
            addlistener(obj.aiSession,'DataAvailable', @obj.returnData); 
        end
              
        function in = run(obj,protocol,varargin)
            
            obj.devices.amplifier_1.getmode;
            obj.devices.amplifier_1.getgain;
            
            obj.devices.amplifier_2.getmode;
            obj.devices.amplifier_2.getgain;

            if nargin>2
                repeats = varargin{1};
            else
                repeats = 1;
            end
            if isprop(obj,'TrialDisplay') && ~isempty(obj.TrialDisplay)
                if ishandle(obj.TrialDisplay)
                    delete(obj.TrialDisplay);
                end
            end
            obj.setDisplay([],[],protocol);
            obj.setTestDisplay();
            
            protocol.setParams('-q','samprateout',protocol.params.sampratein);
            obj.aoSession.Rate = protocol.params.samprateout;
            
            if obj.params.interTrialInterval >0
                t = timerfind('Name','ITItimer');
                if isempty(t)
                    t = timer;
                end
                t.StartDelay = obj.params.interTrialInterval;
                t.TimerFcn = @(tObj, thisEvent) ...
                    fprintf('%.1f sec inter trial\n',tObj.StartDelay);
                set(t,'Name','ITItimer')
            end
            a = instrfind; delete(a), clear a;
            sutterM285 = NewsutterMP285('COM3');
            
            updatePanel(sutterM285);
            
            [stepMult, currentVelocity, vScaleFactor] = getStatus(sutterM285);
            
            xyz_um = getPosition(sutterM285);
            
            setOrigin(sutterM285);
            
            notify(obj,'StartRun');
            
            for n = 1:repeats
                while protocol.hasNext()
                    obj.latestData = [];
                    obj.setAOSession(protocol); % gets the next stimulus
                    
                    setOrigin(sutterM285);
                    setVelocity(sutterM285, 5000, 10)

                    notify(obj,'StartTrial',PassProtocolData(protocol));
                    
                    obj.aiSession.startBackground; % both amp and signal monitor input
                    
                    pause(protocol.params.preDurInSec)
                    for i = 1:length(protocol.params.coordinate)
                        moveTime = moveTo(sutterM285,protocol.params.coordinate{i}); % outof (+)/ into (-) board (x) % left(+)/right(-) (y)
                        pause(protocol.params.pause)
                    end
                    if protocol.params.return
                        moveTime = moveTo(sutterM285,[0;0;0]); 
                    end
                    
                    wait(obj.aiSession);
                    
                    in = obj.latestData;
                    obj.transformInputs(in);
                    if obj.params.interTrialInterval >0
                        t = timerfind('Name','ITItimer');
                        start(t)
                        wait(t)
                    end
                    notify(obj,'SaveData');
                    obj.displayTrial(protocol);
                    notify(obj,'DataSaved');
                end
                protocol.reset;
            end
        end
        
        function returnData(obj,fig,evnt,varargin)
            obj.latestData = [obj.latestData;evnt.Data];
        end
        
        function setDisplay(obj,fig,evnt,varargin)
            setDisplay@TwoAmpRig(obj,fig,evnt,varargin{:})
        end
        
        function displayTrial(obj,protocol)
            if ~ishghandle(obj.TrialDisplay), obj.setDisplay(protocol), end
            displayTrial@TwoAmpRig(obj,protocol)
            
        end

    end
    
    methods (Access = protected)
    end
end
