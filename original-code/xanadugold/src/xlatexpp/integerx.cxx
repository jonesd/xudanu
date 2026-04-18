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

#ifndef INTEGERX_CXX
#define INTEGERX_CXX


#ifndef CHOOSEX_HXX
#include "choosex.hxx"
#endif /* CHOOSEX_HXX */

#ifndef INTEGERX_HXX
#include "integerx.hxx"
#endif /* INTEGERX_HXX */

#ifndef INTEGERX_IXX
#include "integerx.ixx"
#endif /* INTEGERX_IXX */

#ifndef INTEGERP_HXX
#include "integerp.hxx"
#endif /* INTEGERP_HXX */

#ifndef INTEGERP_IXX
#include "integerp.ixx"
#endif /* INTEGERP_IXX */


#ifndef NXCVRX_HXX
#include "nxcvrx.hxx"
#endif /* NXCVRX_HXX */

#ifndef SETX_HXX
#include "setx.hxx"
#endif /* SETX_HXX */

#ifndef XFRSPECX_HXX
#include "xfrspecx.hxx"
#endif /* XFRSPECX_HXX */




/* ************************************************************************ *
 * 
 *                    Class IntegerMapping 
 *
 * ************************************************************************ */



/* Initializers for IntegerMapping */

IntegerMapping * IntegerMapping::TheIdentityIntegerMapping = NULL;



BEGIN_INIT_TIME(IntegerMapping,initTimeNonInherited) {
	CONSTRUCT_ON(PERSISTENT,IntegerMapping::TheIdentityIntegerMapping,IntegerMapping,(IntegerVar0, tcsj));
} END_INIT_TIME(IntegerMapping,initTimeNonInherited);



/* Initializers for IntegerMapping */






/* pseudo constructors */


RPTR(IntegerMapping) IntegerMapping::make (){
	return CAST(IntegerMapping,IntegerSpace::make ()->identityDsp());
}


RPTR(Heaper) IntegerMapping::make (APTR(Rcvr) rcvr){
	IntegerVar translate;
	SPTR(Heaper) result;
	
	translate = rcvr->receiveIntegerVar();
	if (translate == IntegerVarZero) {
		result = IntegerMapping::TheIdentityIntegerMapping;
	} else {
		CONSTRUCT(result,IntegerMapping,(translate, tcsj));
	}
	CAST(SpecialistRcvr,rcvr)->registerIbid(result);
	WPTR(Heaper) 	returnValue;
	returnValue = result;
	return returnValue;
}


RPTR(IntegerMapping) IntegerMapping::make (IntegerVar translate){
	if (translate == IntegerVar0) {
		WPTR(IntegerMapping) 	returnValue;
		returnValue = IntegerMapping::make ();
		return returnValue;
	} else {
		RETURN_CONSTRUCT(IntegerMapping,(translate, tcsj));
	}
}
/* private: for create */


RPTR(Dsp) IntegerMapping::identity (){
	RETURN_CONSTRUCT(IntegerMapping,(IntegerVarZero, tcsj));
}
/* Transforms integers by adding a (possibly negative) offset.  In 
addition to the Dsp protocol, an IntegerDsp will respond to 
"translation" with the offset that it is adding.  
	
	Old documentation indicated a possibility of a future upgrade of 
IntegerDsp which would also optionally reflect (or negate) its input 
in addition to offsetting.  This would however be a non-upwards 
compatable change in that current clients already assume that the 
answer to "translation" fully describes the IntegerDsp.  If such a 
possibility is introduced, it should be as a super-type of 
IntegerDsp, since it would have a weaker contract.  Then 
compatability problems can be caught by the type checker. */


/* unprotected for init creation */


IntegerMapping::IntegerMapping (IntegerVar translation, TCSJ) {
	/* Initialize instance variables */
	
	myTranslation = translation;
}
/* printing */


void IntegerMapping::printOn (ostream& aStream){
	aStream << this->getCategory()->name() << "(" << myTranslation << ")";
}
/* transforming */


RPTR(Position) IntegerMapping::inverseOf (APTR(Position) pos){
	if ( ! (pos != NULL) ) {
		BLAST(Assertion_failed);
	}
	/* shouldn't be necessary, but the old code used to check for NULL 
			so I want to make sure I haven't broken anything */
	if (this == IntegerMapping::TheIdentityIntegerMapping) {
		WPTR(Position) 	returnValue;
		returnValue = pos;
		return returnValue;
	} else {
		WPTR(Position) 	returnValue;
		returnValue = IntegerPos::make (CAST(IntegerPos,pos)->asIntegerVar() - myTranslation);
		return returnValue;
	}
}


RPTR(XnRegion) IntegerMapping::inverseOfAll (APTR(XnRegion) reg){
	SPTR(IntegerRegion) region;
	SPTR(IntegerEdgeAccumulator) result;
	SPTR(IntegerEdgeStepper) edges;
	SPTR(XnRegion) resultReg;
	
	if (this == IntegerMapping::TheIdentityIntegerMapping) {
		WPTR(XnRegion) 	returnValue;
		returnValue = reg;
		return returnValue;
	} else {
		region = CAST(IntegerRegion,reg);
		/* Transform an interval by transforming the endpoints */
		result = IntegerEdgeAccumulator::make (!region->isBoundedBelow(), region->transitionCount());
		edges = region->edgeStepper();
		while (edges->hasValue()) {
			result->edge(this->inverseOfInt(edges->edge()));
			edges->step();
		}
		{edges->destroy();  edges = NULL /* don't want stale (S/CHK)PTRs */;}
		resultReg = result->region();
		{result->destroy();  result = NULL /* don't want stale (S/CHK)PTRs */;}
		WPTR(XnRegion) 	returnValue;
		returnValue = resultReg;
		return returnValue;
	}
}


IntegerVar IntegerMapping::inverseOfInt (IntegerVar pos){
	if (this == IntegerMapping::TheIdentityIntegerMapping) {
		return pos;
	}
	return pos - myTranslation;
}


RPTR(Position) IntegerMapping::of (APTR(Position) pos){
	if ( ! (pos != NULL) ) {
		BLAST(Assertion_failed);
	}
	/* shouldn't be necessary, but the old code used to check for NULL 
			so I want to make sure I haven't broken anything */
	if (this == IntegerMapping::TheIdentityIntegerMapping) {
		WPTR(Position) 	returnValue;
		returnValue = pos;
		return returnValue;
	} else {
		WPTR(Position) 	returnValue;
		returnValue = IntegerPos::make (myTranslation + CAST(IntegerPos,pos)->asIntegerVar());
		return returnValue;
	}
}


RPTR(XnRegion) IntegerMapping::ofAll (APTR(XnRegion) reg){
	SPTR(IntegerRegion) region;
	SPTR(IntegerEdgeAccumulator) result;
	SPTR(IntegerEdgeStepper) edges;
	SPTR(XnRegion) resultReg;
	
	if (this == IntegerMapping::TheIdentityIntegerMapping) {
		WPTR(XnRegion) 	returnValue;
		returnValue = reg;
		return returnValue;
	} else {
		region = CAST(IntegerRegion,reg);
		/* Transform an interval by transforming the endpoints */
		result = IntegerEdgeAccumulator::make (!region->isBoundedBelow(), region->transitionCount());
		edges = region->edgeStepper();
		while (edges->hasValue()) {
			result->edge(this->ofInt(edges->edge()));
			edges->step();
		}
		{edges->destroy();  edges = NULL /* don't want stale (S/CHK)PTRs */;}
		resultReg = result->region();
		{result->destroy();  result = NULL /* don't want stale (S/CHK)PTRs */;}
		WPTR(XnRegion) 	returnValue;
		returnValue = resultReg;
		return returnValue;
	}
}


IntegerVar IntegerMapping::ofInt (IntegerVar pos){
	if (this == IntegerMapping::TheIdentityIntegerMapping) {
		return pos;
	}
	return myTranslation + pos;
}
/* accessing */
/* testing */


UInt32 IntegerMapping::actualHashForEqual (){
	return myTranslation.asLong() + cat_IntegerMapping->hashForEqual();
}


BooleanVar IntegerMapping::isEqual (APTR(Heaper) other){
	/* Should have same offset and reversal */
	
	BEGIN_CHOOSE(other) {
		BEGIN_KIND(IntegerMapping,iDsp) {
			return iDsp->translation() == myTranslation;
		} END_KIND;
		BEGIN_OTHERS {
			return FALSE;
		} END_OTHERS;
	} END_CHOOSE;
	/* compiler fodder */
	return FALSE;
}
/* combining */


RPTR(Dsp) IntegerMapping::compose (APTR(Dsp) other){
	if (this == IntegerMapping::TheIdentityIntegerMapping) {
		WPTR(Dsp) 	returnValue;
		returnValue = other;
		return returnValue;
	} else {
		if (other == IntegerMapping::TheIdentityIntegerMapping) {
			return this;
		}
	}
	WPTR(Dsp) 	returnValue;
	returnValue = IntegerMapping::make (myTranslation + CAST(IntegerMapping,other)->translation());
	return returnValue;
}


RPTR(Mapping) IntegerMapping::inverse (){
	if (this == IntegerMapping::TheIdentityIntegerMapping) {
		return this;
	}
	WPTR(Mapping) 	returnValue;
	returnValue = IntegerMapping::make (-myTranslation);
	return returnValue;
}


RPTR(Dsp) IntegerMapping::inverseCompose (APTR(Dsp) other){
	if (this == IntegerMapping::TheIdentityIntegerMapping) {
		WPTR(Dsp) 	returnValue;
		returnValue = other;
		return returnValue;
	} else {
		WPTR(Dsp) 	returnValue;
		returnValue = other->minus(this);
		return returnValue;
	}
}


RPTR(Dsp) IntegerMapping::minus (APTR(Dsp) other){
	if (other == IntegerMapping::TheIdentityIntegerMapping) {
		return this;
	} else {
		WPTR(Dsp) 	returnValue;
		returnValue = IntegerMapping::make (myTranslation - CAST(IntegerMapping,other)->translation());
		return returnValue;
	}
}
/* sender */


void IntegerMapping::sendIntegerMapping (APTR(Xmtr) xmtr){
	xmtr->sendIntegerVar(myTranslation);
}



/* ************************************************************************ *
 * 
 *                    Class IntegerPos 
 *
 * ************************************************************************ */


/* pseudo constructors */
/* hash computing */
/* Because of the constraints of C++, we have two very different 
types representing integers in our system.  
	
	XuInteger is the boxed representation which must be used in any 
context which only knows that it is dealing with a Position.  
XuInteger is a Heaper with all that implies.  Specifically, one can 
take advantage of all the advantages of polymorphism (leading to uses 
by code that only knows it is dealing with a Position), but at the 
cost of representing each value by a heap allocated object to which 
pointers are passed.  Such a representation is referred to as "boxed" 
because the pointer combined with the storage structure overhead of 
maintaining a heap allocated object constitutes a "box" between the 
user of the data (the guy holding onto the pointer), and the actual 
data (which is inside the Heaper).
	
	In contrast, IntegerVar is the efficient, unboxed representation of 
an integer.  (actually, it is only unboxed so long as it fits within 
some size limit such as 32 bits.  Those IntegerVars that exceed this 
limit pay their own boxing cost to store their representation on the 
heap.  This need not concern us here.)  See "The Var vs Heaper 
distinction" and IntegerVar.  When we know that we are dealing 
specifically with an integer, we`d like to be able to stick with 
IntegerVars without having to convert them to XuIntegers.  However, 
we`d like to be able to do everything that we could normally do if we 
had an XuInteger.
	
	For this purpose, many messages (such as Position * 
Dsp::of(Position*)) have an additional overloading (IntegerVar 
Dsp::of(IntegerVar)) whose semantics is defined in terms of 
converting the argument to an XuInteger, applying the original 
operation, and converting the result (which is asserted to be an 
XuInteger) back to an IntegerVar.  Dsp even provides a default 
implementation to do exactly that.  However, if we actually rely on 
this default implementation then we are defeating the whole purpose 
of avoiding boxing overhead.  Instead, IntegerDsp overrides this to 
provide an efficient implementation.  
	
	Any particular case may at the moment simply be relying on the 
default.  The point is to get interfaces defined early which allow 
efficiency tuning to proceed in a modular fashion later.  Should any 
particular reliance on the default actually prove to be an efficiency 
issue, we will deal with it then. */


/* testing */


UInt32 IntegerPos::actualHashForEqual (){
	/* This must use an external function so other parts of the system can
		 compute the hash from an integerVar without boxing. */
	/* Open-code in smalltalk because we don't have inlines. */
	/* NOTE:  Do NOT change this without also changing the 
	implementation of integerHash!!!. */
	
	
	return IntegerPos::integerHash(myValue);
	
}


BooleanVar IntegerPos::isEqual (APTR(Heaper) other){
	BEGIN_CHOOSE(other) {
		BEGIN_KIND(IntegerPos,xui) {
			return xui->asIntegerVar() == myValue;
		} END_KIND;
		BEGIN_OTHERS {
			return FALSE;
		} END_OTHERS;
	} END_CHOOSE;
	/* compiler fodder */
	return FALSE;
}


BooleanVar IntegerPos::isGE (APTR(Position) other){
	/* Just the full ordering you'd expect on integers */
	
	BEGIN_CHOOSE(other) {
		BEGIN_KIND(IntegerPos,xui) {
			return myValue >= xui->asIntegerVar();
		} END_KIND;
		BEGIN_OTHERS {
			BLAST(CantMixCoordinateSpaces);
		} END_OTHERS;
	} END_CHOOSE;
	/* compiler fodder */
	return FALSE;
}
/* accessing */


RPTR(XnRegion) IntegerPos::asRegion (){
	WPTR(XnRegion) 	returnValue;
	returnValue = IntegerRegion::make (this->asIntegerVar());
	return returnValue;
}
/* printing */


void IntegerPos::printOn (ostream& oo){
	oo << "I(" << myValue << ")";
}
/* protected: creation */


IntegerPos::IntegerPos (IntegerVar newValue, TCSJ) {
	myValue = newValue;
}



/* ************************************************************************ *
 * 
 *                    Class IntegerRegion 
 *
 * ************************************************************************ */



/* Initializers for IntegerRegion */

GPTR(IntegerRegion) IntegerRegion::AllIntegers = NULL;
GPTR(IntegerRegion) IntegerRegion::EmptyIntegerRegion = NULL;
GPTR(IntegerRegion) IntegerRegion::LastAfterRegion = NULL;
IntegerVar IntegerRegion::LastAfterStart = 13;
IntegerVar IntegerRegion::LastBeforeEnd = 13;
GPTR(IntegerRegion) IntegerRegion::LastBeforeRegion = NULL;
GPTR(IntegerRegion) IntegerRegion::LastInterval = NULL;
IntegerVar IntegerRegion::LastLeft = 13;
IntegerVar IntegerRegion::LastRight = 13;
IntegerVar IntegerRegion::LastSingleton = 13;
GPTR(IntegerRegion) IntegerRegion::LastSingletonRegion = NULL;



BEGIN_INIT_TIME(IntegerRegion,initTimeNonInherited) {
	SPTR(IntegerVarArray) empty;
	SPTR(IntegerRegion) tir;
	
	REQUIRES (IntegerVarArray);
	empty = IntegerVarArray::zeros(1);
	/* temp used to get around problem with static members and 
		INIT macro - heh 10 January 1992 */
	CONSTRUCT(tir,IntegerRegion,(TRUE, Int32Zero, empty));
	IntegerRegion::AllIntegers = tir;
	CONSTRUCT(tir,IntegerRegion,(FALSE, Int32Zero, empty));
	IntegerRegion::EmptyIntegerRegion = tir;
	/* call the pseudo constructors with arguments that are known 
		to flush the caches */
	IntegerRegion::after(IntegerVar0);
	IntegerRegion::before(IntegerVar0);
	IntegerRegion::make (IntegerVar0);
	IntegerRegion::make (IntegerVar0, 2);
} END_INIT_TIME(IntegerRegion,initTimeNonInherited);



/* Initializers for IntegerRegion */






/* pseudo constructors */


RPTR(IntegerRegion) IntegerRegion::above (IntegerVar start, BooleanVar inclusive){
	/* Essential. Make a region that contains all integers 
	greater than (or equal if inclusive is true) to start. */
	
	IntegerVar after;
	
	after = start;
	if (!inclusive) {
		after += 1;
	}
	WPTR(IntegerRegion) 	returnValue;
	returnValue = IntegerRegion::after(after);
	return returnValue;
}


RPTR(IntegerRegion) IntegerRegion::after (IntegerVar start){
	/* The region containing all position greater than or equal to start */
	
	SPTR(IntegerVarArray) table;
	SPTR(IntegerRegion) tir;
	
	if (IntegerRegion::LastAfterStart == start) {
		WPTR(IntegerRegion) 	returnValue;
		returnValue = IntegerRegion::LastAfterRegion;
		return returnValue;
	}
	IntegerRegion::LastAfterStart = start;
	table = IntegerVarArray::zeros(1);
	table->storeIntegerVar(Int32Zero, start);
	/* temp used to get around static member problem in INIT 
		macro - heh 10 January 1992 */
	CONSTRUCT(tir,IntegerRegion,(FALSE, 1, table));
	IntegerRegion::LastAfterRegion = tir;
	WPTR(IntegerRegion) 	returnValue;
	returnValue = IntegerRegion::LastAfterRegion;
	return returnValue;
}


RPTR(IntegerRegion) IntegerRegion::before (IntegerVar end){
	/* The region of all integers less than end.  Does not include end. */
	
	SPTR(IntegerVarArray) table;
	SPTR(IntegerRegion) tir;
	
	if (IntegerRegion::LastBeforeEnd == end) {
		WPTR(IntegerRegion) 	returnValue;
		returnValue = IntegerRegion::LastBeforeRegion;
		return returnValue;
	}
	IntegerRegion::LastBeforeEnd = end;
	table = IntegerVarArray::zeros(1);
	table->storeIntegerVar(Int32Zero, end);
	/* temp used to get around problem with static members & INIT 
		macro - heh 10 January 1992 */
	CONSTRUCT(tir,IntegerRegion,(TRUE, 1, table));
	IntegerRegion::LastBeforeRegion = tir;
	WPTR(IntegerRegion) 	returnValue;
	returnValue = IntegerRegion::LastBeforeRegion;
	return returnValue;
}


RPTR(IntegerRegion) IntegerRegion::below (IntegerVar stop, BooleanVar inclusive){
	/* Make a region that contains all integers less than (or 
	equal if inclusive is true) to stop. */
	
	IntegerVar after;
	
	after = stop;
	if (inclusive) {
		after += 1;
	}
	WPTR(IntegerRegion) 	returnValue;
	returnValue = IntegerRegion::after(after);
	return returnValue;
}


RPTR(IntegerRegion) IntegerRegion::integerExtent (IntegerVar start, IntegerVar n){
	/* The region of all integers which are >= start and < start + n */
	
	WPTR(IntegerRegion) 	returnValue;
	returnValue = IntegerRegion::make (start, start + n);
	return returnValue;
}


RPTR(IntegerRegion) IntegerRegion::interval (IntegerVar left, IntegerVar right){
	/* The region of all integers which are >= left and < right */
	
	SPTR(IntegerVarArray) ivArray;
	
	if (left >= right) {
		WPTR(IntegerRegion) 	returnValue;
		returnValue = IntegerRegion::EmptyIntegerRegion;
		return returnValue;
	}
	ivArray = IntegerVarArray::zeros(2);
	ivArray->storeIntegerVar(Int32Zero, left);
	ivArray->storeIntegerVar(1, right);
	RETURN_CONSTRUCT(IntegerRegion,(FALSE, 2, ivArray));
}


RPTR(IntegerRegion) IntegerRegion::make (IntegerVar singleton){
	/* The region with just this one position.  Equivalent to 
	using a converter 
		to convert this position to a region. */
	
	SPTR(IntegerVarArray) table;
	SPTR(IntegerRegion) tir;
	
	if (singleton == IntegerRegion::LastSingleton) {
		WPTR(IntegerRegion) 	returnValue;
		returnValue = IntegerRegion::LastSingletonRegion;
		return returnValue;
	}
	IntegerRegion::LastSingleton = singleton;
	table = IntegerVarArray::zeros(2);
	table->storeIntegerVar(Int32Zero, singleton);
	table->storeIntegerVar(1, singleton + 1);
	/* temp used to get around problem with static members and 
		INIT macro - heh 10 January 1992 */
	CONSTRUCT(tir,IntegerRegion,(FALSE, 2, table));
	IntegerRegion::LastSingletonRegion = tir;
	WPTR(IntegerRegion) 	returnValue;
	returnValue = IntegerRegion::LastSingletonRegion;
	return returnValue;
}


RPTR(IntegerRegion) IntegerRegion::make (IntegerVar left, IntegerVar right){
	/* The region of all integers which are >= left and < right */
	
	SPTR(IntegerVarArray) ivArray;
	
	if (left >= right) {
		WPTR(IntegerRegion) 	returnValue;
		returnValue = IntegerRegion::EmptyIntegerRegion;
		return returnValue;
	}
	ivArray = IntegerVarArray::zeros(2);
	ivArray->storeIntegerVar(Int32Zero, left);
	ivArray->storeIntegerVar(1, right);
	RETURN_CONSTRUCT(IntegerRegion,(FALSE, 2, ivArray));
}
/* privacy violator */
/* private: pseudo constructors */


RPTR(IntegerRegion) IntegerRegion::usingx (
		BooleanVar startsInside, 
		Int32 transitionCount, 
		APTR(IntegerVarArray) transitions)
{
	RETURN_CONSTRUCT(IntegerRegion,(startsInside, transitionCount, transitions));
}
/* An IntegerRegion can be thought of as the disjoint union of 
intervals and inequalities.  The interesting cases to look at are:
	
	The distinctions:
		1) The empty region
		2) The full region
		3) A "left" inequality -- e.g., everything less that 3.
		4) A "right" inequality -- e.g., everything greater than or equal to 7
		
	The non-distinction simple regions:
		5) An interval -- e.g., from 3 inclusive to 7 exclusive
		
	The non-simple regions:
		6) A disjoint union of (in order) an optional left inequality, a set of 
			intervals, and an optional right inequality.  
		
	If a non-empty region has a least element, then it "isBoundedLeft".  
Otherwise it extends leftwards indefinitely.  Similarly, if a 
non-empty region has a greatest element, then it "isBoundedRight".  
Otherwise it extends rightwards indefinitely.  (We may figuratively 
speak of the region extending towards + or - infinity, but we have 
purposely avoided introducing any value which represents an infinity.)
	
	Looking at cases again:
		1) "isBoundedLeft" and "isBoundedRight" since it doesn't extent 
			indenfinitely in either direction.  (A danger to watch out for is that 
			this still has niether a greatest nor a least element).
		2) niether.
		3) "isBoundedRight"
		4) "isBoundedLeft"
		5) "isBoundedLeft" and "isBoundedRight"
		6) "isBoundedLeft" iff doesn't include a left inequality,
			"isBoundedRight" iff doesn't include a right inequality.
			
	An efficiency note:  Currently many of the method which could be 
doing an O(log) binary search (such as hasMember) are instead doing a 
linear search.  This will be fixed if it turns out to be a problem in practice.
	
	See OrderedRegion. */


/* accessing */


RPTR(XnRegion) IntegerRegion::asSimpleRegion (){
	/* Will always return the smallest simple region which 
	contains all my positions */
	
	if (this->isSimple()) {
		return this;
	}
	if (this->isBoundedBelow()) {
		if (this->isBoundedAbove()) {
			WPTR(XnRegion) 	returnValue;
			returnValue = IntegerRegion::make (this->start(), this->stop());
			return returnValue;
		} else {
			WPTR(XnRegion) 	returnValue;
			returnValue = IntegerRegion::after(this->start());
			return returnValue;
		}
	} else {
		if (this->isBoundedAbove()) {
			WPTR(XnRegion) 	returnValue;
			returnValue = IntegerRegion::before(this->stop());
			return returnValue;
		} else {
			WPTR(XnRegion) 	returnValue;
			returnValue = IntegerRegion::allIntegers();
			return returnValue;
		}
	}
}


RPTR(XnRegion) IntegerRegion::beforeLast (){
	/* the region before the last element of the set.  
		What on earth is this for? (Yes, I've looked at senders) */
	
	if (myTransitionCount == Int32Zero) {
		return this;
	}
	if (this->isBoundedAbove()) {
		WPTR(XnRegion) 	returnValue;
		returnValue = IntegerRegion::before(this->stop());
		return returnValue;
	} else {
		WPTR(XnRegion) 	returnValue;
		returnValue = IntegerRegion::allIntegers();
		return returnValue;
	}
}


RPTR(XnRegion) IntegerRegion::compacted (){
	/* transform the region into a simple region with left bound 0 
		(or -inf if unbounded).
		What on earth is this for? (Yes, I've looked at senders) */
	/* ((IntegerRegion make: 3 with: 7) unionWith: (IntegerRegion 
	before: -10)) compacted */
	
	if (this->isBoundedBelow()) {
		if (this->isBoundedAbove()) {
			WPTR(XnRegion) 	returnValue;
			returnValue = IntegerRegion::make (IntegerVar0, this->count());
			return returnValue;
		} else {
			WPTR(XnRegion) 	returnValue;
			returnValue = IntegerRegion::after(IntegerVar0);
			return returnValue;
		}
	} else {
		if (this->isBoundedAbove()) {
			WPTR(XnRegion) 	returnValue;
			returnValue = IntegerRegion::before(myTransitions->integerVarAt(Int32Zero) + this->intersect(IntegerRegion::after(myTransitions->integerVarAt(Int32Zero)))->count());
			return returnValue;
		} else {
			WPTR(XnRegion) 	returnValue;
			returnValue = IntegerRegion::allIntegers();
			return returnValue;
		}
	}
}


RPTR(Mapping) IntegerRegion::compactor (){
	/* A mapping to transform the region into a simple region 
	with left bound 0 (or -inf if unbounded). The domain of the 
	mapping is precisely this region.
		This is primarily used in XuText Waldos, which only deal 
	with contiguous zero-based regions of data. */
	/* ((IntegerRegion make: 3 with: 7) unionWith: (IntegerRegion 
	after: 10)) compactor */
	
	SPTR(Mapping) result;
	IntegerVar end;
	UInt32 index;
	SPTR(IntegerRegion) simple;
	SPTR(Mapping) sub;
	
	if (myTransitionCount == Int32Zero) {
		WPTR(Mapping) 	returnValue;
		returnValue = IntegerMapping::make ()->restrict(this);
		return returnValue;
	}
	result = NULL;
	if (myStartsInside) {
		end = myTransitions->integerVarAt(Int32Zero);
		index = 1;
	} else {
		end = IntegerVar0;
		index = Int32Zero;
	}
	while (index < myTransitionCount) {
		simple = this->simpleRegionAtIndex(index);
		sub = IntegerMapping::make (end - simple->start())->restrict(simple);
		if (result == NULL) {
			result = sub;
		} else {
			result = result->combine(sub);
		}
		if (simple->isBoundedAbove()) {
			end += simple->count();
		}
		index += 2;
	}
	if (result != NULL) {
		WPTR(Mapping) 	returnValue;
		returnValue = result->restrict(this);
		return returnValue;
	} else {
		WPTR(Mapping) 	returnValue;
		returnValue = IntegerMapping::make ()->restrict(this);
		return returnValue;
	}
}


BooleanVar IntegerRegion::isCompacted (){
	/* True if this is either empty or a simple region with lower 
	bound of either 0 or -infinity. Equivalent to
			this->compacted()->isEqual (this) */
	
	if (myStartsInside) {
		return myTransitionCount == 1;
	} else {
		{	BooleanVar crutch_Flag;
			/* myTransitionCount == Int32Zero || myTransitionCount == 2 && myTransitions->integerVarAt(Int32Zero) == IntegerVar0 */
			
			crutch_Flag = myTransitionCount == Int32Zero;
			if(!crutch_Flag) {
				crutch_Flag = myTransitionCount == 2;
				if(crutch_Flag) {
					crutch_Flag = myTransitions->integerVarAt(Int32Zero) == IntegerVar0;
				}
			}
			return crutch_Flag;
		}
	}
}


IntegerVar IntegerRegion::nearestIntHole (IntegerVar index){
	/* This is a hack for finding the smallest available index to 
	allocate that is not in a particular region (a table domain, 
	for example). */
	
	SPTR(IntegerEdgeStepper) edges;
	BooleanVar test;
	
	edges = this->edgeStepper();
	while (edges->hasValue()) {
		if (index < edges->edge()) {
			if (edges->isEntering()) {
				{edges->destroy();  edges = NULL /* don't want stale (S/CHK)PTRs */;}
				return index;
			} else {
				IntegerVar result;
				
				result = edges->edge();
				{edges->destroy();  edges = NULL /* don't want stale (S/CHK)PTRs */;}
				return result;
			}
		}
		edges->step();
	}
	test = edges->isEntering();
	{edges->destroy();  edges = NULL /* don't want stale (S/CHK)PTRs */;}
	if (test) {
		return index;
	} else {
		BLAST(NoHole);
	}
	/* fodder */
	return IntegerVarZero;
}


RPTR(IntegerRegion) IntegerRegion::runAt (IntegerVar pos){
	/* The region starting from pos (inclusive) and going until 
	the next transition. If I contain pos, then I return the 
	longest contiguous region starting at pos of positions I 
	contain. If I don't contain pos, then I return the longest 
	contiguous region starting at pos of positions I do not contain. */
	
	{
		UInt32 LoopFinal = myTransitionCount;
		UInt32 i = Int32Zero;
		for (;;) {
			if (i >= LoopFinal){
				break;
			}
			{
				if (myTransitions->integerVarAt(i) > pos) {
					WPTR(IntegerRegion) 	returnValue;
					returnValue = IntegerRegion::make (pos, myTransitions->integerVarAt(i));
					return returnValue;
				}
			}
			i += 1;
		}
	}
	WPTR(IntegerRegion) 	returnValue;
	returnValue = IntegerRegion::after(pos);
	return returnValue;
}


IntegerVar IntegerRegion::start (){
	/* I have a start only if I'm not empty and I am 
	isBoundedBelow. I report as my start the smallest position I 
	*do* contain, which is one greater than the largest position 
	I do not contain. The lower bound of the interval from 3 
	inclusive to 7 exclusive is 3. 
		See 'stop', you may be surprised. */
	
	{	BooleanVar crutch_Flag;
		/* myStartsInside || myTransitionCount == Int32Zero */
		
		crutch_Flag = myStartsInside;
		if(!crutch_Flag) {
			crutch_Flag = myTransitionCount == Int32Zero;
		}
		if (crutch_Flag) {
			BLAST(InvalidRequest);
		}
	}
	return myTransitions->integerVarAt(Int32Zero);
}


IntegerVar IntegerRegion::stop (){
	/* I have a stop only if I'm not empty and I am 
	isBoundedAbove. I report as my stop the smallest position I 
	*do not* contain, which is one greater than the largest 
	position I do contain.  The ustop of the interval from 3 
	inclusive to 7 exclusive is 7.
		See 'start', you may be surprised. */
	
	{	BooleanVar crutch_Flag;
		/* !this->isBoundedAbove() || myTransitionCount == Int32Zero */
		
		crutch_Flag = !this->isBoundedAbove();
		if(!crutch_Flag) {
			crutch_Flag = myTransitionCount == Int32Zero;
		}
		if (crutch_Flag) {
			BLAST(InvalidRequest);
		}
	}
	return myTransitions->integerVarAt(myTransitionCount - 1);
}
/* unprotected creation */


IntegerRegion::IntegerRegion (
		BooleanVar startsInside, 
		UInt32 count, 
		APTR(IntegerVarArray) transitions) 
{
	myStartsInside = startsInside;
	myTransitionCount = count;
	myTransitions = transitions;
}
/* destroy */


void IntegerRegion::destroy (){
	
}
/* printing */


void IntegerRegion::printOn (ostream& oo){
	if (this->isEmpty()) {
		oo << "{}";
	} else {
		SPTR(IntegerEdgeStepper) edges;
		char * between;
		
		edges = this->edgeStepper();
		if (!this->isSimple()) {
			oo << "{";
		}
		if (!edges->isEntering()) {
			oo << "(-inf";
		}
		between = "[";
		while (edges->hasValue()) {
			if (edges->isEntering()) {
				oo << between;
			} else {
				oo << ", ";
			}
			oo << edges->edge();
			between = "), [";
			edges->step();
		}
		if (edges->isEntering()) {
			oo << ")";
		} else {
			oo << ", +inf)";
		}
		if (!this->isSimple()) {
			oo << "}";
		}
		{edges->destroy();  edges = NULL /* don't want stale (S/CHK)PTRs */;}
	}
}
/* testing */


UInt32 IntegerRegion::actualHashForEqual (){
	return myTransitions->elementsHash(myTransitionCount) ^ ((myStartsInside ? 9617 : 518293) ^ myTransitionCount * 17);
}


BooleanVar IntegerRegion::hasIntMember (IntegerVar key){
	/* Unboxed version.  See class comment for XuInteger */
	
	SPTR(IntegerEdgeStepper) edges;
	BooleanVar result;
	
	edges = this->edgeStepper();
	while (edges->hasValue()) {
		if (key < edges->edge()) {
			result = !edges->isEntering();
			{edges->destroy();  edges = NULL /* don't want stale (S/CHK)PTRs */;}
			return result;
		}
		edges->step();
	}
	result = !edges->isEntering();
	{edges->destroy();  edges = NULL /* don't want stale (S/CHK)PTRs */;}
	return result;
}


BooleanVar IntegerRegion::hasMember (APTR(Position) pos){
	return this->hasIntMember(CAST(IntegerPos,pos)->asIntegerVar());
}


BooleanVar IntegerRegion::intersects (APTR(XnRegion) region){
	WPTR(IntegerRegion) other;
	
	other = CAST(IntegerRegion,region);
	if (Int32Zero == myTransitionCount) {
		if (myStartsInside) {
			return !other->isEmpty();
		} else {
			return !this->isEmpty();
		}
	} else {
		if (Int32Zero == other->transitionCount()) {
			if (other->isBoundedBelow()) {
				return !other->isEmpty();
			} else {
				return !this->isEmpty();
			}
		} else {
			SPTR(IntegerEdgeStepper) mine;
			SPTR(IntegerEdgeStepper) others;
			IntegerVar pending;
			BooleanVar havePending;
			Int32 index;
			BooleanVar startsInside;
			
			mine = this->edgeStepper();
			others = other->edgeStepper();
			havePending = FALSE;
			index = Int32Zero;
			for (;;) {	BooleanVar crutch_Flag;
				/* mine->hasValue() && others->hasValue() */
				
				crutch_Flag = mine->hasValue();
				if(crutch_Flag) {
					crutch_Flag = others->hasValue();
				}
				if (crutch_Flag) {
					IntegerVar me;
					IntegerVar it;
					
					me = mine->edge();
					it = others->edge();
					if (me < it) {
						if (!others->isEntering()) {
							if (havePending) {
								if (pending == me) {
									havePending = FALSE;
								} else {
									{mine->destroy();  mine = NULL /* don't want stale (S/CHK)PTRs */;}
									{others->destroy();  others = NULL /* don't want stale (S/CHK)PTRs */;}
									return TRUE;
								}
							} else {
								havePending = TRUE;
								pending = me;
								index = 1;
							}
						}
						mine->step();
					} else {
						if (!mine->isEntering()) {
							if (havePending) {
								if (pending == it) {
									havePending = FALSE;
								} else {
									{mine->destroy();  mine = NULL /* don't want stale (S/CHK)PTRs */;}
									{others->destroy();  others = NULL /* don't want stale (S/CHK)PTRs */;}
									return TRUE;
								}
							} else {
								havePending = TRUE;
								pending = it;
								index = 1;
							}
						}
						others->step();
					}
				} else {
					break;
				}
			}
			startsInside = myStartsInside && !other->isBoundedBelow();
			{	BooleanVar crutch_Flag;
				/* mine->hasValue() && !others->isEntering() */
				
				crutch_Flag = mine->hasValue();
				if(crutch_Flag) {
					crutch_Flag = !others->isEntering();
				}
				if (crutch_Flag) {
					if (havePending) {
						if (pending == mine->edge()) {
							havePending = FALSE;
						} else {
							{mine->destroy();  mine = NULL /* don't want stale (S/CHK)PTRs */;}
							{others->destroy();  others = NULL /* don't want stale (S/CHK)PTRs */;}
							return TRUE;
						}
					} else {
						havePending = TRUE;
						index = 1;
					}
					if (havePending) {
						{mine->destroy();  mine = NULL /* don't want stale (S/CHK)PTRs */;}
						{others->destroy();  others = NULL /* don't want stale (S/CHK)PTRs */;}
						return TRUE;
					}
					mine->step();
					if (mine->hasValue()) {
						{mine->destroy();  mine = NULL /* don't want stale (S/CHK)PTRs */;}
						{others->destroy();  others = NULL /* don't want stale (S/CHK)PTRs */;}
						{	BooleanVar crutch_Flag;
							/* index == Int32Zero && startsInside || index != Int32Zero */
							
							crutch_Flag = index == Int32Zero;
							if(crutch_Flag) {
								crutch_Flag = startsInside;
							}
							if(!crutch_Flag) {
								crutch_Flag = index != Int32Zero;
							}
							return crutch_Flag;
						}
					}
				}
			}
			{	BooleanVar crutch_Flag;
				/* others->hasValue() && !mine->isEntering() */
				
				crutch_Flag = others->hasValue();
				if(crutch_Flag) {
					crutch_Flag = !mine->isEntering();
				}
				if (crutch_Flag) {
					if (havePending) {
						if (pending == others->edge()) {
							havePending = FALSE;
						} else {
							{mine->destroy();  mine = NULL /* don't want stale (S/CHK)PTRs */;}
							{others->destroy();  others = NULL /* don't want stale (S/CHK)PTRs */;}
							return TRUE;
						}
					} else {
						havePending = TRUE;
						index = 1;
					}
					if (havePending) {
						{mine->destroy();  mine = NULL /* don't want stale (S/CHK)PTRs */;}
						{others->destroy();  others = NULL /* don't want stale (S/CHK)PTRs */;}
						return TRUE;
					}
					others->step();
					if (others->hasValue()) {
						{mine->destroy();  mine = NULL /* don't want stale (S/CHK)PTRs */;}
						{others->destroy();  others = NULL /* don't want stale (S/CHK)PTRs */;}
						{	BooleanVar crutch_Flag;
							/* index == Int32Zero && startsInside || index != Int32Zero */
							
							crutch_Flag = index == Int32Zero;
							if(crutch_Flag) {
								crutch_Flag = startsInside;
							}
							if(!crutch_Flag) {
								crutch_Flag = index != Int32Zero;
							}
							return crutch_Flag;
						}
					}
				}
			}
			{mine->destroy();  mine = NULL /* don't want stale (S/CHK)PTRs */;}
			{others->destroy();  others = NULL /* don't want stale (S/CHK)PTRs */;}
			return havePending;
		}
	}
}


BooleanVar IntegerRegion::isBoundedAbove (){
	/* Either I extend indefinitely to plus infinity, or I am 
	bounded above, not both. 
		The empty region is bounded above despite the fact that it 
	has no upper edge. */
	
	return (myTransitionCount & 1) == Int32Zero != myStartsInside;
}


BooleanVar IntegerRegion::isEmpty (){
	{	BooleanVar crutch_Flag;
		/* !myStartsInside && myTransitionCount == Int32Zero */
		
		crutch_Flag = !myStartsInside;
		if(crutch_Flag) {
			crutch_Flag = myTransitionCount == Int32Zero;
		}
		return crutch_Flag;
	}
}


BooleanVar IntegerRegion::isEqual (APTR(Heaper) other){
	BEGIN_CHOOSE(other) {
		BEGIN_KIND(IntegerRegion,ir) {
			{	BooleanVar crutch_Flag;
				/* ir->isBoundedBelow() != myStartsInside && ir->transitionCount() == myTransitionCount && 
									ir->secretTransitions()->elementsEqual(Int32Zero, myTransitions, Int32Zero, myTransitionCount) */
				
				crutch_Flag = ir->isBoundedBelow() != myStartsInside;
				if(crutch_Flag) {
					crutch_Flag = ir->transitionCount() == myTransitionCount;
					if(crutch_Flag) {
						crutch_Flag = ir->secretTransitions()->elementsEqual(Int32Zero, myTransitions, Int32Zero, myTransitionCount);
					}
				}
				return crutch_Flag;
			}
		} END_KIND;
		BEGIN_OTHERS {
			return FALSE;
		} END_OTHERS;
	} END_CHOOSE;
	/* compiler fodder */
	return FALSE;
}


BooleanVar IntegerRegion::isFinite (){
	{	BooleanVar crutch_Flag;
		/* this->isBoundedBelow() && this->isBoundedAbove() */
		
		crutch_Flag = this->isBoundedBelow();
		if(crutch_Flag) {
			crutch_Flag = this->isBoundedAbove();
		}
		return crutch_Flag;
	}
}


BooleanVar IntegerRegion::isFull (){
	{	BooleanVar crutch_Flag;
		/* myStartsInside && myTransitionCount == Int32Zero */
		
		crutch_Flag = myStartsInside;
		if(crutch_Flag) {
			crutch_Flag = myTransitionCount == Int32Zero;
		}
		return crutch_Flag;
	}
}


BooleanVar IntegerRegion::isSimple (){
	/* Inequalities and intervals are both simple.  See class comment */
	
	if (myStartsInside) {
		return myTransitionCount <= 1;
	} else {
		return myTransitionCount <= 2;
	}
}


BooleanVar IntegerRegion::isSubsetOf (APTR(XnRegion) other){
	if (other->isEmpty()) {
		return this->isEmpty();
	} else {
		SPTR(IntegerEdgeStepper) mine;
		SPTR(IntegerEdgeStepper) others;
		BooleanVar result;
		
		mine = this->edgeStepper();
		others = CAST(IntegerRegion,other)->edgeStepper();
		{	BooleanVar crutch_Flag;
			/* mine->hasValue() || others->hasValue() */
			
			crutch_Flag = mine->hasValue();
			if(!crutch_Flag) {
				crutch_Flag = others->hasValue();
			}
			if (!crutch_Flag) {
				result = mine->isEntering() || !others->isEntering();
				{mine->destroy();  mine = NULL /* don't want stale (S/CHK)PTRs */;}
				{others->destroy();  others = NULL /* don't want stale (S/CHK)PTRs */;}
				return result;
			}
		}
		{	BooleanVar crutch_Flag;
			/* !mine->isEntering() && others->isEntering() */
			
			crutch_Flag = !mine->isEntering();
			if(crutch_Flag) {
				crutch_Flag = others->isEntering();
			}
			if (crutch_Flag) {
				{mine->destroy();  mine = NULL /* don't want stale (S/CHK)PTRs */;}
				{others->destroy();  others = NULL /* don't want stale (S/CHK)PTRs */;}
				return FALSE;
			}
		}
		for (;;) {	BooleanVar crutch_Flag;
			/* mine->hasValue() && others->hasValue() */
			
			crutch_Flag = mine->hasValue();
			if(crutch_Flag) {
				crutch_Flag = others->hasValue();
			}
			if (crutch_Flag) {
				if (others->edge() < mine->edge()) {
					{	BooleanVar crutch_Flag;
						/* !others->isEntering() && !mine->isEntering() */
						
						crutch_Flag = !others->isEntering();
						if(crutch_Flag) {
							crutch_Flag = !mine->isEntering();
						}
						if (crutch_Flag) {
							{mine->destroy();  mine = NULL /* don't want stale (S/CHK)PTRs */;}
							{others->destroy();  others = NULL /* don't want stale (S/CHK)PTRs */;}
							return FALSE;
						}
					}
					others->step();
				} else {
					if (others->edge() > mine->edge()) {
						{	BooleanVar crutch_Flag;
							/* others->isEntering() && mine->isEntering() */
							
							crutch_Flag = others->isEntering();
							if(crutch_Flag) {
								crutch_Flag = mine->isEntering();
							}
							if (crutch_Flag) {
								{mine->destroy();  mine = NULL /* don't want stale (S/CHK)PTRs */;}
								{others->destroy();  others = NULL /* don't want stale (S/CHK)PTRs */;}
								return FALSE;
							}
						}
						mine->step();
					} else {
						if (others->isEntering() != mine->isEntering()) {
							{mine->destroy();  mine = NULL /* don't want stale (S/CHK)PTRs */;}
							{others->destroy();  others = NULL /* don't want stale (S/CHK)PTRs */;}
							return FALSE;
						}
						others->step();
						mine->step();
					}
				}
			} else {
				break;
			}
		}
		result = !(mine->hasValue() && others->isEntering() || others->hasValue() && !mine->isEntering());
		{mine->destroy();  mine = NULL /* don't want stale (S/CHK)PTRs */;}
		{others->destroy();  others = NULL /* don't want stale (S/CHK)PTRs */;}
		return result;
	}
}
/* operations */


RPTR(XnRegion) IntegerRegion::complement (){
	RETURN_CONSTRUCT(IntegerRegion,(!myStartsInside, myTransitionCount, myTransitions));
}


RPTR(XnRegion) IntegerRegion::intersect (APTR(XnRegion) region){
	WPTR(IntegerRegion) other;
	
	other = CAST(IntegerRegion,region);
	if (Int32Zero == myTransitionCount) {
		if (myStartsInside) {
			WPTR(XnRegion) 	returnValue;
			returnValue = other;
			return returnValue;
		} else {
			return this;
		}
	} else {
		if (Int32Zero == other->transitionCount()) {
			if (other->isBoundedBelow()) {
				WPTR(XnRegion) 	returnValue;
				returnValue = other;
				return returnValue;
			} else {
				return this;
			}
		} else {
			SPTR(IntegerEdgeStepper) mine;
			SPTR(IntegerEdgeStepper) others;
			SPTR(IntegerEdgeAccumulator) result;
			SPTR(XnRegion) resultReg;
			
			mine = this->edgeStepper();
			others = other->edgeStepper();
			result = IntegerEdgeAccumulator::make (myStartsInside && !other->isBoundedBelow(), myTransitionCount + other->transitionCount());
			for (;;) {	BooleanVar crutch_Flag;
				/* mine->hasValue() && others->hasValue() */
				
				crutch_Flag = mine->hasValue();
				if(crutch_Flag) {
					crutch_Flag = others->hasValue();
				}
				if (crutch_Flag) {
					IntegerVar me;
					IntegerVar it;
					
					me = mine->edge();
					it = others->edge();
					if (me < it) {
						if (!others->isEntering()) {
							result->edge(me);
						}
						mine->step();
					} else {
						if (!mine->isEntering()) {
							result->edge(it);
						}
						others->step();
					}
				} else {
					break;
				}
			}
			{	BooleanVar crutch_Flag;
				/* mine->hasValue() && !others->isEntering() */
				
				crutch_Flag = mine->hasValue();
				if(crutch_Flag) {
					crutch_Flag = !others->isEntering();
				}
				if (crutch_Flag) {
					result->edges(mine);
				}
			}
			{	BooleanVar crutch_Flag;
				/* others->hasValue() && !mine->isEntering() */
				
				crutch_Flag = others->hasValue();
				if(crutch_Flag) {
					crutch_Flag = !mine->isEntering();
				}
				if (crutch_Flag) {
					result->edges(others);
				}
			}
			{mine->destroy();  mine = NULL /* don't want stale (S/CHK)PTRs */;}
			{others->destroy();  others = NULL /* don't want stale (S/CHK)PTRs */;}
			resultReg = result->region();
			{result->destroy();  result = NULL /* don't want stale (S/CHK)PTRs */;}
			WPTR(XnRegion) 	returnValue;
			returnValue = resultReg;
			return returnValue;
		}
	}
}


RPTR(XnRegion) IntegerRegion::simpleUnion (APTR(XnRegion) otherRegion){
	/* The result is the smallest simple region which satisfies 
	the spec in XuRegion::simpleUnion */
	
	WPTR(IntegerRegion) other;
	
	other = CAST(IntegerRegion,otherRegion);
	if (this->isEmpty()) {
		WPTR(XnRegion) 	returnValue;
		returnValue = other->asSimpleRegion();
		return returnValue;
	}
	if (other->isEmpty()) {
		WPTR(XnRegion) 	returnValue;
		returnValue = this->asSimpleRegion();
		return returnValue;
	}
	{	BooleanVar crutch_Flag;
		/* this->isBoundedBelow() && other->isBoundedBelow() */
		
		crutch_Flag = this->isBoundedBelow();
		if(crutch_Flag) {
			crutch_Flag = other->isBoundedBelow();
		}
		if (crutch_Flag) {
			{	BooleanVar crutch_Flag;
				/* this->isBoundedAbove() && other->isBoundedAbove() */
				
				crutch_Flag = this->isBoundedAbove();
				if(crutch_Flag) {
					crutch_Flag = other->isBoundedAbove();
				}
				if (crutch_Flag) {
					WPTR(XnRegion) 	returnValue;
					returnValue = IntegerRegion::make (min(this->start(), other->start()), max(this->stop(), other->stop()));
					return returnValue;
				} else {
					WPTR(XnRegion) 	returnValue;
					returnValue = IntegerRegion::after(min(this->start(), other->start()));
					return returnValue;
				}
			}
		} else {
			{	BooleanVar crutch_Flag;
				/* this->isBoundedAbove() && other->isBoundedAbove() */
				
				crutch_Flag = this->isBoundedAbove();
				if(crutch_Flag) {
					crutch_Flag = other->isBoundedAbove();
				}
				if (crutch_Flag) {
					WPTR(XnRegion) 	returnValue;
					returnValue = IntegerRegion::before(max(this->stop(), other->stop()));
					return returnValue;
				} else {
					WPTR(XnRegion) 	returnValue;
					returnValue = IntegerRegion::make ()->complement();
					return returnValue;
				}
			}
		}
	}
}


RPTR(XnRegion) IntegerRegion::unionWith (APTR(XnRegion) region){
	if (region->isEmpty()) {
		return this;
	} else {
		SPTR(IntegerRegion) other;
		SPTR(IntegerEdgeStepper) mine;
		SPTR(IntegerEdgeStepper) others;
		SPTR(IntegerEdgeAccumulator) result;
		SPTR(XnRegion) resultReg;
		
		other = CAST(IntegerRegion,region);
		mine = this->edgeStepper();
		others = other->edgeStepper();
		result = IntegerEdgeAccumulator::make (myStartsInside || !other->isBoundedBelow(), myTransitionCount + other->transitionCount());
		for (;;) {	BooleanVar crutch_Flag;
			/* mine->hasValue() && others->hasValue() */
			
			crutch_Flag = mine->hasValue();
			if(crutch_Flag) {
				crutch_Flag = others->hasValue();
			}
			if (crutch_Flag) {
				IntegerVar me;
				IntegerVar him;
				
				me = mine->edge();
				him = others->edge();
				if (me < him) {
					if (others->isEntering()) {
						result->edge(me);
					}
					mine->step();
				} else {
					if (mine->isEntering()) {
						result->edge(him);
					}
					others->step();
				}
			} else {
				break;
			}
		}
		{	BooleanVar crutch_Flag;
			/* mine->hasValue() && others->isEntering() */
			
			crutch_Flag = mine->hasValue();
			if(crutch_Flag) {
				crutch_Flag = others->isEntering();
			}
			if (crutch_Flag) {
				result->edges(mine);
			}
		}
		{	BooleanVar crutch_Flag;
			/* others->hasValue() && mine->isEntering() */
			
			crutch_Flag = others->hasValue();
			if(crutch_Flag) {
				crutch_Flag = mine->isEntering();
			}
			if (crutch_Flag) {
				result->edges(others);
			}
		}
		{mine->destroy();  mine = NULL /* don't want stale (S/CHK)PTRs */;}
		{others->destroy();  others = NULL /* don't want stale (S/CHK)PTRs */;}
		resultReg = result->region();
		{result->destroy();  result = NULL /* don't want stale (S/CHK)PTRs */;}
		WPTR(XnRegion) 	returnValue;
		returnValue = resultReg;
		return returnValue;
	}
}


RPTR(XnRegion) IntegerRegion::with (APTR(Position) position){
	WPTR(XnRegion) 	returnValue;
	returnValue = this->withInt(CAST(IntegerPos,position)->asIntegerVar());
	return returnValue;
}


RPTR(XnRegion) IntegerRegion::withInt (IntegerVar pos){
	SPTR(IntegerEdgeStepper) mine;
	IntegerVar me;
	SPTR(IntegerEdgeAccumulator) result;
	SPTR(XnRegion) resultReg;
	
	if (this->isEmpty()) {
		WPTR(XnRegion) 	returnValue;
		returnValue = IntegerRegion::make (pos);
		return returnValue;
	}
	{	BooleanVar crutch_Flag;
		/* this->isBoundedAbove() && pos == this->stop() */
		
		crutch_Flag = this->isBoundedAbove();
		if(crutch_Flag) {
			crutch_Flag = pos == this->stop();
		}
		if (crutch_Flag) {
			SPTR(IntegerVarArray) newTransitions;
			
			newTransitions = CAST(IntegerVarArray,myTransitions->copy());
			newTransitions->storeIntegerVar(myTransitionCount - 1, pos + 1);
			RETURN_CONSTRUCT(IntegerRegion,(myStartsInside, myTransitionCount, newTransitions));
		}
	}
	mine = this->edgeStepper();
	result = IntegerEdgeAccumulator::make (myStartsInside, myTransitionCount + 2);
	for (;;) {	BooleanVar crutch_Flag;
		/* mine->hasValue() && (me = mine->edge()) < pos */
		
		crutch_Flag = mine->hasValue();
		if(crutch_Flag) {
			crutch_Flag = (me = mine->edge()) < pos;
		}
		if (crutch_Flag) {
			result->edge(me);
			mine->step();
		} else {
			break;
		}
	}
	if (mine->isEntering()) {
		result->edge(pos);
		if (me == pos) {
			mine->step();
		} else {
			result->edge(pos + 1);
		}
	} else {
		if (me == pos) {
			mine->step();
			result->edge(pos + 1);
		}
	}
	if (mine->hasValue()) {
		result->edges(mine);
	}
	{mine->destroy();  mine = NULL /* don't want stale (S/CHK)PTRs */;}
	resultReg = result->region();
	{result->destroy();  result = NULL /* don't want stale (S/CHK)PTRs */;}
	WPTR(XnRegion) 	returnValue;
	returnValue = resultReg;
	return returnValue;
}
/* enumerating */


IntegerVar IntegerRegion::count (){
	IntegerVar result;
	
	if (!this->isFinite()) {
		BLAST(InvalidRequest);
	}
	result = IntegerVarZero;
	{
		UInt32 LoopFinal = myTransitionCount;
		UInt32 i = Int32Zero;
		for (;;) {
			if (i >= LoopFinal){
				break;
			}
			{
				result = result + myTransitions->integerVarAt(i + 1) - myTransitions->integerVarAt(i);
			}
			i += 2;
		}
	}
	return result;
}


BooleanVar IntegerRegion::isEnumerable (APTR(OrderSpec) order/* = NULL*/){
	/* Actually uses the 'order' argument correctly to enumerate the 
		positions. Treats NULL the same as ascending. Iff I am bounded left 
		am I enumerable in ascending order. Similarly, only if I am bounded 
		right am I enumerable in descending order. */
	
	{	BooleanVar crutch_Flag;
		/* order == NULL || order->followsInt(1, IntegerVar0) */
		
		crutch_Flag = order == NULL;
		if(!crutch_Flag) {
			crutch_Flag = order->followsInt(1, IntegerVar0);
		}
		if (crutch_Flag) {
			return this->isBoundedBelow();
		} else {
			return this->isBoundedAbove();
		}
	}
}
/* breaking up */


RPTR(ScruSet) OF1(XnRegion) IntegerRegion::distinctions (){
	SPTR(IntegerRegion) intReg;
	
	if (!this->isSimple()) {
		BLAST(InvalidRequest);
	}
	if (this->isFull()) {
		WPTR(ScruSet) OF1(XnRegion) 	returnValue;
		returnValue = ImmuSet::make ();
		return returnValue;
	}
	{	BooleanVar crutch_Flag;
		/* this->isEmpty() || myTransitionCount == 1 */
		
		crutch_Flag = this->isEmpty();
		if(!crutch_Flag) {
			crutch_Flag = myTransitionCount == 1;
		}
		if (crutch_Flag) {
			WPTR(ScruSet) OF1(XnRegion) 	returnValue;
			returnValue = ImmuSet::make ()->with(this);
			return returnValue;
		}
	}
	CONSTRUCT(intReg,IntegerRegion,(myStartsInside, 1, myTransitions));
	WPTR(ScruSet) OF1(XnRegion) 	returnValue;
	returnValue = ImmuSet::make ()->with(intReg)->with(IntegerRegion::before(this->stop()));
	return returnValue;
}


RPTR(Stepper) IntegerRegion::simpleRegions (APTR(OrderSpec) order/* = NULL*/){
	/* Treats NULL the same as ascending. For the moment, will only work 
		with an ascending OrderSpec. If a descending OrderSpec is provided, 
		it will currently BLAST, but later will work correctly.
		
		Returns a stepper on a disjoint set of simple regions in ascending 
		order.  No difference with disjointSimpleRegions */
	
	{	BooleanVar crutch_Flag;
		/* order == NULL || order->followsInt(1, Int32Zero) */
		
		crutch_Flag = order == NULL;
		if(!crutch_Flag) {
			crutch_Flag = order->followsInt(1, Int32Zero);
		}
		if (!crutch_Flag) {
			BLAST(NOT_YET_IMPLEMENTED);
		}
	}
	if (myTransitionCount == Int32Zero) {
		if (myStartsInside) {
			WPTR(Stepper) 	returnValue;
			returnValue = Stepper::itemStepper(this);
			return returnValue;
		} else {
			WPTR(Stepper) 	returnValue;
			returnValue = Stepper::emptyStepper();
			return returnValue;
		}
	}
	RETURN_CONSTRUCT(IntegerSimpleRegionStepper,(myTransitions, myTransitionCount, !myStartsInside));
}
/* private: */


RPTR(IntegerRegion) IntegerRegion::simpleRegionAtIndex (UInt32 i){
	/* the simple region at the given index in the transition array */
	
	if ( ! (i < myTransitionCount) ) {
		BLAST(Assertion_failed);
	}
	if ((i & 1) == Int32Zero == myStartsInside) {
		WPTR(IntegerRegion) 	returnValue;
		returnValue = IntegerRegion::before(myTransitions->integerVarAt(i));
		return returnValue;
	} else {
		if (i + 1 < myTransitionCount) {
			WPTR(IntegerRegion) 	returnValue;
			returnValue = IntegerRegion::make (myTransitions->integerVarAt(i), myTransitions->integerVarAt(i + 1));
			return returnValue;
		} else {
			WPTR(IntegerRegion) 	returnValue;
			returnValue = IntegerRegion::after(myTransitions->integerVarAt(i));
			return returnValue;
		}
	}
}
/* private: has friends */


RPTR(IntegerEdgeStepper) IntegerRegion::edgeStepper (){
	/* Do not send from outside the module. This should not be exported 
		outside the module, but to not export it in this case is 
	some trouble. */
	
	WPTR(IntegerEdgeStepper) 	returnValue;
	returnValue = IntegerEdgeStepper::make (!myStartsInside, myTransitionCount, myTransitions);
	return returnValue;
}
/* protected: enumerating */


RPTR(Stepper) IntegerRegion::actualStepper (APTR(OrderSpec) order/* = NULL*/){
	/* Iff I am bounded left am I enumerable in ascending order. 
	Similarly, only if I am bounded right am I enumerable in 
	descending order. */
	
	if (order->followsInt(1, IntegerVar0)) {
		WPTR(Stepper) 	returnValue;
		returnValue = AscendingIntegerStepper::make (myTransitions, myTransitionCount);
		return returnValue;
	} else {
		WPTR(Stepper) 	returnValue;
		returnValue = DescendingIntegerStepper::make (myTransitions, myTransitionCount);
		return returnValue;
	}
}



/* ************************************************************************ *
 * 
 *                    Class IntegerSpace 
 *
 * ************************************************************************ */



/* Initializers for IntegerSpace */

GPTR(IntegerSpace) IntegerSpace::TheIntegerSpace = NULL;



BEGIN_INIT_TIME(IntegerSpace,initTimeNonInherited) {
	CONSTRUCT(IntegerSpace::TheIntegerSpace,IntegerSpace,());
} END_INIT_TIME(IntegerSpace,initTimeNonInherited);



/* Initializers for IntegerSpace */






/* creation */
/* rcvr pseudo constructor */


RPTR(Heaper) IntegerSpace::make (APTR(Rcvr) rcvr){
	CAST(SpecialistRcvr,rcvr)->registerIbid(IntegerSpace::TheIntegerSpace);
	WPTR(Heaper) 	returnValue;
	returnValue = IntegerSpace::TheIntegerSpace;
	return returnValue;
}
/* The space of all integers.  See the class comments in 
IntegerRegion, XuInteger, and IntegerDsp for interesting properties 
of this space.  Especially IntegerRegion.
	
	IntegerSpaces are the most frequently used of the coordinate spaces. 
 XuArrays are an efficient data structure which we provide as a table 
whose domain space is an integer space.  In so doing, the notion of 
an array is made to be simply a particular case of a table indexed by 
the positions of a coordinate space.  However, IntegerSpaces and 
XuArrays are both expected to be more efficient than other spaces and 
tables built on other spaces.  See XuArray */


/* creation */


IntegerSpace::IntegerSpace () 
	: CoordinateSpace(IntegerRegion::usingx(FALSE, Int32Zero, IntegerVarArray::zeros(Int32Zero))
		, IntegerRegion::usingx(TRUE, Int32Zero, IntegerVarArray::zeros(Int32Zero))
		, IntegerMapping::identity()
		, IntegerUpOrder::make ()) 
{
	
}
/* making */


RPTR(IntegerRegion) IntegerSpace::above (APTR(IntegerPos) start, BooleanVar inclusive){
	/* Essential. Make a region that contains all integers 
	greater than (or equal if inclusive is true) to start. */
	
	IntegerVar after;
	
	after = start->asIntegerVar();
	if (!inclusive) {
		after += 1;
	}
	WPTR(IntegerRegion) 	returnValue;
	returnValue = IntegerRegion::after(after);
	return returnValue;
}


RPTR(IntegerRegion) IntegerSpace::below (APTR(IntegerPos) stop, BooleanVar inclusive){
	/* Make a region that contains all integers less than (or 
	equal if inclusive is true) to stop. */
	
	IntegerVar after;
	
	after = stop->asIntegerVar();
	if (inclusive) {
		after += 1;
	}
	WPTR(IntegerRegion) 	returnValue;
	returnValue = IntegerRegion::before(after);
	return returnValue;
}


RPTR(IntegerRegion) IntegerSpace::interval (APTR(IntegerPos) start, APTR(IntegerPos) stop){
	/* Make a region that contains all integers greater than or 
	equal to start and less than stop. */
	
	WPTR(IntegerRegion) 	returnValue;
	returnValue = IntegerRegion::make (start->asIntegerVar(), stop->asIntegerVar());
	return returnValue;
}


RPTR(IntegerMapping) IntegerSpace::translation (IntegerVar value){
	/* Essential. Make a Mapping which adds a fixed amount to any value.
		Should this just be supplanted by CoordinateSpace::mapping ()? */
	
	if (value == IntegerVarZero) {
		return CAST(IntegerMapping,this->identityDsp());
	}
	WPTR(IntegerMapping) 	returnValue;
	returnValue = IntegerMapping::make (value);
	return returnValue;
}
/* testing */


UInt32 IntegerSpace::actualHashForEqual (){
	/* is equal to any basic space on the same category of positions */
	
	return this->getCategory()->hashForEqual() + 1;
}


BooleanVar IntegerSpace::isEqual (APTR(Heaper) anObject){
	/* is equal to any basic space on the same category of positions */
	
	return anObject->getCategory() == this->getCategory();
}



/* ************************************************************************ *
 * 
 *                    Class AscendingIntegerStepper 
 *
 * ************************************************************************ */



/* Initializers for AscendingIntegerStepper */

GPTR(InstanceCache) AscendingIntegerStepper::SomeSteppers = NULL;



BEGIN_INIT_TIME(AscendingIntegerStepper,initTimeNonInherited) {
	AscendingIntegerStepper::SomeSteppers = InstanceCache::make (16);
} END_INIT_TIME(AscendingIntegerStepper,initTimeNonInherited);



/* Initializers for AscendingIntegerStepper */






/* creation */


RPTR(Stepper) AscendingIntegerStepper::make (APTR(IntegerVarArray) edges, UInt32 count){
	SPTR(Heaper) result;
	
	result = AscendingIntegerStepper::SomeSteppers->fetch();
	if (result == NULL) {
		RETURN_CONSTRUCT(AscendingIntegerStepper,(edges, count));
	} else {
		WPTR(Stepper) 	returnValue;
		returnValue = new (result) AscendingIntegerStepper(edges, count);
		return returnValue;
	}
}
/* protected: creation */


AscendingIntegerStepper::AscendingIntegerStepper (APTR(IntegerVarArray) edges, UInt32 count) {
	myEdges = edges;
	myIndex = 1;
	myCount = count;
	if (myCount > Int32Zero) {
		myPosition = myEdges->integerVarAt(Int32Zero);
	} else {
		myPosition = IntegerVar0;
	}
}


AscendingIntegerStepper::AscendingIntegerStepper (
		APTR(IntegerVarArray) edges, 
		UInt32 index, 
		UInt32 count, 
		IntegerVar position) 
{
	myEdges = edges;
	myIndex = index;
	myCount = count;
	myPosition = position;
}
/* creation */


RPTR(Stepper) AscendingIntegerStepper::copy (){
	SPTR(Heaper) result;
	
	result = AscendingIntegerStepper::SomeSteppers->fetch();
	if (result == NULL) {
		RETURN_CONSTRUCT(AscendingIntegerStepper,(myEdges, myIndex, myCount, myPosition));
	} else {
		WPTR(Stepper) 	returnValue;
		returnValue = new (result) AscendingIntegerStepper(myEdges, myIndex, myCount, myPosition);
		return returnValue;
	}
}


void AscendingIntegerStepper::destroy (){
	if (!AscendingIntegerStepper::SomeSteppers->store(this)) {
		this->Stepper::destroy();
	}
}
/* accessing */


WPTR(Heaper) AscendingIntegerStepper::fetch (){
	if (this->hasValue()) {
		WPTR(Heaper) 	returnValue;
		returnValue = IntegerPos::make (myPosition);
		return returnValue;
	} else {
		return NULL;
	}
}


BooleanVar AscendingIntegerStepper::hasValue (){
	return myIndex <= myCount;
}


void AscendingIntegerStepper::step (){
	myPosition += 1;
	{	BooleanVar crutch_Flag;
		/* myIndex < myCount && myPosition == myEdges->integerVarAt(myIndex) */
		
		crutch_Flag = myIndex < myCount;
		if(crutch_Flag) {
			crutch_Flag = myPosition == myEdges->integerVarAt(myIndex);
		}
		if (crutch_Flag) {
			myIndex += 2;
			if (myIndex <= myCount) {
				myPosition = myEdges->integerVarAt(myIndex - 1);
			}
		}
	}
}



/* ************************************************************************ *
 * 
 *                    Class DescendingIntegerStepper 
 *
 * ************************************************************************ */


/* creation */


RPTR(Stepper) DescendingIntegerStepper::make (APTR(IntegerVarArray) edges, UInt32 count){
	RETURN_CONSTRUCT(DescendingIntegerStepper,(edges, count));
}
/* protected: create */


DescendingIntegerStepper::DescendingIntegerStepper (APTR(IntegerVarArray) edges, UInt32 count) {
	myEdges = edges;
	myIndex = count - 2;
	if (myIndex >= -1) {
		myPosition = myEdges->integerVarAt(myIndex + 1) - 1;
	} else {
		myPosition = IntegerVar0;
	}
}


DescendingIntegerStepper::DescendingIntegerStepper (
		APTR(IntegerVarArray) edges, 
		Int32 index, 
		IntegerVar position) 
{
	myEdges = edges;
	myIndex = index;
	myPosition = position;
}
/* creation */


RPTR(Stepper) DescendingIntegerStepper::copy (){
	RETURN_CONSTRUCT(DescendingIntegerStepper,(myEdges, myIndex, myPosition));
}
/* accessing */


WPTR(Heaper) DescendingIntegerStepper::fetch (){
	if (this->hasValue()) {
		WPTR(Heaper) 	returnValue;
		returnValue = IntegerPos::make (myPosition);
		return returnValue;
	} else {
		return NULL;
	}
}


BooleanVar DescendingIntegerStepper::hasValue (){
	return myIndex >= -1;
}


void DescendingIntegerStepper::step (){
	myPosition -= 1;
	{	BooleanVar crutch_Flag;
		/* myIndex >= Int32Zero && myPosition < myEdges->integerVarAt(myIndex) */
		
		crutch_Flag = myIndex >= Int32Zero;
		if(crutch_Flag) {
			crutch_Flag = myPosition < myEdges->integerVarAt(myIndex);
		}
		if (crutch_Flag) {
			myIndex -= 2;
			if (myIndex >= -1) {
				myPosition = myEdges->integerVarAt(myIndex + 1) - 1;
			}
		}
	}
}



/* ************************************************************************ *
 * 
 *                    Class IntegerArrangement 
 *
 * ************************************************************************ */


/* creation */


RPTR(IntegerArrangement) IntegerArrangement::make (APTR(XnRegion) region, APTR(OrderSpec) ordering){
	RETURN_CONSTRUCT(IntegerArrangement,(region, ordering));
}
/* accessing */


void IntegerArrangement::copyElements (
		APTR(PrimArray) toArray, 
		APTR(Dsp) toDsp, 
		APTR(PrimArray) fromArray, 
		APTR(Arrangement) fromArrange, 
		APTR(XnRegion) fromRegion)
{
	SPTR(IntegerArrangement) other;
	Int32 start;
	Int32 stop;
	Int32 toStart;
	
	other = CAST(IntegerArrangement,fromArrange);
	if (!myOrdering->isEqual(other->ordering())) {
		BLAST(NOT_YET_IMPLEMENTED);
	}
	{	BooleanVar crutch_Flag;
		/* myRegion->isSimple() && other->region()->isSimple() && fromRegion->isSimple() */
		
		crutch_Flag = myRegion->isSimple();
		if(crutch_Flag) {
			crutch_Flag = other->region()->isSimple();
			if(crutch_Flag) {
				crutch_Flag = fromRegion->isSimple();
			}
		}
		if (!crutch_Flag) {
			BLAST(NOT_YET_IMPLEMENTED);
		}
	}
	/* Known bug !!!! */
	
	/* Assume ascending for the moment. */
	start = fromArrange->indexOf(fromRegion->chooseOne(myOrdering)).asLong();
	stop = fromArrange->indexOf(fromRegion->chooseOne(myOrdering->reversed())).asLong();
	toStart = this->indexOf(toDsp->of(fromRegion->chooseOne(myOrdering))).asLong();
	/* stop < start ifTrue: [| tmp {Int32} | tmp _ start.  start 
		_ stop.  stop _ tmp]. */
	toArray->storeMany(toStart, fromArray, stop + 1 - start, start);
}


IntegerVar IntegerArrangement::indexOf (APTR(Position) position){
	/* Return the index of position into my Region according to 
	my OrderSpec. */
	
	IntegerVar sum;
	IntegerVar intPos;
	
	sum = IntegerVar0;
	intPos = CAST(IntegerPos,position)->asIntegerVar();
	BEGIN_FOR_EACH(IntegerRegion,region,(myRegion->simpleRegions(myOrdering))) {
		if (region->hasIntMember(intPos)) {
			return sum + abs(intPos - CAST(IntegerPos,region->chooseOne(myOrdering))->asIntegerVar());
		} else {
			sum += region->count();
		}
	} END_FOR_EACH;
	BLAST(NotInTable);
	/* compiler fodder */
	return -1;
}


RPTR(IntegerRegion) IntegerArrangement::indicesOf (APTR(XnRegion) region){
	/* Return the region of all the indices corresponding to 
	positions in region. */
	
	BLAST(NOT_YET_IMPLEMENTED);
	/* fodder */
	return NULL;
}


RPTR(XnRegion) IntegerArrangement::keysOf (Int32 start, Int32 stop){
	/* Return the region that corresponds to a range of indices. */
	
	Int32 offset;
	Int32 left;
	Int32 right;
	
	offset = start;
	left = -1;
	BEGIN_FOR_EACH(XnRegion,region,(myRegion->simpleRegions(myOrdering))) {
		if (region->count() <= offset) {
			offset -= region->count().asLong();
		} else {
			if (left == -1) {
				left = CAST(IntegerPos,region->chooseOne(myOrdering))->asIntegerVar().asLong() + offset;
				offset = stop - (start - offset);
				if (offset <= region->count().asLong()) {
					WPTR(XnRegion) 	returnValue;
					returnValue = IntegerRegion::make (left, CAST(IntegerPos,region->chooseOne(myOrdering))->asIntegerVar() + offset);
					return returnValue;
				}
			} else {
				right = CAST(IntegerPos,region->chooseOne(myOrdering))->asIntegerVar().asLong() + offset;
				WPTR(XnRegion) 	returnValue;
				returnValue = IntegerRegion::make (left, right);
				return returnValue;
			}
		}
	} END_FOR_EACH;
	BLAST(NotInTable);
	/* compiler fodder */
	return NULL;
}


RPTR(OrderSpec) IntegerArrangement::ordering (){
	return (OrderSpec*) myOrdering;
}


RPTR(XnRegion) IntegerArrangement::region (){
	return (IntegerRegion*) myRegion;
}
/* printing */


void IntegerArrangement::printOn (ostream& oo){
	oo << this->getCategory()->name() << "(" << myRegion << ", " << myOrdering << ")";
}
/* protected: creation */


IntegerArrangement::IntegerArrangement (APTR(XnRegion) region, APTR(OrderSpec) ordering) {
	if (!region->isFinite()) {
		BLAST(MustBeFinite);
	}
	myRegion = CAST(IntegerRegion,region);
	myOrdering = ordering;
}
/* testing */


UInt32 IntegerArrangement::actualHashForEqual (){
	return myOrdering->hashForEqual() + myRegion->hashForEqual();
}


UInt32 IntegerArrangement::hashForEqual (){
	return myOrdering->hashForEqual() + myRegion->hashForEqual();
}


BooleanVar IntegerArrangement::isEqual (APTR(Heaper) other){
	BEGIN_CHOOSE(other) {
		BEGIN_KIND(IntegerArrangement,o) {
			{	BooleanVar crutch_Flag;
				/* myOrdering->isEqual(o->ordering()) && myRegion->isEqual(o->region()) */
				
				crutch_Flag = myOrdering->isEqual(o->ordering());
				if(crutch_Flag) {
					crutch_Flag = myRegion->isEqual(o->region());
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



/* ************************************************************************ *
 * 
 *                    Class IntegerEdgeAccumulator 
 *
 * ************************************************************************ */



/* Initializers for IntegerEdgeAccumulator */

GPTR(InstanceCache) IntegerEdgeAccumulator::SomeAccumulators = NULL;



BEGIN_INIT_TIME(IntegerEdgeAccumulator,initTimeNonInherited) {
	IntegerEdgeAccumulator::SomeAccumulators = InstanceCache::make (16);
} END_INIT_TIME(IntegerEdgeAccumulator,initTimeNonInherited);



/* Initializers for IntegerEdgeAccumulator */






/* creation */


RPTR(IntegerEdgeAccumulator) IntegerEdgeAccumulator::make (BooleanVar startsInside, UInt32 count){
	SPTR(Heaper) result;
	
	result = IntegerEdgeAccumulator::SomeAccumulators->fetch();
	if (result == NULL) {
		RETURN_CONSTRUCT(IntegerEdgeAccumulator,(startsInside, count));
	} else {
		WPTR(IntegerEdgeAccumulator) 	returnValue;
		returnValue = new (result) IntegerEdgeAccumulator(startsInside, count);
		return returnValue;
	}
}
/* protected: creation */


IntegerEdgeAccumulator::IntegerEdgeAccumulator (BooleanVar startsInside, UInt32 count) {
	myStartsInside = startsInside;
	myEdges = IntegerVarArray::zeros(count);
	myIndex = Int32Zero;
	havePending = FALSE;
	myPending = IntegerVar0;
}


IntegerEdgeAccumulator::IntegerEdgeAccumulator (
		BooleanVar startsInside, 
		APTR(IntegerVarArray) edges, 
		UInt32 index, 
		BooleanVar hasPending, 
		IntegerVar pending) 
{
	myStartsInside = startsInside;
	myEdges = edges;
	myIndex = index;
	havePending = hasPending;
	myPending = pending;
}
/* creation */


RPTR(Accumulator) IntegerEdgeAccumulator::copy (){
	SPTR(Heaper) result;
	
	result = IntegerEdgeAccumulator::SomeAccumulators->fetch();
	if (result == NULL) {
		RETURN_CONSTRUCT(IntegerEdgeAccumulator,(myStartsInside, myEdges, myIndex, havePending, myPending));
	} else {
		WPTR(Accumulator) 	returnValue;
		returnValue = new (result) IntegerEdgeAccumulator(myStartsInside, myEdges, myIndex, havePending, myPending);
		return returnValue;
	}
}


void IntegerEdgeAccumulator::destroy (){
	if (!IntegerEdgeAccumulator::SomeAccumulators->store(this)) {
		this->Accumulator::destroy();
	}
}
/* operations */


void IntegerEdgeAccumulator::step (APTR(Heaper) someObj){
	this->edge(CAST(IntegerPos,someObj)->asIntegerVar());
}


RPTR(Heaper) IntegerEdgeAccumulator::value (){
	WPTR(Heaper) 	returnValue;
	returnValue = this->region();
	return returnValue;
}
/* printing */


void IntegerEdgeAccumulator::printOn (ostream& oo){
	oo << this->getCategory()->name() << "(" << this->region() << ")";
}
/* edge operations */


void IntegerEdgeAccumulator::edge (IntegerVar x){
	/* add a transition at the given position. doing it again 
	cancels it.  This particular coding is used for C++ inlinability */
	
	if (havePending) {
		if (myPending == x) {
			havePending = FALSE;
		} else {
			myEdges->storeIntegerVar(myIndex, myPending);
			myIndex += 1;
			myPending = x;
		}
	} else {
		havePending = TRUE;
		myPending = x;
	}
}


void IntegerEdgeAccumulator::edges (APTR(IntegerEdgeStepper) stepper){
	/* add a whole bunch of edges at once, assuming that they are 
	sorted and there are no duplicates */
	
	if (stepper->hasValue()) {
		this->edge(stepper->edge());
		stepper->step();
		if (stepper->hasValue()) {
			if (!havePending) {
				myPending = stepper->edge();
				havePending = TRUE;
				stepper->step();
			}
			while (stepper->hasValue()) {
				myEdges->storeIntegerVar(myIndex, myPending);
				myIndex += 1;
				myPending = stepper->edge();
				stepper->step();
			}
		}
	}
}


RPTR(IntegerRegion) IntegerEdgeAccumulator::region (){
	/* make a region out of the accumulated edges */
	
	if (havePending) {
		myEdges->storeIntegerVar(myIndex, myPending);
		RETURN_CONSTRUCT(IntegerRegion,(myStartsInside, myIndex + 1, myEdges));
	} else {
		if (myIndex == Int32Zero) {
			if (myStartsInside) {
				WPTR(IntegerRegion) 	returnValue;
				returnValue = IntegerRegion::allIntegers();
				return returnValue;
			} else {
				WPTR(IntegerRegion) 	returnValue;
				returnValue = IntegerRegion::make ();
				return returnValue;
			}
		} else {
			RETURN_CONSTRUCT(IntegerRegion,(myStartsInside, myIndex, myEdges));
		}
	}
}



/* ************************************************************************ *
 * 
 *                    Class IntegerEdgeStepper 
 *
 * ************************************************************************ */



/* Initializers for IntegerEdgeStepper */

GPTR(InstanceCache) IntegerEdgeStepper::SomeEdgeSteppers = NULL;



BEGIN_INIT_TIME(IntegerEdgeStepper,initTimeNonInherited) {
	IntegerEdgeStepper::SomeEdgeSteppers = InstanceCache::make (2);
} END_INIT_TIME(IntegerEdgeStepper,initTimeNonInherited);



/* Initializers for IntegerEdgeStepper */






/* errors */


void IntegerEdgeStepper::outOfBounds (){
	BLAST(OutOfBounds);
}
/* create */


RPTR(IntegerEdgeStepper) IntegerEdgeStepper::make (
		BooleanVar entering, 
		UInt32 count, 
		APTR(IntegerVarArray) edges)
{
	SPTR(Heaper) result;
	
	result = IntegerEdgeStepper::SomeEdgeSteppers->fetch();
	if (result == NULL) {
		RETURN_CONSTRUCT(IntegerEdgeStepper,(entering, count, edges));
	} else {
		WPTR(IntegerEdgeStepper) 	returnValue;
		returnValue = new (result) IntegerEdgeStepper(entering, count, edges);
		return returnValue;
	}
}
/* A single instance of this class is cached.  To take advantage of 
this, a method
that uses IntegerEdgeSteppers should explicitly destroy at least one 
of them. */


/* operations */


WPTR(Heaper) IntegerEdgeStepper::fetch (){
	if (this->hasValue()) {
		WPTR(Heaper) 	returnValue;
		returnValue = IntegerPos::make (this->edge());
		return returnValue;
	} else {
		return NULL;
	}
}
/* edge accessing */
/* protected: create */


IntegerEdgeStepper::IntegerEdgeStepper (
		BooleanVar entering, 
		UInt32 count, 
		APTR(IntegerVarArray) edges) 
{
	myEntering = entering;
	myIndex = Int32Zero;
	myCount = count;
	myEdges = edges;
}


IntegerEdgeStepper::IntegerEdgeStepper (
		BooleanVar entering, 
		UInt32 index, 
		UInt32 count, 
		APTR(IntegerVarArray) edges) 
{
	myEntering = entering;
	myIndex = index;
	myCount = count;
	myEdges = edges;
}
/* destroy */


void IntegerEdgeStepper::destroy (){
	if (!IntegerEdgeStepper::SomeEdgeSteppers->store(this)) {
		this->Stepper::destroy();
	}
}
/* create */


RPTR(Stepper) IntegerEdgeStepper::copy (){
	RETURN_CONSTRUCT(IntegerEdgeStepper,(myEntering, myIndex, myCount, myEdges));
}
/* printing */


void IntegerEdgeStepper::printOn (ostream& oo){
	oo << this->getCategory()->name() << "(";
	if (this->hasValue()) {
		if (this->isEntering()) {
			oo << "entering ";
		} else {
			oo << "leaving ";
		}
		oo << this->edge();
	}
	oo << ")";
}



/* ************************************************************************ *
 * 
 *                    Class IntegerSimpleRegionStepper 
 *
 * ************************************************************************ */


/* operations */


WPTR(Heaper) IntegerSimpleRegionStepper::fetch (){
	return (IntegerRegion*) mySimple;
}


BooleanVar IntegerSimpleRegionStepper::hasValue (){
	return mySimple != NULL;
}


void IntegerSimpleRegionStepper::step (){
	if (isLeftBounded) {
		myIndex += 2;
	} else {
		myIndex += 1;
	}
	isLeftBounded = TRUE;
	if (myIndex < myCount) {
		if (myIndex < myCount - 1) {
			mySimple = IntegerRegion::make (myEdges->integerVarAt(myIndex), myEdges->integerVarAt(myIndex + 1));
		} else {
			mySimple = IntegerRegion::after(myEdges->integerVarAt(myIndex));
		}
	} else {
		mySimple = NULL;
	}
}
/* unprotected create */


IntegerSimpleRegionStepper::IntegerSimpleRegionStepper (
		APTR(IntegerVarArray) edges, 
		UInt32 count, 
		BooleanVar leftBounded) 
{
	myEdges = edges;
	myIndex = Int32Zero;
	myCount = count;
	isLeftBounded = leftBounded;
	if (count == Int32Zero) {
		if (leftBounded) {
			mySimple = NULL;
		} else {
			mySimple = IntegerRegion::allIntegers();
		}
	} else {
		if (!leftBounded) {
			mySimple = IntegerRegion::before(edges->integerVarAt(Int32Zero));
		} else {
			if (count == 1) {
				mySimple = IntegerRegion::after(edges->integerVarAt(Int32Zero));
			} else {
				mySimple = IntegerRegion::make (edges->integerVarAt(Int32Zero), edges->integerVarAt(1));
			}
		}
	}
}


IntegerSimpleRegionStepper::IntegerSimpleRegionStepper (
		APTR(IntegerVarArray) edges, 
		UInt32 index, 
		UInt32 count, 
		BooleanVar leftBounded, 
		APTR(IntegerRegion) simple) 
{
	myEdges = edges;
	myIndex = index;
	myCount = count;
	isLeftBounded = leftBounded;
	mySimple = simple;
}
/* create */


RPTR(Stepper) IntegerSimpleRegionStepper::copy (){
	RETURN_CONSTRUCT(IntegerSimpleRegionStepper,(myEdges, myIndex, myCount, isLeftBounded, mySimple));
}
/* printing */


void IntegerSimpleRegionStepper::printOn (ostream& oo){
	oo << this->getCategory()->name() << "(";
	if (this->hasValue()) {
		oo << this->fetch();
	}
	oo << ")";
}



/* ************************************************************************ *
 * 
 *                    Class IntegerUpOrder 
 *
 * ************************************************************************ */


/* pseudoconstructors */


RPTR(OrderSpec) IntegerUpOrder::make (){
	RETURN_CONSTRUCT(IntegerUpOrder,());
}
/* testing */


UInt32 IntegerUpOrder::actualHashForEqual (){
	return cat_IntegerUpOrder->hashForEqual() + 1;
}


BooleanVar IntegerUpOrder::follows (APTR(Position) x, APTR(Position) y){
	return CAST(IntegerPos,x)->asIntegerVar() >= CAST(IntegerPos,y)->asIntegerVar();
}


BooleanVar IntegerUpOrder::followsInt (IntegerVar x, IntegerVar y){
	/* See discussion in XuInteger class comment about boxed vs 
	unboxed integers */
	
	return x >= y;
}


BooleanVar IntegerUpOrder::isEqual (APTR(Heaper) other){
	return other->isKindOf(cat_IntegerUpOrder);
}


BooleanVar IntegerUpOrder::isFullOrder (APTR(XnRegion) /* keys *//* = NULL*/){
	return TRUE;
}


BooleanVar IntegerUpOrder::preceeds (APTR(XnRegion) before, APTR(XnRegion) after){
	/* Return true if some position in before is less than or 
	equal to all positions in after. */
	
	SPTR(IntegerRegion) first;
	SPTR(IntegerRegion) second;
	
	first = CAST(IntegerRegion,before);
	second = CAST(IntegerRegion,after);
	if (!first->isBoundedBelow()) {
		return TRUE;
	}
	if (!second->isBoundedBelow()) {
		return FALSE;
	}
	return first->start() <= second->start();
}
/* accessing */


RPTR(Arrangement) IntegerUpOrder::arrange (APTR(XnRegion) region){
	WPTR(Arrangement) 	returnValue;
	returnValue = IntegerArrangement::make (region, this);
	return returnValue;
}


RPTR(XnRegion) IntegerUpOrder::chooseMany (APTR(XnRegion) region, IntegerVar n){
	/* Return the first n positions in the region according to my 
	ordering. */
	
	WPTR(XnRegion) 	returnValue;
	returnValue = this->arrange(region)->keysOf(Int32Zero, n.asLong());
	return returnValue;
}


RPTR(Position) IntegerUpOrder::chooseOne (APTR(XnRegion) region){
	/* Return the first position in the region according to my ordering. */
	
	WPTR(Position) 	returnValue;
	returnValue = IntegerPos::make (CAST(IntegerRegion,region)->start());
	return returnValue;
}


RPTR(CoordinateSpace) IntegerUpOrder::coordinateSpace (){
	WPTR(CoordinateSpace) 	returnValue;
	returnValue = IntegerSpace::make ();
	return returnValue;
}

	/* automatic 0-argument constructor */
IntegerUpOrder::IntegerUpOrder() {}

#ifndef INTEGERX_SXX
#include "integerx.sxx"
#endif /* INTEGERX_SXX */


#ifndef INTEGERP_SXX
#include "integerp.sxx"
#endif /* INTEGERP_SXX */



#endif /* INTEGERX_CXX */

