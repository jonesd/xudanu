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

#ifndef SETP_HXX
#define SETP_HXX


#ifndef TOFUX_HXX
#include "tofux.hxx"
#endif /* TOFUX_HXX */

#ifndef INTVARX_HXX
#include "intvarx.hxx"
#endif /* INTVARX_HXX */

#ifndef SETX_HXX
#include "setx.hxx"
#endif /* SETX_HXX */

#ifndef SETP_OXX
#include "setp.oxx"
#endif /* SETP_OXX */


#ifndef CACHEX_OXX
#include "cachex.oxx"
#endif /* CACHEX_OXX */

#ifndef NXCVRX_OXX
#include "nxcvrx.oxx"
#endif /* NXCVRX_OXX */

#ifndef PARRAYX_OXX
#include "parrayx.oxx"
#endif /* PARRAYX_OXX */

#ifndef TABTOOLX_OXX
#include "tabtoolx.oxx"
#endif /* TABTOOLX_OXX */


/* This file group has no comment */
/*  */




/* ************************************************************************ *
 * 
 *                    Class EmptyImmuSet 
 *
 * ************************************************************************ */




	/* NO CLASS COMMENT */

class EmptyImmuSet : public ImmuSet {

/* Attributes for class EmptyImmuSet */
	CONCRETE(EmptyImmuSet)
	PSEUDO_COPY(EmptyImmuSet,XppCuisine)
	NOT_A_TYPE(EmptyImmuSet)
	NO_GC(EmptyImmuSet)
  public: /* rcvr pseudo constructor */

	
	static RPTR(Heaper) make (APTR(Rcvr) ARG(rcvr));
	
  public: /* enumerating */

	
	virtual IntegerVar count ();
	
	
	virtual RPTR(Stepper) stepper ();
	
	
	virtual RPTR(Heaper) theOne ();
	
  public: /* adding-removing */

	
	virtual RPTR(ImmuSet) with (APTR(Heaper) ARG(anElement));
	
	
	virtual RPTR(ImmuSet) without (APTR(Heaper) ARG(anElement));
	
  public: /* accessing */

	
	virtual BooleanVar hasMember (APTR(Heaper) ARG(someone));
	
	
	virtual BooleanVar isEmpty ();
	
	
	virtual BooleanVar isSubsetOf (APTR(ScruSet) ARG(another));
	
  public: /* operations */

	
	virtual RPTR(ImmuSet) intersect (APTR(ScruSet) ARG(another));
	
	
	virtual RPTR(ImmuSet) minus (APTR(ScruSet) ARG(another));
	
	
	virtual RPTR(ImmuSet) unionWith (APTR(ScruSet) ARG(another));
	
  public: /* conversion */

	
	virtual RPTR(MuSet) asMuSet ();
	
  public: /* unprotected for initer create */

	
	EmptyImmuSet ();
	
  public: /* creation */

	/* Don't destroy our single instance */
	
	virtual void destroy ();
	
  protected: /* protected: destruct */

	/* This object is a canonical single instance, so its 
	destructor should only be called after main has exited. */
	
	virtual void destruct ();
	

};  /* end class EmptyImmuSet */



/* ************************************************************************ *
 * 
 *                    Class HashSet 
 *
 * ************************************************************************ */




	/* 	The HashSet class is an implementation of a MuTable set 
	that can contain arbitrary Heapers.  It uses the hashForEqual 
	member function to get a hash value for the items contained 
	in the set.  The set establishes the equality of objects in 
	the set through the isEqual: function.
		
		The implemention of HashSet is straightforward.  There are 
	primitive tables used to store pointers to the stored items 
	(myHashEntries), and their corresponding hash values 
	(myHashValues).  The HashSet also maintain a current tally of 
	the number of items in the set.
		
		definition: preferred location - the location calculated 
	from item hashForEqual mod tableSize.
		
		The search routine first calculates the preferred location.  
	This is used as the first location in the myHashEntries table 
	to test for the presence of the item, and the search proceeds 
	forward (in a linear probe) from there.  If there is no 
	object at that position, the routine assumes the item is not 
	in the table.  If there is an item there, the first test is 
	to check if the item's hash matches the hash myHashValues at 
	that position.  If the match is successful, a full isEqual: 
	test is performed.  If the isEqual: test succeeds, the item 
	is present in the set.  If either test fails, the entry at 
	the desired location is tested to see if it is closer to its 
	own preferred location than the item (a test which 
	necessarily fails the first time).  If it is closer, the item 
	is not in the set.  (This extra test is what distinguishes an 
	ordered hash set from an ordinary hash set.  It often detects 
	the absense of an item well before an empty slot is 
	encountered, and the advantage becomes pronounced as the set 
	fills up.  Ordered hash sets with linear probe beat ordinary 
	hash sets with secondary clustering on misses (the big time 
	eater), yet they preserve linear probe's easy deletion.)
		
		On insertion to the set, the hash and probe sequence is 
	essentially the same as the search.  The main exception is 
	that on a hash collision, the item bumps down any item that 
	is no farther than its own preferred position.
		
		An example is perhaps in order:
		
		the set contains items a, b, and c in table locations 3, 4, 
	and 5.  Assume that a has location 2 as its preferred 
	location, while b and c both have location 4 as their 
	preferred location.  Now, if we attempt to add an item d to 
	the table, and item d were to have a preferred location of 3. 
	 Since 3 is already occupied by something that is already far 
	from its preferred location, we probe for a another location. 
	 At location 4, item d is displaced by one from its preferred 
	location.  Since b is in it's preferred location (4) d 
	replaces it, and we move item b down.  Item c is in location 
	5 because it had already been bumped from location 4 when b 
	was inserted previously.  B again ties with c, so it pushes 
	it out of location 5, replacing it there.  Item c will end up 
	in location 6.  This probe function minimizes the individual 
	displacement of hash misses, while keeping the most items in 
	their preferred locations.
		
		Note that, though the choice of which item to bump is 
	obvious when the distances from home are different, when they 
	are equal we could have given preference to either the new or 
	the old item.  We chose to put the new item closer to its 
	preferred location, on the assumption that things entered 
	recently are more likely to be looked up than things entered long ago.
		
	This algorithm was derived from a short discussion with 
	Michael McClary (probably completely missing his intended 
	design - all mistakes are mine -- heh).
	
	(Unfortunately, I wasn't clear in the discussion.  Since hugh 
	was unavailable when I discovered this, I've taken the 
	opportunity to practice with Smalltalk and corrected both the 
	explanation and the code rather than sending him a 
	clarification. -- michael) */

class HashSet : public MuSet {

/* Attributes for class HashSet */
	DEFERRED(HashSet)
	NO_GC(HashSet)
  public: /* pseudo constructors */

	
	static RPTR(HashSet) make ();
	
	
	static RPTR(HashSet) make (APTR(Heaper) ARG(something));
	
	
	static RPTR(HashSet) make (IntegerVar ARG(someSize));
	
  public: /* accessing */

	
	virtual BooleanVar hasMember (APTR(Heaper) ARG(someone)) DEFERRED_FUNC;
	
	
	virtual BooleanVar isEmpty () DEFERRED_FUNC;
	
  public: /* creation */

	
	virtual RPTR(ScruSet) copy () DEFERRED_FUNC;
	
  public: /* enumerating */

	
	virtual IntegerVar count () DEFERRED_FUNC;
	
	
	virtual RPTR(Stepper) stepper () DEFERRED_FUNC;
	
	
	virtual RPTR(Heaper) theOne () DEFERRED_FUNC;
	
  public: /* adding-removing */

	
	virtual void introduce (APTR(Heaper) ARG(anElement)) DEFERRED_SUBR;
	
	
	virtual void remove (APTR(Heaper) ARG(anElement)) DEFERRED_SUBR;
	
	/* Add anElement to my set of members.  No semantic effect if 
	anElement is already a member. */
	
	virtual void store (APTR(Heaper) ARG(anElement)) DEFERRED_SUBR;
	
	/* make anElement no longer be one of my members.  No 
	semantic effect if it already isn't a member. */
	
	virtual void wipe (APTR(Heaper) ARG(anElement)) DEFERRED_SUBR;
	
  public: /* conversion */

	
	virtual RPTR(ImmuSet) asImmuSet ();
	
	
	virtual RPTR(MuSet) asMuSet ();
	
  private: /* private: testing access */

	
	virtual void printInternals (ostream& ARG(oo)) DEFERRED_SUBR;
	
  private: /* private: enumerating */

	
	virtual RPTR(Stepper) immuStepper ();
	

	/* automatic 0-argument constructor */
  public:
	HashSet();

/* Friends for class HashSet */
/* friends for class HashSet */
friend class HashSetTester;


};  /* end class HashSet */



/* ************************************************************************ *
 * 
 *                    Class   ActualHashSet 
 *
 * ************************************************************************ */



/* Initializers for ActualHashSet */







	/* NO CLASS COMMENT */

class ActualHashSet : public HashSet {

/* Attributes for class ActualHashSet */
	CONCRETE(ActualHashSet)
	COPY(ActualHashSet,XppCuisine)
	AUTO_GC(ActualHashSet)

/* Initializers for ActualHashSet */



friend class INIT_TIME_NAME(ActualHashSet,initTimeNonInherited);

  public: /* pseudo constructors */

	
	static RPTR(ActualHashSet) make ();
	
	
	static RPTR(ActualHashSet) make (APTR(Heaper) ARG(something));
	
	
	static RPTR(ActualHashSet) make (IntegerVar ARG(someSize));
	
  public: /* testing */

	
	virtual UInt32 contentsHash ();
	
  public: /* accessing */

	
	virtual IntegerVar count ();
	
	
	virtual BooleanVar hasMember (APTR(Heaper) ARG(someone));
	
	
	virtual BooleanVar isEmpty ();
	
  public: /* creation */

	
	virtual RPTR(ScruSet) copy ();
	
  protected: /* protected: creation */

	
	ActualHashSet (Int32 ARG(newTally), APTR(SharedPtrArray) ARG(entries));
	
	
	ActualHashSet (
			Int32 ARG(newTally), 
			APTR(UInt32Array) ARG(hashValues), 
			APTR(SharedPtrArray) ARG(entries))
	;
	
	
	virtual void destruct ();
	
  public: /* enumerating */

	
	virtual RPTR(Stepper) stepper ();
	
	
	virtual RPTR(Heaper) theOne ();
	
  public: /* operations */

	/* union equivalent */
	
	virtual void storeAll (APTR(ScruSet) ARG(other));
	
	/* Sort of minus.  Wipe from myself all elements from other.
		Turn myself into my current self minus other. */
	/* Maintainance note: this duplicates some code in wipe: for 
	efficiency */
	
	virtual void wipeAll (APTR(ScruSet) ARG(other));
	
  public: /* adding-removing */

	
	virtual void introduce (APTR(Heaper) ARG(anElement));
	
	
	virtual void remove (APTR(Heaper) ARG(anElement));
	
	/* maintainance note: storeAll: has a copy of the code 
	starting at self hashFind:... for efficiency. */
	
	virtual void store (APTR(Heaper) ARG(anElement));
	
	
	virtual void wipe (APTR(Heaper) ARG(anElement));
	
  private: /* private: housekeeping */

	/* If my contents are shared, and I'm about to change them, 
	make a copy of them. */
	
	INLINE void aboutToWrite ();
	
	
	virtual void actualAboutToWrite ();
	
	
	virtual void checkSize (Int32 ARG(byAmount));
	
	
	virtual Int32 distanceFromHome (
			UInt32 ARG(loc), 
			UInt32 ARG(home), 
			UInt32 ARG(modulus))
	;
	
  private: /* private: hash resolution */

	/* Starting at the item's preferred location and iterating 
	(not recurring!) around the set's
		 storage while the slots we're examining are occupied...
		   If the current slot's occupant is the target item, return a hit 
		   if the current occupant is closer to it's preferred 
	location, return a miss.
		   If we've gone all the way around, return a miss. */
	
	virtual Int32 hashFind (APTR(Heaper) ARG(item));
	
	/* Remove the indicated item from the set.
		 Iteratively (not recursively!) move other items up until 
	one is NULL or happier where it is. */
	
	virtual void hashRemove (UInt32 ARG(from));
	
	/* Starting at the new item's preferred location and 
	iterating (not recurring!) around the set's storage while the 
	slots we're examining are occupied.  (Caller assures us there 
	IS a vacant slot) if the current occupant is no closer to 
	it's preferred location, exchange it with the 'new' one.  
	Bail out if the current occupant IS the new one.
		 Store the currently 'new' item. */
	
	virtual void hashStore (
			APTR(Heaper) ARG(item), 
			APTR(UInt32Array) ARG(values), 
			APTR(PtrArray) ARG(entries))
	;
	
  private: /* private: testing access */

	
	virtual UInt32 entryTableSize ();
	
	/* This method is for regression testing. */
	
	virtual void printInternals (ostream& ARG(oo));
	
  public: /* hooks: */

	/* Make myHashEntries large enough that we won't grow. */
	
	virtual RECEIVE_HOOK void receiveHashSet (APTR(Rcvr) ARG(rcvr));
	
	/* This currently doesn't take advantage of the optimizations 
	in TableEntries.  It should. */
	
	virtual SEND_HOOK void sendHashSet (APTR(Xmtr) ARG(xmtr));
	
  private:
	NOCOPY CHKPTR(UInt32Array) myHashValues;
	NOCOPY CHKPTR(SharedPtrArray) myHashEntries;
	Int32 myTally;

  /* ---------- Static Member variables (class vars) ----------- */
  private:
	
	
	
	
	
	
	
	
	
	
	
/* Friends for class ActualHashSet */
/* friends for class ActualHashSet */
friend class HashSetTester;


};  /* end class ActualHashSet */



/* ************************************************************************ *
 * 
 *                    Class HashSetStepper 
 *
 * ************************************************************************ */



/* Initializers for HashSetStepper */







	/* NO CLASS COMMENT */

class HashSetStepper : public Stepper {

/* Attributes for class HashSetStepper */
	CONCRETE(HashSetStepper)
	NOT_A_TYPE(HashSetStepper)
	AUTO_GC(HashSetStepper)

/* Initializers for HashSetStepper */



friend class INIT_TIME_NAME(HashSetStepper,initTimeNonInherited);

  public: /* pseudo constructors */

	
	static RPTR(Stepper) make (APTR(SharedPtrArray) ARG(elements));
	
  public: /* accessing */

	
	virtual WPTR(Heaper) fetch ();
	
	
	virtual BooleanVar hasValue ();
	
	
	virtual void step ();
	
  protected: /* protected: destruct */

	
	virtual void destruct ();
	
  protected: /* protected: creation */

	
	HashSetStepper (APTR(SharedPtrArray) ARG(elements), Int32 ARG(current));
	
  public: /* creation */

	
	virtual RPTR(Stepper) copy ();
	
	
	virtual void destroy ();
	
  private: /* private: */

	
	virtual void verifyEntry ();
	
  private:
	CHKPTR(SharedPtrArray) myElements;
	Int32 myCurrent;

  /* ---------- Static Member variables (class vars) ----------- */
  private:
	static GPTR(InstanceCache) SomeSteppers;
};  /* end class HashSetStepper */



/* ************************************************************************ *
 * 
 *                    Class ImmuSetOnMu 
 *
 * ************************************************************************ */




	/* NO CLASS COMMENT */

class ImmuSetOnMu : public ImmuSet {

/* Attributes for class ImmuSetOnMu */
	CONCRETE(ImmuSetOnMu)
	NOT_A_TYPE(ImmuSetOnMu)
	COPY(ImmuSetOnMu,XppCuisine)
	AUTO_GC(ImmuSetOnMu)
  public: /* creation */

	
	static RPTR(ImmuSet) make (APTR(MuSet) ARG(aSet));
	
  public: /* accessing */

	
	virtual BooleanVar hasMember (APTR(Heaper) ARG(someone));
	
	
	virtual BooleanVar isEmpty ();
	
	
	virtual BooleanVar isSubsetOf (APTR(ScruSet) ARG(another));
	
  public: /* enumerating */

	
	virtual IntegerVar count ();
	
	
	virtual RPTR(Stepper) stepper ();
	
	
	virtual RPTR(Heaper) theOne ();
	
  public: /* operations */

	
	virtual RPTR(ImmuSet) intersect (APTR(ScruSet) ARG(another));
	
	
	virtual RPTR(ImmuSet) minus (APTR(ScruSet) ARG(another));
	
	
	virtual RPTR(ImmuSet) unionWith (APTR(ScruSet) ARG(another));
	
  public: /* adding-removing */

	
	virtual RPTR(ImmuSet) with (APTR(Heaper) ARG(anElement));
	
	
	virtual RPTR(ImmuSet) without (APTR(Heaper) ARG(anElement));
	
  public: /* conversion */

	
	virtual RPTR(MuSet) asMuSet ();
	
  protected: /* protected: create */

	/* this set should be a copy for my own use */
	/* the pseudo constructor enforces this */
	
	ImmuSetOnMu (APTR(MuSet) ARG(fromSet), TCSJ);
	
	
	virtual void destruct ();
	
  private:
	CHKPTR(MuSet) setInternal;
};  /* end class ImmuSetOnMu */



/* ************************************************************************ *
 * 
 *                    Class TinyImmuSet 
 *
 * ************************************************************************ */




	/* This is an efficient implementation of ImmuSets for zero 
	and one element sets. */

class TinyImmuSet : public ImmuSet {

/* Attributes for class TinyImmuSet */
	CONCRETE(TinyImmuSet)
	NOT_A_TYPE(TinyImmuSet)
	COPY(TinyImmuSet,XppCuisine)
	AUTO_GC(TinyImmuSet)
  public: /* create */

	
	static RPTR(ImmuSet) make (APTR(Heaper) ARG(aHeaper));
	
  protected: /* protected: creation */

	/* Initialize a singleton immuset */
	
	TinyImmuSet (APTR(Heaper) ARG(only), TCSJ);
	
  public: /* enumerating */

	
	virtual IntegerVar count ();
	
	
	virtual RPTR(Stepper) stepper ();
	
	
	virtual RPTR(Heaper) theOne ();
	
  public: /* adding-removing */

	
	virtual RPTR(ImmuSet) with (APTR(Heaper) ARG(anElement));
	
	
	virtual RPTR(ImmuSet) without (APTR(Heaper) ARG(anElement));
	
  public: /* accessing */

	
	virtual BooleanVar hasMember (APTR(Heaper) ARG(someone));
	
	
	virtual BooleanVar isEmpty ();
	
	
	virtual BooleanVar isSubsetOf (APTR(ScruSet) ARG(another));
	
  public: /* operations */

	
	virtual RPTR(ImmuSet) intersect (APTR(ScruSet) ARG(another));
	
	
	virtual RPTR(ImmuSet) minus (APTR(ScruSet) ARG(another));
	
	
	virtual RPTR(ImmuSet) unionWith (APTR(ScruSet) ARG(another));
	
  public: /* conversion */

	
	virtual RPTR(MuSet) asMuSet ();
	
  private:
	CHKPTR(Heaper) elementInternal;
};  /* end class TinyImmuSet */


#ifdef USE_INLINE
#ifndef SETP_IXX
#include "setp.ixx"
#endif /* SETP_IXX */


#endif /* USE_INLINE */


#endif /* SETP_HXX */

