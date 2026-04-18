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

#ifndef PROLSTNP_HXX
#define PROLSTNP_HXX


#ifndef TOFUX_HXX
#include "tofux.hxx"
#endif /* TOFUX_HXX */

#ifndef INTVARX_HXX
#include "intvarx.hxx"
#endif /* INTVARX_HXX */

#ifndef PROLSTNX_HXX
#include "prolstnx.hxx"
#endif /* PROLSTNX_HXX */

#ifndef PROLSTNP_OXX
#include "prolstnp.oxx"
#endif /* PROLSTNP_OXX */


#ifndef NADMINX_HXX
#include "nadminx.hxx"
#endif /* NADMINX_HXX */


#ifndef DISKMANX_OXX
#include "diskmanx.oxx"
#endif /* DISKMANX_OXX */

#ifndef FLUIDX_OXX
#include "fluidx.oxx"
#endif /* FLUIDX_OXX */

#ifndef PARRAYX_OXX
#include "parrayx.oxx"
#endif /* PARRAYX_OXX */

#ifndef PROMANX_OXX
#include "promanx.oxx"
#endif /* PROMANX_OXX */


/*  */
/*  */




/* ************************************************************************ *
 * 
 *                    Class FePromiseSession 
 *
 * ************************************************************************ */



/* Initializers for FePromiseSession */
DESIGN_FLUID(FePromiseSession,CurrentSessions);	/* in FePromiseSession */




	/* Represent a single unique connection to the server over 
	some underlying bytestream channel. */

class FePromiseSession : public FeSession {

/* Attributes for class FePromiseSession */
	CONCRETE(FePromiseSession)
	AUTO_GC(FePromiseSession)

/* Initializers for FePromiseSession */


  public: /* ceration */

	
	static RPTR(FePromiseSession) make (
			APTR(UInt8Array) ARG(port), 
			APTR(Heaper) ARG(listener), 
			APTR(PromiseManager) ARG(manager))
	;
	
  public: /* accessing */

	/* Essential. Terminate this connection.  If withPrejudice is 
	false, it completes the current request and flushes all 
	output before disconnecting. */
	
	virtual CLIENT void endSession (BooleanVar ARG(withPrejudice) = FALSE);
	
	/* Return whether the session has sucessfully logged in. */
	
	virtual BooleanVar isConnected ();
	
	
	virtual RPTR(FePromiseSession) OR(NULL) next ();
	
	/* Essential. A system-specific description of the actual 
	transport medium over which the connection is being maintained. */
	
	virtual CLIENT RPTR(UInt8Array) port ();
	
	
	virtual void remove (APTR(FePromiseSession) ARG(session));
	
  public: /* creation */

	
	FePromiseSession (
			APTR(UInt8Array) ARG(port), 
			APTR(Heaper) ARG(listener), 
			APTR(PromiseManager) ARG(manager))
	;
	
  private:
	CHKPTR(UInt8Array) myPort;
	CHKPTR(PromiseManager) myManager;
	CHKPTR(Heaper) myListener;
	CHKPTR(FePromiseSession) OR(NULL) myNext;
};  /* end class FePromiseSession */



#endif /* PROLSTNP_HXX */

