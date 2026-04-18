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

#ifndef CANOPYX_CXX
#define CANOPYX_CXX


#ifndef CHOOSEX_HXX
#include "choosex.hxx"
#endif /* CHOOSEX_HXX */

#ifndef CANOPYX_HXX
#include "canopyx.hxx"
#endif /* CANOPYX_HXX */

#ifndef CANOPYX_IXX
#include "canopyx.ixx"
#endif /* CANOPYX_IXX */

#ifndef CANOPYR_HXX
#include "canopyr.hxx"
#endif /* CANOPYR_HXX */

#ifndef CANOPYR_IXX
#include "canopyr.ixx"
#endif /* CANOPYR_IXX */

#ifndef CANOPYP_HXX
#include "canopyp.hxx"
#endif /* CANOPYP_HXX */

#ifndef CANOPYP_IXX
#include "canopyp.ixx"
#endif /* CANOPYP_IXX */


#ifndef DISKMANX_HXX
#include "diskmanx.hxx"
#endif /* DISKMANX_HXX */

#ifndef FLKINFOX_HXX
#include "flkinfox.hxx"
#endif /* FLKINFOX_HXX */

#ifndef FLUIDX_HXX
#include "fluidx.hxx"
#endif /* FLUIDX_HXX */

#ifndef GRANMAPX_HXX
#include "granmapx.hxx"
#endif /* GRANMAPX_HXX */

#ifndef INTEGERX_HXX
#include "integerx.hxx"
#endif /* INTEGERX_HXX */

#ifndef PRIMVALX_HXX
#include "primvalx.hxx"
#endif /* PRIMVALX_HXX */

#ifndef SPACEX_HXX
#include "spacex.hxx"
#endif /* SPACEX_HXX */

#ifndef TABLESX_HXX
#include "tablesx.hxx"
#endif /* TABLESX_HXX */

#ifndef TABTOOLX_HXX
#include "tabtoolx.hxx"
#endif /* TABTOOLX_HXX */

#ifndef TCLUDEX_HXX
#include "tcludex.hxx"
#endif /* TCLUDEX_HXX */




/* ************************************************************************ *
 * 
 *                    Class CanopyCrum 
 *
 * ************************************************************************ */



/* Initializers for CanopyCrum */

GPTR(PtrArray) OF1(Position OR(XnRegion)) CanopyCrum::FlagEndorsements = NULL;
GPTR(IDRegion) CanopyCrum::OtherClubs = NULL;
GPTR(CrossRegion) CanopyCrum::OtherEndorsements = NULL;
GPTR(Heaper2UInt32Cache) CanopyCrum::TheEFlagsCache = NULL;
GPTR(Heaper2UInt32Cache) CanopyCrum::ThePFlagsCache = NULL;



BEGIN_INIT_TIME(CanopyCrum,initTimeNonInherited) {
	REQUIRES (Heaper2UInt32Cache);
	CanopyCrum::TheEFlagsCache = Heaper2UInt32Cache::make (50);
	CanopyCrum::ThePFlagsCache = Heaper2UInt32Cache::make (50);
} END_INIT_TIME(CanopyCrum,initTimeNonInherited);



/* Initializers for CanopyCrum */






/* protected: flags */


UInt32 CanopyCrum::endorsementsFlags (APTR(CrossRegion) endorsements){
	/* Flag bits corresponding to endorsements */
	
	UInt32 result;
	UInt32 f;
	
	result = CanopyCrum::TheEFlagsCache->fetch(endorsements);
	{	BooleanVar crutch_Flag;
		/* result != UInt32Zero || endorsements->isEmpty() */
		
		crutch_Flag = result != UInt32Zero;
		if(!crutch_Flag) {
			crutch_Flag = endorsements->isEmpty();
		}
		if (crutch_Flag) {
			return result;
		}
	}
	f = CanopyCrum::firstEndorsementsFlag();
	if ( ! (CanopyCrum::FlagEndorsements != NULL) ) {
		BLAST(Must_be_initialized);
	}
	{
		UInt32 LoopFinal = CanopyCrum::FlagEndorsements->count();
		UInt32 i = UInt32Zero;
		for (;;) {
			if (i >= LoopFinal){
				break;
			}
			{
				BEGIN_CHOOSE(CanopyCrum::FlagEndorsements->get(i)) {
					BEGIN_KIND(Position,p) {
						if (endorsements->hasMember(p)) {
							result |= f;
						}
					} END_KIND;
					BEGIN_KIND(XnRegion,r) {
						if (endorsements->intersects(r)) {
							result |= f;
						}
					} END_KIND;
				} END_CHOOSE;
				f <<= 1;
			}
			i += 1;
		}
	}
	if (endorsements->intersects(CanopyCrum::OtherEndorsements)) {
		result |= CanopyCrum::otherEndorsementsFlag();
	}
	CanopyCrum::TheEFlagsCache->cache(endorsements, result);
	return result;
}


UInt32 CanopyCrum::permissionsFlags (APTR(IDRegion) permissions){
	/* Flag bits corresponding to permissions */
	
	UInt32 result;
	
	result = CanopyCrum::ThePFlagsCache->fetch(permissions);
	if (result != UInt32Zero) {
		return result;
	}
	
	if (permissions->hasMember(CurrentGrandMap.fluidGet()->publicClubID())) {
		result |= CanopyCrum::publicClubFlag();
	}
	if (CanopyCrum::OtherClubs == NULL) {
		CanopyCrum::OtherClubs = CAST(IDRegion,CurrentGrandMap.fluidGet()->publicClubID()->asRegion()->complement());
	}
	if (permissions->intersects(CanopyCrum::OtherClubs)) {
		result |= CanopyCrum::otherClubsFlag();
	}
	CanopyCrum::ThePFlagsCache->cache(permissions, result);
	return result;
}
/* private: flags */


Int32 CanopyCrum::endorsementFlagLimit (){
	/* Max number of special endorsement flags */
	
	/* 28 bits - 2 for permissions - 1 for all other endorsements 
	- 2 reserved */
	return 23;
}


UInt32 CanopyCrum::firstEndorsementsFlag (){
	/* Rightmost flag for interesting endorsements */
	
	return 8;
}


UInt32 CanopyCrum::otherClubsFlag (){
	/* The flag for any other Clubs */
	
	return 2;
}


UInt32 CanopyCrum::otherEndorsementsFlag (){
	/* Flag for all uninteresting endorsements */
	
	return 4;
}


UInt32 CanopyCrum::publicClubFlag (){
	/* The flag for the Universal Public Club */
	
	return 1;
}
/* flag setup */


void CanopyCrum::useEndorsementFlags (APTR(PtrArray) OF1(Position OR(XnRegion)) endorsements){
	/* Use a special flag to look for any of the these endorsements */
	
	{	BooleanVar crutch_Flag;
		/* CanopyCrum::FlagEndorsements == NULL || CanopyCrum::FlagEndorsements->contentsEqual(endorsements) */
		
		crutch_Flag = CanopyCrum::FlagEndorsements == NULL;
		if(!crutch_Flag) {
			crutch_Flag = CanopyCrum::FlagEndorsements->contentsEqual(endorsements);
		}
		if (!crutch_Flag) {
			BLAST(InvalidRequest);
		}
	}
	/* Tried to initialize twice */
	if (endorsements->count() > CanopyCrum::endorsementFlagLimit()) {
		BLAST(IndexOutOfBounds);
	}
	CanopyCrum::FlagEndorsements = CAST(PtrArray,endorsements->copy());
	CanopyCrum::OtherEndorsements = CAST(CrossRegion,CurrentGrandMap.fluidGet()->endorsementSpace()->fullRegion());
	{
		Int32 LoopFinal = CanopyCrum::FlagEndorsements->count();
		Int32 i = Int32Zero;
		for (;;) {
			if (i >= LoopFinal){
				break;
			}
			{
				BEGIN_CHOOSE(CanopyCrum::FlagEndorsements->get(i)) {
					BEGIN_KIND(Position,p) {
						CanopyCrum::OtherEndorsements = CAST(CrossRegion,CanopyCrum::OtherEndorsements->without(p));
					} END_KIND;
					BEGIN_KIND(XnRegion,r) {
						CanopyCrum::OtherEndorsements = CAST(CrossRegion,CanopyCrum::OtherEndorsements->minus(r));
					} END_KIND;
				} END_CHOOSE;
			}
			i += 1;
		}
	}
}
/* CanopyCrums form binary trees that acrete in a balanced fashion.  
No rebalancing ever happens.  Things are simply added to the tree up 
to the point thta the tree is balanced, then the height of the tree 
gets extended at the root.

Essentially, when the join of two trees is asked for, if the two 
trees aren't already parts of a larger tree, the algorithm attempts 
to find a place in one tree into which the other tree could 
completely fit without violating the depth constraint on the tree.  
It then returns the nearest root that contains both trees.  If it 
can't put one tree into the other, then it makes a new node that 
joins the two trees (probably with room to add other stuff deeper down).

myRefCount is only the count of Loafs or HCrums that point at the 
CanopyCrum.  It doesn't include other CanopyCrums.

12/2/92 Ravi
PropJoints have been suspended, and their function has been replaced 
by flag words in the CanopyCrum. Any interesting Club or endorsement 
gets a bit, and there is a bit for "any other Club" and "any other 
endorsement". Any criteria not given a bit of their own require an 
exhaustive search. These flags are widded by ORing up the canopy. 
When we start using more sophisticated hashing strategies, we will 
probably need to reanimate PropJoints. */


/* canopy operations */


RPTR(CanopyCrum) CanopyCrum::computeJoin (APTR(CanopyCrum) otherBCrum){
	/* Find a canopyCrum that is an anscestor to 
		 both the receiver and otherBCrum. otherBCrum 
		 is added to the canopy in a pseudo-balanced fashion. 
		 This demonstrates the beauty and power of caching
		 in object-oriented systems. */
	
	SPTR(MuSet) OF1(CanopyCrum) otherPath;
	SPTR(CanopyCrum) myRoot;
	SPTR(CanopyCrum) otherRoot;
	SPTR(CanopyCache) cache;
	
	if (this->isLE(otherBCrum)) {
		return this;
	}
	cache = this->canopyCache();
	otherPath = cache->pathFor(otherBCrum);
	otherRoot = cache->rootFor(otherBCrum);
	if (otherBCrum->isLE(this)) {
		WPTR(CanopyCrum) 	returnValue;
		returnValue = otherBCrum;
		return returnValue;
	}
	BEGIN_FOR_EACH(CanopyCrum,bCrum,(otherPath->stepper())) {
		if (bCrum->isLE(this)) {
			WPTR(CanopyCrum) 	returnValue;
			returnValue = bCrum;
			return returnValue;
		}
	} END_FOR_EACH;
	myRoot = cache->rootFor(this);
	if (myRoot->maxHeight() > otherRoot->maxHeight()) {
		WPTR(CanopyCrum) 	returnValue;
		returnValue = this->makeJoin(otherRoot);
		return returnValue;
	} else {
		WPTR(CanopyCrum) 	returnValue;
		returnValue = otherBCrum->makeJoin(myRoot);
		return returnValue;
	}
}


RPTR(Pair) OF1(CanopyCrum) CanopyCrum::expand (){
	/* split into two if possible, return the two leaves */
	
	{	BooleanVar crutch_Flag;
		/* child1 != NULL && child2 != NULL */
		
		crutch_Flag = child1 != NULL;
		if(crutch_Flag) {
			crutch_Flag = child2 != NULL;
		}
		if (crutch_Flag) {
			WPTR(Pair) OF1(CanopyCrum) 	returnValue;
			returnValue = Pair::make (this, this);
			return returnValue;
		}
	}
	if ( ! (child1 == NULL && child2 == NULL) ) {
		BLAST(Must_be_both_or_niether);
	}
	BEGIN_CONSISTENT(3) {
		(child1 = this->makeNew())->setParent(this);
		(child2 = this->makeNew())->setParent(this);
		this->canopyCache()->updateCacheForParent(child1, this);
		this->canopyCache()->updateCacheForParent(child2, this);
		this->diskUpdate();
	} END_CONSISTENT;
	WPTR(Pair) OF1(CanopyCrum) 	returnValue;
	returnValue = Pair::make (child1, child2);
	return returnValue;
}


void CanopyCrum::includeCanopy (APTR(CanopyCrum) otherCanopy){
	/* Install otherCanopy at or below the receiver. If the 
	otherCanopy fits in a lower branch, put it there. Otherwise, 
	replace the shortest child with a new child that contains the 
	shortest child and otherCanopy. */
	/* This should be a friend or private function or something. */
	
	/* Thing to do !!!! */
	
	/* Propagate the children's props into their new parent */
	/* Thing to do !!!! */
	
	/* When we have non-props to propagate, do those, too.  i.e., 
		height is currently handle by changeCanopy and will 
		be moved out to HeightChanger momentarily. */
	if ( ! (child1 != NULL) ) {
		BLAST(shouldnt_get_here_);
	}
	if (child1->heightDiff() >= otherCanopy->maxHeight()) {
		child1->includeCanopy(otherCanopy);
	} else {
		if (child2->heightDiff() >= otherCanopy->maxHeight()) {
			child2->includeCanopy(otherCanopy);
		} else {
			BEGIN_CONSISTENT(-1) {
				if (child1->maxHeight() > child2->maxHeight()) {
					(child2 = this->makeNewParent(child2, otherCanopy))->setParent(this);
				} else {
					(child1 = this->makeNewParent(child1, otherCanopy))->setParent(this);
				}
				/* Update the cache for the newly 
					installed subTree
												 because of the new 
					tree above it. */
				this->canopyCache()->updateCacheFor(otherCanopy);
				Sequencer::make (PropChanger::height(this), PropChanger::make (this))->schedule();
			} END_CONSISTENT;
		}
	}
}


BooleanVar CanopyCrum::isLE (APTR(CanopyCrum) other){
	/* Return true if other is equal to the receiver
		 or an anscestor (through the parent links). 
		 Use caches for efficiency. */
	
	return this->canopyCache()->pathFor(other)->hasMember(this);
}
/* canopy accessing */


void CanopyCrum::addPointer (APTR(Heaper) /* ignored */){
	/* Keep a refcount of diskful pointers to myself for disk 
	space management.  (Maybe backpointers later.) */
	
	myRefCount += 1;
	if (myRefCount == 1) {
		this->remember();
	}
	this->diskUpdate();
}


RPTR(CanopyCrum) CanopyCrum::fetchParent (){
	return (CanopyCrum*) parent;
}


UInt32 CanopyCrum::flags (){
	return myFlags;
}


IntegerVar CanopyCrum::heightDiff (){
	return maxH - minH;
}


BooleanVar CanopyCrum::isLeaf (){
	{	BooleanVar crutch_Flag;
		/* child1 == NULL && child2 == NULL */
		
		crutch_Flag = child1 == NULL;
		if(crutch_Flag) {
			crutch_Flag = child2 == NULL;
		}
		return crutch_Flag;
	}
}


IntegerVar CanopyCrum::maxHeight (){
	return maxH;
}


IntegerVar CanopyCrum::minHeight (){
	return minH;
}


void CanopyCrum::removePointer (APTR(Heaper) /* ignored */){
	/* Keep a refcount of diskful pointers to myself for disk 
	space management.  (Maybe backpointers later.)
		 Forget the object if it goes to zero. */
	
	/* Thing to do !!!! */
	
	/* Is calling destroy a bug? */
	myRefCount -= 1;
	/* Known bug !!!! */
	
	/* refCunt going to 0 with an outstanding AgendaItem. */
		/* (myRefCount == IntegerVar0 and: [parent == NULL])
				ifTrue: [self forget; destroy]
				ifFalse: [ */
	this->diskUpdate();
}


void CanopyCrum::setParent (APTR(CanopyCrum) OR(NULL) p){
	{	BooleanVar crutch_Flag;
		/* parent == NULL && p != NULL */
		
		crutch_Flag = parent == NULL;
		if(crutch_Flag) {
			crutch_Flag = p != NULL;
		}
		if (crutch_Flag) {
			this->remember();
		}
	}
	parent = p;
	{	BooleanVar crutch_Flag;
		/* myRefCount == IntegerVar0 && parent == NULL */
		
		crutch_Flag = myRefCount == IntegerVar0;
		if(crutch_Flag) {
			crutch_Flag = parent == NULL;
		}
		if (crutch_Flag) {
			{this->destroy();}
		} else {
			this->diskUpdate();
		}
	}
}
/* protected: */


void CanopyCrum::dismantle (){
	if ( ! (parent == NULL) ) {
		BLAST(We_can_only_dismantle_the_canopy_from_the_root_on_up_);
	}
	/* Thing to do !!!! */
	
	/* This first needs to remove all of myOwnProps from the canopy. */
	BEGIN_CONSISTENT(3) {
		if (child1 != NULL) {
			child1->setParent(NULL);
			child1 = NULL;
		}
		if (child2 != NULL) {
			child2->setParent(NULL);
			child2 = NULL;
		}
		this->Abraham::dismantle();
	} END_CONSISTENT;
}


RPTR(CanopyCrum) CanopyCrum::fetchChild1 (){
	return (CanopyCrum*) child1;
}


RPTR(CanopyCrum) CanopyCrum::fetchChild2 (){
	return (CanopyCrum*) child2;
}


UInt32 CanopyCrum::ownFlags (){
	return myOwnFlags;
}


void CanopyCrum::setOwnFlags (UInt32 newFlags){
	myOwnFlags = newFlags;
}
/* create */


CanopyCrum::CanopyCrum (UInt32 flags, TCSJ) {
	/* Make a canopyCrum for a root:  it has no children. */
	
	minH = maxH = 1;
	child1 = child2 = parent = NULL;
	myOwnFlags = flags;
	myFlags = myOwnFlags;
	myRefCount = IntegerVar0;
}


CanopyCrum::CanopyCrum (
		UInt32 flags, 
		APTR(CanopyCrum) first, 
		APTR(CanopyCrum) second) 
{
	/* prop must be empty */
	
	/* prop isEmpty assert: 'Must be empty'. */
	minH = maxH = 1;
	child1 = first;
	child1->setParent(this);
	child2 = second;
	child2->setParent(this);
	parent = NULL;
	myOwnFlags = flags;
	myFlags = flags | child1->flags() | child2->flags();
	myRefCount = IntegerVar0;
}
/* props */


RPTR(AgendaItem) CanopyCrum::propChanger (APTR(PropChange) /* change */, APTR(Prop) prop){
	/* Return an AgendaItem to propagate properties.
		
		NOTE: The AgendaItem returned is not yet scheduled.  Doing 
	so is up to my caller. */
	
	/* Atomically
			Update myOwnFlags but not myFlags (The latter includes the 
	widded stuff)
			return a PropChanger which at each step will update 
	myPropJoint and move to parent. */
	BEGIN_INSISTENT(3) {
		myOwnFlags |= prop->flags();
		this->diskUpdate();
		WPTR(AgendaItem) 	returnValue;
		returnValue = PropChanger::make (this);
		return returnValue;
	} END_INSISTENT;
}
/* testing */


UInt32 CanopyCrum::contentsHash (){
	/* This is only used by the TestPacker, so it includes all 
	persistent state whether or not
		 it is semantically interesting--myRefCount is not 
	semantically interesting. */
	
	return this->Abraham::contentsHash() ^ child1->hashForEqual() ^ child2->hashForEqual() ^ parent->hashForEqual() ^ IntegerPos::integerHash(minH) ^ IntegerPos::integerHash(maxH) ^ myFlags ^ myOwnFlags ^ IntegerPos::integerHash(myRefCount);
}
/* protected */


BooleanVar CanopyCrum::changeCanopy (){
	/* Figure out new props, etc. Return true if any changes may 
	require further propagation */
	/* At least one subclass adds behavior here by overriding and 
	calling 'super changeCanopy:' */
	
	BooleanVar result;
	
	/* If this is a leaf
			If any of my properties are changed
				Store the modification of the props.
		else
			save current flags
			recalculate the flags from myOwnFlags and the flags of the children
		If anything changed
			flag that the change must be written to disk
		return whether anything changed (which requires propagation 
	rootward) */
	if (this->isLeaf()) {
		result = myFlags != myOwnFlags;
		myFlags = myOwnFlags;
	} else {
		UInt32 before;
		
		before = myFlags;
		myFlags = myOwnFlags | child1->flags() | child2->flags();
		result = before != myFlags;
	}
	if (result) {
		this->diskUpdate();
	}
	return result;
}


BooleanVar CanopyCrum::changeHeight (){
	/* Figure out new height. Return true if changes may require 
	further propagation */
	
	IntegerVar oldMin;
	IntegerVar oldMax;
	
	/* If this is a leaf then it cannot have changed
		otherwise,
		recalculate the heights from the heights of the children
		If anything changed
			flag that the change must be written to disk
		return whether anything changed (which requires propagation 
	rootward) */
	if (this->isLeaf()) {
		return FALSE;
	}
	oldMin = minH;
	oldMax = maxH;
	if (child1->minHeight() > child2->minHeight()) {
		minH = child2->minHeight() + 1;
	} else {
		minH = child1->minHeight() + 1;
	}
	if (child1->maxHeight() > child2->maxHeight()) {
		maxH = child1->maxHeight() + 1;
	} else {
		maxH = child2->maxHeight() + 1;
	}
	{	BooleanVar crutch_Flag;
		/* oldMin != minH || oldMax != maxH */
		
		crutch_Flag = oldMin != minH;
		if(!crutch_Flag) {
			crutch_Flag = oldMax != maxH;
		}
		if (crutch_Flag) {
			this->diskUpdate();
			return TRUE;
		} else {
			return FALSE;
		}
	}
}
/* private */


RPTR(CanopyCrum) CanopyCrum::makeJoin (APTR(CanopyCrum) otherCanopy){
	/* Install otherCanopy as a subtree in the canopy containing 
	the receiver. Look below 
		the receiver and then in successively higher branches for a 
	branch that has 
		enough height difference to contain otherCanopy. */
	
	IntegerVar height;
	SPTR(CanopyCrum) cur;
	SPTR(CanopyCrum) prev;
	
	/* Thing to do !!!! */
	
	/* Propagate the children's props into their new parent */
	/* Thing to do !!!! */
	
	/* When we have non-props to propagate, do those, too.  i.e., 
		height is currently handle by changeCanopy and will 
		be moved out to HeightChanger momentarily. */
	height = otherCanopy->maxHeight();
	cur = this;
	while (!(cur == NULL || cur->heightDiff() >= height)) {
		prev = cur;
		cur = cur->fetchParent();
	}
	/* join the trees at the top */
		/* found a branch that can contain
						 otherCanopy. Place it in that branch. */
	if (cur == NULL) {
		cur = this->makeNewParent(prev, otherCanopy);
		this->canopyCache()->updateCacheForParent(prev, cur);
		this->canopyCache()->updateCacheForParent(otherCanopy, cur);
	} else {
		cur->includeCanopy(otherCanopy);
	}
	/* Cur now contains the closest parent shared between self 
	and otherCanopy. */
	WPTR(CanopyCrum) 	returnValue;
	returnValue = cur;
	return returnValue;
}



/* ************************************************************************ *
 * 
 *                    Class   BertCrum 
 *
 * ************************************************************************ */



/* Initializers for BertCrum */

BUILD_FLUID(CanopyCache,CurrentBertCanopyCache, CanopyCache::make (), DiskManager::emulsion());	/* in BertCrum */


/* Initializers for BertCrum */



/* instance creation */


RPTR(BertCrum) BertCrum::make (){
	BEGIN_CONSISTENT(1) {
		RETURN_CONSTRUCT(BertCrum,());
	} END_CONSISTENT;
}
/* flags */


UInt32 BertCrum::flagsFor (
		APTR(IDRegion) OR(NULL) permissions, 
		APTR(CrossRegion) OR(NULL) endorsements, 
		BooleanVar isNotPartializable, 
		BooleanVar isSensorWaiting)
{
	/* The flag word corresponding to the given props */
	
	UInt32 result;
	
	result = UInt32Zero;
	if (permissions != NULL) {
		result |= CanopyCrum::permissionsFlags(permissions);
	}
	if (endorsements != NULL) {
		result |= CanopyCrum::endorsementsFlags(endorsements);
	}
	if (isNotPartializable) {
		result |= BertCrum::isNotPartializableFlag();
	}
	if (isSensorWaiting) {
		result |= BertCrum::isSensorWaitingFlag();
	}
	return result;
}


UInt32 BertCrum::isNotPartializableFlag () CONST{
	/* Flag bit for active Editions */
	
	return 134217728;
}


UInt32 BertCrum::isSensorWaitingFlag () CONST{
	/* Flag bit for active Editions */
	
	return 67108864;
}
/* This implementation tracks the endorsement information with 
a strictly binary tree.  The tree gets heuristically balanced 
upon insertion of new elements in such a way that the ocrums 
pointing at a particular canopyCrum need not be updated.  
Therefore we should not bother storing backpointers.  I'm 
doing so currently in case we change algorithms.

Deletion may require backpointers to eliminate joins 
with the deleted crums. */


/* private: creation */


BertCrum::BertCrum () 
	: CanopyCrum(UInt32Zero, tcsj) {
	/* Make a canopyCrum for a root:  it has no children. */
	
	this->newShepherd();
}
/* protected: */


WPTR(CanopyCache) BertCrum::canopyCache (){
	/* should have one per Ent */
	
	WPTR(CanopyCache) 	returnValue;
	returnValue = CurrentBertCanopyCache.fluidGet();
	return returnValue;
}


RPTR(CanopyCrum) BertCrum::makeNew (){
	RETURN_CONSTRUCT(BertCrum,());
}
/* protected */


RPTR(CanopyCrum) BertCrum::makeNewParent (APTR(CanopyCrum) first, APTR(CanopyCrum) second){
	BEGIN_CONSISTENT(3) {
		RETURN_CONSTRUCT(BertCrum,(CAST(BertCrum,first), CAST(BertCrum,second)));
	} END_CONSISTENT;
}
/* instance creation */


BertCrum::BertCrum (APTR(BertCrum) first, APTR(BertCrum) second) 
	: CanopyCrum(UInt32Zero
		, first
		, second) 
{
	/* Create a new parent for two BertCrums.
		My client must bring my properties up to date.  This 
	constructor just makes a new parent whose properties are empty */
	
	/* Have the super do the basic creation. */
	this->newShepherd();
	this->canopyCache()->updateCacheForParent(this->fetchChild1(), this);
	this->canopyCache()->updateCacheForParent(this->fetchChild2(), this);
}
/* accessing */


BooleanVar BertCrum::isNotPartializable (){
	return (this->flags() & BertCrum::isNotPartializableFlag()) != UInt32Zero;
}


BooleanVar BertCrum::isSensorWaiting (){
	return (this->flags() & BertCrum::isSensorWaitingFlag()) != UInt32Zero;
}



/* ************************************************************************ *
 * 
 *                    Class   SensorCrum 
 *
 * ************************************************************************ */



/* Initializers for SensorCrum */

BUILD_FLUID(CanopyCache,CurrentSensorCanopyCache, CanopyCache::make (), DiskManager::emulsion());	/* in SensorCrum */


/* Initializers for SensorCrum */



/* pseudo constructors */


RPTR(SensorCrum) SensorCrum::make (){
	BEGIN_CONSISTENT(2) {
		RETURN_CONSTRUCT(SensorCrum,());
	} END_CONSISTENT;
}


RPTR(SensorCrum) SensorCrum::partial (){
	BEGIN_CONSISTENT(1) {
		RETURN_CONSTRUCT(SensorCrum,(SensorCrum::isPartialFlag(), tcsj));
	} END_CONSISTENT;
}
/* flags */


UInt32 SensorCrum::flagsFor (
		APTR(IDRegion) OR(NULL) permissions, 
		APTR(CrossRegion) OR(NULL) endorsements, 
		BooleanVar isPartial)
{
	/* The flag word corresponding to the given props */
	
	UInt32 result;
	
	result = UInt32Zero;
	if (permissions != NULL) {
		result |= CanopyCrum::permissionsFlags(permissions);
	}
	if (endorsements != NULL) {
		result |= CanopyCrum::endorsementsFlags(endorsements);
	}
	if (isPartial) {
		result |= SensorCrum::isPartialFlag();
	}
	return result;
}


UInt32 SensorCrum::isPartialFlag () CONST{
	/* Flag bit for existence of partiality */
	
	return 134217728;
}
/* This implementation is the same as BertCrums.  This will require 
pointers into the ent to implement delete (for archiving).  Canopy 
reorganization could be achieved by removing several orgls, then 
re-adding them (archive then restore). */


/* private: creation */


SensorCrum::SensorCrum () 
	: CanopyCrum(UInt32Zero, tcsj) {
	/* Make a canopyCrum for a root:  it has no children. */
	
	myBackfollowRecorders = ImmuSet::make ();
	this->newShepherd();
}


SensorCrum::SensorCrum (UInt32 flags, TCSJ) 
	: CanopyCrum(flags, tcsj) {
	/* Make a canopyCrum for a root:  it has no children. */
	
	myBackfollowRecorders = ImmuSet::make ();
	this->newShepherd();
}
/* protected: */


WPTR(CanopyCache) SensorCrum::canopyCache (){
	/* should have one per Ent */
	
	WPTR(CanopyCache) 	returnValue;
	returnValue = CurrentSensorCanopyCache.fluidGet();
	return returnValue;
}


RPTR(CanopyCrum) SensorCrum::makeNew (){
	/* Dean -- Thing to do !!!! */
	
	/* is this right? I want to preserve the partiality flag when 
		a partial loaf splits /ravi/5/7/92/ */
	if (this->isPartial()) {
		RETURN_CONSTRUCT(SensorCrum,(SensorCrum::isPartialFlag(), tcsj));
	} else {
		RETURN_CONSTRUCT(SensorCrum,());
	}
}
/* accessing */


RPTR(PropFinder) SensorCrum::checkRecorders (APTR(PropFinder) finder, APTR(SensorCrum) OR(NULL) scrum){
	/* Set off all recorders that respond to the change either in 
	me or in any of my ancestors up to but not including sCrum
		(If I am the same as sCrum, skip me as well.)
		(If sCrum is null, search through all my ancestors to a root 
	of the sensor canopy.)
		return simplest finder for looking at children */
	
	SPTR(SensorCrum) OR(NULL) next;
	
	/* from self rootward until told to stop (at sCrum or the root)
			trigger any matching recorders
		return a simplified finder for examining children. */
	next = this;
	while (next != NULL) {
		next = next->fetchNextAfterTriggeringRecorders(finder, scrum);
	}
	WPTR(PropFinder) 	returnValue;
	returnValue = finder->pass(this);
	return returnValue;
}


RPTR(SensorCrum) OR(NULL) SensorCrum::fetchNextAfterTriggeringRecorders (APTR(PropFinder) finder, APTR(SensorCrum) OR(NULL) sCrum){
	/* Set off all recorders in me that respond to the change, if 
	appropriate
		(If I am the same as sCrum, skip me.)
		If sCrum is null or not me, return my parent so caller can 
	iterate through my ancestors to sCrum or a root. */
	
	/* One step of the leafward walk of the O-plane, triggering recorders:
		Walk rootward on the sensor canopy, where many steps may 
	correspond to this single leafward step. */
	/* If we're the designated sCrum (where this work was already done)
		 	return without doing anything.  We're done.
		For each of our recorders
			if it hasn't gone extinct
				reanimate it long enough to
					trigger it, recording stamp if finder matches.
		Return a pointer to our parent (so caller can iterate this 
	operation rootward). */
	{	BooleanVar crutch_Flag;
		/* sCrum != NULL && this->isEqual(sCrum) */
		
		crutch_Flag = sCrum != NULL;
		if(crutch_Flag) {
			crutch_Flag = this->isEqual(sCrum);
		}
		if (crutch_Flag) {
			return NULL;
		}
	}
	BEGIN_FOR_EACH(RecorderFossil,fossil,(myBackfollowRecorders->stepper())) {
		if (!fossil->isExtinct()) {
			BEGIN_REANIMATE(fossil,ResultRecorder,recorder) {
				recorder->triggerIfMatching(finder, fossil);
			} END_REANIMATE;
		}
	} END_FOR_EACH;
	return CAST(SensorCrum,this->fetchParent());
}


BooleanVar SensorCrum::isPartial (){
	return (this->flags() & SensorCrum::isPartialFlag()) != UInt32Zero;
}


RPTR(ImmuSet) OF1(RecorderFossil) SensorCrum::recorders (){
	return (ImmuSet*) myBackfollowRecorders;
}


RPTR(AgendaItem) SensorCrum::recordingAgent (APTR(RecorderFossil) recorder){
	/* NOTE: The AgendaItem returned is not yet scheduled.  Doing 
	so is up to my caller. */
	
	/* If the recorder we're adding isn't already present here
			pack up the fossil for shipment to the hoister
			atomically
				Install the recorder here
				return a RecorderHoister to propagate the side-effects and 
	anneal the canopy
				(The RecorderHoister will update myFlags)
		return an empty agenda (to satisfy our contract) */
	if (!myBackfollowRecorders->hasMember(recorder)) {
		SPTR(ImmuSet) OF1(RecorderFossil) cargo;
		
		cargo = ImmuSet::make ()->with(recorder);
		BEGIN_CONSISTENT(2) {
			this->installRecorders(cargo);
			this->diskUpdate();
			WPTR(AgendaItem) 	returnValue;
			returnValue = RecorderHoister::make (this, cargo);
			return returnValue;
		} END_CONSISTENT;
	}
	WPTR(AgendaItem) 	returnValue;
	returnValue = Agenda::make ();
	return returnValue;
}


void SensorCrum::removeRecorders (APTR(ImmuSet) OF1(RecorderFossil) recorders){
	/* Remove recorders because they have migrated rootward.
		Recalculate myOwnFlags and myFlags. */
	
	UInt32 f;
	
	myBackfollowRecorders = myBackfollowRecorders->minus(recorders);
	this->diskUpdate();
	f = UInt32Zero;
	BEGIN_FOR_EACH(RecorderFossil,fossil,(myBackfollowRecorders->stepper())) {
		if (!fossil->isExtinct()) {
			BEGIN_REANIMATE(fossil,ResultRecorder,recorder) {
				f |= recorder->sensorProp()->flags();
			} END_REANIMATE;
		}
	} END_FOR_EACH;
	this->setOwnFlags(f);
	this->changeCanopy();
}
/* private: */


void SensorCrum::installRecorders (APTR(ImmuSet) OF1(RecorderFossil) recorders){
	/* Installs the recorders in my set and updates myOwnProp accordingly.
		The caller has already checked that none of these recorders 
	are already installed here.
		The caller also handles updating myFlags.
		The caller also handles all issues of rootward propagation 
	of these changes.
		The caller also does the 'diskUpdate'.
		
		This is a separate method because it's called once by the 
	code that installs a new recorder, and again by the code that 
	recursively hoists recurders up the canopy.
		
		add the new recorders to my set
		for each new recorder
			if it hasn't gone extinct
				extract its properties
				union them into my own */
	
	myBackfollowRecorders = myBackfollowRecorders->unionWith(recorders);
	BEGIN_FOR_EACH(RecorderFossil,fossil,(recorders->stepper())) {
		if (!fossil->isExtinct()) {
			SPTR(Prop) prop;
			
			BEGIN_REANIMATE(fossil,ResultRecorder,recorder) {
				prop = recorder->sensorProp();
			} END_REANIMATE;
			this->setOwnFlags(this->ownFlags() | prop->flags());
		}
	} END_FOR_EACH;
}
/* protected */


RPTR(CanopyCrum) SensorCrum::makeNewParent (APTR(CanopyCrum) first, APTR(CanopyCrum) second){
	BEGIN_CONSISTENT(3) {
		RETURN_CONSTRUCT(SensorCrum,(CAST(SensorCrum,first), CAST(SensorCrum,second)));
	} END_CONSISTENT;
}
/* instance creation */


SensorCrum::SensorCrum (APTR(SensorCrum) first, APTR(SensorCrum) second) 
	: CanopyCrum(UInt32Zero
		, first
		, second) 
{
	/* Create a new parent for two SensorCrums.
		This constructor just makes a new parent whose properties 
	are empty. My client must bring my properties up to date. */
	
	/* Have the super do the basic creation. */
	this->newShepherd();
	myBackfollowRecorders = ImmuSet::make ();
	this->canopyCache()->updateCacheForParent(this->fetchChild1(), this);
	this->canopyCache()->updateCacheForParent(this->fetchChild2(), this);
}



/* ************************************************************************ *
 * 
 *                    Class PropChanger 
 *
 * ************************************************************************ */


/* creation */


RPTR(PropChanger) PropChanger::height (APTR(CanopyCrum) OR(NULL) crum){
	BEGIN_CONSISTENT(3) {
		RETURN_CONSTRUCT(HeightChanger,(crum, tcsj));
	} END_CONSISTENT;
}


RPTR(PropChanger) PropChanger::make (APTR(CanopyCrum) OR(NULL) crum){
	BEGIN_CONSISTENT(2) {
		RETURN_CONSTRUCT(ActualPropChanger,(crum, tcsj));
	} END_CONSISTENT;
}
/* Used to propagate some prop(erty) change rootwards in some canopy. 
 Each step propagates it one step parentwards, until it gets to a 
local root or no further propagation in necessary. */


/* protected: accessing */


RPTR(CanopyCrum) OR(NULL) PropChanger::fetchCrum (){
	return (CanopyCrum*) myCrum;
}


void PropChanger::setCrum (APTR(CanopyCrum) OR(NULL) aCrum){
	/* Move our placeholding finger to a new crum, updating 
	refcounts accordingly */
	
	/* atomically (though we've probably already gone nuclear)
			If there is a new crum
				bump its refcount.
			If there is an old crum
				unbump its refcount.
			Remember the new crum. */
	BEGIN_CONSISTENT(3) {
		if (aCrum != NULL) {
			aCrum->addPointer(this);
		}
		if (myCrum != NULL) {
			myCrum->removePointer(this);
		}
		myCrum = aCrum;
		this->diskUpdate();
	} END_CONSISTENT;
}
/* accessing */
/* creation */


PropChanger::PropChanger (APTR(CanopyCrum) OR(NULL) crum, TCSJ) {
	myCrum = crum;
	if (myCrum == NULL) {
		myCrum->addPointer(this);
	}
}


PropChanger::PropChanger (APTR(CanopyCrum) OR(NULL) crum, UInt32 hash) 
	: AgendaItem(hash, tcsj) {
	/* Special constructor for becoming this class */
	
	/* I don't 'myCrum addPointer: self' because, in becoming, my 
		old self is presumed to already have pointed at the crum */
	myCrum = crum;
}


void PropChanger::dismantle (){
	BEGIN_CONSISTENT(2) {
		if (myCrum != NULL) {
			myCrum->removePointer(this);
			myCrum = NULL;
		}
		this->AgendaItem::dismantle();
	} END_CONSISTENT;
}



/* ************************************************************************ *
 * 
 *                    Class   ActualPropChanger 
 *
 * ************************************************************************ */


/* Used to propagate some prop(erty) change rootwards in some canopy. 
 Each step propagates it one step parentwards, until it gets to a 
local root or no further propagation in necessary. */


/* creation */


ActualPropChanger::ActualPropChanger (APTR(CanopyCrum) crum, TCSJ) 
	: PropChanger(crum, tcsj) {
	this->newShepherd();
}


ActualPropChanger::ActualPropChanger (
		APTR(CanopyCrum) OR(NULL) crum, 
		UInt32 hash, 
		APTR(FlockInfo) info) 

	: PropChanger(crum, hash) {
	/* Special constructor for becoming this class */
	
	this->flockInfo(info);
	this->diskUpdate();
}
/* accessing */


BooleanVar ActualPropChanger::step (){
	/* If I'm done
			Stop me before I step again!.
		atomically
			Do one step of property changing.
				If more needs to be done, step rootward.  (myCrum is set 
	to NULL if I am the root.)
				else I'm done.  Remember it by setting myCrum to NULL
		return a flag saying whether I'm done */
	if (this->fetchCrum() == NULL) {
		return FALSE;
	}
	BEGIN_CONSISTENT(3) {
		if (this->fetchCrum()->changeCanopy()) {
			this->setCrum(this->fetchCrum()->fetchParent());
		} else {
			this->setCrum(NULL);
		}
	} END_CONSISTENT;
	return this->fetchCrum() != NULL;
}



/* ************************************************************************ *
 * 
 *                    Class CanopyCache 
 *
 * ************************************************************************ */


/* make */


RPTR(CanopyCache) CanopyCache::make (){
	RETURN_CONSTRUCT(CanopyCache,());
}
/* protected: creation */


CanopyCache::CanopyCache () {
	myCachedCrum = NULL;
	myCachedRoot = NULL;
	myCachedPath = MuSet::make ();
}
/* operations */


void CanopyCache::clearCache (){
	/* Clear the cache because the canopy has
		 changed.  This ought to destroy the cachedPath. 
		 This must be cleared after every episode!!! */
	
	myCachedCrum = NULL;
	myCachedRoot = NULL;
	myCachedPath = MuSet::make ();
}


RPTR(MuSet) OF1(CanopyCrum) CanopyCache::pathFor (APTR(CanopyCrum) canopyCrum){
	/* Return the set of all crums from canopyCrum 
		(inclusive) to the top of canopyCrum's canopy. */
	
	if (!((Heaper * ) myCachedCrum == canopyCrum)) {
		SPTR(CanopyCrum) cur;
		
		cur = canopyCrum;
		myCachedCrum = canopyCrum;
		myCachedRoot = canopyCrum;
		myCachedPath = MuSet::make ();
		while (cur != NULL) {
			myCachedRoot = cur;
			myCachedPath->store(cur);
			cur = cur->fetchParent();
		}
	}
	return (MuSet*) myCachedPath;
}


RPTR(CanopyCrum) CanopyCache::rootFor (APTR(CanopyCrum) bertCrum){
	/* Return the crum at the top of canopyCrum's canopy. */
	
	this->pathFor(bertCrum);
	return (CanopyCrum*) myCachedRoot;
}


void CanopyCache::updateCacheForParent (APTR(CanopyCrum) childCrum, APTR(CanopyCrum) parentCrum){
	/* If the cache contains childCrum it must be made 
		to contain childCrum's new parent: parentCrum. 
		Also update CachedRoot. */
	
	if (myCachedPath->hasMember(childCrum)) {
		myCachedPath->store(parentCrum);
		if ((Heaper * ) myCachedRoot == childCrum) {
			myCachedRoot = parentCrum;
		}
	}
}


void CanopyCache::updateCacheFor (APTR(CanopyCrum) canopyCrum){
	/* If the cache contains canopyCrum, it must be updated 
		because canopyCrum has new parents. For now, just 
		invalidate the cache. */
	
	if ((Heaper * ) myCachedCrum == canopyCrum) {
		this->clearCache();
	}
}
/* testing */


UInt32 CanopyCache::actualHashForEqual (){
	return Heaper::takeOop();
}



/* ************************************************************************ *
 * 
 *                    Class Heaper2UInt32Cache 
 *
 * ************************************************************************ */



/* Initializers for Heaper2UInt32Cache */


BEGIN_INIT_TIME(Heaper2UInt32Cache,initTimeNonInherited) {
	REQUIRES (PrimArray);
	REQUIRES (PrimeSizeProvider);
} END_INIT_TIME(Heaper2UInt32Cache,initTimeNonInherited);



/* Initializers for Heaper2UInt32Cache */



/* create */


RPTR(Heaper2UInt32Cache) Heaper2UInt32Cache::make (Int32 count, UInt32 empty/* = UInt32Zero*/){
	RETURN_CONSTRUCT(Heaper2UInt32Cache,(PrimeSizeProvider::make ()->uInt32PrimeAfter(count), empty));
}
/* Caches a mapping from Heapers (using isEqual / hashForEqual) to 
UInt32s. Returns myEmptyValue if there is no cached mapping. */


/* accessing */


void Heaper2UInt32Cache::cache (APTR(Heaper) key, UInt32 value){
	/* Cache a value for a key */
	
	Int32 index;
	
	index = key->hashForEqual() % myKeys->count();
	myKeys->store(index, key);
	myValues->storeUInt(index, value);
}


UInt32 Heaper2UInt32Cache::fetch (APTR(Heaper) key){
	/* Return the cached value for the key, or my empty value if 
	there is none */
	
	Int32 index;
	SPTR(Heaper) k;
	
	index = key->hashForEqual() % myKeys->count();
	k = myKeys->fetch(index);
	{	BooleanVar crutch_Flag;
		/* k != NULL && (k == key || k->isEqual(key)) */
		
		crutch_Flag = k != NULL;
		if(crutch_Flag) {
			crutch_Flag = k == key;
			if(!crutch_Flag) {
				crutch_Flag = k->isEqual(key);
			}
		}
		if (crutch_Flag) {
			return myValues->uIntAt(index);
		} else {
			return myEmptyValue;
		}
	}
}


UInt32 Heaper2UInt32Cache::get (APTR(Heaper) key){
	/* Return the cached value for the key, or BLAST if there is none */
	
	Int32 index;
	SPTR(Heaper) k;
	
	index = key->hashForEqual() % myKeys->count();
	k = myKeys->fetch(index);
	{	BooleanVar crutch_Flag;
		/* k != NULL && (k == key || k->isEqual(key)) */
		
		crutch_Flag = k != NULL;
		if(crutch_Flag) {
			crutch_Flag = k == key;
			if(!crutch_Flag) {
				crutch_Flag = k->isEqual(key);
			}
		}
		if (!crutch_Flag) {
			BLAST(NotInTable);
		}
	}
	return myValues->uIntAt(index);
}
/* create */


Heaper2UInt32Cache::Heaper2UInt32Cache (Int32 count, UInt32 empty) {
	myKeys = PtrArray::nulls(count);
	myValues = UInt32Array::make (count);
	myEmptyValue = empty;
	if (empty != UInt32Zero) {
		myValues->storeAll(PrimIntValue::make (empty));
	}
}



/* ************************************************************************ *
 * 
 *                    Class HeightChanger 
 *
 * ************************************************************************ */


/* creation */


RPTR(HeightChanger) HeightChanger::make (APTR(CanopyCrum) crum, APTR(PropChange) /* change */){
	/* Known bug !!!! */
	
	/* BOGUS */
	BEGIN_CONSISTENT(3) {
		RETURN_CONSTRUCT(HeightChanger,(crum, tcsj));
	} END_CONSISTENT;
}
/* Used to propagate some prop(erty) change rootwards in some canopy. 
 Each step propagates it one step parentwards, until it gets to a 
local root or no further propagation in necessary. */


/* creation */


HeightChanger::HeightChanger (APTR(CanopyCrum) crum, TCSJ) 
	: PropChanger(crum, tcsj) {
	this->newShepherd();
}


HeightChanger::HeightChanger (
		APTR(CanopyCrum) OR(NULL) crum, 
		UInt32 hash, 
		APTR(FlockInfo) info) 

	: PropChanger(crum, hash) {
	/* Special constructor for becoming this class */
	
	this->flockInfo(info);
	this->diskUpdate();
}
/* accessing */


BooleanVar HeightChanger::step (){
	/* If I'm done
			Stop me before I step again!.
		atomically
			Do one step of height recalculation.
				If more needs to be done, step rootward.  (myCrum is set 
	to NULL if I am the root.)
				else I'm done.  Remember it by setting myCrum to NULL
		return a flag saying whether I'm done */
	if (this->fetchCrum() == NULL) {
		return FALSE;
	}
	BEGIN_CONSISTENT(3) {
		if (this->fetchCrum()->changeHeight()) {
			this->setCrum(this->fetchCrum()->fetchParent());
		} else {
			this->setCrum(NULL);
		}
	} END_CONSISTENT;
	return this->fetchCrum() != NULL;
}

#ifndef CANOPYX_SXX
#include "canopyx.sxx"
#endif /* CANOPYX_SXX */


#ifndef CANOPYR_SXX
#include "canopyr.sxx"
#endif /* CANOPYR_SXX */


#ifndef CANOPYP_SXX
#include "canopyp.sxx"
#endif /* CANOPYP_SXX */



#endif /* CANOPYX_CXX */

