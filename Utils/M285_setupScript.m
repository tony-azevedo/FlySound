a = instrfind, delete(a), clear a;
sutterM285 = NewsutterMP285('COM4');

updatePanel(sutterM285);
 
[stepMult, currentVelocity, vScaleFactor] = getStatus(sutterM285);

xyz_um = getPosition(sutterM285);

setOrigin(sutterM285);
