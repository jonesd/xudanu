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

#ifndef SPACEX_HXX
#define SPACEX_HXX


#ifndef TOFUX_HXX
#include "tofux.hxx"
#endif /* TOFUX_HXX */

#ifndef INTVARX_HXX
#include "intvarx.hxx"
#endif /* INTVARX_HXX */

#ifndef SPACEX_OXX
#include "spacex.oxx"
#endif /* SPACEX_OXX */


#ifndef INITX_HXX
#include "initx.hxx"
#endif /* INITX_HXX */


#ifndef INTEGERX_OXX
#include "integerx.oxx"
#endif /* INTEGERX_OXX */

#ifndef PARRAYX_OXX
#include "parrayx.oxx"
#endif /* PARRAYX_OXX */

#ifndef SETX_OXX
#include "setx.oxx"
#endif /* SETX_OXX */

#ifndef STEPPERX_OXX
#include "stepperx.oxx"
#endif /* STEPPERX_OXX */


/*  */
/*  */
/* xpp class */

typedef enum { LESS_THAN, EQUAL, GREATER_THAN, INCOMPARABLE }
	OrderEnum;



/* ************************************************************************ *
 * 
 *                    Class Arrangement 
 *
 * ************************************************************************ */




	/* Generally represents a pair of an OrderSpec and a Region.  
	Arrangements map between regions and primArrays. */

class Arrangement : public Heaper {

/* Attributes for class Arrangement */
	DEFERRED(Arrangement)
	COPY(Arrangement,XppCuisine)
	NO_GC(Arrangement)
  public: /* accessing */

	/* Copy elements into toArray arranged according to the receiver. 
		 Copy them from fromArray arranged according to fromArrange.  
		 The source region is fromRegion.  It gets tranformed by toDsp
		 into the toArray. */
	
	virtual void copyElements (
			APTR(PrimArray) ARG(toArray), 
			APTR(Dsp) ARG(toDsp), 
			APTR(PrimArray) ARG(fromArray), 
			APTR(Arrangement) ARG(fromArrange), 
			APTR(XnRegion) ARG(fromRegion))
	;
	
	/* Return the index of position into my Region according to 
	my OrderSpec. */
	
	virtual IntegerVar indexOf (APTR(Position) ARG(position)) DEFERRED_FUNC;
	
	/* Return the region of all the indices corresponding to 
	positions in region. */
	
	virtual RPTR(IntegerRegion) indicesOf (APTR(XnRegion) ARG(region)) DEFERRED_FUNC;
	
	/* Return the region that corresponds to a range of indices. */
	
	virtual RPTR(XnRegion) keysOf (Int32 ARG(start), Int32 ARG(stop)) DEFERRED_FUNC;
	
	/* The region of positions in the arrangement */
	
	virtual RPTR(XnRegion) region () DEFERRED_FUNC;
	
  public: /* testing */

	
	virtual UInt32 actualHashForEqual ();
	

	/* automatic 0-argument constructor */
  public:
	Arrangement();

};  /* end class Arrangement */



/* ************************************************************************ *
 * 
 *                    Class CoordinateSpace 
 *
 * ************************************************************************ */




	/* A coordinate space represents (among other things) the 
	domain space of a table. Corresponding to each coordinate 
	space will be a set of objects of the following kinds:
		
		Position -- The elements of the coordinate space.
		Mapping -- (Add a description.)
		OrderSpec -- The ways of specifying partial orders of this 
	coordinate space's Positions.
		XuRegion -- An XuRegion represents a set of Positions.  The 
	domain of a table is an XuRegion.
		
		When defining a new coordinate space class, one generally 
	defines new corresponing subclasses of each of the above 
	classes.  A kind of any of the above classes knows what 
	coordinate space it is a part of (the "coordinateSpace()" 
	message will yield an appropriate kind of CoordinateSpace).  
	CoordinateSpace objects exist mostly just to represent this 
	commonality.  Coordinate spaces are disjoint--it is an error 
	to use any of the generic protocol of any of the above 
	classes if the objects in question are of two different 
	coordinate spaces.  For example, "dsp->of (pos)" is not an 
	error iff "dsp->coordinateSpace()->isEqual (pos->coordinateSpace())".
		
	Note that this class is not COPY or even PSEUDO_COPY.  All of 
	the instance variables for CoordinateSpace are basically cached
	quantities that require vary little actual state from the 
	derived classes in order to be constructed.  This realization 
	allows a knot
	to be untangled when reading these objects from external storage. */

class CoordinateSpace : public Heaper {

/* Attributes for class CoordinateSpace */
	DEFERRED(CoordinateSpace)
	ON_CLIENT(CoordinateSpace)
	AUTO_GC(CoordinateSpace)
  public: /* accessing */

	
	virtual UInt32 actualHashForEqual ();
	
	/* Essential.  The natural full-ordering of the coordinate space. */
	
	INLINE CLIENT RPTR(OrderSpec) ascending ();
	
	/* Essential. A Mapping which maps each position in this 
	space to every position in the range region. The region can 
	be from any CoordinateSpace. */
	
	INLINE CLIENT RPTR(Mapping) completeMapping (APTR(XnRegion) ARG(range));
	
	/* The mirror image of the partial order returned by 
	'CoordinateSpace::ascending'. */
	
	INLINE CLIENT RPTR(OrderSpec) descending ();
	
	/* Essential.  An empty region in this coordinate space */
	
	INLINE CLIENT RPTR(XnRegion) emptyRegion ();
	
	/* The natural full-ordering of the coordinate space. */
	
	INLINE RPTR(OrderSpec) OR(NULL) fetchAscending ();
	
	/* The mirror image of the partial order returned by 
		'CoordinateSpace::fetchAscending'. */
	
	INLINE RPTR(OrderSpec) OR(NULL) fetchDescending ();
	
	/* A full region in this coordinate space */
	
	INLINE CLIENT RPTR(XnRegion) fullRegion ();
	
	/* Essential.  The natural full-ordering of the coordinate space. */
	
	virtual RPTR(OrderSpec) getAscending ();
	
	/* The mirror image of the partial order returned by 
	'CoordinateSpace::getAscending'. */
	
	virtual RPTR(OrderSpec) getDescending ();
	
	/* A Dsp which maps all positions in the coordinate space 
	onto themselves */
	
	INLINE RPTR(Dsp) identityDsp ();
	
	/* Essential.  A Mapping which maps all positions in the 
	coordinate space onto themselves */
	
	INLINE CLIENT RPTR(Mapping) identityMapping ();
	
	
	virtual BooleanVar isEqual (APTR(Heaper) ARG(other)) DEFERRED_FUNC;
	
	/* tell whether this is a valid Position/XuRegion/Dsp/OrderSpe
	c for this space */
	
	virtual BooleanVar verify (APTR(Heaper) ARG(thing));
	
  protected: /* protected: create followup */

	
	virtual void finishCreate (
			APTR(XnRegion) ARG(emptyRegion), 
			APTR(XnRegion) ARG(fullRegion), 
			APTR(Dsp) ARG(identityDsp), 
			APTR(OrderSpec) ARG(ascending) = NULL, 
			APTR(OrderSpec) ARG(descending) = NULL)
	;
	
  public: /* create */

	
	CoordinateSpace ();
	
	
	CoordinateSpace (
			APTR(XnRegion) ARG(emptyRegion), 
			APTR(XnRegion) ARG(fullRegion), 
			APTR(Dsp) ARG(identityDsp), 
			APTR(OrderSpec) ARG(ascending) = NULL, 
			APTR(OrderSpec) ARG(descending) = NULL)
	;
	
  private:
	CHKPTR(XnRegion) myEmptyRegion;
	CHKPTR(XnRegion) myFullRegion;
	CHKPTR(Dsp) myIdentityDsp;
	CHKPTR(OrderSpec) OR(NULL) myAscending;
	CHKPTR(OrderSpec) OR(NULL) myDescending;
};  /* end class CoordinateSpace */



/* ************************************************************************ *
 * 
 *                    Class Mapping 
 *
 * ************************************************************************ */




	/* A mapping is a general mapping from one coordinate space 
	to another, with few of the guarantees provided by Dsps.  In 
	particular, the source and destination coordinate spaces can 
	be different, and the mapping doesn't have to be everywhere 
	defined (but it has to say where it is defined via "domain" 
	and "range" messages).  A mapping doesn't have to be 
	unique--the same domain position may map to multiple range 
	positions and vice versa.  A mapping of a XuRegion must yield 
	another XuRegion, but a mapping of a simple region doesn't 
	have to yield a simple region.
		
		A useful and valid way to think of a Mapping is as a 
	(possibly infinite) set of pairs (a mathematical set, not a 
	ScruSet).  The domain region consists of the first elements 
	of each pair, and the range region consists of the second elements.
		
		A mapping is most useful as a representation of a version 
	comparison of two different organizations of common elements. 
	 The mapping would tell how positions in one organization 
	correspond to positions in the other. */

class Mapping : public Heaper {

/* Attributes for class Mapping */
	DEFERRED(Mapping)
	ON_CLIENT(Mapping)
	NO_GC(Mapping)
  public: /* pseudo constructors */

	/* Make an empty mapping from cs to rs. The domain will consist of an 
		empty region in cs, and the range will consist of an empty 
	region in rs */
	
	static INLINE RPTR(Mapping) make (APTR(CoordinateSpace) ARG(cs), APTR(CoordinateSpace) ARG(rs));
	
	/* Make a constant mapping from all positions in cs to all 
	positions in values. */
	
	static RPTR(Mapping) make (APTR(CoordinateSpace) ARG(cs), APTR(XnRegion) ARG(values));
	
	/* The combine of all the mappings in 'mappings'  All domains must be 
		in cs and all ranges in rs.  cs and rs must be provided in case 
		'mappings' is empty. */
	
	static RPTR(Mapping) make (
			APTR(CoordinateSpace) ARG(cs), 
			APTR(CoordinateSpace) ARG(rs), 
			APTR(ImmuSet) OF1(Mapping) ARG(mappings))
	;
	
  public: /* accessing */

	/* the coordinate space of the domain of the Mapping */
	
	virtual RPTR(CoordinateSpace) coordinateSpace () DEFERRED_FUNC;
	
	/* Essential.  region in which it is valid. */
	
	virtual CLIENT RPTR(XnRegion) domain () DEFERRED_FUNC;
	
	/* The coordinate space of the domain of the Mapping */
	
	INLINE CLIENT RPTR(CoordinateSpace) domainSpace ();
	
	/* if this is a Dsp or a Dsp retricted to some domain, return 
	the underlying Dsp.  Otherwise NULL. */
	
	virtual RPTR(Dsp) OR(NULL) fetchDsp () DEFERRED_FUNC;
	
	/* Essential. Return true if each Position in the domain is 
	mapped to every Position in the range. */
	
	virtual CLIENT BooleanVar isComplete () DEFERRED_FUNC;
	
	/* Essential. True if this is the identify mapping on the 
	entire space. */
	
	virtual CLIENT BooleanVar isIdentity () DEFERRED_FUNC;
	
	/* Essential.  region in which inverse is valid.  Same as the 
	region that the domain region maps to. For you 
	mathematicians, it is the image of the domain under the mapping. */
	
	virtual CLIENT RPTR(XnRegion) range () DEFERRED_FUNC;
	
	/* The coordinate space of the range of the transformation */
	
	virtual CLIENT RPTR(CoordinateSpace) rangeSpace () DEFERRED_FUNC;
	
	/* return a set of simple mappings that would combine to this one */
	
	virtual RPTR(ImmuSet) OF1(Mapping) simpleMappings () DEFERRED_FUNC;
	
	/* return a set of mappings with simple regions as their 
	domains that would combine 
		to this one. */
	
	virtual RPTR(ImmuSet) OF1(Mapping) simpleRegionMappings () DEFERRED_FUNC;
	
	/* Essential. Break this Mapping up into simpler Mappings 
	which can be combined together to get this one. */
	
	virtual CLIENT RPTR(Stepper) OF1(Mapping) simplerMappings ();
	
	/* Essential. If this is a 'simpler' Mapping, and not isFull, 
	then return a yet simpleMapping of some class from which you 
	can get more information. Note that m->restrict 
	(region)->unrestricted () is not necessarily the same as m, 
	since information may be lost. */
	
	virtual CLIENT RPTR(Mapping) unrestricted ();
	
  public: /* mapping */

	/* Inverse transform a position.  Must BLAST if there isn't a 
	unique inverse.
		'a->isEqual (this->of (b))' iff 'b->isEqual (this->inverseOf (a))'. */
	
	virtual RPTR(Position) inverseOf (APTR(Position) ARG(after)) DEFERRED_FUNC;
	
	/* Inverse transform of a region.
		'a->isEqual (this->of (b))' iff 'b->isEqual (this->inverseOf (a))'. */
	
	virtual RPTR(XnRegion) inverseOfAll (APTR(XnRegion) ARG(after)) DEFERRED_FUNC;
	
	/* Unboxed version of 'this->inverseOf (xuInteger(pos))'. See 
		discussion in the XuInteger class comment about boxed and unboxed 
		protocols */
	
	virtual IntegerVar inverseOfInt (IntegerVar ARG(pos));
	
	/* Transform a position. 'before' must be a Position of my 
	domain space. Iff 'before' is in the domain region over which 
	I am defined and it maps to a unique range Position then the 
	result will be that Position. Otherwise BLAST. For example, 
	if I map 1 to 4, 1 to 5, and 2 to 5 (and nothing else), then 
	this method will yield 5 given 2, but BLAST given anything 
	else. To find all the values 1 maps to, use the 'ofAll' 
	operation on the singleton region whose member is 1. */
	
	virtual CLIENT RPTR(Position) of (APTR(Position) ARG(before)) DEFERRED_FUNC;
	
	/* Essential.  Transform a region. The result region has 
	exactly those positions which are the mappings of the 
	positions in 'before'. This must be the case even if these 
	positions cannot be enumerated. If the mapping for a given 
	position is multiply defined, then (if that position is in 
	'before') all position it maps to must be in the result. 
	Because of this property, the behavior of this method must be 
	taken as really defining the nature of a particular mapping 
	(with other method's behavior being defined in terms of this 
	one), despite the fact that it would have been more natural 
	to take Mapping::of(Position *) as the defining behavior. */
	
	virtual CLIENT RPTR(XnRegion) ofAll (APTR(XnRegion) ARG(before)) DEFERRED_FUNC;
	
	/* Unboxed version of 'this->of (xuInteger(pos))'.  See 
	discussion in the XuInteger class 
		comment about boxed and unboxed protocols */
	
	virtual IntegerVar ofInt (IntegerVar ARG(pos));
	
  public: /* operations */

	/* Defined by the equivalence:
			M->transformedBy(D)->of(R) isEqual (M->of(D->of(R)))
		for all regions R in the domainSpace of M. Equivalent to 
	Dsp::compose, except that it is between a Mapping and a Dsp. */
	
	virtual RPTR(Mapping) appliedAfter (APTR(Dsp) ARG(dsp)) DEFERRED_FUNC;
	
	/* Essential.  Result will do both mine and other's mappings. 
	 It will do my mapping where I am defined, and it will do the 
	other's where his is defined.  If we are both defined over 
	some domain positions, then the result is a multi-valued 
	mapping.  If you think of a Mapping simply as a set of pairs 
	(see class comment), then 'combine' yields a Mapping 
	consisting of the union of these two sets. */
	
	virtual CLIENT RPTR(Mapping) combine (APTR(Mapping) ARG(other));
	
	/* Essential. Return the inverse of this transformation. 
	Considering the Mapping as a set of pairs (see class 
	comment), return the Dsp which has the mirror image of all my pairs. */
	
	virtual CLIENT RPTR(Mapping) inverse () DEFERRED_FUNC;
	
	/* There is no sensible explanation for what this message 
	does on Mappings 
		which aren't Dsps.  In the future, we will probably retire 
	this message,
		so don't use it. */
	
	virtual RPTR(Mapping) preCompose (APTR(Dsp) ARG(dsp)) DEFERRED_FUNC;
	
	/* Essential.  Restrict the domain.  The domain of the result 
	will be the intersection of my domain and 'region'.  
	Otherwise we are the same. */
	
	virtual CLIENT RPTR(Mapping) restrict (APTR(XnRegion) ARG(region)) DEFERRED_FUNC;
	
	/* Restrict the range.  The range of the result will be the 
	intersection of my range and 'region'.  Otherwise we are the same. */
	
	virtual RPTR(Mapping) restrictRange (APTR(XnRegion) ARG(region)) DEFERRED_FUNC;
	
	/* Defined by the equivalence:
			M->transformedBy(D)->of(R) isEqual (D->of(M->of(R)))
		for all regions R in the domainSpace of M. Equivalent to 
	Dsp::preCompose, except that it is between a Mapping and a Dsp. */
	
	virtual RPTR(Mapping) transformedBy (APTR(Dsp) ARG(dsp)) DEFERRED_FUNC;
	
  public: /* vulnerable: accessing */

	/* if I know how to combine the two into a single mapping, 
	then I do so */
	
	virtual RPTR(Mapping) fetchCombine (APTR(Mapping) ARG(mapping)) DEFERRED_FUNC;
	
  public: /* testing */

	
	virtual UInt32 actualHashForEqual ();
	

	/* automatic 0-argument constructor */
  public:
	Mapping();

/* Friends for class Mapping */
/* friends for class Mapping */
friend void storeMapping (Mapping *, MuSet *);
friend class SimpleMapping;



};  /* end class Mapping */



/* ************************************************************************ *
 * 
 *                    Class   Dsp 
 *
 * ************************************************************************ */




	/* A Dsp is a mapping from a coordinate space to itself that 
	preserves simple regions.  Every coordinate space must have 
	an identity Dsp (which maps all positions of that space onto 
	themselves). Dsps are necessarily invertable and composable.
	
	(Removed from CoordinateSpace because Dsps are still internal.:
	Dsp -- The transformations that can be applied to positions 
	and regions of this cordinate space.  A Dsp is necessarily 
	invertible but generally not order-preserving. The 
	composition of two Dsps is always a Dsp. If you can subtract 
	two Dsps, the result will be another Dsp.  The Dsp of a 
	Position in this space is always another Position in this 
	space.  The Dsp of a simple region is always another simple region.)
		
		
		Considering a Mapping as a set of pairs, a Dsp is one for 
	which each position appears exactly once in the first 
	elements of the pairs, and exactly once in the second 
	elements.  Composition of Dsps isn't necessarily commutative, 
	though there are currently no counter-examples.  Therefore we 
	must be extra careful to avoid embodying commutativity 
	assumptions in our code, as we currently have no way of 
	finding such bugs. */

class Dsp : public Mapping {

/* Attributes for class Dsp */
	DEFERRED(Dsp)
	NO_GC(Dsp)
  public: /* accessing */

	/* For Dsp's, it is identical to compose. */
	
	INLINE RPTR(Mapping) appliedAfter (APTR(Dsp) ARG(dsp));
	
	/* the coordinate space of the domain and range of the Dsp */
	
	virtual RPTR(CoordinateSpace) coordinateSpace () DEFERRED_FUNC;
	
	/* Must be valid everywhere in the domain for a Dsp. */
	
	virtual RPTR(XnRegion) domain ();
	
	
	INLINE RPTR(Dsp) OR(NULL) fetchDsp ();
	
	
	INLINE BooleanVar isComplete ();
	
	/* Says whether this Dsp maps every Position onto itself */
	
	virtual BooleanVar isIdentity () DEFERRED_FUNC;
	
	/* a->compose(b) is the same as b->preCompose(a).  Don't use it, use
		compose instead. */
	
	virtual RPTR(Mapping) preCompose (APTR(Dsp) ARG(dsp));
	
	
	virtual RPTR(XnRegion) range ();
	
	/* Same as the domain space */
	
	INLINE RPTR(CoordinateSpace) rangeSpace ();
	
	/* A Dsp is a simpleMapping already, so this just returns the 
	singleton set containing me */
	
	virtual RPTR(ImmuSet) OF1(Mapping) simpleMappings ();
	
	/* The domain of a Dsp is the simple region covering the 
	whole coordinate space, so
		I just return a singleton set containing myself */
	
	virtual RPTR(ImmuSet) OF1(Mapping) simpleRegionMappings ();
	
	/* For Dsp's, it is identical to preCompose. */
	
	INLINE RPTR(Mapping) transformedBy (APTR(Dsp) ARG(dsp));
	
  public: /* combining */

	/* Return the composition of the two Dsps. Two Dsps of the 
	same space are always composable.
		(a->compose(b) ->minus(b))->isEqual (a)
		(a->compose(b) ->of(pos))->isEqual (a->of (b->of (pos)) */
	
	virtual RPTR(Dsp) compose (APTR(Dsp) ARG(other)) DEFERRED_FUNC;
	
	/* Return the inverse of this transformation. Considering the 
	Dsp as a set of pairs 
		(see class comment), return the Dsp which has the mirror 
	image of all my 
		pairs. */
	
	virtual RPTR(Mapping) inverse () DEFERRED_FUNC;
	
	/* Return the difference of the two Dsps.
		(a->compose(b) ->minus(b))->isEqual (a) */
	
	virtual RPTR(Dsp) minus (APTR(Dsp) ARG(other)) DEFERRED_FUNC;
	
  public: /* transforming */

	/* If 'reg' is a simple region, then the result must also be simple */
	
	virtual RPTR(XnRegion) ofAll (APTR(XnRegion) ARG(reg)) DEFERRED_FUNC;
	
  public: /* operations */

	
	INLINE RPTR(Mapping) restrict (APTR(XnRegion) ARG(region));
	
	
	virtual RPTR(Mapping) restrictRange (APTR(XnRegion) ARG(region));
	
  protected: /* protected: */

	
	virtual RPTR(Mapping) fetchCombine (APTR(Mapping) ARG(mapping));
	
  public: /* deferred transforming */

	/* Since Dsps always represent a unique mapping in either 
	direction, the permission to BLAST
		in the Mapping constract no longer applies.
		a->inverseOf(b) ->isEqual (a->inverse()->of(b)) */
	
	virtual RPTR(Position) inverseOf (APTR(Position) ARG(pos));
	
	/* Inverse transform a region.  A simple region must yield a 
	simple region.
		a->inverseOfAll(b) ->isEqual (a->inverseAll()->of(b)) */
	
	virtual RPTR(XnRegion) inverseOfAll (APTR(XnRegion) ARG(reg));
	
	/* Since Dsps always represent a unique mapping in either 
	direction, the permission to BLAST
		in the Mapping constract no longer applies. */
	
	virtual RPTR(Position) of (APTR(Position) ARG(pos));
	
  public: /* deferred combining */

	/* Return the composition of my inverse with the other.
		a->inverseCompose(b) ->isEqual (a->inverse()->compose(b)) */
	
	virtual RPTR(Dsp) inverseCompose (APTR(Dsp) ARG(other));
	

	/* automatic 0-argument constructor */
  public:
	Dsp();

};  /* end class Dsp */



/* ************************************************************************ *
 * 
 *                    Class OrderSpec 
 *
 * ************************************************************************ */




	/* [documentation note: we need to hide the documentation 
	about partial orders, but still warn that the orders may 
	become partial]. An OrderSpec for a given coordinate space 
	represents a partial ordering of all the Positions of that 
	coordinate space.  The fundamental ordering relationship is 
	"follows".  The response of Positions to isGE defines the 
	natural, "ascending" partial order among the positions.  
	Every coordinate space will have at least this ascending and 
	the corresponding descending OrderSpecs.  OrderSpecs are 
	useful to specify in what order a stepper produced for 
	stepping over positions should do so. */

class OrderSpec : public Heaper {

/* Attributes for class OrderSpec */
	DEFERRED(OrderSpec)
	ON_CLIENT(OrderSpec)
	COPY(OrderSpec,XppCuisine)
	NO_GC(OrderSpec)
  public: /* testing */

	
	virtual UInt32 actualHashForEqual ();
	
	/* Say what the relative ordering relationship is between x and y */
	
	virtual OrderEnum compare (APTR(Position) ARG(x), APTR(Position) ARG(y));
	
	/* Essential.  Compare the two and return true if x is known 
	to follow y in the ordering.  This message is the 'greater 
	than or equal to' equivalent for this ordering.  It must have 
	those properties a mathematician would demand of a '>=' on a 
	partial order:
			os->follows(a, a)   (reflexivity)
			os->follows(a, b) && os->follows(b, c) implies 
	os->follows(a, c)  (transitivity)
			os->follows(a, b) && os->follows(b, a) implies 
	a->isEqual(b)  (what's the name for this?) */
	
	virtual CLIENT BooleanVar follows (APTR(Position) ARG(x), APTR(Position) ARG(y)) DEFERRED_FUNC;
	
	/* See discussion in XuInteger class comment about boxed vs 
	unboxed integers */
	
	virtual BooleanVar followsInt (IntegerVar ARG(x), IntegerVar ARG(y));
	
	
	virtual BooleanVar isEqual (APTR(Heaper) ARG(other)) DEFERRED_FUNC;
	
	/* Essential.  If this returns TRUE, then I define a full 
	order over all positions in 'keys' (or all positions in the 
	space if 'keys' is NULL).  However, if I return FALSE, that 
	doesn't guarantee that I don't define a full ordering.  I may 
	happen to define a full ordering without knowing it.
		
		A full ordering is one in which for each a, b in keys; 
	either this->follows(a, b) or this->follows(b, a). */
	
	virtual BooleanVar isFullOrder (APTR(XnRegion) ARG(keys) = NULL) DEFERRED_FUNC;
	
	/* Return true if some position in before is less than or 
	equal to all positions in after. */
	
	virtual BooleanVar preceeds (APTR(XnRegion) ARG(before), APTR(XnRegion) ARG(after)) DEFERRED_FUNC;
	
  public: /* accessing */

	/* Return an Arrangement of the positions in region according 
	to the ordering of the receiver. */
	
	virtual RPTR(Arrangement) arrange (APTR(XnRegion) ARG(region));
	
	/* Essential.  Like Positions, Dsps, and XuRegions, an 
	OrderSpec is specific to one coordinate space.  It is an 
	error to use the generic protocol on objects from different 
	coordinate spaces. */
	
	virtual CLIENT RPTR(CoordinateSpace) coordinateSpace () DEFERRED_FUNC;
	
	/* Returns an OrderSpec representing the mirror image of my ordering.
		o->follows(a, b) iff o->reverse()->follows(b, a) */
	
	virtual CLIENT RPTR(OrderSpec) reversed ();
	

	/* automatic 0-argument constructor */
  public:
	OrderSpec();

};  /* end class OrderSpec */



/* ************************************************************************ *
 * 
 *                    Class Position 
 *
 * ************************************************************************ */




	/* This is the superclass of all positions of coordinate 
	spaces.  Each individual position is specific to some one 
	coordinate space.  Positions themselves don't have much 
	behavior, as most of the interesting aspects of coordinate 
	spaces are defined in the other objects in terms of 
	positions.  Positions do have their own native ordering 
	messages, but for most purposes it's probably better to 
	compare them using an appropriate OrderSpec. */

class Position : public Heaper {

/* Attributes for class Position */
	DEFERRED(Position)
	ON_CLIENT(Position)
	NO_GC(Position)
  public: /* testing */

	/* since we redefine equal, subclasses had better redefine 
	actualHashForEqual */
	
	virtual UInt32 actualHashForEqual ();
	
	
	virtual BooleanVar isEqual (APTR(Heaper) ARG(other)) DEFERRED_FUNC;
	
  public: /* accessing */

	/* Essential.  A region containing this position as its only 
	element. */
	
	virtual CLIENT RPTR(XnRegion) asRegion () DEFERRED_FUNC;
	
	/* Essential.  The coordinate space this is a position in. 
	This implies that a position object is only a position in one 
	particular coordinate space. */
	
	virtual CLIENT RPTR(CoordinateSpace) coordinateSpace () DEFERRED_FUNC;
	

	/* automatic 0-argument constructor */
  public:
	Position();

};  /* end class Position */



/* ************************************************************************ *
 * 
 *                    Class XnRegion 
 *
 * ************************************************************************ */




	/* The design of a new coordinate space consists mostly in 
	the design of the XuRegions which can be used to describe 
	(possibly infinite) sets of positions in that coordinate 
	space.  It will generally not be the case (for a given 
	coordinate space) that all mathematically describable sets of 
	positions will be representable by an XuRegion in that space. 
	 This should not be seen as a temporary deficiency of the 
	current implementation of a space, but rather part of the 
	design of what a given space *means*.  
		
		For example, in IntegerSpace, one cannot form the XuRegion 
	whose members are exactly the even numbers.  If this were 
	possible, other desirable properties which are part of the 
	intent of IntegerSpaces would no longer be possible.  For 
	example, any XuRegion should be able to break itself up into 
	a finite number of simple XuRegions ("simple" is described 
	below).  Were an even number region possible, this would have 
	undesirable consequences for the definition of "simple" in 
	this space.  If you want (for example) to be able to have a 
	XuRegion which can represent all the even numbers, it 
	probably makes more sense to define a whole new space in 
	which these new XuRegions apply.
		
		XuRegions should be closed under a large set of operations, 
	such as intersection, unionWith, complement and minus.  
	("closed" means that the result of performing this operation 
	on XuRegions of a given space is another valid XuRegion in 
	the same space.)  Additional guarantees are documented with 
	each operation.
		
		A XuRegion may be classified at one of three levels of "simplicity":
		
		1) The simplest are the *distinctions*.  Distinctions are 
	those that answer with (at most) a single set containing 
	themselves in response to the message "distinctions".  (The 
	reason I say "at most" is that a full region (one that covers 
	the entire coordinate space) may answer with the empty set.)  
	Distinctions are the simplest XuRegions of a given space out 
	of which all other XuRegions of that space can be finitely 
	composed.  There should probably be a message "isDistinction" 
	for which exactly the distinctions answer "true".  The 
	complement of a distinction is a distinction.  Three examples 
	of distinctions in spaces are:
		
			a) in IntegerSpace, any simple inequality.  For example, 
	all integers < 37.
			b) in one kind of 3-space, any half space (all the space on 
	one side of some plane)
			c) in another kind of 3-space, any sphere or spherical hole.
			
		Note that "c" could not just have spheres as the distinction 
	because distinctions must be closed under complement.  (We 
	are here ignoring the quite substantial problems that arise 
	in dealing with approximate (e.g., floating point) which 
	would almost necessarily have to arise in doing any decent 
	3-space.  3-space is nevertheless a good intuition pump.)
		
		2) Next are the *simple regions*.  Simple regions are 
	exactly those that say "true" to "isSimple".  All 
	distinctions are also simple regions.  In response to the 
	message "distinctions", and simple region must return a 
	finite set of distinctions which, when intersected together, 
	yield the original simple region.  Generally, one tries to 
	define the simple regions for a space to correspond to some 
	notion of locality in the space.  For example, it may be good 
	for a simple region not to be able to have a hole in it.  Or 
	perhaps a simple region is which must be connected (whatever 
	that means in a given space).  Example non-distinction simple 
	regions for the above example spaces would be:
		
			a) The interval from 3 inclusive to 17 exclusive 
	(intersection of all integers >= 3 and all < 17)
			b) A convex hull (intersection of half spaces)
			c) Whatever you get by intersecting a bunch of spheres and 
	sherical holes.
			
		The simple regions for both "a" and "b" would be connected, 
	without holes, and even convex.  This follows directly from 
	the definition of our distinctions.  None of these nice 
	properties holds for "c", and this also follows directly from 
	our decision to start with spheres.  "c" is still perfectly 
	valid, just less preferable by some criteria.
		
		3) Finally, there are the regions of a space in general.  
	Any region must respond to the message "simpleRegions" with a 
	stepper which will produce a finite number of simple regions 
	that, when unioned together, yields the original region.  A 
	simple region will return a stepper that will return at most 
	itself ("at most" because an empty region (which covers no 
	positions) may return an empty stepper).  Example non-simple 
	regions are:
		
			a) all integers < 3 and all integers >= 17
			b) two convex hulls
			c) two disjoint spheres
			
		Note that "a" is the complement of the earlier "a" example, 
	thereby showing why the complement of a simple region isn`t 
	necessarily simple.  Even though the "c" space is so 
	unconstrained in the properties of its simple regions, there 
	is no way to interect a finite number of spheres and 
	spherical holes to produce a pair of disjoint spheres.  
	Therefore the pair is non-simple.  Not all spaces must have 
	non-simple regions (or even non-distinctions).  It is 
	interesting to observe for "b" and "c" that even though there 
	is a natural conversion between their respective positions, 
	(except for the empty and full regions) there is no 
	conversion at all between their respective regions.  The 
	kinds of sets of positions representable in one space is 
	completely different than those representable in the other space.
		
		We will use these three example spaces repeatedly in 
	documenting the protocol. */

class XnRegion : public Heaper {

/* Attributes for class XnRegion */
	DEFERRED(XnRegion)
	ON_CLIENT(XnRegion)
	NO_GC(XnRegion)
  public: /* pseudo constructors */

	/* Make a set containing all the positions in the region */
	
	static RPTR(ImmuSet) immuSet (APTR(XnRegion) ARG(region));
	
  public: /* accessing */

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
	
	virtual RPTR(XnRegion) asSimpleRegion ();
	
	/* Essential.  The coordinate space in which this is a region */
	
	virtual CLIENT RPTR(CoordinateSpace) coordinateSpace () DEFERRED_FUNC;
	
  public: /* operations */

	/* Essential.  Return a region of containing exactly those 
	positions not in this region. The complement of a distinction 
	must be a distinction. */
	
	virtual CLIENT RPTR(XnRegion) complement () DEFERRED_FUNC;
	
	/* The region where they differ.  
		a->delta(b) ->isEqual (a->minus(b)->unionWith(b->minus(a))) */
	
	virtual RPTR(XnRegion) delta (APTR(XnRegion) ARG(region));
	
	/* Essential.  The intersection of two simple regions must be 
	simple. The intersection of two distinctions must therefore 
	be a simple region. The result has exactly those members 
	which both the original regions have. */
	
	virtual CLIENT RPTR(XnRegion) intersect (APTR(XnRegion) ARG(other)) DEFERRED_FUNC;
	
	/* The region containing all my position which aren't in other. */
	
	virtual CLIENT RPTR(XnRegion) minus (APTR(XnRegion) ARG(other));
	
	/* The result must contain all positions contained by either 
	of the two 
		original regions, and the result must be simple. However, the result 
		may contain additional positions. See the comment on 
		'XuRegion::asSimpleRegion'.  a->simpleUnion(b) satisfies the 
	same specification 
		as (a->unionWith(b))->asSimpleRegion(). However, the two results do 
		not have to be the same region. */
	
	virtual RPTR(XnRegion) simpleUnion (APTR(XnRegion) ARG(other)) DEFERRED_FUNC;
	
	/* The result has as members exactly those positions which 
	are members of either of the original two regions. No matter 
	how simple the two original regions are, the result may be non-simple.
		
		The only reason this is called 'unionWith' instead of 
	'union' is that the latter is a C++ keyword. */
	
	virtual CLIENT RPTR(XnRegion) unionWith (APTR(XnRegion) ARG(other)) DEFERRED_FUNC;
	
	/* the region with one more position. Actually, if I already 
	contain pos, then the result is just me. */
	
	virtual CLIENT RPTR(XnRegion) with (APTR(Position) ARG(pos));
	
	/* the region with one less position. Actually if I already 
	don't contain pos, then the result is just me. */
	
	virtual CLIENT RPTR(XnRegion) without (APTR(Position) ARG(pos));
	
  public: /* testing */

	
	virtual UInt32 actualHashForEqual ();
	
	/* Do I contain this position? More than anything else, the 
	behavior of this message is the defining characteristic of an 
	XuRegion. All other messages (except for the simplicity 
	characterization) should be specifiable in terms of the 
	behavior of this message. What an XuRegion *is* (mostly) is a 
	finite decision procedure for accepting or rejecting any 
	given position. */
	
	virtual CLIENT BooleanVar hasMember (APTR(Position) ARG(atPos)) DEFERRED_FUNC;
	
	/* Essential.  tell whether it has any points in common */
	
	virtual CLIENT BooleanVar intersects (APTR(XnRegion) ARG(other));
	
	/* Am I a distinction.  See XuRegion class comment for 
	implications of being a distinction. */
	
	virtual BooleanVar isDistinction ();
	
	/* Every coordinate space has exactly one empty region. It is 
	the one containing no positions. It and only it responds 
	'true' to this message. */
	
	virtual CLIENT BooleanVar isEmpty () DEFERRED_FUNC;
	
	/* Two regions are equal iff they contain exactly the same 
	set of positions */
	
	virtual BooleanVar isEqual (APTR(Heaper) ARG(other)) DEFERRED_FUNC;
	
	/* Essential.  Do I contain a finite number of positions? If 
	I do, then the 'count' message will say how many, and I will 
	gladly provide a stepper which will step over all of them. 
	I.e., isFinite implies isEnumerable. */
	
	virtual CLIENT BooleanVar isFinite () DEFERRED_FUNC;
	
	/* true if this is the largest possible region in this space 
	-- the region that contains all positions in the space. Note 
	that in a space which has no positions (which is perfectly 
	valid), the one XuRegion would be both empty (since it has no 
	positions) and full (since it has all the positions in the space). */
	
	virtual CLIENT BooleanVar isFull ();
	
	/* Am I a simple region.  See XuRegion class comment for 
	implications of being simple. */
	
	virtual BooleanVar isSimple () DEFERRED_FUNC;
	
	/* I'm a subset of other if I don't have any positions that 
	he doesn't. Note that if we are equal, then I am still a 
	subset of him. If you want to know if I'm a strict subset, you can ask 
		a->isSubsetOf(b) && ! a->isEqual(b) */
	
	virtual CLIENT BooleanVar isSubsetOf (APTR(XnRegion) ARG(other));
	
  public: /* enumerating */

	/* If an OrderSpec is given, return the first n elements 
	according to that OrderSpec. If no OrderSpec is given, then 
	iff I contain at least n positions, return n of them; 
	otherwise BLAST. This should be implemented even by regions 
	that aren't enumerable.  Inspired by the axiom of choice. */
	
	virtual CLIENT RPTR(XnRegion) chooseMany (IntegerVar ARG(n), APTR(OrderSpec) ARG(order) = NULL);
	
	/* Essential.  If an OrderSpec is given, return the first 
	element according to that OrderSpec. If no OrderSpec is 
	given, then iff I contain at least one position, return one 
	of them; otherwise BLAST. This should be implemented even by 
	regions that aren't enumerable.  Inspired by the axiom of choice. */
	
	virtual CLIENT RPTR(Position) chooseOne (APTR(OrderSpec) ARG(order) = NULL);
	
	/* How many positions do I contain?  If I am not 'isFinite', 
	then this message will BLAST. */
	
	virtual CLIENT IntegerVar count () DEFERRED_FUNC;
	
	/* break it up into a set of non-empty simple regions which don't 
		overlap. This message satisfies all the specs of 'simpleRegions', and 
		in addition provides for lack of overlap. It may be 
	significantly more 
		expensive than 'simpleRegions' which is why they both exist. */
	
	INLINE RPTR(Stepper) OF1(XnRegion) disjointSimpleRegions (APTR(OrderSpec) ARG(order) = NULL);
	
	/* Break it up into a set of non-full distinctions. It is an 
	error to send 
		this to a non-simple region. A full region will respond with the null 
		set. Other distinctions will respond with a singleton set containing 
		themselves, and simple regions will respond with a set of 
	distinctions 
		which, when intersected together, yield the original region. */
	
	virtual RPTR(ScruSet) OF1(XnRegion) distinctions () DEFERRED_FUNC;
	
	/* Break myself up into a finite set of non-empty simple 
	regions which, when 
		unionWith'ed together will yield me. May be sent to any region. If I 
		am isEmpty, I will respond with the empty stepper. Otherwise, if I am 
		simple I will respond with a stepper producing just myself. 
		
		Please only use NULL for the 'order' argument for now unless the 
		documentation for a particular region or coordinate space says that 
		it will deal with the 'order' argument meaningfully. When no order is 
		specified then I may return the simple regions in any order. When the 
		ordering functionality is implemented, then I am constrained to 
		produce the simple regions in an order consistent with the argument's 
		ordering of my positions. When the simple regions don't overlap, and 
		don't surround each other in the ordering, then the meaning is clear. 
		Otherwise, there are several plausible options for how we should 
		specify this message. */
	
	virtual RPTR(Stepper) simpleRegions (APTR(OrderSpec) ARG(order) = NULL) DEFERRED_FUNC;
	
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
	
	virtual CLIENT RPTR(Stepper) OF1(Position) stepper (APTR(OrderSpec) ARG(order) = NULL);
	
	/* Iff I contain exactly one position, return it.  Otherwise 
	BLAST. The idea for this message is taken from the THE 
	function of ONTIC (reference McAllester) */
	
	virtual CLIENT RPTR(Position) theOne ();
	
  protected: /* protected: enumerating */

	/* Only called if I've already said I'm enumerable in the 
	originally stated order.  Also, if the originally stated 
	order was NULL, I get a guaranteed non-null order.  
	Subclasses which override 'stepper' to a method which doesn't 
	send 'actualStepper' may override 'actualStepper' to a stub 
	method which always BLASTs. */
	
	virtual RPTR(Stepper) OF1(Position) actualStepper (APTR(OrderSpec) ARG(order)) DEFERRED_FUNC;
	

	/* automatic 0-argument constructor */
  public:
	XnRegion();


  /* ---------- Static Member variables (class vars) ----------- */
  private:
	
	
};  /* end class XnRegion */


#ifdef USE_INLINE
#ifndef SPACEX_IXX
#include "spacex.ixx"
#endif /* SPACEX_IXX */


#endif /* USE_INLINE */


#endif /* SPACEX_HXX */

