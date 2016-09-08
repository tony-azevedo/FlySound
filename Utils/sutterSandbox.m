obj = NewsutterMP285('COM4');

updatePanel(obj);
 
[stepMult, currentVelocity, vScaleFactor] = getStatus(obj);

xyz_um = getPosition(obj);

setOrigin(obj);

a = instrfind;
%%
pause(2) 
moveTime = moveTo(obj,[0;20;0]);
pause(1)
moveTime = moveTo(obj,[0;-20;0]);
 
%%
setVelocity(obj, 1000, 10) 
pause(1) 
moveTime = moveTo(obj,[0;100;0])
pause(1)
moveTime = moveTo(obj,[0;-100;0])
