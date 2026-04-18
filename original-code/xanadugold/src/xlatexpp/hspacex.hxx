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

#ifndef HSPACEX_HXX
#define HSPACEX_HXX


#ifndef TOFUX_HXX
#include "tofux.hxx"
#endif /* TOFUX_HXX */

#ifndef INTVARX_HXX
#include "intvarx.hxx"
#endif /* INTVARX_HXX */

#ifndef HSPACEX_OXX
#include "hspacex.oxx"
#endif /* HSPACEX_OXX */


#ifndef INITX_HXX
#include "initx.hxx"
#endif /* INITX_HXX */

#ifndef SPACEX_HXX
#include "spacex.hxx"
#endif /* SPACEX_HXX */


#ifndef NXCVRX_OXX
#include "nxcvrx.oxx"
#endif /* NXCVRX_OXX */


/*  */
/*  */




/* ************************************************************************ *
 * 
 *                    Class HeaperSpace 
 *
 * ************************************************************************ */



/* Initializers for HeaperSpace */







	/* A HeaperSpace is one whose positions represent the 
	identity of individual Heapers.  Identity of a Heaper is 
	determined according by its response to "isEqual" and 
	"hashForEqual" (see "The Equality of Decisions" for a bunch 
	of surprising issues regarding Heaper equality).  A region is 
	a HeaperSpace is a SetRegion (see SetRegion).  As a result of 
	having HeaperSpaces, one can use the identity of Heapers to 
	index into hash tables, and still obey the convention that a 
	table maps from positions in some coordinate space.
		
		HeaperSpaces cannot (yet?) be used as the domain space for 
	Xanadu Stamps, and therefore also not as the domain space of 
	an IndexedWaldo.  In order to do this, the Heapers in 
	question would have to persist in a way that Xanadu doesn't 
	provide for.
		
		As is typical for an unordered space, the only Dsp for this 
	space is the identity Dsp.  No type or pseudo-constructor is 
	exported however--the Dsp is gotten by converting a 
	HeaperSpace to a Dsp.  Similarly, no heaper-specific type or 
	pseudo-constructor is exported for my regions.  The 
	conversions are sufficient.  The resulting regions are 
	guaranteed to be SetRegions. */

class HeaperSpace : public CoordinateSpace {

/* Attributes for class HeaperSpace */
	CONCRETE(HeaperSpace)
	PSEUDO_COPY(HeaperSpace,XppCuisine)
	NO_GC(HeaperSpace)

/* Initializers for HeaperSpace */



friend class INIT_TIME_NAME(HeaperSpace,initTimeNonInherited);

  public: /* pseudo constructors */

	/* Return the one instance of HeaperSpace */
	
	static INLINE RPTR(HeaperSpace) make ();
	
  public: /* rcvr pseudo constructor */

	
	static RPTR(Heaper) make (APTR(Rcvr) ARG(rcvr));
	
  public: /* creation */

	
	HeaperSpace ();
	
  public: /* testing */

	/* is equal to any basic space on the same category of positions */
	
	virtual UInt32 actualHashForEqual ();
	
	/* is equal to any basic space on the same category of positions */
	
	virtual BooleanVar isEqual (APTR(Heaper) ARG(anObject));
	


  /* ---------- Static Member variables (class vars) ----------- */
  private:
	static GPTR(HeaperSpace) TheHeaperSpace;
};  /* end class HeaperSpace */



/* ************************************************************************ *
 * 
 *                    Class UnOrdered 
 *
 * ************************************************************************ */




	/* A convenient superclass of all Positions which have no 
	natural ordering.  See UnOrdered::isGE for the defining 
	property of this class.  This class should probably go away 
	and UnOrdered::isGE distributed to the subclasses. */

class UnOrdered : public Position {

/* Attributes for class UnOrdered */
	DEFERRED(UnOrdered)
	NOT_A_TYPE(UnOrdered)
	NO_GC(UnOrdered)
  public: /* accessing */

	
	virtual RPTR(XnRegion) asRegion () DEFERRED_FUNC;
	
	
	virtual RPTR(CoordinateSpace) coordinateSpace () DEFERRED_FUNC;
	
  public: /* testing */

	
	virtual UInt32 actualHashForEqual ();
	
	/* Up in position, isGE is deferred, and isEqual is defined 
	in terms of isEqual.
		Here in UnOrdered, we define isGE in terms of isEqual, so we 
	must redefine
		isEqual to be deferred. */
	
	virtual BooleanVar isEqual (APTR(Heaper) ARG(other)) DEFERRED_FUNC;
	

	/* automatic 0-argument constructor */
  public:
	UnOrdered();

};  /* end class UnOrdered */



/* ************************************************************************ *
 * 
 *                    Class   HeaperAsPosition 
 *
 * ************************************************************************ */




	/* A position in a HeaperSpace that represents the identity 
	of some particular Heaper.  See class comment in HeaperSpace. */

class HeaperAsPosition : public UnOrdered {

/* Attributes for class HeaperAsPosition */
	DEFERRED(HeaperAsPosition)
	NO_GC(HeaperAsPosition)
  public: /* pseudo constructors */

	/* Return a HeaperAsPosition which represents the identity of 
	this Heaper.  The resulting HeaperAsPosition will strongly 
	retain the original Heaper against garbage collection (though 
	not of course against manual deletion).  See wimpyAsPosition */
	
	static RPTR(HeaperAsPosition) make (APTR(Heaper) ARG(heaper));
	
  public: /* testing */

	
	virtual UInt32 actualHashForEqual ();
	
	
	virtual BooleanVar isEqual (APTR(Heaper) ARG(other)) DEFERRED_FUNC;
	
  public: /* accessing */

	
	INLINE RPTR(XnRegion) asRegion ();
	
	
	virtual RPTR(CoordinateSpace) coordinateSpace () DEFERRED_FUNC;
	
	/* Return the underlying Heaper whose identity (as a position) I 
		represent. 
		
		It is considered good form not to use this message. There is some 
		controversy as to whether it will go away in the future. If you 
		know of any good reason why it should stick around please let us 
		know. */
	
	virtual RPTR(Heaper) heaper () DEFERRED_FUNC;
	

	/* automatic 0-argument constructor */
  public:
	HeaperAsPosition();

};  /* end class HeaperAsPosition */


#ifdef USE_INLINE
#ifndef HSPACEX_IXX
#include "hspacex.ixx"
#endif /* HSPACEX_IXX */


#endif /* USE_INLINE */


#endif /* HSPACEX_HXX */

