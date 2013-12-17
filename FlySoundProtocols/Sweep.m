% Collect data
classdef Sweep < FlySoundProtocol
    
    properties (Constant)
        protocolName = 'Sweep';
    end
    
    properties (SetAccess = protected)
        requiredRig = 'BasicEPhysRig';
        analyses = {'powerSpectrum'};
    end
    
    properties (SetAccess = protected)
    end

    
    methods
        
        function obj = Sweep(varargin)
            ...
        end
        
        function varargout = getStimulus(obj,varargin)
            varargout = {obj.out,obj.x};
        end
        
    end % methods
    
    methods (Access = protected)
                        
        function defineParameters(obj)
            obj.params.sampratein = 50000;
            obj.params.samprateout = 50000;
            obj.params.durSweep = 5;
            obj.params.Vm_id = 0;
            obj.params = obj.getDefaults;
        end
       
        function setupStimulus(obj,varargin)
            obj.x = makeOutTime(obj);
            obj.out.voltage = zeros(size(obj.x));
            obj.out.current = zeros(size(obj.x));
        end
                
    end % protected methods
    
    methods (Static)
    end
end % classdef

                
% function displayTrial(obj)
%     figure(1);
%     ax1 = subplot(4,1,1);
%     ax2 = subplot(4,1,[2 3 4]);
%     redlines = findobj(1,'Color',[1, 0, 0]);
%     set(redlines,'color',[1 .8 .8]);
%     line(obj.x,obj.y(:,1),'parent',ax2,'color',[1 0 0],'linewidth',1);
%     box off; set(gca,'TickDir','out');
%     switch obj.recmode
%         case 'VClamp'
%             ylabel(ax2,'I (pA)'); %xlim([0 max(t)]);
%             line(obj.x,obj.y(:,3),'parent',ax1,'color',[1 0 0],'linewidth',1);
%             ylabel(ax1,'V_m (mV)'); %xlim([0 max(t)]);
%             title(ax1,[num2str(mean(obj.y(:,3))) ' mV']);
%         case 'IClamp'
%             ylabel('V_m (mV)'); %xlim([0 max(t)]);
%             line(obj.x,obj.y(:,2),'parent',ax1,'color',[1 0 0],'linewidth',1);
%             ylabel(ax1,'I (pA)'); %xlim([0 max(t)]);
%             title(ax1,[num2str(mean(obj.y(:,2))) ' pA']);
%     end
%     xlabel('Time (s)'); %xlim([0 max(t)]);
% end
