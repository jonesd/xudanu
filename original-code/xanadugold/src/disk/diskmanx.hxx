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

#ifndef DISKMANX_HXX
#define DISKMANX_HXX


#ifndef TOFUX_HXX
#include "tofux.hxx"
#endif /* TOFUX_HXX */

#ifndef INTVARX_HXX
#include "intvarx.hxx"
#endif /* INTVARX_HXX */

#ifndef DISKMANX_OXX
#include "diskmanx.oxx"
#endif /* DISKMANX_OXX */


#ifndef BOOTPLNX_HXX
#include "bootplnx.hxx"
#endif /* BOOTPLNX_HXX */

#ifndef INITX_HXX
#include "initx.hxx"
#endif /* INITX_HXX */


#ifndef COOKBKX_OXX
#include "cookbkx.oxx"
#endif /* COOKBKX_OXX */

#ifndef COUNTERX_OXX
#include "counterx.oxx"
#endif /* COUNTERX_OXX */

#ifndef FLKINFOX_OXX
#include "flkinfox.oxx"
#endif /* FLKINFOX_OXX */

#ifndef FLUIDX_OXX
#include "fluidx.oxx"
#endif /* FLUIDX_OXX */

#ifndef PRIMTABX_OXX
#include "primtabx.oxx"
#endif /* PRIMTABX_OXX */

#ifndef RECIPEX_OXX
#include "recipex.oxx"
#endif /* RECIPEX_OXX */

#ifndef SHEPHX_OXX
#include "shephx.oxx"
#endif /* SHEPHX_OXX */

#ifndef TURTLEX_OXX
#include "turtlex.oxx"
#endif /* TURTLEX_OXX */

#ifndef WPARRAYX_OXX
#include "wparrayx.oxx"
#endif /* WPARRAYX_OXX */

#ifndef XFRSPECX_OXX
#include "xfrspecx.oxx"
#endif /* XFRSPECX_OXX */


/*  */
/*  */
#define BEGIN_CONSISTENT(dirty)												\
	{	CurrentPacker.fluidGet()->beginConsistent(dirty);						\
		CurrentPacker.fluidGet()->consistentBlockAt(__FILE__,__LINE__);	\
		PLANT_BOMB(ConsistentBlock,Boom);									\
		ARM_BOMB(Boom,(dirty));												\
		{																		\
			FLUID_BIND(InsideTransactionFlag,TRUE)  {
	
#define END_CONSISTENT	}	}	}

#define BEGIN_INSISTENT(dirty)													\
	{	if (! InsideTransactionFlag.fluidFetch()) {									\
			BLAST(Assertion_failed);												\
		}																			\
		CurrentPacker.fluidGet()->beginConsistent(dirty);						\
		CurrentPacker.fluidGet()->consistentBlockAt(__FILE__,__LINE__);	\
		PLANT_BOMB(ConsistentBlock,Boom);									\
		ARM_BOMB(Boom,(dirty));												\
		{
	
#define END_INSISTENT	}	}





/* ************************************************************************ *
 * 
 *                    Class DiskManager 
 *
 * ************************************************************************ */



/* Initializers for DiskManager */
extern Recipe * DiskCuisine;	/* in DiskManager */



DESIGN_FLUID(DiskManager,CurrentPacker);	/* in DiskManager */
DESIGN_PRIM_FLUID(BooleanVar,InsideAgenda);	/* in DiskManager */


/* exceptions: exceptions */

ORDER_BOMB(ConsistentBlock, IntegerVar );

;



	/* This is the public interface for managing objects that 
	should go to disk.
	This is also the anchor for the so-called Backend emulsion, 
	but I'll call it
	the DiskManager emulsion for simplicity. */

class DiskManager : public Heaper {

/* Attributes for class DiskManager */
	DEFERRED(DiskManager)
	AUTO_GC(DiskManager)

/* Initializers for DiskManager */





  public: /* creation */

	/* This builds the disk managing structure. */
	
	static RPTR(DiskManager) initializeDisk (char * ARG(fname));
	
	
	static RPTR(DiskManager) make (char * ARG(fname));
	
  public: /* emulsion accessing */

	
	static Emulsion * emulsion ();
	
  public: /* shepherds */

	/* Queue destroy of the given flock.  The destroy will 
	probably happen later. */
	
	virtual void destroyFlock (APTR(FlockInfo) ARG(info)) DEFERRED_SUBR;
	
	/* The flock described by info is Dirty! On the next commit, 
	rewrite it to the disk. */
	
	virtual void diskUpdate (APTR(FlockInfo) OR(NULL) ARG(info)) DEFERRED_SUBR;
	
	/* The flock designated by info has completed all dismantling 
	actions; throw it off the disk. */
	
	virtual void dismantleFlock (APTR(FlockInfo) ARG(info)) DEFERRED_SUBR;
	
	/* The flock identified by token is being removed from 
	memory. For now, this is an 
		error if the flock has been updated. If the flock has been 
	forgotten, then it will 
		be dismantled when next it comes in from disk. */
	
	virtual void dropFlock (Int32 ARG(token)) DEFERRED_SUBR;
	
	/* Remember that there are no more persistent pointers to the shepherd 
		described by info. If it gets garbage collected, remember to 
	dismantle it 
		when it comes back in from the disk. */
	
	virtual void forgetFlock (APTR(FlockInfo) ARG(info)) DEFERRED_SUBR;
	
	/* Return the starting object for the entire backend. This 
	will be the 0th 
		flock in the first snarf following the snarfInfo tables. 
	This will eventually 
		always be a shepherd that describes the protocol of the rest 
	of the disk. */
	
	virtual RPTR(Turtle) getInitialFlock () DEFERRED_FUNC;
	
	/* Shepherds use a sequence number for their hash. The most 
	trivial (reasonable) 
		implementation just uses a BatchCounter. This will not be 
	persistent till we get 
		Turtles. */
	
	virtual UInt32 nextHashForEqual () DEFERRED_FUNC;
	
	/* There are now persistent pointers to the shepherd 
	described by info.  See forgetFlock. */
	
	virtual void rememberFlock (APTR(FlockInfo) ARG(info)) DEFERRED_SUBR;
	
	
	virtual void setHashCounter (APTR(Counter) ARG(aCounter));
	
	/* Shep has been created, but is not consistent yet. 
	storeNewFlock must be called on it before the next makeConsistent. */
	
	virtual void storeAlmostNewShepherd (APTR(Abraham) ARG(shep)) DEFERRED_SUBR;
	
	/* A turtle just got created! Remember it as the initial flock. */
	
	virtual void storeInitialFlock (
			APTR(Abraham) ARG(turtle), 
			APTR(XcvrMaker) ARG(protocol), 
			APTR(Cookbook) ARG(cookbook))
	 DEFERRED_SUBR;
	
	/* Shep just got created! On some later commit, assign it to a snarf 
		and write it to the disk. */
	
	virtual void storeNewFlock (APTR(Abraham) ARG(shep)) DEFERRED_SUBR;
	
  public: /* stubs */

	/* If something is already imaged at that location, then 
	return it. If there is already
		 an existing stub with the same hash at a different 
	location, follow them both till we 
		 know that they are actually different objects. */
	
	virtual RPTR(Abraham) fetchCanonical (
			UInt32 ARG(hash), 
			Int32 ARG(snarfID), 
			Int32 ARG(index))
	 DEFERRED_FUNC;
	
	/* Retrieve from the disk the flock at index within the 
	specified snarf.  Since
		 stubs are canonical, and this only gets called by stubs, 
	the existing stub will 
		 *become* the shepherd for the flock. */
	
	virtual void makeReal (APTR(FlockInfo) ARG(info)) DEFERRED_SUBR;
	
	/* Called to register a newly created stub (by the 
	diskSpecialist) in the internal 
		tables. The diskSpecialist in particular calls this when it 
	couldn't find an 
		already existing stub (with fetchCacnonical) representing 
	the flock at the 
		particular location. */
	
	virtual void registerStub (
			APTR(Abraham) ARG(shep), 
			Int32 ARG(snarfID), 
			Int32 ARG(index))
	 DEFERRED_SUBR;
	
  public: /* transactions */

	/* This is called before entering consistent block.  'dirty' 
	is the block's declaration of the maximum number of shepherds 
	which it can dirty.  If this is a top level consistent block, 
	the virtual image in memory is now in a consistent state. It 
	may be written to the disk if necessary.   */
	
	virtual void beginConsistent (IntegerVar ARG(dirty)) DEFERRED_SUBR;
	
	/* This is called after beginConsistent, but before entering 
	a consistent block, for debugging purposes.  Default is to do 
	nothing */
	
	virtual void consistentBlockAt (char * ARG(fileName), Int32 ARG(lineNo));
	
	/* This is called after exiting a consistent block. */
	
	virtual void endConsistent (IntegerVar ARG(dirty)) DEFERRED_SUBR;
	
	
	virtual BooleanVar insideCommit () DEFERRED_FUNC;
	
	/* Flush everything out to disk and remove all purgeable 
	imaged objects from memory.  */
	
	virtual void purge () DEFERRED_SUBR;
	
	/* purge all shepherds that are currently clean, not locked, 
	not dirty, and 
		purgeable. Purging just turns them into stubs, freeing the 
	rest of their flocks. 
		Garbage collection can clean up the flocks and any stubs no 
	longer pointed to 
		by something in memory. */
	
	virtual void purgeClean (BooleanVar ARG(noneLocked) = FALSE) DEFERRED_SUBR;
	
  public: /* testing */

	
	virtual UInt32 actualHashForEqual ();
	
	
	virtual BooleanVar isFake () DEFERRED_FUNC;
	
  protected: /* protected: accessing */

	
	INLINE void flockInfoTable (APTR(PrimPtrTable) ARG(table));
	
	
	INLINE void flockTable (APTR(WeakPtrArray) ARG(table));
	
  public: /* accessing */

	
	INLINE RPTR(PrimPtrTable) flockInfoTable ();
	
	
	INLINE RPTR(WeakPtrArray) flockTable ();
	
  protected: /* protected: creation */

	
	DiskManager ();
	
	
	virtual void destruct ();
	
  public: /* emulsion accessing */

	
	virtual char * fluidSpace ();
	
	
	virtual char * fluidSpace (char * ARG(aFluidSpace));
	
  private:
	char * myFluidSpace;
	CHKPTR(PrimPtrTable) myFlockInfoTable;
	CHKPTR(WeakPtrArray) myFlockTable;

  /* ---------- Static Member variables (class vars) ----------- */
  private:
	static Emulsion * SecretEmulsion;
/* Friends for class DiskManager */
/* friends for class DiskManager */
friend class Abraham;



};  /* end class DiskManager */



/* ************************************************************************ *
 * 
 *                    Class ShepherdBootMaker 
 *
 * ************************************************************************ */




	/* NO CLASS COMMENT */

class ShepherdBootMaker : public BootMaker {

/* Attributes for class ShepherdBootMaker */
	CONCRETE(ShepherdBootMaker)
	COPY(ShepherdBootMaker,BootCuisine)
	NOT_A_TYPE(ShepherdBootMaker)
	NO_GC(ShepherdBootMaker)
  public: /* creation */

	
	static RPTR(BootPlan) make ();
	
  public: /* accessing */

	
	virtual RPTR(Category) bootCategory ();
	
  protected: /* protected: */

	
	virtual RPTR(Heaper) bootHeaper ();
	

	/* automatic 0-argument constructor */
  public:
	ShepherdBootMaker();

};  /* end class ShepherdBootMaker */


#ifdef USE_INLINE
#ifndef DISKMANX_IXX
#include "diskmanx.ixx"
#endif /* DISKMANX_IXX */


#endif /* USE_INLINE */


#endif /* DISKMANX_HXX */

