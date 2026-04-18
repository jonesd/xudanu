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

#ifndef CROSSX_HXX
#define CROSSX_HXX


#ifndef TOFUX_HXX
#include "tofux.hxx"
#endif /* TOFUX_HXX */

#ifndef INTVARX_HXX
#include "intvarx.hxx"
#endif /* INTVARX_HXX */

#ifndef CROSSX_OXX
#include "crossx.oxx"
#endif /* CROSSX_OXX */


#ifndef INITX_HXX
#include "initx.hxx"
#endif /* INITX_HXX */

#ifndef SPACEX_HXX
#include "spacex.hxx"
#endif /* SPACEX_HXX */


#ifndef CROSSP_OXX
#include "crossp.oxx"
#endif /* CROSSP_OXX */

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




/* ************************************************************************ *
 * 
 *                    Class CrossMapping 
 *
 * ************************************************************************ */




	/* All other crossed mappings must be gotten by factoring the 
	non-dsp aspects out into the generic non-dsp mapping objects. 
	 This class represents what remains after the factoring. */

class CrossMapping : public Dsp {

/* Attributes for class CrossMapping */
	DEFERRED(CrossMapping)
	ON_CLIENT(CrossMapping)
	NO_GC(CrossMapping)
  public: /* pseudoconstructors */

	
	static RPTR(CrossMapping) make (APTR(CrossSpace) ARG(space), APTR(PtrArray) OF1(Dsp OR(NULL)) ARG(subDsps) = NULL);
	
  public: /* transforming */

	
	virtual RPTR(XnRegion) ofAll (APTR(XnRegion) ARG(reg)) DEFERRED_FUNC;
	
  public: /* combining */

	
	virtual RPTR(Dsp) compose (APTR(Dsp) ARG(other)) DEFERRED_FUNC;
	
	
	virtual RPTR(Mapping) inverse () DEFERRED_FUNC;
	
	
	virtual RPTR(Dsp) minus (APTR(Dsp) ARG(other)) DEFERRED_FUNC;
	
  public: /* accessing */

	
	virtual RPTR(CoordinateSpace) coordinateSpace () DEFERRED_FUNC;
	
	
	virtual BooleanVar isIdentity () DEFERRED_FUNC;
	
	/* The Dsp applied to Positions in the given subspace. */
	
	virtual CLIENT RPTR(Dsp) subMapping (Int32 ARG(index)) DEFERRED_FUNC;
	
	/* The Mappings applied to Positions in each of the 
	subspaces. Each of these is already simple enough that it is 
	either the identityMapping or a visible subclass like 
	IntegerMapping. */
	
	virtual CLIENT RPTR(PtrArray) OF1(Dsp) subMappings () DEFERRED_FUNC;
	

	/* automatic 0-argument constructor */
  public:
	CrossMapping();

};  /* end class CrossMapping */



/* ************************************************************************ *
 * 
 *                    Class CrossOrderSpec 
 *
 * ************************************************************************ */




	/* myLexOrder lists the lexicographic order in which each 
	dimension should be processed.  Every dimension should be 
	listed exactly one, from most significant (at index 0) to 
	least significant.
	
	mySubOrders are indexed by *dimension*, not by lexicographic 
	order.  In order to index by lex order, look up the dimension 
	in myLexOrder, and then look up the resulting dimension 
	number in mySubOrders. */

class CrossOrderSpec : public OrderSpec {

/* Attributes for class CrossOrderSpec */
	CONCRETE(CrossOrderSpec)
	ON_CLIENT(CrossOrderSpec)
	COPY(CrossOrderSpec,XppCuisine)
	AUTO_GC(CrossOrderSpec)
  public: /* pseudoconstructors */

	
	static RPTR(CrossOrderSpec) make (
			APTR(CrossSpace) ARG(space), 
			APTR(PtrArray) OF1(OrderSpec OR(NULL)) ARG(subOrderings) = NULL, 
			APTR(PrimIntArray) ARG(lexOrder) = NULL)
	;
	
  private: /* private: pseudo constructors */

	/* Only used during construction; must pass the array in 
	explicitly since the space isnt initialized yet */
	
	static RPTR(CrossOrderSpec) fetchAscending (APTR(GenericCrossSpace) ARG(space), APTR(PtrArray) OF1(CoordinateSpace) ARG(subSpaces));
	
	/* Only used during construction; must pass the array in 
	explicitly since the space isnt initialized yet */
	
	static RPTR(CrossOrderSpec) fetchDescending (APTR(GenericCrossSpace) ARG(space), APTR(PtrArray) OF1(CoordinateSpace) ARG(subSpaces));
	
  private: /* private: creation */

	
	CrossOrderSpec (
			APTR(CrossSpace) ARG(space), 
			APTR(PtrArray) OF1(OrderSpec) ARG(subOrders), 
			APTR(PrimIntArray) ARG(lexOrder))
	;
	
  public: /* accessing */

	
	INLINE RPTR(CoordinateSpace) coordinateSpace ();
	
	/* Lists the lexicographic order in which each dimension 
	should be processed.  Every dimension is listed exactly once, 
	from most significant (at index 0) to least significant. */
	
	virtual CLIENT RPTR(PrimIntArray) lexOrder ();
	
	/* The sub OrderSpec used for the given axis. Note that this 
	is *not* in lex order. */
	
	virtual CLIENT RPTR(OrderSpec) subOrder (Int32 ARG(i));
	
	/* The sub OrderSpec used for each axis in the space. Note 
	that this is *not* in lex order, but rather indexed by axis number. */
	
	virtual CLIENT RPTR(PtrArray) OF1(OrderSpec) subOrders ();
	
  public: /* testing */

	
	virtual UInt32 actualHashForEqual ();
	
	
	virtual BooleanVar follows (APTR(Position) ARG(x), APTR(Position) ARG(y));
	
	
	virtual BooleanVar isEqual (APTR(Heaper) ARG(other));
	
	/* Essential.  If this returns TRUE, then I define a full 
	order over all positions in 'keys' (or all positions in the 
	space if 'keys' is NULL).  However, if I return FALSE, that 
	doesn't guarantee that I don't define a full ordering.  I may 
	happen to define a full ordering without knowing it.
		
		A full ordering is one in which for each a, b in keys; 
	either this->follows(a, b) or this->follows(b, a). */
	
	virtual BooleanVar isFullOrder (APTR(XnRegion) ARG(keys) = NULL);
	
	/* Return true if some position in before is less than or 
	equal to all positions in after. */
	
	virtual BooleanVar preceeds (APTR(XnRegion) ARG(before), APTR(XnRegion) ARG(after));
	
  private:
	CHKPTR(CrossSpace) mySpace;
	CHKPTR(PtrArray) OF1(OrderSpec) mySubOrders;
	CHKPTR(PrimIntArray) myLexOrder;
/* Friends for class CrossOrderSpec */
friend class GenericCrossSpace;



};  /* end class CrossOrderSpec */



/* ************************************************************************ *
 * 
 *                    Class CrossRegion 
 *
 * ************************************************************************ */




	/* A cross region is a distinction if 1) it is empty, 2) it 
	is full, or 3) it is the rectangular cross of full regions 
	and one distinction. Note that case 3 actually subsumes 1 and 
	2.  Since the simple regions of a space are the intersections 
	of a finite number of distinctions of a space, this implies 
	that A cross region is simple if it is the rectangular cross 
	of simple regions.  In other words, a simple region is 
	identical to the cross of its projections. */

class CrossRegion : public XnRegion {

/* Attributes for class CrossRegion */
	DEFERRED(CrossRegion)
	ON_CLIENT(CrossRegion)
	NO_GC(CrossRegion)
  public: /* testing */

	/* To avoid overly burdensome canonicalization rules, my hash 
	is calculated from the hash of my projections */
	
	virtual UInt32 actualHashForEqual ();
	
	
	virtual BooleanVar hasMember (APTR(Position) ARG(atPos)) DEFERRED_FUNC;
	
	
	virtual BooleanVar isEmpty () DEFERRED_FUNC;
	
	
	virtual BooleanVar isEnumerable (APTR(OrderSpec) ARG(order) = NULL) DEFERRED_FUNC;
	
	
	virtual BooleanVar isEqual (APTR(Heaper) ARG(other)) DEFERRED_FUNC;
	
	
	virtual BooleanVar isFinite () DEFERRED_FUNC;
	
	
	virtual BooleanVar isSimple () DEFERRED_FUNC;
	
  public: /* enumerating */

	/* Essential. Divide this Region up into a disjoint sequence 
	of boxes. A box is a region which is the cross of its projections. */
	
	virtual CLIENT RPTR(Stepper) OF1(CrossRegion) boxes () DEFERRED_FUNC;
	
	
	virtual IntegerVar count () DEFERRED_FUNC;
	
	
	virtual RPTR(ScruSet) OF1(XnRegion) distinctions () DEFERRED_FUNC;
	
	/* Whether this Region is a box, i.e. is equal to the cross 
	of its projections. */
	
	virtual CLIENT BooleanVar isBox () DEFERRED_FUNC;
	
	
	virtual RPTR(Stepper) simpleRegions (APTR(OrderSpec) ARG(order) = NULL) DEFERRED_FUNC;
	
  public: /* operations */

	
	virtual RPTR(XnRegion) asSimpleRegion () DEFERRED_FUNC;
	
	
	virtual RPTR(XnRegion) complement () DEFERRED_FUNC;
	
	
	virtual RPTR(XnRegion) intersect (APTR(XnRegion) ARG(other)) DEFERRED_FUNC;
	
	
	virtual RPTR(XnRegion) simpleUnion (APTR(XnRegion) ARG(other));
	
	
	virtual RPTR(XnRegion) unionWith (APTR(XnRegion) ARG(other)) DEFERRED_FUNC;
	
  public: /* accessing */

	
	virtual RPTR(CoordinateSpace) coordinateSpace () DEFERRED_FUNC;
	
	/* The answer is the projection of this region into the 
	specified dimension of the cross space */
	
	virtual CLIENT RPTR(XnRegion) projection (Int32 ARG(index));
	
	/* Essential.  The answer is the projection of this region 
	into each dimension of the cross space. Note that two regions 
	which are different can have the same projections. */
	
	virtual CLIENT RPTR(PtrArray) OF1(XnRegion) projections () DEFERRED_FUNC;
	
  protected: /* protected: enumerating */

	
	virtual RPTR(Stepper) OF1(Position) actualStepper (APTR(OrderSpec) ARG(order)) DEFERRED_FUNC;
	

	/* automatic 0-argument constructor */
  public:
	CrossRegion();

};  /* end class CrossRegion */



/* ************************************************************************ *
 * 
 *                    Class CrossSpace 
 *
 * ************************************************************************ */




	/* Represents the cross of several coordinate spaces.   */

class CrossSpace : public CoordinateSpace {

/* Attributes for class CrossSpace */
	DEFERRED(CrossSpace)
	ON_CLIENT(CrossSpace)
	AUTO_GC(CrossSpace)
  public: /* creation */

	/* Make a cross space with the given list of subspaces */
	/* Should use middlemen.  Just hard code special cases for now */
	
	static CLIENT RPTR(CrossSpace) make (APTR(PtrArray) OF1(CoordinateSpace) ARG(subSpaces));
	
	/* Cross two sub spaces */
	
	static RPTR(CrossSpace) make (APTR(CoordinateSpace) ARG(zeroSpace), APTR(CoordinateSpace) ARG(oneSpace));
	
  public: /* accessing */

	/* Essential.  The base spaces that I am a cross of. */
	
	virtual CLIENT RPTR(PtrArray) OF1(CoordinateSpace) axes ();
	
	/* The sub coordinate space on the given axis */
	
	virtual CLIENT RPTR(CoordinateSpace) axis (Int32 ARG(dimension));
	
	/* The number of dimensions in this space */
	
	INLINE CLIENT Int32 axisCount ();
	
  public: /* testing */

	
	virtual UInt32 actualHashForEqual ();
	
	
	virtual BooleanVar isEqual (APTR(Heaper) ARG(other));
	
  public: /* making */

	/* Essential.  Map each coordinate according to the mapping 
	from its space.  NULLs mean 'use the identity mapping' */
	
	virtual CLIENT RPTR(Mapping) crossOfMappings (APTR(PtrArray) OF1(Mapping OR(NULL)) ARG(subMappings) = NULL) DEFERRED_FUNC;
	
	/* Essential.  Make a lexical ordering of all elements in the 
	space, using the given ordering for each sub space. If no sub 
	space ordering is given, then it is in the order they are in the array.
		
		subSpaceOrdering lists the lexicographic order in which each 
	dimension should be processed.  Every dimension should be 
	listed exactly one, from most significant (at index 0) to 
	least significant.
	
		subOrderings are indexed by *dimension*, not by 
	lexicographic order.  In order to index by lex order, look up 
	the dimension in subSpaceOrdering, and then look up the 
	resulting dimension number in subOrderings. */
	
	virtual CLIENT RPTR(CrossOrderSpec) crossOfOrderSpecs (APTR(PtrArray) OF1(OrderSpec OR(NULL)) ARG(subOrderings) = NULL, APTR(PrimIntArray) ARG(subSpaceOrdering) = NULL) DEFERRED_FUNC;
	
	/* Essential. Make an individual position */
	
	virtual CLIENT RPTR(Tuple) crossOfPositions (APTR(PtrArray) OF1(Position) ARG(coordinates)) DEFERRED_FUNC;
	
	/* Essential. Make a 'rectangular' region as a cross of all 
	the given regions */
	
	virtual CLIENT RPTR(CrossRegion) crossOfRegions (APTR(PtrArray) OF1(XnRegion OR(NULL)) ARG(subRegions)) DEFERRED_FUNC;
	
	/* Return a region whose projection is 'subRegion' along 
	'dimension', but is full on all other dimensions */
	
	virtual CLIENT RPTR(CrossRegion) extrusion (Int32 ARG(dimension), APTR(XnRegion) ARG(subRegion)) DEFERRED_FUNC;
	
  protected: /* protected: accessing */

	/* The actual array of sub spaces. DO NOT MODIFY */
	
	INLINE RPTR(PtrArray) OF1(CoordinateSpace) secretSubSpaces ();
	
  protected: /* protected: creation */

	
	CrossSpace ();
	
	
	CrossSpace (APTR(PtrArray) OF1(CoordinateSpace) ARG(subSpaces), TCSJ);
	
  private:
	CHKPTR(PtrArray) OF1(CoordinateSpace) mySubSpaces;
/* Friends for class CrossSpace */
friend class BoxAccumulator;
friend class BoxStepper;
friend class GenericCrossSpace;
friend class GenericCrossRegion;
friend class BoxProjectionStepper;


};  /* end class CrossSpace */



/* ************************************************************************ *
 * 
 *                    Class Tuple 
 *
 * ************************************************************************ */




	/* A tuple is a Position in a CrossSpace represented by a 
	sequence of Positions in its subSpaces */

class Tuple : public Position {

/* Attributes for class Tuple */
	DEFERRED(Tuple)
	ON_CLIENT(Tuple)
	COPY(Tuple,XppCuisine)
	NO_GC(Tuple)
  public: /* pseudoconstructors */

	
	static RPTR(Tuple) make (APTR(PtrArray) OF1(Position) ARG(coordinates));
	
	
	static RPTR(Tuple) two (APTR(Position) ARG(zero), APTR(Position) ARG(one));
	
  public: /* printing */

	
	virtual void printOn (ostream& ARG(oo));
	
	
	virtual void printOnWithSimpleSyntax (
			ostream& ARG(oo), 
			char * ARG(openString), 
			char * ARG(sep), 
			char * ARG(closeString))
	;
	
  public: /* accessing */

	
	virtual RPTR(XnRegion) asRegion () DEFERRED_FUNC;
	
	/* The position with in a subspace */
	
	virtual CLIENT RPTR(Position) coordinate (Int32 ARG(index));
	
	/* Essential. An array of the coordinates in each sub space */
	
	virtual CLIENT RPTR(PtrArray) OF1(Position) coordinates () DEFERRED_FUNC;
	
	
	virtual RPTR(CoordinateSpace) coordinateSpace () DEFERRED_FUNC;
	
  public: /* testing */

	
	virtual UInt32 actualHashForEqual ();
	
	
	virtual BooleanVar isEqual (APTR(Heaper) ARG(other)) DEFERRED_FUNC;
	

	/* automatic 0-argument constructor */
  public:
	Tuple();

};  /* end class Tuple */


#ifdef USE_INLINE
#ifndef CROSSX_IXX
#include "crossx.ixx"
#endif /* CROSSX_IXX */


#endif /* USE_INLINE */


#endif /* CROSSX_HXX */

