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

#ifndef TOKENSX_HXX
#define TOKENSX_HXX


#ifndef TOFUX_HXX
#include "tofux.hxx"
#endif /* TOFUX_HXX */

#ifndef INTVARX_HXX
#include "intvarx.hxx"
#endif /* INTVARX_HXX */

#ifndef TOKENSX_OXX
#include "tokensx.oxx"
#endif /* TOKENSX_OXX */


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
 *                    Class TokenSource 
 *
 * ************************************************************************ */




	/* Manage a set of integerVars as tokens.  The Available 
	array is tokens that have been returned to the pool.  They 
	get used in preference to allocating new ones so that we keep 
	the numbers dense. */

class TokenSource : public Heaper {

/* Attributes for class TokenSource */
	CONCRETE(TokenSource)
	EQ(TokenSource)
	AUTO_GC(TokenSource)
  public: /* creation */

	
	static RPTR(TokenSource) make ();
	
  public: /* accessing */

	
	virtual void returnToken (Int32 ARG(token));
	
	
	virtual Int32 takeToken ();
	
  public: /* creation */

	
	TokenSource ();
	
  private:
	CHKPTR(Int32Array) myAvailable;
	Int32 myAvailableCount;
	Int32 myCeiling;
};  /* end class TokenSource */



#endif /* TOKENSX_HXX */

