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

#ifndef GCHOOKSX_HXX
#define GCHOOKSX_HXX


#ifndef TOFUX_HXX
#include "tofux.hxx"
#endif /* TOFUX_HXX */

#ifndef INTVARX_HXX
#include "intvarx.hxx"
#endif /* INTVARX_HXX */

#ifndef GCHOOKSX_OXX
#include "gchooksx.oxx"
#endif /* GCHOOKSX_OXX */


#ifndef INITX_HXX
#include "initx.hxx"
#endif /* INITX_HXX */

#ifndef WPARRAYX_HXX
#include "wparrayx.hxx"
#endif /* WPARRAYX_HXX */


#ifndef PARRAYX_OXX
#include "parrayx.oxx"
#endif /* PARRAYX_OXX */

#ifndef PRIMTABX_OXX
#include "primtabx.oxx"
#endif /* PRIMTABX_OXX */


/*  */
/*  */




/* ************************************************************************ *
 * 
 *                    Class CloseExecutor 
 *
 * ************************************************************************ */



/* Initializers for CloseExecutor */




	/* This executor manages objects that need to close file 
	descriptors on finalization. */

class CloseExecutor : public XnExecutor {

/* Attributes for class CloseExecutor */
	CONCRETE(CloseExecutor)
	EQ(CloseExecutor)
	NOT_A_TYPE(CloseExecutor)
	NO_GC(CloseExecutor)

/* Initializers for CloseExecutor */


  public: /* accessing */

	
	static void registerHolder (APTR(Heaper) ARG(holder), Int32 ARG(fd));
	
	
	static void unregisterHolder (APTR(Heaper) ARG(holder), Int32 ARG(fd));
	
  protected: /* protected: create */

	
	CloseExecutor ();
	
  public: /* invoking */

	
	virtual void execute (Int32 ARG(estateIndex));
	


  /* ---------- Static Member variables (class vars) ----------- */
  private:
	static GPTR(Int32Array) FDArray;
	static GPTR(WeakPtrArray) FileDescriptorHolders;
};  /* end class CloseExecutor */



/* ************************************************************************ *
 * 
 *                    Class DeleteExecutor 
 *
 * ************************************************************************ */



/* Initializers for DeleteExecutor */




	/* This executor manages objects that need to release 
	non-Heaper storage on finalization. */

class DeleteExecutor : public XnExecutor {

/* Attributes for class DeleteExecutor */
	CONCRETE(DeleteExecutor)
	EQ(DeleteExecutor)
	NOT_A_TYPE(DeleteExecutor)
	NO_GC(DeleteExecutor)

/* Initializers for DeleteExecutor */


  public: /* accessing */

	
	static void registerHolder (APTR(Heaper) ARG(holder), void * ARG(storage));
	
	
	static void unregisterHolder (APTR(Heaper) ARG(holder), void * ARG(storage));
	
  public: /* invoking */

	
	virtual void execute (Int32 ARG(estateIndex));
	
  protected: /* protected: create */

	
	DeleteExecutor ();
	


  /* ---------- Static Member variables (class vars) ----------- */
  private:
	static void* * StorageArray;
	static GPTR(WeakPtrArray) StorageHolders;
};  /* end class DeleteExecutor */



/* ************************************************************************ *
 * 
 *                    Class RepairEngineer 
 *
 * ************************************************************************ */



/* Initializers for RepairEngineer */




	/* RepairEngineers are invoked at the top of server loops and 
	the like in order to perform damage control after such events 
	as a conservative GC or a conservative purge in response to 
	an resource emergency with a deep stack.  These modules 
	should implement subclasses of RepairEngineer (RE) which 
	implement the method {void} repair.
	REs are registered by construction and deregistered by destruction. */

class RepairEngineer : public Heaper {

/* Attributes for class RepairEngineer */
	DEFERRED(RepairEngineer)
	EQ(RepairEngineer)
	AUTO_GC(RepairEngineer)

/* Initializers for RepairEngineer */


  public: /* repairing */

	
	static void repairThings ();
	
  protected: /* protected: create */

	
	RepairEngineer ();
	
	
	virtual void destruct ();
	
  public: /* invoking */

	
	virtual void repair () DEFERRED_SUBR;
	
  private: /* private: accessing */

	
	INLINE RPTR(RepairEngineer) next ();
	
	
	INLINE void setNext (APTR(RepairEngineer) ARG(n));
	
	
	INLINE void setPrev (APTR(RepairEngineer) ARG(n));
	
  private:
	CHKPTR(RepairEngineer) myNext;
	UNPTR(RepairEngineer) myPrev;

  /* ---------- Static Member variables (class vars) ----------- */
  private:
	static GPTR(RepairEngineer) FirstEngineer;
};  /* end class RepairEngineer */



/* ************************************************************************ *
 * 
 *                    Class SanitationEngineer 
 *
 * ************************************************************************ */



/* Initializers for SanitationEngineer */




	/* SanitationEngineers are used by modules that can perform 
	clever resource management at garbage collection time.  These 
	modules should implement subclasses of SanitationEngineer 
	(SE) which implement the method {void} recycle.
	The garbage collector calls the recycle method for each 
	existing SE prior to the marking phase.  SEs are registered
	by construction and deregistered by destruction. */

class SanitationEngineer : public Heaper {

/* Attributes for class SanitationEngineer */
	DEFERRED(SanitationEngineer)
	EQ(SanitationEngineer)
	AUTO_GC(SanitationEngineer)

/* Initializers for SanitationEngineer */


  public: /* sanitizing */

	
	static void garbageDay (BooleanVar ARG(required));
	
  public: /* invoking */

	
	virtual void recycle (BooleanVar ARG(required)) DEFERRED_SUBR;
	
  protected: /* protected: create */

	
	SanitationEngineer ();
	
	
	virtual void destruct ();
	
  private: /* private: accessing */

	
	INLINE RPTR(SanitationEngineer) next ();
	
	
	INLINE void setNext (APTR(SanitationEngineer) ARG(n));
	
	
	INLINE void setPrev (APTR(SanitationEngineer) ARG(p));
	
  private:
	CHKPTR(SanitationEngineer) myNext;
	UNPTR(SanitationEngineer) myPrev;

  /* ---------- Static Member variables (class vars) ----------- */
  private:
	static GPTR(SanitationEngineer) FirstEngineer;
};  /* end class SanitationEngineer */



/* ************************************************************************ *
 * 
 *                    Class StackExaminer 
 *
 * ************************************************************************ */



/* Initializers for StackExaminer */




	/* main() routines that are going to invoke garbage collection should
	call StackExaminer::stackEnd(&stackObj), where stackObj is an Int32
	local to main's stack frame.  This should be called before anything
	else, even invoking the Initializer object. */

class StackExaminer : public Heaper {

/* Attributes for class StackExaminer */
	CONCRETE(StackExaminer)
	NO_GC(StackExaminer)

/* Initializers for StackExaminer */


  public: /* accessing */

	/* Do NOT destroy the result table.  It is reused to avoid 
	allocation during purgeClean. */
	
	static RPTR(PrimPtrTable) pointersOnStack ();
	
	
	static INLINE Int32 * stackEnd ();
	
	
	static void stackEnd (Int32 * ARG(end));
	
  public: /* testing */

	
	virtual UInt32 actualHashForEqual ();
	

	/* automatic 0-argument constructor */
  public:
	StackExaminer();


  /* ---------- Static Member variables (class vars) ----------- */
  private:
	static Int32 * StackEnd;
	static GPTR(PrimPtrTable) TheStackSet;
};  /* end class StackExaminer */


#ifdef USE_INLINE
#ifndef GCHOOKSX_IXX
#include "gchooksx.ixx"
#endif /* GCHOOKSX_IXX */


#endif /* USE_INLINE */


#endif /* GCHOOKSX_HXX */

