classdef BiasControl < handle
    % BiasControl:  implements the http based control interface used to
    % control the BIAS (Basic Image Acquisition Software).
    %
    
    properties
        address = '';
        port = [];
    end
    
    properties (Dependent)
        baseUrl;
    end
    
    methods
        
        function self = BiasControl(address, port)
            self.address = address;
            self.port = port;
        end
        
        function rsp = connect(self)
            cmd = sprintf('%s/?connect',self.baseUrl);
            rsp = self.sendCmd(cmd);
        end
        
        function rsp = disconnect(self)
            cmd = sprintf('%s/?disconnect',self.baseUrl);
            rsp = self.sendCmd(cmd);
        end
        
        function rsp = startCapture(self)
            cmd = sprintf('%s/?start-capture',self.baseUrl);
            rsp = self.sendCmd(cmd);
        end
        
        function rsp = stopCapture(self)
            cmd = sprintf('%s/?stop-capture',self.baseUrl);
            rsp = self.sendCmd(cmd);
        end
        
        function rsp = getConfiguration(self)
            cmd = sprintf('%s/?get-configuration', self.baseUrl);
            rsp = self.sendCmd(cmd);
        end
        
        function rsp = setConfiguration(self,config)
            configJson = structToJson(config);
            cmd = sprintf('%s/?set-configuration=%s',self.baseUrl, configJson);
            rsp = self.sendCmd(cmd);
        end
        
        function rsp = enableLogging(self)
            cmd = sprintf('%s/?enable-logging',self.baseUrl);
            rsp = self.sendCmd(cmd);
        end
        
        function rsp = disableLogging(self)
            cmd = sprintf('%s/?disable-logging', self.baseUrl);
            rsp = self.sendCmd(cmd);
        end
        
        function rsp = loadConfiguration(self,fileName)
            cmd = sprintf('%s/?load-configuration=%s',self.baseUrl,fileName);
            rsp = self.sendCmd(cmd);
        end
        
        function rsp = saveConfiguration(self,fileName)
            cmd = sprintf('%s/?save-configuration=%s',self.baseUrl,fileName);
            rsp = self.sendCmd(cmd);
        end
        
        function rsp = getFrameCount(self)
            cmd = sprintf('%s/?get-frame-count',self.baseUrl);
            rsp = self.sendCmd(cmd);
        end
        
        function rsp = getCameraGuid(self)
            cmd = sprintf('%s/?get-camera-guid',self.baseUrl);
            rsp = self.sendCmd(cmd);
        end
        
        function rsp = getStatus(self)
            cmd = sprintf('%s/?get-status', self.baseUrl);
            rsp = self.sendCmd(cmd);
        end
        
        function rsp = setVideoFile(self,fileName)
            cmd = sprintf('%s/?set-video-file=%s',self.baseUrl,fileName);
            rsp = self.sendCmd(cmd);
        end
        
        function rsp = getVideoFile(self)
            cmd = sprintf('%s/?get-video-file',self.baseUrl);
            rsp = self.sendCmd(cmd);
        end
        
        function rsp = getTimeStamp(self)
            cmd = sprintf('%s/?get-time-stamp', self.baseUrl);
            rsp = self.sendCmd(cmd);
        end
        
        function rsp = getFramesPerSec(self)
            cmd = sprintf('%s/?get-frames-per-sec', self.baseUrl);
            rsp = self.sendCmd(cmd);
        end
        
        function rsp = setCameraName(self,name)
            cmd = sprintf('%s/?set-camera-name=%s',self.baseUrl,name);
            rsp = self.sendCmd(cmd);
        end
        
        function rsp = setWindowGeometry(self, geom)
            geomJson = structToJson(geom);
            cmd = sprintf('%s/?set-window-geometry=%s',self.baseUrl,geomJson);
            rsp = self.sendCmd(cmd);
        end
        
        function rsp = getWindowGeometry(self)
            cmd = sprintf('%s/?get-window-geometry',self.baseUrl);
            rsp = self.sendCmd(cmd);
        end
        
        function rsp = closeWindow(self)
            cmd = sprintf('%s/?close',self.baseUrl);
            rsp = self.sendCmd(cmd);
        end
        
        function baseUrl = get.baseUrl(self)
            baseUrl = sprintf('http://%s:%d',self.address,self.port);
        end
        
    end
    
    methods (Access=protected)
        
        function rsp = sendCmd(self, cmd)
            rspString = urlread(cmd);
            rsp = loadjson(rspString);
        end
    end
    
end

function valJson = structToJson(val)
valJson = savejson('',val);
valJson = strrep(valJson,sprintf('\n'), '');
valJson = strrep(valJson,sprintf('\t'), '');
end