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
Output from Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989
*/

#ifndef HLOGGERX_CXX
#define HLOGGERX_CXX


#ifndef CHOOSEX_HXX
#include "choosex.hxx"
#endif /* CHOOSEX_HXX */

#ifndef HLOGGERP_HXX
#include "hloggerp.hxx"
#endif /* HLOGGERP_HXX */

#ifndef HLOGGERP_IXX
#include "hloggerp.ixx"
#endif /* HLOGGERP_IXX */


#ifndef GCHOOKSX_HXX
#include "gchooksx.hxx"
#endif /* GCHOOKSX_HXX */

#ifndef LOGGERX_HXX
#include "loggerx.hxx"
#endif /* LOGGERX_HXX */

#ifndef NXCVRX_HXX
#include "nxcvrx.hxx"
#endif /* NXCVRX_HXX */




/* ************************************************************************ *
 * 
 *                    Class SwitchLogger 
 *
 * ************************************************************************ */


/* operate */


void SwitchLogger::execute (){
	Logger::get(myLoggerName)->init(myDirective);
}
/* hooks: */


void SwitchLogger::restartSwitchLogger (APTR(Rcvr) /* rcvr *//* = NULL*/){
	DeleteExecutor::registerHolder(this, myLoggerName);
	DeleteExecutor::registerHolder(this, myDirective);
}

	/* automatic 0-argument constructor */
SwitchLogger::SwitchLogger() {}

#ifndef HLOGGERP_SXX
#include "hloggerp.sxx"
#endif /* HLOGGERP_SXX */



#endif /* HLOGGERX_CXX */

