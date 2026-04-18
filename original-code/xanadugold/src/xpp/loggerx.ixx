/* Copyright Xanadu Operating Company.  All Rights Reserved. */

/******************************************************************************
*                                                                            *
* The information contained herein is confidential, proprietary to Xanadu    *
* Operating Company, and considered a trade secret as defined in section     * 
* 499C of the penal code of the State of California.  Use of this information* 
* by anyone other than authorized employees of Xanadu is granted             *
* only under a  written non-disclosure agreement, expressly prescribing      * 
* the scope and  manner of such use.                                         *
*                                                                            *
***************************************************************************
*/

#ifndef LOGGERX_IXX
#define LOGGERX_IXX


BUILD_BOMB_BEGIN(StreamFlush,ostream *) {
    CHARGE->flush();
} BUILD_BOMB_END(StreamFlush);


#endif /* LOGGERX_IXX */

