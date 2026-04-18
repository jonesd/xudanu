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

#ifndef FLKINFOX_HXX
#define FLKINFOX_HXX


#ifndef TOFUX_HXX
#include "tofux.hxx"
#endif /* TOFUX_HXX */

#ifndef INTVARX_HXX
#include "intvarx.hxx"
#endif /* INTVARX_HXX */

#ifndef FLKINFOX_OXX
#include "flkinfox.oxx"
#endif /* FLKINFOX_OXX */


#ifndef INITX_HXX
#include "initx.hxx"
#endif /* INITX_HXX */


#ifndef PRIMTABX_OXX
#include "primtabx.oxx"
#endif /* PRIMTABX_OXX */

#ifndef SHEPHX_OXX
#include "shephx.oxx"
#endif /* SHEPHX_OXX */


/*  */
/*  */




/* ************************************************************************ *
 * 
 *                    Class FlockLocation 
 *
 * ************************************************************************ */




	/* Represent the location of a flock on disk.  This ID of the 
	snarf in which the flock is contained, and the index of the 
	flock within that snarf.  This information side-effect free, 
	even in subclasses. */

class FlockLocation : public Heaper {

/* Attributes for class FlockLocation */
	CONCRETE(FlockLocation)
	EQ(FlockLocation)
	NO_GC(FlockLocation)
  public: /* creation */

	
	static RPTR(FlockLocation) make (Int32 ARG(snarfID), Int32 ARG(index));
	
  protected: /* protected: accessing */

	/* This is used to set the index when a flock is bumped from 
	its snarf and forwarded by
		way of the new flocks table */
	
	virtual void index (Int32 ARG(anIndex));
	
  public: /* accessing */

	
	INLINE Int32 index ();
	
	
	INLINE Int32 snarfID ();
	
  public: /* creation */

	
	FlockLocation (Int32 ARG(snarfID), Int32 ARG(index));
	
  public: /* printing */

	
	virtual void printOn (ostream& ARG(oo));
	
  private:
	Int32 mySnarfID;
	Int4 myIndex;
};  /* end class FlockLocation */



/* ************************************************************************ *
 * 
 *                    Class   FlockInfo 
 *
 * ************************************************************************ */



/* Initializers for FlockInfo */




	/* Contains all the information the packer needs to know 
	about the flock on disk (except forwarder stuff).  The packer 
	knows about forwarders by having several FlockInfo objects 
	for the same flock.  We should consider having a separate 
	class for forward information that does not contain the flags 
	and the oldSize.
	
	myOldSize - this is the size of the flock on disk as of the 
	last commit.  If this is zero, it is uninitialized.  This is 
	used to refitting without bringing in the snarf for this flock.
	
	myFlags - keeps track of whether the receive is a new flock 
	(isn't on disk yet), is forgotten, is in the process is 
	fchanging its forggten state (isChanging), and is Update 
	(contents have changed). */

class FlockInfo : public FlockLocation {

/* Attributes for class FlockInfo */
	CONCRETE(FlockInfo)
	NO_GC(FlockInfo)

/* Initializers for FlockInfo */


  public: /* creation */

	
	static RPTR(FlockInfo) forgotten (
			APTR(Abraham) ARG(shep), 
			Int32 ARG(snarfID), 
			Int32 ARG(index))
	;
	
	/* Make a ShepherdLocation for a new shepherd. Index is the index into 
		the new flocks table in the snarfPacker. The newmask indicates 
		that the index is into the newFlocks table rather than a snarf. */
	
	static RPTR(FlockInfo) make (APTR(Abraham) ARG(shep), IntegerVar ARG(index));
	
	/* Make a flockInfo to a new location for the same shepherd.  
	Clear the new flag, and keep the rest the same. */
	
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
	
  public: /* debugging tools */

	
	static BooleanVar testContentsDirty (APTR(FlockInfo) ARG(info));
	
	
	static BooleanVar testForgotten (APTR(FlockInfo) ARG(info));
	
  public: /* testing flags */

	
	static INLINE UInt32 contentsDirty ();
	
	
	static INLINE UInt32 destroyed ();
	
	
	static INLINE UInt32 dismantled ();
	
	
	static INLINE UInt32 forgottenMask ();
	
	
	static INLINE UInt32 forgottenStateDirty ();
	
	
	static INLINE UInt32 forwarded ();
	
	
	static INLINE UInt32 isNewMask ();
	
	
	static INLINE UInt32 shepNullInPersistent ();
	
  public: /* flock tables */

	
	static RPTR(FlockInfo) getInfo (Int32 ARG(index));
	
	
	static void removeInfo (Int32 ARG(token));
	
  public: /* testing */

	/* Return true if my shepherd has changed and informed the 
	SnarfPacker. */
	
	virtual BooleanVar isContentsDirty ();
	
	/* Return true if our shepherd has received destroy */
	
	virtual BooleanVar isDestroyed ();
	
	/* Return true if anything about my flock is changing 
	(including if the flock is new). */
	
	virtual BooleanVar isDirty ();
	
	/* Return true if our shepherd has been dismantled */
	
	virtual BooleanVar isDismantled ();
	
	/* Return true if my Shepherd's new state is it should be forgotten. */
	
	virtual BooleanVar isForgotten ();
	
	/* Return true if the shepherd I describe is changing between 
	being forgotten and being remembered. */
	
	virtual BooleanVar isForgottenStateDirty ();
	
	/* Return true if my shepherd has been forwarded. */
	
	virtual BooleanVar isForwarded ();
	
	/* Return true if the associated flock is new.  If so, myIndex
		 is an offset into the new flocks table inside the SnarfPacker. */
	
	virtual BooleanVar isNew ();
	
	/* Return true if my shepherd was forgotten after the last commit. */
	
	virtual BooleanVar wasForgotten ();
	
	/* Return true if our shepherd pointer was NULL in makePersistent */
	
	virtual BooleanVar wasShepNullInPersistent ();
	
  public: /* accessing */

	/* Reset my contentsDirty flag.  This is primarily used to 
	know when a flock has
		 changed again after some info has been computed from it. */
	
	virtual void clearContentsDirty ();
	
	/* A write to the disk has happened.  Commit all the changes 
	in the flags. */
	
	virtual void commitFlags ();
	
	
	virtual Int32 flags ();
	
	
	virtual UInt4 flockHash ();
	
	/* As a freshly forwarded flock, I'll be treated as new for a while. */
	
	virtual void forward (Int32 ARG(index));
	
	/* Set my contentsDirty flag.  Return false if I was already 
	dirty (in either way). */
	
	virtual BooleanVar markContentsDirty ();
	
	/* Set my shepNull flag. */
	
	virtual void markDestroyed ();
	
	/* Set my Dismantled flag.  BLAST if already set. */
	
	virtual void markDismantled ();
	
	/* Set my Forgotten flag.  Return false if I was already dirty. */
	
	virtual BooleanVar markForgotten ();
	
	/* Clear my Forgotten flag.  Return false if I was already dirty. */
	
	virtual BooleanVar markRemembered ();
	
	/* Set my shepNull flag. */
	
	virtual void markShepNull ();
	
	
	virtual Int32 oldSize ();
	
	
	virtual void setSize (Int32 ARG(size));
	
  public: /* tokens */

	
	virtual RPTR(Abraham) fetchShepherd ();
	
	
	virtual RPTR(Abraham) getShepherd ();
	
	/* Register this info as the best known informatino about the flock. */
	
	virtual void registerInfo ();
	
	
	virtual Int32 token ();
	
  public: /* create */

	
	FlockInfo (
			APTR(Abraham) ARG(shep), 
			Int32 ARG(snarfID), 
			Int32 ARG(index), 
			Int32 ARG(flags), 
			Int32 ARG(size))
	;
	
  public: /* printing */

	
	virtual void printOn (ostream& ARG(oo));
	
  private:
	UInt4 myFlockHash;
	Int32 myToken;
	UInt32 myFlags;
	Int32 myOldSize;

  /* ---------- Static Member variables (class vars) ----------- */
  private:
	
/* Friends for class FlockInfo */
	friend UInt4  contentsDirty ();
	friend UInt4  forgottenMask ();
	friend UInt4  forgottenStateDirty ();
	friend UInt4  isNewMask ();



};  /* end class FlockInfo */


#ifdef USE_INLINE
#ifndef FLKINFOX_IXX
#include "flkinfox.ixx"
#endif /* FLKINFOX_IXX */


#endif /* USE_INLINE */


#endif /* FLKINFOX_HXX */

