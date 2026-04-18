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

#ifndef REALX_CXX
#define REALX_CXX


#ifndef CHOOSEX_HXX
#include "choosex.hxx"
#endif /* CHOOSEX_HXX */

#ifndef REALX_HXX
#include "realx.hxx"
#endif /* REALX_HXX */

#ifndef REALX_IXX
#include "realx.ixx"
#endif /* REALX_IXX */

#ifndef REALP_HXX
#include "realp.hxx"
#endif /* REALP_HXX */

#ifndef REALP_IXX
#include "realp.ixx"
#endif /* REALP_IXX */


#ifndef NXCVRX_HXX
#include "nxcvrx.hxx"
#endif /* NXCVRX_HXX */

#ifndef PRIMVALX_HXX
#include "primvalx.hxx"
#endif /* PRIMVALX_HXX */

#ifndef XFRSPECX_HXX
#include "xfrspecx.hxx"
#endif /* XFRSPECX_HXX */




/* ************************************************************************ *
 * 
 *                    Class RealPos 
 *
 * ************************************************************************ */


/* creation */


RPTR(RealPos) RealPos::makeIEEE32 (IEEE32 value){
	/* See comment in XuReal::makeIEEE64 */
	
	/* Known bug !!!! */
	
	/* must ensure that it is a number, and convert -0 to +0 */
	/* Thing to do !!!! */
	
	/* perhaps we should check to see if a lower precision can 
	hold it exactly, and delegate to XuIEEE8.  Nahh. */
	RETURN_CONSTRUCT(IEEE32Pos,(value, tcsj));
}


RPTR(RealPos) RealPos::makeIEEE64 (IEEE64 value){
	/* Returns an XuReal which exactly represents the same real 
	number that is represented by 'value'.  BLASTs if value 
	doesn't represent a real (i.e., no NANs or inifinities).  
	Negative 0 will be silently converted to positive zero */
	
	/* Known bug !!!! */
	
	/* must ensure that it is a number, and convert -0 to +0 */
	/* Thing to do !!!! */
	
	/* perhaps we should check to see if a lower precision can 
	hold it exactly, and delegate to XuIEEE32 or XuIEEE8.  Nahh. */
	RETURN_CONSTRUCT(IEEE64Pos,(value, tcsj));
}


RPTR(RealPos) RealPos::makeIEEE8 (IEEE8 value){
	/* See comment in XuReal::makeIEEE64 */
	
	/* Known bug !!!! */
	
	/* must ensure that it is a number, and convert -0 to +0 */
	RETURN_CONSTRUCT(IEEE8Pos,(value, tcsj));
}
/* Represents some real number exactly.  Not all real numbers can be 
exactly represented.  See class comment in RealSpace. */


/* accessing */


RPTR(XnRegion) RealPos::asRegion (){
	WPTR(XnRegion) 	returnValue;
	returnValue = RealRegion::make (FALSE, PrimSpec::pointer()->arrayWithTwo(BeforeReal::make (this), AfterReal::make (this)));
	return returnValue;
}
/* testing */


UInt32 RealPos::actualHashForEqual (){
	return (UInt32 ) this->asIEEE64();
	
	
}


BooleanVar RealPos::isEqual (APTR(Heaper) other){
	/* MarkM -- Thing to do !!!! */
	
	/* 128 bit values */
	BEGIN_CHOOSE(other) {
		BEGIN_KIND(RealPos,r) {
			return this->asIEEE64() == r->asIEEE64();
		} END_KIND;
		BEGIN_OTHERS {
			return FALSE;
		} END_OTHERS;
	} END_CHOOSE;
	/* fodder */
	return FALSE;
}


BooleanVar RealPos::isGE (APTR(Position) other){
	return this->asIEEE64() >= CAST(RealPos,other)->asIEEE64();
}
/* obsolete: */

	/* automatic 0-argument constructor */
RealPos::RealPos() {}



/* ************************************************************************ *
 * 
 *                    Class RealRegion 
 *
 * ************************************************************************ */



/* Initializers for RealRegion */

GPTR(RealManager) RealRegion::TheManager = NULL;



BEGIN_INIT_TIME(RealRegion,initTimeNonInherited) {
	REQUIRES (EdgeManager);
	CONSTRUCT(RealRegion::TheManager,RealManager,());
} END_INIT_TIME(RealRegion,initTimeNonInherited);



/* Initializers for RealRegion */






/* creation */


RPTR(RealRegion) RealRegion::make (BooleanVar startsInside, APTR(PrimArray) OF1(RealEdge) transitions){
	/* Make a new region, reusing the given array. Noone else 
	should ever modify it! */
	
	Int32 precision;
	SPTR(PrimSpec) spec;
	SPTR(PrimFloatArray) transVals;
	SPTR(PrimIntegerArray) transFlags;
	SPTR(PtrArray) tr;
	
	tr = CAST(PtrArray,transitions);
	precision = Int32Zero;
	{
		Int32 LoopFinal = transitions->count();
		Int32 i = Int32Zero;
		for (;;) {
			if (i >= LoopFinal){
				break;
			}
			{
				precision = max(precision, CAST(RealEdge,tr->get(i))->position()->precision());
			}
			i += 1;
		}
	}
	if (precision == 64) {
		spec = PrimSpec::iEEE64();
	} else {
		if (precision == 32) {
			spec = PrimSpec::iEEE32();
		} else {
			if (precision == 8) {
				spec = PrimSpec::iEEE32();
				/* add an iEEE8 spec to the system 
					and use it here */
				/* Thing to do !!!! */
				
			} else {
				if (transitions->count() == Int32Zero) {
					spec = PrimSpec::iEEE64();
				} else {
					BLAST(UnrecognizedPrecision);
				}
			}
		}
	}
	transVals = CAST(PrimFloatArray,spec->array(transitions->count()));
	transFlags = CAST(PrimIntegerArray,PrimSpec::uInt8()->array(tr->count()));
	/* Thing to do !!!! */
	
	/* add 'PrimSpec uInt1' to the system and use it here */
	{
		Int32 LoopFinal = transitions->count();
		Int32 i = Int32Zero;
		for (;;) {
			if (i >= LoopFinal){
				break;
			}
			{
				SPTR(RealEdge) edge;
				UInt1 flag;
				
				edge = CAST(RealEdge,tr->get(i));
				transVals->storeFloat(i, edge->position()->asIEEE64());
				BEGIN_CHOOSE(edge) {
					BEGIN_KIND(BeforeReal,after) {
						flag = UInt32Zero;
					} END_KIND;
					BEGIN_KIND(AfterReal,before) {
						flag = 1;
					} END_KIND;
				} END_CHOOSE;
				transFlags->storeInteger(i, flag);
			}
			i += 1;
		}
	}
	WPTR(RealRegion) 	returnValue;
	returnValue = RealRegion::usingx(startsInside, transVals, transFlags);
	return returnValue;
}


RPTR(RealRegion) RealRegion::usingx (
		BooleanVar startsInside, 
		APTR(PrimFloatArray) vals, 
		APTR(PrimIntegerArray) flags)
{
	RETURN_CONSTRUCT(RealRegion,(startsInside, vals, flags));
}
/* enumerating */


RPTR(Stepper) RealRegion::simpleRegions (APTR(OrderSpec) order/* = NULL*/){
	WPTR(Stepper) 	returnValue;
	returnValue = RealRegion::TheManager->simpleRegions(this, order);
	return returnValue;
}


RPTR(Stepper) OF1(Position) RealRegion::stepper (APTR(OrderSpec) order/* = NULL*/){
	if (!this->isFinite()) {
		BLAST(NotEnumerable);
	}
	RETURN_CONSTRUCT(RealStepper,(this->secretTransitions(), tcsj));
}
/* protected: enumerating */


RPTR(Stepper) OF1(Position) RealRegion::actualStepper (APTR(OrderSpec) order){
	BLAST(SHOULD_NOT_IMPLEMENT);
	/* fodder */
	return NULL;
}
/* testing */


UInt32 RealRegion::actualHashForEqual (){
	return this->getCategory()->hashForEqual() ^ myTransitionVals->contentsHash() ^ myTransitionFlags->contentsHash() ^ (myStartsInside ? 255 : UInt32Zero);
}


BooleanVar RealRegion::isEqual (APTR(Heaper) other){
	BEGIN_CHOOSE(other) {
		BEGIN_KIND(RealRegion,region) {
			{	BooleanVar crutch_Flag;
				/* myStartsInside == region->startsInside() && this->secretTransitions()->contentsEqual(region->secretTransitions()) */
				
				crutch_Flag = myStartsInside == region->startsInside();
				if(crutch_Flag) {
					crutch_Flag = this->secretTransitions()->contentsEqual(region->secretTransitions());
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


BooleanVar RealRegion::isFinite (){
	return RealRegion::TheManager->isFinite(this);
}


BooleanVar RealRegion::isFull (){
	return RealRegion::TheManager->isFull(this);
}


BooleanVar RealRegion::isSimple (){
	return RealRegion::TheManager->isSimple(this);
}


BooleanVar RealRegion::isSubsetOf (APTR(XnRegion) other){
	return RealRegion::TheManager->isSubsetOf(this, other);
}
/* operations */


RPTR(XnRegion) RealRegion::simpleUnion (APTR(XnRegion) other){
	WPTR(XnRegion) 	returnValue;
	returnValue = RealRegion::TheManager->simpleUnion(this, other);
	return returnValue;
}


RPTR(XnRegion) RealRegion::unionWith (APTR(XnRegion) other){
	WPTR(XnRegion) 	returnValue;
	returnValue = RealRegion::TheManager->unionWith(this, other);
	return returnValue;
}
/* secret */


RPTR(PtrArray) OF1(RealEdge) RealRegion::secretTransitions (){
	SPTR(PtrArray) OF1(RealEdge) result;
	
	result = CAST(PtrArray,PrimSpec::pointer()->array(myTransitionVals->count()));
	{
		Int32 LoopFinal = result->count();
		Int32 i = Int32Zero;
		for (;;) {
			if (i >= LoopFinal){
				break;
			}
			{
				SPTR(RealPos) pos;
				SPTR(RealEdge) edge;
				
				pos = RealPos::make (myTransitionVals->floatAt(i));
				if (myTransitionFlags->integerAt(i) == IntegerVar0) {
					edge = BeforeReal::make (pos);
				} else {
					edge = AfterReal::make (pos);
				}
				result->store(i, edge);
			}
			i += 1;
		}
	}
	WPTR(PtrArray) OF1(RealEdge) 	returnValue;
	returnValue = result;
	return returnValue;
}
/* printing */


void RealRegion::printOn (ostream& oo){
	RealRegion::TheManager->printRegionOn(this, oo);
}
/* accessing */


RPTR(RealPos) RealRegion::lowerBound (){
	/* The largest real number such that all the positions in the 
	region are >= it.  Does not necessarily lie in the region.  
	For example, the region of all numbers > 2 has a lowerBound of 2. */
	
	return CAST(RealPos,RealRegion::TheManager->greatestLowerBound(this));
}


RPTR(RealPos) RealRegion::upperBound (){
	/* The smallest real number such that all the positions in 
	the region are <= it.  Does not necessarily lie in the 
	region.  For example, the region of all numbers < 2 has an 
	upperBound of 2. */
	
	return CAST(RealPos,RealRegion::TheManager->leastUpperBound(this));
}
/* creation */


RealRegion::RealRegion (
		BooleanVar startsInside, 
		APTR(PrimFloatArray) vals, 
		APTR(PrimIntegerArray) flags) 
{
	myStartsInside = startsInside;
	myTransitionVals = vals;
	myTransitionFlags = flags;
}



/* ************************************************************************ *
 * 
 *                    Class RealSpace 
 *
 * ************************************************************************ */



/* Initializers for RealSpace */

GPTR(RealSpace) RealSpace::TheRealSpace = NULL;



BEGIN_INIT_TIME(RealSpace,initTimeNonInherited) {
	REQUIRES (PrimSpec);
	CONSTRUCT(RealSpace::TheRealSpace,RealSpace,());
} END_INIT_TIME(RealSpace,initTimeNonInherited);



/* Initializers for RealSpace */






/* creation */
/* rcvr pseudo constructors */


RPTR(Heaper) RealSpace::make (APTR(Rcvr) rcvr){
	CAST(SpecialistRcvr,rcvr)->registerIbid(RealSpace::TheRealSpace);
	WPTR(Heaper) 	returnValue;
	returnValue = RealSpace::TheRealSpace;
	return returnValue;
}
/* Non-arithmetic space of real numbers in which only certain 
positions are explicitly representable.  In this release, the only 
exactly representable numbers are those real numbers which can be 
represented in IEEE64 (double precision) format.  Future releases may 
make more real numbers representable. */


/* create */


RealSpace::RealSpace () 
	: CoordinateSpace(RealRegion::make (FALSE, PtrArray::empty())
		, RealRegion::make (TRUE, PtrArray::empty())
		, RealDsp::make ()
		, RealUpOrder::make ()) 
{
	
}
/* making */


RPTR(RealRegion) RealSpace::above (APTR(RealPos) val, BooleanVar inclusive){
	/* The region consisting of all positions >= val if 
	inclusive, or all > val if not inclusive. */
	
	if (inclusive) {
		WPTR(RealRegion) 	returnValue;
		returnValue = RealRegion::make (FALSE, PrimSpec::pointer()->arrayWith(BeforeReal::make (val)));
		return returnValue;
	} else {
		WPTR(RealRegion) 	returnValue;
		returnValue = RealRegion::make (FALSE, PrimSpec::pointer()->arrayWith(AfterReal::make (val)));
		return returnValue;
	}
}


RPTR(RealRegion) RealSpace::below (APTR(RealPos) val, BooleanVar inclusive){
	/* The region consisting of all positions <= val if 
	inclusive, or all < val if not inclusive. */
	
	if (inclusive) {
		WPTR(RealRegion) 	returnValue;
		returnValue = RealRegion::make (TRUE, PrimSpec::pointer()->arrayWith(AfterReal::make (val)));
		return returnValue;
	} else {
		WPTR(RealRegion) 	returnValue;
		returnValue = RealRegion::make (TRUE, PrimSpec::pointer()->arrayWith(BeforeReal::make (val)));
		return returnValue;
	}
}


RPTR(RealRegion) RealSpace::interval (APTR(RealPos) start, APTR(RealPos) stop){
	/* Return a region of all numbers >= lower and < upper. */
	
	/* MarkM -- Thing to do !!!! */
	
	/* use a single constructor */
	return CAST(RealRegion,this->above(start, TRUE)->intersect(this->below(stop, FALSE)));
}
/* obsolete: */


RPTR(RealRegion) RealSpace::after (IEEE64 val){
	/* The region consisting of all position >= val.
		Should this just be supplanted by CoordinateSpace::region ()? */
	
	/* Thing to do !!!! */
	
	/* update clients */
	WPTR(RealRegion) 	returnValue;
	returnValue = RealRegion::make (FALSE, PrimSpec::pointer()->arrayWith(BeforeReal::make (RealPos::make (val))));
	return returnValue;
}


RPTR(RealRegion) RealSpace::before (IEEE64 val){
	/* The region consisting of all position <= val
		Should this just be supplanted by CoordinateSpace::region ()? */
	
	/* Thing to do !!!! */
	
	/* update clients */
	WPTR(RealRegion) 	returnValue;
	returnValue = RealRegion::make (TRUE, PrimSpec::pointer()->arrayWith(AfterReal::make (RealPos::make (val))));
	return returnValue;
}


RPTR(RealRegion) RealSpace::strictlyAfter (IEEE64 val){
	/* The region consisting of all position > val
		Should this just be supplanted by CoordinateSpace::region ()?
		Add Boolean to after to say whether its inclusive? */
	
	/* Thing to do !!!! */
	
	/* update clients */
	WPTR(RealRegion) 	returnValue;
	returnValue = RealRegion::make (FALSE, PrimSpec::pointer()->arrayWith(AfterReal::make (RealPos::make (val))));
	return returnValue;
}


RPTR(RealRegion) RealSpace::strictlyBefore (IEEE64 val){
	/* The region consisting of all position < val
		Should this just be supplanted by CoordinateSpace::region ()?
		Add Boolean to before to say whether its inclusive? */
	
	/* Thing to do !!!! */
	
	/* update clients */
	WPTR(RealRegion) 	returnValue;
	returnValue = RealRegion::make (TRUE, PrimSpec::pointer()->arrayWith(AfterReal::make (RealPos::make (val))));
	return returnValue;
}
/* testing */


UInt32 RealSpace::actualHashForEqual (){
	/* is equal to any basic space on the same category of positions */
	
	return this->getCategory()->hashForEqual() + 1;
}


BooleanVar RealSpace::isEqual (APTR(Heaper) anObject){
	/* is equal to any basic space on the same category of positions */
	
	return anObject->getCategory() == this->getCategory();
}



/* ************************************************************************ *
 * 
 *                    Class IEEE32Pos 
 *
 * ************************************************************************ */


/* For representing exactly those real numbers that can be 
represented in IEEE single precision */


/* creation */


IEEE32Pos::IEEE32Pos (IEEE32 value, TCSJ) {
	myValue = value;
}
/* obsolete: */


IEEE64 IEEE32Pos::asIEEE (){
	return (IEEE64 ) myValue;
	
	
}


IEEE64 IEEE32Pos::asIEEE64 (){
	return (IEEE64 ) myValue;
	
	
}


Int32 IEEE32Pos::precision (){
	return 32;
}
/* printing */


void IEEE32Pos::printOn (ostream& oo){
	oo << "<" << myValue << ">";
}
/* accessing */


RPTR(PrimFloatValue) IEEE32Pos::value (){
	WPTR(PrimFloatValue) 	returnValue;
	returnValue = PrimIEEE32::make (myValue);
	return returnValue;
}



/* ************************************************************************ *
 * 
 *                    Class IEEE64Pos 
 *
 * ************************************************************************ */


/* For representing exactly those real numbers that can be 
represented in IEEE double precision */


/* creation */


IEEE64Pos::IEEE64Pos (IEEE64 value, TCSJ) {
	myValue = value;
}
/* obsolete: */


IEEE64 IEEE64Pos::asIEEE (){
	return myValue;
}


IEEE64 IEEE64Pos::asIEEE64 (){
	return myValue;
}


Int32 IEEE64Pos::precision (){
	return 64;
}
/* printing */


void IEEE64Pos::printOn (ostream& oo){
	oo << "<" << myValue << ">";
}
/* accessing */


RPTR(PrimFloatValue) IEEE64Pos::value (){
	WPTR(PrimFloatValue) 	returnValue;
	returnValue = PrimIEEE64::make (myValue);
	return returnValue;
}



/* ************************************************************************ *
 * 
 *                    Class IEEE8Pos 
 *
 * ************************************************************************ */


/* For representing exactly those real numbers that can be 
represented in IEEE stupid precision */


/* creation */


IEEE8Pos::IEEE8Pos (IEEE8 value, TCSJ) {
	myValue = value;
}
/* obsolete: */


IEEE64 IEEE8Pos::asIEEE (){
	BLAST(NOT_YET_IMPLEMENTED);
	/* fodder */
	return 0.0;
}


IEEE64 IEEE8Pos::asIEEE64 (){
	BLAST(NOT_YET_IMPLEMENTED);
	/* fodder */
	return 0.0;
}


Int32 IEEE8Pos::precision (){
	return 8;
}
/* accessing */


RPTR(PrimFloatValue) IEEE8Pos::value (){
	BLAST(NOT_YET_IMPLEMENTED);
	/* fodder */
	return NULL;
}



/* ************************************************************************ *
 * 
 *                    Class RealDsp 
 *
 * ************************************************************************ */



/* Initializers for RealDsp */

/* Initializer inherited from IdentityDsp */

IdentityDsp * RealDsp::theDsp = NULL;


/* Initializer inherited from IdentityDsp */


BEGIN_INIT_TIME(RealDsp,initTimeInherited) {
	CONSTRUCT_ON(PERSISTENT,RealDsp::theDsp,RealDsp,());
} END_INIT_TIME(RealDsp,initTimeInherited);



/* Initializers for RealDsp */

/* Initializer inherited from IdentityDsp */




/* Initializer inherited from IdentityDsp */



/* creation */


RPTR(Dsp) RealDsp::make (){
	RETURN_CONSTRUCT(RealDsp,());
}
/* deferred accessing */


RPTR(CoordinateSpace) RealDsp::coordinateSpace (){
	WPTR(CoordinateSpace) 	returnValue;
	returnValue = RealSpace::make ();
	return returnValue;
}

	/* automatic 0-argument constructor */
RealDsp::RealDsp() {}



/* ************************************************************************ *
 * 
 *                    Class RealEdge 
 *
 * ************************************************************************ */


/* accessing */


RPTR(RealPos) RealEdge::position (){
	return (RealPos*) myPos;
}
/* testing */


UInt32 RealEdge::actualHashForEqual (){
	return myPos->hashForEqual() ^ this->getCategory()->hashForEqual();
}


BooleanVar RealEdge::touches (APTR(TransitionEdge) other){
	return myPos->isEqual(CAST(RealEdge,other)->position());
}
/* printing */
/* creation */


RealEdge::RealEdge (APTR(RealPos) pos, TCSJ) {
	myPos = pos;
}



/* ************************************************************************ *
 * 
 *                    Class   AfterReal 
 *
 * ************************************************************************ */


/* create */


RPTR(RealEdge) AfterReal::make (APTR(RealPos) pos){
	RETURN_CONSTRUCT(AfterReal,(pos, tcsj));
}
/* comparing */


BooleanVar AfterReal::follows (APTR(Position) pos){
	return this->position()->isGE(CAST(RealPos,pos));
}


BooleanVar AfterReal::isEqual (APTR(Heaper) other){
	BEGIN_CHOOSE(other) {
		BEGIN_KIND(AfterReal,after) {
			return this->position()->isEqual(after->position());
		} END_KIND;
		BEGIN_OTHERS {
			return FALSE;
		} END_OTHERS;
	} END_CHOOSE;
	/* fodder */
	return FALSE;
}


BooleanVar AfterReal::isFollowedBy (APTR(TransitionEdge) next){
	return FALSE;
}


BooleanVar AfterReal::isGE (APTR(TransitionEdge) other){
	return this->position()->isGE(CAST(RealEdge,other)->position());
}
/* printing */


void AfterReal::printTransitionOn (
		ostream& oo, 
		BooleanVar entering, 
		BooleanVar touchesPrevious)
{
	oo << " ";
	if (entering) {
		oo << "(";
	}
	{	BooleanVar crutch_Flag;
		/* touchesPrevious && !entering */
		
		crutch_Flag = touchesPrevious;
		if(crutch_Flag) {
			crutch_Flag = !entering;
		}
		if (!crutch_Flag) {
			oo << this->position();
		}
	}
	if (!entering) {
		oo << "]";
	}
}
/* creation */


AfterReal::AfterReal (APTR(RealPos) pos, TCSJ) 
	: RealEdge(pos, tcsj) {
	
}



/* ************************************************************************ *
 * 
 *                    Class   BeforeReal 
 *
 * ************************************************************************ */


/* create */


RPTR(RealEdge) BeforeReal::make (APTR(RealPos) pos){
	RETURN_CONSTRUCT(BeforeReal,(pos, tcsj));
}
/* printing */


void BeforeReal::printTransitionOn (
		ostream& oo, 
		BooleanVar entering, 
		BooleanVar touchesPrevious)
{
	oo << " ";
	if (entering) {
		oo << "[";
	}
	{	BooleanVar crutch_Flag;
		/* touchesPrevious && !entering */
		
		crutch_Flag = touchesPrevious;
		if(crutch_Flag) {
			crutch_Flag = !entering;
		}
		if (!crutch_Flag) {
			oo << this->position();
		}
	}
	if (!entering) {
		oo << ")";
	}
}
/* comparing */


BooleanVar BeforeReal::follows (APTR(Position) pos){
	return !CAST(RealPos,pos)->isGE(this->position());
}


BooleanVar BeforeReal::isEqual (APTR(Heaper) other){
	BEGIN_CHOOSE(other) {
		BEGIN_KIND(BeforeReal,after) {
			return this->position()->isEqual(after->position());
		} END_KIND;
		BEGIN_OTHERS {
			return FALSE;
		} END_OTHERS;
	} END_CHOOSE;
	/* fodder */
	return FALSE;
}


BooleanVar BeforeReal::isFollowedBy (APTR(TransitionEdge) next){
	BEGIN_CHOOSE(next) {
		BEGIN_KIND(AfterReal,after) {
			return this->position()->isEqual(after->position());
		} END_KIND;
		BEGIN_OTHERS {
			return FALSE;
		} END_OTHERS;
	} END_CHOOSE;
	/* fodder */
	return FALSE;
}


BooleanVar BeforeReal::isGE (APTR(TransitionEdge) other){
	BEGIN_CHOOSE(other) {
		BEGIN_KIND(BeforeReal,before) {
			return this->position()->isGE(before->position());
		} END_KIND;
		BEGIN_KIND(AfterReal,after) {
			return !after->position()->isGE(this->position());
		} END_KIND;
	} END_CHOOSE;
	/* fodder */
	return FALSE;
}
/* creation */


BeforeReal::BeforeReal (APTR(RealPos) pos, TCSJ) 
	: RealEdge(pos, tcsj) {
	
}



/* ************************************************************************ *
 * 
 *                    Class RealManager 
 *
 * ************************************************************************ */


/* protected: */


RPTR(Position) RealManager::edgePosition (APTR(TransitionEdge) edge){
	WPTR(Position) 	returnValue;
	returnValue = CAST(RealEdge,edge)->position();
	return returnValue;
}


RPTR(XnRegion) RealManager::makeNew (BooleanVar startsInside, APTR(PtrArray) OF1(TransitionEdge) transitions){
	WPTR(XnRegion) 	returnValue;
	returnValue = RealRegion::make (startsInside, transitions);
	return returnValue;
}


RPTR(XnRegion) RealManager::makeNew (
		BooleanVar startsInside, 
		APTR(PtrArray) OF1(TransitionEdge) transitions, 
		Int32 count)
{
	WPTR(XnRegion) 	returnValue;
	returnValue = this->makeNew(startsInside, CAST(PtrArray,transitions->copy(count)));
	return returnValue;
}


RPTR(PtrArray) OF1(TransitionEdge) RealManager::posTransitions (APTR(Position) pos){
	BLAST(NOT_YET_IMPLEMENTED);
	/* fodder */
	return NULL;
}


BooleanVar RealManager::startsInside (APTR(XnRegion) region){
	return CAST(RealRegion,region)->startsInside();
}


RPTR(PtrArray) OF1(TransitionEdge) RealManager::transitions (APTR(XnRegion) region){
	WPTR(PtrArray) OF1(TransitionEdge) 	returnValue;
	returnValue = CAST(RealRegion,region)->secretTransitions();
	return returnValue;
}

	/* automatic 0-argument constructor */
RealManager::RealManager() {}



/* ************************************************************************ *
 * 
 *                    Class RealStepper 
 *
 * ************************************************************************ */


/* operations */


WPTR(Heaper) RealStepper::fetch (){
	/* If I am exhausted (i.e., if (! this->hasValue())), then 
	return NULL. Else return 
		current element.  I return wimpily since most items returned 
	are held by collections.
		If I create a new object, I should cache it. */
	
	BLAST(NOT_YET_IMPLEMENTED);
	/* fodder */
	return NULL;
}


BooleanVar RealStepper::hasValue (){
	/* Iff I have a current value (i.e. this message returns 
	true), then I am not 
		exhasted. 'fetch' and 'get' will both return this value, and 
	I can be 'step'ped to 
		my next state. As I am stepped, eventually I may become 
	exhausted (the 
		reverse of all the above), which is a permanent condition. 
		
		Note that not all steppers have to be exhaustable. A Stepper which 
		enumerates all primes is perfectly reasonable. Assuming 
	otherwise will create 
		infinite loops.  See class comment. */
	
	BLAST(NOT_YET_IMPLEMENTED);
	/* fodder */
	return FALSE;
}


void RealStepper::step (){
	/* Essential.  If I am currently exhausted (see 
	Stepper::hasValue()), then it is an error to step me. The 
	result of doing so isn't currently specified (we probably 
	should specify it to BLAST, but I know that the 
	implementation doesn't currently live up to that spec). 
		
		If I am not exhausted, then this advances me to my next 
	state. If my current value (see Stepper::get()) was my final 
	value, then I am now exhausted, otherwise my new current 
	value is the next value. */
	
	BLAST(NOT_YET_IMPLEMENTED);
}
/* create */


RPTR(Stepper) RealStepper::copy (){
	/* Return a new stepper which steps independently of me, but 
	whose current 
		value is the same as mine, and which must produce a future 
	history of values 
		which satisfies the same obligation that my contract 
	obligates me to produce 
		now. Typically, this will mean that he must produce the same 
	future history 
		that I'm going to produce. However, let's say that I am 
	enumerating the 
		elements of a partial order in some full order which is 
	consistent with the 
		partial order. If a copy of me is made after I'm part way 
	through, then me 
		and my copy may produce any future history compatable both 
	with the partial 
		order and the elements I've already produced by the time of 
	the copy. Of 
		course, a subclass or a Stepper creating message (like 
		IntegerRegion::stepper()) may specify the more stringent 
	requirement (that a 
		copy must produce the same sequence). 
		
		To prevent aliasing, Steppers should typically be passed by 
	copy. See class 
		comment. */
	
	BLAST(NOT_YET_IMPLEMENTED);
	/* fodder */
	return NULL;
}


RealStepper::RealStepper (APTR(PtrArray) transitions, TCSJ) {
	
}



/* ************************************************************************ *
 * 
 *                    Class RealUpOrder 
 *
 * ************************************************************************ */


/* creation */


RPTR(OrderSpec) RealUpOrder::make (){
	RETURN_CONSTRUCT(RealUpOrder,());
}
/* accessing */


RPTR(Arrangement) RealUpOrder::arrange (APTR(XnRegion) region){
	SPTR(Stepper) stepper;
	SPTR(PtrArray) array;
	
	if (!region->isFinite()) {
		BLAST(MustBeFinite);
	}
	stepper = CAST(RealRegion,region)->stepper();
	array = CAST(PtrArray,stepper->stepMany());
	if (!stepper->atEnd()) {
		BLAST(NOT_YET_IMPLEMENTED);
	}
	WPTR(Arrangement) 	returnValue;
	returnValue = ExplicitArrangement::make (array);
	return returnValue;
}


RPTR(CoordinateSpace) RealUpOrder::coordinateSpace (){
	WPTR(CoordinateSpace) 	returnValue;
	returnValue = RealSpace::make ();
	return returnValue;
}
/* testing */


UInt32 RealUpOrder::actualHashForEqual (){
	return cat_RealUpOrder->hashForEqual() + 1;
}


BooleanVar RealUpOrder::follows (APTR(Position) x, APTR(Position) y){
	/* MarkM -- Thing to do !!!! */
	
	/* 128 bit values */
	return CAST(RealPos,x)->asIEEE64() >= CAST(RealPos,y)->asIEEE64();
}


BooleanVar RealUpOrder::isEqual (APTR(Heaper) other){
	return other->isKindOf(cat_RealUpOrder);
}


BooleanVar RealUpOrder::isFullOrder (APTR(XnRegion) keys/* = NULL*/){
	return TRUE;
}


BooleanVar RealUpOrder::preceeds (APTR(XnRegion) before, APTR(XnRegion) after){
	BEGIN_CHOOSE(before) {
		BEGIN_KIND(RealRegion,br) {
			if (!br->isBoundedBelow()) {
				return TRUE;
			}
			BEGIN_CHOOSE(after) {
				BEGIN_KIND(RealRegion,ar) {
					{	BooleanVar crutch_Flag;
						/* !ar->isBoundedBelow() && this->follows(ar->lowerBound(), br->lowerBound()) */
						
						crutch_Flag = !ar->isBoundedBelow();
						if(crutch_Flag) {
							crutch_Flag = this->follows(ar->lowerBound(), br->lowerBound());
						}
						return crutch_Flag;
					}
				} END_KIND;
			} END_CHOOSE;
		} END_KIND;
	} END_CHOOSE;
	/* fodder */
	return FALSE;
}

	/* automatic 0-argument constructor */
RealUpOrder::RealUpOrder() {}

#ifndef REALX_SXX
#include "realx.sxx"
#endif /* REALX_SXX */


#ifndef REALP_SXX
#include "realp.sxx"
#endif /* REALP_SXX */



#endif /* REALX_CXX */

