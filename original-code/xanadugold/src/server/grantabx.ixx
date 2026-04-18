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

#ifndef GRANTABX_IXX
#define GRANTABX_IXX


#ifndef COUNTERX_HXX
#include "counterx.hxx"
#endif /* COUNTERX_HXX */

#ifndef PARRAYX_HXX
#include "parrayx.hxx"
#endif /* PARRAYX_HXX */

#ifndef SPACEX_HXX
#include "spacex.hxx"
#endif /* SPACEX_HXX */


#include <math.h>




/* ************************************************************************ *
 * 
 *                    Class GrandHashSet 
 *
 * ************************************************************************ */


/* pseudoConstructors */
/* adding-removing */
/* accessing */
/* testing */
/* conversion */
/* creation */
/* printing */
/* enumerating */
/* protected: creation */
/* private: housekeeping */
/* receiver */
/* private: friendly */
/* private: enumerating */


INLINE void GrandHashSet::checkSteppers (){
	if (myOutstandingSteppers > IntegerVar0) {
		BLAST(ModifyBlockedByOutstandingStepper);
	}
}



/* ************************************************************************ *
 * 
 *                    Class GrandHashTable 
 *
 * ************************************************************************ */


/* pseudoConstructors */
/* adding-removing */
/* accessing */
/* testing */
/* creation */
/* printing */
/* runs */
/* private: enumerating */


INLINE void GrandHashTable::checkSteppers (){
	if (myOutstandingSteppers > IntegerVar0) {
		BLAST(ModifyBlockedByOutstandingStepper);
	}
}
/* enumerating */
/* protected: creation */
/* private: housekeeping */
/* hooks: */
/* private: friendly */
/* conversion */


#endif /* GRANTABX_IXX */

