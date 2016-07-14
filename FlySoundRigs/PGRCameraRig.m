classdef PGRCameraRig < EPhysRig
    % current hierarchy: 7/14/16
    %   Rig -> EPhysRig -> BasicEPhysRig
    %                   -> TwoTrodeRig
    %                   -> PiezoRig 
    %                   -> TwoPhotonRig -> TwoPhotonEPhysRig 
    %                                   -> TwoPhotonPiezoRig     
    %                   -> CameraRig    -> CameraEPhysRig 
    %                                   -> PiezoCameraRig 
    %                   -> PGRCameraRig -> PGREPhysRig
    %                                   -> PGRPiezoRig % This setup is for
    %                                   a digital output that requires same
    %                                   session, and same input and output
    %                                   sample rates
    %       -> SingleSession rig?
    
    properties (Constant,Abstract)
        rigName;
        IsContinuous;
    end
    
    methods
        function obj = PGRCameraRig(varargin)
            obj.addDevice('camera','Camera');
            rigDev = getpref('AcquisitionHardware','rigDev');
            triggerChannelIn = getpref('AcquisitionHardware','triggerChannelIn');
            triggerChannelOut = getpref('AcquisitionHardware','triggerChannelOut');
            
            obj.aiSession.addTriggerConnection([rigDev '/' triggerChannelIn],'External','StartTrigger');
            obj.aoSession.addTriggerConnection('External',[rigDev '/' triggerChannelOut],'StartTrigger');
            addlistener(obj,'StartTrial',@obj.readyCamera);
        end
        
        function in = run(obj,protocol,varargin)

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

            obj.aiSession.Rate = protocol.params.sampratein;
            obj.aiSession.NumberOfScans = length(makeInTime(protocol));
            obj.aoSession.Rate = protocol.params.samprateout;
            
            fprintf('Camera Installed: samprateout = sampratein\n');            
            
            if obj.params.interTrialInterval >0;
                t = timerfind('Name','ITItimer');
                if isempty(t)
                    t = timer;
                end
                t.StartDelay = obj.params.interTrialInterval;
                t.TimerFcn = @(tObj, thisEvent) ... 
                    fprintf('%.1f sec inter trial\n',tObj.StartDelay);
                set(t,'Name','ITItimer')
            end
            notify(obj,'StartRun');
            for n = 1:repeats
                while protocol.hasNext()
                    obj.setAOSession(protocol);
                    notify(obj,'StartTrial',PassProtocolData(protocol));
                    %disp(obj.aoSession)
                    obj.aoSession.startBackground; % Start the session that receives start trigger first
                    
                    %disp(obj.aiSession)
                    % Collect input
                    in = obj.aiSession.startForeground; % both amp and signal monitor input
                    %disp(obj.aiSession)
                    obj.transformInputs(in);
                    if obj.params.interTrialInterval >0;
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
        
        function readyCamera(obj,fig,evnt,varargin)
            
            str = sprintf('Ready the camera:\n%.5f sec',evnt.protocol.params.durSweep - 0.002);
            h = msgbox(str,'CAMERA');
            pos = get(h,'position');
            %set(h, 'position',[1280 700 pos(3) pos(4)])
            set(h, 'position',[5 480 pos(3) pos(4)])
            clipboard('copy',sprintf('%.5f',evnt.protocol.params.durSweep - 0.002));

            uiwait(h);

        end
        
        function setDisplay(obj,fig,evnt,varargin)
            setDisplay@Rig(obj,fig,evnt,varargin{:})
            if nargin>3
                protocol = varargin{1};            
                ax = subplot(3,1,[1 2],'Parent',obj.TrialDisplay,'tag','inputax');
                delete(findobj(ax,'tag','ampinput'));
                line(makeTime(protocol),makeTime(protocol),'parent',ax,'color',[1 0 0],'linewidth',1,'tag','ampinput','displayname','input');
                ylabel('Amp Input'); box off; set(gca,'TickDir','out');
                
                ax = subplot(3,1,3,'Parent',obj.TrialDisplay,'tag','outputax');
                
                line(makeInTime(protocol),makeInTime(protocol),'parent',ax,'color',[0 0 1],'linewidth',1,'tag','exposure','displayname','V');
                ylabel('SGS (V)'); box off; set(gca,'TickDir','out');
                xlabel('Time (s)'); %xlim([0 max(t)]);
                linkaxes(get(obj.TrialDisplay,'children'),'x');
            end
        end
        
        function displayTrial(obj,protocol)
            if ~ishghandle(obj.TrialDisplay), obj.setDisplay(protocol), end

            if strcmp(obj.devices.amplifier.mode,'VClamp')
                invec = obj.inputs.data.current;
                ind = find(strcmp(obj.devices.amplifier.inputLabels,'current'));
                inunits = obj.devices.amplifier.inputUnits{ind(1)};
                ylabel(findobj(obj.TrialDisplay,'tag','inputax'),inunits);
            elseif sum(strcmp({'IClamp','IClamp_fast'},obj.devices.amplifier.mode))
                invec = obj.inputs.data.voltage;
                ind = find(strcmp(obj.devices.amplifier.inputLabels,'voltage'));
                inunits = obj.devices.amplifier.inputUnits{ind(1)};
                ylabel(findobj(obj.TrialDisplay,'tag','inputax'),inunits);
            end
                        
            l = findobj(findobj(obj.TrialDisplay,'tag','inputax'),'tag','ampinput');
            set(l,'ydata',invec);
            
            l = findobj(findobj(obj.TrialDisplay,'tag','outputax'),'tag','exposure');
            set(l,'ydata',obj.inputs.data.exposure);

        end

    end
    
    methods (Access = protected)
    end
end
