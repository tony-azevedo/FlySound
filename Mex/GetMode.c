#include <afxwin.h> // MFC core and standard components
#include "AxMultiClampMsg.h"
#include "mex.h"
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
char GetMode()
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
        
        // get the current mode
        UINT uMode = 0;
        if( !MCCMSG_GetMode(m_hMCCmsg, &uMode, &nError) )
        {
            char szError[256] = "";
            MCCMSG_BuildErrorText(m_hMCCmsg, nError, szError, sizeof(szError)); AfxMessageBox(szError, MB_ICONSTOP);
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
    
    HMCCMSG hMCCmsg
    double multiplier;              /* input scalar */
    double *inMatrix;               /* 1xN input matrix */
    size_t ncols;                   /* size of matrix */
    double *outMatrix;              /* output matrix */

    /* check for proper number of arguments */
    if(nrhs!=2) {
        mexErrMsgIdAndTxt("MyToolbox:arrayProduct:nrhs","Two inputs required.");
    }
    if(nlhs!=1) {
        mexErrMsgIdAndTxt("MyToolbox:arrayProduct:nlhs","One output required.");
    }
    /* make sure the first input argument is scalar */
    if( !mxIsDouble(prhs[0]) || 
         mxIsComplex(prhs[0]) ||
         mxGetNumberOfElements(prhs[0])!=1 ) {
        mexErrMsgIdAndTxt("MyToolbox:arrayProduct:notScalar","Input multiplier must be a scalar.");
    }
    
    /* make sure the second input argument is type double */
    if( !mxIsDouble(prhs[1]) || 
         mxIsComplex(prhs[1])) {
        mexErrMsgIdAndTxt("MyToolbox:arrayProduct:notDouble","Input matrix must be type double.");
    }
    
    /* check that number of rows in second input argument is 1 */
    if(mxGetM(prhs[1])!=1) {
        mexErrMsgIdAndTxt("MyToolbox:arrayProduct:notRowVector","Input must be a row vector.");
    }
    
    /* get the value of the scalar input  */
    multiplier = mxGetScalar(prhs[0]);

    /* create a pointer to the real data in the input matrix  */
    inMatrix = mxGetPr(prhs[1]);

    /* get dimensions of the input matrix */
    ncols = mxGetN(prhs[1]);

    /* create the output matrix */
    plhs[0] = mxCreateDoubleMatrix(1,(mwSize)ncols,mxREAL);

    /* get a pointer to the real data in the output matrix */
    outMatrix = mxGetPr(plhs[0]);
    
    
    /* Do the actual computations in a subroutine */
    MCCMSG_GetMode(voidPtr, uint32Ptr, int32Ptr)
    GetMode();
    return;
    
}
