classdef EpiRig < EPhysRig
    % current hierarchy:
    %   Rig -> EPhysRig -> BasicEPhysRig
    %                   -> TwoTrodeRig
    %                   -> PiezoRig 
    %                   -> TwoPhotonRig -> TwoPhotonEPhysRig 
    %                                   -> TwoPhotonPiezoRig     
    %                   -> CameraRig    -> CameraEPhysRig 
    %                                   -> PiezoCameraRig 
    
    properties (Constant)
        rigName = 'EpiRig';
        IsContinuous = false;
    end
    
    methods
        function obj = EpiRig(varargin)
            obj.addDevice('epi','Epifluorescence');
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
                out = protocol.getStimulus;
                
                delete(findobj(ax,'tag','sgsmonitor'));               
                delete(findobj(ax,'tag','piezocommand'));
                line(makeOutTime(protocol),out.epicommand,'parent',ax,'color',[.7 .7 .7],'linewidth',1,'tag','epicommand','displayname','V');
                ylabel('Epi (V)'); box off; set(gca,'TickDir','out');
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
            
            chnames = obj.getChannelNames;
            
            l = findobj(findobj(obj.TrialDisplay,'tag','outputax'),'tag','epicommand');
            set(l,'ydata',obj.outputs.datacolumns(:,strcmp(chnames.out,'epicommand')));

            l = findobj(findobj(obj.TrialDisplay,'tag','inputax'),'tag','ampinput');
            set(l,'ydata',invec);
            
        end

    end
    
    methods (Access = protected)
    end
end
