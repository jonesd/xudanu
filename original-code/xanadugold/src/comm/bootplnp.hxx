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

#ifndef BOOTPLNP_HXX
#define BOOTPLNP_HXX


#ifndef TOFUX_HXX
#include "tofux.hxx"
#endif /* TOFUX_HXX */

#ifndef INTVARX_HXX
#include "intvarx.hxx"
#endif /* INTVARX_HXX */

#ifndef BOOTPLNX_HXX
#include "bootplnx.hxx"
#endif /* BOOTPLNX_HXX */

#ifndef BOOTPLNP_OXX
#include "bootplnp.oxx"
#endif /* BOOTPLNP_OXX */


/*  */
/*  */




/* ************************************************************************ *
 * 
 *                    Class ClearPlan 
 *
 * ************************************************************************ */




	/* Remove a particular entry from the table of current BootPlans. */

class ClearPlan : public BootPlan {

/* Attributes for class ClearPlan */
	CONCRETE(ClearPlan)
	COPY(ClearPlan,BootCuisine)
	NOT_A_TYPE(ClearPlan)
	AUTO_GC(ClearPlan)
  public: /* accessing */

	
	virtual RPTR(Category) bootCategory ();
	
	/* Return the object representing the connection.  This gives 
	the client a handle by which to terminate the connection. */
	
	virtual RPTR(Connection) connection ();
	
  public: /* operate */

	/* Use this hook to clear the element out of the bootPlan 
	registration table. */
	
	virtual void execute ();
	
  public: /* creation */

	
	ClearPlan (APTR(Category) ARG(cat), TCSJ);
	
  private:
	CHKPTR(Category) myCategory;
};  /* end class ClearPlan */



/* ************************************************************************ *
 * 
 *                    Class DirectConnection 
 *
 * ************************************************************************ */




	/* We just made the object, so the connection is just a 
	reference to the object. */

class DirectConnection : public Connection {

/* Attributes for class DirectConnection */
	CONCRETE(DirectConnection)
	NOT_A_TYPE(DirectConnection)
	AUTO_GC(DirectConnection)
  public: /* accessing */

	
	virtual RPTR(Category) bootCategory ();
	
	
	virtual RPTR(Heaper) bootHeaper ();
	
  public: /* creation */

	
	DirectConnection (APTR(Category) ARG(cat), APTR(Heaper) ARG(heaper));
	
	/* myHeaper destroy. There are bootHeapers that you REALLY 
	don't want to destroy, such as the GrandMap */
	
	virtual void destruct ();
	
  private:
	CHKPTR(Category) myCategory;
	CHKPTR(Heaper) myHeaper;
};  /* end class DirectConnection */



#endif /* BOOTPLNP_HXX */

