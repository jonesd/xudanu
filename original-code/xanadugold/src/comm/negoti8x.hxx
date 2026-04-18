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

#ifndef NEGOTI8X_HXX
#define NEGOTI8X_HXX


#ifndef TOFUX_HXX
#include "tofux.hxx"
#endif /* TOFUX_HXX */

#ifndef INTVARX_HXX
#include "intvarx.hxx"
#endif /* INTVARX_HXX */

#ifndef NEGOTI8X_OXX
#include "negoti8x.oxx"
#endif /* NEGOTI8X_OXX */


#ifndef INITX_HXX
#include "initx.hxx"
#endif /* INITX_HXX */


#ifndef NEGOTI8P_OXX
#include "negoti8p.oxx"
#endif /* NEGOTI8P_OXX */

#ifndef XFRSPECX_OXX
#include "xfrspecx.oxx"
#endif /* XFRSPECX_OXX */


/*  */
/*  */




/* ************************************************************************ *
 * 
 *                    Class ProtocolBroker 
 *
 * ************************************************************************ */



/* Initializers for ProtocolBroker */




	/* NO CLASS COMMENT */

class ProtocolBroker : public Heaper {

/* Attributes for class ProtocolBroker */
	DEFERRED(ProtocolBroker)
	EQ(ProtocolBroker)
	NO_GC(ProtocolBroker)

/* Initializers for ProtocolBroker */


  public: /* configuration */

	/* return whichever is the best current protocol. */
	
	static RPTR(XcvrMaker) commProtocol ();
	
	
	static RPTR(XcvrMaker) commProtocol (char * ARG(id));
	
	/* return whichever is the best current protocol. */
	
	static RPTR(XcvrMaker) diskProtocol ();
	
	
	static RPTR(XcvrMaker) diskProtocol (char * ARG(id));
	
	
	static void registerXcvrProtocol (APTR(XcvrMaker) ARG(maker));
	
	/* Set the protocol. */
	
	static void setCommProtocol (APTR(XcvrMaker) ARG(maker));
	
	/* Set the protocol. */
	
	static void setDiskProtocol (APTR(XcvrMaker) ARG(maker));
	

	/* automatic 0-argument constructor */
  public:
	ProtocolBroker();


  /* ---------- Static Member variables (class vars) ----------- */
  private:
	static GPTR(ProtocolItem) CommProtocols;
	static GPTR(ProtocolItem) DiskProtocols;
	static GPTR(XcvrMaker) TheCommProtocol;
	static GPTR(XcvrMaker) TheDiskProtocol;
};  /* end class ProtocolBroker */



#endif /* NEGOTI8X_HXX */

