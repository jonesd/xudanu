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

#ifndef PROLSTNX_HXX
#define PROLSTNX_HXX


#ifndef TOFUX_HXX
#include "tofux.hxx"
#endif /* TOFUX_HXX */

#ifndef INTVARX_HXX
#include "intvarx.hxx"
#endif /* INTVARX_HXX */

#ifndef PROLSTNX_OXX
#include "prolstnx.oxx"
#endif /* PROLSTNX_OXX */


#ifndef INITX_HXX
#include "initx.hxx"
#endif /* INITX_HXX */

#ifndef SKTSRVX_HXX
#include "sktsrvx.hxx"
#endif /* SKTSRVX_HXX */


#ifndef NADMINX_OXX
#include "nadminx.oxx"
#endif /* NADMINX_OXX */

#ifndef PORTALR_OXX
#include "portalr.oxx"
#endif /* PORTALR_OXX */

#ifndef PROMANX_OXX
#include "promanx.oxx"
#endif /* PROMANX_OXX */


/*  */
/*  */




/* ************************************************************************ *
 * 
 *                    Class IPPromiseListener 
 *
 * ************************************************************************ */




	/* A IPConnectionListener is associated with the FD of a 
	socket connection to a frontend.
	Its handleInput method is used to invoke a 
	waitForAndProcessMessage method to handle messages
	from the frontend. */

class IPPromiseListener : public FDListener {

/* Attributes for class IPPromiseListener */
	CONCRETE(IPPromiseListener)
	AUTO_GC(IPPromiseListener)
  public: /* creation */

	
	static RPTR(FDListener) make (int ARG(aSocket));
	
  protected: /* protected: destruct */

	
	virtual void destruct ();
	
  public: /* creation */

	
	IPPromiseListener (int ARG(aSocket), TCSJ);
	
  public: /* testing */

	
	virtual BooleanVar shouldBeReady ();
	
  public: /* accessing */

	/* Attempt to execute another chunk.  Return whether there is 
	more to be done. */
	
	virtual BooleanVar execute ();
	
  private:
	CHKPTR(PromiseManager) myManager;
	CHKPTR(FeSession) mySession;
	CHKPTR(PacketPortal) myPortal;
};  /* end class IPPromiseListener */



#endif /* PROLSTNX_HXX */

