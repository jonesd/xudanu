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

#ifndef SPACEP_HXX
#define SPACEP_HXX


#ifndef TOFUX_HXX
#include "tofux.hxx"
#endif /* TOFUX_HXX */

#ifndef INTVARX_HXX
#include "intvarx.hxx"
#endif /* INTVARX_HXX */

#ifndef SPACEX_HXX
#include "spacex.hxx"
#endif /* SPACEX_HXX */

#ifndef SPACEP_OXX
#include "spacep.oxx"
#endif /* SPACEP_OXX */


#ifndef STEPPERX_HXX
#include "stepperx.hxx"
#endif /* STEPPERX_HXX */


#ifndef SETX_OXX
#include "setx.oxx"
#endif /* SETX_OXX */


/*  */
/*  */




/* ************************************************************************ *
 * 
 *                    Class CompositeMapping 
 *
 * ************************************************************************ */




	/* NO CLASS COMMENT */

class CompositeMapping : public Mapping {

/* Attributes for class CompositeMapping */
	CONCRETE(CompositeMapping)
	NOT_A_TYPE(CompositeMapping)
	COPY(CompositeMapping,XppCuisine)
	AUTO_GC(CompositeMapping)
  public: /* functions */

	
	static RPTR(Mapping) privateMakeMapping (
			APTR(CoordinateSpace) ARG(cs), 
			APTR(CoordinateSpace) ARG(rs), 
			APTR(ImmuSet) OF1(Mapping) ARG(mappings))
	;
	
	/* store a map into the set, checking to see if it can be 
	combined with another */
	
	static void storeMapping (APTR(Mapping) ARG(map), APTR(MuSet) OF1(Mapping) ARG(maps));
	
  public: /* operations */

	
	virtual RPTR(Mapping) appliedAfter (APTR(Dsp) ARG(dsp));
	
	
	virtual RPTR(Mapping) inverse ();
	
	
	virtual RPTR(Mapping) preCompose (APTR(Dsp) ARG(dsp));
	
	
	virtual RPTR(Mapping) restrict (APTR(XnRegion) ARG(region));
	
	
	virtual RPTR(Mapping) restrictRange (APTR(XnRegion) ARG(region));
	
	
	virtual RPTR(Mapping) transformedBy (APTR(Dsp) ARG(dsp));
	
  public: /* accessing */

	
	virtual RPTR(CoordinateSpace) coordinateSpace ();
	
	
	virtual RPTR(XnRegion) domain ();
	
	
	virtual RPTR(Dsp) OR(NULL) fetchDsp ();
	
	
	virtual BooleanVar isComplete ();
	
	
	virtual BooleanVar isIdentity ();
	
	
	virtual RPTR(XnRegion) range ();
	
	
	virtual RPTR(CoordinateSpace) rangeSpace ();
	
	
	virtual RPTR(ImmuSet) OF1(Mapping) simpleMappings ();
	
	
	virtual RPTR(ImmuSet) OF1(Mapping) simpleRegionMappings ();
	
  public: /* transforming */

	
	virtual RPTR(Position) inverseOf (APTR(Position) ARG(pos));
	
	
	virtual RPTR(XnRegion) inverseOfAll (APTR(XnRegion) ARG(reg));
	
	
	virtual RPTR(Position) of (APTR(Position) ARG(pos));
	
	
	virtual RPTR(XnRegion) ofAll (APTR(XnRegion) ARG(reg));
	
  public: /* printing */

	
	virtual void printOn (ostream& ARG(stream));
	
  private: /* private: private creation */

	
	CompositeMapping (
			APTR(CoordinateSpace) ARG(cs), 
			APTR(CoordinateSpace) ARG(rs), 
			APTR(ImmuSet) OF1(Mapping) ARG(mappings))
	;
	
  public: /* testing */

	
	virtual UInt32 actualHashForEqual ();
	
	
	virtual BooleanVar isEqual (APTR(Heaper) ARG(other));
	
  protected: /* protected: protected */

	
	virtual RPTR(Mapping) fetchCombine (APTR(Mapping) ARG(mapping));
	
  private:
	CHKPTR(CoordinateSpace) myCS;
	CHKPTR(CoordinateSpace) myRS;
	CHKPTR(ImmuSet) OF1(Mapping) myMappings;
/* Friends for class CompositeMapping */
/* friends for class CompositeMapping */
friend SPTR(Mapping) mapping(Mapping*, Mapping*);
friend SPTR(Mapping)  privateMakeMapping (CoordinateSpace *, CoordinateSpace *, ImmuSet OF1(Mapping) *);


};  /* end class CompositeMapping */



/* ************************************************************************ *
 * 
 *                    Class ConstantMapping 
 *
 * ************************************************************************ */




	/* NO CLASS COMMENT */

class ConstantMapping : public Mapping {

/* Attributes for class ConstantMapping */
	CONCRETE(ConstantMapping)
	NOT_A_TYPE(ConstantMapping)
	COPY(ConstantMapping,XppCuisine)
	AUTO_GC(ConstantMapping)
  public: /* creation */

	
	ConstantMapping (APTR(CoordinateSpace) ARG(cs), APTR(XnRegion) ARG(values));
	
  public: /* transforming */

	
	virtual RPTR(Position) inverseOf (APTR(Position) ARG(pos));
	
	
	virtual RPTR(XnRegion) inverseOfAll (APTR(XnRegion) ARG(reg));
	
	
	virtual RPTR(Position) of (APTR(Position) ARG(pos));
	
	
	virtual RPTR(XnRegion) ofAll (APTR(XnRegion) ARG(reg));
	
  public: /* accessing */

	
	virtual RPTR(Mapping) appliedAfter (APTR(Dsp) ARG(dsp));
	
	
	virtual RPTR(CoordinateSpace) coordinateSpace ();
	
	
	virtual RPTR(XnRegion) domain ();
	
	
	virtual RPTR(Dsp) OR(NULL) fetchDsp ();
	
	
	virtual BooleanVar isComplete ();
	
	
	virtual BooleanVar isIdentity ();
	
	
	virtual RPTR(Mapping) preCompose (APTR(Dsp) ARG(dsp));
	
	
	virtual RPTR(XnRegion) range ();
	
	
	virtual RPTR(CoordinateSpace) rangeSpace ();
	
	
	virtual RPTR(ImmuSet) OF1(Mapping) simpleMappings ();
	
	
	virtual RPTR(ImmuSet) OF1(Mapping) simpleRegionMappings ();
	
	
	virtual RPTR(Mapping) transformedBy (APTR(Dsp) ARG(dsp));
	
  public: /* printing */

	
	virtual void printOn (ostream& ARG(oo));
	
  public: /* testing */

	
	virtual UInt32 actualHashForEqual ();
	
	
	virtual BooleanVar isEqual (APTR(Heaper) ARG(other));
	
  private: /* private: private */

	
	virtual RPTR(XnRegion) values ();
	
  public: /* operations */

	
	virtual RPTR(Mapping) inverse ();
	
	
	virtual RPTR(Mapping) restrict (APTR(XnRegion) ARG(region));
	
	
	virtual RPTR(Mapping) restrictRange (APTR(XnRegion) ARG(region));
	
  public: /* protected */

	
	virtual RPTR(Mapping) fetchCombine (APTR(Mapping) ARG(aMapping));
	
  private:
	CHKPTR(CoordinateSpace) myCoordinateSpace;
	CHKPTR(XnRegion) myValues;
	friend class Mapping;
};  /* end class ConstantMapping */



/* ************************************************************************ *
 * 
 *                    Class DisjointRegionStepper 
 *
 * ************************************************************************ */




	/* NO CLASS COMMENT */

class DisjointRegionStepper : public Stepper {

/* Attributes for class DisjointRegionStepper */
	CONCRETE(DisjointRegionStepper)
	NOT_A_TYPE(DisjointRegionStepper)
	AUTO_GC(DisjointRegionStepper)
  public: /* instance creation */

	
	static RPTR(Stepper) make (APTR(XnRegion) ARG(region), APTR(OrderSpec) ARG(order));
	
  public: /* accessing */

	
	virtual WPTR(Heaper) fetch ();
	
	
	virtual BooleanVar hasValue ();
	
	
	virtual void step ();
	
  public: /* instance creation */

	
	virtual RPTR(Stepper) copy ();
	
	
	DisjointRegionStepper (APTR(XnRegion) ARG(region), APTR(OrderSpec) ARG(order));
	
  private:
	CHKPTR(XnRegion) myValue;
	CHKPTR(XnRegion) myRegion;
	CHKPTR(OrderSpec) myOrder;
};  /* end class DisjointRegionStepper */



/* ************************************************************************ *
 * 
 *                    Class EmptyMapping 
 *
 * ************************************************************************ */



/* Initializers for EmptyMapping */




	/* NO CLASS COMMENT */

class EmptyMapping : public Mapping {

/* Attributes for class EmptyMapping */
	CONCRETE(EmptyMapping)
	NOT_A_TYPE(EmptyMapping)
	COPY(EmptyMapping,XppCuisine)
	AUTO_GC(EmptyMapping)

/* Initializers for EmptyMapping */


  public: /* pseudoconstructor */

	
	static RPTR(Mapping) make (APTR(CoordinateSpace) ARG(cs), APTR(CoordinateSpace) ARG(rs));
	
  public: /* accessing */

	
	virtual RPTR(CoordinateSpace) coordinateSpace ();
	
	
	virtual RPTR(XnRegion) domain ();
	
	
	virtual RPTR(Dsp) OR(NULL) fetchDsp ();
	
	
	virtual BooleanVar isComplete ();
	
	
	virtual BooleanVar isIdentity ();
	
	
	virtual RPTR(XnRegion) range ();
	
	
	virtual RPTR(CoordinateSpace) rangeSpace ();
	
	
	virtual RPTR(ImmuSet) OF1(Mapping) simpleMappings ();
	
	
	virtual RPTR(ImmuSet) OF1(Mapping) simpleRegionMappings ();
	
  public: /* transforming */

	
	virtual RPTR(Position) inverseOf (APTR(Position) ARG(pos));
	
	
	virtual RPTR(XnRegion) inverseOfAll (APTR(XnRegion) ARG(reg));
	
	
	virtual RPTR(Position) of (APTR(Position) ARG(pos));
	
	
	virtual RPTR(XnRegion) ofAll (APTR(XnRegion) ARG(reg));
	
  private: /* private: private creation */

	
	EmptyMapping (APTR(CoordinateSpace) ARG(cs), APTR(CoordinateSpace) ARG(rs));
	
  public: /* printing */

	
	virtual void printOn (ostream& ARG(stream));
	
  public: /* testing */

	
	virtual UInt32 actualHashForEqual ();
	
	/* This, and the CompositeMapping version, don't check 
	CoordinateSpaces.  Should they? */
	
	virtual BooleanVar isEqual (APTR(Heaper) ARG(other));
	
  public: /* operations */

	
	virtual RPTR(Mapping) appliedAfter (APTR(Dsp) ARG(dsp));
	
	
	virtual RPTR(Mapping) inverse ();
	
	
	virtual RPTR(Mapping) preCompose (APTR(Dsp) ARG(dsp));
	
	
	virtual RPTR(Mapping) restrict (APTR(XnRegion) ARG(region));
	
	
	virtual RPTR(Mapping) restrictRange (APTR(XnRegion) ARG(region));
	
	
	virtual RPTR(Mapping) transformedBy (APTR(Dsp) ARG(dsp));
	
  protected: /* protected: protected */

	
	virtual RPTR(Mapping) fetchCombine (APTR(Mapping) ARG(mapping));
	
  private:
	CHKPTR(CoordinateSpace) myCS;
	CHKPTR(CoordinateSpace) myRS;

  /* ---------- Static Member variables (class vars) ----------- */
  private:
	static GPTR(Mapping) LastEmptyMapping;
	static GPTR(CoordinateSpace) LastEmptyMappingCoordinateSpace;
	static GPTR(CoordinateSpace) LastEmptyMappingRangeSpace;
/* Friends for class EmptyMapping */
/* friends for class EmptyMapping */
friend SPTR(Mapping) emptyMapping (CoordinateSpace * cs, CoordinateSpace * rs);



	friend class Mapping;
};  /* end class EmptyMapping */



/* ************************************************************************ *
 * 
 *                    Class ReverseOrder 
 *
 * ************************************************************************ */




	/* NO CLASS COMMENT */

class ReverseOrder : public OrderSpec {

/* Attributes for class ReverseOrder */
	CONCRETE(ReverseOrder)
	COPY(ReverseOrder,XppCuisine)
	NOT_A_TYPE(ReverseOrder)
	AUTO_GC(ReverseOrder)
  public: /* pseudoconstructors */

	
	static RPTR(OrderSpec) make (APTR(OrderSpec) ARG(order));
	
  public: /* accessing */

	
	virtual RPTR(CoordinateSpace) coordinateSpace ();
	
	
	virtual RPTR(OrderSpec) reversed ();
	
  public: /* testing */

	
	virtual UInt32 actualHashForEqual ();
	
	
	virtual BooleanVar follows (APTR(Position) ARG(x), APTR(Position) ARG(y));
	
	
	virtual BooleanVar followsInt (IntegerVar ARG(x), IntegerVar ARG(y));
	
	
	virtual BooleanVar isEqual (APTR(Heaper) ARG(other));
	
	
	virtual BooleanVar isFullOrder (APTR(XnRegion) ARG(keys) = NULL);
	
	/* Return true if some position in before is less than or 
	equal to all positions in after. */
	
	virtual BooleanVar preceeds (APTR(XnRegion) ARG(before), APTR(XnRegion) ARG(after));
	
  private: /* private: creation */

	
	ReverseOrder (APTR(OrderSpec) ARG(order), TCSJ);
	
  private:
	CHKPTR(OrderSpec) myOrder;
};  /* end class ReverseOrder */



/* ************************************************************************ *
 * 
 *                    Class SimpleMapping 
 *
 * ************************************************************************ */




	/* NO CLASS COMMENT */

class SimpleMapping : public Mapping {

/* Attributes for class SimpleMapping */
	CONCRETE(SimpleMapping)
	COPY(SimpleMapping,XppCuisine)
	AUTO_GC(SimpleMapping)
  public: /* pseudo constructors */

	
	static RPTR(Mapping) restrictTo (APTR(XnRegion) ARG(region), APTR(Mapping) ARG(mapping));
	
  public: /* accessing */

	
	virtual RPTR(Mapping) appliedAfter (APTR(Dsp) ARG(dsp));
	
	
	virtual RPTR(CoordinateSpace) coordinateSpace ();
	
	
	virtual RPTR(XnRegion) domain ();
	
	
	virtual RPTR(Dsp) OR(NULL) fetchDsp ();
	
	
	virtual BooleanVar isComplete ();
	
	
	virtual BooleanVar isIdentity ();
	
	
	virtual RPTR(Mapping) preCompose (APTR(Dsp) ARG(dsp));
	
	
	virtual RPTR(XnRegion) range ();
	
	
	virtual RPTR(CoordinateSpace) rangeSpace ();
	
	
	virtual RPTR(ImmuSet) OF1(Mapping) simpleMappings ();
	
	
	virtual RPTR(ImmuSet) OF1(Mapping) simpleRegionMappings ();
	
	
	virtual RPTR(Mapping) transformedBy (APTR(Dsp) ARG(dsp));
	
  public: /* transforming */

	
	virtual RPTR(Position) inverseOf (APTR(Position) ARG(pos));
	
	
	virtual RPTR(XnRegion) inverseOfAll (APTR(XnRegion) ARG(reg));
	
	
	virtual RPTR(Position) of (APTR(Position) ARG(pos));
	
	
	virtual RPTR(XnRegion) ofAll (APTR(XnRegion) ARG(reg));
	
  public: /* operations */

	
	virtual RPTR(Mapping) inverse ();
	
	
	virtual RPTR(Mapping) restrict (APTR(XnRegion) ARG(region));
	
	
	virtual RPTR(Mapping) restrictRange (APTR(XnRegion) ARG(region));
	
  public: /* printing */

	
	virtual void printOn (ostream& ARG(oo));
	
  private: /* private: private creation */

	
	SimpleMapping (APTR(XnRegion) ARG(region), APTR(Mapping) ARG(mapping));
	
  public: /* testing */

	
	virtual UInt32 actualHashForEqual ();
	
	
	virtual BooleanVar isEqual (APTR(Heaper) ARG(other));
	
  private: /* private: private */

	
	virtual RPTR(Mapping) mapping ();
	
  public: /* protected */

	
	virtual RPTR(Mapping) fetchCombine (APTR(Mapping) ARG(mapping));
	
  private:
	CHKPTR(XnRegion) myRegion;
	CHKPTR(Mapping) myMapping;
/* Friends for class SimpleMapping */
/* friends for class SimpleMapping */
friend SPTR(Mapping) restrictTo (XnRegion*, Mapping*);



	friend class Mapping;
};  /* end class SimpleMapping */



#endif /* SPACEP_HXX */

