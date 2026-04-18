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

#ifndef TABTOOLX_HXX
#define TABTOOLX_HXX


#ifndef TOFUX_HXX
#include "tofux.hxx"
#endif /* TOFUX_HXX */

#ifndef INTVARX_HXX
#include "intvarx.hxx"
#endif /* INTVARX_HXX */

#ifndef TABTOOLX_OXX
#include "tabtoolx.oxx"
#endif /* TABTOOLX_OXX */


#ifndef INITX_HXX
#include "initx.hxx"
#endif /* INITX_HXX */


#ifndef PARRAYX_OXX
#include "parrayx.oxx"
#endif /* PARRAYX_OXX */


/*  */
/*  */




/* ************************************************************************ *
 * 
 *                    Class PrimeSizeProvider 
 *
 * ************************************************************************ */



/* Initializers for PrimeSizeProvider */




	/* This is a non-stepper stepper that returns a stream of 
	prime numbers.
	
	SCPrimeSizeProvider rejects many primes to be nice for 
	secondary clustering at the cost of increased table size, 
	LPPrimeSizeProvider does not claim to do this.
	
	 - michael 31 July 1991 */

class PrimeSizeProvider : public Heaper {

/* Attributes for class PrimeSizeProvider */
	CONCRETE(PrimeSizeProvider)
	EQ(PrimeSizeProvider)
	AUTO_GC(PrimeSizeProvider)

/* Initializers for PrimeSizeProvider */
friend class INIT_TIME_NAME(PrimeSizeProvider,initTimeNonInherited);

  public: /* creation */

	
	static INLINE RPTR(PrimeSizeProvider) make ();
	
  public: /* accessing */

	
	virtual IntegerVar primeAfter (IntegerVar ARG(attempt));
	
	
	virtual UInt32 uInt32PrimeAfter (UInt32 ARG(attempt));
	
  public: /* creation */

	
	PrimeSizeProvider (APTR(UInt32Array) ARG(aSmallPrimeTable), TCSJ);
	
  private:
	CHKPTR(UInt32Array) smallPrimeTable;
};  /* end class PrimeSizeProvider */



/* ************************************************************************ *
 * 
 *                    Class   LPPrimeSizeProvider 
 *
 * ************************************************************************ */



/* Initializers for LPPrimeSizeProvider */







	/* This is a non-stepper stepper that returns a stream of 
	prime numbers.
	
	SCPrimeSizeProvider rejects many primes to be nice for 
	secondary clustering at the cost of increased table size, 
	LPPrimeSizeProvider does not claim to do this.
	
	 - michael 31 July 1991 */

class LPPrimeSizeProvider : public PrimeSizeProvider {

/* Attributes for class LPPrimeSizeProvider */
	CONCRETE(LPPrimeSizeProvider)
	EQ(LPPrimeSizeProvider)
	NO_GC(LPPrimeSizeProvider)

/* Initializers for LPPrimeSizeProvider */



friend class INIT_TIME_NAME(LPPrimeSizeProvider,initTimeNonInherited);

  public: /* make */

	
	static INLINE RPTR(LPPrimeSizeProvider) make ();
	
  public: /* initialization */

	
	static RPTR(UInt32Array) primeTable ();
	
  public: /* creation */

	
	LPPrimeSizeProvider (APTR(UInt32Array) ARG(aSmallPrimeTable), TCSJ);
	


  /* ---------- Static Member variables (class vars) ----------- */
  private:
	static GPTR(LPPrimeSizeProvider) MySoleProvider;
};  /* end class LPPrimeSizeProvider */


#ifdef USE_INLINE
#ifndef TABTOOLX_IXX
#include "tabtoolx.ixx"
#endif /* TABTOOLX_IXX */


#endif /* USE_INLINE */


#endif /* TABTOOLX_HXX */

