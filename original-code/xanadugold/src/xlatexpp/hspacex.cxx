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

#ifndef HSPACEX_CXX
#define HSPACEX_CXX


#ifndef CHOOSEX_HXX
#include "choosex.hxx"
#endif /* CHOOSEX_HXX */

#ifndef HSPACEX_HXX
#include "hspacex.hxx"
#endif /* HSPACEX_HXX */

#ifndef HSPACEX_IXX
#include "hspacex.ixx"
#endif /* HSPACEX_IXX */

#ifndef HSPACEP_HXX
#include "hspacep.hxx"
#endif /* HSPACEP_HXX */

#ifndef HSPACEP_IXX
#include "hspacep.ixx"
#endif /* HSPACEP_IXX */


#ifndef NXCVRX_HXX
#include "nxcvrx.hxx"
#endif /* NXCVRX_HXX */

#ifndef STEPPERX_HXX
#include "stepperx.hxx"
#endif /* STEPPERX_HXX */

#ifndef XFRSPECX_HXX
#include "xfrspecx.hxx"
#endif /* XFRSPECX_HXX */




/* ************************************************************************ *
 * 
 *                    Class HeaperSpace 
 *
 * ************************************************************************ */



/* Initializers for HeaperSpace */

GPTR(HeaperSpace) HeaperSpace::TheHeaperSpace = NULL;



BEGIN_INIT_TIME(HeaperSpace,initTimeNonInherited) {
	CONSTRUCT(HeaperSpace::TheHeaperSpace,HeaperSpace,());
} END_INIT_TIME(HeaperSpace,initTimeNonInherited);



/* Initializers for HeaperSpace */






/* pseudo constructors */
/* rcvr pseudo constructor */


RPTR(Heaper) HeaperSpace::make (APTR(Rcvr) rcvr){
	CAST(SpecialistRcvr,rcvr)->registerIbid(HeaperSpace::TheHeaperSpace);
	WPTR(Heaper) 	returnValue;
	returnValue = HeaperSpace::TheHeaperSpace;
	return returnValue;
}
/* A HeaperSpace is one whose positions represent the identity of 
individual Heapers.  Identity of a Heaper is determined according by 
its response to "isEqual" and "hashForEqual" (see "The Equality of 
Decisions" for a bunch of surprising issues regarding Heaper 
equality).  A region is a HeaperSpace is a SetRegion (see SetRegion). 
 As a result of having HeaperSpaces, one can use the identity of 
Heapers to index into hash tables, and still obey the convention that 
a table maps from positions in some coordinate space.
	
	HeaperSpaces cannot (yet?) be used as the domain space for Xanadu 
Stamps, and therefore also not as the domain space of an 
IndexedWaldo.  In order to do this, the Heapers in question would 
have to persist in a way that Xanadu doesn't provide for.
	
	As is typical for an unordered space, the only Dsp for this space is 
the identity Dsp.  No type or pseudo-constructor is exported 
however--the Dsp is gotten by converting a HeaperSpace to a Dsp.  
Similarly, no heaper-specific type or pseudo-constructor is exported 
for my regions.  The conversions are sufficient.  The resulting 
regions are guaranteed to be SetRegions. */


/* creation */


HeaperSpace::HeaperSpace () 
	: CoordinateSpace(HeaperRegion::make ()
		, HeaperRegion::make ()->complement()
		, HeaperDsp::make ()
		, NULL
		, NULL) 
{
	
}
/* testing */


UInt32 HeaperSpace::actualHashForEqual (){
	/* is equal to any basic space on the same category of positions */
	
	return this->getCategory()->hashForEqual() + 1;
}


BooleanVar HeaperSpace::isEqual (APTR(Heaper) anObject){
	/* is equal to any basic space on the same category of positions */
	
	return anObject->getCategory() == this->getCategory();
}



/* ************************************************************************ *
 * 
 *                    Class UnOrdered 
 *
 * ************************************************************************ */


/* A convenient superclass of all Positions which have no natural 
ordering.  See UnOrdered::isGE for the defining property of this 
class.  This class should probably go away and UnOrdered::isGE 
distributed to the subclasses. */


/* accessing */
/* testing */


UInt32 UnOrdered::actualHashForEqual (){
	return Heaper::takeOop();
}

	/* automatic 0-argument constructor */
UnOrdered::UnOrdered() {}



/* ************************************************************************ *
 * 
 *                    Class   HeaperAsPosition 
 *
 * ************************************************************************ */


/* pseudo constructors */


RPTR(HeaperAsPosition) HeaperAsPosition::make (APTR(Heaper) heaper){
	/* Return a HeaperAsPosition which represents the identity of 
	this Heaper.  The resulting HeaperAsPosition will strongly 
	retain the original Heaper against garbage collection (though 
	not of course against manual deletion).  See wimpyAsPosition */
	
	RETURN_CONSTRUCT(StrongAsPosition,(heaper, tcsj));
}
/* A position in a HeaperSpace that represents the identity of some 
particular Heaper.  See class comment in HeaperSpace. */


/* testing */


UInt32 HeaperAsPosition::actualHashForEqual (){
	return Heaper::takeOop();
}
/* accessing */

	/* automatic 0-argument constructor */
HeaperAsPosition::HeaperAsPosition() {}



/* ************************************************************************ *
 * 
 *                    Class HeaperDsp 
 *
 * ************************************************************************ */



/* Initializers for HeaperDsp */

/* Initializer inherited from IdentityDsp */

IdentityDsp * HeaperDsp::theDsp = NULL;


/* Initializer inherited from IdentityDsp */


BEGIN_INIT_TIME(HeaperDsp,initTimeInherited) {
	CONSTRUCT_ON(PERSISTENT,HeaperDsp::theDsp,HeaperDsp,());
} END_INIT_TIME(HeaperDsp,initTimeInherited);



/* Initializers for HeaperDsp */

/* Initializer inherited from IdentityDsp */




/* Initializer inherited from IdentityDsp */



/* pseudo constructors */


RPTR(Dsp) HeaperDsp::make (){
	return (HeaperDsp * ) ((IdentityDsp * ) HeaperDsp::theDsp);
}


RPTR(Heaper) HeaperDsp::make (APTR(Rcvr) rcvr){
	CAST(SpecialistRcvr,rcvr)->registerIbid(HeaperDsp::theDsp);
	WPTR(Heaper) 	returnValue;
	returnValue = HeaperDsp::theDsp;
	return returnValue;
}
/* accessing */


RPTR(CoordinateSpace) HeaperDsp::coordinateSpace (){
	WPTR(CoordinateSpace) 	returnValue;
	returnValue = HeaperSpace::make ();
	return returnValue;
}
/* creation */


HeaperDsp::HeaperDsp () {
	
}



/* ************************************************************************ *
 * 
 *                    Class SetRegion 
 *
 * ************************************************************************ */


/* How do you make regions for spaces whose positions
		a) have no orderring (i.e., either no ordering can be imposed (as 
			in HeaperSpace) or it is undesirable to impose one (as curently 
			in IDSpace)); and
		b) there is an inifinte supply of new positions, and you can only 
			name the positions you've encountered?
			
	SetRegion is our answer to that.  To start with, a set region can 
simply be an enumeration of the positions which are its members.  
However, because the complement of an XuRegion must be a valid 
XuRegion, and we have no other representation of the infinite set of 
positions left over, we must also be able to represent the region 
consisting of all positions except those explicitly enumerated.  
Every SetRegion must either have a finite number of positions, or it 
must cover all the space except for a finite number of positions.
	
	With regard to degrees of simplicity (see class comment in 
XuRegion), we currently only have distinctions.  There are no 
non-distinctions, and therefore no non-simple SetRegions.  
Interesting cases are:
	
		1) empty region
		2) full region
		3) singleton set (single member)
		4) singleton hole (single non-member)
		5) region with more than 1, but a finite number, of members
		6) region with more than 1, but a finite number, of non-members
	
	Cases 1, 3, and 5 can be considered the "positive" regions, and 
cases 2, 4, and 6 the "negative" ones.
	
	Because we only have distinctions (which we are currently doing for 
an internal reason which will probably go away), we forego the 
ability to use the generic XuRegion protocol to decompose complex 
regions into simpler ones.  Instead we provide SetRegion specific 
protocol ("positions" and "isComplement").  
	
	At a later time, we will probably have cases 1 thru 4 above be the 
only distinctions, case 6 be a simple region but not a distinction, 
and have case 5 be a non-simple region.  (These choices are all 
consistent with the letter and spirit of the simplicity framework 
documented in XuRegion.  Simple regions must be the *intersection* of 
distinctions, therefore case 5 cannot be a simple non-distinction.)  
Please try to write your software so that it'll be insensitive to 
this change.  Thanks.
	
	SetRegion is an abstract superclass useful for defining regions for 
spaces which have the constraints listed above. */


/* accessing */


RPTR(XnRegion) SetRegion::asSimpleRegion (){
	return this;
}


RPTR(ScruSet) OF1(XnRegion) SetRegion::distinctions (){
	WPTR(ScruSet) OF1(XnRegion) 	returnValue;
	returnValue = ImmuSet::make ()->with(this);
	return returnValue;
}


RPTR(Stepper) SetRegion::simpleRegions (APTR(OrderSpec) /* order *//* = NULL*/){
	/* Make up a singleton set containing the whole region */
	
	WPTR(Stepper) 	returnValue;
	returnValue = Stepper::itemStepper(this);
	return returnValue;
}
/* enumerating */


IntegerVar SetRegion::count (){
	if (myIsComplement) {
		BLAST(NotEnumerable);
	}
	return myPositions->count();
}


BooleanVar SetRegion::isEnumerable (APTR(OrderSpec) order/* = NULL*/){
	return !myIsComplement;
}


RPTR(Position) SetRegion::theOne (){
	if (this->count() != 1) {
		BLAST(NotOneElement);
	}
	return CAST(Position,myPositions->theOne());
}
/* operations */


RPTR(XnRegion) SetRegion::complement (){
	WPTR(XnRegion) 	returnValue;
	returnValue = this->makeNew(!myIsComplement, myPositions);
	return returnValue;
}


RPTR(XnRegion) SetRegion::intersect (APTR(XnRegion) region){
	if (region->isEmpty()) {
		WPTR(XnRegion) 	returnValue;
		returnValue = region;
		return returnValue;
	} else {
		WPTR(SetRegion) other;
		
		other = CAST(SetRegion,region);
		if (myIsComplement) {
			if (other->isComplement()) {
				WPTR(XnRegion) 	returnValue;
				returnValue = this->makeNew(TRUE, myPositions->unionWith(other->positions()));
				return returnValue;
			} else {
				WPTR(XnRegion) 	returnValue;
				returnValue = this->makeNew(FALSE, other->positions()->minus(myPositions));
				return returnValue;
			}
		} else {
			if (other->isComplement()) {
				WPTR(XnRegion) 	returnValue;
				returnValue = this->makeNew(FALSE, myPositions->minus(other->positions()));
				return returnValue;
			} else {
				WPTR(XnRegion) 	returnValue;
				returnValue = this->makeNew(FALSE, myPositions->intersect(other->positions()));
				return returnValue;
			}
		}
	}
}


RPTR(XnRegion) SetRegion::minus (APTR(XnRegion) other){
	if (other->isEmpty()) {
		return this;
	} else {
		WPTR(SetRegion) set;
		
		set = CAST(SetRegion,other);
		if (myIsComplement) {
			if (set->isComplement()) {
				WPTR(XnRegion) 	returnValue;
				returnValue = this->makeNew(FALSE, set->positions()->minus(myPositions));
				return returnValue;
			} else {
				WPTR(XnRegion) 	returnValue;
				returnValue = this->makeNew(TRUE, set->positions()->unionWith(myPositions));
				return returnValue;
			}
		} else {
			if (set->isComplement()) {
				WPTR(XnRegion) 	returnValue;
				returnValue = this->makeNew(FALSE, set->positions()->intersect(myPositions));
				return returnValue;
			} else {
				WPTR(XnRegion) 	returnValue;
				returnValue = this->makeNew(FALSE, myPositions->minus(set->positions()));
				return returnValue;
			}
		}
	}
}


RPTR(XnRegion) SetRegion::simpleUnion (APTR(XnRegion) other){
	WPTR(XnRegion) 	returnValue;
	returnValue = this->unionWith(other);
	return returnValue;
}


RPTR(XnRegion) SetRegion::unionWith (APTR(XnRegion) region){
	if (region->isEmpty()) {
		return this;
	} else {
		WPTR(SetRegion) other;
		
		other = CAST(SetRegion,region);
		if (myIsComplement) {
			if (other->isComplement()) {
				WPTR(XnRegion) 	returnValue;
				returnValue = this->makeNew(TRUE, myPositions->intersect(other->positions()));
				return returnValue;
			} else {
				WPTR(XnRegion) 	returnValue;
				returnValue = this->makeNew(TRUE, myPositions->minus(other->positions()));
				return returnValue;
			}
		} else {
			if (other->isComplement()) {
				WPTR(XnRegion) 	returnValue;
				returnValue = this->makeNew(TRUE, other->positions()->minus(myPositions));
				return returnValue;
			} else {
				WPTR(XnRegion) 	returnValue;
				returnValue = this->makeNew(FALSE, myPositions->unionWith(other->positions()));
				return returnValue;
			}
		}
	}
}


RPTR(XnRegion) SetRegion::with (APTR(Position) pos){
	if (myIsComplement) {
		WPTR(XnRegion) 	returnValue;
		returnValue = this->makeNew(myIsComplement, myPositions->without(pos));
		return returnValue;
	} else {
		WPTR(XnRegion) 	returnValue;
		returnValue = this->makeNew(myIsComplement, myPositions->with(pos));
		return returnValue;
	}
}


RPTR(XnRegion) SetRegion::without (APTR(Position) pos){
	if (myIsComplement) {
		WPTR(XnRegion) 	returnValue;
		returnValue = this->makeNew(myIsComplement, myPositions->with(pos));
		return returnValue;
	} else {
		WPTR(XnRegion) 	returnValue;
		returnValue = this->makeNew(myIsComplement, myPositions->without(pos));
		return returnValue;
	}
}
/* testing */


UInt32 SetRegion::actualHashForEqual (){
	return this->getCategory()->hashForEqual() ^ myPositions->hashForEqual() ^ (myIsComplement ? 15732 : Int32Zero);
}


BooleanVar SetRegion::hasMember (APTR(Position) atPos){
	return myPositions->hasMember(atPos) != myIsComplement;
}


BooleanVar SetRegion::intersects (APTR(XnRegion) region){
	if (region->isEmpty()) {
		return FALSE;
	} else {
		WPTR(SetRegion) other;
		
		other = CAST(SetRegion,region);
		if (myIsComplement) {
			if (other->isComplement()) {
				return TRUE;
			} else {
				return !other->positions()->isSubsetOf(myPositions);
			}
		} else {
			if (other->isComplement()) {
				return !myPositions->isSubsetOf(other->positions());
			} else {
				return other->positions()->intersects(myPositions);
			}
		}
	}
}


BooleanVar SetRegion::isEmpty (){
	{	BooleanVar crutch_Flag;
		/* !myIsComplement && myPositions->isEmpty() */
		
		crutch_Flag = !myIsComplement;
		if(crutch_Flag) {
			crutch_Flag = myPositions->isEmpty();
		}
		return crutch_Flag;
	}
}


BooleanVar SetRegion::isEqual (APTR(Heaper) other){
	BEGIN_CHOOSE(other) {
		BEGIN_KIND(SetRegion,sr) {
			/* Hack !!!! */
			
			{	BooleanVar crutch_Flag;
				/* other->isKindOf(this->getCategory()) && sr->isComplement() == myIsComplement && sr->positions()->isEqual(myPositions) */
				
				crutch_Flag = other->isKindOf(this->getCategory());
				if(crutch_Flag) {
					crutch_Flag = sr->isComplement() == myIsComplement;
					if(crutch_Flag) {
						crutch_Flag = sr->positions()->isEqual(myPositions);
					}
				}
				return crutch_Flag;
			}
		} END_KIND;
		BEGIN_OTHERS {
			return FALSE;
		} END_OTHERS;
	} END_CHOOSE;
	/* fodder */
	return FALSE;
}


BooleanVar SetRegion::isFinite (){
	return !myIsComplement;
}


BooleanVar SetRegion::isFull (){
	{	BooleanVar crutch_Flag;
		/* myIsComplement && myPositions->isEmpty() */
		
		crutch_Flag = myIsComplement;
		if(crutch_Flag) {
			crutch_Flag = myPositions->isEmpty();
		}
		return crutch_Flag;
	}
}


BooleanVar SetRegion::isSimple (){
	return TRUE;
}


BooleanVar SetRegion::isSubsetOf (APTR(XnRegion) other){
	if (other->isEmpty()) {
		return this->isEmpty();
	} else {
		WPTR(SetRegion) set;
		
		set = CAST(SetRegion,other);
		if (myIsComplement) {
			{	BooleanVar crutch_Flag;
				/* set->isComplement() && set->positions()->isSubsetOf(myPositions) */
				
				crutch_Flag = set->isComplement();
				if(crutch_Flag) {
					crutch_Flag = set->positions()->isSubsetOf(myPositions);
				}
				return crutch_Flag;
			}
		} else {
			if (set->isComplement()) {
				return !set->positions()->intersects(myPositions);
			} else {
				return myPositions->isSubsetOf(set->positions());
			}
		}
	}
}
/* protected: creation */


SetRegion::SetRegion (BooleanVar cmp, APTR(ImmuSet) OF1(Position) set) {
	/* the set should be for my use alone */
	
	myIsComplement = cmp;
	myPositions = set;
}
/* printing */


void SetRegion::printOn (ostream& oo){
	oo << this->getCategory()->name();
	if (myIsComplement) {
		oo << "~";
	}
	myPositions->printOnWithSimpleSyntax(oo, "{", ", ", "}");
}
/* protected: protected deferred */
/* deferred accessing */
/* protected: enumerating */


RPTR(Stepper) SetRegion::actualStepper (APTR(OrderSpec) /* order */){
	WPTR(Stepper) 	returnValue;
	returnValue = myPositions->stepper();
	return returnValue;
}



/* ************************************************************************ *
 * 
 *                    Class   HeaperRegion 
 *
 * ************************************************************************ */


/* pseudo constructors */


RPTR(SetRegion) HeaperRegion::allHeaperAsPositions (){
	RETURN_CONSTRUCT(HeaperRegion,(TRUE, ImmuSet::make ()));
}


RPTR(SetRegion) HeaperRegion::make (){
	RETURN_CONSTRUCT(HeaperRegion,(FALSE, ImmuSet::make ()));
}


RPTR(SetRegion) HeaperRegion::make (APTR(HeaperAsPosition) heaper){
	RETURN_CONSTRUCT(HeaperRegion,(FALSE, ImmuSet::make ()->with(heaper)));
}


RPTR(SetRegion) HeaperRegion::make (APTR(ScruSet) OF1(HeaperAsPosition) heapers){
	RETURN_CONSTRUCT(HeaperRegion,(FALSE, heapers->asImmuSet()));
}
/* accessing */


RPTR(CoordinateSpace) HeaperRegion::coordinateSpace (){
	WPTR(CoordinateSpace) 	returnValue;
	returnValue = HeaperSpace::make ();
	return returnValue;
}
/* protected: protected */


RPTR(XnRegion) HeaperRegion::makeNew (BooleanVar isComplement, APTR(ImmuSet) OF1(Position) positions){
	RETURN_CONSTRUCT(HeaperRegion,(isComplement, positions));
}
/* testing */


BooleanVar HeaperRegion::isEnumerable (APTR(OrderSpec) order/* = NULL*/){
	return FALSE;
}
/* creation */


HeaperRegion::HeaperRegion (BooleanVar isComplement, APTR(ImmuSet) OF1(HeaperAsPosition) positions) 
	: SetRegion(isComplement, positions) {
	
}



/* ************************************************************************ *
 * 
 *                    Class StrongAsPosition 
 *
 * ************************************************************************ */


/* testing */


UInt32 StrongAsPosition::actualHashForEqual (){
	return itsHeaper->hashForEqual();
}


BooleanVar StrongAsPosition::isEqual (APTR(Heaper) other){
	BEGIN_CHOOSE(other) {
		BEGIN_KIND(HeaperAsPosition,hap) {
			{	BooleanVar crutch_Flag;
				/* itsHeaper == hap->heaper() || itsHeaper->isEqual(hap->heaper()) */
				
				crutch_Flag = itsHeaper == hap->heaper();
				if(!crutch_Flag) {
					crutch_Flag = itsHeaper->isEqual(hap->heaper());
				}
				return crutch_Flag;
			}
		} END_KIND;
		BEGIN_OTHERS {
			return FALSE;
		} END_OTHERS;
	} END_CHOOSE;
	/* fodder */
	return FALSE;
}
/* accessing */


RPTR(CoordinateSpace) StrongAsPosition::coordinateSpace (){
	WPTR(CoordinateSpace) 	returnValue;
	returnValue = HeaperSpace::make ();
	return returnValue;
}


RPTR(Heaper) StrongAsPosition::heaper (){
	return (Heaper*) itsHeaper;
}
/* printing */


void StrongAsPosition::printOn (ostream& oo){
	oo << "position of (" << itsHeaper << ")";
}
/* instance creation */


StrongAsPosition::StrongAsPosition (APTR(Heaper) aHeaper, TCSJ) {
	if ( ! (aHeaper != NULL) ) {
		BLAST(Heapers_in_StrongAsPosition_must_be_real);
	}
	itsHeaper = aHeaper;
}

#ifndef HSPACEX_SXX
#include "hspacex.sxx"
#endif /* HSPACEX_SXX */


#ifndef HSPACEP_SXX
#include "hspacep.sxx"
#endif /* HSPACEP_SXX */



#endif /* HSPACEX_CXX */

