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

#ifndef TABTOOLX_CXX
#define TABTOOLX_CXX


#ifndef CHOOSEX_HXX
#include "choosex.hxx"
#endif /* CHOOSEX_HXX */

#ifndef TABTOOLX_HXX
#include "tabtoolx.hxx"
#endif /* TABTOOLX_HXX */

#ifndef TABTOOLX_IXX
#include "tabtoolx.ixx"
#endif /* TABTOOLX_IXX */




/* ************************************************************************ *
 * 
 *                    Class PrimeSizeProvider 
 *
 * ************************************************************************ */



/* Initializers for PrimeSizeProvider */


BEGIN_INIT_TIME(PrimeSizeProvider,initTimeNonInherited) {
	REQUIRES (LPPrimeSizeProvider);
} END_INIT_TIME(PrimeSizeProvider,initTimeNonInherited);



/* Initializers for PrimeSizeProvider */



/* creation */
/* This is a non-stepper stepper that returns a stream of prime numbers.

SCPrimeSizeProvider rejects many primes to be nice for secondary 
clustering at the cost of increased table size, LPPrimeSizeProvider 
does not claim to do this.

 - michael 31 July 1991 */


/* accessing */


IntegerVar PrimeSizeProvider::primeAfter (IntegerVar attempt){
	UInt32 val;
	UInt32 idx;
	UInt32 lim;
	
	idx = UInt32Zero;
	val = attempt.asLong();
	lim = smallPrimeTable->count();
	for (;;) {	BooleanVar crutch_Flag;
		/* idx < lim && val > smallPrimeTable->uIntAt(idx) */
		
		crutch_Flag = idx < lim;
		if(crutch_Flag) {
			crutch_Flag = val > smallPrimeTable->uIntAt(idx);
		}
		if (crutch_Flag) {
			idx += 1;
		} else {
			break;
		}
	}
	if (idx >= smallPrimeTable->count()) {
		return attempt * 2 + 1;
	} else {
		return IntegerVar(smallPrimeTable->uIntAt(idx));
	}
}


UInt32 PrimeSizeProvider::uInt32PrimeAfter (UInt32 attempt){
	UInt32 val;
	UInt32 idx;
	UInt32 lim;
	
	idx = UInt32Zero;
	val = attempt;
	lim = smallPrimeTable->count();
	for (;;) {	BooleanVar crutch_Flag;
		/* idx < lim && val > smallPrimeTable->uIntAt(idx) */
		
		crutch_Flag = idx < lim;
		if(crutch_Flag) {
			crutch_Flag = val > smallPrimeTable->uIntAt(idx);
		}
		if (crutch_Flag) {
			idx += 1;
		} else {
			break;
		}
	}
	if (idx >= smallPrimeTable->count()) {
		return attempt * 2 + 1;
	} else {
		return smallPrimeTable->uIntAt(idx);
	}
}
/* creation */


PrimeSizeProvider::PrimeSizeProvider (APTR(UInt32Array) aSmallPrimeTable, TCSJ) {
	smallPrimeTable = aSmallPrimeTable;
}



/* ************************************************************************ *
 * 
 *                    Class   LPPrimeSizeProvider 
 *
 * ************************************************************************ */



/* Initializers for LPPrimeSizeProvider */

GPTR(LPPrimeSizeProvider) LPPrimeSizeProvider::MySoleProvider = NULL;



BEGIN_INIT_TIME(LPPrimeSizeProvider,initTimeNonInherited) {
	REQUIRES (UInt32Array);
	CONSTRUCT(LPPrimeSizeProvider::MySoleProvider,LPPrimeSizeProvider,(LPPrimeSizeProvider::primeTable(), tcsj));
} END_INIT_TIME(LPPrimeSizeProvider,initTimeNonInherited);



/* Initializers for LPPrimeSizeProvider */






/* make */
/* initialization */


RPTR(UInt32Array) LPPrimeSizeProvider::primeTable (){
	SPTR(UInt32Array) smallPrimeTable;
	
	smallPrimeTable = UInt32Array::make (71);
	smallPrimeTable->storeUInt(UInt32Zero, 7);
	smallPrimeTable->storeUInt(1, 19);
	smallPrimeTable->storeUInt(2, 41);
	smallPrimeTable->storeUInt(3, 67);
	smallPrimeTable->storeUInt(4, 101);
	smallPrimeTable->storeUInt(5, 139);
	smallPrimeTable->storeUInt(6, 191);
	smallPrimeTable->storeUInt(7, 241);
	smallPrimeTable->storeUInt(8, 313);
	smallPrimeTable->storeUInt(9, 401);
	smallPrimeTable->storeUInt(10, 499);
	smallPrimeTable->storeUInt(11, 617);
	smallPrimeTable->storeUInt(12, 751);
	smallPrimeTable->storeUInt(13, 911);
	smallPrimeTable->storeUInt(14, 1091);
	smallPrimeTable->storeUInt(15, 1297);
	smallPrimeTable->storeUInt(16, 1543);
	smallPrimeTable->storeUInt(17, 1801);
	smallPrimeTable->storeUInt(18, 2113);
	smallPrimeTable->storeUInt(19, 2459);
	smallPrimeTable->storeUInt(20, 2851);
	smallPrimeTable->storeUInt(21, 3331);
	smallPrimeTable->storeUInt(22, 3833);
	smallPrimeTable->storeUInt(23, 4421);
	smallPrimeTable->storeUInt(24, 5059);
	smallPrimeTable->storeUInt(25, 5801);
	smallPrimeTable->storeUInt(26, 6607);
	smallPrimeTable->storeUInt(27, 7547);
	smallPrimeTable->storeUInt(28, 8599);
	smallPrimeTable->storeUInt(29, 9697);
	smallPrimeTable->storeUInt(30, 11004);
	smallPrimeTable->storeUInt(31, 12479);
	smallPrimeTable->storeUInt(32, 14057);
	smallPrimeTable->storeUInt(33, 15803);
	smallPrimeTable->storeUInt(34, 17881);
	smallPrimeTable->storeUInt(35, 20117);
	smallPrimeTable->storeUInt(36, 22573);
	smallPrimeTable->storeUInt(37, 28499);
	smallPrimeTable->storeUInt(38, 32003);
	smallPrimeTable->storeUInt(39, 35759);
	smallPrimeTable->storeUInt(40, 40009);
	smallPrimeTable->storeUInt(41, 44729);
	smallPrimeTable->storeUInt(42, 50053);
	smallPrimeTable->storeUInt(43, 55933);
	smallPrimeTable->storeUInt(44, 62483);
	smallPrimeTable->storeUInt(45, 69911);
	smallPrimeTable->storeUInt(46, 77839);
	smallPrimeTable->storeUInt(47, 86929);
	smallPrimeTable->storeUInt(48, 96787);
	smallPrimeTable->storeUInt(49, 108041);
	smallPrimeTable->storeUInt(50, 120473);
	smallPrimeTable->storeUInt(51, 134087);
	smallPrimeTable->storeUInt(52, 149287);
	smallPrimeTable->storeUInt(53, 166303);
	smallPrimeTable->storeUInt(54, 185063);
	smallPrimeTable->storeUInt(55, 205957);
	smallPrimeTable->storeUInt(56, 228887);
	smallPrimeTable->storeUInt(57, 254663);
	smallPrimeTable->storeUInt(58, 282833);
	smallPrimeTable->storeUInt(59, 313979);
	smallPrimeTable->storeUInt(60, 347287);
	smallPrimeTable->storeUInt(61, 384317);
	smallPrimeTable->storeUInt(62, 424667);
	smallPrimeTable->storeUInt(63, 468841);
	smallPrimeTable->storeUInt(64, 517073);
	smallPrimeTable->storeUInt(65, 569927);
	smallPrimeTable->storeUInt(66, 627553);
	smallPrimeTable->storeUInt(67, 691183);
	smallPrimeTable->storeUInt(68, 760657);
	smallPrimeTable->storeUInt(69, 836483);
	smallPrimeTable->storeUInt(70, 919757);
	WPTR(UInt32Array) 	returnValue;
	returnValue = smallPrimeTable;
	return returnValue;
}
/* This is a non-stepper stepper that returns a stream of prime numbers.

SCPrimeSizeProvider rejects many primes to be nice for secondary 
clustering at the cost of increased table size, LPPrimeSizeProvider 
does not claim to do this.

 - michael 31 July 1991 */


/* creation */


LPPrimeSizeProvider::LPPrimeSizeProvider (APTR(UInt32Array) aSmallPrimeTable, TCSJ) 
	: PrimeSizeProvider(aSmallPrimeTable, tcsj) {
	
}

#ifndef TABTOOLX_SXX
#include "tabtoolx.sxx"
#endif /* TABTOOLX_SXX */



#endif /* TABTOOLX_CXX */

