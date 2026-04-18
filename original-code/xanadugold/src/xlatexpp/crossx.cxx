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

#ifndef CROSSX_CXX
#define CROSSX_CXX


#ifndef CHOOSEX_HXX
#include "choosex.hxx"
#endif /* CHOOSEX_HXX */

#ifndef CROSSX_HXX
#include "crossx.hxx"
#endif /* CROSSX_HXX */

#ifndef CROSSX_IXX
#include "crossx.ixx"
#endif /* CROSSX_IXX */

#ifndef CROSSP_HXX
#include "crossp.hxx"
#endif /* CROSSP_HXX */

#ifndef CROSSP_IXX
#include "crossp.ixx"
#endif /* CROSSP_IXX */


#ifndef NXCVRX_HXX
#include "nxcvrx.hxx"
#endif /* NXCVRX_HXX */

#ifndef PRIMVALX_HXX
#include "primvalx.hxx"
#endif /* PRIMVALX_HXX */

#ifndef SETX_HXX
#include "setx.hxx"
#endif /* SETX_HXX */

#ifndef XFRSPECX_HXX
#include "xfrspecx.hxx"
#endif /* XFRSPECX_HXX */




/* ************************************************************************ *
 * 
 *                    Class CrossMapping 
 *
 * ************************************************************************ */


/* pseudoconstructors */


RPTR(CrossMapping) CrossMapping::make (APTR(CrossSpace) space, APTR(PtrArray) OF1(Dsp OR(NULL)) subDsps/* = NULL*/){
	SPTR(PtrArray) OF1(Dsp) subDs;
	
	subDs = PtrArray::nulls(space->axisCount());
	{
		Int32 LoopFinal = subDs->count();
		Int32 i = Int32Zero;
		for (;;) {
			if (i >= LoopFinal){
				break;
			}
			{
				subDs->store(i, space->axis(i)->identityDsp());
			}
			i += 1;
		}
	}
	if (subDsps != NULL) {
		{
			Int32 LoopFinal = subDs->count();
			Int32 i = Int32Zero;
			for (;;) {
				if (i >= LoopFinal){
					break;
				}
				{
					SPTR(Dsp) OR(NULL) subDsp;
					
					if ((subDsp = CAST(Dsp,subDsps->fetch(i))) != NULL) {
						subDs->store(i, subDsp);
					}
				}
				i += 1;
			}
		}
	}
	RETURN_CONSTRUCT(GenericCrossDsp,(space, subDs));
}
/* All other crossed mappings must be gotten by factoring the non-dsp 
aspects out into the generic non-dsp mapping objects.  This class 
represents what remains after the factoring. */


/* transforming */
/* combining */
/* accessing */

	/* automatic 0-argument constructor */
CrossMapping::CrossMapping() {}



/* ************************************************************************ *
 * 
 *                    Class CrossOrderSpec 
 *
 * ************************************************************************ */


/* pseudoconstructors */


RPTR(CrossOrderSpec) CrossOrderSpec::make (
		APTR(CrossSpace) space, 
		APTR(PtrArray) OF1(OrderSpec OR(NULL)) subOrderings/* = NULL*/, 
		APTR(PrimIntArray) lexOrder/* = NULL*/)
{
	SPTR(PrimIntArray) lexO;
	SPTR(PtrArray) OF1(OrderSpec) subOrders;
	
	subOrders = PtrArray::nulls(space->axisCount());
	{
		Int32 LoopFinal = subOrders->count();
		Int32 i = Int32Zero;
		for (;;) {
			if (i >= LoopFinal){
				break;
			}
			{
				subOrders->store(i, space->axis(i)->fetchAscending());
			}
			i += 1;
		}
	}
	if (subOrderings != NULL) {
		{
			Int32 LoopFinal = subOrders->count();
			Int32 i = Int32Zero;
			for (;;) {
				if (i >= LoopFinal){
					break;
				}
				{
					SPTR(OrderSpec) OR(NULL) subOrder;
					
					subOrder = CAST(OrderSpec,subOrderings->fetch(i));
					if (subOrder == NULL) {
						if ( ! (subOrders->fetch(i) != NULL) ) {
							BLAST(Must_have_an_ordering_from_each_space);
						}
					} else {
						subOrders->store(i, subOrder);
					}
				}
				i += 1;
			}
		}
	}
	if (lexOrder == NULL) {
		lexO = PrimIntArray::zeros(32, subOrders->count());
		{
			Int32 LoopFinal = subOrders->count();
			Int32 i = Int32Zero;
			for (;;) {
				if (i >= LoopFinal){
					break;
				}
				{
					lexO->storeInteger(i, i);
				}
				i += 1;
			}
		}
	} else {
		lexO = lexOrder;
	}
	RETURN_CONSTRUCT(CrossOrderSpec,(space, subOrders, lexO));
}
/* private: pseudo constructors */


RPTR(CrossOrderSpec) CrossOrderSpec::fetchAscending (APTR(GenericCrossSpace) space, APTR(PtrArray) OF1(CoordinateSpace) subSpaces){
	/* Only used during construction; must pass the array in 
	explicitly since the space isnt initialized yet */
	
	SPTR(PtrArray) OF1(OrderSpec) result;
	SPTR(PrimIntArray) lex;
	
	result = PtrArray::nulls(subSpaces->count());
	lex = PrimIntArray::zeros(32, subSpaces->count());
	{
		Int32 LoopFinal = result->count();
		Int32 dimension = Int32Zero;
		for (;;) {
			if (dimension >= LoopFinal){
				break;
			}
			{
				SPTR(OrderSpec) sub;
				
				sub = CAST(CoordinateSpace,subSpaces->fetch(dimension))->fetchAscending();
				if (sub == NULL) {
					return NULL;
				}
				result->store(dimension, sub);
				lex->storeInteger(dimension, dimension);
			}
			dimension += 1;
		}
	}
	RETURN_CONSTRUCT(CrossOrderSpec,(space, result, lex));
}


RPTR(CrossOrderSpec) CrossOrderSpec::fetchDescending (APTR(GenericCrossSpace) space, APTR(PtrArray) OF1(CoordinateSpace) subSpaces){
	/* Only used during construction; must pass the array in 
	explicitly since the space isnt initialized yet */
	
	SPTR(PtrArray) OF1(OrderSpec) result;
	SPTR(PrimIntArray) lex;
	
	result = PtrArray::nulls(subSpaces->count());
	lex = PrimIntArray::zeros(32, subSpaces->count());
	{
		Int32 LoopFinal = result->count();
		Int32 dimension = Int32Zero;
		for (;;) {
			if (dimension >= LoopFinal){
				break;
			}
			{
				SPTR(OrderSpec) sub;
				
				sub = CAST(CoordinateSpace,subSpaces->fetch(dimension))->fetchAscending();
				if (sub == NULL) {
					return NULL;
				}
				result->store(dimension, sub);
				lex->storeInteger(dimension, dimension);
			}
			dimension += 1;
		}
	}
	RETURN_CONSTRUCT(CrossOrderSpec,(space, result, lex));
}
/* myLexOrder lists the lexicographic order in which each dimension 
should be processed.  Every dimension should be listed exactly one, 
from most significant (at index 0) to least significant.

mySubOrders are indexed by *dimension*, not by lexicographic order.  
In order to index by lex order, look up the dimension in myLexOrder, 
and then look up the resulting dimension number in mySubOrders. */


/* private: creation */


CrossOrderSpec::CrossOrderSpec (
		APTR(CrossSpace) space, 
		APTR(PtrArray) OF1(OrderSpec) subOrders, 
		APTR(PrimIntArray) lexOrder) 
{
	mySpace = space;
	mySubOrders = subOrders;
	myLexOrder = lexOrder;
}
/* accessing */


RPTR(PrimIntArray) CrossOrderSpec::lexOrder (){
	/* Lists the lexicographic order in which each dimension 
	should be processed.  Every dimension is listed exactly once, 
	from most significant (at index 0) to least significant. */
	
	return CAST(PrimIntArray,myLexOrder->copy());
}


RPTR(OrderSpec) CrossOrderSpec::subOrder (Int32 i){
	/* The sub OrderSpec used for the given axis. Note that this 
	is *not* in lex order. */
	
	return CAST(OrderSpec,mySubOrders->fetch(i));
}


RPTR(PtrArray) OF1(OrderSpec) CrossOrderSpec::subOrders (){
	/* The sub OrderSpec used for each axis in the space. Note 
	that this is *not* in lex order, but rather indexed by axis number. */
	
	return CAST(PtrArray,mySubOrders->copy());
}
/* testing */


UInt32 CrossOrderSpec::actualHashForEqual (){
	return mySpace->hashForEqual() ^ (mySubOrders->hashForEqual() ^ myLexOrder->hashForEqual());
}


BooleanVar CrossOrderSpec::follows (APTR(Position) /* x */, APTR(Position) /* y */){
	BLAST(NOT_YET_IMPLEMENTED);
	/* fodder */
	return FALSE;
}


BooleanVar CrossOrderSpec::isEqual (APTR(Heaper) /* other */){
	BLAST(NOT_YET_IMPLEMENTED);
	/* fodder */
	return FALSE;
}


BooleanVar CrossOrderSpec::isFullOrder (APTR(XnRegion) /* keys *//* = NULL*/){
	/* Essential.  If this returns TRUE, then I define a full 
	order over all positions in 'keys' (or all positions in the 
	space if 'keys' is NULL).  However, if I return FALSE, that 
	doesn't guarantee that I don't define a full ordering.  I may 
	happen to define a full ordering without knowing it.
		
		A full ordering is one in which for each a, b in keys; 
	either this->follows(a, b) or this->follows(b, a). */
	
	return FALSE;
}


BooleanVar CrossOrderSpec::preceeds (APTR(XnRegion) before, APTR(XnRegion) after){
	/* Return true if some position in before is less than or 
	equal to all positions in after. */
	
	BEGIN_CHOOSE(before) {
		BEGIN_KIND(GenericCrossRegion,bc) {
			BEGIN_CHOOSE(after) {
				BEGIN_KIND(GenericCrossRegion,ac) {
					{
						Int32 LoopFinal = myLexOrder->count();
						Int32 i = Int32Zero;
						for (;;) {
							if (i >= LoopFinal){
								break;
							}
							{
								Int32 dim;
								SPTR(OrderSpec) sub;
								
								dim = myLexOrder->integerAt(i).asLong();
								sub = CAST(OrderSpec,mySubOrders->get(dim));
								{
									Int32 LoopFinal = bc->boxCount();
									Int32 bi = Int32Zero;
									for (;;) {
										if (bi >= LoopFinal){
											break;
										}
										{
											SPTR(XnRegion) bp;
											
											bp = bc->boxProjection(bi, dim);
											{
												Int32 LoopFinal = ac->boxCount();
												Int32 ai = Int32Zero;
												for (;;) {
													if (ai >= LoopFinal){
														break;
													}
													{
														SPTR(XnRegion) ap;
														
														ap = ac->boxProjection(ai, dim);
														if (sub->preceeds(bp, ap)) {
															return TRUE;
														}
													}
													ai += 1;
												}
											}
										}
										bi += 1;
									}
								}
							}
							i += 1;
						}
					}
					return FALSE;
				} END_KIND;
				BEGIN_OTHERS {
					BLAST(NOT_YET_IMPLEMENTED);
				} END_OTHERS;
			} END_CHOOSE;
		} END_KIND;
		BEGIN_OTHERS {
			BLAST(NOT_YET_IMPLEMENTED);
		} END_OTHERS;
	} END_CHOOSE;
	/* fodder */
	return FALSE;
}



/* ************************************************************************ *
 * 
 *                    Class CrossRegion 
 *
 * ************************************************************************ */


/* A cross region is a distinction if 1) it is empty, 2) it is full, 
or 3) it is the rectangular cross of full regions and one 
distinction. Note that case 3 actually subsumes 1 and 2.  Since the 
simple regions of a space are the intersections of a finite number of 
distinctions of a space, this implies that A cross region is simple 
if it is the rectangular cross of simple regions.  In other words, a 
simple region is identical to the cross of its projections. */


/* testing */


UInt32 CrossRegion::actualHashForEqual (){
	/* To avoid overly burdensome canonicalization rules, my hash 
	is calculated from the hash of my projections */
	
	return cat_CrossRegion->hashForEqual() ^ this->projections()->contentsHash();
}
/* enumerating */
/* operations */


RPTR(XnRegion) CrossRegion::simpleUnion (APTR(XnRegion) other){
	WPTR(XnRegion) 	returnValue;
	returnValue = this->unionWith(other)->asSimpleRegion();
	return returnValue;
}
/* accessing */


RPTR(XnRegion) CrossRegion::projection (Int32 index){
	/* The answer is the projection of this region into the 
	specified dimension of the cross space */
	
	return CAST(XnRegion,this->projections()->fetch(index));
}
/* protected: enumerating */

	/* automatic 0-argument constructor */
CrossRegion::CrossRegion() {}



/* ************************************************************************ *
 * 
 *                    Class CrossSpace 
 *
 * ************************************************************************ */


/* creation */


RPTR(CrossSpace) CrossSpace::make (APTR(PtrArray) OF1(CoordinateSpace) subSpaces){
	/* Make a cross space with the given list of subspaces */
	/* Should use middlemen.  Just hard code special cases for now */
	
	WPTR(CrossSpace) 	returnValue;
	returnValue = GenericCrossSpace::make (CAST(PtrArray,subSpaces->copy()));
	return returnValue;
}


RPTR(CrossSpace) CrossSpace::make (APTR(CoordinateSpace) zeroSpace, APTR(CoordinateSpace) oneSpace){
	/* Cross two sub spaces */
	
	RETURN_CONSTRUCT(GenericCrossSpace,(CAST(PtrArray,PrimSpec::pointer()->arrayWithTwo(zeroSpace, oneSpace)), tcsj));
}
/* Represents the cross of several coordinate spaces.   */


/* accessing */


RPTR(PtrArray) OF1(CoordinateSpace) CrossSpace::axes (){
	/* Essential.  The base spaces that I am a cross of. */
	
	return CAST(PtrArray,mySubSpaces->copy());
}


RPTR(CoordinateSpace) CrossSpace::axis (Int32 dimension){
	/* The sub coordinate space on the given axis */
	
	return CAST(CoordinateSpace,mySubSpaces->fetch(dimension));
}
/* testing */


UInt32 CrossSpace::actualHashForEqual (){
	return mySubSpaces->contentsHash() ^ cat_CrossSpace->hashForEqual();
}


BooleanVar CrossSpace::isEqual (APTR(Heaper) other){
	BEGIN_CHOOSE(other) {
		BEGIN_KIND(CrossSpace,cross) {
			return cross->secretSubSpaces()->contentsEqual(mySubSpaces);
		} END_KIND;
		BEGIN_OTHERS {
			return FALSE;
		} END_OTHERS;
	} END_CHOOSE;
	/* compiler fodder */
	return FALSE;
}
/* making */
/* protected: accessing */
/* protected: creation */


CrossSpace::CrossSpace () {
	mySubSpaces = NULL;
}


CrossSpace::CrossSpace (APTR(PtrArray) OF1(CoordinateSpace) subSpaces, TCSJ) {
	mySubSpaces = subSpaces;
}



/* ************************************************************************ *
 * 
 *                    Class Tuple 
 *
 * ************************************************************************ */


/* pseudoconstructors */


RPTR(Tuple) Tuple::make (APTR(PtrArray) OF1(Position) coordinates){
	WPTR(Tuple) 	returnValue;
	returnValue = ActualTuple::make (CAST(PtrArray,coordinates->copy()));
	return returnValue;
}


RPTR(Tuple) Tuple::two (APTR(Position) zero, APTR(Position) one){
	WPTR(Tuple) 	returnValue;
	returnValue = ActualTuple::make (CAST(PtrArray,PrimSpec::pointer()->arrayWithTwo(zero, one)));
	return returnValue;
}
/* A tuple is a Position in a CrossSpace represented by a sequence of 
Positions in its subSpaces */


/* printing */


void Tuple::printOn (ostream& oo){
	this->printOnWithSimpleSyntax(oo, "<", ", ", ">");
}


void Tuple::printOnWithSimpleSyntax (
		ostream& oo, 
		char * openString, 
		char * sep, 
		char * closeString)
{
	SPTR(PtrArray) OF1(Position) coords;
	
	oo << openString;
	coords = this->coordinates();
	{
		Int32 LoopFinal = coords->count();
		Int32 i = Int32Zero;
		for (;;) {
			if (i >= LoopFinal){
				break;
			}
			{
				if (i > Int32Zero) {
					oo << sep;
				}
				coords->fetch(i)->printOn(oo);
			}
			i += 1;
		}
	}
	oo << closeString;
}
/* accessing */


RPTR(Position) Tuple::coordinate (Int32 index){
	/* The position with in a subspace */
	
	return CAST(Position,this->coordinates()->fetch(index));
}
/* testing */


UInt32 Tuple::actualHashForEqual (){
	return Heaper::takeOop();
}

	/* automatic 0-argument constructor */
Tuple::Tuple() {}



/* ************************************************************************ *
 * 
 *                    Class ActualTuple 
 *
 * ************************************************************************ */


/* pseudoconstructors */


RPTR(Tuple) ActualTuple::make (APTR(PtrArray) OF1(Position) coordinates){
	RETURN_CONSTRUCT(ActualTuple,(coordinates, tcsj));
}
/* Default implementation of position in a crossed coordinate space. 
NOT.A.TYPE */


/* accessing */


RPTR(XnRegion) ActualTuple::asRegion (){
	SPTR(PtrArray) OF1(XnRegion) result;
	
	result = PtrArray::nulls(myCoordinates->count());
	{
		Int32 LoopFinal = result->count();
		Int32 i = Int32Zero;
		for (;;) {
			if (i >= LoopFinal){
				break;
			}
			{
				result->store(i, this->coordinate(i)->asRegion());
			}
			i += 1;
		}
	}
	WPTR(XnRegion) 	returnValue;
	returnValue = GenericCrossRegion::make (CAST(CrossSpace,this->coordinateSpace()), 1, result);
	return returnValue;
}


RPTR(PtrArray) OF1(Position) ActualTuple::coordinates (){
	return CAST(PtrArray,myCoordinates->copy());
}


RPTR(CoordinateSpace) ActualTuple::coordinateSpace (){
	SPTR(PtrArray) OF1(CoordinateSpace) result;
	
	result = PtrArray::nulls(myCoordinates->count());
	{
		Int32 LoopFinal = result->count();
		Int32 i = Int32Zero;
		for (;;) {
			if (i >= LoopFinal){
				break;
			}
			{
				result->store(i, this->coordinate(i)->coordinateSpace());
			}
			i += 1;
		}
	}
	WPTR(CoordinateSpace) 	returnValue;
	returnValue = CrossSpace::make (result);
	return returnValue;
}


Int32 ActualTuple::count (){
	return myCoordinates->count();
}


RPTR(Position) ActualTuple::positionAt (Int32 dimension){
	return CAST(Position,myCoordinates->fetch(dimension));
}
/* comparing */


UInt32 ActualTuple::actualHashForEqual (){
	return myCoordinates->contentsHash();
}


BooleanVar ActualTuple::isEqual (APTR(Heaper) other){
	BEGIN_CHOOSE(other) {
		BEGIN_KIND(ActualTuple,actual) {
			return myCoordinates->contentsEqual(actual->secretCoordinates());
		} END_KIND;
		BEGIN_KIND(Tuple,tuple) {
			return myCoordinates->contentsEqual(tuple->coordinates());
		} END_KIND;
		BEGIN_OTHERS {
			return FALSE;
		} END_OTHERS;
	} END_CHOOSE;
	/* compiler fodder */
	return FALSE;
}
/* private: creation */


ActualTuple::ActualTuple (APTR(PtrArray) OF1(Position) coordinates, TCSJ) {
	myCoordinates = coordinates;
}
/* private: accessing */


RPTR(PtrArray) OF1(Position) ActualTuple::secretCoordinates (){
	/* The internal array of coordinates. Do not modify this array! */
	
	return (PtrArray*) myCoordinates;
}



/* ************************************************************************ *
 * 
 *                    Class BoxAccumulator 
 *
 * ************************************************************************ */



/* Initializers for BoxAccumulator */

GPTR(InstanceCache) BoxAccumulator::SomeAccumulators = NULL;



BEGIN_INIT_TIME(BoxAccumulator,initTimeNonInherited) {
	BoxAccumulator::SomeAccumulators = InstanceCache::make (8);
} END_INIT_TIME(BoxAccumulator,initTimeNonInherited);



/* Initializers for BoxAccumulator */






/* creation */


RPTR(BoxAccumulator) BoxAccumulator::make (APTR(GenericCrossRegion) region){
	SPTR(Heaper) result;
	
	result = BoxAccumulator::SomeAccumulators->fetch();
	if (result == NULL) {
		RETURN_CONSTRUCT(BoxAccumulator,(region, tcsj));
	} else {
		WPTR(BoxAccumulator) 	returnValue;
		returnValue = new (result) BoxAccumulator(region, tcsj);
		return returnValue;
	}
}


RPTR(BoxAccumulator) BoxAccumulator::make (APTR(CrossSpace) space, Int32 expectedBoxCount){
	SPTR(Heaper) result;
	
	result = BoxAccumulator::SomeAccumulators->fetch();
	if (result == NULL) {
		RETURN_CONSTRUCT(BoxAccumulator,(space, expectedBoxCount));
	} else {
		WPTR(BoxAccumulator) 	returnValue;
		returnValue = new (result) BoxAccumulator(space, expectedBoxCount);
		return returnValue;
	}
}
/* was NOT.A.TYPE but this prevented compilation  */


/* creation */


RPTR(Accumulator) BoxAccumulator::copy (){
	SPTR(Heaper) result;
	
	result = BoxAccumulator::SomeAccumulators->fetch();
	if (result == NULL) {
		RETURN_CONSTRUCT(BoxAccumulator,(mySpace, CAST(PtrArray,myRegions->copy()), myIndex));
	} else {
		WPTR(Accumulator) 	returnValue;
		returnValue = new (result) BoxAccumulator(mySpace, CAST(PtrArray,myRegions->copy()), myIndex);
		return returnValue;
	}
}
/* protected: creation */


BoxAccumulator::BoxAccumulator (APTR(GenericCrossRegion) region, TCSJ) {
	mySpace = region->crossSpace();
	myRegions = CAST(PtrArray,region->secretRegions()->copy());
	myIndex = region->boxCount();
}


BoxAccumulator::BoxAccumulator (APTR(CrossSpace) space, Int32 expectedBoxCount) {
	mySpace = space;
	myRegions = PtrArray::nulls(space->axisCount() * expectedBoxCount);
	myIndex = Int32Zero;
}


BoxAccumulator::BoxAccumulator (
		APTR(CrossSpace) space, 
		APTR(PtrArray) OF1(XnRegion) /* regions */, 
		Int32 expectedBoxCount) 
{
	mySpace = space;
	myRegions = PtrArray::nulls(space->axisCount() * expectedBoxCount);
	myIndex = Int32Zero;
	/* shouldn't we be doing something with the 'regios' argument? */
	BLAST(NOT_YET_IMPLEMENTED);
}
/* private: */


void BoxAccumulator::aboutToAdd (){
	/* Make sure there is room to add a box */
	
	if (!(myIndex * mySpace->axisCount() < myRegions->count())) {
		myRegions = CAST(PtrArray,myRegions->copyGrow((myIndex + 1) * mySpace->axisCount()));
	}
}


Int32 BoxAccumulator::addSubstitutedBox (
		Int32 current, 
		Int32 dimension, 
		APTR(XnRegion) newRegion)
{
	/* Add a new box which is just like a current one except for 
	the projection on one dimension. Return its index */
	
	this->aboutToAdd();
	myRegions->storeMany(myIndex * mySpace->axisCount(), myRegions, mySpace->axisCount(), current * mySpace->axisCount());
	myRegions->store(myIndex * mySpace->axisCount() + dimension, newRegion);
	myIndex += 1;
	return myIndex - 1;
}


Int32 BoxAccumulator::boxCount (){
	/* Known bug !!!! */
	
	/* includes deleted boxes */
	return myIndex;
}


RPTR(XnRegion) BoxAccumulator::boxProjection (Int32 box, Int32 dimension){
	/* Change a projection of a box */
	
	return CAST(XnRegion,myRegions->fetch(box * mySpace->axisCount() + dimension));
}


void BoxAccumulator::deleteBox (Int32 box){
	/* Mark a box as deleted */
	
	myRegions->store(box * mySpace->axisCount(), NULL);
}


BooleanVar BoxAccumulator::distributeUnion (
		Int32 added, 
		Int32 start, 
		Int32 stop)
{
	/* Take my box at added
			and distribute it over my existing boxes from start to stop - 1
			meanwhile taking pieces out of my box at remainder
				and delete it if it becomes empty
		Return true if there is still something left in the remainder */
	
	{
		Int32 LoopFinal = stop;
		Int32 index = start;
		for (;;) {
			if (index >= LoopFinal){
				break;
			}
			{
				if (!this->splitUnion(added, index, stop)) {
					return FALSE;
				}
			}
			index += 1;
		}
	}
	return TRUE;
}


Int32 BoxAccumulator::index (){
	return myIndex;
}


BooleanVar BoxAccumulator::isDeleted (Int32 box){
	/* Whether the box has been deleted */
	
	return myRegions->fetch(box * mySpace->axisCount()) == NULL;
}


RPTR(PtrArray) OF1(XnRegion) BoxAccumulator::secretRegions (){
	return (PtrArray*) myRegions;
}


BooleanVar BoxAccumulator::splitUnion (
		Int32 added, 
		Int32 current, 
		Int32 stop)
{
	/* Take my box at added
			and union it with my box at current
			delete it if it becomes empty
		Return true if there is still something left in the added box */
	
	Int32 dimension;
	SPTR(XnRegion) addedRegion;
	SPTR(XnRegion) currentRegion;
	SPTR(XnRegion) common;
	Int32 newAdded;
	SPTR(XnRegion) extraCurrent;
	SPTR(XnRegion) extraAdded;
	
	if (this->isDeleted(current)) {
		return TRUE;
	}
	dimension = Int32Zero;
	/* see if the added intersects the current in this dimension */
	while (dimension + 1 < mySpace->axisCount()) {
		addedRegion = this->boxProjection(added, dimension);
		currentRegion = this->boxProjection(current, dimension);
		/* Thing to do !!!! */
		
		/* Add protocol for tri-delta: gives triple (a-b, a&b, b-a) */
		common = addedRegion->intersect(currentRegion);
		if (common->isEmpty()) {
			return TRUE;
		}
		/* split out the part of current that doesn't intersect */
		extraCurrent = currentRegion->minus(common);
		if (!extraCurrent->isEmpty()) {
			this->addSubstitutedBox(current, dimension, extraCurrent);
			this->storeBoxProjection(current, dimension, common);
		}
		/* split out the part of the added that doesn't intersect */
		extraAdded = addedRegion->minus(common);
		if (!extraAdded->isEmpty()) {
			newAdded = 
					this->addSubstitutedBox(added, dimension, extraAdded);
			this->distributeUnion(newAdded, current + 1, stop);
			this->storeBoxProjection(added, dimension, common);
		}
		dimension += 1;
	}
	/* union the added into the last dimension of the current box */
	addedRegion = this->boxProjection(added, dimension);
	currentRegion = this->boxProjection(current, dimension);
	this->storeBoxProjection(current, dimension, currentRegion->unionWith(addedRegion));
	this->deleteBox(added);
	return FALSE;
}


void BoxAccumulator::storeBoxProjection (
		Int32 box, 
		Int32 dimension, 
		APTR(XnRegion) region)
{
	/* Change a projection of a box */
	
	myRegions->store(box * mySpace->axisCount() + dimension, region);
}


void BoxAccumulator::tryMergeBoxes (Int32 i, Int32 j){
	/* If two boxes differ by only one projection, union the 
	second into the first and delete the second */
	
	Int32 unequal;
	
	unequal = -1;
	{
		Int32 LoopFinal = mySpace->axisCount();
		Int32 dim = Int32Zero;
		for (;;) {
			if (dim >= LoopFinal){
				break;
			}
			{
				if (!this->boxProjection(i, dim)->isEqual(this->boxProjection(j, dim))) {
					if (unequal >= Int32Zero) {
						return;
						
					}
					unequal = dim;
				}
			}
			dim += 1;
		}
	}
	this->storeBoxProjection(i, unequal, this->boxProjection(i, unequal)->unionWith(this->boxProjection(j, unequal)));
	this->deleteBox(j);
}
/* operations */


void BoxAccumulator::addAccumulatedBoxes (APTR(BoxAccumulator) other){
	/* Add in all the boxes in another accumulator */
	
	{
		Int32 LoopFinal = other->index();
		Int32 box = Int32Zero;
		for (;;) {
			if (box >= LoopFinal){
				break;
			}
			{
				if (!other->isDeleted(box)) {
					this->aboutToAdd();
					myRegions->storeMany(myIndex * mySpace->axisCount(), other->secretRegions(), mySpace->axisCount(), box * mySpace->axisCount());
					myIndex += 1;
				}
			}
			box += 1;
		}
	}
}


Int32 BoxAccumulator::addBox (APTR(BoxStepper) box){
	/* Add the current box to the end of the array */
	
	return this->addProjections(box->region()->secretRegions(), box->boxIndex());
}


void BoxAccumulator::addInverseTransformedBox (APTR(BoxStepper) box, APTR(GenericCrossDsp) dsp){
	/* Add the current box, transformed by the inverse of the dsp */
	
	Int32 base;
	
	this->aboutToAdd();
	base = mySpace->axisCount() * myIndex;
	{
		Int32 LoopFinal = mySpace->axisCount();
		Int32 dimension = Int32Zero;
		for (;;) {
			if (dimension >= LoopFinal){
				break;
			}
			{
				myRegions->store(base + dimension, dsp->subMapping(dimension)->inverseOfAll(box->projection(dimension)));
			}
			dimension += 1;
		}
	}
	myIndex += 1;
}


Int32 BoxAccumulator::addProjections (APTR(PtrArray) OF1(XnRegion) projections, Int32 boxIndex){
	/* Add a box to the end of the array */
	
	this->aboutToAdd();
	myRegions->storeMany(myIndex * mySpace->axisCount(), projections, mySpace->axisCount(), boxIndex * mySpace->axisCount());
	myIndex += 1;
	return myIndex - 1;
}


void BoxAccumulator::addTransformedBox (APTR(BoxStepper) box, APTR(GenericCrossDsp) dsp){
	/* Add the current box, transformed by the dsp */
	
	Int32 base;
	
	this->aboutToAdd();
	base = myIndex * mySpace->axisCount();
	{
		Int32 LoopFinal = mySpace->axisCount();
		Int32 dimension = Int32Zero;
		for (;;) {
			if (dimension >= LoopFinal){
				break;
			}
			{
				myRegions->store(base + dimension, dsp->subMapping(dimension)->ofAll(box->projection(dimension)));
			}
			dimension += 1;
		}
	}
	myIndex += 1;
}


void BoxAccumulator::intersectWithBox (APTR(BoxStepper) box){
	/* Intersect the current region with a box. May leave the 
	result uncanonicalized */
	
	{
		Int32 LoopFinal = myIndex;
		Int32 i = Int32Zero;
		for (;;) {
			if (i >= LoopFinal){
				break;
			}
			{
				if (!box->intersectBoxInto(myRegions, i)) {
					this->deleteBox(i);
				}
			}
			i += 1;
		}
	}
}


void BoxAccumulator::mergeBoxes (){
	/* merge boxes which differ in only one projection */
	
	/* Ravi -- Thing to do !!!! */
	
	/* hash lookup */
	{
		Int32 LoopFinal = myIndex;
		Int32 i = Int32Zero;
		for (;;) {
			if (i >= LoopFinal){
				break;
			}
			{
				if (!this->isDeleted(i)) {
					{
						Int32 LoopFinal = myIndex;
						Int32 j = Int32Zero;
						for (;;) {
							if (j >= LoopFinal){
								break;
							}
							{
								{	BooleanVar crutch_Flag;
									/* i == j || this->isDeleted(j) */
									
									crutch_Flag = i == j;
									if(!crutch_Flag) {
										crutch_Flag = this->isDeleted(j);
									}
									if (!crutch_Flag) {
										this->tryMergeBoxes(i, j);
									}
								}
							}
							j += 1;
						}
					}
				}
			}
			i += 1;
		}
	}
}


RPTR(XnRegion) BoxAccumulator::region (){
	/* The current region in the accumulator. CLIENT MUST KNOW 
	THAT IT IS CANONICAL */
	
	WPTR(XnRegion) 	returnValue;
	returnValue = GenericCrossRegion::make (mySpace, myIndex, CAST(PtrArray,myRegions->copy(myIndex * mySpace->axisCount())));
	return returnValue;
}


void BoxAccumulator::removeDeleted (){
	/* Remove boxes which have been deleted */
	
	Int32 to;
	Int32 from;
	
	from = to = Int32Zero;
	while (from < myIndex) {
		if (!this->isDeleted(from)) {
			if (from > to) {
				myRegions->storeMany(to * mySpace->axisCount(), myRegions, mySpace->axisCount(), from * mySpace->axisCount());
			}
			to += 1;
		}
		from += 1;
	}
	myIndex = to;
}


void BoxAccumulator::step (APTR(Heaper) someObj){
	this->unionWithBoxes(CAST(GenericCrossRegion,someObj)->boxStepper());
}


void BoxAccumulator::unionWithBox (APTR(BoxStepper) box){
	/* Add the current box to the accumulator */
	
	Int32 initialIndex;
	Int32 addedIndex;
	
	initialIndex = myIndex;
	addedIndex = this->addBox(box);
	this->distributeUnion(addedIndex, Int32Zero, initialIndex);
}


void BoxAccumulator::unionWithBoxes (APTR(BoxStepper) boxes){
	/* Add a sequence of disjoint boxes to the accumulator */
	
	if (myIndex == Int32Zero) {
		while (boxes->hasValue()) {
			this->addBox(boxes);
			boxes->step();
		}
	} else {
		while (boxes->hasValue()) {
			this->unionWithBox(boxes);
			boxes->step();
		}
	}
}


RPTR(Heaper) BoxAccumulator::value (){
	WPTR(Heaper) 	returnValue;
	returnValue = this->region();
	return returnValue;
}



/* ************************************************************************ *
 * 
 *                    Class BoxProjectionStepper 
 *
 * ************************************************************************ */



/* Initializers for BoxProjectionStepper */

GPTR(InstanceCache) BoxProjectionStepper::SomeSteppers = NULL;



BEGIN_INIT_TIME(BoxProjectionStepper,initTimeNonInherited) {
	BoxProjectionStepper::SomeSteppers = InstanceCache::make (8);
} END_INIT_TIME(BoxProjectionStepper,initTimeNonInherited);



/* Initializers for BoxProjectionStepper */






/* create */


RPTR(BoxProjectionStepper) BoxProjectionStepper::make (APTR(GenericCrossRegion) region){
	SPTR(Heaper) result;
	
	result = BoxProjectionStepper::SomeSteppers->fetch();
	if (result == NULL) {
		RETURN_CONSTRUCT(BoxProjectionStepper,(region, tcsj));
	} else {
		WPTR(BoxProjectionStepper) 	returnValue;
		returnValue = new (result) BoxProjectionStepper(region, tcsj);
		return returnValue;
	}
}


RPTR(BoxProjectionStepper) BoxProjectionStepper::make (
		APTR(GenericCrossRegion) region, 
		Int32 boxIndex, 
		Int32 boxLimit)
{
	SPTR(Heaper) result;
	
	result = BoxProjectionStepper::SomeSteppers->fetch();
	if (result == NULL) {
		RETURN_CONSTRUCT(BoxProjectionStepper,(region, boxIndex, boxLimit));
	} else {
		WPTR(BoxProjectionStepper) 	returnValue;
		returnValue = new (result) BoxProjectionStepper(region, boxIndex, boxLimit);
		return returnValue;
	}
}
/* Steps over all projections of some boxes. was not.a.type but this 
prevented compilation */


/* create */


RPTR(Stepper) BoxProjectionStepper::copy (){
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


void BoxProjectionStepper::destroy (){
	if (!BoxProjectionStepper::SomeSteppers->store(this)) {
		this->Stepper::destroy();
	}
}
/* protected: create */


BoxProjectionStepper::BoxProjectionStepper (APTR(GenericCrossRegion) region, TCSJ) {
	myRegion = region;
	myBoxIndex = Int32Zero;
	myBoxLimit = region->boxCount();
	myDimension = Int32Zero;
}


BoxProjectionStepper::BoxProjectionStepper (
		APTR(GenericCrossRegion) region, 
		Int32 boxIndex, 
		Int32 boxLimit) 
{
	myRegion = region;
	myBoxIndex = boxIndex;
	myBoxLimit = boxLimit;
	myDimension = Int32Zero;
}


BoxProjectionStepper::BoxProjectionStepper (
		APTR(GenericCrossRegion) region, 
		Int32 boxIndex, 
		Int32 boxLimit, 
		Int32 dimension) 
{
	myRegion = region;
	myBoxIndex = boxIndex;
	myBoxLimit = boxLimit;
	myDimension = dimension;
}
/* operations */


WPTR(Heaper) BoxProjectionStepper::fetch (){
	if (!(myBoxIndex < myBoxLimit)) {
		return NULL;
	}
	WPTR(Heaper) 	returnValue;
	returnValue = this->projection();
	return returnValue;
}


BooleanVar BoxProjectionStepper::hasValue (){
	return myBoxIndex < myBoxLimit;
}


void BoxProjectionStepper::step (){
	if (myBoxIndex < myBoxLimit) {
		myDimension += 1;
		if (!(myDimension < myRegion->crossSpace()->axisCount())) {
			myBoxIndex += 1;
			myDimension = Int32Zero;
		}
	}
}
/* accessing */


Int32 BoxProjectionStepper::dimension (){
	return myDimension;
}


RPTR(XnRegion) BoxProjectionStepper::projection (){
	WPTR(XnRegion) 	returnValue;
	returnValue = myRegion->boxProjection(myBoxIndex, myDimension);
	return returnValue;
}



/* ************************************************************************ *
 * 
 *                    Class BoxStepper 
 *
 * ************************************************************************ */



/* Initializers for BoxStepper */

GPTR(InstanceCache) BoxStepper::SomeSteppers = NULL;



BEGIN_INIT_TIME(BoxStepper,initTimeNonInherited) {
	BoxStepper::SomeSteppers = InstanceCache::make (8);
} END_INIT_TIME(BoxStepper,initTimeNonInherited);



/* Initializers for BoxStepper */






/* create */


RPTR(BoxStepper) BoxStepper::make (APTR(GenericCrossRegion) region){
	SPTR(Heaper) result;
	
	result = BoxStepper::SomeSteppers->fetch();
	if (result == NULL) {
		RETURN_CONSTRUCT(BoxStepper,(region, tcsj));
	} else {
		WPTR(BoxStepper) 	returnValue;
		returnValue = new (result) BoxStepper(region, tcsj);
		return returnValue;
	}
}
/* Steps over all boxes. was NOT.A.TYPE but this prevented compilation */


/* operations */


WPTR(Heaper) BoxStepper::fetch (){
	if (myIndex >= myRegion->boxCount()) {
		return NULL;
	}
	if (myValue == NULL) {
		myValue = 
				GenericCrossRegion::make (myRegion->crossSpace(), 1, CAST(PtrArray,myRegion->secretRegions()->copy(myRegion->crossSpace()->axisCount(), myIndex * myRegion->crossSpace()->axisCount())));
	}
	return (XnRegion*) myValue;
}


BooleanVar BoxStepper::hasValue (){
	return myIndex < myRegion->boxCount();
}


void BoxStepper::step (){
	if (myIndex < myRegion->boxCount()) {
		myIndex += 1;
		myValue = NULL;
	}
}
/* create */


RPTR(Stepper) BoxStepper::copy (){
	SPTR(Heaper) result;
	
	result = BoxStepper::SomeSteppers->fetch();
	if (result == NULL) {
		RETURN_CONSTRUCT(BoxStepper,(myRegion, myIndex, myValue));
	} else {
		WPTR(Stepper) 	returnValue;
		returnValue = new (result) BoxStepper(myRegion, myIndex, myValue);
		return returnValue;
	}
}


void BoxStepper::destroy (){
	if (!BoxStepper::SomeSteppers->store(this)) {
		this->Stepper::destroy();
	}
}
/* protected: create */


BoxStepper::BoxStepper (APTR(GenericCrossRegion) region, TCSJ) {
	myRegion = region;
	myIndex = Int32Zero;
	myValue = NULL;
}


BoxStepper::BoxStepper (
		APTR(GenericCrossRegion) region, 
		Int32 index, 
		APTR(XnRegion) OR(NULL) value) 
{
	myRegion = region;
	myIndex = index;
	myValue = value;
}
/* accessing */


RPTR(GenericCrossRegion) BoxStepper::boxComplement (){
	/* The complement of this box */
	
	SPTR(BoxAccumulator) result;
	SPTR(PtrArray) OF1(XnRegion) extrusion;
	
	result = BoxAccumulator::make (myRegion->crossSpace(), myRegion->crossSpace()->axisCount());
	{
		Int32 LoopFinal = myRegion->crossSpace()->axisCount();
		Int32 dimension = Int32Zero;
		for (;;) {
			if (dimension >= LoopFinal){
				break;
			}
			{
				SPTR(XnRegion) special;
				
				extrusion = PtrArray::nulls(myRegion->crossSpace()->axisCount());
				{
					Int32 LoopFinal = dimension;
					Int32 i = Int32Zero;
					for (;;) {
						if (i >= LoopFinal){
							break;
						}
						{
							extrusion->store(i, this->projection(i));
						}
						i += 1;
					}
				}
				special = this->projection(dimension)->complement();
				if (!special->isEmpty()) {
					extrusion->store(dimension, special);
					{
						Int32 LoopFinal = myRegion->crossSpace()->axisCount();
						Int32 i = dimension + 1;
						for (;;) {
							if (i >= LoopFinal){
								break;
							}
							{
								extrusion->store(i, myRegion->crossSpace()->axis(i)->fullRegion());
							}
							i += 1;
						}
					}
					result->addProjections(extrusion, Int32Zero);
				}
			}
			dimension += 1;
		}
	}
	return CAST(GenericCrossRegion,result->region());
}


RPTR(BoxAccumulator) BoxStepper::boxComplementAccumulator (){
	/* The complement of this box */
	
	SPTR(BoxAccumulator) result;
	SPTR(PtrArray) OF1(XnRegion) extrusion;
	
	result = BoxAccumulator::make (myRegion->crossSpace(), myRegion->crossSpace()->axisCount());
	{
		Int32 LoopFinal = myRegion->crossSpace()->axisCount();
		Int32 dimension = Int32Zero;
		for (;;) {
			if (dimension >= LoopFinal){
				break;
			}
			{
				extrusion = PtrArray::nulls(myRegion->crossSpace()->axisCount());
				{
					Int32 LoopFinal = dimension;
					Int32 i = Int32Zero;
					for (;;) {
						if (i >= LoopFinal){
							break;
						}
						{
							extrusion->store(i, this->projection(i));
						}
						i += 1;
					}
				}
				extrusion->store(dimension, this->projection(dimension)->complement());
				{
					Int32 LoopFinal = myRegion->crossSpace()->axisCount();
					Int32 i = dimension + 1;
					for (;;) {
						if (i >= LoopFinal){
							break;
						}
						{
							extrusion->store(i, myRegion->crossSpace()->axis(i)->fullRegion());
						}
						i += 1;
					}
				}
				result->addProjections(extrusion, Int32Zero);
			}
			dimension += 1;
		}
	}
	WPTR(BoxAccumulator) 	returnValue;
	returnValue = result;
	return returnValue;
}


UInt32 BoxStepper::boxHash (){
	UInt32 result;
	
	result = UInt32Zero;
	BEGIN_FOR_EACH(XnRegion,sub,(this->projectionStepper())) {
		result ^= sub->hashForEqual();
	} END_FOR_EACH;
	return result;
}


BooleanVar BoxStepper::boxHasMember (APTR(ActualTuple) tuple){
	/* Whether my current box contains a position */
	
	SPTR(BoxProjectionStepper) mine;
	
	mine = this->projectionStepper();
	while (mine->hasValue()) {
		if (!mine->projection()->hasMember(tuple->positionAt(mine->dimension()))) {
			return FALSE;
		}
		mine->step();
	}
	{mine->destroy();  mine = NULL /* don't want stale (S/CHK)PTRs */;}
	return TRUE;
}


Int32 BoxStepper::boxIndex (){
	return myIndex;
}


BooleanVar BoxStepper::boxIntersects (APTR(BoxStepper) other){
	/* Whether my current box intersects others current box */
	
	SPTR(BoxProjectionStepper) mine;
	SPTR(BoxProjectionStepper) others;
	
	mine = this->projectionStepper();
	others = other->projectionStepper();
	while (mine->hasValue()) {
		if (!mine->projection()->intersects(others->projection())) {
			return FALSE;
		}
		mine->step();
		others->step();
	}
	{mine->destroy();  mine = NULL /* don't want stale (S/CHK)PTRs */;}
	{others->destroy();  others = NULL /* don't want stale (S/CHK)PTRs */;}
	return TRUE;
}


BooleanVar BoxStepper::boxIsEqual (APTR(BoxStepper) other){
	/* Whether my current box isEqual others current box */
	
	SPTR(BoxProjectionStepper) mine;
	SPTR(BoxProjectionStepper) others;
	
	mine = this->projectionStepper();
	others = other->projectionStepper();
	while (mine->hasValue()) {
		if (!mine->projection()->isEqual(others->projection())) {
			return FALSE;
		}
		mine->step();
		others->step();
	}
	{mine->destroy();  mine = NULL /* don't want stale (S/CHK)PTRs */;}
	{others->destroy();  others = NULL /* don't want stale (S/CHK)PTRs */;}
	return TRUE;
}


BooleanVar BoxStepper::boxIsSubsetOf (APTR(BoxStepper) other){
	/* Whether my current box isSubsetOf others current box */
	
	SPTR(BoxProjectionStepper) mine;
	SPTR(BoxProjectionStepper) others;
	
	mine = this->projectionStepper();
	others = other->projectionStepper();
	while (mine->hasValue()) {
		if (!mine->projection()->isSubsetOf(others->projection())) {
			return FALSE;
		}
		mine->step();
		others->step();
	}
	{mine->destroy();  mine = NULL /* don't want stale (S/CHK)PTRs */;}
	{others->destroy();  others = NULL /* don't want stale (S/CHK)PTRs */;}
	return TRUE;
}


BooleanVar BoxStepper::intersectBoxInto (APTR(PtrArray) OF1(XnRegion) result, Int32 boxIndex){
	/* Intersect each projection in the box into the array. 
	Return false if the result is empty, stopping at the first 
	dimension for which the intersection is empty. */
	
	SPTR(BoxProjectionStepper) mine;
	SPTR(XnRegion) proj;
	Int32 base;
	
	base = myRegion->crossSpace()->axisCount() * boxIndex;
	mine = this->projectionStepper();
	while (mine->hasValue()) {
		result->store(base + mine->dimension(), proj = CAST(XnRegion,result->fetch(base + mine->dimension()))->intersect(mine->projection()));
		if (proj->isEmpty()) {
			return FALSE;
		}
		mine->step();
	}
	{mine->destroy();  mine = NULL /* don't want stale (S/CHK)PTRs */;}
	return TRUE;
}


BooleanVar BoxStepper::isBoxOf (APTR(GenericCrossRegion) other){
	/* Whether my box is also a box in the other region */
	
	SPTR(BoxStepper) others;
	
	others = other->boxStepper();
	while (others->hasValue()) {
		if (this->boxIsEqual(others)) {
			return TRUE;
		}
		others->step();
	}
	return FALSE;
}


RPTR(XnRegion) BoxStepper::projection (Int32 dimension){
	/* The projection of my current box into one dimension */
	
	WPTR(XnRegion) 	returnValue;
	returnValue = myRegion->boxProjection(myIndex, dimension);
	return returnValue;
}


RPTR(BoxProjectionStepper) BoxStepper::projectionStepper (){
	/* A stepper over all the projections in the current box */
	
	WPTR(BoxProjectionStepper) 	returnValue;
	returnValue = BoxProjectionStepper::make (myRegion, myIndex, myIndex + 1);
	return returnValue;
}


RPTR(GenericCrossRegion) BoxStepper::region (){
	return (GenericCrossRegion*) myRegion;
}


void BoxStepper::unionBoxInto (APTR(PtrArray) OF1(XnRegion) result, Int32 boxIndex){
	/* Union each projection in the box into the array */
	
	SPTR(BoxProjectionStepper) mine;
	Int32 base;
	
	base = myRegion->crossSpace()->axisCount() * boxIndex;
	mine = this->projectionStepper();
	while (mine->hasValue()) {
		result->store(base + mine->dimension(), CAST(XnRegion,result->fetch(base + mine->dimension()))->unionWith(mine->projection()));
		mine->step();
	}
	{mine->destroy();  mine = NULL /* don't want stale (S/CHK)PTRs */;}
}



/* ************************************************************************ *
 * 
 *                    Class GenericCrossDsp 
 *
 * ************************************************************************ */


/* private: pseudoconstructors */


RPTR(GenericCrossDsp) GenericCrossDsp::identity (APTR(GenericCrossSpace) space, APTR(PtrArray) OF1(CoordinateSpace) subSpaces){
	/* Only used during construction; must pass the array in 
	explicitly since the space isnt initialized yet */
	
	SPTR(PtrArray) OF1(Dsp) result;
	
	result = PtrArray::nulls(subSpaces->count());
	{
		Int32 LoopFinal = result->count();
		Int32 dimension = Int32Zero;
		for (;;) {
			if (dimension >= LoopFinal){
				break;
			}
			{
				result->store(dimension, CAST(CoordinateSpace,subSpaces->fetch(dimension))->identityDsp());
			}
			dimension += 1;
		}
	}
	RETURN_CONSTRUCT(GenericCrossDsp,(space, result));
}
/*  Was NOT.A.TYPE but that obstructed compilation. */


/* accessing */


RPTR(CoordinateSpace) GenericCrossDsp::coordinateSpace (){
	return (CrossSpace*) mySpace;
}


BooleanVar GenericCrossDsp::isIdentity (){
	{
		Int32 LoopFinal = mySubDsps->count();
		Int32 i = Int32Zero;
		for (;;) {
			if (i >= LoopFinal){
				break;
			}
			{
				if (!this->subMapping(i)->isIdentity()) {
					return FALSE;
				}
			}
			i += 1;
		}
	}
	return TRUE;
}


RPTR(Dsp) GenericCrossDsp::subMapping (Int32 index){
	return CAST(Dsp,mySubDsps->fetch(index));
}


RPTR(PtrArray) OF1(Dsp) GenericCrossDsp::subMappings (){
	return CAST(PtrArray,mySubDsps->copy());
}
/* private: creation */


GenericCrossDsp::GenericCrossDsp (APTR(CrossSpace) space, APTR(PtrArray) OF1(Dsp) subDsps) {
	mySpace = space;
	mySubDsps = subDsps;
}
/* transforming */


RPTR(Position) GenericCrossDsp::inverseOf (APTR(Position) position){
	BEGIN_CHOOSE(position) {
		BEGIN_KIND(ActualTuple,tuple) {
			SPTR(PtrArray) OF1(Position) result;
			
			result = PtrArray::nulls(tuple->count());
			{
				Int32 LoopFinal = tuple->count();
				Int32 dimension = Int32Zero;
				for (;;) {
					if (dimension >= LoopFinal){
						break;
					}
					{
						result->store(dimension, this->subMapping(dimension)->inverseOf(tuple->positionAt(dimension)));
					}
					dimension += 1;
				}
			}
			WPTR(Position) 	returnValue;
			returnValue = ActualTuple::make (result);
			return returnValue;
		} END_KIND;
	} END_CHOOSE;
	/* compiler fodder */
	return NULL;
}


RPTR(XnRegion) GenericCrossDsp::inverseOfAll (APTR(XnRegion) region){
	BEGIN_CHOOSE(region) {
		BEGIN_KIND(GenericCrossRegion,cross) {
			SPTR(BoxAccumulator) result;
			SPTR(BoxStepper) boxes;
			
			result = BoxAccumulator::make (mySpace, cross->boxCount());
			boxes = cross->boxStepper();
			while (boxes->hasValue()) {
				result->addInverseTransformedBox(boxes, this);
				boxes->step();
			}
			WPTR(XnRegion) 	returnValue;
			returnValue = result->region();
			return returnValue;
		} END_KIND;
	} END_CHOOSE;
	/* compiler fodder */
	return NULL;
}


RPTR(Position) GenericCrossDsp::of (APTR(Position) position){
	BEGIN_CHOOSE(position) {
		BEGIN_KIND(ActualTuple,tuple) {
			SPTR(PtrArray) OF1(Position) result;
			
			result = PtrArray::nulls(tuple->count());
			{
				Int32 LoopFinal = tuple->count();
				Int32 dimension = Int32Zero;
				for (;;) {
					if (dimension >= LoopFinal){
						break;
					}
					{
						result->store(dimension, this->subMapping(dimension)->of(tuple->positionAt(dimension)));
					}
					dimension += 1;
				}
			}
			WPTR(Position) 	returnValue;
			returnValue = ActualTuple::make (result);
			return returnValue;
		} END_KIND;
	} END_CHOOSE;
	/* compiler fodder */
	return NULL;
}


RPTR(XnRegion) GenericCrossDsp::ofAll (APTR(XnRegion) region){
	BEGIN_CHOOSE(region) {
		BEGIN_KIND(GenericCrossRegion,cross) {
			SPTR(BoxAccumulator) result;
			SPTR(BoxStepper) boxes;
			
			result = BoxAccumulator::make (mySpace, cross->boxCount());
			boxes = cross->boxStepper();
			while (boxes->hasValue()) {
				result->addTransformedBox(boxes, this);
				boxes->step();
			}
			WPTR(XnRegion) 	returnValue;
			returnValue = result->region();
			return returnValue;
		} END_KIND;
	} END_CHOOSE;
	/* compiler fodder */
	return NULL;
}
/* combining */


RPTR(Dsp) GenericCrossDsp::compose (APTR(Dsp) other){
	SPTR(PtrArray) OF1(Dsp) newSubDsps;
	
	newSubDsps = PtrArray::nulls(mySubDsps->count());
	BEGIN_CHOOSE(other) {
		BEGIN_KIND(CrossMapping,cross) {
			{
				Int32 LoopFinal = newSubDsps->count();
				Int32 dimension = Int32Zero;
				for (;;) {
					if (dimension >= LoopFinal){
						break;
					}
					{
						newSubDsps->store(dimension, this->subMapping(dimension)->compose(cross->subMapping(dimension)));
					}
					dimension += 1;
				}
			}
			WPTR(Dsp) 	returnValue;
			returnValue = GenericCrossDsp::make (mySpace, newSubDsps);
			return returnValue;
		} END_KIND;
	} END_CHOOSE;
	/* compiler fodder */
	return NULL;
}


RPTR(Mapping) GenericCrossDsp::inverse (){
	SPTR(PtrArray) OF1(Dsp) newSubDsps;
	
	newSubDsps = PtrArray::nulls(mySubDsps->count());
	{
		Int32 LoopFinal = newSubDsps->count();
		Int32 dimension = Int32Zero;
		for (;;) {
			if (dimension >= LoopFinal){
				break;
			}
			{
				newSubDsps->store(dimension, CAST(Dsp,this->subMapping(dimension)->inverse()));
			}
			dimension += 1;
		}
	}
	RETURN_CONSTRUCT(GenericCrossDsp,(mySpace, newSubDsps));
}


RPTR(Dsp) GenericCrossDsp::inverseCompose (APTR(Dsp) other){
	SPTR(PtrArray) OF1(Dsp) newSubDsps;
	
	newSubDsps = PtrArray::nulls(mySubDsps->count());
	BEGIN_CHOOSE(other) {
		BEGIN_KIND(CrossMapping,cross) {
			{
				Int32 LoopFinal = newSubDsps->count();
				Int32 dimension = Int32Zero;
				for (;;) {
					if (dimension >= LoopFinal){
						break;
					}
					{
						newSubDsps->store(dimension, this->subMapping(dimension)->inverseCompose(cross->subMapping(dimension)));
					}
					dimension += 1;
				}
			}
			WPTR(Dsp) 	returnValue;
			returnValue = GenericCrossDsp::make (mySpace, newSubDsps);
			return returnValue;
		} END_KIND;
	} END_CHOOSE;
	/* compiler fodder */
	return NULL;
}


RPTR(Dsp) GenericCrossDsp::minus (APTR(Dsp) other){
	SPTR(PtrArray) OF1(Dsp) newSubDsps;
	
	newSubDsps = PtrArray::nulls(mySubDsps->count());
	BEGIN_CHOOSE(other) {
		BEGIN_KIND(CrossMapping,cross) {
			{
				Int32 LoopFinal = newSubDsps->count();
				Int32 dimension = Int32Zero;
				for (;;) {
					if (dimension >= LoopFinal){
						break;
					}
					{
						newSubDsps->store(dimension, this->subMapping(dimension)->minus(cross->subMapping(dimension)));
					}
					dimension += 1;
				}
			}
			WPTR(Dsp) 	returnValue;
			returnValue = GenericCrossDsp::make (mySpace, newSubDsps);
			return returnValue;
		} END_KIND;
	} END_CHOOSE;
	/* compiler fodder */
	return NULL;
}
/* private: accessing */


RPTR(PtrArray) OF1(Dsp) GenericCrossDsp::secretSubDsps (){
	/* The actual array of sub Dsps. DO NOT MODIFY */
	
	return (PtrArray*) mySubDsps;
}
/* testing */


UInt32 GenericCrossDsp::actualHashForEqual (){
	return mySpace->hashForEqual() ^ mySubDsps->contentsHash() ^ this->getCategory()->hashForEqual();
}


BooleanVar GenericCrossDsp::isEqual (APTR(Heaper) other){
	BEGIN_CHOOSE(other) {
		BEGIN_KIND(GenericCrossDsp,cross) {
			return mySubDsps->contentsEqual(cross->secretSubDsps());
		} END_KIND;
		BEGIN_OTHERS {
			return FALSE;
		} END_OTHERS;
	} END_CHOOSE;
	/* compiler fodder */
	return FALSE;
}



/* ************************************************************************ *
 * 
 *                    Class GenericCrossRegion 
 *
 * ************************************************************************ */


/* private: pseudo constructors */


RPTR(CrossRegion) GenericCrossRegion::empty (APTR(GenericCrossSpace) space){
	RETURN_CONSTRUCT(GenericCrossRegion,(space, Int32Zero, PtrArray::empty()));
}


RPTR(CrossRegion) GenericCrossRegion::full (APTR(GenericCrossSpace) space, APTR(PtrArray) OF1(CoordinateSpace) subSpaces){
	/* Only used during construction; must pass the array in 
	explicitly since the space isnt initialized yet */
	
	SPTR(PtrArray) OF1(XnRegion) result;
	
	result = PtrArray::nulls(subSpaces->count());
	{
		Int32 LoopFinal = result->count();
		Int32 dimension = Int32Zero;
		for (;;) {
			if (dimension >= LoopFinal){
				break;
			}
			{
				result->store(dimension, CAST(CoordinateSpace,subSpaces->fetch(dimension))->fullRegion());
			}
			dimension += 1;
		}
	}
	RETURN_CONSTRUCT(GenericCrossRegion,(space, 1, result));
}
/* create */


RPTR(GenericCrossRegion) GenericCrossRegion::make (
		APTR(CrossSpace) space, 
		Int32 count, 
		APTR(PtrArray) OF1(XnRegion) regions)
{
	RETURN_CONSTRUCT(GenericCrossRegion,(space, count, regions));
}
/* Represents a region as a two-dimensional array of crosses of subregions.
 Was NOT.A.TYPE but that obstructed compilation.
I think this might work better if the array is lexically sorted, but 
I am not sure there is any meaningful way to do so. Thus there is no 
sorting assumed in the algorithms, although the protocol may 
occasionally suggest that there might be.

Eventually this implementation may save space by using NULL to 
represent repetitions of a sub region such that
	fetchBoxProjection (box, dim) == NULL
only if
	box > 0
	&& boxProjection (box, dim)->isEqual (boxProjection (box - 1, dim))
	&& (dim == 0
		|| fetchBoxProjection (box, dim - 1) == NULL) */


/* accessing */


RPTR(CoordinateSpace) GenericCrossRegion::coordinateSpace (){
	return (CrossSpace*) mySpace;
}


IntegerVar GenericCrossRegion::count (){
	IntegerVar result;
	SPTR(BoxStepper) boxes;
	
	result = IntegerVarZero;
	boxes = this->boxStepper();
	while (boxes->hasValue()) {
		IntegerVar sub;
		
		sub = 1;
		BEGIN_FOR_EACH(XnRegion,proj,(boxes->projectionStepper())) {
			sub *= proj->count();
		} END_FOR_EACH;
		result += sub;
		boxes->step();
	}
	{boxes->destroy();  boxes = NULL /* don't want stale (S/CHK)PTRs */;}
	return result;
}


RPTR(XnRegion) GenericCrossRegion::projection (Int32 index){
	SPTR(XnRegion) result;
	SPTR(BoxStepper) boxes;
	
	if (myCount == 1) {
		WPTR(XnRegion) 	returnValue;
		returnValue = this->boxProjection(Int32Zero, index);
		return returnValue;
	}
	result = mySpace->axis(index)->emptyRegion();
	boxes = this->boxStepper();
	while (boxes->hasValue()) {
		result = result->unionWith(boxes->projection(index));
		boxes->step();
	}
	{boxes->destroy();  boxes = NULL /* don't want stale (S/CHK)PTRs */;}
	WPTR(XnRegion) 	returnValue;
	returnValue = result;
	return returnValue;
}


RPTR(PtrArray) OF1(XnRegion) GenericCrossRegion::projections (){
	SPTR(PtrArray) OF1(XnRegion) result;
	SPTR(BoxStepper) boxes;
	
	result = PtrArray::nulls(mySpace->axisCount());
	{
		UInt32 LoopFinal = result->count();
		UInt32 i = UInt32Zero;
		for (;;) {
			if (i >= LoopFinal){
				break;
			}
			{
				result->store(i, mySpace->axis(i)->emptyRegion());
			}
			i += 1;
		}
	}
	boxes = this->boxStepper();
	while (boxes->hasValue()) {
		boxes->unionBoxInto(result, Int32Zero);
		boxes->step();
	}
	{boxes->destroy();  boxes = NULL /* don't want stale (S/CHK)PTRs */;}
	WPTR(PtrArray) OF1(XnRegion) 	returnValue;
	returnValue = result;
	return returnValue;
}


RPTR(Position) GenericCrossRegion::theOne (){
	SPTR(PtrArray) OF1(Position) result;
	
	if (!(myCount == 1)) {
		BLAST(MustHaveSingleElement);
	}
	result = PtrArray::nulls(mySpace->axisCount());
	{
		Int32 LoopFinal = result->count();
		Int32 i = Int32Zero;
		for (;;) {
			if (i >= LoopFinal){
				break;
			}
			{
				result->store(i, this->boxProjection(Int32Zero, i)->theOne());
			}
			i += 1;
		}
	}
	WPTR(Position) 	returnValue;
	returnValue = mySpace->crossOfPositions(result);
	return returnValue;
}
/* protected: */


RPTR(CrossSpace) GenericCrossRegion::crossSpace (){
	return (CrossSpace*) mySpace;
}
/* private: */


Int32 GenericCrossRegion::boxCount (){
	return myCount;
}


RPTR(XnRegion) GenericCrossRegion::boxProjection (Int32 box, Int32 dimension){
	/* A region is at a given 2D place in the array */
	
	return CAST(XnRegion,myRegions->fetch(box * this->crossSpace()->axisCount() + dimension));
}


RPTR(BoxProjectionStepper) GenericCrossRegion::boxProjectionStepper (){
	/* A stepper over all projections of all boxes in the region */
	
	WPTR(BoxProjectionStepper) 	returnValue;
	returnValue = BoxProjectionStepper::make (this);
	return returnValue;
}


RPTR(BoxStepper) GenericCrossRegion::boxStepper (){
	/* A stepper over all boxes */
	
	WPTR(BoxStepper) 	returnValue;
	returnValue = BoxStepper::make (this);
	return returnValue;
}


BooleanVar GenericCrossRegion::hasBoxProjection (
		APTR(XnRegion) other, 
		Int32 box, 
		Int32 dimension)
{
	/* Whether a region is at a given 2D place in the array. 
	Searches forward and backward through adjacent boxes which 
	have the same hash value */
	
	Int32 index;
	UInt32 hash;
	SPTR(XnRegion) sub;
	
	index = box;
	hash = other->hashForEqual();
	for (;;) {	BooleanVar crutch_Flag;
		/* index >= Int32Zero && (sub = this->boxProjection(index, dimension))->hashForEqual() == hash */
		
		crutch_Flag = index >= Int32Zero;
		if(crutch_Flag) {
			crutch_Flag = (sub = this->boxProjection(index, dimension))->hashForEqual() == hash;
		}
		if (crutch_Flag) {
			if (sub->isEqual(other)) {
				return TRUE;
			}
			index -= 1;
		} else {
			break;
		}
	}
	index = box + 1;
	for (;;) {	BooleanVar crutch_Flag;
		/* index < myCount && (sub = this->boxProjection(index, dimension))->hashForEqual() == hash */
		
		crutch_Flag = index < myCount;
		if(crutch_Flag) {
			crutch_Flag = (sub = this->boxProjection(index, dimension))->hashForEqual() == hash;
		}
		if (crutch_Flag) {
			if (sub->isEqual(other)) {
				return TRUE;
			}
			index += 1;
		} else {
			break;
		}
	}
	return FALSE;
}


RPTR(PtrArray) OF1(XnRegion) GenericCrossRegion::secretRegions (){
	/* The array holding the regions. DO NOT MODIFY */
	
	return (PtrArray*) myRegions;
}
/* testing */


UInt32 GenericCrossRegion::actualHashForEqual (){
	UInt32 result;
	SPTR(BoxStepper) boxes;
	
	result = this->getCategory()->hashForEqual();
	boxes = this->boxStepper();
	while (boxes->hasValue()) {
		result ^= boxes->boxHash();
		boxes->step();
	}
	{boxes->destroy();  boxes = NULL /* don't want stale (S/CHK)PTRs */;}
	return result;
}


BooleanVar GenericCrossRegion::hasMember (APTR(Position) position){
	SPTR(BoxStepper) boxes;
	
	boxes = this->boxStepper();
	while (boxes->hasValue()) {
		if (boxes->boxHasMember(CAST(ActualTuple,position))) {
			return TRUE;
		}
		boxes->step();
	}
	return FALSE;
}


BooleanVar GenericCrossRegion::intersects (APTR(XnRegion) other){
	SPTR(BoxStepper) mine;
	SPTR(BoxStepper) others;
	
	mine = this->boxStepper();
	while (mine->hasValue()) {
		others = CAST(GenericCrossRegion,other)->boxStepper();
		while (others->hasValue()) {
			if (mine->boxIntersects(others)) {
				return TRUE;
			}
			others->step();
		}
		mine->step();
	}
	{mine->destroy();  mine = NULL /* don't want stale (S/CHK)PTRs */;}
	{others->destroy();  others = NULL /* don't want stale (S/CHK)PTRs */;}
	return FALSE;
}


BooleanVar GenericCrossRegion::isDistinction (){
	if (myCount > 1) {
		return FALSE;
	}
	if (myCount == Int32Zero) {
		return TRUE;
	}
	BEGIN_FOR_EACH(XnRegion,proj,(this->boxProjectionStepper())) {
		if (!proj->isDistinction()) {
			return FALSE;
		}
	} END_FOR_EACH;
	return TRUE;
}


BooleanVar GenericCrossRegion::isEmpty (){
	return myCount == Int32Zero;
}


BooleanVar GenericCrossRegion::isEnumerable (APTR(OrderSpec) /* order *//* = NULL*/){
	BLAST(NOT_YET_IMPLEMENTED);
	/* fodder */
	return FALSE;
}


BooleanVar GenericCrossRegion::isEqual (APTR(Heaper) other){
	BEGIN_CHOOSE(other) {
		BEGIN_KIND(GenericCrossRegion,cross) {
			SPTR(BoxStepper) boxes;
			
			{	BooleanVar crutch_Flag;
				/* cross->boxCount() == myCount && cross->crossSpace()->isEqual(this->crossSpace()) */
				
				crutch_Flag = cross->boxCount() == myCount;
				if(crutch_Flag) {
					crutch_Flag = cross->crossSpace()->isEqual(this->crossSpace());
				}
				if (!crutch_Flag) {
					return FALSE;
				}
			}
			boxes = this->boxStepper();
			while (boxes->hasValue()) {
				if (!boxes->isBoxOf(cross)) {
					return FALSE;
				}
				boxes->step();
			}
			{boxes->destroy();  boxes = NULL /* don't want stale (S/CHK)PTRs */;}
			return TRUE;
		} END_KIND;
		BEGIN_OTHERS {
			return FALSE;
		} END_OTHERS;
	} END_CHOOSE;
	/* compiler fodder */
	return FALSE;
}


BooleanVar GenericCrossRegion::isFinite (){
	BEGIN_FOR_EACH(XnRegion,sub,(this->boxProjectionStepper())) {
		if (!sub->isFinite()) {
			return FALSE;
		}
	} END_FOR_EACH;
	return TRUE;
}


BooleanVar GenericCrossRegion::isFull (){
	if (!(myCount == 1)) {
		return FALSE;
	}
	BEGIN_FOR_EACH(XnRegion,sub,(this->boxProjectionStepper())) {
		if (!sub->isFull()) {
			return FALSE;
		}
	} END_FOR_EACH;
	return TRUE;
}


BooleanVar GenericCrossRegion::isSimple (){
	if (myCount > 1) {
		return FALSE;
	}
	if (myCount == Int32Zero) {
		return TRUE;
	}
	BEGIN_FOR_EACH(XnRegion,proj,(this->boxProjectionStepper())) {
		if (!proj->isSimple()) {
			return FALSE;
		}
	} END_FOR_EACH;
	return TRUE;
}


BooleanVar GenericCrossRegion::isSubsetOf (APTR(XnRegion) other){
	/* Ravi -- Thing to do !!!! */
	
	/* figure out a more efficient algorithm - the one commented 
	out below doesn't work */
	/* | others {BoxStepper} mine {BoxStepper} |
		others := other boxStepper.
		[others hasValue] whileTrue:
			[mine := self boxStepper.
			[mine hasValue] whileTrue:
				[(others boxIsSubsetOf: mine) ifFalse:
					[^false].
				mine step].
			others step].
		^true */
	return this->CrossRegion::isSubsetOf(other);
}
/* operations */


RPTR(XnRegion) GenericCrossRegion::asSimpleRegion (){
	SPTR(PtrArray) result;
	SPTR(BoxProjectionStepper) projections;
	
	if (this->isEmpty()) {
		return this;
	}
	result = PtrArray::nulls(mySpace->axisCount());
	projections = this->boxProjectionStepper();
	while (projections->hasValue()) {
		if (result->fetch(projections->dimension()) == NULL) {
			result->store(projections->dimension(), projections->projection()->asSimpleRegion());
		} else {
			result->store(projections->dimension(), CAST(XnRegion,result->fetch(projections->dimension()))->simpleUnion(projections->projection()));
		}
		projections->step();
	}
	{projections->destroy();  projections = NULL /* don't want stale (S/CHK)PTRs */;}
	WPTR(XnRegion) 	returnValue;
	returnValue = mySpace->crossOfRegions(result);
	return returnValue;
}


RPTR(XnRegion) GenericCrossRegion::complement (){
	SPTR(XnRegion) result;
	SPTR(BoxStepper) boxes;
	
	if (this->isEmpty()) {
		WPTR(XnRegion) 	returnValue;
		returnValue = mySpace->fullRegion();
		return returnValue;
	}
	boxes = this->boxStepper();
	result = boxes->boxComplement();
	boxes->step();
	while (boxes->hasValue()) {
		result = result->intersect(boxes->boxComplement());
		boxes->step();
	}
	{boxes->destroy();  boxes = NULL /* don't want stale (S/CHK)PTRs */;}
	WPTR(XnRegion) 	returnValue;
	returnValue = result;
	return returnValue;
}


RPTR(XnRegion) GenericCrossRegion::intersect (APTR(XnRegion) region){
	BEGIN_CHOOSE(region) {
		BEGIN_KIND(GenericCrossRegion,other) {
			SPTR(BoxAccumulator) result;
			SPTR(GenericCrossRegion) smaller;
			SPTR(GenericCrossRegion) larger;
			SPTR(BoxStepper) bits;
			SPTR(BoxAccumulator) piece;
			
			if (this->boxCount() < other->boxCount()) {
				smaller = this;
				larger = other;
			} else {
				smaller = other;
				larger = this;
			}
			if (smaller->isEmpty()) {
				WPTR(XnRegion) 	returnValue;
				returnValue = smaller;
				return returnValue;
			}
			bits = smaller->boxStepper();
			result = NULL;
			piece = BoxAccumulator::make (larger);
			while (bits->hasValue()) {
				piece->intersectWithBox(bits);
				if (result == NULL) {
					result = piece;
				} else {
					result->addAccumulatedBoxes(piece);
				}
				bits->step();
				if (bits->hasValue()) {
					piece = BoxAccumulator::make (larger);
				}
			}
			{bits->destroy();  bits = NULL /* don't want stale (S/CHK)PTRs */;}
			result->mergeBoxes();
			result->removeDeleted();
			WPTR(XnRegion) 	returnValue;
			returnValue = result->region();
			return returnValue;
		} END_KIND;
	} END_CHOOSE;
	/* compiler fodder */
	return NULL;
}


RPTR(XnRegion) GenericCrossRegion::unionWith (APTR(XnRegion) region){
	SPTR(BoxAccumulator) result;
	
	BEGIN_CHOOSE(region) {
		BEGIN_KIND(GenericCrossRegion,other) {
			SPTR(BoxStepper) stepper;
			
			result = BoxAccumulator::make (this);
			stepper = other->boxStepper();
			result->unionWithBoxes(stepper);
			{stepper->destroy();  stepper = NULL /* don't want stale (S/CHK)PTRs */;}
			result->mergeBoxes();
			result->removeDeleted();
			WPTR(XnRegion) 	returnValue;
			returnValue = result->region();
			return returnValue;
		} END_KIND;
	} END_CHOOSE;
	/* compiler fodder */
	return NULL;
}
/* printing */


void GenericCrossRegion::printOn (ostream& oo){
	SPTR(BoxStepper) boxes;
	char * between;
	
	oo << "{";
	boxes = this->boxStepper();
	while (boxes->hasValue()) {
		between = "";
		BEGIN_FOR_EACH(XnRegion,proj,(boxes->projectionStepper())) {
			oo << between;
			if (proj->isFull()) {
				oo << "*";
			} else {
				oo << proj;
			}
			between = " x ";
		} END_FOR_EACH;
		boxes->step();
		if (boxes->hasValue()) {
			oo << ", ";
		}
	}
	{boxes->destroy();  boxes = NULL /* don't want stale (S/CHK)PTRs */;}
	oo << "}";
}
/* enumerating */


RPTR(Stepper) OF1(CrossRegion) GenericCrossRegion::boxes (){
	WPTR(Stepper) OF1(CrossRegion) 	returnValue;
	returnValue = this->boxStepper();
	return returnValue;
}


RPTR(ScruSet) OF1(XnRegion) GenericCrossRegion::distinctions (){
	SPTR(Accumulator) result;
	SPTR(BoxProjectionStepper) ps;
	
	if (!this->isSimple()) {
		BLAST(MustBeSimple);
	}
	result = SetAccumulator::make ();
	ps = this->boxProjectionStepper();
	BEGIN_FOR_EACH(XnRegion,sub,(ps)) {
		BEGIN_FOR_EACH(XnRegion,dist,(sub->distinctions()->stepper())) {
			result->step(mySpace->extrusion(ps->dimension(), dist));
		} END_FOR_EACH;
	} END_FOR_EACH;
	return CAST(ScruSet,result->value());
}


BooleanVar GenericCrossRegion::isBox (){
	return this->isSimple();
}


RPTR(Stepper) GenericCrossRegion::simpleRegions (APTR(OrderSpec) order/* = NULL*/){
	if (order != NULL) {
		BLAST(NOT_YET_IMPLEMENTED);
	}
	WPTR(Stepper) 	returnValue;
	returnValue = GenericCrossSimpleRegionStepper::make (mySpace, this->boxStepper());
	return returnValue;
}
/* protected: enumerating */


RPTR(Stepper) OF1(Position) GenericCrossRegion::actualStepper (APTR(OrderSpec) /* order */){
	if (this->isEmpty()) {
		WPTR(Stepper) OF1(Position) 	returnValue;
		returnValue = Stepper::emptyStepper();
		return returnValue;
	}
	/* Ravi -- Thing to do !!!! */
	
	/* do a real stepper */
	/* Hack !!!! */
	
	WPTR(Stepper) OF1(Position) 	returnValue;
	returnValue = Stepper::itemStepper(this->theOne());
	return returnValue;
}
/* protected: create */


GenericCrossRegion::GenericCrossRegion (
		APTR(CrossSpace) space, 
		Int32 count, 
		APTR(PtrArray) OF1(XnRegion) regions) 
{
	mySpace = space;
	myCount = count;
	myRegions = regions;
}



/* ************************************************************************ *
 * 
 *                    Class GenericCrossSimpleRegionStepper 
 *
 * ************************************************************************ */


/* create */


RPTR(Stepper) GenericCrossSimpleRegionStepper::make (APTR(CrossSpace) space, APTR(Stepper) boxes){
	RETURN_CONSTRUCT(GenericCrossSimpleRegionStepper,(space, boxes));
}
/* operations */


WPTR(Heaper) GenericCrossSimpleRegionStepper::fetch (){
	SPTR(PtrArray) result;
	
	if (!this->hasValue()) {
		return NULL;
	}
	result = PtrArray::nulls(mySpace->axisCount());
	{
		Int32 LoopFinal = mySpace->axisCount();
		Int32 i = Int32Zero;
		for (;;) {
			if (i >= LoopFinal){
				break;
			}
			{
				result->store(i, CAST(Stepper,mySimples->get(i))->get());
			}
			i += 1;
		}
	}
	WPTR(Heaper) 	returnValue;
	returnValue = mySpace->crossOfRegions(result);
	return returnValue;
}


BooleanVar GenericCrossSimpleRegionStepper::hasValue (){
	return myBoxes->hasValue();
}


void GenericCrossSimpleRegionStepper::step (){
	Int32 index;
	
	if (myBoxes->hasValue()) {
		index = mySpace->axisCount() - 1;
		while (index >= Int32Zero) {
			SPTR(Stepper) sub;
			
			sub = CAST(Stepper,mySimples->get(index));
			sub->step();
			if (sub->hasValue()) {
				this->replenishSteppers(index + 1);
				return;
				
			}
			index -= 1;
		}
		myBoxes->step();
		if (myBoxes->hasValue()) {
			this->replenishSteppers(Int32Zero);
		}
	}
}
/* private: */


void GenericCrossSimpleRegionStepper::replenishSteppers (Int32 index){
	/* Replenish all steppers starting at index */
	
	SPTR(CrossRegion) box;
	
	box = CAST(CrossRegion,myBoxes->get());
	{
		Int32 LoopFinal = mySpace->axisCount();
		Int32 i = index;
		for (;;) {
			if (i >= LoopFinal){
				break;
			}
			{
				mySimples->store(i, box->projection(i)->simpleRegions());
			}
			i += 1;
		}
	}
}
/* create */


RPTR(Stepper) GenericCrossSimpleRegionStepper::copy (){
	SPTR(PtrArray) simples;
	
	simples = PtrArray::nulls(mySimples->count());
	{
		Int32 LoopFinal = simples->count();
		Int32 i = Int32Zero;
		for (;;) {
			if (i >= LoopFinal){
				break;
			}
			{
				simples->store(i, CAST(Stepper,mySimples->get(i))->copy());
			}
			i += 1;
		}
	}
	RETURN_CONSTRUCT(GenericCrossSimpleRegionStepper,(mySpace, myBoxes->copy(), simples));
}
/* protected: create */


GenericCrossSimpleRegionStepper::GenericCrossSimpleRegionStepper (APTR(CrossSpace) space, APTR(Stepper) boxes) {
	mySpace = space;
	myBoxes = boxes;
	if (boxes->hasValue()) {
		mySimples = PtrArray::nulls(space->axisCount());
		this->replenishSteppers(Int32Zero);
	}
}


GenericCrossSimpleRegionStepper::GenericCrossSimpleRegionStepper (
		APTR(CrossSpace) space, 
		APTR(Stepper) boxes, 
		APTR(PtrArray) simples) 
{
	mySpace = space;
	myBoxes = boxes;
	mySimples = simples;
}



/* ************************************************************************ *
 * 
 *                    Class GenericCrossSpace 
 *
 * ************************************************************************ */


/* rcvr pseudoconstructors */


RPTR(Heaper) GenericCrossSpace::make (APTR(Rcvr) rcvr){
	WPTR(Heaper) 	returnValue;
	returnValue = new (CAST(SpecialistRcvr,rcvr)->makeIbid(cat_GenericCrossSpace)) GenericCrossSpace(CAST(PtrArray,rcvr->receiveHeaper()), tcsj);
	return returnValue;
}
/* pseudoconstructors */


RPTR(CrossSpace) GenericCrossSpace::make (APTR(PtrArray) OF1(CoordinateSpace) subSpaces){
	RETURN_CONSTRUCT(GenericCrossSpace,(subSpaces, tcsj));
}
/* Default implementation of cross coordinate space.
was NOT.A.TYPE but that prevented compilation */


/* making */


RPTR(Mapping) GenericCrossSpace::crossOfMappings (APTR(PtrArray) OF1(Mapping OR(NULL)) subMappings/* = NULL*/){
	if (subMappings == NULL) {
		WPTR(Mapping) 	returnValue;
		returnValue = CrossMapping::make (this);
		return returnValue;
	}
	{
		Int32 LoopFinal = subMappings->count();
		Int32 i = Int32Zero;
		for (;;) {
			if (i >= LoopFinal){
				break;
			}
			{
				SPTR(Mapping) OR(NULL) subM;
				
				subM = CAST(Mapping,subMappings->fetch(i));
				{	BooleanVar crutch_Flag;
					/* subM != NULL && !subM->isKindOf(cat_Dsp) */
					
					crutch_Flag = subM != NULL;
					if(crutch_Flag) {
						crutch_Flag = !subM->isKindOf(cat_Dsp);
					}
					if (crutch_Flag) {
						BLAST(NOT_YET_IMPLEMENTED);
					}
				}
			}
			i += 1;
		}
	}
	WPTR(Mapping) 	returnValue;
	returnValue = CrossMapping::make (this, subMappings);
	return returnValue;
}


RPTR(CrossOrderSpec) GenericCrossSpace::crossOfOrderSpecs (APTR(PtrArray) OF1(OrderSpec OR(NULL)) subOrderings/* = NULL*/, APTR(PrimIntArray) subSpaceOrdering/* = NULL*/){
	WPTR(CrossOrderSpec) 	returnValue;
	returnValue = CrossOrderSpec::make (this, subOrderings, subSpaceOrdering);
	return returnValue;
}


RPTR(Tuple) GenericCrossSpace::crossOfPositions (APTR(PtrArray) OF1(Position) coordinates){
	WPTR(Tuple) 	returnValue;
	returnValue = ActualTuple::make (coordinates);
	return returnValue;
}


RPTR(CrossRegion) GenericCrossSpace::crossOfRegions (APTR(PtrArray) OF1(XnRegion OR(NULL)) subRegions){
	SPTR(PtrArray) OF1(XnRegion) result;
	
	result = CAST(PtrArray,subRegions->copy());
	{
		Int32 LoopFinal = result->count();
		Int32 dimension = Int32Zero;
		for (;;) {
			if (dimension >= LoopFinal){
				break;
			}
			{
				if (result->fetch(dimension) == NULL) {
					result->store(dimension, this->axis(dimension)->fullRegion());
				} else {
					if (CAST(XnRegion,result->fetch(dimension))->isEmpty()) {
						return CAST(CrossRegion,this->emptyRegion());
					}
				}
			}
			dimension += 1;
		}
	}
	WPTR(CrossRegion) 	returnValue;
	returnValue = GenericCrossRegion::make (this, 1, result);
	return returnValue;
}


RPTR(CrossRegion) GenericCrossSpace::extrusion (Int32 dimension, APTR(XnRegion) subRegion){
	SPTR(PtrArray) OF1(XnRegion) projs;
	
	if (subRegion->isEmpty()) {
		return CAST(CrossRegion,this->emptyRegion());
	}
	projs = PtrArray::nulls(GenericCrossSpace::mySubSpaces->count());
	{
		Int32 LoopFinal = GenericCrossSpace::mySubSpaces->count();
		Int32 i = Int32Zero;
		for (;;) {
			if (i >= LoopFinal){
				break;
			}
			{
				if (i == dimension) {
					projs->store(i, subRegion);
				} else {
					projs->store(i, CAST(CoordinateSpace,GenericCrossSpace::mySubSpaces->fetch(i))->fullRegion());
				}
			}
			i += 1;
		}
	}
	WPTR(CrossRegion) 	returnValue;
	returnValue = GenericCrossRegion::make (this, 1, projs);
	return returnValue;
}
/* private: creation */


GenericCrossSpace::GenericCrossSpace (APTR(PtrArray) OF1(CoordinateSpace) subSpaces, TCSJ) 
	: CrossSpace(subSpaces, tcsj) {
	this->finishCreate(GenericCrossRegion::empty(this), GenericCrossRegion::full(this, subSpaces), GenericCrossDsp::identity(this, subSpaces), CrossOrderSpec::fetchAscending(this, subSpaces), CrossOrderSpec::fetchDescending(this, subSpaces));
}
/* printing */


void GenericCrossSpace::printOn (ostream& oo){
	oo << "<";
	{
		Int32 LoopFinal = GenericCrossSpace::mySubSpaces->count();
		Int32 i = Int32Zero;
		for (;;) {
			if (i >= LoopFinal){
				break;
			}
			{
				if (i > Int32Zero) {
					oo << " x ";
				}
				oo << GenericCrossSpace::mySubSpaces->fetch(i);
			}
			i += 1;
		}
	}
	oo << ">";
}
/* hooks: */


void GenericCrossSpace::sendGenericCrossSpaceTo (APTR(Xmtr) xmtr){
	xmtr->sendHeaper(GenericCrossSpace::mySubSpaces);
}



/* ************************************************************************ *
 * 
 *                    Class TupleStepper 
 *
 * ************************************************************************ */


/* pseudoconstructors */


RPTR(Stepper) TupleStepper::make (
		APTR(CrossSpace) space, 
		APTR(PtrArray) OF1(Stepper OF1(Position)) virginSteppers, 
		APTR(PrimIntArray) lexOrder/* = NULL*/)
{
	SPTR(PtrArray) OF1(Stepper OF1(Position)) steppers;
	SPTR(PrimIntArray) lexO;
	
	if (virginSteppers->count() == Int32Zero) {
		WPTR(Stepper) 	returnValue;
		returnValue = Stepper::itemStepper(space->crossOfPositions(PtrArray::nulls(Int32Zero)));
		return returnValue;
	}
	steppers = PtrArray::nulls(virginSteppers->count());
	{
		Int32 LoopFinal = virginSteppers->count();
		Int32 i = Int32Zero;
		for (;;) {
			if (i >= LoopFinal){
				break;
			}
			{
				SPTR(Stepper) OF1(Position) vs;
				
				vs = CAST(Stepper,virginSteppers->fetch(i));
				if (!vs->hasValue()) {
					WPTR(Stepper) 	returnValue;
					returnValue = Stepper::emptyStepper();
					return returnValue;
				}
				steppers->store(i, vs->copy());
			}
			i += 1;
		}
	}
	if (lexOrder == NULL) {
		lexO = Int32Array::make (virginSteppers->count());
		{
			Int32 LoopFinal = virginSteppers->count();
			Int32 i = Int32Zero;
			for (;;) {
				if (i >= LoopFinal){
					break;
				}
				{
					lexO->storeInteger(i, i);
				}
				i += 1;
			}
		}
	} else {
		lexO = lexOrder;
	}
	RETURN_CONSTRUCT(TupleStepper,(space, virginSteppers, steppers, lexO));
}
/* A stepper for stepping through the positions in a simple cross 
region in order according to a lexicographic composition of 
OrderSpecs of each of the projections of the region.  See 
CrossOrderSpec.NOT.A.TYPE  */


/* private: creation */


TupleStepper::TupleStepper (
		APTR(CrossSpace) space, 
		APTR(PtrArray) OF1(Stepper OF1(Position)) virginSteppers, 
		APTR(PtrArray) OF1(Stepper OF1(Position)) steppers, 
		APTR(PrimIntArray) lexOrder) 
{
	mySpace = space;
	myVirginSteppers = virginSteppers;
	mySteppers = steppers;
	myLexOrder = lexOrder;
	this->setValueFromSteppers();
}
/* private: */


void TupleStepper::setValueFromSteppers (){
	SPTR(PtrArray) OF1(Position) coords;
	
	coords = PtrArray::nulls(mySteppers->count());
	{
		Int32 LoopFinal = mySteppers->count();
		Int32 i = Int32Zero;
		for (;;) {
			if (i >= LoopFinal){
				break;
			}
			{
				coords->store(i, CAST(Position,CAST(Stepper,mySteppers->fetch(i))->get()));
			}
			i += 1;
		}
	}
	myValue = mySpace->crossOfPositions(coords);
}
/* operations */


RPTR(Stepper) TupleStepper::copy (){
	SPTR(PtrArray) OF1(Stepper OF1(Position)) newSteppers;
	
	if (!this->hasValue()) {
		WPTR(Stepper) 	returnValue;
		returnValue = Stepper::emptyStepper();
		return returnValue;
	}
	newSteppers = PtrArray::nulls(mySteppers->count());
	{
		Int32 LoopFinal = mySteppers->count();
		Int32 i = Int32Zero;
		for (;;) {
			if (i >= LoopFinal){
				break;
			}
			{
				newSteppers->store(i, CAST(Stepper,mySteppers->fetch(i))->copy());
			}
			i += 1;
		}
	}
	RETURN_CONSTRUCT(TupleStepper,(mySpace, myVirginSteppers, newSteppers, myLexOrder));
}


WPTR(Heaper) TupleStepper::fetch (){
	return (Tuple*) myValue;
}


BooleanVar TupleStepper::hasValue (){
	return myValue != NULL;
}


void TupleStepper::step (){
	SPTR(Stepper) OF1(Position) stomp;
	
	if (myValue == NULL) {
		return;
		
	}
	{
		Int32 LoopFinal = Int32Zero;
		Int32 i = myLexOrder->count() - 1;
		for (;;) {
			if (i <= LoopFinal){
				break;
			}
			{
				Int32 dim;
				
				dim = myLexOrder->integerAt(i).asLong();
				stomp = CAST(Stepper,mySteppers->fetch(dim));
				stomp->step();
				if (stomp->hasValue()) {
					this->setValueFromSteppers();
					return;
					
				}
				mySteppers->store(dim, CAST(Stepper,myVirginSteppers->fetch(dim))->copy());
			}
			i -= 1;
		}
	}
	myValue = NULL;
}

#ifndef CROSSX_SXX
#include "crossx.sxx"
#endif /* CROSSX_SXX */


#ifndef CROSSP_SXX
#include "crossp.sxx"
#endif /* CROSSP_SXX */



#endif /* CROSSX_CXX */

