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

#ifndef REALX_HXX
#define REALX_HXX


#ifndef TOFUX_HXX
#include "tofux.hxx"
#endif /* TOFUX_HXX */

#ifndef INTVARX_HXX
#include "intvarx.hxx"
#endif /* INTVARX_HXX */

#ifndef REALX_OXX
#include "realx.oxx"
#endif /* REALX_OXX */


#ifndef INITX_HXX
#include "initx.hxx"
#endif /* INITX_HXX */

#ifndef SPACEX_HXX
#include "spacex.hxx"
#endif /* SPACEX_HXX */


#ifndef EDGER_OXX
#include "edger.oxx"
#endif /* EDGER_OXX */

#ifndef NXCVRX_OXX
#include "nxcvrx.oxx"
#endif /* NXCVRX_OXX */

#ifndef PARRAYX_OXX
#include "parrayx.oxx"
#endif /* PARRAYX_OXX */

#ifndef PRIMVALX_OXX
#include "primvalx.oxx"
#endif /* PRIMVALX_OXX */

#ifndef REALP_OXX
#include "realp.oxx"
#endif /* REALP_OXX */

#ifndef SETX_OXX
#include "setx.oxx"
#endif /* SETX_OXX */

#ifndef STEPPERX_OXX
#include "stepperx.oxx"
#endif /* STEPPERX_OXX */


/*  */
/*  */
#define IEEE8 Int8




/* ************************************************************************ *
 * 
 *                    Class RealPos 
 *
 * ************************************************************************ */




	/* Represents some real number exactly.  Not all real numbers 
	can be exactly represented.  See class comment in RealSpace. */

class RealPos : public Position {

/* Attributes for class RealPos */
	DEFERRED(RealPos)
	ON_CLIENT(RealPos)
	COPY(RealPos,XppCuisine)
	NO_GC(RealPos)
  public: /* creation */

	/* make an XuReal given an IEEE floating point number of 
	whatever precision on this platform is able to hold all the 
	real numbers currently representable by an XuReal.  Currently 
	this is IEEE64 (double precision), but may be redeclared as a 
	larger IEEE precision in the future.  See comment in 
	XuReal::makeIEEE64 */
	
	static INLINE RPTR(RealPos) make (IEEE64 ARG(value));
	
	/* See comment in XuReal::makeIEEE64 */
	
	static RPTR(RealPos) makeIEEE32 (IEEE32 ARG(value));
	
	/* Returns an XuReal which exactly represents the same real 
	number that is represented by 'value'.  BLASTs if value 
	doesn't represent a real (i.e., no NANs or inifinities).  
	Negative 0 will be silently converted to positive zero */
	
	static RPTR(RealPos) makeIEEE64 (IEEE64 ARG(value));
	
	/* See comment in XuReal::makeIEEE64 */
	
	static RPTR(RealPos) makeIEEE8 (IEEE8 ARG(value));
	
  public: /* accessing */

	
	virtual RPTR(XnRegion) asRegion ();
	
	
	INLINE RPTR(CoordinateSpace) coordinateSpace ();
	
	/* Essential. Return the number as a PrimFloat object from 
	which you can get it in a variety of representations. */
	
	virtual CLIENT RPTR(PrimFloatValue) value () DEFERRED_FUNC;
	
  public: /* testing */

	
	virtual UInt32 actualHashForEqual ();
	
	
	virtual BooleanVar isEqual (APTR(Heaper) ARG(other));
	
	
	virtual BooleanVar isGE (APTR(Position) ARG(other));
	
  public: /* obsolete: */

	/* Returns the value as IEEE basic data type is big enough to 
	hold any value which can be put into an XuReal.  Currently 
	this is an IEEE64 (double precision).  In future releases of 
	this API, the return type of this method may be changed to 
	IEEE128 (quad precision).  Once we support other ways of 
	representing real numbers, there may not be an all-inclusive 
	IEEE type, in which case this message will BLAST.
		
		The only IEEE values which this will return are those that 
	represent real numbers.  I.e., no NANs, no inifinities, no 
	negative zero. */
	
	virtual IEEE64 asIEEE () DEFERRED_FUNC;
	
	/* Returns the value as IEEE64 (double precision).
		The only IEEE values which this will return are those that 
	represent real numbers.  I.e., no NANs, no inifinities, no 
	negative zero. */
	
	virtual IEEE64 asIEEE64 () DEFERRED_FUNC;
	
	/* What precision is it, in terms of the number of bits used 
	to represent it.  In the interests of efficiency, this may 
	return a number larger than that *needed* to represent it.  
	However, the precision reported must be at least that needed 
	to represent this number.  It is assumed that the format of 
	the number satisfies the IEEE radix independent floating 
	point spec.  Should we represent real numbers other that 
	those representable in IEEE, the meaning of this message will 
	be more fully specified.
		
		The fact that this message is allowed to overestimate 
	precision doesn't interfere with equality: a->isEqual(b) 
	exactly when they represent that same real number, even if 
	one of them happens to overestimate precision more that the other. */
	
	virtual Int32 precision () DEFERRED_FUNC;
	

	/* automatic 0-argument constructor */
  public:
	RealPos();

};  /* end class RealPos */



/* ************************************************************************ *
 * 
 *                    Class RealRegion 
 *
 * ************************************************************************ */



/* Initializers for RealRegion */







	/* NO CLASS COMMENT */

class RealRegion : public XnRegion {

/* Attributes for class RealRegion */
	CONCRETE(RealRegion)
	ON_CLIENT(RealRegion)
	COPY(RealRegion,XppCuisine)
	AUTO_GC(RealRegion)

/* Initializers for RealRegion */



friend class INIT_TIME_NAME(RealRegion,initTimeNonInherited);

  public: /* creation */

	/* Make a new region, reusing the given array. Noone else 
	should ever modify it! */
	
	static RPTR(RealRegion) make (BooleanVar ARG(startsInside), APTR(PrimArray) OF1(RealEdge) ARG(transitions));
	
	
	static RPTR(RealRegion) usingx (
			BooleanVar ARG(startsInside), 
			APTR(PrimFloatArray) ARG(vals), 
			APTR(PrimIntegerArray) ARG(flags))
	;
	
  public: /* enumerating */

	
	INLINE IntegerVar count ();
	
	
	INLINE RPTR(ScruSet) OF1(XnRegion) distinctions ();
	
	/* Essential. Break this up into disjoint intervals */
	
	INLINE CLIENT RPTR(Stepper) OF1(RealRegion) intervals (APTR(OrderSpec) ARG(order) = NULL);
	
	/* Whether this Region is a non-empty interval, i.e. if A, B 
	in the Region and A <= C <= B then C is in the Region. This 
	includes inequalities (e.g. {x | x > 5}) and the fullRegion 
	in addition to ordinary two-ended intervals. */
	
	INLINE CLIENT BooleanVar isInterval ();
	
	
	virtual RPTR(Stepper) simpleRegions (APTR(OrderSpec) ARG(order) = NULL);
	
	
	virtual RPTR(Stepper) OF1(Position) stepper (APTR(OrderSpec) ARG(order) = NULL);
	
  protected: /* protected: enumerating */

	
	virtual RPTR(Stepper) OF1(Position) actualStepper (APTR(OrderSpec) ARG(order));
	
  public: /* testing */

	
	virtual UInt32 actualHashForEqual ();
	
	
	INLINE BooleanVar hasMember (APTR(Position) ARG(position));
	
	/* Same meaning as IntegerRegion::isBoundedAbove */
	
	INLINE CLIENT BooleanVar isBoundedAbove ();
	
	/* Same meaning as IntegerRegion::isBoundedBelow */
	
	INLINE CLIENT BooleanVar isBoundedBelow ();
	
	
	INLINE BooleanVar isEmpty ();
	
	/* Any representable infinite set of real numbers is also not 
	enumerable */
	
	INLINE BooleanVar isEnumerable (APTR(OrderSpec) ARG(order) = NULL);
	
	
	virtual BooleanVar isEqual (APTR(Heaper) ARG(other));
	
	
	virtual BooleanVar isFinite ();
	
	
	virtual BooleanVar isFull ();
	
	
	virtual BooleanVar isSimple ();
	
	
	virtual BooleanVar isSubsetOf (APTR(XnRegion) ARG(other));
	
  public: /* operations */

	
	INLINE RPTR(XnRegion) complement ();
	
	
	INLINE RPTR(XnRegion) intersect (APTR(XnRegion) ARG(other));
	
	
	virtual RPTR(XnRegion) simpleUnion (APTR(XnRegion) ARG(other));
	
	
	virtual RPTR(XnRegion) unionWith (APTR(XnRegion) ARG(other));
	
  public: /* secret */

	
	virtual RPTR(PtrArray) OF1(RealEdge) secretTransitions ();
	
	
	INLINE BooleanVar startsInside ();
	
  public: /* printing */

	
	virtual void printOn (ostream& ARG(oo));
	
  public: /* accessing */

	
	INLINE RPTR(XnRegion) asSimpleRegion ();
	
	
	INLINE RPTR(CoordinateSpace) coordinateSpace ();
	
	/* The largest real number such that all the positions in the 
	region are >= it.  Does not necessarily lie in the region.  
	For example, the region of all numbers > 2 has a lowerBound of 2. */
	
	virtual CLIENT RPTR(RealPos) lowerBound ();
	
	/* The smallest real number such that all the positions in 
	the region are <= it.  Does not necessarily lie in the 
	region.  For example, the region of all numbers < 2 has an 
	upperBound of 2. */
	
	virtual CLIENT RPTR(RealPos) upperBound ();
	
  public: /* creation */

	
	RealRegion (
			BooleanVar ARG(startsInside), 
			APTR(PrimFloatArray) ARG(vals), 
			APTR(PrimIntegerArray) ARG(flags))
	;
	
  private:
	BooleanVar myStartsInside;
	CHKPTR(PrimFloatArray) myTransitionVals;
	CHKPTR(PrimIntegerArray) myTransitionFlags;

  /* ---------- Static Member variables (class vars) ----------- */
  private:
	static GPTR(RealManager) TheManager;
};  /* end class RealRegion */



/* ************************************************************************ *
 * 
 *                    Class RealSpace 
 *
 * ************************************************************************ */



/* Initializers for RealSpace */







	/* Non-arithmetic space of real numbers in which only certain 
	positions are explicitly representable.  In this release, the 
	only exactly representable numbers are those real numbers 
	which can be represented in IEEE64 (double precision) format. 
	 Future releases may make more real numbers representable. */

class RealSpace : public CoordinateSpace {

/* Attributes for class RealSpace */
	CONCRETE(RealSpace)
	PSEUDO_COPY(RealSpace,XppCuisine)
	ON_CLIENT(RealSpace)
	NO_GC(RealSpace)

/* Initializers for RealSpace */



friend class INIT_TIME_NAME(RealSpace,initTimeNonInherited);

  public: /* creation */

	
	static INLINE CLIENT RPTR(RealSpace) make ();
	
  public: /* rcvr pseudo constructors */

	
	static RPTR(Heaper) make (APTR(Rcvr) ARG(rcvr));
	
  public: /* create */

	
	RealSpace ();
	
  public: /* making */

	/* The region consisting of all positions >= val if 
	inclusive, or all > val if not inclusive. */
	
	virtual CLIENT RPTR(RealRegion) above (APTR(RealPos) ARG(val), BooleanVar ARG(inclusive));
	
	/* The region consisting of all positions <= val if 
	inclusive, or all < val if not inclusive. */
	
	virtual CLIENT RPTR(RealRegion) below (APTR(RealPos) ARG(val), BooleanVar ARG(inclusive));
	
	/* Return a region of all numbers >= lower and < upper. */
	
	virtual CLIENT RPTR(RealRegion) interval (APTR(RealPos) ARG(start), APTR(RealPos) ARG(stop));
	
	/* The XuReal representing the same real number as that 
	exactly represented by 'val'.  If 'val' doesn't represent a 
	real number (i.e., it is an infinity or a NAN), then this 
	message BLASTs.  If 'val' is a negative zero, it is silently 
	converted to a positive zero */
	
	INLINE CLIENT RPTR(RealPos) position (IEEE64 ARG(val));
	
  public: /* obsolete: */

	/* The region consisting of all position >= val.
		Should this just be supplanted by CoordinateSpace::region ()? */
	
	virtual RPTR(RealRegion) after (IEEE64 ARG(val));
	
	/* The region consisting of all position <= val
		Should this just be supplanted by CoordinateSpace::region ()? */
	
	virtual RPTR(RealRegion) before (IEEE64 ARG(val));
	
	/* The region consisting of all position > val
		Should this just be supplanted by CoordinateSpace::region ()?
		Add Boolean to after to say whether its inclusive? */
	
	virtual RPTR(RealRegion) strictlyAfter (IEEE64 ARG(val));
	
	/* The region consisting of all position < val
		Should this just be supplanted by CoordinateSpace::region ()?
		Add Boolean to before to say whether its inclusive? */
	
	virtual RPTR(RealRegion) strictlyBefore (IEEE64 ARG(val));
	
  public: /* testing */

	/* is equal to any basic space on the same category of positions */
	
	virtual UInt32 actualHashForEqual ();
	
	/* is equal to any basic space on the same category of positions */
	
	virtual BooleanVar isEqual (APTR(Heaper) ARG(anObject));
	


  /* ---------- Static Member variables (class vars) ----------- */
  private:
	static GPTR(RealSpace) TheRealSpace;
};  /* end class RealSpace */


#ifdef USE_INLINE
#ifndef REALX_IXX
#include "realx.ixx"
#endif /* REALX_IXX */


#endif /* USE_INLINE */


#endif /* REALX_HXX */

