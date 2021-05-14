% Control the Epifluorescence, control displacements
classdef ControlProtocol < FlySoundProtocol

    properties
    end
    
    properties (Constant,Abstract)
        stimulusHash
    end
    
    properties (SetAccess = protected)
    end
        
    events
    end
    
    methods
        
        function obj = ControlProtocol(varargin)
            %% touch the controlProtocolRefValueMap file
            if ~exist('controlProtocolRefValueMap.mat','file')
                map.(obj.protocolName) = obj.stimulusHash;
                pth = mfilename('fullpath');
                [pth,~] = fileparts(pth);
                save(fullfile(pth,'controlProtocolRefValueMap'),'-struct','map');
                fprintf('Creating ref value map\n')
                disp(map)
            else
                map = load('controlProtocolRefValueMap');
                if ~isfield(map,obj.protocolName)
                    map.(obj.protocolName) = obj.stimulusHash;
                    pth = mfilename('fullpath');
                    [pth,~] = fileparts(pth);
                    save(fullfile(pth,'controlProtocolRefValueMap'),'-struct','map');
                elseif map.(obj.protocolName) ~= obj.stimulusHash
                    map.(obj.protocolName) = obj.stimulusHash;
                    pth = mfilename('fullpath');
                    [pth,~] = fileparts(pth);
                    save(fullfile(pth,'controlProtocolRefValueMap'),'-struct','map');
                end 
            end
        end
                
    end % methods
    
    methods (Access = protected)        
    end % protected methods
    
    methods (Static)
    end
end % classdef
