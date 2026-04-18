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

#ifndef HSPACEP_HXX
#define HSPACEP_HXX


#ifndef TOFUX_HXX
#include "tofux.hxx"
#endif /* TOFUX_HXX */

#ifndef INTVARX_HXX
#include "intvarx.hxx"
#endif /* INTVARX_HXX */

#ifndef HSPACEX_HXX
#include "hspacex.hxx"
#endif /* HSPACEX_HXX */

#ifndef HSPACEP_OXX
#include "hspacep.oxx"
#endif /* HSPACEP_OXX */


#ifndef SPACER_HXX
#include "spacer.hxx"
#endif /* SPACER_HXX */


#ifndef NXCVRX_OXX
#include "nxcvrx.oxx"
#endif /* NXCVRX_OXX */

#ifndef SETX_OXX
#include "setx.oxx"
#endif /* SETX_OXX */

#ifndef STEPPERX_OXX
#include "stepperx.oxx"
#endif /* STEPPERX_OXX */


/*  */
/*  */




/* ************************************************************************ *
 * 
 *                    Class HeaperDsp 
 *
 * ************************************************************************ */



/* Initializers for HeaperDsp */
/* Declaration inherited from IdentityDsp */




/* Declaration inherited from IdentityDsp */





	/* NO CLASS COMMENT */

class HeaperDsp : public IdentityDsp {

/* Attributes for class HeaperDsp */
	CONCRETE(HeaperDsp)
	PSEUDO_COPY(HeaperDsp,XppCuisine)
	NOT_A_TYPE(HeaperDsp)
	NO_GC(HeaperDsp)

/* Initializers for HeaperDsp */
/* Declaration inherited from IdentityDsp */




/* Declaration inherited from IdentityDsp */

friend class INIT_TIME_NAME(HeaperDsp,initTimeInherited);

  public: /* pseudo constructors */

	
	static RPTR(Dsp) make ();
	
	
	static RPTR(Heaper) make (APTR(Rcvr) ARG(rcvr));
	
  public: /* accessing */

	
	virtual RPTR(CoordinateSpace) coordinateSpace ();
	
  public: /* creation */

	
	HeaperDsp ();
	


  /* ---------- Static Member variables (class inst vars) ----------- */
  private:
	static IdentityDsp * theDsp;
};  /* end class HeaperDsp */



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
				
		SetRegion is our answer to that.  To start with, a set 
	region can simply be an enumeration of the positions which 
	are its members.  However, because the complement of an 
	XuRegion must be a valid XuRegion, and we have no other 
	representation of the infinite set of positions left over, we 
	must also be able to represent the region consisting of all 
	positions except those explicitly enumerated.  Every 
	SetRegion must either have a finite number of positions, or 
	it must cover all the space except for a finite number of positions.
		
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
		
		Cases 1, 3, and 5 can be considered the "positive" regions, 
	and cases 2, 4, and 6 the "negative" ones.
		
		Because we only have distinctions (which we are currently 
	doing for an internal reason which will probably go away), we 
	forego the ability to use the generic XuRegion protocol to 
	decompose complex regions into simpler ones.  Instead we 
	provide SetRegion specific protocol ("positions" and "isComplement").  
		
		At a later time, we will probably have cases 1 thru 4 above 
	be the only distinctions, case 6 be a simple region but not a 
	distinction, and have case 5 be a non-simple region.  (These 
	choices are all consistent with the letter and spirit of the 
	simplicity framework documented in XuRegion.  Simple regions 
	must be the *intersection* of distinctions, therefore case 5 
	cannot be a simple non-distinction.)  Please try to write 
	your software so that it'll be insensitive to this change.  Thanks.
		
		SetRegion is an abstract superclass useful for defining 
	regions for spaces which have the constraints listed above. */

class SetRegion : public XnRegion {

/* Attributes for class SetRegion */
	DEFERRED(SetRegion)
	COPY(SetRegion,XppCuisine)
	AUTO_GC(SetRegion)
  public: /* accessing */

	
	virtual RPTR(XnRegion) asSimpleRegion ();
	
	
	virtual RPTR(ScruSet) OF1(XnRegion) distinctions ();
	
	/* FALSE means that I'm a 'positive' region (see class comment).  
		TRUE means I'm a negative region. */
	
	INLINE BooleanVar isComplement ();
	
	/* If I'm a positive region (see class comment and isComplement), then 
		this is a list of those positions I contain. If I'm 
	negative, then it's 
		those positions I don't contain. */
	
	INLINE WPTR(ImmuSet) OF1(Position) positions ();
	
	/* Make up a singleton set containing the whole region */
	
	virtual RPTR(Stepper) simpleRegions (APTR(OrderSpec) ARG(order) = NULL);
	
  public: /* enumerating */

	
	virtual IntegerVar count ();
	
	
	virtual BooleanVar isEnumerable (APTR(OrderSpec) ARG(order) = NULL);
	
	
	virtual RPTR(Position) theOne ();
	
  public: /* operations */

	
	virtual RPTR(XnRegion) complement ();
	
	
	virtual RPTR(XnRegion) intersect (APTR(XnRegion) ARG(region));
	
	
	virtual RPTR(XnRegion) minus (APTR(XnRegion) ARG(other));
	
	
	virtual RPTR(XnRegion) simpleUnion (APTR(XnRegion) ARG(other));
	
	
	virtual RPTR(XnRegion) unionWith (APTR(XnRegion) ARG(region));
	
	
	virtual RPTR(XnRegion) with (APTR(Position) ARG(pos));
	
	
	virtual RPTR(XnRegion) without (APTR(Position) ARG(pos));
	
  public: /* testing */

	
	virtual UInt32 actualHashForEqual ();
	
	
	virtual BooleanVar hasMember (APTR(Position) ARG(atPos));
	
	
	virtual BooleanVar intersects (APTR(XnRegion) ARG(region));
	
	
	virtual BooleanVar isEmpty ();
	
	
	virtual BooleanVar isEqual (APTR(Heaper) ARG(other));
	
	
	virtual BooleanVar isFinite ();
	
	
	virtual BooleanVar isFull ();
	
	
	virtual BooleanVar isSimple ();
	
	
	virtual BooleanVar isSubsetOf (APTR(XnRegion) ARG(other));
	
  protected: /* protected: creation */

	/* the set should be for my use alone */
	
	SetRegion (BooleanVar ARG(cmp), APTR(ImmuSet) OF1(Position) ARG(set));
	
  public: /* printing */

	
	virtual void printOn (ostream& ARG(oo));
	
  protected: /* protected: protected deferred */

	
	virtual RPTR(XnRegion) makeNew (BooleanVar ARG(isComplement), APTR(ImmuSet) OF1(Position) ARG(positions)) DEFERRED_FUNC;
	
  public: /* deferred accessing */

	
	virtual RPTR(CoordinateSpace) coordinateSpace () DEFERRED_FUNC;
	
  protected: /* protected: enumerating */

	
	virtual RPTR(Stepper) actualStepper (APTR(OrderSpec) ARG(order));
	
  private:
	CHKPTR(ImmuSet) OF1(Position) myPositions;
	BooleanVar myIsComplement;
/* Friends for class SetRegion */
/* friends for class SetRegion */
SPTR(SetRegion) setRegion (CoordinateSpace * cs, ImmuSet * aSet);
friend class SetRegionStepper;



};  /* end class SetRegion */



/* ************************************************************************ *
 * 
 *                    Class   HeaperRegion 
 *
 * ************************************************************************ */




	/* NO CLASS COMMENT */

class HeaperRegion : public SetRegion {

/* Attributes for class HeaperRegion */
	CONCRETE(HeaperRegion)
	NOT_A_TYPE(HeaperRegion)
	COPY(HeaperRegion,XppCuisine)
	NO_GC(HeaperRegion)
  public: /* pseudo constructors */

	
	static RPTR(SetRegion) allHeaperAsPositions ();
	
	
	static RPTR(SetRegion) make ();
	
	
	static RPTR(SetRegion) make (APTR(HeaperAsPosition) ARG(heaper));
	
	
	static RPTR(SetRegion) make (APTR(ScruSet) OF1(HeaperAsPosition) ARG(heapers));
	
  public: /* accessing */

	
	virtual RPTR(CoordinateSpace) coordinateSpace ();
	
  protected: /* protected: protected */

	
	virtual RPTR(XnRegion) makeNew (BooleanVar ARG(isComplement), APTR(ImmuSet) OF1(Position) ARG(positions));
	
  public: /* testing */

	
	virtual BooleanVar isEnumerable (APTR(OrderSpec) ARG(order) = NULL);
	
  public: /* creation */

	
	HeaperRegion (BooleanVar ARG(isComplement), APTR(ImmuSet) OF1(HeaperAsPosition) ARG(positions));
	

};  /* end class HeaperRegion */



/* ************************************************************************ *
 * 
 *                    Class StrongAsPosition 
 *
 * ************************************************************************ */




	/* NO CLASS COMMENT */

class StrongAsPosition : public HeaperAsPosition {

/* Attributes for class StrongAsPosition */
	CONCRETE(StrongAsPosition)
	NOT_A_TYPE(StrongAsPosition)
	COPY(StrongAsPosition,XppCuisine)
	AUTO_GC(StrongAsPosition)
  public: /* testing */

	
	virtual UInt32 actualHashForEqual ();
	
	
	virtual BooleanVar isEqual (APTR(Heaper) ARG(other));
	
  public: /* accessing */

	
	virtual RPTR(CoordinateSpace) coordinateSpace ();
	
	
	virtual RPTR(Heaper) heaper ();
	
  public: /* printing */

	
	virtual void printOn (ostream& ARG(oo));
	
  public: /* instance creation */

	
	StrongAsPosition (APTR(Heaper) ARG(aHeaper), TCSJ);
	
  private:
	CHKPTR(Heaper) itsHeaper;
	friend class HeaperAsPosition;
};  /* end class StrongAsPosition */


#ifdef USE_INLINE
#ifndef HSPACEP_IXX
#include "hspacep.ixx"
#endif /* HSPACEP_IXX */


#endif /* USE_INLINE */


#endif /* HSPACEP_HXX */

