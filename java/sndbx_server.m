% sndbx_server.m

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
    reply = socket.recv(1);
    fprintf('Received: [%s]\n', char(reply(:)'));
    socket.send('world', 0);
    pause(1); % do some "work"
end

socket.close()
context.destroy()
