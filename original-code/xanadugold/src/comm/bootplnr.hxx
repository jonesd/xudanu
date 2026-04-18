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

#ifndef BOOTPLNR_HXX
#define BOOTPLNR_HXX


#ifndef TOFUX_HXX
#include "tofux.hxx"
#endif /* TOFUX_HXX */

#ifndef INTVARX_HXX
#include "intvarx.hxx"
#endif /* INTVARX_HXX */

#ifndef BOOTPLNX_HXX
#include "bootplnx.hxx"
#endif /* BOOTPLNX_HXX */

#ifndef BOOTPLNR_OXX
#include "bootplnr.oxx"
#endif /* BOOTPLNR_OXX */


/*  */
/*  */




/* ************************************************************************ *
 * 
 *                    Class NestedConnection 
 *
 * ************************************************************************ */




	/* We just made an object that wraps another object, so the 
	connection needs to wrap the connection by which that other 
	object was obtained. */

class NestedConnection : public Connection {

/* Attributes for class NestedConnection */
	CONCRETE(NestedConnection)
	NOT_A_TYPE(NestedConnection)
	AUTO_GC(NestedConnection)
  public: /* creation */

	
	static RPTR(Connection) make (
			APTR(Category) ARG(cat), 
			APTR(Heaper) ARG(heaper), 
			APTR(Connection) ARG(sub))
	;
	
  public: /* accessing */

	
	virtual RPTR(Category) bootCategory ();
	
	
	virtual RPTR(Heaper) bootHeaper ();
	
  public: /* creation */

	
	NestedConnection (
			APTR(Category) ARG(cat), 
			APTR(Heaper) ARG(heaper), 
			APTR(Connection) ARG(sub))
	;
	
	
	virtual void destruct ();
	
  private:
	CHKPTR(Category) myCategory;
	CHKPTR(Heaper) myHeaper;
	CHKPTR(Connection) mySub;
};  /* end class NestedConnection */



#endif /* BOOTPLNR_HXX */

