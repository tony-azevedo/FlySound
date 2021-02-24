% sndbx_client

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