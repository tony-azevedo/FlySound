#include <afxwin.h> // MFC core and standard components
#include "AxMultiClampMsg.h"
//============================================================================
// FUNCTION: DisplayErrorMsg
// PURPOSE: Display error as text string
//
void DisplayErrorMsg(HMCCMSG hMCCmsg, int nError)
{
    char szError[256] = "";
    MCCMSG_BuildErrorText(hMCCmsg, nError, szError, sizeof(szError));
    AfxMessageBox(szError, MB_ICONSTOP);
}
//============================================================================
// FUNCTION: main
// PURPOSE: This example shows how to create the DLL handle, select the first
// MultiClamp, set current clamp mode, execute auto fast and
// slow compensation, and destroy the handle.
//
int main()
{
// check the API version matches the expected value
    if( !MCCMSG_CheckAPIVersion(MCCMSG_APIVERSION_STR) )
    {
        AfxMessageBox("Version mismatch: AXCLAMPEXMSG.DLL", MB_ICONSTOP);
        return 0;
    }
// create DLL handle
    int nError = MCCMSG_ERROR_NOERROR;
    HMCCMSG hMCCmsg = MCCMSG_CreateObject(&nError);
    if( !hMCCmsg )
        {
            DisplayErrorMsg(hMCCmsg, nError);
            return 0;
        }
// find the first MultiClamp
        char szError[256] = "";
        char szSerialNum[16] = ""; // Serial number of MultiClamp 700B
        UINT uModel = 0; // Identifies MultiClamp 700A or 700B model
        UINT uCOMPortID = 0; // COM port ID of MultiClamp 700A (1-16)
        UINT uDeviceID = 0; // Device ID of MultiClamp 700A (1-8)
        UINT uChannelID = 0; // Headstage channel ID
        if( !MCCMSG_FindFirstMultiClamp(hMCCmsg, &uModel, szSerialNum,
                sizeof(szSerialNum), &uCOMPortID,
                &uDeviceID, &uChannelID, &nError) )
        {
            DisplayErrorMsg(hMCCmsg, nError);
            return 0;
        }
// select this MultiClamp
        if( !MCCMSG_SelectMultiClamp(hMCCmsg, uModel, szSerialNum,
                uCOMPortID, uDeviceID, uChannelID, &nError) )
        {
            DisplayErrorMsg(hMCCmsg, nError);
            return 0;
        }
// set voltage clamp mode
        if( !MCCMSG_SetMode(hMCCmsg, MCCMSG_MODE_VCLAMP, &nError) )
        {
            DisplayErrorMsg(hMCCmsg, nError);
            return 0;
        }
// execute auto fast compensation
        if( !MCCMSG_AutoFastComp(hMCCmsg, &nError) )
        {
            DisplayErrorMsg(hMCCmsg, nError);
            return 0;
        }
// execute auto slow compensation
        if( !MCCMSG_AutoSlowComp(hMCCmsg, &nError) )
        {
            DisplayErrorMsg(hMCCmsg, nError);
            return 0;
        }
// destroy DLL handle
        MCCMSG_DestroyObject(hMCCmsg);
        hMCCmsg = NULL;
        return 0;
} 


void mexFunction( int nlhs, mxArray *plhs[],
        int nrhs, const mxArray*prhs[] )
        
{
    double *yp;
    double *t,*y;
    size_t m,n;
    
    /* Check for proper number of arguments */
    
    if (nrhs != 2) {
        mexErrMsgIdAndTxt( "MATLAB:yprime:invalidNumInputs",
                "Two input arguments required.");
    } else if (nlhs > 1) {
        mexErrMsgIdAndTxt( "MATLAB:yprime:maxlhs",
                "Too many output arguments.");
    }
    
    /* Check the dimensions of Y.  Y can be 4 X 1 or 1 X 4. */
    
    m = mxGetM(Y_IN);
    n = mxGetN(Y_IN);
    if (!mxIsDouble(Y_IN) || mxIsComplex(Y_IN) ||
            (MAX(m,n) != 4) || (MIN(m,n) != 1)) {
        mexErrMsgIdAndTxt( "MATLAB:yprime:invalidY",
                "YPRIME requires that Y be a 4 x 1 vector.");
    }
    
    /* Create a matrix for the return argument */
    YP_OUT = mxCreateDoubleMatrix( (mwSize)m, (mwSize)n, mxREAL);
    
    /* Assign pointers to the various parameters */
    yp = mxGetPr(YP_OUT);
    
    t = mxGetPr(T_IN);
    y = mxGetPr(Y_IN);
    
    /* Do the actual computations in a subroutine */
    yprime(yp,t,y);
    return;
    
}
