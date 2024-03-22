classdef CameraBaslerM2852TRig < CameraBaslerTwoAmpRig
    
    properties
        latestData
    end
    
    properties (Constant)
        rigName = 'CameraBaslerM2852TRig';
        IsContinuous = false;
    end
    
    methods
        function obj = CameraBaslerM2852TRig(varargin)
            addlistener(obj.aiSession,'DataAvailable', @obj.returnData); 
        end
              
        function in = run(obj,protocol,varargin)
            % have to do all the setup lines from super class
            obj.devices.amplifier_1.getmode;
            obj.devices.amplifier_1.getgain;
            
            obj.devices.amplifier_2.getmode;
            obj.devices.amplifier_2.getgain;

            % have to do all the setup lines from super class
            obj.devices.camera.setup(protocol);

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
                    % have to do all the setup lines from super class
                    notify(obj,'StartTrialCamera');

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
                    notify(obj,'EndTrial');

                    in = obj.latestData;                    
                                        
                    %disp(obj.aiSession)
                    obj.transformInputs(in);
                    if obj.params.interTrialInterval >0
                        t = timerfind('Name','ITItimer');
                        start(t)
                        wait(t)
                    end
                    notify(obj,'SaveData');
                    obj.displayTrial(protocol);
                    notify(obj,'DataSaved');
                    notify(obj,'IncreaseTrialNum');

                end
                protocol.reset;
            end
        end
        
        function returnData(obj,fig,evnt,varargin)
            obj.latestData = [obj.latestData;evnt.Data];
        end
        
        function setDisplay(obj,fig,evnt,varargin)
            setDisplay@TwoAmpRig(obj,fig,evnt,varargin{:})

            ax = findobj(obj.TrialDisplay,'tag','inputax1');
            xlims = get(ax,'xlim');
            ylims = get(ax,'ylim');
            x_ = min(xlims)+ 0.025 * diff(xlims);
            y_ = max(ylims)- 0.025 * diff(ylims);
            
            text(x_,y_,sprintf('Camera status:'),'parent',ax,'horizontalAlignment','left','verticalAlignment','top','tag','CameraStatus','fontsize',7);

        end
        
        function displayTrial(obj,protocol)
            if ~ishghandle(obj.TrialDisplay), obj.setDisplay(protocol), end
            displayTrial@TwoAmpRig(obj,protocol)

            xlims = get(findobj(obj.TrialDisplay,'tag','inputax1'),'xlim');
            ylims = get(findobj(obj.TrialDisplay,'tag','inputax1'),'ylim');
            x_ = min(xlims)+ 0.025 * diff(xlims);
            y_ = max(ylims)- 0.025 * diff(ylims);
            t = makeInTime(protocol);
            frames = obj.inputs.data.exposure(1:end-1)==0&obj.inputs.data.exposure(2:end)>0;
            fps = 1/median(diff(t(frames)));
            N = obj.devices.camera.videoInput.DiskLoggerFrameCount; %sum(obj.inputs.data.exposure);
            set(findobj(obj.TrialDisplay,'type','text','tag','CameraStatus'),'string',sprintf('Frames: %d at %.1f fps',N,fps),'position',[x_, y_, 0]);

        end

    end
    
    methods (Access = protected)
    end
end
