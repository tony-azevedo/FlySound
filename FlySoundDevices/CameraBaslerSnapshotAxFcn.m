function CameraBaslerSnapshotAxFcn(axobj,event,camobj)

frame = camobj.getExampleFrame;
oldimage = camobj.displayimgobject;
camobj.displayimgobject.CData(:) = frame(camobj.dwnsamp);

drawnow

