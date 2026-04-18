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

#ifndef FAKEDSKP_HXX
#define FAKEDSKP_HXX


#ifndef TOFUX_HXX
#include "tofux.hxx"
#endif /* TOFUX_HXX */

#ifndef INTVARX_HXX
#include "intvarx.hxx"
#endif /* INTVARX_HXX */

#ifndef FAKEDSKP_OXX
#include "fakedskp.oxx"
#endif /* FAKEDSKP_OXX */


#ifndef DISKMANX_HXX
#include "diskmanx.hxx"
#endif /* DISKMANX_HXX */

#ifndef INITX_HXX
#include "initx.hxx"
#endif /* INITX_HXX */

#ifndef THUNKX_HXX
#include "thunkx.hxx"
#endif /* THUNKX_HXX */

#ifndef TURTLEX_HXX
#include "turtlex.hxx"
#endif /* TURTLEX_HXX */


#ifndef COOKBKX_OXX
#include "cookbkx.oxx"
#endif /* COOKBKX_OXX */

#ifndef COUNTERX_OXX
#include "counterx.oxx"
#endif /* COUNTERX_OXX */

#ifndef FLKINFOX_OXX
#include "flkinfox.oxx"
#endif /* FLKINFOX_OXX */

#ifndef XFRSPECX_OXX
#include "xfrspecx.oxx"
#endif /* XFRSPECX_OXX */


/*  */
/*  */




/* ************************************************************************ *
 * 
 *                    Class FakeDisk 
 *
 * ************************************************************************ */




	/* NO CLASS COMMENT */

class FakeDisk : public Thunk {

/* Attributes for class FakeDisk */
	CONCRETE(FakeDisk)
	COPY(FakeDisk,BootCuisine)
	NOT_A_TYPE(FakeDisk)
	AUTO_GC(FakeDisk)
  public: /* running */

	
	virtual void execute ();
	

	/* automatic 0-argument constructor */
  public:
	FakeDisk();
  private:
	CHKPTR(Category) myCategory;
};  /* end class FakeDisk */



/* ************************************************************************ *
 * 
 *                    Class FakePacker 
 *
 * ************************************************************************ */




	/* Most of the disk operations are just no-ops. */

class FakePacker : public DiskManager {

/* Attributes for class FakePacker */
	CONCRETE(FakePacker)
	AUTO_GC(FakePacker)
  public: /* creation */

	
	static RPTR(DiskManager) make ();
	
  public: /* transactions */

	
	virtual void beginConsistent (IntegerVar ARG(dirty));
	
	
	virtual void endConsistent (IntegerVar ARG(dirty));
	
	
	virtual BooleanVar insideCommit ();
	
	/* Flush everything out to disk and remove all purgeable imaged
		 objects from memory.  This doesn't clear the ShepherdMap table.  
		 This will have to be a weak table, and then the destruction of a 
		 shepherd or shepherdStub should remove it from myShepherdMap. */
	
	virtual void purge ();
	
	/* No shepherds are clean, so no-op. */
	
	virtual void purgeClean (BooleanVar ARG(noneLocked) = FALSE);
	
  public: /* shepherds */

	/* Queue destroy of the given flock.  dismantle it 
	immediately in the FakePacker. */
	
	virtual void destroyFlock (APTR(FlockInfo) ARG(info));
	
	/* The flock identified by token is Dirty! On some later 
	commit, write it to the disk. */
	
	virtual void diskUpdate (APTR(FlockInfo) OR(NULL) ARG(info));
	
	/* Tehre are no local data-structures. */
	/* info markDismantled. */
	
	virtual void dismantleFlock (APTR(FlockInfo) ARG(info));
	
	/* No prob. */
	
	virtual void dropFlock (Int32 ARG(token));
	
	/* Yeah. Right. */
	
	virtual void forgetFlock (APTR(FlockInfo) ARG(info));
	
	
	virtual RPTR(Turtle) getInitialFlock ();
	
	/* Shepherds use a sequence number for their hash.  Return the next one
		 and increment.  This should actually spread the hashes. */
	/* This actually needs to roll over the UInt32 limit. */
	
	virtual UInt32 nextHashForEqual ();
	
	/* There are now persistent pointers to the shepherd 
	represented by token. */
	
	virtual void rememberFlock (APTR(FlockInfo) ARG(info));
	
	/* Do nothing */
	
	virtual void storeAlmostNewShepherd (APTR(Abraham) ARG(shep));
	
	
	virtual void storeInitialFlock (
			APTR(Abraham) ARG(turtle), 
			APTR(XcvrMaker) ARG(protocol), 
			APTR(Cookbook) ARG(cookbook))
	;
	
	/* Shep just got created! On some later commit, assign it to a snarf 
		and write it to the disk. */
	
	virtual void storeNewFlock (APTR(Abraham) ARG(shep));
	
	
	virtual void storeTurtle (APTR(Turtle) ARG(turtle));
	
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
	
  protected: /* protected: create */

	
	FakePacker ();
	
  public: /* testing */

	
	virtual BooleanVar isFake ();
	
  public: /* internals */

	
	virtual void destroyAbandoned ();
	
  private:
	CHKPTR(Turtle) OR(NULL) myTurtle;
	UInt4 myCount;
};  /* end class FakePacker */



/* ************************************************************************ *
 * 
 *                    Class MockTurtle 
 *
 * ************************************************************************ */




	/* The MockTurtle is used with the FakePacker.  All it 
	provides is an Agenda */

class MockTurtle : public Turtle {

/* Attributes for class MockTurtle */
	CONCRETE(MockTurtle)
	LOCKED(MockTurtle)
	COPY(MockTurtle,DiskCuisine)
	AUTO_GC(MockTurtle)
  public: /* pseudo-constructor */

	
	static RPTR(Turtle) make (APTR(Category) ARG(category));
	
  public: /* accessing */

	
	virtual NOLOCK RPTR(Category) bootCategory ();
	
	
	virtual RPTR(Heaper) bootHeaper ();
	
	
	virtual RPTR(Cookbook) cookbook ();
	
	
	virtual RPTR(Counter) counter ();
	
	
	virtual NOLOCK RPTR(Agenda) OR(NULL) fetchAgenda ();
	
	
	virtual RPTR(XcvrMaker) protocol ();
	
	/* Right */
	
	virtual void saveBootHeaper (APTR(Heaper) ARG(boot));
	
	/* Right */
	
	virtual void setProtocol (APTR(XcvrMaker) ARG(xcvrMaker), APTR(Cookbook) ARG(book));
	
  protected: /* protected: creation */

	
	MockTurtle (APTR(Category) ARG(bootCategory), TCSJ);
	
  private:
	CHKPTR(Agenda) OR(NULL) myAgenda;
	CHKPTR(Category) myBootCategory;
};  /* end class MockTurtle */



#endif /* FAKEDSKP_HXX */

