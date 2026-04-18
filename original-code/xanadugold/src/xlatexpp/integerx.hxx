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

#ifndef INTEGERX_HXX
#define INTEGERX_HXX


#ifndef TOFUX_HXX
#include "tofux.hxx"
#endif /* TOFUX_HXX */

#ifndef INTVARX_HXX
#include "intvarx.hxx"
#endif /* INTVARX_HXX */

#ifndef INTEGERX_OXX
#include "integerx.oxx"
#endif /* INTEGERX_OXX */


#ifndef INITX_HXX
#include "initx.hxx"
#endif /* INITX_HXX */

#ifndef SPACEX_HXX
#include "spacex.hxx"
#endif /* SPACEX_HXX */


#ifndef INTEGERP_OXX
#include "integerp.oxx"
#endif /* INTEGERP_OXX */

#ifndef NXCVRX_OXX
#include "nxcvrx.oxx"
#endif /* NXCVRX_OXX */

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
#define Integer0 IntegerPos::make(0)




/* ************************************************************************ *
 * 
 *                    Class IntegerMapping 
 *
 * ************************************************************************ */



/* Initializers for IntegerMapping */







	/* Transforms integers by adding a (possibly negative) 
	offset.  In addition to the Dsp protocol, an IntegerDsp will 
	respond to "translation" with the offset that it is adding.  
		
		Old documentation indicated a possibility of a future 
	upgrade of IntegerDsp which would also optionally reflect (or 
	negate) its input in addition to offsetting.  This would 
	however be a non-upwards compatable change in that current 
	clients already assume that the answer to "translation" fully 
	describes the IntegerDsp.  If such a possibility is 
	introduced, it should be as a super-type of IntegerDsp, since 
	it would have a weaker contract.  Then compatability problems 
	can be caught by the type checker. */

class IntegerMapping : public Dsp {

/* Attributes for class IntegerMapping */
	CONCRETE(IntegerMapping)
	PSEUDO_COPY(IntegerMapping,XppCuisine)
	ON_CLIENT(IntegerMapping)
	NO_GC(IntegerMapping)

/* Initializers for IntegerMapping */



friend class INIT_TIME_NAME(IntegerMapping,initTimeNonInherited);

  public: /* pseudo constructors */

	
	static RPTR(IntegerMapping) make ();
	
	
	static RPTR(Heaper) make (APTR(Rcvr) ARG(rcvr));
	
	
	static RPTR(IntegerMapping) make (IntegerVar ARG(translate));
	
  private: /* private: for create */

	
	static RPTR(Dsp) identity ();
	
  public: /* unprotected for init creation */

	/* Initialize instance variables */
	
	IntegerMapping (IntegerVar ARG(translation), TCSJ);
	
  public: /* printing */

	
	virtual void printOn (ostream& ARG(aStream));
	
  public: /* transforming */

	
	virtual RPTR(Position) inverseOf (APTR(Position) ARG(pos));
	
	
	virtual RPTR(XnRegion) inverseOfAll (APTR(XnRegion) ARG(reg));
	
	
	virtual IntegerVar inverseOfInt (IntegerVar ARG(pos));
	
	
	virtual RPTR(Position) of (APTR(Position) ARG(pos));
	
	
	virtual RPTR(XnRegion) ofAll (APTR(XnRegion) ARG(reg));
	
	
	virtual IntegerVar ofInt (IntegerVar ARG(pos));
	
  public: /* accessing */

	
	INLINE RPTR(CoordinateSpace) coordinateSpace ();
	
	
	INLINE BooleanVar isIdentity ();
	
	/* The offset which I add to a position.  
		If my translation is 7, then this->of(4) is 11. */
	
	INLINE CLIENT IntegerVar translation ();
	
  public: /* testing */

	
	virtual UInt32 actualHashForEqual ();
	
	/* Should have same offset and reversal */
	
	virtual BooleanVar isEqual (APTR(Heaper) ARG(other));
	
  public: /* combining */

	
	virtual RPTR(Dsp) compose (APTR(Dsp) ARG(other));
	
	
	virtual RPTR(Mapping) inverse ();
	
	
	virtual RPTR(Dsp) inverseCompose (APTR(Dsp) ARG(other));
	
	
	virtual RPTR(Dsp) minus (APTR(Dsp) ARG(other));
	
  public: /* sender */

	
	virtual SEND_HOOK void sendIntegerMapping (APTR(Xmtr) ARG(xmtr));
	
  private:
	IntegerVar myTranslation;

  /* ---------- Static Member variables (class vars) ----------- */
  private:
	static IntegerMapping * TheIdentityIntegerMapping;
/* Friends for class IntegerMapping */
/* friends for class IntegerDsp */
friend class IntegerSpace;



};  /* end class IntegerMapping */



/* ************************************************************************ *
 * 
 *                    Class IntegerPos 
 *
 * ************************************************************************ */




	/* Because of the constraints of C++, we have two very 
	different types representing integers in our system.  
		
		XuInteger is the boxed representation which must be used in 
	any context which only knows that it is dealing with a 
	Position.  XuInteger is a Heaper with all that implies.  
	Specifically, one can take advantage of all the advantages of 
	polymorphism (leading to uses by code that only knows it is 
	dealing with a Position), but at the cost of representing 
	each value by a heap allocated object to which pointers are 
	passed.  Such a representation is referred to as "boxed" 
	because the pointer combined with the storage structure 
	overhead of maintaining a heap allocated object constitutes a 
	"box" between the user of the data (the guy holding onto the 
	pointer), and the actual data (which is inside the Heaper).
		
		In contrast, IntegerVar is the efficient, unboxed 
	representation of an integer.  (actually, it is only unboxed 
	so long as it fits within some size limit such as 32 bits.  
	Those IntegerVars that exceed this limit pay their own boxing 
	cost to store their representation on the heap.  This need 
	not concern us here.)  See "The Var vs Heaper distinction" 
	and IntegerVar.  When we know that we are dealing 
	specifically with an integer, we`d like to be able to stick 
	with IntegerVars without having to convert them to 
	XuIntegers.  However, we`d like to be able to do everything 
	that we could normally do if we had an XuInteger.
		
		For this purpose, many messages (such as Position * 
	Dsp::of(Position*)) have an additional overloading 
	(IntegerVar Dsp::of(IntegerVar)) whose semantics is defined 
	in terms of converting the argument to an XuInteger, applying 
	the original operation, and converting the result (which is 
	asserted to be an XuInteger) back to an IntegerVar.  Dsp even 
	provides a default implementation to do exactly that.  
	However, if we actually rely on this default implementation 
	then we are defeating the whole purpose of avoiding boxing 
	overhead.  Instead, IntegerDsp overrides this to provide an 
	efficient implementation.  
		
		Any particular case may at the moment simply be relying on 
	the default.  The point is to get interfaces defined early 
	which allow efficiency tuning to proceed in a modular fashion 
	later.  Should any particular reliance on the default 
	actually prove to be an efficiency issue, we will deal with it then. */

class IntegerPos : public Position {

/* Attributes for class IntegerPos */
	CONCRETE(IntegerPos)
	ON_CLIENT(IntegerPos)
	COPY(IntegerPos,XppCuisine)
	NO_GC(IntegerPos)
  public: /* pseudo constructors */

	/* Box an integer. See XuInteger class comment. you can also create an 
		integer in smalltalk by sending the integer message to a 
	Smalltalk integer */
	
	static INLINE RPTR(IntegerPos) make (IntegerVar ARG(newValue));
	
	/* Box an integer. See XuInteger class comment. you can also create an 
		integer in smalltalk by sending the integer message to a 
	Smalltalk integer.
		This should return the canonical zero eventually. */
	
	static INLINE RPTR(IntegerPos) zero ();
	
  public: /* hash computing */

	/* NOTE:  Do NOT change this without also changing the 
	implementation of hashForEqual in XuInteger!!!. */
	
	static INLINE UInt32 integerHash (IntegerVar ARG(value));
	
  public: /* testing */

	/* This must use an external function so other parts of the system can
		 compute the hash from an integerVar without boxing. */
	/* Open-code in smalltalk because we don't have inlines. */
	/* NOTE:  Do NOT change this without also changing the 
	implementation of integerHash!!!. */
	
	virtual UInt32 actualHashForEqual ();
	
	
	virtual BooleanVar isEqual (APTR(Heaper) ARG(other));
	
	/* Just the full ordering you'd expect on integers */
	
	virtual BooleanVar isGE (APTR(Position) ARG(other));
	
  public: /* accessing */

	/* Unboxed version as an integer.  See class comment */
	
	INLINE Int32 asInt32 ();
	
	/* Essential.  Unboxed version.  See class comment */
	
	INLINE IntegerVar asIntegerVar ();
	
	
	virtual RPTR(XnRegion) asRegion ();
	
	
	INLINE RPTR(CoordinateSpace) coordinateSpace ();
	
	/* Essential.  Unboxed version.  See class comment */
	
	INLINE CLIENT IntegerVar value ();
	
  public: /* printing */

	
	virtual void printOn (ostream& ARG(oo));
	
  protected: /* protected: creation */

	
	IntegerPos (IntegerVar ARG(newValue), TCSJ);
	
  private:
	IntegerVar myValue;

  /* ---------- Static Member variables (class vars) ----------- */
  private:
	static GPTR(IntegerPos) TheZero;
};  /* end class IntegerPos */



/* ************************************************************************ *
 * 
 *                    Class IntegerRegion 
 *
 * ************************************************************************ */



/* Initializers for IntegerRegion */







	/* An IntegerRegion can be thought of as the disjoint union 
	of intervals and inequalities.  The interesting cases to look at are:
		
		The distinctions:
			1) The empty region
			2) The full region
			3) A "left" inequality -- e.g., everything less that 3.
			4) A "right" inequality -- e.g., everything greater than or 
	equal to 7
			
		The non-distinction simple regions:
			5) An interval -- e.g., from 3 inclusive to 7 exclusive
			
		The non-simple regions:
			6) A disjoint union of (in order) an optional left 
	inequality, a set of 
				intervals, and an optional right inequality.  
			
		If a non-empty region has a least element, then it 
	"isBoundedLeft".  Otherwise it extends leftwards 
	indefinitely.  Similarly, if a non-empty region has a 
	greatest element, then it "isBoundedRight".  Otherwise it 
	extends rightwards indefinitely.  (We may figuratively speak 
	of the region extending towards + or - infinity, but we have 
	purposely avoided introducing any value which represents an infinity.)
		
		Looking at cases again:
			1) "isBoundedLeft" and "isBoundedRight" since it doesn't extent 
				indenfinitely in either direction.  (A danger to watch out 
	for is that 
				this still has niether a greatest nor a least element).
			2) niether.
			3) "isBoundedRight"
			4) "isBoundedLeft"
			5) "isBoundedLeft" and "isBoundedRight"
			6) "isBoundedLeft" iff doesn't include a left inequality,
				"isBoundedRight" iff doesn't include a right inequality.
				
		An efficiency note:  Currently many of the method which 
	could be doing an O(log) binary search (such as hasMember) 
	are instead doing a linear search.  This will be fixed if it 
	turns out to be a problem in practice.
		
		See OrderedRegion. */

class IntegerRegion : public XnRegion {

/* Attributes for class IntegerRegion */
	CONCRETE(IntegerRegion)
	ON_CLIENT(IntegerRegion)
	COPY(IntegerRegion,XppCuisine)
	AUTO_GC(IntegerRegion)

/* Initializers for IntegerRegion */



friend class INIT_TIME_NAME(IntegerRegion,initTimeNonInherited);

  public: /* pseudo constructors */

	/* Essential. Make a region that contains all integers 
	greater than (or equal if inclusive is true) to start. */
	
	static RPTR(IntegerRegion) above (IntegerVar ARG(start), BooleanVar ARG(inclusive));
	
	/* The region containing all position greater than or equal to start */
	
	static RPTR(IntegerRegion) after (IntegerVar ARG(start));
	
	/* The full region of this space */
	
	static INLINE RPTR(IntegerRegion) allIntegers ();
	
	/* The region of all integers less than end.  Does not include end. */
	
	static RPTR(IntegerRegion) before (IntegerVar ARG(end));
	
	/* Make a region that contains all integers less than (or 
	equal if inclusive is true) to stop. */
	
	static RPTR(IntegerRegion) below (IntegerVar ARG(stop), BooleanVar ARG(inclusive));
	
	/* The region of all integers which are >= start and < start + n */
	
	static RPTR(IntegerRegion) integerExtent (IntegerVar ARG(start), IntegerVar ARG(n));
	
	/* The region of all integers which are >= left and < right */
	
	static RPTR(IntegerRegion) interval (IntegerVar ARG(left), IntegerVar ARG(right));
	
	/* No integers, the empty region */
	
	static INLINE RPTR(IntegerRegion) make ();
	
	/* The region with just this one position.  Equivalent to 
	using a converter 
		to convert this position to a region. */
	
	static RPTR(IntegerRegion) make (IntegerVar ARG(singleton));
	
	/* The region of all integers which are >= left and < right */
	
	static RPTR(IntegerRegion) make (IntegerVar ARG(left), IntegerVar ARG(right));
	
  public: /* privacy violator */

	/* used for an efficiency hack in PointRegion.  Don't use. */
	
	static INLINE RPTR(IntegerVarArray) badlyViolatePrivacyOfIntegerRegionTransitions (APTR(IntegerRegion) ARG(reg));
	
  private: /* private: pseudo constructors */

	
	static RPTR(IntegerRegion) usingx (
			BooleanVar ARG(startsInside), 
			Int32 ARG(transitionCount), 
			APTR(IntegerVarArray) ARG(transitions))
	;
	
  public: /* accessing */

	/* Will always return the smallest simple region which 
	contains all my positions */
	
	virtual RPTR(XnRegion) asSimpleRegion ();
	
	/* the region before the last element of the set.  
		What on earth is this for? (Yes, I've looked at senders) */
	
	virtual RPTR(XnRegion) beforeLast ();
	
	/* transform the region into a simple region with left bound 0 
		(or -inf if unbounded).
		What on earth is this for? (Yes, I've looked at senders) */
	/* ((IntegerRegion make: 3 with: 7) unionWith: (IntegerRegion 
	before: -10)) compacted */
	
	virtual RPTR(XnRegion) compacted ();
	
	/* A mapping to transform the region into a simple region 
	with left bound 0 (or -inf if unbounded). The domain of the 
	mapping is precisely this region.
		This is primarily used in XuText Waldos, which only deal 
	with contiguous zero-based regions of data. */
	/* ((IntegerRegion make: 3 with: 7) unionWith: (IntegerRegion 
	after: 10)) compactor */
	
	virtual RPTR(Mapping) compactor ();
	
	
	INLINE RPTR(CoordinateSpace) coordinateSpace ();
	
	/* True if this is either empty or a simple region with lower 
	bound of either 0 or -infinity. Equivalent to
			this->compacted()->isEqual (this) */
	
	virtual BooleanVar isCompacted ();
	
	/* This is a hack for finding the smallest available index to 
	allocate that is not in a particular region (a table domain, 
	for example). */
	
	virtual IntegerVar nearestIntHole (IntegerVar ARG(index));
	
	/* The region starting from pos (inclusive) and going until 
	the next transition. If I contain pos, then I return the 
	longest contiguous region starting at pos of positions I 
	contain. If I don't contain pos, then I return the longest 
	contiguous region starting at pos of positions I do not contain. */
	
	virtual RPTR(IntegerRegion) runAt (IntegerVar ARG(pos));
	
	/* I have a start only if I'm not empty and I am 
	isBoundedBelow. I report as my start the smallest position I 
	*do* contain, which is one greater than the largest position 
	I do not contain. The lower bound of the interval from 3 
	inclusive to 7 exclusive is 3. 
		See 'stop', you may be surprised. */
	
	virtual CLIENT IntegerVar start ();
	
	/* I have a stop only if I'm not empty and I am 
	isBoundedAbove. I report as my stop the smallest position I 
	*do not* contain, which is one greater than the largest 
	position I do contain.  The ustop of the interval from 3 
	inclusive to 7 exclusive is 7.
		See 'start', you may be surprised. */
	
	virtual CLIENT IntegerVar stop ();
	
  public: /* unprotected creation */

	
	IntegerRegion (
			BooleanVar ARG(startsInside), 
			UInt32 ARG(count), 
			APTR(IntegerVarArray) ARG(transitions))
	;
	
  public: /* destroy */

	
	virtual void destroy ();
	
  public: /* printing */

	
	virtual void printOn (ostream& ARG(oo));
	
  public: /* testing */

	
	virtual UInt32 actualHashForEqual ();
	
	/* Unboxed version.  See class comment for XuInteger */
	
	virtual BooleanVar hasIntMember (IntegerVar ARG(key));
	
	
	virtual BooleanVar hasMember (APTR(Position) ARG(pos));
	
	
	virtual BooleanVar intersects (APTR(XnRegion) ARG(region));
	
	/* Either I extend indefinitely to plus infinity, or I am 
	bounded above, not both. 
		The empty region is bounded above despite the fact that it 
	has no upper edge. */
	
	virtual CLIENT BooleanVar isBoundedAbove ();
	
	/* Either I extend indefinitely to minus infinity, or I am 
	bounded below, not both. 
		The empty region is bounded below despite the fact that it 
	has no lower bound. */
	
	INLINE CLIENT BooleanVar isBoundedBelow ();
	
	
	virtual BooleanVar isEmpty ();
	
	
	virtual BooleanVar isEqual (APTR(Heaper) ARG(other));
	
	
	virtual BooleanVar isFinite ();
	
	
	virtual BooleanVar isFull ();
	
	/* Inequalities and intervals are both simple.  See class comment */
	
	virtual BooleanVar isSimple ();
	
	
	virtual BooleanVar isSubsetOf (APTR(XnRegion) ARG(other));
	
  public: /* operations */

	
	virtual RPTR(XnRegion) complement ();
	
	
	virtual RPTR(XnRegion) intersect (APTR(XnRegion) ARG(region));
	
	/* The result is the smallest simple region which satisfies 
	the spec in XuRegion::simpleUnion */
	
	virtual RPTR(XnRegion) simpleUnion (APTR(XnRegion) ARG(otherRegion));
	
	
	virtual RPTR(XnRegion) unionWith (APTR(XnRegion) ARG(region));
	
	
	virtual RPTR(XnRegion) with (APTR(Position) ARG(position));
	
	
	virtual RPTR(XnRegion) withInt (IntegerVar ARG(pos));
	
  public: /* enumerating */

	
	virtual IntegerVar count ();
	
	/* Essential. Break this into an ascending sequence of 
	disjoint intervals (which may be unbounded). */
	
	CLIENT INLINE RPTR(Stepper) OF1(IntegerRegion) intervals (APTR(OrderSpec) ARG(order) = NULL);
	
	/* Actually uses the 'order' argument correctly to enumerate the 
		positions. Treats NULL the same as ascending. Iff I am bounded left 
		am I enumerable in ascending order. Similarly, only if I am bounded 
		right am I enumerable in descending order. */
	
	virtual BooleanVar isEnumerable (APTR(OrderSpec) ARG(order) = NULL);
	
	/* Whether this Region is a non-empty interval, i.e. if A, B 
	in the Region and A <= C <= B then C is in the Region. This 
	includes inequalities (e.g. {x | x > 5}) and the fullRegion 
	in addition to ordinary two-ended intervals. */
	
	INLINE CLIENT BooleanVar isInterval ();
	
  public: /* breaking up */

	
	virtual RPTR(ScruSet) OF1(XnRegion) distinctions ();
	
	/* Treats NULL the same as ascending. For the moment, will only work 
		with an ascending OrderSpec. If a descending OrderSpec is provided, 
		it will currently BLAST, but later will work correctly.
		
		Returns a stepper on a disjoint set of simple regions in ascending 
		order.  No difference with disjointSimpleRegions */
	
	virtual RPTR(Stepper) simpleRegions (APTR(OrderSpec) ARG(order) = NULL);
	
  private: /* private: */

	/* The actuall array. DO NOT MODIFY */
	
	INLINE RPTR(IntegerVarArray) secretTransitions ();
	
	/* the simple region at the given index in the transition array */
	
	virtual RPTR(IntegerRegion) simpleRegionAtIndex (UInt32 ARG(i));
	
  private: /* private: has friends */

	/* Do not send from outside the module. This should not be exported 
		outside the module, but to not export it in this case is 
	some trouble. */
	
	virtual RPTR(IntegerEdgeStepper) edgeStepper ();
	
	/* Do not send from outside the module. This should not be exported 
		outside the module, but to not export it in this case is 
	some trouble. 
		It is used for an efficiency hack in PointRegion. */
	
	INLINE UInt32 transitionCount ();
	
  protected: /* protected: enumerating */

	/* Iff I am bounded left am I enumerable in ascending order. 
	Similarly, only if I am bounded right am I enumerable in 
	descending order. */
	
	virtual RPTR(Stepper) actualStepper (APTR(OrderSpec) ARG(order) = NULL);
	
  private:
	BooleanVar myStartsInside;
	UInt32 myTransitionCount;
	CHKPTR(IntegerVarArray) myTransitions;

  /* ---------- Static Member variables (class vars) ----------- */
  private:
	static GPTR(IntegerRegion) AllIntegers;
	static GPTR(IntegerRegion) EmptyIntegerRegion;
	static GPTR(IntegerRegion) LastAfterRegion;
	static IntegerVar LastAfterStart;
	static IntegerVar LastBeforeEnd;
	static GPTR(IntegerRegion) LastBeforeRegion;
	static GPTR(IntegerRegion) LastInterval;
	static IntegerVar LastLeft;
	static IntegerVar LastRight;
	static IntegerVar LastSingleton;
	static GPTR(IntegerRegion) LastSingletonRegion;
/* Friends for class IntegerRegion */
friend class ID;
friend class IntegerMapping;
friend class IntegerSpace;
friend class PointRegion;
friend class SlicePointRegion;



};  /* end class IntegerRegion */



/* ************************************************************************ *
 * 
 *                    Class IntegerSpace 
 *
 * ************************************************************************ */



/* Initializers for IntegerSpace */







	/* The space of all integers.  See the class comments in 
	IntegerRegion, XuInteger, and IntegerDsp for interesting 
	properties of this space.  Especially IntegerRegion.
		
		IntegerSpaces are the most frequently used of the coordinate 
	spaces.  XuArrays are an efficient data structure which we 
	provide as a table whose domain space is an integer space.  
	In so doing, the notion of an array is made to be simply a 
	particular case of a table indexed by the positions of a 
	coordinate space.  However, IntegerSpaces and XuArrays are 
	both expected to be more efficient than other spaces and 
	tables built on other spaces.  See XuArray */

class IntegerSpace : public CoordinateSpace {

/* Attributes for class IntegerSpace */
	CONCRETE(IntegerSpace)
	PSEUDO_COPY(IntegerSpace,XppCuisine)
	ON_CLIENT(IntegerSpace)
	NO_GC(IntegerSpace)

/* Initializers for IntegerSpace */



friend class INIT_TIME_NAME(IntegerSpace,initTimeNonInherited);

  public: /* creation */

	/* Get the receievr for wire requests. */
	
	static INLINE RPTR(IntegerSpace) implicitReceiver ();
	
	/* return the one integer space */
	
	static INLINE CLIENT RPTR(IntegerSpace) make ();
	
  public: /* rcvr pseudo constructor */

	
	static RPTR(Heaper) make (APTR(Rcvr) ARG(rcvr));
	
  public: /* creation */

	
	IntegerSpace ();
	
  public: /* making */

	/* Essential. Make a region that contains all integers 
	greater than (or equal if inclusive is true) to start. */
	
	virtual CLIENT RPTR(IntegerRegion) above (APTR(IntegerPos) ARG(start), BooleanVar ARG(inclusive));
	
	/* Make a region that contains all integers less than (or 
	equal if inclusive is true) to stop. */
	
	virtual CLIENT RPTR(IntegerRegion) below (APTR(IntegerPos) ARG(stop), BooleanVar ARG(inclusive));
	
	/* Make a region that contains all integers greater than or 
	equal to start and less than stop. */
	
	virtual CLIENT RPTR(IntegerRegion) interval (APTR(IntegerPos) ARG(start), APTR(IntegerPos) ARG(stop));
	
	/* Essential. Make an integer Position object */
	
	INLINE CLIENT RPTR(IntegerPos) position (IntegerVar ARG(value));
	
	/* Essential. Make a Mapping which adds a fixed amount to any value.
		Should this just be supplanted by CoordinateSpace::mapping ()? */
	
	virtual CLIENT RPTR(IntegerMapping) translation (IntegerVar ARG(value));
	
  public: /* testing */

	/* is equal to any basic space on the same category of positions */
	
	virtual UInt32 actualHashForEqual ();
	
	/* is equal to any basic space on the same category of positions */
	
	virtual BooleanVar isEqual (APTR(Heaper) ARG(anObject));
	


  /* ---------- Static Member variables (class vars) ----------- */
  private:
	static GPTR(IntegerSpace) TheIntegerSpace;
/* Friends for class IntegerSpace */
/* friends for class IntegerSpace */

friend class IntegerRegion;
friend class IntegerDsp;



};  /* end class IntegerSpace */


#ifdef USE_INLINE
#ifndef INTEGERX_IXX
#include "integerx.ixx"
#endif /* INTEGERX_IXX */


#endif /* USE_INLINE */


#endif /* INTEGERX_HXX */

