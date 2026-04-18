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

#ifndef NADMINP_HXX
#define NADMINP_HXX


#ifndef TOFUX_HXX
#include "tofux.hxx"
#endif /* TOFUX_HXX */

#ifndef INTVARX_HXX
#include "intvarx.hxx"
#endif /* INTVARX_HXX */

#ifndef NADMINX_HXX
#include "nadminx.hxx"
#endif /* NADMINX_HXX */

#ifndef NADMINP_OXX
#include "nadminp.oxx"
#endif /* NADMINP_OXX */


#ifndef PARRAYX_OXX
#include "parrayx.oxx"
#endif /* PARRAYX_OXX */


/*  */
/*  */




/* ************************************************************************ *
 * 
 *                    Class DefaultSession 
 *
 * ************************************************************************ */




	/* The default session. */

class DefaultSession : public FeSession {

/* Attributes for class DefaultSession */
	CONCRETE(DefaultSession)
	NOT_A_TYPE(DefaultSession)
	NO_GC(DefaultSession)
  public: /* creation */

	
	static RPTR(FeSession) make ();
	
  public: /* accessing */

	/* Do nothing */
	
	virtual CLIENT void endSession (BooleanVar ARG(withPrejudice) = FALSE);
	
	/* Return whether the session has sucessfully logged in. */
	
	virtual BooleanVar isConnected ();
	
	/* Essential. A system-specific description of the actual 
	transport medium over which the connection is being maintained. */
	
	virtual CLIENT RPTR(UInt8Array) port ();
	

	/* automatic 0-argument constructor */
  public:
	DefaultSession();

};  /* end class DefaultSession */



#endif /* NADMINP_HXX */

