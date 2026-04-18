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

#ifndef PACKERT_HXX
#define PACKERT_HXX


#ifndef TOFUX_HXX
#include "tofux.hxx"
#endif /* TOFUX_HXX */

#ifndef INTVARX_HXX
#include "intvarx.hxx"
#endif /* INTVARX_HXX */

#ifndef PACKERX_HXX
#include "packerx.hxx"
#endif /* PACKERX_HXX */

#ifndef PACKERT_OXX
#include "packert.oxx"
#endif /* PACKERT_OXX */


#ifndef BOOTPLNX_HXX
#include "bootplnx.hxx"
#endif /* BOOTPLNX_HXX */

#ifndef FLKINFOX_HXX
#include "flkinfox.hxx"
#endif /* FLKINFOX_HXX */

#ifndef NSCOTTYX_HXX
#include "nscottyx.hxx"
#endif /* NSCOTTYX_HXX */

#ifndef SHEPHX_HXX
#include "shephx.hxx"
#endif /* SHEPHX_HXX */

#ifndef THUNKX_HXX
#include "thunkx.hxx"
#endif /* THUNKX_HXX */


#ifndef COOKBKX_OXX
#include "cookbkx.oxx"
#endif /* COOKBKX_OXX */

#ifndef GRANMAPX_OXX
#include "granmapx.oxx"
#endif /* GRANMAPX_OXX */

#ifndef INTTABX_OXX
#include "inttabx.oxx"
#endif /* INTTABX_OXX */

#ifndef NXCVRX_OXX
#include "nxcvrx.oxx"
#endif /* NXCVRX_OXX */

#ifndef PARRAYX_OXX
#include "parrayx.oxx"
#endif /* PARRAYX_OXX */

#ifndef SETX_OXX
#include "setx.oxx"
#endif /* SETX_OXX */

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
 *                    Class DoublingFlock 
 *
 * ************************************************************************ */




	/* NO CLASS COMMENT */

class DoublingFlock : public Abraham {

/* Attributes for class DoublingFlock */
	CONCRETE(DoublingFlock)
	SHEPHERD_PATRIARCH(DoublingFlock,Abraham)
	COPY(DoublingFlock,DiskCuisine)
	EQ(DoublingFlock)
	LOCKED(DoublingFlock)
	NO_GC(DoublingFlock)
  public: /* creation */

	
	static RPTR(DoublingFlock) make (UInt32 ARG(hash));
	
	
	static RPTR(DoublingFlock) make (UInt32 ARG(hash), Int32 ARG(count));
	
  public: /* accessing */

	
	virtual NOLOCK Int32 count ();
	
	
	virtual void doDouble ();
	
  public: /* hooks: */

	
	virtual RECEIVE_HOOK void receiveTestFlock (APTR(Rcvr) ARG(rcvr));
	
	
	virtual SEND_HOOK void sendTestFlock (APTR(Xmtr) ARG(xmtr));
	
  public: /* printing */

	
	virtual void printOn (ostream& ARG(oo));
	
  public: /* creation */

	
	DoublingFlock (UInt32 ARG(hash), TCSJ);
	
	
	DoublingFlock (UInt32 ARG(hash), Int32 ARG(count));
	
  public: /* testing */

	
	virtual UInt32 contentsHash ();
	
  private:
	Int32 myCount;
};  /* end class DoublingFlock */



/* ************************************************************************ *
 * 
 *                    Class HashStream 
 *
 * ************************************************************************ */




	/* NO CLASS COMMENT */

class HashStream : public XnWriteStream {

/* Attributes for class HashStream */
	CONCRETE(HashStream)
	EQ(HashStream)
	NOT_A_TYPE(HashStream)
	NO_GC(HashStream)
  public: /* creation */

	
	static RPTR(XnWriteStream) make ();
	
  public: /* create */

	
	HashStream ();
	
  public: /* accessing */

	
	virtual void flush ();
	
	/* The accumulated hash */
	
	virtual UInt32 hash ();
	
	
	virtual void putByte (UInt32 ARG(byte));
	
	
	virtual void putData (APTR(UInt8Array) ARG(array));
	
	
	virtual void putStr (char * ARG(string));
	
  private:
	UInt32 myHash;
};  /* end class HashStream */



/* ************************************************************************ *
 * 
 *                    Class HonestAbeIniter 
 *
 * ************************************************************************ */



/* Initializers for HonestAbeIniter */




	/* NO CLASS COMMENT */

class HonestAbeIniter : public Thunk {

/* Attributes for class HonestAbeIniter */
	CONCRETE(HonestAbeIniter)
	COPY(HonestAbeIniter,BootCuisine)
	NOT_A_TYPE(HonestAbeIniter)
	AUTO_GC(HonestAbeIniter)

/* Initializers for HonestAbeIniter */


  public: /* accessing */

	
	static RPTR(BeGrandMap) fetchGrandMap ();
	
  public: /* running */

	
	virtual void execute ();
	

	/* automatic 0-argument constructor */
  public:
	HonestAbeIniter();
  private:
	CHKPTR(Category) myCategory;
	BooleanVar blastOnError;
	IntegerVar persistInterval;

  /* ---------- Static Member variables (class vars) ----------- */
  private:
	static GPTR(Connection) TheHonestConnection;
	static GPTR(BeGrandMap) TheHonestGrandMap;
};  /* end class HonestAbeIniter */



/* ************************************************************************ *
 * 
 *                    Class HonestAbePlan 
 *
 * ************************************************************************ */




	/* NO CLASS COMMENT */

class HonestAbePlan : public BootMaker {

/* Attributes for class HonestAbePlan */
	CONCRETE(HonestAbePlan)
	COPY(HonestAbePlan,BootCuisine)
	NOT_A_TYPE(HonestAbePlan)
	AUTO_GC(HonestAbePlan)
  public: /* accessing */

	
	virtual RPTR(Category) bootCategory ();
	
	
	virtual RPTR(Heaper) bootHeaper ();
	

	/* automatic 0-argument constructor */
  public:
	HonestAbePlan();
  private:
	CHKPTR(Category) myCategory;
};  /* end class HonestAbePlan */



/* ************************************************************************ *
 * 
 *                    Class Honestly 
 *
 * ************************************************************************ */




	/* NO CLASS COMMENT */

class Honestly : public Thunk {

/* Attributes for class Honestly */
	CONCRETE(Honestly)
	COPY(Honestly,BootCuisine)
	NOT_A_TYPE(Honestly)
	AUTO_GC(Honestly)
  public: /* running */

	
	virtual void execute ();
	

	/* automatic 0-argument constructor */
  public:
	Honestly();
  private:
	CHKPTR(Category) myCategory;
	BooleanVar blastOnError;
	IntegerVar persistInterval;
};  /* end class Honestly */



/* ************************************************************************ *
 * 
 *                    Class PairFlock 
 *
 * ************************************************************************ */




	/* NO CLASS COMMENT */

class PairFlock : public Abraham {

/* Attributes for class PairFlock */
	CONCRETE(PairFlock)
	SHEPHERD_PATRIARCH(PairFlock,Abraham)
	COPY(PairFlock,DiskCuisine)
	EQ(PairFlock)
	LOCKED(PairFlock)
	AUTO_GC(PairFlock)
  public: /* creation */

	
	static RPTR(PairFlock) make (APTR(Abraham) ARG(left), APTR(Abraham) ARG(right));
	
  public: /* accessing */

	
	virtual NOLOCK RPTR(Abraham) left ();
	
	
	virtual NOLOCK RPTR(Abraham) right ();
	
  public: /* creation */

	
	PairFlock (APTR(Abraham) ARG(left), APTR(Abraham) ARG(right));
	
  public: /* testing */

	
	virtual UInt32 contentsHash ();
	
  private:
	CHKPTR(Abraham) myLeft;
	CHKPTR(Abraham) myRight;
};  /* end class PairFlock */



/* ************************************************************************ *
 * 
 *                    Class TestFlockInfo 
 *
 * ************************************************************************ */




	/* Used in conjunction with the TestPacker. Keeps a hash of 
	the last contents that were written to disk. */

class TestFlockInfo : public FlockInfo {

/* Attributes for class TestFlockInfo */
	CONCRETE(TestFlockInfo)
	AUTO_GC(TestFlockInfo)
  public: /* pseudo constructors */

	/* index = UInt32Zero assert: 'Should have index 0'. */
	
	static RPTR(FlockInfo) forgotten (
			APTR(Abraham) ARG(shep), 
			Int32 ARG(snarfID), 
			Int32 ARG(index))
	;
	
	/* index = UInt32Zero assert: 'Should have index 0'. */
	
	static RPTR(FlockInfo) make (APTR(Abraham) ARG(shep), IntegerVar ARG(index));
	
	/* index = UInt32Zero assert: 'Should have index 0'. */
	
	static RPTR(FlockInfo) make (
			APTR(FlockInfo) ARG(info), 
			Int32 ARG(snarfID), 
			Int32 ARG(index))
	;
	
	
	static RPTR(FlockInfo) remembered (
			APTR(Abraham) ARG(shep), 
			Int32 ARG(snarfID), 
			Int32 ARG(index))
	;
	
  public: /* create */

	
	TestFlockInfo (
			APTR(Abraham) ARG(shep), 
			Int32 ARG(snarfID), 
			Int32 ARG(index), 
			UInt32 ARG(flags))
	;
	
	
	TestFlockInfo (
			APTR(Abraham) ARG(shep), 
			Int32 ARG(snarfID), 
			Int32 ARG(index), 
			Int32 ARG(flags), 
			Int32 ARG(size))
	;
	
  public: /* accessing */

	
	virtual void setContents (APTR(UInt8Array) ARG(bits));
	
	/* Update the contents hash and other information from the 
	current state of the shepherd. Return true if the HASH only 
	has changed since the last time. */
	
	virtual BooleanVar updateContentsInfo ();
	
  private:
	UInt32 myOldHash;
	UInt32 myPreviousHash;
	CHKPTR(UInt8Array) myOldContents;
	friend class FlockInfo;
};  /* end class TestFlockInfo */



/* ************************************************************************ *
 * 
 *                    Class TestPacker 
 *
 * ************************************************************************ */


/* exceptions: private: */

ORDER_BOMB(EndCommit, TestPacker * );

;



	/* Does not actually go to disk, but just tests that the 
	protocol is being followed correctly. Some of these tests may 
	make it into the real SnarfPacker, but some of them will 
	remain debugging tools. Most operations only do enough real 
	stuff to be able to check that they work.
	
	
	The TestPacker holds onto an IntegerTable of UInt8Arrays that 
	contain the disk representations of all the flocks.  It also holds 
	
	myDisk contains a UInt8Array for every flock that made it to 
	disk.  They are assigned sequential numbers.
	myNewFlocks contains the flockInfos for new flocks, and thus 
	contains the new flocks wimpily.
	myAlmostNewFlocks contains flocks that are under construction 
	but have not yet finished.
	myDestroyedFlocks contains flocks that will be destroyed upon 
	exiting the current consistent block.
	myChangedFlocks points strongly at flocks that must be 
	rewritten to disk.
	 */

class TestPacker : public DiskManager {

/* Attributes for class TestPacker */
	CONCRETE(TestPacker)
	AUTO_GC(TestPacker)
  public: /* pseudo constructors */

	
	static RPTR(DiskManager) make (BooleanVar ARG(blast), IntegerVar ARG(persistInterval));
	
  public: /* shepherds */

	/* Queue destroy of the given flock.  The destroy will 
	probably happen later. */
	
	virtual void destroyFlock (APTR(FlockInfo) ARG(info));
	
	
	virtual void diskUpdate (APTR(FlockInfo) ARG(info));
	
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
	
	/* Shep just got created! On some later commit, assign it to a snarf 
		and write it to the disk. */
	
	virtual void storeNewFlock (APTR(Abraham) ARG(shep));
	
  private: /* private: testing */

	
	virtual void checkNewFlockIndices ();
	
	
	virtual void committing (BooleanVar ARG(flag));
	
	/* Decrement the countdown and return its new value */
	
	virtual IntegerVar countDown ();
	
	
	virtual void mustBeInsideTransaction ();
	
	/* Check that I know about this shepherd */
	
	virtual void mustKnowShepherd (APTR(FlockInfo) ARG(info));
	
	
	virtual void mustNotBeCommitting ();
	
	
	virtual void resetCountDown ();
	
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
	
  private: /* private: streams */

	/* Send the snarf over a transmitter into a stream that just 
	counts the bytes put into it. */
	
	virtual Int32 computeSize (APTR(Abraham) ARG(flock));
	
	
	virtual RPTR(SpecialistRcvr) makeRcvr (APTR(XnReadStream) ARG(readStream));
	
	
	virtual RPTR(SpecialistXmtr) makeXmtr (APTR(XnWriteStream) ARG(writeStream));
	
	/* Get a read stream on the disk contents of the info */
	
	virtual RPTR(XnReadStream) readStream (APTR(FlockInfo) ARG(info));
	
	/* Get a write stream on the disk contents of the info */
	
	virtual RPTR(XnWriteStream) writeStream (APTR(FlockInfo) ARG(info));
	
  private: /* private: disk */

	
	virtual void assignSnarf (APTR(Abraham) ARG(shep));
	
	/* Rewrite all flocks that have changed in this snarf. */
	/* check that all changed flocks are in fact in myChangedFlocks */
	
	virtual void flushChanges ();
	
	/* The flock represented by info has changed.  Record it in the
		 bookkeeping data-structures.  This must be called by all things 
		 that affect whether the flock gets rewritten to disk. */
	
	virtual void recordUpdate (APTR(FlockInfo) ARG(info));
	
	/* do nothing for now */
	
	virtual void refitFlocks ();
	
  public: /* create */

	
	TestPacker (BooleanVar ARG(blast), IntegerVar ARG(persistInterval));
	
  public: /* internals */

	/* Compute a hash on the contents */
	
	virtual UInt32 computeHash (APTR(Abraham) ARG(flock));
	
  public: /* transactions */

	
	virtual void beginConsistent (IntegerVar ARG(dirty));
	
	
	virtual void endConsistent (IntegerVar ARG(dirty));
	
	
	virtual BooleanVar insideCommit ();
	
	
	virtual void makePersistent ();
	
	
	virtual void purge ();
	
	
	virtual void purgeClean (BooleanVar ARG(noneLocked) = FALSE);
	
  public: /* testing */

	
	virtual BooleanVar isFake ();
	
  private:
	UInt32 myNextHash;
	CHKPTR(Abraham) myInitialFlock;
	CHKPTR(IntegerTable) OF1(FlockInfo) myFlocks;
	CHKPTR(IntegerTable) OF1(Abraham) myChangedFlocks;
	CHKPTR(IntegerTable) OF1(Abraham) myDestroyedFlocks;
	CHKPTR(MuSet) OF1(Abraham) myAlmostNewFlocks;
	CHKPTR(IntegerTable) OF1(FlockInfo) myNewFlocks;
	CHKPTR(XcvrMaker) myXcvrMaker;
	IntegerVar myCountDown;
	IntegerVar myPersistInterval;
	CHKPTR(IntegerTable) OF1(UInt8Array) myDisk;
	CHKPTR(Cookbook) myBook;
	BooleanVar amCommitting;
	BooleanVar blastOnError;
/* Friends for class TestPacker */
friend class EndCommit_Bomb;


};  /* end class TestPacker */


#ifdef USE_INLINE
#ifndef PACKERT_IXX
#include "packert.ixx"
#endif /* PACKERT_IXX */


#endif /* USE_INLINE */


#endif /* PACKERT_HXX */

