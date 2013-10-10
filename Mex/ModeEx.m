% Target: [lib.pointer, voidPtr, uint32Ptr, int32Ptr] MCCMSG_GetMode(voidPtr, uint32Ptr, int32Ptr)
% helpful: http://www.mathworks.com/help/matlab/matlab_external/passing-arguments-to-shared-library-functions.html
% http://www.mathworks.com/help/matlab/matlab_external/calling-functions-in-shared-libraries.html

[notfound,warns] = loadlibrary('AxMultiClampMsg','AxMultiClampMsg.h');
libisloaded('AxMultiClampMsg')
libfunctions('AxMultiClampMsg','-full')
libfunctionsview('AxMultiClampMsg')
unloadlibrary AxMultiClampMsg

% MCCMSG_CreateObject(0)
nError = 0;
[lp1,hMCCmsg] = calllib('AxMultiClampMsg','MCCMSG_CreateObject',nError);

% MCCMSG_FindFirstMultiClamp(voidPtr, uint32Ptr, cstring, uint32, uint32Ptr, uint32Ptr, uint32Ptr, int32Ptr)
% UINT uModel = 0; // Identifies MultiClamp 700A or 700B model
% char szSerialNum[16] = ""; // Serial number of MultiClamp 700B
% UINT uCOMPortID = 0; // COM port ID of MultiClamp 700A (1-16)
% UINT uDeviceID = 0; // Device ID of MultiClamp 700A (1-8)
% UINT uChannelID = 0; // Headstage channel ID

szError = '';
szSerialNum = ''; %// Serial number of MultiClamp 700B
uModel = 0; %//Identifies MultiClamp 700A or 700B model
uCOMPortID = 0; %// COM port ID of MultiClamp 700A (1-16)
uDeviceID = 0; %// Device ID of MultiClamp 700A (1-8)
uChannelID = 0; %// Headstage channel ID
% MCCMSG_FindFirstMultiClamp(hMCCmsg, uModel, szSerialNum,...
%     sizeof(szSerialNum),uCOMPortID,...
%     uDeviceID, uChannelID)


[lp2, hMCCmsg, uModel, szSerialNum, hmm, uCOMPortID, uDeviceID, uChannelID] = ...
    calllib('AxMultiClampMsg','MCCMSG_FindFirstMultiClamp',hMCCmsg,uModel, szSerialNum,...
    length(szSerialNum), uCOMPortID,...
    uDeviceID, uChannelID,nError)

% device = MCCMSG_SelectMultiClamp(??)
%[lib.pointer, voidPtr, cstring, int32Ptr]	MCCMSG_SelectMultiClamp	(voidPtr, uint32, cstring, uint32, uint32, uint32, int32Ptr)
[voidptr3, h2, uModel, hmm, uCOMPortID] = ...
    calllib('AxMultiClampMsg','MCCMSG_SelectMultiClamp',hMCCmsg,0,[],0,0,0,0)
% int nError = MCCMSG_ERROR_NOERROR;
% MCCMSG_SetMode(m_hMCCmsg, MCCMSG_MODE_VCLAMP, &nError);

%if !MCCMSG_FindFirstMultiClamp(hMCCmsg, &uModel, szSerialNum,
%   sizeof(szSerialNum), &uCOMPortID,
%   &uDeviceID, &uChannelID, &nError)

% if( !MCCMSG_SelectMultiClamp(hMCCmsg, uModel, szSerialNum,
% uCOMPortID, uDeviceID, uChannelID, &nError) )

% MCCMSG_DestroyObject(handle)