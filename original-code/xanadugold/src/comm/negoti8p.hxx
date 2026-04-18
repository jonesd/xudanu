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

#ifndef NEGOTI8P_HXX
#define NEGOTI8P_HXX


#ifndef TOFUX_HXX
#include "tofux.hxx"
#endif /* TOFUX_HXX */

#ifndef INTVARX_HXX
#include "intvarx.hxx"
#endif /* INTVARX_HXX */

#ifndef NEGOTI8X_HXX
#include "negoti8x.hxx"
#endif /* NEGOTI8X_HXX */

#ifndef NEGOTI8P_OXX
#include "negoti8p.oxx"
#endif /* NEGOTI8P_OXX */


#ifndef THUNKX_HXX
#include "thunkx.hxx"
#endif /* THUNKX_HXX */


#ifndef NXCVRX_OXX
#include "nxcvrx.oxx"
#endif /* NXCVRX_OXX */


/*  */
/*  */




/* ************************************************************************ *
 * 
 *                    Class ProtocolItem 
 *
 * ************************************************************************ */




	/* NO CLASS COMMENT */

class ProtocolItem : public Heaper {

/* Attributes for class ProtocolItem */
	CONCRETE(ProtocolItem)
	AUTO_GC(ProtocolItem)
  public: /* accessing */

	
	virtual RPTR(Heaper) get (char * ARG(name));
	
  public: /* create */

	
	ProtocolItem (
			char * ARG(name), 
			APTR(Heaper) ARG(item), 
			APTR(ProtocolItem) ARG(next))
	;
	
  public: /* testing */

	
	virtual UInt32 actualHashForEqual ();
	
  private:
	char * myName;
	CHKPTR(ProtocolItem) myNext;
	CHKPTR(Heaper) myItem;
};  /* end class ProtocolItem */



/* ************************************************************************ *
 * 
 *                    Class SetCommProtocol 
 *
 * ************************************************************************ */




	/* When executed, the receiver will set the comm protocol for 
	the next connection. */

class SetCommProtocol : public Thunk {

/* Attributes for class SetCommProtocol */
	CONCRETE(SetCommProtocol)
	COPY(SetCommProtocol,BootCuisine)
	NOT_A_TYPE(SetCommProtocol)
	AUTO_GC(SetCommProtocol)
  public: /* hooks: */

	
	virtual void restartSetCommProtocol (APTR(Rcvr) ARG(rcvr) = NULL);
	
  public: /* thunking */

	/* Execute the action defined by this thunk. */
	
	virtual void execute ();
	

	/* automatic 0-argument constructor */
  public:
	SetCommProtocol();
  private:
	char * myName;
};  /* end class SetCommProtocol */



/* ************************************************************************ *
 * 
 *                    Class SetDiskProtocol 
 *
 * ************************************************************************ */




	/* When executed, the receiver will set the disk protocol for 
	the next connection. */

class SetDiskProtocol : public Thunk {

/* Attributes for class SetDiskProtocol */
	CONCRETE(SetDiskProtocol)
	COPY(SetDiskProtocol,BootCuisine)
	NOT_A_TYPE(SetDiskProtocol)
	AUTO_GC(SetDiskProtocol)
  public: /* operate */

	/* Execute the action defined by this thunk. */
	
	virtual void execute ();
	
  public: /* hooks: */

	
	virtual void restartSetDiskProtocol (APTR(Rcvr) ARG(rcvr) = NULL);
	

	/* automatic 0-argument constructor */
  public:
	SetDiskProtocol();
  private:
	char * myName;
};  /* end class SetDiskProtocol */



#endif /* NEGOTI8P_HXX */

