/* Copyright Xanadu Operating Company.  All Rights Reserved.
	6 September 1991 at 2:05:25 pm
******************************************************************************
*                                                                            *
* The information contained herein is confidential, proprietary to Xanadu    *
* Operating Company, and considered a trade secret as defined in section     * 
* 499C of the penal code of the State of California.  Use of this information* 
* by anyone other than authorized employees of Xanadu is granted             *
* only under a  written non-disclosure agreement, expressly prescribing      * 
* the scope and  manner of such use.                                         *
*                                                                            *
******************************************************************************
*/


#include "buildx.hxx"
#include "urdix.hxx"


/* ************************************************************************ *
 * 
 *                    Class BuildUrdiFile
 *
 * ************************************************************************ */


void BuildUrdiFile::execute () {

    Urdi* newUrdi = urdi(myFilename, mySnarfSize, mySnarfCount, myStageCount, 10);
    UrdiView* view = newUrdi->makeWriteView();
    SnarfHandle * handle = view->makeErasingHandle(Int32Zero);
    handle->destroy();
    view->commitWrite();
    view->destroy();
    newUrdi->destroy();
}

BuildUrdiFile::BuildUrdiFile() {}

#ifndef UBUILDX_SXX
#include "buildx.sxx"
#endif /* UBUILDX_SXX */
