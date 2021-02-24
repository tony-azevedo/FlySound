% sndbx_jeromq
% 
% javaclasspath('jeromq-0.5.2.jar')
% import org.zeromq.*;
% 
% context = ZContext();
% socket = context.createSocket(ZMQ.SUB); 
% success = false;
% while(~success)
%     success = socket.connect('tcp://127.0.0.1:5996');
% end
% socket.subscribe("");
% socket.setTCPKeepAlive(1);
% 
% %receive a message
% message = socket.recv(1); %nonblocking receive uses argument (1)
% 
% %when done
% socket.close();
% 
%%
% JARPATH = 'jeromq-0.5.2.jar';
% javaclasspath(JARPATH)
% if 1
%     import org.zeromq.*
%     import java.lang.*
% else
%     % import org.zeromq.SocketType
%     % import org.zeromq.ZMQ
%     % import org.zeromq.ZContext
% end
% 
% context = ZContext();
% publisher = context.createSocket(SocketType.PUB);
% publisher.bind('tcp://127.0.0.1:5556');
% publisher.bind('ipc://weather');
% 
% nextInt = @(n) randi(n) - 1;
% 
% while (~Thread.currentThread().isInterrupted())
%     zipcode = 10000 + nextInt(10000) - 1;
%     temperature = nextInt(215) - 80 + 1;
%     relhumidity = nextInt(50) + 10 + 1;
%     fprintf(1,'%05d %d %d\n', zipcode, temperature, relhumidity)
%     
%     publisher.send(sprintf('%05d %d %d', zipcode, temperature, relhumidity), 0);
% end
% 
% publisher.close();

%% server
% Imitates behavior of running `./scripts/run-example hwserver` in JeroMQ repo.
% Prepare the following JAR file by running:
% `mvn clean install -DskipTests`
% in the JeroMQ repo.
JARPATH = 'C:\Users\tony\Code\FlySound\java\jeromq-0.5.2.jar';
javaclasspath(JARPATH)
import org.zeromq.*
import java.lang.*
% import org.zeromq.SocketType
% import org.zeromq.ZMQ
% import org.zeromq.ZContext
% import java.lang.Thread

context = ZContext();
socket = context.createSocket(SocketType.REP);
socket.bind('tcp://*:5556');

while (~Thread.currentThread().isInterrupted())
    reply = socket.recv();
    fprintf('Received: [%s]\n', char(reply(:)'));
    socket.send('world', 0);
    pause(1); % do some "work"
end

socket.close()
context.destroy()

%% client
JARPATH = 'C:\Users\tony\Code\FlySound\java\jeromq-0.5.2.jar';
javaclasspath(JARPATH)
import org.zeromq.*

context = ZContext();
socket = context.createSocket(SocketType.REQ);
socket.connect('tcp://localhost:5556');
for requestNbr = 1 : 10
    socket.send(sprintf('Hello%d', requestNbr), 0);
    reply = socket.recv();
    fprintf('Received %s %d\n', char(reply(:)'), requestNbr)
end
