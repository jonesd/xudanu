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

#ifndef BOOTPLNX_HXX
#define BOOTPLNX_HXX


#ifndef TOFUX_HXX
#include "tofux.hxx"
#endif /* TOFUX_HXX */

#ifndef INTVARX_HXX
#include "intvarx.hxx"
#endif /* INTVARX_HXX */

#ifndef BOOTPLNX_OXX
#include "bootplnx.oxx"
#endif /* BOOTPLNX_OXX */


#ifndef INITX_HXX
#include "initx.hxx"
#endif /* INITX_HXX */

#ifndef THUNKX_HXX
#include "thunkx.hxx"
#endif /* THUNKX_HXX */


#ifndef COOKBKX_OXX
#include "cookbkx.oxx"
#endif /* COOKBKX_OXX */

#ifndef PRIMTABX_OXX
#include "primtabx.oxx"
#endif /* PRIMTABX_OXX */

#ifndef RECIPEX_OXX
#include "recipex.oxx"
#endif /* RECIPEX_OXX */


/*  */
/*  */




/* ************************************************************************ *
 * 
 *                    Class BootPlan 
 *
 * ************************************************************************ */



/* Initializers for BootPlan */
extern Recipe * BootCuisine;	/* in BootPlan */







	/* NO CLASS COMMENT */

class BootPlan : public Thunk {

/* Attributes for class BootPlan */
	DEFERRED(BootPlan)
	NO_GC(BootPlan)

/* Initializers for BootPlan */



friend class INIT_TIME_NAME(BootPlan,initTimeNonInherited);

  public: /* accessing */

	
	virtual RPTR(Category) bootCategory () DEFERRED_FUNC;
	
	/* Return the object representing the connection.  This gives 
	the client a handle by which to terminate the connection. */
	
	virtual RPTR(Connection) connection () DEFERRED_FUNC;
	
  public: /* operate */

	/* A comm hook couldn't register the bootPlan because it's 
	working with a not-fully
		 constructed object, so we have to make bootPlans thunks and 
	register them here. */
	
	virtual void execute ();
	

	/* automatic 0-argument constructor */
  public:
	BootPlan();

};  /* end class BootPlan */



/* ************************************************************************ *
 * 
 *                    Class   BootMaker 
 *
 * ************************************************************************ */




	/* NO CLASS COMMENT */

class BootMaker : public BootPlan {

/* Attributes for class BootMaker */
	DEFERRED(BootMaker)
	NOT_A_TYPE(BootMaker)
	NO_GC(BootMaker)
  public: /* accessing */

	
	virtual RPTR(Category) bootCategory () DEFERRED_FUNC;
	
	/* Return the object representing the connection.  This gives 
	the client a handle by which to terminate the connection. */
	
	virtual RPTR(Connection) connection ();
	
  public: /* printing */

	
	virtual void printOn (ostream& ARG(oo));
	
  protected: /* protected: */

	/* Subclasses of maker only need to define the routine that 
	makes the boot heaper. */
	
	virtual RPTR(Heaper) bootHeaper () DEFERRED_FUNC;
	

	/* automatic 0-argument constructor */
  public:
	BootMaker();

};  /* end class BootMaker */



/* ************************************************************************ *
 * 
 *                    Class Connection 
 *
 * ************************************************************************ */



/* Initializers for Connection */







	/* Suclasses represent particular kinds of connections.  The 
	connection object serves two purposes:  you can get the boot 
	object from it, and you can destroy it to break the 
	connection.  Note that destroying the bootObject does not 
	break the connection because you might have gotten other 
	objects from it. */

class Connection : public Heaper {

/* Attributes for class Connection */
	DEFERRED(Connection)
	EQ(Connection)
	NO_GC(Connection)

/* Initializers for Connection */



friend class INIT_TIME_NAME(Connection,initTimeNonInherited);

  public: /* registration */

	/* Throw out any plan associated with cat. */
	
	static void clearPlan (APTR(Category) ARG(cat));
	
	/* For the current run, return plan if anyone looks for a 
	bootPlan that returns an instance of the category that plan returns. */
	
	static void registerBootPlan (APTR(BootPlan) ARG(plan));
	
  public: /* creation */

	
	static RPTR(Connection) make (APTR(Category) ARG(category));
	
  public: /* accessing */

	
	virtual RPTR(Category) bootCategory () DEFERRED_FUNC;
	
	
	virtual RPTR(Heaper) bootHeaper () DEFERRED_FUNC;
	

	/* automatic 0-argument constructor */
  public:
	Connection();


  /* ---------- Static Member variables (class vars) ----------- */
  private:
	static GPTR(PrimPtr2PtrTable) OF2(Category,BootPlan) TheBootPlans;
};  /* end class Connection */



#endif /* BOOTPLNX_HXX */

