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

#ifndef SHEPHX_IXX
#define SHEPHX_IXX


#ifndef FLKINFOX_HXX
#include "flkinfox.hxx"
#endif /* FLKINFOX_HXX */

#ifndef TOKENSX_HXX
#include "tokensx.hxx"
#endif /* TOKENSX_HXX */






/* ************************************************************************ *
 * 
 *                    Class Abraham 
 *
 * ************************************************************************ */


/* global: functions */


INLINE BooleanVar  isConstructed (APTR(Heaper) obj){
	{	BooleanVar crutch_Flag;
		/* obj != NULL && obj->getCategory() != cat_Heaper */
		
		crutch_Flag = obj != NULL;
		if(crutch_Flag) {
			crutch_Flag = obj->getCategory() != cat_Heaper;
		}
		return crutch_Flag;
	}
}


INLINE BooleanVar  isDestructed (APTR(Heaper) obj){
	{	BooleanVar crutch_Flag;
		/* obj == NULL || obj->getCategory() == cat_Heaper */
		
		crutch_Flag = obj == NULL;
		if(!crutch_Flag) {
			crutch_Flag = obj->getCategory() == cat_Heaper;
		}
		return crutch_Flag;
	}
}
/* tokens */
/* protected: destruction */
/* protected: disk */
/* destruction */
/* testing */
/* accessing */
/* protected: create */


INLINE Abraham::Abraham (UInt32 hash, TCSJ) {
	/* This is for shepherds that are becoming from another shepherd. */
	
	/* Thing to do !!!! */
	
	/* Change my callers to use Abraham::Abraham(UInt32,APTR(Flock
		Info)).  The flockInfo should be restored at the 
		Abraham level instead of below.  This also more 
		likely causes the type checker to catch inappropriate 
		become-constructor use */
	myHash = hash;
	this->restartAbraham();
}
/* hooks: */


#endif /* SHEPHX_IXX */

