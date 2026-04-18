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

#ifndef CONSISTT_HXX
#define CONSISTT_HXX


#ifndef TOFUX_HXX
#include "tofux.hxx"
#endif /* TOFUX_HXX */

#ifndef INTVARX_HXX
#include "intvarx.hxx"
#endif /* INTVARX_HXX */

#ifndef CONSISTT_OXX
#include "consistt.oxx"
#endif /* CONSISTT_OXX */


#ifndef BOOTPLNX_HXX
#include "bootplnx.hxx"
#endif /* BOOTPLNX_HXX */

#ifndef DISKMANX_HXX
#include "diskmanx.hxx"
#endif /* DISKMANX_HXX */

#ifndef INITX_HXX
#include "initx.hxx"
#endif /* INITX_HXX */

#ifndef THUNKX_HXX
#include "thunkx.hxx"
#endif /* THUNKX_HXX */


#ifndef COOKBKX_OXX
#include "cookbkx.oxx"
#endif /* COOKBKX_OXX */

#ifndef FLKINFOX_OXX
#include "flkinfox.oxx"
#endif /* FLKINFOX_OXX */

#ifndef INTEGERX_OXX
#include "integerx.oxx"
#endif /* INTEGERX_OXX */

#ifndef SETX_OXX
#include "setx.oxx"
#endif /* SETX_OXX */

#ifndef SHEPHX_OXX
#include "shephx.oxx"
#endif /* SHEPHX_OXX */

#ifndef TURTLEX_OXX
#include "turtlex.oxx"
#endif /* TURTLEX_OXX */

#ifndef XFRSPECX_OXX
#include "xfrspecx.oxx"
#endif /* XFRSPECX_OXX */


/*  */
/*  */




/* ************************************************************************ *
 * 
 *                    Class CBlockTracker 
 *
 * ************************************************************************ */



/* Initializers for CBlockTracker */




	/* NO CLASS COMMENT */

class CBlockTracker : public Heaper {

/* Attributes for class CBlockTracker */
	CONCRETE(CBlockTracker)
	AUTO_GC(CBlockTracker)

/* Initializers for CBlockTracker */


  public: /* creation */

	
	static RPTR(CBlockTracker) make (IntegerVar ARG(dirty), APTR(CBlockTracker) OR(NULL) ARG(outer));
	
  public: /* printing */

	/* CBlockTracker printTrackersOn: cerr. cerr endEntry */
	
	static void printTrackersOn (ostream& ARG(oo));
	
  public: /* creation */

	
	CBlockTracker (IntegerVar ARG(dirty), APTR(CBlockTracker) OR(NULL) ARG(outer));
	
  public: /* accessing */

	
	virtual void dirty (APTR(FlockInfo) OR(NULL) ARG(info));
	
	
	virtual RPTR(CBlockTracker) OR(NULL) fetchUnwrapped ();
	
	
	virtual void track (char * ARG(fileName), Int32 ARG(lineNo));
	
  public: /* printing */

	
	virtual void printAllOn (ostream& ARG(oo));
	
	
	virtual void printOn (ostream& ARG(oo));
	
  private: /* private: accessing */

	
	virtual IntegerVar dirtyInfosCount ();
	
	
	virtual IntegerVar dirtySoFar ();
	
	
	virtual RPTR(CBlockTracker) OR(NULL) fetchMatch (APTR(CBlockTracker) ARG(other));
	
	
	virtual char OR(NULL) * fileName ();
	
	
	virtual void innerDirtied (IntegerVar ARG(dirty));
	
	
	virtual void innerDirtyInfos (APTR(MuSet) OF1(IntegerPos) ARG(dirties));
	
	
	virtual void innerTrulyDirtied (IntegerVar ARG(dirty));
	
	
	virtual IntegerVar limit ();
	
	
	virtual Int32 lineNo ();
	
	
	virtual IntegerVar maxDirty ();
	
	
	virtual IntegerVar occurencesCount ();
	
	
	virtual void reportProblems ();
	
	
	virtual IntegerVar slack ();
	
	
	virtual IntegerVar trulyDirtySoFar ();
	
	
	virtual void updateFrom (APTR(CBlockTracker) ARG(other));
	
  public: /* testing */

	
	virtual UInt32 actualHashForEqual ();
	
  private:
	char OR(NULL) * myFileName;
	Int4 myLineNo;
	IntegerVar myMaxDirty;
	IntegerVar myLimit;
	IntegerVar myDirtySoFar;
	IntegerVar myTrulyDirtySoFar;
	CHKPTR(MuSet) OF1(IntegerPos) myDirtyInfos;
	IntegerVar myDirtyInfosCount;
	CHKPTR(CBlockTracker) OR(NULL) myOuterTracker;
	IntegerVar myOccurencesCount;

  /* ---------- Static Member variables (class vars) ----------- */
  private:
	static GPTR(CBlockTracker) OR(NULL) TheTrackerList;
};  /* end class CBlockTracker */



/* ************************************************************************ *
 * 
 *                    Class CBlockTrackingPacker 
 *
 * ************************************************************************ */




	/* NO CLASS COMMENT */

class CBlockTrackingPacker : public DiskManager {

/* Attributes for class CBlockTrackingPacker */
	CONCRETE(CBlockTrackingPacker)
	AUTO_GC(CBlockTrackingPacker)
  public: /* creation */

	
	static RPTR(DiskManager) make (APTR(DiskManager) ARG(subPacker));
	
  public: /* transactions */

	
	virtual void beginConsistent (IntegerVar ARG(dirty));
	
	
	virtual void consistentBlockAt (char * ARG(fileName), Int32 ARG(lineNo));
	
	
	virtual void endConsistent (IntegerVar ARG(dirty));
	
	
	virtual BooleanVar insideCommit ();
	
	
	virtual void purge ();
	
	
	virtual void purgeClean (BooleanVar ARG(noneLocked) = FALSE);
	
  public: /* shepherds */

	/* Queue destroy of the given flock.  The destroy will 
	probably happen later. */
	
	virtual void destroyFlock (APTR(FlockInfo) ARG(info));
	
	
	virtual void diskUpdate (APTR(FlockInfo) OR(NULL) ARG(info));
	
	/* The flock designated by info has completed all dismantling 
	actions; throw it off the disk. */
	
	virtual void dismantleFlock (APTR(FlockInfo) ARG(info));
	
	
	virtual void dropFlock (Int32 ARG(token));
	
	
	virtual void forgetFlock (APTR(FlockInfo) ARG(info));
	
	
	virtual RPTR(Turtle) getInitialFlock ();
	
	
	virtual UInt32 nextHashForEqual ();
	
	
	virtual void rememberFlock (APTR(FlockInfo) ARG(info));
	
	
	virtual void storeAlmostNewShepherd (APTR(Abraham) ARG(shep));
	
	
	virtual void storeInitialFlock (
			APTR(Abraham) ARG(turtle), 
			APTR(XcvrMaker) ARG(protocol), 
			APTR(Cookbook) ARG(cookbook))
	;
	
	
	virtual void storeNewFlock (APTR(Abraham) ARG(shep));
	
  public: /* stubs */

	
	virtual RPTR(Abraham) fetchCanonical (
			UInt32 ARG(hash), 
			Int32 ARG(snarfID), 
			Int32 ARG(index))
	;
	
	
	virtual void makeReal (APTR(FlockInfo) ARG(info));
	
	
	virtual void registerStub (
			APTR(Abraham) ARG(shep), 
			Int32 ARG(snarfID), 
			Int32 ARG(index))
	;
	
  public: /* create */

	
	CBlockTrackingPacker (APTR(DiskManager) ARG(subPacker), TCSJ);
	
  protected: /* protected: destruction */

	
	virtual void destruct ();
	
  public: /* testing */

	
	virtual BooleanVar isFake ();
	
  private: /* private: */

	
	virtual BooleanVar checkTracker ();
	
	/* Used by ResetCommit bomb */
	
	virtual void commitState (BooleanVar ARG(flag));
	
  private:
	CHKPTR(DiskManager) myPacker;
	CHKPTR(CBlockTracker) OR(NULL) myTracker;
};  /* end class CBlockTrackingPacker */



/* ************************************************************************ *
 * 
 *                    Class PrintCBlocksTracks 
 *
 * ************************************************************************ */




	/* NO CLASS COMMENT */

class PrintCBlocksTracks : public Thunk {

/* Attributes for class PrintCBlocksTracks */
	CONCRETE(PrintCBlocksTracks)
	COPY(PrintCBlocksTracks,BootCuisine)
	NOT_A_TYPE(PrintCBlocksTracks)
	NO_GC(PrintCBlocksTracks)
  public: /* operate */

	/*  */
	/* PrintCBlocksTracks create execute */
	
	virtual void execute ();
	

	/* automatic 0-argument constructor */
  public:
	PrintCBlocksTracks();

};  /* end class PrintCBlocksTracks */



/* ************************************************************************ *
 * 
 *                    Class TrackCBlocks 
 *
 * ************************************************************************ */




	/* NO CLASS COMMENT */

class TrackCBlocks : public BootPlan {

/* Attributes for class TrackCBlocks */
	CONCRETE(TrackCBlocks)
	COPY(TrackCBlocks,BootCuisine)
	NOT_A_TYPE(TrackCBlocks)
	AUTO_GC(TrackCBlocks)
  public: /* accessing */

	
	virtual RPTR(Category) bootCategory ();
	
	/* Return the object representing the connection. This gives 
	the client a handle by 
		which to terminate the connection. */
	
	virtual RPTR(Connection) connection ();
	

	/* automatic 0-argument constructor */
  public:
	TrackCBlocks();
  private:
	CHKPTR(BootPlan) myBootPlan;
};  /* end class TrackCBlocks */



#endif /* CONSISTT_HXX */

