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

#ifndef NXCVRX_HXX
#define NXCVRX_HXX


#ifndef TOFUX_HXX
#include "tofux.hxx"
#endif /* TOFUX_HXX */

#ifndef INTVARX_HXX
#include "intvarx.hxx"
#endif /* INTVARX_HXX */

#ifndef NXCVRX_OXX
#include "nxcvrx.oxx"
#endif /* NXCVRX_OXX */


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
 *                    Class Rcvr 
 *
 * ************************************************************************ */




	/* NO CLASS COMMENT */

class Rcvr : public Heaper {

/* Attributes for class Rcvr */
	DEFERRED(Rcvr)
	EQ(Rcvr)
	NO_GC(Rcvr)
  public: /* receiving */

	
	virtual BooleanVar receiveBooleanVar () DEFERRED_FUNC;
	
	/* Fill the array with data from the stream. */
	
	virtual void receiveData (APTR(UInt8Array) ARG(array)) DEFERRED_SUBR;
	
	
	virtual RPTR(Heaper) receiveHeaper () DEFERRED_FUNC;
	
	
	virtual IEEEDoubleVar receiveIEEEDoubleVar () DEFERRED_FUNC;
	
	
	virtual Int32 receiveInt32 () DEFERRED_FUNC;
	
	
	virtual Int8 receiveInt8 () DEFERRED_FUNC;
	
	
	virtual IntegerVar receiveIntegerVar () DEFERRED_FUNC;
	
	/* Receive an object into another object. */
	
	virtual void receiveInto (APTR(Heaper) ARG(memory)) DEFERRED_SUBR;
	
	
	virtual char * receiveString () DEFERRED_FUNC;
	
	
	virtual UInt32 receiveUInt32 () DEFERRED_FUNC;
	
	
	virtual UInt8 receiveUInt8 () DEFERRED_FUNC;
	

	/* automatic 0-argument constructor */
  public:
	Rcvr();

};  /* end class Rcvr */



/* ************************************************************************ *
 * 
 *                    Class Xmtr 
 *
 * ************************************************************************ */




	/* NO CLASS COMMENT */

class Xmtr : public Heaper {

/* Attributes for class Xmtr */
	DEFERRED(Xmtr)
	EQ(Xmtr)
	NO_GC(Xmtr)
  public: /* sending */

	
	virtual void sendBooleanVar (BooleanVar ARG(b)) DEFERRED_SUBR;
	
	
	virtual void sendHeaper (APTR(Heaper) ARG(object)) DEFERRED_SUBR;
	
	
	virtual void sendIEEEDoubleVar (IEEEDoubleVar ARG(x)) DEFERRED_SUBR;
	
	
	virtual void sendInt32 (Int32 ARG(n)) DEFERRED_SUBR;
	
	
	virtual void sendInt8 (Int8 ARG(byte)) DEFERRED_SUBR;
	
	
	virtual void sendIntegerVar (IntegerVar ARG(n)) DEFERRED_SUBR;
	
	
	virtual void sendString (char * ARG(s)) DEFERRED_SUBR;
	
	
	virtual void sendUInt32 (UInt32 ARG(n)) DEFERRED_SUBR;
	
	
	virtual void sendUInt8 (UInt8 ARG(byte)) DEFERRED_SUBR;
	
	
	virtual void sendUInt8Data (APTR(UInt8Array) ARG(array)) DEFERRED_SUBR;
	

	/* automatic 0-argument constructor */
  public:
	Xmtr();

};  /* end class Xmtr */



#endif /* NXCVRX_HXX */

