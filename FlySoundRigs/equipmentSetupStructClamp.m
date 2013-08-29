function eSS = equipmentSetupStructClamp()
% Equipment for current rig.

eSS.microscope.make = 'Olympus';
eSS.microscope.model = 'BX51WI';

eSS.daq1.make = 'National Instruments';
eSS.daq1.model = 'USB-6343';
eSS.daq1.devName = 'Dev1';

eSS.daq2.make = 'National Instruments';
eSS.daq2.model = 'NI 9263';
eSS.daq2.devName = 'cDAQ1Mod1';

eSS.manipulator1.make = 'Sutter';
eSS.manipulator1.model = 'MP-225';
eSS.manipulator1.device = 'Headstage';

eSS.manipulator2.make = 'Sutter';
eSS.manipulator2.model = 'MP-225';
eSS.manipulator2.device = 'PiezoAcuator';

eSS.amp1.make = 'Axon Instruments';
eSS.amp1.model = 'AxoClamp2B';
eSS.amp1.note = 'from Bruce Bean';

eSS.amp2.make = 'Axon Instruments';
eSS.amp2.model = 'AxoPatch200B';

eSS.scope.make = 'Tektronix';
eSS.scope.model = 'TDS2014B';

eSS.filter.make = 'Warner Instruments';
eSS.filter.model = 'LFP202A';

eSS.piezoAcuator.make = 'Physik Instrumente';
eSS.piezoAcuator.model = 'P-840.20';
eSS.piezoAcuator.amplifier = 'E505';
eSS.piezoAcuator.servo = 'E509X1';

eSS.audio.make = 'Crown';
eSS.audio.model = 'D45';
eSS.audio.speaker = 'ScanSpeak';

eSS.externalSoln.NaCl = 103;
eSS.externalSoln.KCl = 3;
eSS.externalSoln.TES = 5;
eSS.externalSoln.trehalose_2H2O = 8;
eSS.externalSoln.glucose = 10;
eSS.externalSoln.NaHCO3 = 26;
eSS.externalSoln.NaH2PO4_H2O = 1;
eSS.externalSoln.CaCl2_H2O = 1.5;
eSS.externalSoln.MgCl2_6H2O = 4;

eSS.internalSoln.potassiumAspartate = 140;
eSS.internalSoln.HEPES = 10;
eSS.internalSoln.EGTA = 1;
eSS.internalSoln.MgATP = 4;
eSS.internalSoln.Na3GTP	= 0.5;
eSS.internalSoln.KCl = 1;
eSS.internalSoln.biocytinHydrazide = 13;