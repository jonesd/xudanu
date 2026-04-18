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

#ifndef SETX_CXX
#define SETX_CXX


#ifndef CHOOSEX_HXX
#include "choosex.hxx"
#endif /* CHOOSEX_HXX */

#ifndef SETX_HXX
#include "setx.hxx"
#endif /* SETX_HXX */

#ifndef SETX_IXX
#include "setx.ixx"
#endif /* SETX_IXX */

#ifndef SETP_HXX
#include "setp.hxx"
#endif /* SETP_HXX */

#ifndef SETP_IXX
#include "setp.ixx"
#endif /* SETP_IXX */


#ifndef NXCVRX_HXX
#include "nxcvrx.hxx"
#endif /* NXCVRX_HXX */

#ifndef TABTOOLX_HXX
#include "tabtoolx.hxx"
#endif /* TABTOOLX_HXX */

#ifndef XFRSPECX_HXX
#include "xfrspecx.hxx"
#endif /* XFRSPECX_HXX */




/* ************************************************************************ *
 * 
 *                    Class ScruSet 
 *
 * ************************************************************************ */


/* exceptions: exceptions */


/* X++ has three basic kinds of collection classes.  Tables, Sets and 
XuRegions.  XuRegions are not-necessarily-discrete collections of 
positions, and are documented in the space module.  Sets and Tables 
are both discrete and finite, and similar in many ways.  Both 
originate in a three-way type distinction between:
	
	ScruX  --  The protocol for examining one.  I.e., it is *Scru*table
		ImmuX  --  The contract guarantees that the set or table you're 
looking at won't change (though the things it contains may change)
		MuX  --  Additional protocol for changing it.
		
	Concrete classes may be a subclass of any of the above.  It makes 
sense to have a concrete subclass of ScruX which isn't a subclass of 
either MuX or ImmuX when, for example, it represents a tracking, 
filtered view of some other set which is itself changing.  All kinds 
of collection can be iterated over when appropriate using 
Steppers--our basic iteration abstraction (see Stepper).
	
	Immu's are sort of like Stamps -- they represent a particular state 
a colection can have.  Mu's are sort of like Berts -- they represent 
a continuing collection identity which can change its current state.
	
	Sets are pure collections--their contents are just a set of Heapers. 
 Sets (as opposed to tables) do not provide any organization of these 
contents. */


/* testing */


UInt32 ScruSet::actualHashForEqual (){
	return Heaper::takeOop();
}


BooleanVar ScruSet::contentsEqual (APTR(ScruSet) other){
	/* Returns whether the two ScruSets have exactly the same set 
	of elements at the moment.
		'a->contentsEqual(b)' is equivalent to 
		'a->asImmuSet()->isEqual(b->asImmuSet())'. */
	
	if (other->count() != this->count()) {
		return FALSE;
	}
	BEGIN_FOR_EACH(Heaper,each,(other->stepper())) {
		if (!this->hasMember(each)) {
			return FALSE;
		}
	} END_FOR_EACH;
	return TRUE;
}


UInt32 ScruSet::contentsHash (){
	/* Has the same relationship to contentsEqual that 
	hashForEqual has to isEqual. 
		I.e., if 'a->contentsEqual (b)', then 'a->contentsHash() == 
	b->contentsHash()'. 
		The same complex caveats apply as to the stability and 
	portability of the 
		hash values as apply for hashForEqual. */
	
	UInt32 result;
	
	result = UInt32Zero;
	BEGIN_FOR_EACH(Heaper,each,(this->stepper())) {
		result ^= each->hashForEqual();
	} END_FOR_EACH;
	return result;
}


BooleanVar ScruSet::intersects (APTR(ScruSet) other){
	/* tell whether they have any points in common */
	/* subclasses can override for efficiency */
	
	if (other->isEmpty()) {
		return FALSE;
	}
	if (this->count() > other->count()) {
		return other->intersects(this);
	}
	BEGIN_FOR_EACH(Heaper,mem,(this->stepper())) {
		if (other->hasMember(mem)) {
			return TRUE;
		}
	} END_FOR_EACH;
	return FALSE;
}


BooleanVar ScruSet::isSubsetOf (APTR(ScruSet) another){
	/* Whether another currently has all my elements */
	
	BEGIN_FOR_EACH(Heaper,elem,(this->stepper())) {
		if (!another->hasMember(elem)) {
			return FALSE;
		}
	} END_FOR_EACH;
	return TRUE;
}
/* creation */
/* conversion */


RPTR(PtrArray) ScruSet::asArray (){
	/* The elements in the set in an array, in some random order */
	
	SPTR(PtrArray) result;
	SPTR(Stepper) mine;
	
	/* Thing to do !!!! */
	
	/* make this faster */
	result = PtrArray::nulls(this->count().asLong());
	mine = this->stepper();
	{
		Int32 LoopFinal = result->count();
		Int32 index = Int32Zero;
		for (;;) {
			if (index >= LoopFinal){
				break;
			}
			{
				result->store(index, mine->fetch());
				mine->step();
			}
			index += 1;
		}
	}
	{mine->destroy();  mine = NULL /* don't want stale (S/CHK)PTRs */;}
	WPTR(PtrArray) 	returnValue;
	returnValue = result;
	return returnValue;
}
/* printing */


void ScruSet::printOn (ostream& oo){
	oo << this->getCategory()->name();
	this->printOnWithSimpleSyntax(oo, "{", ", ", "}");
}


void ScruSet::printOnWithSimpleSyntax (
		ostream& oo, 
		char * open, 
		char * sep, 
		char * close)
{
	this->printOnWithSyntax(oo, open, sep, close, FALSE);
}


void ScruSet::printOnWithSyntax (
		ostream& oo, 
		char * open, 
		char * sep, 
		char * close, 
		BooleanVar fullPrint/* = FALSE*/)
{
	/* For example, if we have the set '{a, b, c}' and we print it with 
		'p->printOnWithSyntax(oo, "<<", "; ", ">>");', we get '<<a; 
	b; c>>'.  This is a convenient little hack
		for printing with all sorts of separators and brackets. */
	
	SPTR(Stepper) dSet;
	IntegerVar elemCount;
	BooleanVar printMore;
	
	printMore = !fullPrint;
	elemCount = IntegerVar0;
	oo << open;
	if (this->isEmpty()) {
		oo << "nullSet";
	} else {
		dSet = this->stepper();
		for (;;) {	BooleanVar crutch_Flag;
			/* dSet->hasValue() && printMore */
			
			crutch_Flag = dSet->hasValue();
			if(crutch_Flag) {
				crutch_Flag = printMore;
			}
			if (crutch_Flag) {
				oo << dSet->fetch();
				dSet->step();
				if (dSet->hasValue()) {
					oo << sep;
				}
				{	BooleanVar crutch_Flag;
					/* printMore && (elemCount += 1) > 200 */
					
					crutch_Flag = printMore;
					if(crutch_Flag) {
						crutch_Flag = (elemCount += 1) > 200;
					}
					if (crutch_Flag) {
						printMore = FALSE;
					}
				}
			} else {
				break;
			}
		}
	}
	{	BooleanVar crutch_Flag;
		/* !printMore && dSet->hasValue() */
		
		crutch_Flag = !printMore;
		if(crutch_Flag) {
			crutch_Flag = dSet->hasValue();
		}
		if (crutch_Flag) {
			oo << "etc...";
		}
	}
	oo << close;
}
/* enumerating */


RPTR(Heaper) ScruSet::theOne (){
	/* Iff I contain exactly one member, return it.  Otherwise BLAST.
		The idea for this message is taken from the THE function of ONTIC
		(reference McAllester) */
	
	SPTR(Stepper) stepper;
	SPTR(Heaper) result;
	
	if (this->count() != 1) {
		BLAST(NotOneElement);
	}
	stepper = this->stepper();
	result = stepper->fetch();
	{stepper->destroy();  stepper = NULL /* don't want stale (S/CHK)PTRs */;}
	WPTR(Heaper) 	returnValue;
	returnValue = result;
	return returnValue;
}

	/* automatic 0-argument constructor */
ScruSet::ScruSet() {}



/* ************************************************************************ *
 * 
 *                    Class   ImmuSet 
 *
 * ************************************************************************ */



/* Initializers for ImmuSet */

WPTR(ImmuSet) ImmuSet::EmptySet = NULL;



BEGIN_INIT_TIME(ImmuSet,initTimeNonInherited) {
	REQUIRES (Stepper);
	CONSTRUCT_ON(PERSISTENT,ImmuSet::EmptySet,EmptyImmuSet,());
} END_INIT_TIME(ImmuSet,initTimeNonInherited);



/* Initializers for ImmuSet */






/* protected: pseudo constructors */


RPTR(ImmuSet) ImmuSet::from (APTR(MuSet) set){
	/* This is for ImmuSet subclasses to produce results from 
	temporary MuSets.
		The difference between this and ImmuSet make.MuSet: is that 
	this doesn't make a copy
		of the MuSet when making an ImmuSetOnMu. */
	
	if (set->isEmpty()) {
		WPTR(ImmuSet) 	returnValue;
		returnValue = ImmuSet::EmptySet;
		return returnValue;
	}
	if (set->count() == 1) {
		WPTR(ImmuSet) 	returnValue;
		returnValue = TinyImmuSet::make (set->theOne());
		return returnValue;
	}
	WPTR(ImmuSet) 	returnValue;
	returnValue = ImmuSetOnMu::make (set);
	return returnValue;
}
/* pseudo constructors */


RPTR(ImmuSet) ImmuSet::make (APTR(MuSet) set){
	if (set->isEmpty()) {
		WPTR(ImmuSet) 	returnValue;
		returnValue = ImmuSet::EmptySet;
		return returnValue;
	}
	if (set->count() == 1) {
		WPTR(ImmuSet) 	returnValue;
		returnValue = TinyImmuSet::make (set->theOne());
		return returnValue;
	}
	WPTR(ImmuSet) 	returnValue;
	returnValue = ImmuSetOnMu::make (CAST(MuSet,set->copy()));
	return returnValue;
}


RPTR(ImmuSet) ImmuSet::newWith (APTR(Heaper) value){
	/* A single element ImmuSet */
	
	WPTR(ImmuSet) 	returnValue;
	returnValue = TinyImmuSet::make (value);
	return returnValue;
}
/* ImmuSets are ScruSets which are guaranteed never to change.  
ImmuSets correspond to the mathematical notion of a finite set of 
elements, except of course that here the elements can be any valid 
X++ object.  Just like mathematical sets, two are equal (according to 
isEqual) iff they have the same elements.  Just because the set 
cannot change, that doesn't prevent any of the members from 
undergoing state change.
	
	ImmuSets implement some additional protocol to make new sets out of 
old ones according to the familiar set theoretic operators (like 
intersect).  XuRegions are much like ImmuSets of Positions except 
that they aren't necessarily finite or even enumerable.  XuRegions 
implement a similar protocol, but aren't polymorphic with ImmuSets.  */


/* accessing */
/* operations */
/* adding-removing */
/* creation */


RPTR(ScruSet) ImmuSet::copy (){
	/* don't need to actually make a copy, as this is immutable */
	
	return this;
}
/* conversion */


RPTR(ImmuSet) ImmuSet::asImmuSet (){
	return this;
}
/* enumerating */
/* testing */


UInt32 ImmuSet::actualHashForEqual (){
	return this->contentsHash();
}


BooleanVar ImmuSet::isEqual (APTR(Heaper) other){
	BEGIN_CHOOSE(other) {
		BEGIN_KIND(ImmuSet,o) {
			return this->contentsEqual(o);
		} END_KIND;
		BEGIN_OTHERS {
			return FALSE;
		} END_OTHERS;
	} END_CHOOSE;
	/* compiler fodder */
	return FALSE;
}

	/* automatic 0-argument constructor */
ImmuSet::ImmuSet() {}



/* ************************************************************************ *
 * 
 *                    Class   MuSet 
 *
 * ************************************************************************ */



/* Initializers for MuSet */


BEGIN_INIT_TIME(MuSet,initTimeNonInherited) {
	REQUIRES (ActualHashSet);
} END_INIT_TIME(MuSet,initTimeNonInherited);


/* exceptions: exceptions */



/* Initializers for MuSet */



/* pseudo constructors */


RPTR(MuSet) MuSet::fromStepper (APTR(Stepper) stepper){
	SPTR(MuSet) result;
	
	result = MuSet::make ();
	BEGIN_FOR_EACH(Heaper,element,(stepper)) {
		result->store(element);
	} END_FOR_EACH;
	WPTR(MuSet) 	returnValue;
	returnValue = result;
	return returnValue;
}


RPTR(MuSet) MuSet::make (){
	WPTR(MuSet) 	returnValue;
	returnValue = ActualHashSet::make ();
	return returnValue;
}


RPTR(MuSet) MuSet::make (APTR(Heaper) item){
	WPTR(MuSet) 	returnValue;
	returnValue = ActualHashSet::make (item);
	return returnValue;
}


RPTR(MuSet) MuSet::make (IntegerVar someSize){
	/* someSize is a non-semantic hint about how big the set might get. */
	
	WPTR(MuSet) 	returnValue;
	returnValue = ActualHashSet::make (someSize);
	return returnValue;
}
/* MuSets are a changable collection of elements.  Added to the 
ScruSet protocol are messages for performing these changes.  The 
"introduce/store/wipe/remove" suite is defined by analogy with 
similar methods in MuTable.  See both ScruSet and MuTable. */


/* accessing */
/* operations */


void MuSet::restrictTo (APTR(ScruSet) other){
	/* Sort of intersect.  Wipe from myself all elements that I 
	don't have in common with other.
		Turn myself into the intersection of my current self and other. */
	
	SPTR(MuSet) tmp;
	
	tmp = CAST(MuSet,this->copy());
	tmp->wipeAll(other);
	this->wipeAll(tmp);
	{tmp->destroy();  tmp = NULL /* don't want stale (S/CHK)PTRs */;}
}


void MuSet::storeAll (APTR(ScruSet) other){
	/* Sort of union.  Store into myself all elements from other.
		Turn myself into the union of my current self and other. */
	
	BEGIN_FOR_EACH(Heaper,elem,(other->stepper())) {
		this->store(elem);
	} END_FOR_EACH;
}


void MuSet::wipeAll (APTR(ScruSet) other){
	/* Sort of minus.  Wipe from myself all elements from other.
		Turn myself into my current self minus other. */
	
	BEGIN_FOR_EACH(Heaper,elem,(other->stepper())) {
		this->wipe(elem);
	} END_FOR_EACH;
}
/* adding-removing */
/* creation */
/* conversion */


RPTR(ImmuSet) MuSet::asImmuSet (){
	if (this->isEmpty()) {
		WPTR(ImmuSet) 	returnValue;
		returnValue = ImmuSet::make ();
		return returnValue;
	}
	if (this->count() == 1) {
		WPTR(ImmuSet) 	returnValue;
		returnValue = ImmuSet::make ()->with(this->theOne());
		return returnValue;
	}
	WPTR(ImmuSet) 	returnValue;
	returnValue = ImmuSet::make (this);
	return returnValue;
}


RPTR(MuSet) MuSet::asMuSet (){
	return CAST(MuSet,this->copy());
}
/* enumerating */
/* private: enumerating */

	/* automatic 0-argument constructor */
MuSet::MuSet() {}



/* ************************************************************************ *
 * 
 *                    Class SetAccumulator 
 *
 * ************************************************************************ */


/* instance creation */


RPTR(SetAccumulator) SetAccumulator::make (){
	/* Make a SetAccumulator which starts out with no elements 
	accumulated */
	
	RETURN_CONSTRUCT(SetAccumulator,());
}


RPTR(SetAccumulator) SetAccumulator::make (APTR(ScruSet) initialSet){
	/* Make a new SetAccumulator in which all the current 
	elements of initialSet are already accumulated.
		Future changes to initialSet have no effect on the accumulator. */
	
	RETURN_CONSTRUCT(SetAccumulator,(initialSet, tcsj));
}
/* A SetAccumulator accumulates a bunch of objects and then makes an 
ImmuSet containing all the accumulated objects.  Several people have 
observed that a SetAccumulator doesn't buy you much because instead 
you could just store into a MuSet.  While this is true (and is in 
fact how SetAccumulator is trivially implemented), my feeling is that 
if what a loop is doing is enumerating a bunch of elements from which 
a Set is to be formed, using a SetAccumulator in the loops says this 
more clearly to readers of the code. */


/* accessing */


void SetAccumulator::step (APTR(Heaper) someObj){
	muSet->store(someObj);
}


RPTR(Heaper) SetAccumulator::value (){
	WPTR(Heaper) 	returnValue;
	returnValue = muSet->asImmuSet();
	return returnValue;
}
/* protected: creation */


SetAccumulator::SetAccumulator () {
	muSet = MuSet::make ();
}


SetAccumulator::SetAccumulator (APTR(ScruSet) initialSet, TCSJ) {
	muSet = initialSet->asMuSet();
}
/* creation */


RPTR(Accumulator) SetAccumulator::copy (){
	RETURN_CONSTRUCT(SetAccumulator,(muSet->asMuSet(), tcsj));
}



/* ************************************************************************ *
 * 
 *                    Class UnionRecruiter 
 *
 * ************************************************************************ */


/* pseudo constructors */


RPTR(UnionRecruiter) UnionRecruiter::make (){
	/* Make a new UnionRecruiter which hasn't yet accumulated anything */
	
	RETURN_CONSTRUCT(UnionRecruiter,());
}
/* Like a SetAccumulator, a UnionRecruiter makes an ImmuSet out of 
the things that it Accumulates.  However, the things that a 
UnionRecruiter accumulates must themselves be ScruSets, and the 
resulting ImmuSet consists of the union of the elements of each of 
the accumulated sets as of the time they were accumulated. */


/* accessing */


void UnionRecruiter::step (APTR(Heaper) someObj){
	muSet->storeAll(CAST(ScruSet,someObj));
}


RPTR(Heaper) UnionRecruiter::value (){
	WPTR(Heaper) 	returnValue;
	returnValue = muSet->asImmuSet();
	return returnValue;
}
/* protected: creation */


UnionRecruiter::UnionRecruiter () {
	muSet = MuSet::make ();
}
/* creation */


RPTR(Accumulator) UnionRecruiter::copy (){
	SPTR(Accumulator) result;
	
	result = UnionRecruiter::make ();
	result->step(muSet);
	WPTR(Accumulator) 	returnValue;
	returnValue = result;
	return returnValue;
}



/* ************************************************************************ *
 * 
 *                    Class EmptyImmuSet 
 *
 * ************************************************************************ */


/* rcvr pseudo constructor */


RPTR(Heaper) EmptyImmuSet::make (APTR(Rcvr) rcvr){
	CAST(SpecialistRcvr,rcvr)->registerIbid(ImmuSet::make ());
	WPTR(Heaper) 	returnValue;
	returnValue = ImmuSet::make ();
	return returnValue;
}
/* enumerating */


IntegerVar EmptyImmuSet::count (){
	return IntegerVar0;
}


RPTR(Stepper) EmptyImmuSet::stepper (){
	WPTR(Stepper) 	returnValue;
	returnValue = Stepper::emptyStepper();
	return returnValue;
}


RPTR(Heaper) EmptyImmuSet::theOne (){
	BLAST(NotOneElement);
	return NULL;
}
/* adding-removing */


RPTR(ImmuSet) EmptyImmuSet::with (APTR(Heaper) anElement){
	WPTR(ImmuSet) 	returnValue;
	returnValue = TinyImmuSet::make (anElement);
	return returnValue;
}


RPTR(ImmuSet) EmptyImmuSet::without (APTR(Heaper) /* anElement */){
	return this;
}
/* accessing */


BooleanVar EmptyImmuSet::hasMember (APTR(Heaper) /* someone */){
	return FALSE;
}


BooleanVar EmptyImmuSet::isEmpty (){
	return TRUE;
}


BooleanVar EmptyImmuSet::isSubsetOf (APTR(ScruSet) /* another */){
	return TRUE;
}
/* operations */


RPTR(ImmuSet) EmptyImmuSet::intersect (APTR(ScruSet) /* another */){
	return this;
}


RPTR(ImmuSet) EmptyImmuSet::minus (APTR(ScruSet) /* another */){
	return this;
}


RPTR(ImmuSet) EmptyImmuSet::unionWith (APTR(ScruSet) another){
	WPTR(ImmuSet) 	returnValue;
	returnValue = another->asImmuSet();
	return returnValue;
}
/* conversion */


RPTR(MuSet) EmptyImmuSet::asMuSet (){
	WPTR(MuSet) 	returnValue;
	returnValue = MuSet::make ();
	return returnValue;
}
/* unprotected for initer create */


EmptyImmuSet::EmptyImmuSet () {
	
}
/* creation */


void EmptyImmuSet::destroy (){
	/* Don't destroy our single instance */
	
	
}
/* protected: destruct */


void EmptyImmuSet::destruct (){
	/* This object is a canonical single instance, so its 
	destructor should only be called after main has exited. */
	
	if (!Initializer::inStaticDestruction()) BLAST(SanityViolation);
	
	this->ImmuSet::destruct();
}



/* ************************************************************************ *
 * 
 *                    Class HashSet 
 *
 * ************************************************************************ */


/* pseudo constructors */


RPTR(HashSet) HashSet::make (){
	WPTR(HashSet) 	returnValue;
	returnValue = ActualHashSet::make ();
	return returnValue;
}


RPTR(HashSet) HashSet::make (APTR(Heaper) something){
	SPTR(ActualHashSet) set;
	
	set = ActualHashSet::make (1);
	set->store(something);
	WPTR(HashSet) 	returnValue;
	returnValue = set;
	return returnValue;
}


RPTR(HashSet) HashSet::make (IntegerVar someSize){
	WPTR(HashSet) 	returnValue;
	returnValue = ActualHashSet::make (someSize);
	return returnValue;
}
/* 	The HashSet class is an implementation of a MuTable set that can 
contain arbitrary Heapers.  It uses the hashForEqual member function 
to get a hash value for the items contained in the set.  The set 
establishes the equality of objects in the set through the isEqual: function.
	
	The implemention of HashSet is straightforward.  There are primitive 
tables used to store pointers to the stored items (myHashEntries), 
and their corresponding hash values (myHashValues).  The HashSet also 
maintain a current tally of the number of items in the set.
	
	definition: preferred location - the location calculated from item 
hashForEqual mod tableSize.
	
	The search routine first calculates the preferred location.  This is 
used as the first location in the myHashEntries table to test for the 
presence of the item, and the search proceeds forward (in a linear 
probe) from there.  If there is no object at that position, the 
routine assumes the item is not in the table.  If there is an item 
there, the first test is to check if the item's hash matches the hash 
myHashValues at that position.  If the match is successful, a full 
isEqual: test is performed.  If the isEqual: test succeeds, the item 
is present in the set.  If either test fails, the entry at the 
desired location is tested to see if it is closer to its own 
preferred location than the item (a test which necessarily fails the 
first time).  If it is closer, the item is not in the set.  (This 
extra test is what distinguishes an ordered hash set from an ordinary 
hash set.  It often detects the absense of an item well before an 
empty slot is encountered, and the advantage becomes pronounced as 
the set fills up.  Ordered hash sets with linear probe beat ordinary 
hash sets with secondary clustering on misses (the big time eater), 
yet they preserve linear probe's easy deletion.)
	
	On insertion to the set, the hash and probe sequence is essentially 
the same as the search.  The main exception is that on a hash 
collision, the item bumps down any item that is no farther than its 
own preferred position.
	
	An example is perhaps in order:
	
	the set contains items a, b, and c in table locations 3, 4, and 5.  
Assume that a has location 2 as its preferred location, while b and c 
both have location 4 as their preferred location.  Now, if we attempt 
to add an item d to the table, and item d were to have a preferred 
location of 3.  Since 3 is already occupied by something that is 
already far from its preferred location, we probe for a another 
location.  At location 4, item d is displaced by one from its 
preferred location.  Since b is in it's preferred location (4) d 
replaces it, and we move item b down.  Item c is in location 5 
because it had already been bumped from location 4 when b was 
inserted previously.  B again ties with c, so it pushes it out of 
location 5, replacing it there.  Item c will end up in location 6.  
This probe function minimizes the individual displacement of hash 
misses, while keeping the most items in their preferred locations.
	
	Note that, though the choice of which item to bump is obvious when 
the distances from home are different, when they are equal we could 
have given preference to either the new or the old item.  We chose to 
put the new item closer to its preferred location, on the assumption 
that things entered recently are more likely to be looked up than 
things entered long ago.
	
This algorithm was derived from a short discussion with Michael 
McClary (probably completely missing his intended design - all 
mistakes are mine -- heh).

(Unfortunately, I wasn't clear in the discussion.  Since hugh was 
unavailable when I discovered this, I've taken the opportunity to 
practice with Smalltalk and corrected both the explanation and the 
code rather than sending him a clarification. -- michael) */


/* accessing */
/* creation */
/* enumerating */
/* adding-removing */
/* conversion */


RPTR(ImmuSet) HashSet::asImmuSet (){
	if (this->isEmpty()) {
		WPTR(ImmuSet) 	returnValue;
		returnValue = ImmuSet::make ();
		return returnValue;
	}
	if (this->count() == 1) {
		WPTR(ImmuSet) 	returnValue;
		returnValue = ImmuSet::make ()->with(this->theOne());
		return returnValue;
	}
	WPTR(ImmuSet) 	returnValue;
	returnValue = ImmuSet::make (this);
	return returnValue;
}


RPTR(MuSet) HashSet::asMuSet (){
	return CAST(MuSet,this->copy());
}
/* private: testing access */
/* private: enumerating */


RPTR(Stepper) HashSet::immuStepper (){
	BLAST(NOT_YET_IMPLEMENTED);
	return NULL;
}

	/* automatic 0-argument constructor */
HashSet::HashSet() {}



/* ************************************************************************ *
 * 
 *                    Class   ActualHashSet 
 *
 * ************************************************************************ */



/* Initializers for ActualHashSet */





BEGIN_INIT_TIME(ActualHashSet,initTimeNonInherited) {
	/* ((5 - 10) + 17) == ((5 - 10) \\ 17) assert: 
				'incorrect modulus - change HashSet distanceFromHome' */
	REQUIRES (LPPrimeSizeProvider);
} END_INIT_TIME(ActualHashSet,initTimeNonInherited);



/* Initializers for ActualHashSet */






/* pseudo constructors */


RPTR(ActualHashSet) ActualHashSet::make (){
	RETURN_CONSTRUCT(ActualHashSet,(Int32Zero, SharedPtrArray::make (7)));
}


RPTR(ActualHashSet) ActualHashSet::make (APTR(Heaper) something){
	SPTR(ActualHashSet) set;
	
	set = ActualHashSet::make (1);
	set->store(something);
	WPTR(ActualHashSet) 	returnValue;
	returnValue = set;
	return returnValue;
}


RPTR(ActualHashSet) ActualHashSet::make (IntegerVar someSize){
	RETURN_CONSTRUCT(ActualHashSet,(Int32Zero, SharedPtrArray::make (LPPrimeSizeProvider::make ()->uInt32PrimeAfter(someSize.asLong()))));
}
/* testing */


UInt32 ActualHashSet::contentsHash (){
	UInt32 hashResult;
	
	hashResult = UInt32Zero;
	{
		UInt32 LoopFinal = myHashEntries->count();
		UInt32 idx = UInt32Zero;
		for (;;) {
			if (idx >= LoopFinal){
				break;
			}
			{
				if (myHashEntries->fetch(idx) != NULL) {
					hashResult += myHashValues->uIntAt(idx);
				}
			}
			idx += 1;
		}
	}
	return hashResult;
}
/* accessing */


IntegerVar ActualHashSet::count (){
	return myTally;
}


BooleanVar ActualHashSet::hasMember (APTR(Heaper) someone){
	
	return this->hashFind(someone) >= Int32Zero;
}


BooleanVar ActualHashSet::isEmpty (){
	return myTally == UInt32Zero;
}
/* creation */


RPTR(ScruSet) ActualHashSet::copy (){
	RETURN_CONSTRUCT(ActualHashSet,(myTally, myHashValues, myHashEntries));
}
/* protected: creation */


ActualHashSet::ActualHashSet (Int32 newTally, APTR(SharedPtrArray) entries) {
	myTally = newTally;
	myHashValues = UInt32Array::make (entries->count());
	myHashEntries = entries;
	myHashEntries->shareMore();
	
}


ActualHashSet::ActualHashSet (
		Int32 newTally, 
		APTR(UInt32Array) hashValues, 
		APTR(SharedPtrArray) entries) 
{
	myTally = newTally;
	myHashValues = hashValues;
	myHashEntries = entries;
	myHashEntries->shareMore();
	
}


void ActualHashSet::destruct (){
	myHashEntries->shareLess();
	this->HashSet::destruct();
}
/* enumerating */


RPTR(Stepper) ActualHashSet::stepper (){
	
	WPTR(Stepper) 	returnValue;
	returnValue = HashSetStepper::make (myHashEntries);
	return returnValue;
}


RPTR(Heaper) ActualHashSet::theOne (){
	if (myTally != 1) {
		BLAST(NotOneElement);
	}
	{
		Int32 LoopFinal = myHashEntries->count();
		Int32 i = Int32Zero;
		for (;;) {
			if (i >= LoopFinal){
				break;
			}
			{
				if (myHashEntries->fetch(i) != NULL) {
					WPTR(Heaper) 	returnValue;
					returnValue = myHashEntries->fetch(i);
					return returnValue;
				}
			}
			i += 1;
		}
	}
	return NULL;
}
/* operations */


void ActualHashSet::storeAll (APTR(ScruSet) other){
	/* union equivalent */
	
	BooleanVar haveStored;
	
	haveStored = FALSE;
	BEGIN_FOR_EACH(Heaper,elem,(other->stepper())) {
		if (this->hashFind(elem) < Int32Zero) {
			if (!haveStored) {
				haveStored = TRUE;
				
				this->checkSize(other->count().asLong());
			}
			this->hashStore(elem, myHashValues, myHashEntries);
			myTally += 1;
		}
	} END_FOR_EACH;
}


void ActualHashSet::wipeAll (APTR(ScruSet) other){
	/* Sort of minus.  Wipe from myself all elements from other.
		Turn myself into my current self minus other. */
	/* Maintainance note: this duplicates some code in wipe: for 
	efficiency */
	
	Int32 loc;
	BooleanVar haveWritten;
	
	if (myTally == UInt32Zero) {
		return;
		
	}
	haveWritten = FALSE;
	BEGIN_FOR_EACH(Heaper,elem,(other->stepper())) {
		if ((loc = this->hashFind(elem)) >= Int32Zero) {
			if (!haveWritten) {
				this->aboutToWrite();
				haveWritten = TRUE;
				
			}
			this->hashRemove((UInt32 ) loc);
			myTally -= 1;
		}
	} END_FOR_EACH;
}
/* adding-removing */


void ActualHashSet::introduce (APTR(Heaper) anElement){
	
	this->checkSize(1);
	if (this->hashFind(anElement) >= Int32Zero) {
		BLAST(AlreadyInSet);
	} else {
		this->hashStore(anElement, (UInt32Array * ) myHashValues, (PtrArray * ) myHashEntries);
		myTally += 1;
	}
}


void ActualHashSet::remove (APTR(Heaper) anElement){
	Int32 loc;
	
	
	this->aboutToWrite();
	if ((loc = this->hashFind(anElement)) >= Int32Zero) {
		this->hashRemove((UInt32 ) loc);
		myTally -= 1;
	} else {
		BLAST(NotInSet);
	}
}


void ActualHashSet::store (APTR(Heaper) anElement){
	/* maintainance note: storeAll: has a copy of the code 
	starting at self hashFind:... for efficiency. */
	
	if (this->hashFind(anElement) < Int32Zero) {
		this->checkSize(1);
		this->hashStore(anElement, (UInt32Array * ) myHashValues, (PtrArray * ) myHashEntries);
		
		myTally += 1;
	}
}


void ActualHashSet::wipe (APTR(Heaper) anElement){
	Int32 loc;
	
	if (myTally == UInt32Zero) {
		return;
		
	}
	if ((loc = this->hashFind(anElement)) >= Int32Zero) {
		
		this->aboutToWrite();
		this->hashRemove((UInt32 ) loc);
		myTally -= 1;
	}
}
/* private: housekeeping */


void ActualHashSet::actualAboutToWrite (){
	SPTR(UInt32Array) newValues;
	SPTR(SharedPtrArray) newEntries;
	
	newValues = CAST(UInt32Array,myHashValues->copy());
	newEntries = CAST(SharedPtrArray,myHashEntries->copy());
	myHashEntries->shareLess();
	myHashValues = newValues;
	myHashEntries = newEntries;
	myHashEntries->shareMore();
}


void ActualHashSet::checkSize (Int32 byAmount){
	Int32 newSize;
	SPTR(UInt32Array) newValues;
	SPTR(SharedPtrArray) newEntries;
	WPTR(Heaper) he;
	
	/* Leave a third of free space. */
	if ((myTally + byAmount) * 5 >> 2 < myHashEntries->count()) {
		this->aboutToWrite();
		return;
		
	}
	newSize = LPPrimeSizeProvider::make ()->uInt32PrimeAfter(myHashValues->count() * 2 + byAmount);
	newValues = UInt32Array::make (newSize);
	newEntries = SharedPtrArray::make (newSize);
	{
		Int32 LoopFinal = myHashValues->count();
		register Int32 from = Int32Zero;
		for (;;) {
			if (from >= LoopFinal){
				break;
			}
			{
				if ((he = myHashEntries->fetch(from)) != NULL) {
					this->hashStore(he, newValues, newEntries);
				}
			}
			from += 1;
		}
	}
	if (myHashEntries->shareCount() > 1) {
		myHashEntries->shareLess();
	} else {
		{myHashValues->destroy();  myHashValues = NULL /* don't want stale (S/CHK)PTRs */;}
		{myHashEntries->destroy();  myHashEntries = NULL /* don't want stale (S/CHK)PTRs */;}
	}
	myHashValues = newValues;
	myHashEntries = newEntries;
	myHashEntries->shareMore();
}


Int32 ActualHashSet::distanceFromHome (
		UInt32 loc, 
		UInt32 home, 
		UInt32 modulus)
{
	Int32 dist;
	
	
	/* alternate coding if modulus doesn't handle negatives the 
		same as smalltalk 
				(positive remainder only) */
	dist = loc - home;
	if (dist < Int32Zero) {
		dist += modulus;
	}
	return dist;
	
}
/* private: hash resolution */


Int32 ActualHashSet::hashFind (APTR(Heaper) item){
	/* Starting at the item's preferred location and iterating 
	(not recurring!) around the set's
		 storage while the slots we're examining are occupied...
		   If the current slot's occupant is the target item, return a hit 
		   if the current occupant is closer to it's preferred 
	location, return a miss.
		   If we've gone all the way around, return a miss. */
	
	UInt32 tSize;
	UInt32 current;
	UInt32 currentValue;
	SPTR(Heaper) currentEntry;
	UInt32 currentHome;
	UInt32 targetValue;
	UInt32 targetHome;
	
	tSize = myHashValues->count();
	targetValue = item->hashForEqual();
	targetHome = current = targetValue % tSize;
	while ((currentEntry = myHashEntries->fetch(current)) != NULL) {
		currentValue = myHashValues->uIntAt(current);
		if (currentValue == targetValue) {
			if (currentEntry->isEqual(item)) {
				return current;
			}
		}
		/* Found it. */
		currentHome = currentValue % tSize;
		if (this->distanceFromHome(current, targetHome, tSize) > 
					this->distanceFromHome(current, currentHome, tSize)) {
			return -1;
		}
		/* Would have seen it by now. */
		current = (current + 1) % tSize;
		/* All the way around. */
		if (current == targetHome) {
			return -1;
		}
	}
	/* Found an empty slot. */
	return -1;
}


void ActualHashSet::hashRemove (UInt32 from){
	/* Remove the indicated item from the set.
		 Iteratively (not recursively!) move other items up until 
	one is NULL or happier where it is. */
	
	UInt32 tSize;
	UInt32 current;
	UInt32 next;
	UInt32 nextValue;
	SPTR(Heaper) nextEntry;
	
	current = from;
	tSize = myHashValues->count();
	for (;;) {	BooleanVar crutch_Flag;
		/* (nextEntry = myHashEntries->fetch(next = (current + 1) % tSize)) != NULL && (nextValue = myHashValues->uIntAt(next)) % tSize != next */
		
		crutch_Flag = (nextEntry = myHashEntries->fetch(next = (current + 1) % tSize)) != NULL;
		if(crutch_Flag) {
			crutch_Flag = (nextValue = myHashValues->uIntAt(next)) % tSize != next;
		}
		if (crutch_Flag) {
			myHashEntries->store(current, nextEntry);
			myHashValues->storeUInt(current, nextValue);
			current = next;
		} else {
			break;
		}
	}
	myHashEntries->store(current, NULL);
	myHashValues->storeUInt(current, UInt32Zero);
}


void ActualHashSet::hashStore (
		APTR(Heaper) item, 
		APTR(UInt32Array) values, 
		APTR(PtrArray) entries)
{
	/* Starting at the new item's preferred location and 
	iterating (not recurring!) around the set's storage while the 
	slots we're examining are occupied.  (Caller assures us there 
	IS a vacant slot) if the current occupant is no closer to 
	it's preferred location, exchange it with the 'new' one.  
	Bail out if the current occupant IS the new one.
		 Store the currently 'new' item. */
	
	UInt32 tSize;
	UInt32 current;
	UInt32 itemValue;
	UInt32 movingValue;
	SPTR(Heaper) movingEntry;
	UInt32 movingEntrysHome;
	UInt32 sittingValue;
	SPTR(Heaper) sittingEntry;
	UInt32 sittingEntrysHome;
	
	tSize = values->count();
	movingEntry = item;
	movingValue = itemValue = movingEntry->hashForEqual();
	movingEntrysHome = current = movingValue % tSize;
	while ((sittingEntry = entries->fetch(current)) != NULL) {
		sittingValue = values->uIntAt(current);
		sittingEntrysHome = sittingValue % tSize;
		/* If the test below is >, new items are stored as 
			far as possible from their desired location, 
			giving the better slots to previous entries.  
			If it is >=, new items are stored as close as 
			possible to their desired locations, with 
			older items moved farther down, giving the 
			better slots to the more recent items.
						 
						 (Changing this test to > requires moving 
			the duplicate item test.) */
			/* Bump the old occupant to another slot. */
		if (this->distanceFromHome(current, movingEntrysHome, tSize) >= 
					this->distanceFromHome(current, sittingEntrysHome, tSize)) {
			entries->store(current, movingEntry);
			values->storeUInt(current, movingValue);
			movingEntry = sittingEntry;
			movingValue = sittingValue;
			movingEntrysHome = sittingEntrysHome;
			/* item already in set, return. */
			{	BooleanVar crutch_Flag;
				/* movingValue == itemValue && movingEntry->isEqual(item) */
				
				crutch_Flag = movingValue == itemValue;
				if(crutch_Flag) {
					crutch_Flag = movingEntry->isEqual(item);
				}
				if (crutch_Flag) {
					return;
					
				}
			}
		}
		current = (current + 1) % tSize;
	}
	entries->store(current, movingEntry);
	values->storeUInt(current, movingValue);
}
/* private: testing access */


UInt32 ActualHashSet::entryTableSize (){
	return myHashEntries->count();
}


void ActualHashSet::printInternals (ostream& oo){
	/* This method is for regression testing. */
	
	UInt32 tSize;
	UInt32 tValue;
	
	tSize = myHashValues->count();
	oo << "tally == " << myTally << "\n";
	{
		UInt32 LoopFinal = myHashEntries->count();
		UInt32 idx = UInt32Zero;
		for (;;) {
			if (idx >= LoopFinal){
				break;
			}
			{
				oo << idx << ":\t(" << (tValue = myHashValues->uIntAt(idx)) % tSize;
				oo << ", " << 
							this->distanceFromHome(idx, tValue, tSize) << ") ";
				
				{
			char	buffer[9];
			sprintf(buffer, "%X", tValue);
			oo << buffer;
		}
				
				oo << ",\t" << myHashEntries->fetch(idx) << "\n";
			}
			idx += 1;
		}
	}
	oo << "\n";
}
/* hooks: */


void ActualHashSet::receiveHashSet (APTR(Rcvr) rcvr){
	/* Make myHashEntries large enough that we won't grow. */
	
	Int32 count;
	
	count = LPPrimeSizeProvider::make ()->uInt32PrimeAfter(myTally * 2);
	myHashEntries = SharedPtrArray::make (count);
	myHashEntries->shareMore();
	myHashValues = UInt32Array::make (count);
	{
		for (Int32 T_LoopVar = myTally; T_LoopVar > 0; T_LoopVar -= 1) {
			this->hashStore(rcvr->receiveHeaper(), myHashValues, myHashEntries);
		}
	}
}


void ActualHashSet::sendHashSet (APTR(Xmtr) xmtr){
	/* This currently doesn't take advantage of the optimizations 
	in TableEntries.  It should. */
	
	Int32 count;
	
	count = Int32Zero;
	BEGIN_FOR_EACH(Heaper,value,(this->stepper())) {
		xmtr->sendHeaper(value);
		count += 1;
	} END_FOR_EACH;
	if ( ! (count == myTally) ) {
		BLAST(Must_write_every_element);
	}
}



/* ************************************************************************ *
 * 
 *                    Class HashSetStepper 
 *
 * ************************************************************************ */



/* Initializers for HashSetStepper */

GPTR(InstanceCache) HashSetStepper::SomeSteppers = NULL;



BEGIN_INIT_TIME(HashSetStepper,initTimeNonInherited) {
	HashSetStepper::SomeSteppers = InstanceCache::make (16);
} END_INIT_TIME(HashSetStepper,initTimeNonInherited);



/* Initializers for HashSetStepper */






/* pseudo constructors */


RPTR(Stepper) HashSetStepper::make (APTR(SharedPtrArray) elements){
	SPTR(Heaper) result;
	
	result = HashSetStepper::SomeSteppers->fetch();
	if (result == NULL) {
		RETURN_CONSTRUCT(HashSetStepper,(elements, Int32Zero));
	} else {
		WPTR(Stepper) 	returnValue;
		returnValue = new (result) HashSetStepper(elements, Int32Zero);
		return returnValue;
	}
}
/* accessing */


WPTR(Heaper) HashSetStepper::fetch (){
	{	BooleanVar crutch_Flag;
		/* myElements != NULL && myCurrent < myElements->count() */
		
		crutch_Flag = myElements != NULL;
		if(crutch_Flag) {
			crutch_Flag = myCurrent < myElements->count();
		}
		if (crutch_Flag) {
			WPTR(Heaper) 	returnValue;
			returnValue = myElements->fetch(myCurrent);
			return returnValue;
		} else {
			return NULL;
		}
	}
}


BooleanVar HashSetStepper::hasValue (){
	{	BooleanVar crutch_Flag;
		/* myElements != NULL && myCurrent < myElements->count() */
		
		crutch_Flag = myElements != NULL;
		if(crutch_Flag) {
			crutch_Flag = myCurrent < myElements->count();
		}
		return crutch_Flag;
	}
}


void HashSetStepper::step (){
	myCurrent += 1;
	this->verifyEntry();
}
/* protected: destruct */


void HashSetStepper::destruct (){
	if (myElements != NULL) {
		myElements->shareLess();
	}
	this->Stepper::destruct();
}
/* protected: creation */


HashSetStepper::HashSetStepper (APTR(SharedPtrArray) elements, Int32 current) {
	myElements = elements;
	myElements->shareMore();
	myCurrent = current;
	this->verifyEntry();
}
/* creation */


RPTR(Stepper) HashSetStepper::copy (){
	SPTR(Heaper) result;
	
	result = HashSetStepper::SomeSteppers->fetch();
	if (result == NULL) {
		RETURN_CONSTRUCT(HashSetStepper,(myElements, myCurrent));
	} else {
		WPTR(Stepper) 	returnValue;
		returnValue = new (result) HashSetStepper(myElements, myCurrent);
		return returnValue;
	}
}


void HashSetStepper::destroy (){
	if (!HashSetStepper::SomeSteppers->store(this)) {
		this->Stepper::destroy();
	}
}
/* private: */


void HashSetStepper::verifyEntry (){
	if (myElements != NULL) {
		if (myCurrent < myElements->count()) {
			myCurrent = myElements->indexPast(NULL, myCurrent);
			if (myCurrent == -1) {
				myCurrent = myElements->count();
			}
		}
		if (!this->hasValue()) {
			myElements->shareLess();
			myElements = NULL;
		}
	}
}



/* ************************************************************************ *
 * 
 *                    Class ImmuSetOnMu 
 *
 * ************************************************************************ */


/* creation */


RPTR(ImmuSet) ImmuSetOnMu::make (APTR(MuSet) aSet){
	RETURN_CONSTRUCT(ImmuSetOnMu,(aSet, tcsj));
}
/* accessing */


BooleanVar ImmuSetOnMu::hasMember (APTR(Heaper) someone){
	return setInternal->hasMember(someone);
}


BooleanVar ImmuSetOnMu::isEmpty (){
	return setInternal->isEmpty();
}


BooleanVar ImmuSetOnMu::isSubsetOf (APTR(ScruSet) another){
	return setInternal->isSubsetOf(another);
}
/* enumerating */


IntegerVar ImmuSetOnMu::count (){
	return setInternal->count();
}


RPTR(Stepper) ImmuSetOnMu::stepper (){
	WPTR(Stepper) 	returnValue;
	returnValue = setInternal->stepper();
	return returnValue;
}


RPTR(Heaper) ImmuSetOnMu::theOne (){
	WPTR(Heaper) 	returnValue;
	returnValue = setInternal->theOne();
	return returnValue;
}
/* operations */


RPTR(ImmuSet) ImmuSetOnMu::intersect (APTR(ScruSet) another){
	if (another->isEmpty()) {
		WPTR(ImmuSet) 	returnValue;
		returnValue = ImmuSet::make ();
		return returnValue;
	} else {
		SPTR(MuSet) tmp;
		
		tmp = CAST(MuSet,setInternal->copy());
		tmp->restrictTo(another);
		WPTR(ImmuSet) 	returnValue;
		returnValue = ImmuSet::from(tmp);
		return returnValue;
	}
}


RPTR(ImmuSet) ImmuSetOnMu::minus (APTR(ScruSet) another){
	if (another->isEmpty()) {
		return this;
	} else {
		SPTR(MuSet) tmp;
		
		tmp = CAST(MuSet,setInternal->copy());
		tmp->wipeAll(another);
		WPTR(ImmuSet) 	returnValue;
		returnValue = ImmuSet::from(tmp);
		return returnValue;
	}
}


RPTR(ImmuSet) ImmuSetOnMu::unionWith (APTR(ScruSet) another){
	if (another->isEmpty()) {
		return this;
	} else {
		SPTR(MuSet) tmp;
		
		if (setInternal->count() < another->count()) {
			WPTR(ImmuSet) 	returnValue;
			returnValue = another->asImmuSet()->unionWith(setInternal);
			return returnValue;
		}
		tmp = CAST(MuSet,setInternal->copy());
		tmp->storeAll(another);
		WPTR(ImmuSet) 	returnValue;
		returnValue = ImmuSet::from(tmp);
		return returnValue;
	}
}
/* adding-removing */


RPTR(ImmuSet) ImmuSetOnMu::with (APTR(Heaper) anElement){
	SPTR(MuSet) tmp;
	
	tmp = this->asMuSet();
	tmp->store(anElement);
	RETURN_CONSTRUCT(ImmuSetOnMu,(tmp, tcsj));
}


RPTR(ImmuSet) ImmuSetOnMu::without (APTR(Heaper) anElement){
	SPTR(MuSet) tmp;
	
	tmp = CAST(MuSet,setInternal->copy());
	tmp->wipe(anElement);
	WPTR(ImmuSet) 	returnValue;
	returnValue = ImmuSet::from(tmp);
	return returnValue;
}
/* conversion */


RPTR(MuSet) ImmuSetOnMu::asMuSet (){
	return CAST(MuSet,setInternal->copy());
}
/* protected: create */


ImmuSetOnMu::ImmuSetOnMu (APTR(MuSet) fromSet, TCSJ) {
	/* this set should be a copy for my own use */
	/* the pseudo constructor enforces this */
	
	setInternal = fromSet;
}


void ImmuSetOnMu::destruct (){
	{setInternal->destroy();  setInternal = NULL /* don't want stale (S/CHK)PTRs */;}
	this->ImmuSet::destruct();
}



/* ************************************************************************ *
 * 
 *                    Class TinyImmuSet 
 *
 * ************************************************************************ */


/* create */


RPTR(ImmuSet) TinyImmuSet::make (APTR(Heaper) aHeaper){
	RETURN_CONSTRUCT(TinyImmuSet,(aHeaper, tcsj));
}
/* This is an efficient implementation of ImmuSets for zero and one 
element sets. */


/* protected: creation */


TinyImmuSet::TinyImmuSet (APTR(Heaper) only, TCSJ) {
	/* Initialize a singleton immuset */
	
	elementInternal = only;
}
/* enumerating */


IntegerVar TinyImmuSet::count (){
	return 1;
}


RPTR(Stepper) TinyImmuSet::stepper (){
	WPTR(Stepper) 	returnValue;
	returnValue = Stepper::itemStepper(elementInternal);
	return returnValue;
}


RPTR(Heaper) TinyImmuSet::theOne (){
	return (Heaper*) elementInternal;
}
/* adding-removing */


RPTR(ImmuSet) TinyImmuSet::with (APTR(Heaper) anElement){
	if (elementInternal->isEqual(anElement)) {
		return this;
	} else {
		SPTR(MuSet) nuSet;
		
		nuSet = MuSet::make (anElement);
		nuSet->introduce(elementInternal);
		WPTR(ImmuSet) 	returnValue;
		returnValue = ImmuSet::make (nuSet);
		return returnValue;
	}
}


RPTR(ImmuSet) TinyImmuSet::without (APTR(Heaper) anElement){
	if (elementInternal->isEqual(anElement)) {
		WPTR(ImmuSet) 	returnValue;
		returnValue = ImmuSet::make ();
		return returnValue;
	}
	return this;
}
/* accessing */


BooleanVar TinyImmuSet::hasMember (APTR(Heaper) someone){
	return elementInternal->isEqual(someone);
}


BooleanVar TinyImmuSet::isEmpty (){
	return FALSE;
}


BooleanVar TinyImmuSet::isSubsetOf (APTR(ScruSet) another){
	return another->hasMember(elementInternal);
}
/* operations */


RPTR(ImmuSet) TinyImmuSet::intersect (APTR(ScruSet) another){
	if (another->hasMember(elementInternal)) {
		return this;
	} else {
		WPTR(ImmuSet) 	returnValue;
		returnValue = ImmuSet::make ();
		return returnValue;
	}
}


RPTR(ImmuSet) TinyImmuSet::minus (APTR(ScruSet) another){
	if (another->hasMember(elementInternal)) {
		WPTR(ImmuSet) 	returnValue;
		returnValue = ImmuSet::make ();
		return returnValue;
	} else {
		return this;
	}
}


RPTR(ImmuSet) TinyImmuSet::unionWith (APTR(ScruSet) another){
	if (another->isEmpty()) {
		return this;
	} else {
		SPTR(MuSet) nuSet;
		
		if (another->hasMember(elementInternal)) {
			WPTR(ImmuSet) 	returnValue;
			returnValue = another->asImmuSet();
			return returnValue;
		}
		if (another->count() > 5) {
			WPTR(ImmuSet) 	returnValue;
			returnValue = another->asImmuSet()->unionWith(this);
			return returnValue;
		}
		nuSet = MuSet::make (elementInternal);
		nuSet->storeAll(another);
		WPTR(ImmuSet) 	returnValue;
		returnValue = ImmuSet::make (nuSet);
		return returnValue;
	}
}
/* conversion */


RPTR(MuSet) TinyImmuSet::asMuSet (){
	WPTR(MuSet) 	returnValue;
	returnValue = MuSet::make (elementInternal);
	return returnValue;
}

#ifndef SETX_SXX
#include "setx.sxx"
#endif /* SETX_SXX */


#ifndef SETP_SXX
#include "setp.sxx"
#endif /* SETP_SXX */



#endif /* SETX_CXX */

