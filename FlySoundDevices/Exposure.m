classdef Exposure < Device
    
    properties (Constant)
        
    end
    
    properties (Hidden, SetAccess = protected)
    end
    
    properties (SetAccess = protected)
        gaincorrection
    end
    
    properties
        deviceName = 'Exposure';
    end

    events
        %
    end
    
    methods
        function obj = Exposure(varargin)
            % This and the transformInputs function are hard coded
            
%             obj.inputLabels = {'exposure'};
%             obj.inputUnits = {'V'};
%             obj.inputPorts = 18;
%             obj.outputLabels = {'trigger','shutter'};
%             obj.outputUnits = {'V'};
%             obj.outputPorts = [1 3];

            obj.digitalInputLabels = {'exposure'};
            obj.digitalInputUnits = {'Bit'};
            obj.digitalInputPorts = [4];
        end
        
        function varargout = transformInputs(obj,inputstruct)
%             inlabels = fieldnames(inputstruct);
%             units = {};
%             for il = 1:length(inlabels)
%                 if strcmp(inlabels{il},'exposure')
%                     units = {'bit'};
%                    
%                     inputstruct.exposure = inputstruct.exposure > 2.5;
%                     inputstruct.exposure = ...
%                         [inputstruct.exposure(2:end) - inputstruct.exposure(1:end-1); 0];
%                     inputstruct.exposure = inputstruct.exposure > 0;
%                 end
%             end
%             varargout = {inputstruct,units};
            
            inlabels = fieldnames(inputstruct);
            units = {};
            for il = 1:length(inlabels)
                if strcmp(inlabels{il},'exposure')
                    units = {'bit'};
                    
                    inputstruct.exposure = inputstruct.exposure > 0.5;
                    inputstruct.exposure = ...
                        [inputstruct.exposure(2:end) - inputstruct.exposure(1:end-1); 0];
                    inputstruct.exposure = inputstruct.exposure > 0;
                end
            end
            varargout = {inputstruct,units};

        end
        
        function out = transformOutputs(obj,out,varargin)
            %multiply outputs by volts/micron
%             rig = varargin{1};
            if ~isfield(out,'trigger')
                fns = fieldnames(out);
                out.trigger = out.(fns{1});
                out.trigger(:) = 0;
            else
            end
%             dur = length(out.trigger)/rig.aoSession.Rate;
%             frametime = 1/obj.params.framerate;
%             Nframes = floor(dur/frametime);
%             idxs = round(((1:Nframes)-1)*(frametime*rig.aoSession.Rate) + 1);
%             out.trigger(idxs) = 1;
%             out.trigger(idxs+1) = 1;
%             out.trigger(idxs(2)) = 0;
%             out.trigger(idxs(2)+1) = 0;
%             out.trigger(idxs(3)) = 0;
%             out.trigger(idxs(3)+1) = 0;
%             out.trigger(end) = 0;
            out.trigger(1:3) = 1;
            
            %out.trigger = ~out.trigger;
%             obj.params.Nframes = sum(out.trigger)/2;
%             obj.videoInput.TriggerRepeat = obj.params.Nframes-1;
%             % obj.videoInput.TriggerFcn = {obj.dispFunc};
        end
    
    end
    
    methods (Access = protected)
        function setupDevice(obj)        
        end

        function defineParameters(obj)
            obj.params.setup = 'x Frames, write in the rest of the information';
        end
    end
end
