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

#ifndef PACKERX_HXX
#define PACKERX_HXX


#ifndef TOFUX_HXX
#include "tofux.hxx"
#endif /* TOFUX_HXX */

#ifndef INTVARX_HXX
#include "intvarx.hxx"
#endif /* INTVARX_HXX */

#ifndef PACKERX_OXX
#include "packerx.oxx"
#endif /* PACKERX_OXX */


#ifndef DISKMANX_HXX
#include "diskmanx.hxx"
#endif /* DISKMANX_HXX */

#ifndef INITX_HXX
#include "initx.hxx"
#endif /* INITX_HXX */


#ifndef ARRAYX_OXX
#include "arrayx.oxx"
#endif /* ARRAYX_OXX */

#ifndef COOKBKX_OXX
#include "cookbkx.oxx"
#endif /* COOKBKX_OXX */

#ifndef COUNTERX_OXX
#include "counterx.oxx"
#endif /* COUNTERX_OXX */

#ifndef FLKINFOX_OXX
#include "flkinfox.oxx"
#endif /* FLKINFOX_OXX */

#ifndef GCHOOKSX_OXX
#include "gchooksx.oxx"
#endif /* GCHOOKSX_OXX */

#ifndef INTEGERX_OXX
#include "integerx.oxx"
#endif /* INTEGERX_OXX */

#ifndef INTTABX_OXX
#include "inttabx.oxx"
#endif /* INTTABX_OXX */

#ifndef NSCOTTYX_OXX
#include "nscottyx.oxx"
#endif /* NSCOTTYX_OXX */

#ifndef PACKERP_OXX
#include "packerp.oxx"
#endif /* PACKERP_OXX */

#ifndef PURGINGX_OXX
#include "purgingx.oxx"
#endif /* PURGINGX_OXX */

#ifndef SETTABX_OXX
#include "settabx.oxx"
#endif /* SETTABX_OXX */

#ifndef SETX_OXX
#include "setx.oxx"
#endif /* SETX_OXX */

#ifndef SHEPHX_OXX
#include "shephx.oxx"
#endif /* SHEPHX_OXX */

#ifndef SNFINFOX_OXX
#include "snfinfox.oxx"
#endif /* SNFINFOX_OXX */

#ifndef TABLESX_OXX
#include "tablesx.oxx"
#endif /* TABLESX_OXX */

#ifndef TURTLEX_OXX
#include "turtlex.oxx"
#endif /* TURTLEX_OXX */

#ifndef URDIX_OXX
#include "urdix.oxx"
#endif /* URDIX_OXX */

#ifndef XFRSPECX_OXX
#include "xfrspecx.oxx"
#endif /* XFRSPECX_OXX */


/*  */
/*  */




/* ************************************************************************ *
 * 
 *                    Class SnarfPacker 
 *
 * ************************************************************************ */



/* Initializers for SnarfPacker */


/* exceptions: private: */

ORDER_BOMB(ResetCommit, SPTR(SnarfPacker) );

;



	/* Should myFlocks contain full flockInfos for forwarded 
	flocks?  Both the flags and the size mean nothing.
	
	A SnarfPacker maintains the relationship between Shepherds 
	and the set of snarfs representing the disk.  A SnarfPacker 
	assigns flocks to snarfs based loosely on the flocks's 
	Shepherd's preferences.  When a flock changes, it informs the 
	SnarfPacker.  When the SnarfPacker decides to write to the 
	disk, it ensures that the changed objects still fit in their 
	snarf (migrating them if necessary), writes them to the 
	snarf, then writes out the snarf.
	
	mySnarfInfo {MuTable of: XuInteger}
			- How much space remains in each snarf.
	mySnarfMap {MuTable of: SnarfRecord}
			- Map from snarfIDs to a SnarfRecord that handles that snarf.
	myChangedSnarfs {MuSet of: XuInteger}
			- The IDs for all snarfs in which an imaged flock has changed.
	myFlocks {SetTable of: XuInteger and: FlockInfo}
			- Indexed by Abraham hash, contains all FlockInfos that 
	refer to flocks in memory.
			  Multiple infos may refer to the same flock if it is 
	referenced through forwarding.
			  The only info considered to have the correct state wrt 
	its flocks suitability for
			  purging is the info pointed to by its Abraham.
	myInsideCommit {BooleanVar}
			- True while writing new and changed flocks to disk to 
	prevent purging,
			  and during purgeClean to prevent recursive call through 
	Purgeror recycling. */

class SnarfPacker : public DiskManager {

/* Attributes for class SnarfPacker */
	CONCRETE(SnarfPacker)
	AUTO_GC(SnarfPacker)

/* Initializers for SnarfPacker */


  public: /* creation */

	
	static RPTR(DiskManager) initializeUrdiOnDisk (char * ARG(fname));
	
	
	static RPTR(SnarfPacker) make (char * ARG(fname));
	
  public: /* shepherds */

	/* Queue destroy of the given flock.  The destroy will happen later. */
	
	virtual void destroyFlock (APTR(FlockInfo) ARG(info));
	
	
	virtual void diskUpdate (APTR(FlockInfo) OR(NULL) ARG(info));
	
	/* Turn the flock designated by info into a Pumpkin.  It 
	should have completed all dismantle actions. */
	
	virtual void dismantleFlock (APTR(FlockInfo) ARG(info));
	
	/* The flock is being removed from memory.  For now, this is an error
		 if the flock has been updated.  If the flock has been forgotten, 
		 then it will be dismantled when next it comes in from disk.
		 Because of forwarding, there may be many FlockInfos refering
		 to the flock if it is not new. */
	
	virtual void dropFlock (Int32 ARG(token));
	
	/* Remember that there are no more persistent pointers to the shepherd
		 represented by info.  If it gets manually deleted, 
	dismantle it immediately.  
		 If it gets garbage collected, remember to dismantle it when 
	it comes back 
		 in from the disk. */
	
	virtual void forgetFlock (APTR(FlockInfo) ARG(info));
	
	/* Return the starting object for the entire backend.  This 
	will be the 0th
		 flock in the first snarf following the snarfInfo tables. */
	
	virtual RPTR(Turtle) getInitialFlock ();
	
	/* Shepherds use a sequence number for their hash.  Return the next one
		and increment.  This should actually spread the hashes. */
	
	virtual UInt32 nextHashForEqual ();
	
	/* There are now persistent pointers to the shepherd help by info. */
	
	virtual void rememberFlock (APTR(FlockInfo) ARG(info));
	
	/* Do nothing */
	
	virtual void storeAlmostNewShepherd (APTR(Abraham) ARG(shep));
	
	/* A turtle just got created!  Write out a pseudo-forwarder 
	that has all the protocol information encoded in the snarfID 
	and index. */
	
	virtual void storeInitialFlock (
			APTR(Abraham) ARG(turtle), 
			APTR(XcvrMaker) ARG(protocol), 
			APTR(Cookbook) ARG(cookbook))
	;
	
	/* Shep just got created! On some later commit, assign it to a snarf 
		and write it to the disk. */
	
	virtual void storeNewFlock (APTR(Abraham) ARG(shep));
	
  public: /* stubs */

	/* If something is already imaged at that location, then 
	return it. If there is already
		 an existing stub with the same hash at a different 
	location, follow them till we 
		 know that they are actually different objects. */
	
	virtual RPTR(Abraham) fetchCanonical (
			UInt32 ARG(hash), 
			Int32 ARG(snarfID), 
			Int32 ARG(index))
	;
	
	/* Retrieve from the disk the flock at index within the 
	specified snarf.  Since
		 stubs are canonical, and this only gets called by stubs, 
	the existing stub will 
		 *become* the shepherd for the flock. */
	
	virtual void makeReal (APTR(FlockInfo) ARG(info));
	
	
	virtual void registerStub (
			APTR(Abraham) ARG(shep), 
			Int32 ARG(snarfID), 
			Int32 ARG(index))
	;
	
  public: /* internals */

	/* Add another flockInfo object to myFlocks with info about 
	another location for shep. */
	
	virtual void addInfo (APTR(FlockInfo) ARG(info), APTR(Abraham) ARG(shep));
	
	/* Send the snarf over a transmitter into a stream that just 
	counts the bytes put 
		into it. */
	
	virtual Int32 computeSize (APTR(Abraham) ARG(flock));
	
	/* Return the current urdiView. */
	
	virtual RPTR(UrdiView) currentView ();
	
	/* Destroy all forgotten flocks that are no longer in memory. */
	
	virtual void destroyAbandoned ();
	
	/* Shep has grown too large for its current place.  Treat it 
	as just a new flock and give it another place. */
	
	virtual void forwardFlock (APTR(Abraham) ARG(shep));
	
	
	virtual RPTR(SpecialistRcvr) makeRcvr (APTR(XnReadStream) ARG(readStream));
	
	
	virtual RPTR(SpecialistXmtr) makeXmtr (APTR(XnWriteStream) ARG(writeStream));
	
	
	virtual void setHashCounter (APTR(Counter) ARG(aCounter));
	
	
	virtual void testNewFlocks ();
	
  public: /* transactions */

	
	virtual void beginConsistent (IntegerVar ARG(dirtyFlocks));
	
	
	virtual void endConsistent (IntegerVar ARG(dirty));
	
	
	virtual BooleanVar insideCommit ();
	
	/* The virtual image in memory is now in a consistent state. 
	Write the image of 
		all changed or new Shepherds out to the disk in a single 
	atomic action.  The 
		atomicity only happens on top of a real Urdi, however. */
	
	virtual void makePersistent ();
	
	/* Flush everything out to disk and remove all purgeable imaged
		 objects from memory. */
	
	virtual void purge ();
	
	/* purge all shepherds that are currently clean, not locked, not dirty,
		 and purgeable.  Purging just turns them into stubs, freeing 
	all their 
		 flocks.  Garbage collection can clean up the flocks and any stubs no 
		 longer pointed to by something in memory.  Because infos for new 
		 flocks don't appear in myFlocks, this will not throw out 
	any newFlocks 
		 (which will be marked dirty anyway).  For each FlockInfo, we check
		 that its flock refers to that exact instance to get correct 
	information
		 about its dirty state. */
	
	virtual void purgeClean (BooleanVar ARG(noneLocked) = FALSE);
	
  protected: /* protected: destruction */

	/* Destroy all objects imaged from this snarf. */
	
	virtual void destruct ();
	
  private: /* private: */

	/* Find a snarf in which to fit shep.  Then assign it to
		 that location, and mark that snarf as changed. */
	
	virtual void assignSnarf (APTR(Abraham) ARG(shep));
	
	/* Perform the sanity check of the moment.  Beware the 
	compile cost of changing this comment. */
	/* myFlocks stepper forEach: [:info {FlockInfo} | info getShepherd].
		myNewFlocks stepper forEach: [:info {FlockInfo} | info getShepherd] */
	
	virtual void checkInfos ();
	
	/* Used by ResetCommit bomb */
	
	virtual void commitState (BooleanVar ARG(flag));
	
	/* Commit by destroying the current view and creating a new one. */
	
	virtual void commitView ();
	
	/* Return true if the object is on disk but not in memory. */
	
	virtual RPTR(Abraham) OR(NULL) fetchInMemory (Int32 ARG(snarfID), Int32 ARG(index));
	
	/* Actually write all the changed and newly assigned flocks 
	to the disk. */
	
	virtual void flushFlocks ();
	
	/* Return the set of indices to flocks in snarf snarfID that 
	are forgotten. */
	
	virtual RPTR(MuSet) OF1(IntegerPos) forgottenFlocks (Int32 ARG(snarfID));
	
	/* Return a flock at a particular location.  This needs to register
		 the flock if it doesn't exist already. */
	
	virtual RPTR(Abraham) getFlock (Int32 ARG(snarfID), Int32 ARG(index));
	
	/* Get the read handler on the snarf. */
	
	virtual RPTR(SnarfHandler) getReadHandler (Int32 ARG(snarfID));
	
	/* Return the snarfRecord for snarfID.  The SnarfRecord must 
	exist if there are
		 changed flocks imaged out of that snarf, but might not 
	otherwise.  Create it if necessary. */
	
	virtual RPTR(SnarfRecord) getSnarfRecord (Int32 ARG(snarfID));
	
	/* The flock represented by info has changed.  Record it in the
		 bookkeeping data-structures.  This must be called by all things 
		 that affect whether the flock gets rewritten to disk. */
	/* The following test should be unnecessary because infos for
		 new flocks should already be dirty, so we shouldn't get here. */
	
	virtual void recordUpdate (APTR(FlockInfo) ARG(info));
	
	/* Make sure all flocks that have changed still fit in their snarfs. 
		 Add any that don't to myNewFlocks and return the table 
		 from their current locations to the newShepherds. */
	
	virtual void refitFlocks ();
	
	/* Release the supplied snarfHandler and destroy it. */
	
	virtual void releaseReadHandler (APTR(SnarfHandler) ARG(handler));
	
	/* Make sure that the shepherd or stub at that location actually points
		 at the real location for a shepherd.  This will resolve 
	forwarding pointers, 
		 but not instantiate any flocks. */
	
	virtual RPTR(FlockInfo) resolveLocation (APTR(FlockInfo) ARG(info));
	
  protected: /* protected: creation */

	
	SnarfPacker (APTR(Urdi) ARG(urdi), TCSJ);
	
  public: /* testing */

	
	virtual BooleanVar isFake ();
	
  private:
	CHKPTR(SnarfInfoHandler) mySnarfInfo;
	CHKPTR(Turtle) OR(NULL) myTurtle;
	Int32 myAllocationSnarf;
	CHKPTR(MuTable) OF2(IntegerPos,SnarfRecord) mySnarfMap;
	CHKPTR(SetTable) OF2(IntegerPos,FlockInfo) myFlocks;
	CHKPTR(IntegerTable) OF1(FlockInfo) myNewFlocks;
	IntegerVar myLastNewCount;
	IntegerVar myNewEstimate;
	CHKPTR(MuArray) OF1(Abraham) myDestroyedFlocks;
	UrdiView * myUrdiView;
	Urdi * myUrdi;
	CHKPTR(XcvrMaker) myXcvrMaker;
	CHKPTR(Cookbook) myBook;
	CHKPTR(Counter) myNextHash;
	IntegerVar myConsistentCount;
	BooleanVar myInsideCommit;
	IntegerVar myDestroyCount;
	CHKPTR(SanitationEngineer) myPurgeror;
	CHKPTR(LiberalPurgeror) myRepairer;

  /* ---------- Static Member variables (class vars) ----------- */
  private:
	
	static Int32 LRUCount;
/* Friends for class SnarfPacker */
friend class ResetCommit_Bomb;
friend class CBlockTrackingPacker;


};  /* end class SnarfPacker */


#ifdef USE_INLINE
#ifndef PACKERX_IXX
#include "packerx.ixx"
#endif /* PACKERX_IXX */


#endif /* USE_INLINE */


#endif /* PACKERX_HXX */

