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

#ifndef BRANGE2X_IXX
#define BRANGE2X_IXX


#ifndef BRANGE3X_HXX
#include "brange3x.hxx"
#endif /* BRANGE3X_HXX */

#ifndef IDX_HXX
#include "idx.hxx"
#endif /* IDX_HXX */

#ifndef NKERNELX_HXX
#include "nkernelx.hxx"
#endif /* NKERNELX_HXX */

#ifndef PRIMTABX_HXX
#include "primtabx.hxx"
#endif /* PRIMTABX_HXX */

#ifndef PROPSX_HXX
#include "propsx.hxx"
#endif /* PROPSX_HXX */

#ifndef SETX_HXX
#include "setx.hxx"
#endif /* SETX_HXX */

#ifndef WPARRAYX_HXX
#include "wparrayx.hxx"
#endif /* WPARRAYX_HXX */


#include "entx.hxx"  // for various fluids.



/* ************************************************************************ *
 * 
 *                    Class BeWork 
 *
 * ************************************************************************ */


/* creation */
/* locking */


INLINE RPTR(FeWork) OR(NULL) BeWork::fetchLockingWork (){
	/* The Work which has this locked, or NULL if noone does. */
	
	return CAST(FeWork,myLockingWork->fetch(Int32Zero));
}
/* contents */
/* permissions */
/* props */
/* accessing */
/* private: */
/* hooks: */
/* creation */
/* printing */



/* ************************************************************************ *
 * 
 *                    Class   BeClub 
 *
 * ************************************************************************ */


/* creation */
/* dependents */
/* accessing */
/* private: propagating */
/* private: accessing */
/* contents */
/* propagating */
/* hooks: */
/* creation */


#endif /* BRANGE2X_IXX */

