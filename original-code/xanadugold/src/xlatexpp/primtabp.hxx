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

#ifndef PRIMTABP_HXX
#define PRIMTABP_HXX


#ifndef TOFUX_HXX
#include "tofux.hxx"
#endif /* TOFUX_HXX */

#ifndef INTVARX_HXX
#include "intvarx.hxx"
#endif /* INTVARX_HXX */

#ifndef PRIMTABX_HXX
#include "primtabx.hxx"
#endif /* PRIMTABX_HXX */

#ifndef PRIMTABP_OXX
#include "primtabp.oxx"
#endif /* PRIMTABP_OXX */


#ifndef WPARRAYX_HXX
#include "wparrayx.hxx"
#endif /* WPARRAYX_HXX */


#ifndef CACHEX_OXX
#include "cachex.oxx"
#endif /* CACHEX_OXX */

#ifndef PARRAYX_OXX
#include "parrayx.oxx"
#endif /* PARRAYX_OXX */


/*  */
/*  */




/* ************************************************************************ *
 * 
 *                    Class PrimPtrTableExecutor 
 *
 * ************************************************************************ */




	/* NO CLASS COMMENT */

class PrimPtrTableExecutor : public XnExecutor {

/* Attributes for class PrimPtrTableExecutor */
	CONCRETE(PrimPtrTableExecutor)
	AUTO_GC(PrimPtrTableExecutor)
  public: /* create */

	
	static RPTR(PrimPtrTableExecutor) make (APTR(PrimPtrTable) ARG(table), APTR(XnExecutor) OR(NULL) ARG(follower));
	
  public: /* invoking */

	
	virtual void execute (Int32 ARG(estateIndex));
	
  protected: /* protected: create */

	
	PrimPtrTableExecutor (APTR(PrimPtrTable) ARG(table), APTR(XnExecutor) OR(NULL) ARG(follower));
	
  private:
	CHKPTR(PrimPtrTable) myTable;
	CHKPTR(XnExecutor) OR(NULL) myFollower;
};  /* end class PrimPtrTableExecutor */



/* ************************************************************************ *
 * 
 *                    Class PrimRemovedObject 
 *
 * ************************************************************************ */



/* Initializers for PrimRemovedObject */







	/* A single instance of this exists as a marker for slots in 
	PrimTables where entries have been removed.
	This object lives on the GC heap to keep weak arrays happy */

class PrimRemovedObject : public Heaper {

/* Attributes for class PrimRemovedObject */
	CONCRETE(PrimRemovedObject)
	EQ(PrimRemovedObject)
	NO_GC(PrimRemovedObject)
	NOT_A_TYPE(PrimRemovedObject)

/* Initializers for PrimRemovedObject */



friend class INIT_TIME_NAME(PrimRemovedObject,initTimeNonInherited);

  public: /* accessing */

	
	static INLINE WPTR(Heaper) make ();
	

	/* automatic 0-argument constructor */
  public:
	PrimRemovedObject();


  /* ---------- Static Member variables (class vars) ----------- */
  private:
	static GPTR(Heaper) TheRemovedObject;
};  /* end class PrimRemovedObject */



/* ************************************************************************ *
 * 
 *                    Class PrimSetExecutor 
 *
 * ************************************************************************ */




	/* NO CLASS COMMENT */

class PrimSetExecutor : public XnExecutor {

/* Attributes for class PrimSetExecutor */
	CONCRETE(PrimSetExecutor)
	AUTO_GC(PrimSetExecutor)
  public: /* pseudoconstructor */

	
	static RPTR(PrimSetExecutor) make (APTR(PrimSet) ARG(set));
	
  protected: /* protected: create */

	
	PrimSetExecutor (APTR(PrimSet) ARG(set), TCSJ);
	
  public: /* execution */

	
	virtual void execute (Int32 ARG(estateIndex));
	
  private:
	CHKPTR(PrimSet) mySet;
};  /* end class PrimSetExecutor */



/* ************************************************************************ *
 * 
 *                    Class PrimSetStepper 
 *
 * ************************************************************************ */



/* Initializers for PrimSetStepper */







	/* NO CLASS COMMENT */

class PrimSetStepper : public Stepper {

/* Attributes for class PrimSetStepper */
	CONCRETE(PrimSetStepper)
	AUTO_GC(PrimSetStepper)

/* Initializers for PrimSetStepper */



friend class INIT_TIME_NAME(PrimSetStepper,initTimeNonInherited);

  public: /* create */

	
	static RPTR(Stepper) make (APTR(PtrArray) ARG(ptrs));
	
  public: /* create */

	
	virtual RPTR(Stepper) copy ();
	
	
	PrimSetStepper (APTR(PtrArray) ARG(array), Int32 ARG(index));
	
	
	virtual void destroy ();
	
  public: /* accessing */

	
	virtual WPTR(Heaper) fetch ();
	
	
	virtual BooleanVar hasValue ();
	
	
	virtual void step ();
	
  public: /* printint */

	
	virtual void printOn (ostream& ARG(oo));
	
  private:
	CHKPTR(PtrArray) myPtrs;
	Int4 myIndex;

  /* ---------- Static Member variables (class vars) ----------- */
  private:
	static GPTR(InstanceCache) SomeSteppers;
};  /* end class PrimSetStepper */


#ifdef USE_INLINE
#ifndef PRIMTABP_IXX
#include "primtabp.ixx"
#endif /* PRIMTABP_IXX */


#endif /* USE_INLINE */


#endif /* PRIMTABP_HXX */

