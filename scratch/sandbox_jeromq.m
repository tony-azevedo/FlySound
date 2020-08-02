% Author : Dheepak Krishnamurthy
% License : BSD 3 Clause

import org.zeromq.ZMQ;

ctx = zmq.Ctx();

socket = ctx.createSocket(ZMQ.REP);

socket.connect('tcp://127.0.0.1:5557');
message = socket.recv(0);
json_data = native2unicode(message.data)';

message = zmq.Msg(8);
message.put(unicode2native('Received'));
socket.send(message, 0);

socket.close()

