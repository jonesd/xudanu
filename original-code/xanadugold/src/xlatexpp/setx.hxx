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

#ifndef SETX_HXX
#define SETX_HXX


#ifndef TOFUX_HXX
#include "tofux.hxx"
#endif /* TOFUX_HXX */

#ifndef INTVARX_HXX
#include "intvarx.hxx"
#endif /* INTVARX_HXX */

#ifndef SETX_OXX
#include "setx.oxx"
#endif /* SETX_OXX */


#ifndef INITX_HXX
#include "initx.hxx"
#endif /* INITX_HXX */

#ifndef STEPPERX_HXX
#include "stepperx.hxx"
#endif /* STEPPERX_HXX */


#ifndef PARRAYX_OXX
#include "parrayx.oxx"
#endif /* PARRAYX_OXX */

#ifndef SETP_OXX
#include "setp.oxx"
#endif /* SETP_OXX */


/* This file group has no comment */
/* This group of files represents the Set type of collections for 
X++.  There are 3
basic categories:
	 ScruSet - which is read-only but is not guaranteed to not change,
	 ImmuSet - a set which is guaranteed not to change once constructed, and
	 MuSet - a set which has a protocol to allow it to be changed.
 */
/* xpp class */




/* ************************************************************************ *
 * 
 *                    Class ScruSet 
 *
 * ************************************************************************ */


/* exceptions: exceptions */

PROBLEM_LIST(NotInSetFilter,1,(NotInSet));



	/* X++ has three basic kinds of collection classes.  Tables, 
	Sets and XuRegions.  XuRegions are not-necessarily-discrete 
	collections of positions, and are documented in the space 
	module.  Sets and Tables are both discrete and finite, and 
	similar in many ways.  Both originate in a three-way type 
	distinction between:
		
		ScruX  --  The protocol for examining one.  I.e., it is *Scru*table
			ImmuX  --  The contract guarantees that the set or table 
	you're looking at won't change (though the things it contains 
	may change)
			MuX  --  Additional protocol for changing it.
			
		Concrete classes may be a subclass of any of the above.  It 
	makes sense to have a concrete subclass of ScruX which isn't 
	a subclass of either MuX or ImmuX when, for example, it 
	represents a tracking, filtered view of some other set which 
	is itself changing.  All kinds of collection can be iterated 
	over when appropriate using Steppers--our basic iteration 
	abstraction (see Stepper).
		
		Immu's are sort of like Stamps -- they represent a 
	particular state a colection can have.  Mu's are sort of like 
	Berts -- they represent a continuing collection identity 
	which can change its current state.
		
		Sets are pure collections--their contents are just a set of 
	Heapers.  Sets (as opposed to tables) do not provide any 
	organization of these contents. */

class ScruSet : public Heaper {

/* Attributes for class ScruSet */
	DEFERRED(ScruSet)
	NO_GC(ScruSet)
  public: /* testing */

	
	virtual UInt32 actualHashForEqual ();
	
	/* Returns whether the two ScruSets have exactly the same set 
	of elements at the moment.
		'a->contentsEqual(b)' is equivalent to 
		'a->asImmuSet()->isEqual(b->asImmuSet())'. */
	
	virtual BooleanVar contentsEqual (APTR(ScruSet) ARG(other));
	
	/* Has the same relationship to contentsEqual that 
	hashForEqual has to isEqual. 
		I.e., if 'a->contentsEqual (b)', then 'a->contentsHash() == 
	b->contentsHash()'. 
		The same complex caveats apply as to the stability and 
	portability of the 
		hash values as apply for hashForEqual. */
	
	virtual UInt32 contentsHash ();
	
	/* Is someone a member of the set now? */
	
	virtual BooleanVar hasMember (APTR(Heaper) ARG(someone)) DEFERRED_FUNC;
	
	/* tell whether they have any points in common */
	/* subclasses can override for efficiency */
	
	virtual BooleanVar intersects (APTR(ScruSet) ARG(other));
	
	/* Whether it currently has any elements */
	
	virtual BooleanVar isEmpty () DEFERRED_FUNC;
	
	
	virtual BooleanVar isEqual (APTR(Heaper) ARG(other)) DEFERRED_FUNC;
	
	/* Whether another currently has all my elements */
	
	virtual BooleanVar isSubsetOf (APTR(ScruSet) ARG(another));
	
  public: /* creation */

	/* A new one whose initial state is my current state, but 
	that doesn't track 
		changes. Note that there is no implication that these can be 
	'destroy'ed 
		separately, because (for example) an ImmuSet just returns itself */
	
	virtual RPTR(ScruSet) copy () DEFERRED_FUNC;
	
  public: /* conversion */

	/* The elements in the set in an array, in some random order */
	
	virtual RPTR(PtrArray) asArray ();
	
	/* Return an immu snapshot of my current state. Should 
	probably be done with a 
		Converter rather than with a message (for the reasons listed 
	in the Converter 
		class comment). In terms of the Stamp/Bert analogy mentioned 
	in the class 
		comment, asImmuSet is like asking for the current Stamp. */
	
	virtual RPTR(ImmuSet) asImmuSet () DEFERRED_FUNC;
	
	/* Return a Mu whose initial state is the same as my current 
	state, but which 
		will now deviate independently of me. In terms of the 
	Stamp/Bert analogy 
		mentioned in the class comment, asMuSet is like asking for a 
	new Bert starting 
		on the current Stamp. */
	
	virtual RPTR(MuSet) asMuSet () DEFERRED_FUNC;
	
  public: /* printing */

	
	virtual void printOn (ostream& ARG(oo));
	
	
	virtual void printOnWithSimpleSyntax (
			ostream& ARG(oo), 
			char * ARG(open), 
			char * ARG(sep), 
			char * ARG(close))
	;
	
	/* For example, if we have the set '{a, b, c}' and we print it with 
		'p->printOnWithSyntax(oo, "<<", "; ", ">>");', we get '<<a; 
	b; c>>'.  This is a convenient little hack
		for printing with all sorts of separators and brackets. */
	
	virtual void printOnWithSyntax (
			ostream& ARG(oo), 
			char * ARG(open), 
			char * ARG(sep), 
			char * ARG(close), 
			BooleanVar ARG(fullPrint) = FALSE)
	;
	
  public: /* enumerating */

	/* How many elements are currently in the set.  Being a set, 
	if the same element is put into the set twice,
		it is only in the set once.  'Same' above is according to 
	'isEqual'. */
	
	virtual IntegerVar count () DEFERRED_FUNC;
	
	/* Returns a stepper which will enumerate all the elements of 
	the set in some unspecified order */
	
	virtual RPTR(Stepper) stepper () DEFERRED_FUNC;
	
	/* Iff I contain exactly one member, return it.  Otherwise BLAST.
		The idea for this message is taken from the THE function of ONTIC
		(reference McAllester) */
	
	virtual RPTR(Heaper) theOne ();
	

	/* automatic 0-argument constructor */
  public:
	ScruSet();

};  /* end class ScruSet */



/* ************************************************************************ *
 * 
 *                    Class   ImmuSet 
 *
 * ************************************************************************ */



/* Initializers for ImmuSet */







	/* ImmuSets are ScruSets which are guaranteed never to 
	change.  ImmuSets correspond to the mathematical notion of a 
	finite set of elements, except of course that here the 
	elements can be any valid X++ object.  Just like mathematical 
	sets, two are equal (according to isEqual) iff they have the 
	same elements.  Just because the set cannot change, that 
	doesn't prevent any of the members from undergoing state change.
		
		ImmuSets implement some additional protocol to make new sets 
	out of old ones according to the familiar set theoretic 
	operators (like intersect).  XuRegions are much like ImmuSets 
	of Positions except that they aren't necessarily finite or 
	even enumerable.  XuRegions implement a similar protocol, but 
	aren't polymorphic with ImmuSets.  */

class ImmuSet : public ScruSet {

/* Attributes for class ImmuSet */
	DEFERRED(ImmuSet)
	NO_GC(ImmuSet)

/* Initializers for ImmuSet */



friend class INIT_TIME_NAME(ImmuSet,initTimeNonInherited);

  protected: /* protected: pseudo constructors */

	/* This is for ImmuSet subclasses to produce results from 
	temporary MuSets.
		The difference between this and ImmuSet make.MuSet: is that 
	this doesn't make a copy
		of the MuSet when making an ImmuSetOnMu. */
	
	static RPTR(ImmuSet) from (APTR(MuSet) ARG(set));
	
  public: /* pseudo constructors */

	
	static INLINE RPTR(ImmuSet) make ();
	
	
	static RPTR(ImmuSet) make (APTR(MuSet) ARG(set));
	
	/* A single element ImmuSet */
	
	static RPTR(ImmuSet) newWith (APTR(Heaper) ARG(value));
	
  public: /* accessing */

	
	virtual BooleanVar hasMember (APTR(Heaper) ARG(someone)) DEFERRED_FUNC;
	
	
	virtual BooleanVar isEmpty () DEFERRED_FUNC;
	
  public: /* operations */

	/* Regular set intersection.  Return an ImmuSet containing 
	only those objects which are members of 
		both sets */
	
	virtual RPTR(ImmuSet) intersect (APTR(ScruSet) ARG(another)) DEFERRED_FUNC;
	
	/* Return an ImmuSet containing those of my members which 
	aren't members of 'another' */
	
	virtual RPTR(ImmuSet) minus (APTR(ScruSet) ARG(another)) DEFERRED_FUNC;
	
	/* Return an ImmuSet containing those objects with are 
	members of either of us */
	
	virtual RPTR(ImmuSet) unionWith (APTR(ScruSet) ARG(another)) DEFERRED_FUNC;
	
  public: /* adding-removing */

	/* 'set->with (anElement)' means the same as 'set->unionWith 
	(immuSet (anElement))'.
		It returns an ImmuSet with all my members and having 
	anElement as a member.
		If anElement is a member of me, then the result is identical to me. */
	
	virtual RPTR(ImmuSet) with (APTR(Heaper) ARG(anElement)) DEFERRED_FUNC;
	
	/* 'set->without (anElement)' means the same as 'set->minus 
	(immuSet (anElement))'.
		It returns an ImmuSet with all my members except anElement.  
	If anElement isn't already a member,
		then the result is identical to me. */
	
	virtual RPTR(ImmuSet) without (APTR(Heaper) ARG(anElement)) DEFERRED_FUNC;
	
  public: /* creation */

	/* don't need to actually make a copy, as this is immutable */
	
	virtual RPTR(ScruSet) copy ();
	
  public: /* conversion */

	
	virtual RPTR(ImmuSet) asImmuSet ();
	
	
	virtual RPTR(MuSet) asMuSet () DEFERRED_FUNC;
	
  public: /* enumerating */

	
	virtual IntegerVar count () DEFERRED_FUNC;
	
	
	virtual RPTR(Stepper) stepper () DEFERRED_FUNC;
	
  public: /* testing */

	
	virtual UInt32 actualHashForEqual ();
	
	
	virtual BooleanVar isEqual (APTR(Heaper) ARG(other));
	

	/* automatic 0-argument constructor */
  public:
	ImmuSet();


  /* ---------- Static Member variables (class vars) ----------- */
  private:
	static WPTR(ImmuSet) EmptySet;
};  /* end class ImmuSet */



/* ************************************************************************ *
 * 
 *                    Class   MuSet 
 *
 * ************************************************************************ */



/* Initializers for MuSet */


/* exceptions: exceptions */

PROBLEM_LIST(AlreadyInSetFilter,1,(AlreadyInSet));



	/* MuSets are a changable collection of elements.  Added to 
	the ScruSet protocol are messages for performing these 
	changes.  The "introduce/store/wipe/remove" suite is defined 
	by analogy with similar methods in MuTable.  See both ScruSet 
	and MuTable. */

class MuSet : public ScruSet {

/* Attributes for class MuSet */
	DEFERRED(MuSet)
	EQ(MuSet)
	NO_GC(MuSet)

/* Initializers for MuSet */
friend class INIT_TIME_NAME(MuSet,initTimeNonInherited);

  public: /* pseudo constructors */

	
	static RPTR(MuSet) fromStepper (APTR(Stepper) ARG(stepper));
	
	
	static RPTR(MuSet) make ();
	
	
	static RPTR(MuSet) make (APTR(Heaper) ARG(item));
	
	/* someSize is a non-semantic hint about how big the set might get. */
	
	static RPTR(MuSet) make (IntegerVar ARG(someSize));
	
  public: /* accessing */

	
	virtual BooleanVar hasMember (APTR(Heaper) ARG(someone)) DEFERRED_FUNC;
	
	
	virtual BooleanVar isEmpty () DEFERRED_FUNC;
	
  public: /* operations */

	/* Sort of intersect.  Wipe from myself all elements that I 
	don't have in common with other.
		Turn myself into the intersection of my current self and other. */
	
	virtual void restrictTo (APTR(ScruSet) ARG(other));
	
	/* Sort of union.  Store into myself all elements from other.
		Turn myself into the union of my current self and other. */
	
	virtual void storeAll (APTR(ScruSet) ARG(other));
	
	/* Sort of minus.  Wipe from myself all elements from other.
		Turn myself into my current self minus other. */
	
	virtual void wipeAll (APTR(ScruSet) ARG(other));
	
  public: /* adding-removing */

	/* Add anElement to my members, but only if it isn't already a member.
		If it is already a member, BLAST */
	
	virtual void introduce (APTR(Heaper) ARG(anElement)) DEFERRED_SUBR;
	
	/* Remove anElement from my members.  If it isn't currently a 
	member, then BLAST */
	
	virtual void remove (APTR(Heaper) ARG(anElement)) DEFERRED_SUBR;
	
	/* Add anElement to my set of members.  No semantic effect if 
	anElement is already a member. */
	
	virtual void store (APTR(Heaper) ARG(anElement)) DEFERRED_SUBR;
	
	/* make anElement no longer be one of my members.  No 
	semantic effect if it already isn't a member. */
	
	virtual void wipe (APTR(Heaper) ARG(anElement)) DEFERRED_SUBR;
	
  public: /* creation */

	
	virtual RPTR(ScruSet) copy () DEFERRED_FUNC;
	
  public: /* conversion */

	
	virtual RPTR(ImmuSet) asImmuSet ();
	
	
	virtual RPTR(MuSet) asMuSet ();
	
  public: /* enumerating */

	
	virtual IntegerVar count () DEFERRED_FUNC;
	
	
	virtual RPTR(Stepper) stepper () DEFERRED_FUNC;
	
  private: /* private: enumerating */

	
	virtual RPTR(Stepper) immuStepper () DEFERRED_FUNC;
	

	/* automatic 0-argument constructor */
  public:
	MuSet();

/* Friends for class MuSet */
/* friends for class MuSet */
friend class ImmuSetOnMu;
friend class COWMuSet;


};  /* end class MuSet */



/* ************************************************************************ *
 * 
 *                    Class SetAccumulator 
 *
 * ************************************************************************ */




	/* A SetAccumulator accumulates a bunch of objects and then 
	makes an ImmuSet containing all the accumulated objects.  
	Several people have observed that a SetAccumulator doesn't 
	buy you much because instead you could just store into a 
	MuSet.  While this is true (and is in fact how SetAccumulator 
	is trivially implemented), my feeling is that if what a loop 
	is doing is enumerating a bunch of elements from which a Set 
	is to be formed, using a SetAccumulator in the loops says 
	this more clearly to readers of the code. */

class SetAccumulator : public Accumulator {

/* Attributes for class SetAccumulator */
	CONCRETE(SetAccumulator)
	COPY(SetAccumulator,XppCuisine)
	AUTO_GC(SetAccumulator)
  public: /* instance creation */

	/* Make a SetAccumulator which starts out with no elements 
	accumulated */
	
	static RPTR(SetAccumulator) make ();
	
	/* Make a new SetAccumulator in which all the current 
	elements of initialSet are already accumulated.
		Future changes to initialSet have no effect on the accumulator. */
	
	static RPTR(SetAccumulator) make (APTR(ScruSet) ARG(initialSet));
	
  public: /* accessing */

	
	virtual void step (APTR(Heaper) ARG(someObj));
	
	
	virtual RPTR(Heaper) value ();
	
  protected: /* protected: creation */

	
	SetAccumulator ();
	
	
	SetAccumulator (APTR(ScruSet) ARG(initialSet), TCSJ);
	
  public: /* creation */

	
	virtual RPTR(Accumulator) copy ();
	
  private:
	CHKPTR(MuSet) muSet;
	friend class Accumulator;
};  /* end class SetAccumulator */



/* ************************************************************************ *
 * 
 *                    Class UnionRecruiter 
 *
 * ************************************************************************ */




	/* Like a SetAccumulator, a UnionRecruiter makes an ImmuSet 
	out of the things that it Accumulates.  However, the things 
	that a UnionRecruiter accumulates must themselves be 
	ScruSets, and the resulting ImmuSet consists of the union of 
	the elements of each of the accumulated sets as of the time 
	they were accumulated. */

class UnionRecruiter : public Accumulator {

/* Attributes for class UnionRecruiter */
	CONCRETE(UnionRecruiter)
	COPY(UnionRecruiter,XppCuisine)
	AUTO_GC(UnionRecruiter)
  public: /* pseudo constructors */

	/* Make a new UnionRecruiter which hasn't yet accumulated anything */
	
	static RPTR(UnionRecruiter) make ();
	
  public: /* accessing */

	
	virtual void step (APTR(Heaper) ARG(someObj));
	
	
	virtual RPTR(Heaper) value ();
	
  protected: /* protected: creation */

	
	UnionRecruiter ();
	
  public: /* creation */

	
	virtual RPTR(Accumulator) copy ();
	
  private:
	CHKPTR(MuSet) muSet;
	friend class Accumulator;
};  /* end class UnionRecruiter */


#ifdef USE_INLINE
#ifndef SETX_IXX
#include "setx.ixx"
#endif /* SETX_IXX */


#endif /* USE_INLINE */


#endif /* SETX_HXX */

