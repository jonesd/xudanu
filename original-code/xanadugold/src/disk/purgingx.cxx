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

#ifndef PURGINGX_CXX
#define PURGINGX_CXX


#ifndef CHOOSEX_HXX
#include "choosex.hxx"
#endif /* CHOOSEX_HXX */

#ifndef PURGINGX_HXX
#include "purgingx.hxx"
#endif /* PURGINGX_HXX */

#ifndef PURGINGX_IXX
#include "purgingx.ixx"
#endif /* PURGINGX_IXX */

#ifndef PURGINGP_HXX
#include "purgingp.hxx"
#endif /* PURGINGP_HXX */

#ifndef PURGINGP_IXX
#include "purgingp.ixx"
#endif /* PURGINGP_IXX */


#ifndef SHEPHX_HXX
#include "shephx.hxx"
#endif /* SHEPHX_HXX */




/* ************************************************************************ *
 * 
 *                    Class LiberalPurgeror 
 *
 * ************************************************************************ */


/* create */


RPTR(LiberalPurgeror) LiberalPurgeror::make (APTR(SnarfPacker) packer){
	RETURN_CONSTRUCT(LiberalPurgeror,(packer, tcsj));
}
/* protected: create */


LiberalPurgeror::LiberalPurgeror (APTR(SnarfPacker) packer, TCSJ) {
	myPacker = packer;
	myMustPurge = FALSE;
}
/* accessing */


void LiberalPurgeror::setMustPurge (){
	myMustPurge = TRUE;
}
/* invoking */


void LiberalPurgeror::repair (){
	if (myMustPurge) {
		myPacker->purgeClean(TRUE);
		myMustPurge = FALSE;
	}
}



/* ************************************************************************ *
 * 
 *                    Class Purgeror 
 *
 * ************************************************************************ */



/* Initializers for Purgeror */

IntegerVar Purgeror::PurgeRate = 40;



/* Initializers for Purgeror */



/* creation */


RPTR(Purgeror) Purgeror::make (APTR(DiskManager) packer){
	RETURN_CONSTRUCT(Purgeror,(packer, tcsj));
}
/* setting */


void Purgeror::setPurgeRate (IntegerVar count){
	Purgeror::PurgeRate = count;
}
/* We are about to garbage collect.  Every so often, purge the 
objects that are clean so their flocks can be garbage collected. */


/* accessing */
/* protected: creation */


Purgeror::Purgeror (APTR(DiskManager) packer, TCSJ) {
	myPacker = packer;
	myCount = IntegerVar0;
	myPurgePending = FALSE;
}
/* invoking */


void Purgeror::recycle (BooleanVar required){
	if (required) {
		myPurgePending = TRUE;
		return;
		
	}
	{	BooleanVar crutch_Flag;
		/* myCount >= Purgeror::PurgeRate && Purgeror::PurgeRate > IntegerVarZero */
		
		crutch_Flag = myCount >= Purgeror::PurgeRate;
		if(crutch_Flag) {
			crutch_Flag = Purgeror::PurgeRate > IntegerVarZero;
		}
		if (crutch_Flag) {
			{	BooleanVar crutch_Flag;
				/* InsideTransactionFlag.fluidFetch() || myPacker->insideCommit() */
				
				crutch_Flag = InsideTransactionFlag.fluidFetch();
				if(!crutch_Flag) {
					crutch_Flag = myPacker->insideCommit();
				}
				if (crutch_Flag) {
					myPurgePending = TRUE;
				} else {
					myPacker->purgeClean();
					myCount = IntegerVarZero;
					myPurgePending = FALSE;
				}
			}
		} else {
			myCount += 1;
		}
	}
}



/* ************************************************************************ *
 * 
 *                    Class DiskPurgeRate 
 *
 * ************************************************************************ */


/* Set the number of GCs between purges of the packer. */


/* operate */


void DiskPurgeRate::execute (){
	/* Set the number of GCs between packer purges. */
	
	Purgeror::setPurgeRate(myCount);
}

	/* automatic 0-argument constructor */
DiskPurgeRate::DiskPurgeRate() {}

#ifndef PURGINGX_SXX
#include "purgingx.sxx"
#endif /* PURGINGX_SXX */


#ifndef PURGINGP_SXX
#include "purgingp.sxx"
#endif /* PURGINGP_SXX */



#endif /* PURGINGX_CXX */

