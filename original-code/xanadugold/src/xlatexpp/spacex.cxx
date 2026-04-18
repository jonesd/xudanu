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

#ifndef SPACEX_CXX
#define SPACEX_CXX


#ifndef CHOOSEX_HXX
#include "choosex.hxx"
#endif /* CHOOSEX_HXX */

#ifndef SPACEX_HXX
#include "spacex.hxx"
#endif /* SPACEX_HXX */

#ifndef SPACEX_IXX
#include "spacex.ixx"
#endif /* SPACEX_IXX */

#ifndef SPACER_HXX
#include "spacer.hxx"
#endif /* SPACER_HXX */

#ifndef SPACER_IXX
#include "spacer.ixx"
#endif /* SPACER_IXX */

#ifndef SPACEP_HXX
#include "spacep.hxx"
#endif /* SPACEP_HXX */

#ifndef SPACEP_IXX
#include "spacep.ixx"
#endif /* SPACEP_IXX */


#ifndef INTEGERX_HXX
#include "integerx.hxx"
#endif /* INTEGERX_HXX */




/* ************************************************************************ *
 * 
 *                    Class Arrangement 
 *
 * ************************************************************************ */


/* Generally represents a pair of an OrderSpec and a Region.  
Arrangements map between regions and primArrays. */


/* accessing */


void Arrangement::copyElements (
		APTR(PrimArray) toArray, 
		APTR(Dsp) toDsp, 
		APTR(PrimArray) fromArray, 
		APTR(Arrangement) fromArrange, 
		APTR(XnRegion) fromRegion)
{
	/* Copy elements into toArray arranged according to the receiver. 
		 Copy them from fromArray arranged according to fromArrange.  
		 The source region is fromRegion.  It gets tranformed by toDsp
		 into the toArray. */
	
	BEGIN_FOR_EACH(Position,key,(fromRegion->stepper())) {
		toArray->storeValue(this->indexOf(toDsp->of(key)).asLong(), fromArray->fetchValue(fromArrange->indexOf(key).asLong()));
	} END_FOR_EACH;
}
/* testing */


UInt32 Arrangement::actualHashForEqual (){
	return Heaper::takeOop();
}

	/* automatic 0-argument constructor */
Arrangement::Arrangement() {}



/* ************************************************************************ *
 * 
 *                    Class CoordinateSpace 
 *
 * ************************************************************************ */


/* A coordinate space represents (among other things) the domain 
space of a table. Corresponding to each coordinate space will be a 
set of objects of the following kinds:
	
	Position -- The elements of the coordinate space.
	Mapping -- (Add a description.)
	OrderSpec -- The ways of specifying partial orders of this 
coordinate space's Positions.
	XuRegion -- An XuRegion represents a set of Positions.  The domain 
of a table is an XuRegion.
	
	When defining a new coordinate space class, one generally defines 
new corresponing subclasses of each of the above classes.  A kind of 
any of the above classes knows what coordinate space it is a part of 
(the "coordinateSpace()" message will yield an appropriate kind of 
CoordinateSpace).  CoordinateSpace objects exist mostly just to 
represent this commonality.  Coordinate spaces are disjoint--it is an 
error to use any of the generic protocol of any of the above classes 
if the objects in question are of two different coordinate spaces.  
For example, "dsp->of (pos)" is not an error iff "dsp->coordinateSpace
()->isEqual (pos->coordinateSpace())".
	
Note that this class is not COPY or even PSEUDO_COPY.  All of the 
instance variables for CoordinateSpace are basically cached
quantities that require vary little actual state from the derived 
classes in order to be constructed.  This realization allows a knot
to be untangled when reading these objects from external storage. */


/* accessing */


UInt32 CoordinateSpace::actualHashForEqual (){
	return Heaper::takeOop();
}


RPTR(OrderSpec) CoordinateSpace::getAscending (){
	/* Essential.  The natural full-ordering of the coordinate space. */
	
	SPTR(OrderSpec) OR(NULL) result;
	
	result = this->fetchAscending();
	if (result == NULL) {
		BLAST(NoFullOrder);
	}
	WPTR(OrderSpec) 	returnValue;
	returnValue = result;
	return returnValue;
}


RPTR(OrderSpec) CoordinateSpace::getDescending (){
	/* The mirror image of the partial order returned by 
	'CoordinateSpace::getAscending'. */
	
	SPTR(OrderSpec) OR(NULL) result;
	
	result = this->fetchDescending();
	if (result == NULL) {
		BLAST(NoFullOrder);
	}
	WPTR(OrderSpec) 	returnValue;
	returnValue = result;
	return returnValue;
}


BooleanVar CoordinateSpace::verify (APTR(Heaper) thing){
	/* tell whether this is a valid Position/XuRegion/Dsp/OrderSpe
	c for this space */
	
	BEGIN_CHOOSE(thing) {
		KIND4(Position,XnRegion,Dsp,OrderSpec,t, {
			return this->isEqual(t->coordinateSpace());
		});
	} END_CHOOSE;
	/* cast into blasts here. */
	return FALSE;
}
/* protected: create followup */


void CoordinateSpace::finishCreate (
		APTR(XnRegion) emptyRegion, 
		APTR(XnRegion) fullRegion, 
		APTR(Dsp) identityDsp, 
		APTR(OrderSpec) ascending/* = NULL*/, 
		APTR(OrderSpec) descending/* = NULL*/)
{
	myEmptyRegion = emptyRegion;
	myFullRegion = fullRegion;
	myIdentityDsp = identityDsp;
	myAscending = ascending;
	{	BooleanVar crutch_Flag;
		/* descending == NULL && ascending != NULL */
		
		crutch_Flag = descending == NULL;
		if(crutch_Flag) {
			crutch_Flag = ascending != NULL;
		}
		if (crutch_Flag) {
			myDescending = ascending->reversed();
		} else {
			myDescending = descending;
		}
	}
}
/* create */


CoordinateSpace::CoordinateSpace () {
	myEmptyRegion = NULL;
	myFullRegion = NULL;
	myIdentityDsp = NULL;
	myAscending = NULL;
	myDescending = NULL;
}


CoordinateSpace::CoordinateSpace (
		APTR(XnRegion) emptyRegion, 
		APTR(XnRegion) fullRegion, 
		APTR(Dsp) identityDsp, 
		APTR(OrderSpec) ascending/* = NULL*/, 
		APTR(OrderSpec) descending/* = NULL*/) 
{
	myEmptyRegion = emptyRegion;
	myFullRegion = fullRegion;
	myIdentityDsp = identityDsp;
	myAscending = ascending;
	{	BooleanVar crutch_Flag;
		/* descending == NULL && ascending != NULL */
		
		crutch_Flag = descending == NULL;
		if(crutch_Flag) {
			crutch_Flag = ascending != NULL;
		}
		if (crutch_Flag) {
			myDescending = ascending->reversed();
		} else {
			myDescending = descending;
		}
	}
}



/* ************************************************************************ *
 * 
 *                    Class Mapping 
 *
 * ************************************************************************ */


/* pseudo constructors */


RPTR(Mapping) Mapping::make (APTR(CoordinateSpace) cs, APTR(XnRegion) values){
	/* Make a constant mapping from all positions in cs to all 
	positions in values. */
	
	if (values->isEmpty()) {
		WPTR(Mapping) 	returnValue;
		returnValue = Mapping::make (cs, values->coordinateSpace());
		return returnValue;
	} else {
		RETURN_CONSTRUCT(ConstantMapping,(cs, values));
	}
}


RPTR(Mapping) Mapping::make (
		APTR(CoordinateSpace) cs, 
		APTR(CoordinateSpace) rs, 
		APTR(ImmuSet) OF1(Mapping) mappings)
{
	/* The combine of all the mappings in 'mappings'  All domains must be 
		in cs and all ranges in rs.  cs and rs must be provided in case 
		'mappings' is empty. */
	
	if (mappings->isEmpty()) {
		WPTR(Mapping) 	returnValue;
		returnValue = EmptyMapping::make (cs, rs);
		return returnValue;
	} else {
		SPTR(MuSet) OF1(Mapping) result;
		
		result = MuSet::make ();
		BEGIN_FOR_EACH(Mapping,each,(mappings->stepper())) {
			CompositeMapping::storeMapping(each, result);
		} END_FOR_EACH;
		WPTR(Mapping) 	returnValue;
		returnValue = CompositeMapping::privateMakeMapping(cs, rs, mappings);
		return returnValue;
	}
}
/* A mapping is a general mapping from one coordinate space to 
another, with few of the guarantees provided by Dsps.  In particular, 
the source and destination coordinate spaces can be different, and 
the mapping doesn't have to be everywhere defined (but it has to say 
where it is defined via "domain" and "range" messages).  A mapping 
doesn't have to be unique--the same domain position may map to 
multiple range positions and vice versa.  A mapping of a XuRegion 
must yield another XuRegion, but a mapping of a simple region doesn't 
have to yield a simple region.
	
	A useful and valid way to think of a Mapping is as a (possibly 
infinite) set of pairs (a mathematical set, not a ScruSet).  The 
domain region consists of the first elements of each pair, and the 
range region consists of the second elements.
	
	A mapping is most useful as a representation of a version comparison 
of two different organizations of common elements.  The mapping would 
tell how positions in one organization correspond to positions in the other. */


/* accessing */


RPTR(Stepper) OF1(Mapping) Mapping::simplerMappings (){
	/* Essential. Break this Mapping up into simpler Mappings 
	which can be combined together to get this one. */
	
	WPTR(Stepper) OF1(Mapping) 	returnValue;
	returnValue = this->simpleMappings()->stepper();
	return returnValue;
}


RPTR(Mapping) Mapping::unrestricted (){
	/* Essential. If this is a 'simpler' Mapping, and not isFull, 
	then return a yet simpleMapping of some class from which you 
	can get more information. Note that m->restrict 
	(region)->unrestricted () is not necessarily the same as m, 
	since information may be lost. */
	
	if (this->fetchDsp() == NULL) {
		BLAST(NotSimpleEnough);
	}
	WPTR(Mapping) 	returnValue;
	returnValue = this->fetchDsp();
	return returnValue;
}
/* mapping */


IntegerVar Mapping::inverseOfInt (IntegerVar pos){
	/* Unboxed version of 'this->inverseOf (xuInteger(pos))'. See 
		discussion in the XuInteger class comment about boxed and unboxed 
		protocols */
	
	return CAST(IntegerPos,this->inverseOf(IntegerPos::make (pos)))->asIntegerVar();
}


IntegerVar Mapping::ofInt (IntegerVar pos){
	/* Unboxed version of 'this->of (xuInteger(pos))'.  See 
	discussion in the XuInteger class 
		comment about boxed and unboxed protocols */
	
	return CAST(IntegerPos,this->of(IntegerPos::make (pos)))->asIntegerVar();
}
/* operations */


RPTR(Mapping) Mapping::combine (APTR(Mapping) other){
	/* Essential.  Result will do both mine and other's mappings. 
	 It will do my mapping where I am defined, and it will do the 
	other's where his is defined.  If we are both defined over 
	some domain positions, then the result is a multi-valued 
	mapping.  If you think of a Mapping simply as a set of pairs 
	(see class comment), then 'combine' yields a Mapping 
	consisting of the union of these two sets. */
	
	SPTR(Mapping) result;
	
	result = this->fetchCombine(other);
	if (result != NULL) {
		WPTR(Mapping) 	returnValue;
		returnValue = result;
		return returnValue;
	}
	result = other->fetchCombine(this);
	if (result != NULL) {
		WPTR(Mapping) 	returnValue;
		returnValue = result;
		return returnValue;
	} else {
		SPTR(MuSet) OF1(Mapping) set;
		
		set = MuSet::make ();
		set->store(this);
		set->store(other);
		WPTR(Mapping) 	returnValue;
		returnValue = CompositeMapping::privateMakeMapping(this->domainSpace(), this->rangeSpace(), set->asImmuSet());
		return returnValue;
	}
}
/* vulnerable: accessing */
/* testing */


UInt32 Mapping::actualHashForEqual (){
	return Heaper::takeOop();
}

	/* automatic 0-argument constructor */
Mapping::Mapping() {}



/* ************************************************************************ *
 * 
 *                    Class   Dsp 
 *
 * ************************************************************************ */


/* A Dsp is a mapping from a coordinate space to itself that 
preserves simple regions.  Every coordinate space must have an 
identity Dsp (which maps all positions of that space onto 
themselves). Dsps are necessarily invertable and composable.

(Removed from CoordinateSpace because Dsps are still internal.:
Dsp -- The transformations that can be applied to positions and 
regions of this cordinate space.  A Dsp is necessarily invertible but 
generally not order-preserving. The composition of two Dsps is always 
a Dsp. If you can subtract two Dsps, the result will be another Dsp.  
The Dsp of a Position in this space is always another Position in 
this space.  The Dsp of a simple region is always another simple region.)
	
	
	Considering a Mapping as a set of pairs, a Dsp is one for which each 
position appears exactly once in the first elements of the pairs, and 
exactly once in the second elements.  Composition of Dsps isn't 
necessarily commutative, though there are currently no 
counter-examples.  Therefore we must be extra careful to avoid 
embodying commutativity assumptions in our code, as we currently have 
no way of finding such bugs. */


/* accessing */


RPTR(XnRegion) Dsp::domain (){
	/* Must be valid everywhere in the domain for a Dsp. */
	
	WPTR(XnRegion) 	returnValue;
	returnValue = this->coordinateSpace()->fullRegion();
	return returnValue;
}


RPTR(Mapping) Dsp::preCompose (APTR(Dsp) dsp){
	/* a->compose(b) is the same as b->preCompose(a).  Don't use it, use
		compose instead. */
	
	WPTR(Mapping) 	returnValue;
	returnValue = dsp->compose(this);
	return returnValue;
}


RPTR(XnRegion) Dsp::range (){
	WPTR(XnRegion) 	returnValue;
	returnValue = this->coordinateSpace()->fullRegion();
	return returnValue;
}


RPTR(ImmuSet) OF1(Mapping) Dsp::simpleMappings (){
	/* A Dsp is a simpleMapping already, so this just returns the 
	singleton set containing me */
	
	WPTR(ImmuSet) OF1(Mapping) 	returnValue;
	returnValue = ImmuSet::make ()->with(this);
	return returnValue;
}


RPTR(ImmuSet) OF1(Mapping) Dsp::simpleRegionMappings (){
	/* The domain of a Dsp is the simple region covering the 
	whole coordinate space, so
		I just return a singleton set containing myself */
	
	WPTR(ImmuSet) OF1(Mapping) 	returnValue;
	returnValue = ImmuSet::make ()->with(this);
	return returnValue;
}
/* combining */
/* transforming */
/* operations */


RPTR(Mapping) Dsp::restrictRange (APTR(XnRegion) region){
	WPTR(Mapping) 	returnValue;
	returnValue = SimpleMapping::restrictTo(this->inverseOfAll(region), this);
	return returnValue;
}
/* protected: */


RPTR(Mapping) Dsp::fetchCombine (APTR(Mapping) mapping){
	if (this->isEqual(mapping)) {
		return this;
	} else {
		return NULL;
	}
}
/* deferred transforming */


RPTR(Position) Dsp::inverseOf (APTR(Position) pos){
	/* Since Dsps always represent a unique mapping in either 
	direction, the permission to BLAST
		in the Mapping constract no longer applies.
		a->inverseOf(b) ->isEqual (a->inverse()->of(b)) */
	
	WPTR(Position) 	returnValue;
	returnValue = CAST(Dsp,this->inverse())->of(pos);
	return returnValue;
}


RPTR(XnRegion) Dsp::inverseOfAll (APTR(XnRegion) reg){
	/* Inverse transform a region.  A simple region must yield a 
	simple region.
		a->inverseOfAll(b) ->isEqual (a->inverseAll()->of(b)) */
	
	WPTR(XnRegion) 	returnValue;
	returnValue = CAST(Dsp,this->inverse())->ofAll(reg);
	return returnValue;
}


RPTR(Position) Dsp::of (APTR(Position) pos){
	/* Since Dsps always represent a unique mapping in either 
	direction, the permission to BLAST
		in the Mapping constract no longer applies. */
	
	WPTR(Position) 	returnValue;
	returnValue = this->ofAll(pos->asRegion())->theOne();
	return returnValue;
}
/* deferred combining */


RPTR(Dsp) Dsp::inverseCompose (APTR(Dsp) other){
	/* Return the composition of my inverse with the other.
		a->inverseCompose(b) ->isEqual (a->inverse()->compose(b)) */
	
	WPTR(Dsp) 	returnValue;
	returnValue = CAST(Dsp,this->inverse())->compose(other);
	return returnValue;
}

	/* automatic 0-argument constructor */
Dsp::Dsp() {}



/* ************************************************************************ *
 * 
 *                    Class OrderSpec 
 *
 * ************************************************************************ */


/* [documentation note: we need to hide the documentation about 
partial orders, but still warn that the orders may become partial]. 
An OrderSpec for a given coordinate space represents a partial 
ordering of all the Positions of that coordinate space.  The 
fundamental ordering relationship is "follows".  The response of 
Positions to isGE defines the natural, "ascending" partial order 
among the positions.  Every coordinate space will have at least this 
ascending and the corresponding descending OrderSpecs.  OrderSpecs 
are useful to specify in what order a stepper produced for stepping 
over positions should do so. */


/* testing */


UInt32 OrderSpec::actualHashForEqual (){
	return Heaper::takeOop();
}


OrderEnum OrderSpec::compare (APTR(Position) x, APTR(Position) y){
	/* Say what the relative ordering relationship is between x and y */
	
	if (this->follows(x, y)) {
		if (this->follows(y, x)) {
			return EQUAL;
		} else {
			return GREATER_THAN;
		}
	} else {
		if (this->follows(y, x)) {
			return LESS_THAN;
		} else {
			return INCOMPARABLE;
		}
	}
}


BooleanVar OrderSpec::followsInt (IntegerVar x, IntegerVar y){
	/* See discussion in XuInteger class comment about boxed vs 
	unboxed integers */
	
	return this->follows(IntegerPos::make (x), IntegerPos::make (y));
}
/* accessing */


RPTR(Arrangement) OrderSpec::arrange (APTR(XnRegion) region){
	/* Return an Arrangement of the positions in region according 
	to the ordering of the receiver. */
	
	WPTR(Arrangement) 	returnValue;
	returnValue = ExplicitArrangement::make (CAST(PtrArray,region->stepper(this)->stepMany()));
	return returnValue;
}


RPTR(OrderSpec) OrderSpec::reversed (){
	/* Returns an OrderSpec representing the mirror image of my ordering.
		o->follows(a, b) iff o->reverse()->follows(b, a) */
	
	WPTR(OrderSpec) 	returnValue;
	returnValue = ReverseOrder::make (this);
	return returnValue;
}

	/* automatic 0-argument constructor */
OrderSpec::OrderSpec() {}



/* ************************************************************************ *
 * 
 *                    Class Position 
 *
 * ************************************************************************ */


/* This is the superclass of all positions of coordinate spaces.  
Each individual position is specific to some one coordinate space.  
Positions themselves don't have much behavior, as most of the 
interesting aspects of coordinate spaces are defined in the other 
objects in terms of positions.  Positions do have their own native 
ordering messages, but for most purposes it's probably better to 
compare them using an appropriate OrderSpec. */


/* testing */


UInt32 Position::actualHashForEqual (){
	/* since we redefine equal, subclasses had better redefine 
	actualHashForEqual */
	
	return Heaper::takeOop();
}
/* accessing */

	/* automatic 0-argument constructor */
Position::Position() {}



/* ************************************************************************ *
 * 
 *                    Class XnRegion 
 *
 * ************************************************************************ */


/* pseudo constructors */


RPTR(ImmuSet) XnRegion::immuSet (APTR(XnRegion) region){
	/* Make a set containing all the positions in the region */
	
	if (!region->isFinite()) {
		BLAST(MustBeFinite);
	}
	WPTR(ImmuSet) 	returnValue;
	returnValue = MuSet::fromStepper(region->stepper())->asImmuSet();
	return returnValue;
}
/* The design of a new coordinate space consists mostly in the design 
of the XuRegions which can be used to describe (possibly infinite) 
sets of positions in that coordinate space.  It will generally not be 
the case (for a given coordinate space) that all mathematically 
describable sets of positions will be representable by an XuRegion in 
that space.  This should not be seen as a temporary deficiency of the 
current implementation of a space, but rather part of the design of 
what a given space *means*.  
	
	For example, in IntegerSpace, one cannot form the XuRegion whose 
members are exactly the even numbers.  If this were possible, other 
desirable properties which are part of the intent of IntegerSpaces 
would no longer be possible.  For example, any XuRegion should be 
able to break itself up into a finite number of simple XuRegions 
("simple" is described below).  Were an even number region possible, 
this would have undesirable consequences for the definition of 
"simple" in this space.  If you want (for example) to be able to have 
a XuRegion which can represent all the even numbers, it probably 
makes more sense to define a whole new space in which these new 
XuRegions apply.
	
	XuRegions should be closed under a large set of operations, such as 
intersection, unionWith, complement and minus.  ("closed" means that 
the result of performing this operation on XuRegions of a given space 
is another valid XuRegion in the same space.)  Additional guarantees 
are documented with each operation.
	
	A XuRegion may be classified at one of three levels of "simplicity":
	
	1) The simplest are the *distinctions*.  Distinctions are those that 
answer with (at most) a single set containing themselves in response 
to the message "distinctions".  (The reason I say "at most" is that a 
full region (one that covers the entire coordinate space) may answer 
with the empty set.)  Distinctions are the simplest XuRegions of a 
given space out of which all other XuRegions of that space can be 
finitely composed.  There should probably be a message 
"isDistinction" for which exactly the distinctions answer "true".  
The complement of a distinction is a distinction.  Three examples of 
distinctions in spaces are:
	
		a) in IntegerSpace, any simple inequality.  For example, all integers < 37.
		b) in one kind of 3-space, any half space (all the space on one 
side of some plane)
		c) in another kind of 3-space, any sphere or spherical hole.
		
	Note that "c" could not just have spheres as the distinction because 
distinctions must be closed under complement.  (We are here ignoring 
the quite substantial problems that arise in dealing with approximate 
(e.g., floating point) which would almost necessarily have to arise 
in doing any decent 3-space.  3-space is nevertheless a good intuition pump.)
	
	2) Next are the *simple regions*.  Simple regions are exactly those 
that say "true" to "isSimple".  All distinctions are also simple 
regions.  In response to the message "distinctions", and simple 
region must return a finite set of distinctions which, when 
intersected together, yield the original simple region.  Generally, 
one tries to define the simple regions for a space to correspond to 
some notion of locality in the space.  For example, it may be good 
for a simple region not to be able to have a hole in it.  Or perhaps 
a simple region is which must be connected (whatever that means in a 
given space).  Example non-distinction simple regions for the above 
example spaces would be:
	
		a) The interval from 3 inclusive to 17 exclusive (intersection of 
all integers >= 3 and all < 17)
		b) A convex hull (intersection of half spaces)
		c) Whatever you get by intersecting a bunch of spheres and sherical holes.
		
	The simple regions for both "a" and "b" would be connected, without 
holes, and even convex.  This follows directly from the definition of 
our distinctions.  None of these nice properties holds for "c", and 
this also follows directly from our decision to start with spheres.  
"c" is still perfectly valid, just less preferable by some criteria.
	
	3) Finally, there are the regions of a space in general.  Any region 
must respond to the message "simpleRegions" with a stepper which will 
produce a finite number of simple regions that, when unioned 
together, yields the original region.  A simple region will return a 
stepper that will return at most itself ("at most" because an empty 
region (which covers no positions) may return an empty stepper).  
Example non-simple regions are:
	
		a) all integers < 3 and all integers >= 17
		b) two convex hulls
		c) two disjoint spheres
		
	Note that "a" is the complement of the earlier "a" example, thereby 
showing why the complement of a simple region isn`t necessarily 
simple.  Even though the "c" space is so unconstrained in the 
properties of its simple regions, there is no way to interect a 
finite number of spheres and spherical holes to produce a pair of 
disjoint spheres.  Therefore the pair is non-simple.  Not all spaces 
must have non-simple regions (or even non-distinctions).  It is 
interesting to observe for "b" and "c" that even though there is a 
natural conversion between their respective positions, (except for 
the empty and full regions) there is no conversion at all between 
their respective regions.  The kinds of sets of positions 
representable in one space is completely different than those 
representable in the other space.
	
	We will use these three example spaces repeatedly in documenting the 
protocol. */


/* accessing */


RPTR(XnRegion) XnRegion::asSimpleRegion (){
	/* Return a simple region containing all positions contained 
	by myself. 
		If I am simple, then the result must be me.  Otherwise,
		the resulting region will contain more positions than I do, but it 
		must contain all those that I do.  It would be good for the resulting 
		simple region to not contain many more points than it needs in order 
		to satisfy these constraints; but this is a preference, not a 
		specification. Particular spaces may specify stronger guarantees, 
		but as far as class XuRegion is concerned it is correct 
	(though silly) 
		for this message to always return the full region for the space. */
	
	WPTR(XnRegion) 	returnValue;
	returnValue = this->simpleUnion(this);
	return returnValue;
}
/* operations */


RPTR(XnRegion) XnRegion::delta (APTR(XnRegion) region){
	/* The region where they differ.  
		a->delta(b) ->isEqual (a->minus(b)->unionWith(b->minus(a))) */
	
	WPTR(XnRegion) 	returnValue;
	returnValue = this->minus(region)->unionWith(region->minus(this));
	return returnValue;
}


RPTR(XnRegion) XnRegion::minus (APTR(XnRegion) other){
	/* The region containing all my position which aren't in other. */
	
	if (other->isEmpty()) {
		return this;
	} else {
		WPTR(XnRegion) 	returnValue;
		returnValue = this->intersect(other->complement());
		return returnValue;
	}
}


RPTR(XnRegion) XnRegion::with (APTR(Position) pos){
	/* the region with one more position. Actually, if I already 
	contain pos, then the result is just me. */
	
	WPTR(XnRegion) 	returnValue;
	returnValue = this->unionWith(pos->asRegion());
	return returnValue;
}


RPTR(XnRegion) XnRegion::without (APTR(Position) pos){
	/* the region with one less position. Actually if I already 
	don't contain pos, then the result is just me. */
	
	WPTR(XnRegion) 	returnValue;
	returnValue = this->minus(pos->asRegion());
	return returnValue;
}
/* testing */


UInt32 XnRegion::actualHashForEqual (){
	return Heaper::takeOop();
}


BooleanVar XnRegion::intersects (APTR(XnRegion) other){
	/* Essential.  tell whether it has any points in common */
	
	if (this->isEmpty()) {
		return FALSE;
	} else {
		if (other->isEmpty()) {
			return FALSE;
		} else {
			return !this->intersect(other)->isEmpty();
		}
	}
}


BooleanVar XnRegion::isDistinction (){
	/* Am I a distinction.  See XuRegion class comment for 
	implications of being a distinction. */
	
	{	BooleanVar crutch_Flag;
		/* this->isSimple() && this->distinctions()->count() <= 1 */
		
		crutch_Flag = this->isSimple();
		if(crutch_Flag) {
			crutch_Flag = this->distinctions()->count() <= 1;
		}
		return crutch_Flag;
	}
}


BooleanVar XnRegion::isFull (){
	/* true if this is the largest possible region in this space 
	-- the region that contains all positions in the space. Note 
	that in a space which has no positions (which is perfectly 
	valid), the one XuRegion would be both empty (since it has no 
	positions) and full (since it has all the positions in the space). */
	
	return this->complement()->isEmpty();
}


BooleanVar XnRegion::isSubsetOf (APTR(XnRegion) other){
	/* I'm a subset of other if I don't have any positions that 
	he doesn't. Note that if we are equal, then I am still a 
	subset of him. If you want to know if I'm a strict subset, you can ask 
		a->isSubsetOf(b) && ! a->isEqual(b) */
	
	return this->minus(other)->isEmpty();
}
/* enumerating */


RPTR(XnRegion) XnRegion::chooseMany (IntegerVar n, APTR(OrderSpec) order/* = NULL*/){
	/* If an OrderSpec is given, return the first n elements 
	according to that OrderSpec. If no OrderSpec is given, then 
	iff I contain at least n positions, return n of them; 
	otherwise BLAST. This should be implemented even by regions 
	that aren't enumerable.  Inspired by the axiom of choice. */
	
	BLAST(NOT_YET_IMPLEMENTED);
	/* fodder */
	return NULL;
}


RPTR(Position) XnRegion::chooseOne (APTR(OrderSpec) order/* = NULL*/){
	/* Essential.  If an OrderSpec is given, return the first 
	element according to that OrderSpec. If no OrderSpec is 
	given, then iff I contain at least one position, return one 
	of them; otherwise BLAST. This should be implemented even by 
	regions that aren't enumerable.  Inspired by the axiom of choice. */
	
	if (this->isEmpty()) {
		BLAST(EmptyRegion);
	}
	/* Thing to do !!!! */
	
	/* self isEnumerable assert: 'Must be overridden otherwise'. */
	return CAST(Position,this->stepper(order)->get());
}


RPTR(Stepper) OF1(Position) XnRegion::stepper (APTR(OrderSpec) order/* = NULL*/){
	/* Essential.  If my positions are enumerable in the order 
	specified, then return a stepper which will so enumerate 
	them. If 'order' is NULL, then I may treat this as a request 
	to enumerate according to any order I choose, except that if 
	I am enumerable in ascending order, then I must be enumerable 
	given NULL. For example, if I choose to regard NULL as 
	implying ascending order, and I am only enumerable in 
	descending order, then given NULL, I may blast even though 
	there is an order in which I am enumerable. 
		
		In fact, right now the ability to respond to an 'order' 
	argument is in such a to-be-implemented state that it should 
	only be considered safe to provide a NULL argument, unless 
	the documentation on a particular space or region says otherwise. 
		
		The eventual specification of this message is clear, and is 
	upwards compatible from the current behavior: If I can 
	enumerate in an order consistent with 'order', do so. If 
	'order' is NULL, then if I can be enumerated at all (if there 
	is any counting sequence), then I still do so. For example, I 
	should be able to get an (infinite) stepper for stepping 
	through all the integers, but not all the reals. As the above 
	example shows, being enumerable doesn't imply being finite.  
		
		Also, being able to produce a stepper that continues to 
	yield more positions in the specified order is not sufficient 
	to imply being enumerable.  To be enumerable, it must be the 
	case that any given position which is a member of the region 
	will eventually be reached by the stepper.  Not all 
	implementations currently succeed in guaranteeing this (See 
	UnionCrossRegion::isEnumerable).
		
		See ScruTable::stepper. */
	
	SPTR(OrderSpec) OR(NULL) ord;
	
	ord = order;
	if (ord == NULL) {
		ord = this->coordinateSpace()->fetchAscending();
	}
	if (ord == NULL) {
		BLAST(NotEnumerable);
	}
	WPTR(Stepper) OF1(Position) 	returnValue;
	returnValue = this->actualStepper(ord);
	return returnValue;
}


RPTR(Position) XnRegion::theOne (){
	/* Iff I contain exactly one position, return it.  Otherwise 
	BLAST. The idea for this message is taken from the THE 
	function of ONTIC (reference McAllester) */
	
	SPTR(Stepper) stepper;
	SPTR(Position) result;
	
	{	BooleanVar crutch_Flag;
		/* this->isFinite() && this->count() == 1 */
		
		crutch_Flag = this->isFinite();
		if(crutch_Flag) {
			crutch_Flag = this->count() == 1;
		}
		if (!crutch_Flag) {
			BLAST(NotOneElement);
		}
	}
	stepper = this->stepper();
	result = CAST(Position,stepper->fetch());
	{stepper->destroy();  stepper = NULL /* don't want stale (S/CHK)PTRs */;}
	WPTR(Position) 	returnValue;
	returnValue = result;
	return returnValue;
}
/* protected: enumerating */

	/* automatic 0-argument constructor */
XnRegion::XnRegion() {}



/* ************************************************************************ *
 * 
 *                    Class ExplicitArrangement 
 *
 * ************************************************************************ */


/* create */


RPTR(Arrangement) ExplicitArrangement::make (APTR(PtrArray) OF1(Position) positions){
	RETURN_CONSTRUCT(ExplicitArrangement,(positions, tcsj));
}
/* create */


ExplicitArrangement::ExplicitArrangement (APTR(PtrArray) OF1(Position) positions, TCSJ) {
	myPositions = positions;
}
/* accessing */


IntegerVar ExplicitArrangement::indexOf (APTR(Position) position){
	{
		Int32 LoopFinal = myPositions->count();
		Int32 i = Int32Zero;
		for (;;) {
			if (i >= LoopFinal){
				break;
			}
			{
				if (position->isEqual(myPositions->fetch(i))) {
					return i;
				}
			}
			i += 1;
		}
	}
	BLAST(NotFound);
	/* compiler fodder */
	return -1;
}


RPTR(IntegerRegion) ExplicitArrangement::indicesOf (APTR(XnRegion) region){
	SPTR(IntegerRegion) result;
	
	result = IntegerRegion::make ();
	{
		Int32 LoopFinal = myPositions->count();
		Int32 i = Int32Zero;
		for (;;) {
			if (i >= LoopFinal){
				break;
			}
			{
				if (region->hasMember(CAST(Position,myPositions->fetch(i)))) {
					result = CAST(IntegerRegion,result->with(IntegerPos::make (i)));
				}
			}
			i += 1;
		}
	}
	WPTR(IntegerRegion) 	returnValue;
	returnValue = result;
	return returnValue;
}


RPTR(XnRegion) ExplicitArrangement::keysOf (Int32 start, Int32 stop){
	SPTR(XnRegion) result;
	
	result = NULL;
	{
		Int32 LoopFinal = stop;
		Int32 i = start;
		for (;;) {
			if (i >= LoopFinal){
				break;
			}
			{
				if (result == NULL) {
					result = CAST(Position,myPositions->fetch(i))->asRegion();
				} else {
					result = result->with(CAST(Position,myPositions->fetch(i)));
				}
			}
			i += 1;
		}
	}
	if (result == NULL) {
		BLAST(IndexOutOfBounds);
	}
	WPTR(XnRegion) 	returnValue;
	returnValue = result;
	return returnValue;
}


RPTR(XnRegion) ExplicitArrangement::region (){
	SPTR(XnRegion) result;
	
	result = CAST(XnRegion,myPositions->get(Int32Zero));
	{
		Int32 LoopFinal = myPositions->count();
		Int32 i = 1;
		for (;;) {
			if (i >= LoopFinal){
				break;
			}
			{
				result = result->with(CAST(Position,myPositions->get(i)));
			}
			i += 1;
		}
	}
	WPTR(XnRegion) 	returnValue;
	returnValue = result;
	return returnValue;
}
/* testing */


UInt32 ExplicitArrangement::actualHashForEqual (){
	return myPositions->contentsHash();
}


UInt32 ExplicitArrangement::hashForEqual (){
	return myPositions->contentsHash();
}


BooleanVar ExplicitArrangement::isEqual (APTR(Heaper) other){
	BEGIN_CHOOSE(other) {
		BEGIN_KIND(ExplicitArrangement,o) {
			return myPositions->contentsEqual(o->positions());
		} END_KIND;
		BEGIN_OTHERS {
			return FALSE;
		} END_OTHERS;
	} END_CHOOSE;
	/* fodder */
	return FALSE;
}
/* private: accessing */


RPTR(PtrArray) ExplicitArrangement::positions (){
	return (PtrArray*) myPositions;
}



/* ************************************************************************ *
 * 
 *                    Class IdentityDsp 
 *
 * ************************************************************************ */



/* Initializers for IdentityDsp */

/* Initializers for IdentityDsp */
/* An implementation sharing convenience for Dsp classes which only 
provide the identity mapping functionality for their coordinate 
spaces.  This provides everything except the coordinate space itself 
(which must be provided by the subclass).  Will eventually be 
declared NOT_A_TYPE, so don't use it in type declarations.  
	
	Assumes that if a given space uses it as its identity Dsp, then the 
one cached instance will be the only identity Dsp for that space.  
I.e., I do equality comparison as an EQ object.  If this assumpsion 
isn't true, please override isEqual and hashForEqual.  See PathDsp.
	
	IdentityDsp is in module "unorder" because typically unordered 
spaces will only have an identity Dsp and so want to subclass this 
class.  Non-unordered spaces should also feel free to use this as 
appropriate. */


/* creation */


IdentityDsp::IdentityDsp () {
	
}
/* transforming */


RPTR(Position) IdentityDsp::inverseOf (APTR(Position) pos){
	WPTR(Position) 	returnValue;
	returnValue = pos;
	return returnValue;
}


RPTR(XnRegion) IdentityDsp::inverseOfAll (APTR(XnRegion) reg){
	WPTR(XnRegion) 	returnValue;
	returnValue = reg;
	return returnValue;
}


RPTR(Position) IdentityDsp::of (APTR(Position) pos){
	WPTR(Position) 	returnValue;
	returnValue = pos;
	return returnValue;
}


RPTR(XnRegion) IdentityDsp::ofAll (APTR(XnRegion) reg){
	WPTR(XnRegion) 	returnValue;
	returnValue = reg;
	return returnValue;
}
/* combining */


RPTR(Dsp) IdentityDsp::compose (APTR(Dsp) other){
	WPTR(Dsp) 	returnValue;
	returnValue = other;
	return returnValue;
}


RPTR(Mapping) IdentityDsp::inverse (){
	return this;
}


RPTR(Dsp) IdentityDsp::inverseCompose (APTR(Dsp) other){
	WPTR(Dsp) 	returnValue;
	returnValue = other;
	return returnValue;
}


RPTR(Dsp) IdentityDsp::minus (APTR(Dsp) other){
	return CAST(Dsp,other->inverse());
}
/* printing */


void IdentityDsp::printOn (ostream& oo){
	oo << this->getCategory()->name() << "(" << this->coordinateSpace() << ")";
}
/* accessing */


BooleanVar IdentityDsp::isIdentity (){
	return TRUE;
}
/* deferred accessing */
/* testing */


UInt32 IdentityDsp::actualHashForEqual (){
	return Heaper::takeOop();
}


BooleanVar IdentityDsp::isEqual (APTR(Heaper) other){
	return this == other;
}



/* ************************************************************************ *
 * 
 *                    Class MergeStepper 
 *
 * ************************************************************************ */


/* pseudoconstructors */


RPTR(Stepper) MergeStepper::make (
		APTR(Stepper) OF1(Position) a, 
		APTR(Stepper) OF1(Position) b, 
		APTR(OrderSpec) order)
{
	RETURN_CONSTRUCT(MergeStepper,(a, b, order, NULL));
}
/* A Stepper for doing a merge-sort like ordered interleaving of two 
other steppers.  It is assumed that the other two steppers are 
constructed so that their values are also produced in order according 
to the same OrderSpec.  A tree of these operates much like a heap as 
found in heapsort. */


/* operations */


RPTR(Stepper) MergeStepper::copy (){
	if (myValue == NULL) {
		WPTR(Stepper) 	returnValue;
		returnValue = Stepper::emptyStepper();
		return returnValue;
	}
	RETURN_CONSTRUCT(MergeStepper,(myA->copy(), myB->copy(), myOrder, myValue));
}


WPTR(Heaper) MergeStepper::fetch (){
	return (Position*) myValue;
}


BooleanVar MergeStepper::hasValue (){
	return myValue != NULL;
}


void MergeStepper::step (){
	SPTR(Position) a;
	SPTR(Position) b;
	
	a = CAST(Position,myA->fetch());
	b = CAST(Position,myB->fetch());
	if (a == NULL) {
		if (b == NULL) {
			myValue = NULL;
		} else {
			myValue = b;
			myB->step();
		}
	} else {
		if (b == NULL) {
			myValue = a;
			myA->step();
		} else {
			if (myOrder->follows(a, b)) {
				myValue = b;
				myB->step();
				if (a->isEqual(b)) {
					myA->step();
				}
			} else {
				myValue = a;
				myA->step();
				if (a->isEqual(b)) {
					myB->step();
				}
			}
		}
	}
}
/* private: creation */


MergeStepper::MergeStepper (
		APTR(Stepper) OF1(Position) a, 
		APTR(Stepper) OF1(Position) b, 
		APTR(OrderSpec) order, 
		APTR(Position) OR(NULL) value) 
{
	myA = a;
	myB = b;
	myOrder = order;
	myValue = value;
	if (value == NULL) {
		this->step();
	}
}



/* ************************************************************************ *
 * 
 *                    Class CompositeMapping 
 *
 * ************************************************************************ */


/* functions */


RPTR(Mapping) CompositeMapping::privateMakeMapping (
		APTR(CoordinateSpace) cs, 
		APTR(CoordinateSpace) rs, 
		APTR(ImmuSet) OF1(Mapping) mappings)
{
	if (mappings->isEmpty()) {
		WPTR(Mapping) 	returnValue;
		returnValue = EmptyMapping::make (cs, rs);
		return returnValue;
	} else {
		if (mappings->count() == 1) {
			return CAST(Mapping,mappings->theOne());
		} else {
			RETURN_CONSTRUCT(CompositeMapping,(cs, rs, mappings));
		}
	}
}


void CompositeMapping::storeMapping (APTR(Mapping) map, APTR(MuSet) OF1(Mapping) maps){
	/* store a map into the set, checking to see if it can be 
	combined with another */
	
	BEGIN_FOR_EACH(Mapping,each,(maps->stepper())) {
		SPTR(Mapping) combined;
		
		combined = map->fetchCombine(each);
		if (combined != NULL) {
			combined = each->fetchCombine(map);
		}
		if (combined != NULL) {
			maps->remove(each);
			maps->introduce(combined);
			return;
			
		}
	} END_FOR_EACH;
	maps->introduce(map);
}
/* operations */


RPTR(Mapping) CompositeMapping::appliedAfter (APTR(Dsp) dsp){
	SPTR(SetAccumulator) OF1(Mapping) result;
	
	result = SetAccumulator::make ();
	BEGIN_FOR_EACH(Mapping,each,(myMappings->stepper())) {
		result->step(each->appliedAfter(dsp));
	} END_FOR_EACH;
	WPTR(Mapping) 	returnValue;
	returnValue = CompositeMapping::privateMakeMapping(this->coordinateSpace(), this->rangeSpace(), CAST(ImmuSet,result->value()));
	return returnValue;
}


RPTR(Mapping) CompositeMapping::inverse (){
	SPTR(Mapping) result;
	
	/* Ravi -- Thing to do !!!! */
	
	/* can this be done more efficiently by taking advantage of 
		invariants? */
	result = Mapping::make (this->rangeSpace(), this->domainSpace());
	BEGIN_FOR_EACH(Mapping,sub,(myMappings->stepper())) {
		result = result->combine(sub->inverse());
	} END_FOR_EACH;
	WPTR(Mapping) 	returnValue;
	returnValue = result;
	return returnValue;
}


RPTR(Mapping) CompositeMapping::preCompose (APTR(Dsp) dsp){
	SPTR(SetAccumulator) OF1(Mapping) result;
	
	result = SetAccumulator::make ();
	BEGIN_FOR_EACH(Mapping,each,(myMappings->stepper())) {
		result->step(each->preCompose(dsp));
	} END_FOR_EACH;
	WPTR(Mapping) 	returnValue;
	returnValue = CompositeMapping::privateMakeMapping(this->coordinateSpace(), this->rangeSpace(), CAST(ImmuSet,result->value()));
	return returnValue;
}


RPTR(Mapping) CompositeMapping::restrict (APTR(XnRegion) region){
	SPTR(MuSet) OF1(Mapping) result;
	
	result = MuSet::make ();
	BEGIN_FOR_EACH(Mapping,each,(myMappings->stepper())) {
		SPTR(Mapping) restricted;
		
		restricted = each->restrict(region);
		if (!restricted->domain()->isEmpty()) {
			result->store(restricted);
		}
	} END_FOR_EACH;
	WPTR(Mapping) 	returnValue;
	returnValue = CompositeMapping::privateMakeMapping(this->coordinateSpace(), this->rangeSpace(), result->asImmuSet());
	return returnValue;
}


RPTR(Mapping) CompositeMapping::restrictRange (APTR(XnRegion) region){
	SPTR(MuSet) OF1(Mapping) result;
	
	result = MuSet::make ();
	BEGIN_FOR_EACH(Mapping,each,(myMappings->stepper())) {
		SPTR(Mapping) restricted;
		
		restricted = each->restrictRange(region);
		if (!restricted->domain()->isEmpty()) {
			result->store(restricted);
		}
	} END_FOR_EACH;
	WPTR(Mapping) 	returnValue;
	returnValue = CompositeMapping::privateMakeMapping(this->coordinateSpace(), this->rangeSpace(), result->asImmuSet());
	return returnValue;
}


RPTR(Mapping) CompositeMapping::transformedBy (APTR(Dsp) dsp){
	SPTR(SetAccumulator) OF1(Mapping) result;
	
	result = SetAccumulator::make ();
	BEGIN_FOR_EACH(Mapping,each,(myMappings->stepper())) {
		result->step(each->transformedBy(dsp));
	} END_FOR_EACH;
	WPTR(Mapping) 	returnValue;
	returnValue = CompositeMapping::privateMakeMapping(this->coordinateSpace(), this->rangeSpace(), CAST(ImmuSet,result->value()));
	return returnValue;
}
/* accessing */


RPTR(CoordinateSpace) CompositeMapping::coordinateSpace (){
	return (CoordinateSpace*) myCS;
}


RPTR(XnRegion) CompositeMapping::domain (){
	SPTR(XnRegion) result;
	
	result = this->coordinateSpace()->emptyRegion();
	BEGIN_FOR_EACH(Mapping,each,(myMappings->stepper())) {
		result = result->unionWith(each->domain());
	} END_FOR_EACH;
	WPTR(XnRegion) 	returnValue;
	returnValue = result;
	return returnValue;
}


RPTR(Dsp) OR(NULL) CompositeMapping::fetchDsp (){
	return NULL;
}


BooleanVar CompositeMapping::isComplete (){
	/* blast? */
	return FALSE;
}


BooleanVar CompositeMapping::isIdentity (){
	return FALSE;
}


RPTR(XnRegion) CompositeMapping::range (){
	SPTR(XnRegion) result;
	
	result = this->rangeSpace()->emptyRegion();
	BEGIN_FOR_EACH(Mapping,each,(myMappings->stepper())) {
		result = result->unionWith(each->range());
	} END_FOR_EACH;
	WPTR(XnRegion) 	returnValue;
	returnValue = result;
	return returnValue;
}


RPTR(CoordinateSpace) CompositeMapping::rangeSpace (){
	return (CoordinateSpace*) myRS;
}


RPTR(ImmuSet) OF1(Mapping) CompositeMapping::simpleMappings (){
	return (ImmuSet*) myMappings;
}


RPTR(ImmuSet) OF1(Mapping) CompositeMapping::simpleRegionMappings (){
	SPTR(MuSet) OF1(Mapping) simpleMappings;
	SPTR(Mapping) eachSimple;
	
	simpleMappings = MuSet::make ();
	BEGIN_FOR_EACH(Mapping,each,(myMappings->stepper())) {
		if (each->domain()->isSimple()) {
			simpleMappings->store(each);
		} else {
			BEGIN_FOR_EACH(XnRegion,simpleRegion,(each->domain()->simpleRegions())) {
				eachSimple = each->restrict(simpleRegion);
				simpleMappings->store(eachSimple);
			} END_FOR_EACH;
		}
	} END_FOR_EACH;
	WPTR(ImmuSet) OF1(Mapping) 	returnValue;
	returnValue = ImmuSet::make (simpleMappings);
	return returnValue;
}
/* transforming */


RPTR(Position) CompositeMapping::inverseOf (APTR(Position) pos){
	SPTR(Position) result;
	
	result = NULL;
	BEGIN_FOR_EACH(Mapping,each,(myMappings->stepper())) {
		if (each->range()->hasMember(pos)) {
			if (result == NULL) {
				result = each->inverseOf(pos);
			} else {
				BLAST(MultiplePreImages);
			}
		}
	} END_FOR_EACH;
	if (result == NULL) {
		BLAST(NotInRange);
	}
	WPTR(Position) 	returnValue;
	returnValue = result;
	return returnValue;
}


RPTR(XnRegion) CompositeMapping::inverseOfAll (APTR(XnRegion) reg){
	SPTR(XnRegion) result;
	
	result = this->coordinateSpace()->emptyRegion();
	BEGIN_FOR_EACH(Mapping,each,(myMappings->stepper())) {
		result = result->unionWith(each->inverseOfAll(reg));
	} END_FOR_EACH;
	WPTR(XnRegion) 	returnValue;
	returnValue = result;
	return returnValue;
}


RPTR(Position) CompositeMapping::of (APTR(Position) pos){
	SPTR(Position) result;
	
	result = NULL;
	BEGIN_FOR_EACH(Mapping,each,(myMappings->stepper())) {
		if (each->domain()->hasMember(pos)) {
			if (result == NULL) {
				result = each->of(pos);
			} else {
				BLAST(MultipleImages);
			}
		}
	} END_FOR_EACH;
	if (result == NULL) {
		BLAST(NotInDomain);
	}
	WPTR(Position) 	returnValue;
	returnValue = result;
	return returnValue;
}


RPTR(XnRegion) CompositeMapping::ofAll (APTR(XnRegion) reg){
	SPTR(XnRegion) result;
	
	result = this->rangeSpace()->emptyRegion();
	BEGIN_FOR_EACH(Mapping,each,(myMappings->stepper())) {
		result = result->unionWith(each->ofAll(reg));
	} END_FOR_EACH;
	WPTR(XnRegion) 	returnValue;
	returnValue = result;
	return returnValue;
}
/* printing */


void CompositeMapping::printOn (ostream& stream){
	stream << this->getCategory()->name();
	myMappings->printOnWithSimpleSyntax(stream, "(", ", ", ")");
}
/* private: private creation */


CompositeMapping::CompositeMapping (
		APTR(CoordinateSpace) cs, 
		APTR(CoordinateSpace) rs, 
		APTR(ImmuSet) OF1(Mapping) mappings) 
{
	myCS = cs;
	myRS = rs;
	myMappings = mappings;
}
/* testing */


UInt32 CompositeMapping::actualHashForEqual (){
	return cat_CompositeMapping->hashForEqual() ^ myMappings->hashForEqual();
}


BooleanVar CompositeMapping::isEqual (APTR(Heaper) other){
	BEGIN_CHOOSE(other) {
		BEGIN_KIND(CompositeMapping,cm) {
			return cm->simpleMappings()->isEqual(myMappings);
		} END_KIND;
		BEGIN_OTHERS {
			return FALSE;
		} END_OTHERS;
	} END_CHOOSE;
	/* fodder */
	return FALSE;
}
/* protected: protected */


RPTR(Mapping) CompositeMapping::fetchCombine (APTR(Mapping) mapping){
	if (mapping->isKindOf(cat_EmptyMapping)) {
		return this;
	} else {
		SPTR(MuSet) OF1(Mapping) result;
		
		result = myMappings->asMuSet();
		if (mapping->isKindOf(cat_CompositeMapping)) {
			BEGIN_FOR_EACH(Mapping,each,(mapping->simpleMappings()->stepper())) {
				CompositeMapping::storeMapping(each, result);
			} END_FOR_EACH;
		} else {
			CompositeMapping::storeMapping(mapping, result);
		}
		WPTR(Mapping) 	returnValue;
		returnValue = CompositeMapping::privateMakeMapping(myCS, myRS, result->asImmuSet());
		return returnValue;
	}
}



/* ************************************************************************ *
 * 
 *                    Class ConstantMapping 
 *
 * ************************************************************************ */


/* creation */


ConstantMapping::ConstantMapping (APTR(CoordinateSpace) cs, APTR(XnRegion) values) {
	myCoordinateSpace = cs;
	myValues = values;
}
/* transforming */


RPTR(Position) ConstantMapping::inverseOf (APTR(Position) /* pos */){
	BLAST(MultiplePreImages);
	return NULL;
}


RPTR(XnRegion) ConstantMapping::inverseOfAll (APTR(XnRegion) reg){
	if (reg->intersects(myValues)) {
		WPTR(XnRegion) 	returnValue;
		returnValue = this->domain();
		return returnValue;
	} else {
		WPTR(XnRegion) 	returnValue;
		returnValue = this->coordinateSpace()->emptyRegion();
		return returnValue;
	}
}


RPTR(Position) ConstantMapping::of (APTR(Position) /* pos */){
	{	BooleanVar crutch_Flag;
		/* myValues->isFinite() && myValues->count() == 1 */
		
		crutch_Flag = myValues->isFinite();
		if(crutch_Flag) {
			crutch_Flag = myValues->count() == 1;
		}
		if (crutch_Flag) {
			WPTR(Position) 	returnValue;
			returnValue = myValues->theOne();
			return returnValue;
		} else {
			BLAST(MultipleImages);
		}
	}
	/* fodder */
	return NULL;
}


RPTR(XnRegion) ConstantMapping::ofAll (APTR(XnRegion) reg){
	if (reg->isEmpty()) {
		WPTR(XnRegion) 	returnValue;
		returnValue = this->rangeSpace()->emptyRegion();
		return returnValue;
	} else {
		WPTR(XnRegion) 	returnValue;
		returnValue = this->range();
		return returnValue;
	}
}
/* accessing */


RPTR(Mapping) ConstantMapping::appliedAfter (APTR(Dsp) /* dsp */){
	return this;
}


RPTR(CoordinateSpace) ConstantMapping::coordinateSpace (){
	return (CoordinateSpace*) myCoordinateSpace;
}


RPTR(XnRegion) ConstantMapping::domain (){
	WPTR(XnRegion) 	returnValue;
	returnValue = myCoordinateSpace->fullRegion();
	return returnValue;
}


RPTR(Dsp) OR(NULL) ConstantMapping::fetchDsp (){
	return NULL;
}


BooleanVar ConstantMapping::isComplete (){
	return TRUE;
}


BooleanVar ConstantMapping::isIdentity (){
	return FALSE;
}


RPTR(Mapping) ConstantMapping::preCompose (APTR(Dsp) dsp){
	WPTR(Mapping) 	returnValue;
	returnValue = Mapping::make (myCoordinateSpace, dsp->ofAll(myValues));
	return returnValue;
}


RPTR(XnRegion) ConstantMapping::range (){
	return (XnRegion*) myValues;
}


RPTR(CoordinateSpace) ConstantMapping::rangeSpace (){
	WPTR(CoordinateSpace) 	returnValue;
	returnValue = myValues->coordinateSpace();
	return returnValue;
}


RPTR(ImmuSet) OF1(Mapping) ConstantMapping::simpleMappings (){
	WPTR(ImmuSet) OF1(Mapping) 	returnValue;
	returnValue = ImmuSet::make ()->with(this);
	return returnValue;
}


RPTR(ImmuSet) OF1(Mapping) ConstantMapping::simpleRegionMappings (){
	WPTR(ImmuSet) OF1(Mapping) 	returnValue;
	returnValue = ImmuSet::make ()->with(this);
	return returnValue;
}


RPTR(Mapping) ConstantMapping::transformedBy (APTR(Dsp) dsp){
	WPTR(Mapping) 	returnValue;
	returnValue = Mapping::make (myCoordinateSpace, dsp->ofAll(myValues));
	return returnValue;
}
/* printing */


void ConstantMapping::printOn (ostream& oo){
	oo << this->getCategory()->name() << "(" << myValues << ")";
}
/* testing */


UInt32 ConstantMapping::actualHashForEqual (){
	return myCoordinateSpace->hashForEqual() + myValues->hashForEqual();
}


BooleanVar ConstantMapping::isEqual (APTR(Heaper) other){
	BEGIN_CHOOSE(other) {
		BEGIN_KIND(ConstantMapping,cm) {
			{	BooleanVar crutch_Flag;
				/* cm->coordinateSpace()->isEqual(myCoordinateSpace) && cm->values()->isEqual(myValues) */
				
				crutch_Flag = cm->coordinateSpace()->isEqual(myCoordinateSpace);
				if(crutch_Flag) {
					crutch_Flag = cm->values()->isEqual(myValues);
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
/* private: private */


RPTR(XnRegion) ConstantMapping::values (){
	return (XnRegion*) myValues;
}
/* operations */


RPTR(Mapping) ConstantMapping::inverse (){
	WPTR(Mapping) 	returnValue;
	returnValue = Mapping::make (this->rangeSpace(), this->domainSpace()->fullRegion())->restrict(this->range());
	return returnValue;
}


RPTR(Mapping) ConstantMapping::restrict (APTR(XnRegion) region){
	WPTR(Mapping) 	returnValue;
	returnValue = SimpleMapping::restrictTo(region, this);
	return returnValue;
}


RPTR(Mapping) ConstantMapping::restrictRange (APTR(XnRegion) region){
	WPTR(Mapping) 	returnValue;
	returnValue = Mapping::make (myCoordinateSpace, myValues->intersect(region));
	return returnValue;
}
/* protected */


RPTR(Mapping) ConstantMapping::fetchCombine (APTR(Mapping) aMapping){
	BEGIN_CHOOSE(aMapping) {
		BEGIN_KIND(ConstantMapping,cm) {
			WPTR(Mapping) 	returnValue;
			returnValue = Mapping::make (this->coordinateSpace(), myValues->unionWith(cm->values()));
			return returnValue;
		} END_KIND;
		BEGIN_OTHERS {
			return NULL;
		} END_OTHERS;
	} END_CHOOSE;
	/* fodder */
	return NULL;
}



/* ************************************************************************ *
 * 
 *                    Class DisjointRegionStepper 
 *
 * ************************************************************************ */


/* instance creation */


RPTR(Stepper) DisjointRegionStepper::make (APTR(XnRegion) region, APTR(OrderSpec) order){
	RETURN_CONSTRUCT(DisjointRegionStepper,(region, order));
}
/* accessing */


WPTR(Heaper) DisjointRegionStepper::fetch (){
	return (XnRegion*) myValue;
}


BooleanVar DisjointRegionStepper::hasValue (){
	return myValue != NULL;
}


void DisjointRegionStepper::step (){
	myValue = CAST(XnRegion,myRegion->simpleRegions(myOrder)->fetch());
	if (myValue == NULL) {
		if (!myRegion->isEmpty()) {
			BLAST(RegionReturnedNullStepperEvenThoughNonEmpty);
		}
	} else {
		myRegion = myRegion->minus(myValue);
	}
}
/* instance creation */


RPTR(Stepper) DisjointRegionStepper::copy (){
	WPTR(Stepper) 	returnValue;
	returnValue = DisjointRegionStepper::make (myValue->unionWith(myRegion), myOrder);
	return returnValue;
}


DisjointRegionStepper::DisjointRegionStepper (APTR(XnRegion) region, APTR(OrderSpec) order) {
	myValue = NULL;
	myRegion = region;
	myOrder = order;
	if (!myRegion->isEmpty()) {
		this->step();
	}
}



/* ************************************************************************ *
 * 
 *                    Class EmptyMapping 
 *
 * ************************************************************************ */



/* Initializers for EmptyMapping */

GPTR(Mapping) EmptyMapping::LastEmptyMapping = NULL;
GPTR(CoordinateSpace) EmptyMapping::LastEmptyMappingCoordinateSpace = NULL;
GPTR(CoordinateSpace) EmptyMapping::LastEmptyMappingRangeSpace = NULL;


/* Initializers for EmptyMapping */



/* pseudoconstructor */


RPTR(Mapping) EmptyMapping::make (APTR(CoordinateSpace) cs, APTR(CoordinateSpace) rs){
	{	BooleanVar crutch_Flag;
		/* EmptyMapping::LastEmptyMapping == NULL || !cs->isEqual(EmptyMapping::LastEmptyMappingCoordinateSpace) || !rs->isEqual(EmptyMapping::LastEmptyMappingRangeSpace) */
		
		crutch_Flag = EmptyMapping::LastEmptyMapping == NULL;
		if(!crutch_Flag) {
			crutch_Flag = !cs->isEqual(EmptyMapping::LastEmptyMappingCoordinateSpace);
			if(!crutch_Flag) {
				crutch_Flag = !rs->isEqual(EmptyMapping::LastEmptyMappingRangeSpace);
			}
		}
		if (crutch_Flag) {
			EmptyMapping::LastEmptyMappingCoordinateSpace = cs;
			EmptyMapping::LastEmptyMappingRangeSpace = rs;
			CONSTRUCT(EmptyMapping::LastEmptyMapping,EmptyMapping,(cs, rs));
		}
	}
	WPTR(Mapping) 	returnValue;
	returnValue = EmptyMapping::LastEmptyMapping;
	return returnValue;
}
/* accessing */


RPTR(CoordinateSpace) EmptyMapping::coordinateSpace (){
	return (CoordinateSpace*) myCS;
}


RPTR(XnRegion) EmptyMapping::domain (){
	WPTR(XnRegion) 	returnValue;
	returnValue = this->coordinateSpace()->emptyRegion();
	return returnValue;
}


RPTR(Dsp) OR(NULL) EmptyMapping::fetchDsp (){
	return NULL;
}


BooleanVar EmptyMapping::isComplete (){
	return TRUE;
}


BooleanVar EmptyMapping::isIdentity (){
	return FALSE;
}


RPTR(XnRegion) EmptyMapping::range (){
	WPTR(XnRegion) 	returnValue;
	returnValue = this->rangeSpace()->emptyRegion();
	return returnValue;
}


RPTR(CoordinateSpace) EmptyMapping::rangeSpace (){
	return (CoordinateSpace*) myRS;
}


RPTR(ImmuSet) OF1(Mapping) EmptyMapping::simpleMappings (){
	WPTR(ImmuSet) OF1(Mapping) 	returnValue;
	returnValue = ImmuSet::make ();
	return returnValue;
}


RPTR(ImmuSet) OF1(Mapping) EmptyMapping::simpleRegionMappings (){
	WPTR(ImmuSet) OF1(Mapping) 	returnValue;
	returnValue = ImmuSet::make ()->with(this);
	return returnValue;
}
/* transforming */


RPTR(Position) EmptyMapping::inverseOf (APTR(Position) /* pos */){
	BLAST(NotInRange);
	return NULL;
}


RPTR(XnRegion) EmptyMapping::inverseOfAll (APTR(XnRegion) /* reg */){
	WPTR(XnRegion) 	returnValue;
	returnValue = this->coordinateSpace()->emptyRegion();
	return returnValue;
}


RPTR(Position) EmptyMapping::of (APTR(Position) /* pos */){
	BLAST(NotInDomain);
	return NULL;
}


RPTR(XnRegion) EmptyMapping::ofAll (APTR(XnRegion) /* reg */){
	WPTR(XnRegion) 	returnValue;
	returnValue = this->rangeSpace()->emptyRegion();
	return returnValue;
}
/* private: private creation */


EmptyMapping::EmptyMapping (APTR(CoordinateSpace) cs, APTR(CoordinateSpace) rs) {
	myCS = cs;
	myRS = rs;
}
/* printing */


void EmptyMapping::printOn (ostream& stream){
	stream << this->getCategory()->name();
	stream << "()";
}
/* testing */


UInt32 EmptyMapping::actualHashForEqual (){
	return cat_EmptyMapping->hashForEqual();
}


BooleanVar EmptyMapping::isEqual (APTR(Heaper) other){
	/* This, and the CompositeMapping version, don't check 
	CoordinateSpaces.  Should they? */
	
	return other->isKindOf(cat_EmptyMapping);
}
/* operations */


RPTR(Mapping) EmptyMapping::appliedAfter (APTR(Dsp) /* dsp */){
	return this;
}


RPTR(Mapping) EmptyMapping::inverse (){
	WPTR(Mapping) 	returnValue;
	returnValue = Mapping::make (this->rangeSpace(), this->domainSpace());
	return returnValue;
}


RPTR(Mapping) EmptyMapping::preCompose (APTR(Dsp) /* dsp */){
	return this;
}


RPTR(Mapping) EmptyMapping::restrict (APTR(XnRegion) /* region */){
	return this;
}


RPTR(Mapping) EmptyMapping::restrictRange (APTR(XnRegion) /* region */){
	return this;
}


RPTR(Mapping) EmptyMapping::transformedBy (APTR(Dsp) /* dsp */){
	return this;
}
/* protected: protected */


RPTR(Mapping) EmptyMapping::fetchCombine (APTR(Mapping) mapping){
	WPTR(Mapping) 	returnValue;
	returnValue = mapping;
	return returnValue;
}



/* ************************************************************************ *
 * 
 *                    Class ReverseOrder 
 *
 * ************************************************************************ */


/* pseudoconstructors */


RPTR(OrderSpec) ReverseOrder::make (APTR(OrderSpec) order){
	RETURN_CONSTRUCT(ReverseOrder,(order, tcsj));
}
/* accessing */


RPTR(CoordinateSpace) ReverseOrder::coordinateSpace (){
	WPTR(CoordinateSpace) 	returnValue;
	returnValue = myOrder->coordinateSpace();
	return returnValue;
}


RPTR(OrderSpec) ReverseOrder::reversed (){
	return (OrderSpec*) myOrder;
}
/* testing */


UInt32 ReverseOrder::actualHashForEqual (){
	return myOrder->hashForEqual() ^ -1;
}


BooleanVar ReverseOrder::follows (APTR(Position) x, APTR(Position) y){
	return myOrder->follows(y, x);
}


BooleanVar ReverseOrder::followsInt (IntegerVar x, IntegerVar y){
	return myOrder->followsInt(y, x);
}


BooleanVar ReverseOrder::isEqual (APTR(Heaper) other){
	BEGIN_CHOOSE(other) {
		BEGIN_KIND(OrderSpec,os) {
			return myOrder->isEqual(os->reversed());
		} END_KIND;
		BEGIN_OTHERS {
			return FALSE;
		} END_OTHERS;
	} END_CHOOSE;
	/* fodder */
	return FALSE;
}


BooleanVar ReverseOrder::isFullOrder (APTR(XnRegion) keys/* = NULL*/){
	return myOrder->isFullOrder(keys);
}


BooleanVar ReverseOrder::preceeds (APTR(XnRegion) before, APTR(XnRegion) after){
	/* Return true if some position in before is less than or 
	equal to all positions in after. */
	
	BLAST(NOT_YET_IMPLEMENTED);
	return FALSE;
}
/* private: creation */


ReverseOrder::ReverseOrder (APTR(OrderSpec) order, TCSJ) {
	myOrder = order;
}



/* ************************************************************************ *
 * 
 *                    Class SimpleMapping 
 *
 * ************************************************************************ */


/* pseudo constructors */


RPTR(Mapping) SimpleMapping::restrictTo (APTR(XnRegion) region, APTR(Mapping) mapping){
	if (region->isEmpty()) {
		WPTR(Mapping) 	returnValue;
		returnValue = EmptyMapping::make (mapping->domainSpace(), mapping->rangeSpace());
		return returnValue;
	} else {
		RETURN_CONSTRUCT(SimpleMapping,(region, mapping));
	}
}
/* accessing */


RPTR(Mapping) SimpleMapping::appliedAfter (APTR(Dsp) dsp){
	WPTR(Mapping) 	returnValue;
	returnValue = SimpleMapping::restrictTo(dsp->inverseOfAll(myRegion), myMapping->appliedAfter(dsp));
	return returnValue;
}


RPTR(CoordinateSpace) SimpleMapping::coordinateSpace (){
	WPTR(CoordinateSpace) 	returnValue;
	returnValue = myRegion->coordinateSpace();
	return returnValue;
}


RPTR(XnRegion) SimpleMapping::domain (){
	return (XnRegion*) myRegion;
}


RPTR(Dsp) OR(NULL) SimpleMapping::fetchDsp (){
	WPTR(Dsp) OR(NULL) 	returnValue;
	returnValue = myMapping->fetchDsp();
	return returnValue;
}


BooleanVar SimpleMapping::isComplete (){
	return myMapping->isComplete();
}


BooleanVar SimpleMapping::isIdentity (){
	return FALSE;
}


RPTR(Mapping) SimpleMapping::preCompose (APTR(Dsp) dsp){
	WPTR(Mapping) 	returnValue;
	returnValue = SimpleMapping::restrictTo(myRegion, myMapping->preCompose(dsp));
	return returnValue;
}


RPTR(XnRegion) SimpleMapping::range (){
	WPTR(XnRegion) 	returnValue;
	returnValue = myMapping->ofAll(myRegion);
	return returnValue;
}


RPTR(CoordinateSpace) SimpleMapping::rangeSpace (){
	WPTR(CoordinateSpace) 	returnValue;
	returnValue = myMapping->rangeSpace();
	return returnValue;
}


RPTR(ImmuSet) OF1(Mapping) SimpleMapping::simpleMappings (){
	WPTR(ImmuSet) OF1(Mapping) 	returnValue;
	returnValue = ImmuSet::make ()->with(this);
	return returnValue;
}


RPTR(ImmuSet) OF1(Mapping) SimpleMapping::simpleRegionMappings (){
	if (myMapping->domain()->isSimple()) {
		WPTR(ImmuSet) OF1(Mapping) 	returnValue;
		returnValue = ImmuSet::make ()->with(myMapping);
		return returnValue;
	} else {
		SPTR(MuSet) simpleMappings;
		
		simpleMappings = MuSet::make ();
		BEGIN_FOR_EACH(XnRegion,simpleRegion,(myMapping->domain()->simpleRegions())) {
			simpleMappings->store(myMapping->restrict(simpleRegion));
		} END_FOR_EACH;
		WPTR(ImmuSet) OF1(Mapping) 	returnValue;
		returnValue = ImmuSet::make (simpleMappings);
		return returnValue;
	}
}


RPTR(Mapping) SimpleMapping::transformedBy (APTR(Dsp) dsp){
	WPTR(Mapping) 	returnValue;
	returnValue = SimpleMapping::restrictTo(myRegion, myMapping->transformedBy(dsp));
	return returnValue;
}
/* transforming */


RPTR(Position) SimpleMapping::inverseOf (APTR(Position) pos){
	SPTR(Position) result;
	
	result = myMapping->inverseOf(pos);
	if (myRegion->hasMember(result)) {
		WPTR(Position) 	returnValue;
		returnValue = result;
		return returnValue;
	} else {
		BLAST(NotInRange);
	}
	/* fodder */
	return NULL;
}


RPTR(XnRegion) SimpleMapping::inverseOfAll (APTR(XnRegion) reg){
	WPTR(XnRegion) 	returnValue;
	returnValue = myMapping->inverseOfAll(reg)->intersect(myRegion);
	return returnValue;
}


RPTR(Position) SimpleMapping::of (APTR(Position) pos){
	if (this->domain()->hasMember(pos)) {
		WPTR(Position) 	returnValue;
		returnValue = myMapping->of(pos);
		return returnValue;
	} else {
		BLAST(NotInDomain);
	}
	/* fodder */
	return NULL;
}


RPTR(XnRegion) SimpleMapping::ofAll (APTR(XnRegion) reg){
	WPTR(XnRegion) 	returnValue;
	returnValue = myMapping->ofAll(this->domain()->intersect(reg));
	return returnValue;
}
/* operations */


RPTR(Mapping) SimpleMapping::inverse (){
	WPTR(Mapping) 	returnValue;
	returnValue = myMapping->inverse()->restrictRange(myRegion);
	return returnValue;
}


RPTR(Mapping) SimpleMapping::restrict (APTR(XnRegion) region){
	WPTR(Mapping) 	returnValue;
	returnValue = SimpleMapping::restrictTo(myRegion->intersect(region), myMapping);
	return returnValue;
}


RPTR(Mapping) SimpleMapping::restrictRange (APTR(XnRegion) region){
	WPTR(Mapping) 	returnValue;
	returnValue = SimpleMapping::restrictTo(myRegion, myMapping->restrictRange(region));
	return returnValue;
}
/* printing */


void SimpleMapping::printOn (ostream& oo){
	oo << myMapping << " on " << myRegion;
}
/* private: private creation */


SimpleMapping::SimpleMapping (APTR(XnRegion) region, APTR(Mapping) mapping) {
	myRegion = region;
	myMapping = mapping;
}
/* testing */


UInt32 SimpleMapping::actualHashForEqual (){
	return myRegion->hashForEqual() + myMapping->hashForEqual();
}


BooleanVar SimpleMapping::isEqual (APTR(Heaper) other){
	BEGIN_CHOOSE(other) {
		BEGIN_KIND(SimpleMapping,sm) {
			{	BooleanVar crutch_Flag;
				/* sm->domain()->isEqual(myRegion) && sm->mapping()->isEqual(myMapping) */
				
				crutch_Flag = sm->domain()->isEqual(myRegion);
				if(crutch_Flag) {
					crutch_Flag = sm->mapping()->isEqual(myMapping);
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
/* private: private */


RPTR(Mapping) SimpleMapping::mapping (){
	return (Mapping*) myMapping;
}
/* protected */


RPTR(Mapping) SimpleMapping::fetchCombine (APTR(Mapping) mapping){
	if (mapping->isEqual(myMapping)) {
		WPTR(Mapping) 	returnValue;
		returnValue = mapping;
		return returnValue;
	}
	BEGIN_CHOOSE(mapping) {
		BEGIN_KIND(SimpleMapping,other) {
			SPTR(Mapping) both;
			
			if (other->mapping()->isEqual(myMapping)) {
				WPTR(Mapping) 	returnValue;
				returnValue = SimpleMapping::restrictTo(other->domain()->unionWith(myRegion), myMapping);
				return returnValue;
			} else {
				{	BooleanVar crutch_Flag;
					/* other->domain()->isEqual(myRegion) && (both = myMapping->fetchCombine(other->mapping())) != NULL */
					
					crutch_Flag = other->domain()->isEqual(myRegion);
					if(crutch_Flag) {
						crutch_Flag = (both = myMapping->fetchCombine(other->mapping())) != NULL;
					}
					if (crutch_Flag) {
						WPTR(Mapping) 	returnValue;
						returnValue = SimpleMapping::restrictTo(myRegion, both);
						return returnValue;
					}
				}
			}
		} END_KIND;
		BEGIN_OTHERS {
			
		} END_OTHERS;
	} END_CHOOSE;
	return NULL;
}

#ifndef SPACEX_SXX
#include "spacex.sxx"
#endif /* SPACEX_SXX */


#ifndef SPACER_SXX
#include "spacer.sxx"
#endif /* SPACER_SXX */


#ifndef SPACEP_SXX
#include "spacep.sxx"
#endif /* SPACEP_SXX */



#endif /* SPACEX_CXX */

