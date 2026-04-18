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

#ifndef NKERNELP_HXX
#define NKERNELP_HXX


#ifndef TOFUX_HXX
#include "tofux.hxx"
#endif /* TOFUX_HXX */

#ifndef INTVARX_HXX
#include "intvarx.hxx"
#endif /* INTVARX_HXX */

#ifndef NKERNELX_HXX
#include "nkernelx.hxx"
#endif /* NKERNELX_HXX */

#ifndef NKERNELP_OXX
#include "nkernelp.oxx"
#endif /* NKERNELP_OXX */


#ifndef STEPPERX_HXX
#include "stepperx.hxx"
#endif /* STEPPERX_HXX */

#ifndef WPARRAYX_HXX
#include "wparrayx.hxx"
#endif /* WPARRAYX_HXX */


#ifndef BRANGE1X_OXX
#include "brange1x.oxx"
#endif /* BRANGE1X_OXX */

#ifndef BRANGE3X_OXX
#include "brange3x.oxx"
#endif /* BRANGE3X_OXX */

#ifndef DETECTX_OXX
#include "detectx.oxx"
#endif /* DETECTX_OXX */

#ifndef IDX_OXX
#include "idx.oxx"
#endif /* IDX_OXX */

#ifndef PRIMVALX_OXX
#include "primvalx.oxx"
#endif /* PRIMVALX_OXX */

#ifndef SPACEX_OXX
#include "spacex.oxx"
#endif /* SPACEX_OXX */


/*  */
/*  */




/* ************************************************************************ *
 * 
 *                    Class EditionStepper 
 *
 * ************************************************************************ */




	/* NO CLASS COMMENT */

class EditionStepper : public TableStepper {

/* Attributes for class EditionStepper */
	CONCRETE(EditionStepper)
	NOT_A_TYPE(EditionStepper)
	AUTO_GC(EditionStepper)
  public: /* create */

	
	virtual RPTR(Stepper) copy ();
	
	
	EditionStepper (APTR(Stepper) OF1(Position) ARG(keys), APTR(FeEdition) ARG(edition));
	
  public: /* special */

	
	virtual RPTR(Position) position ();
	
  public: /* operations */

	
	virtual WPTR(Heaper) fetch ();
	
	
	virtual BooleanVar hasValue ();
	
	
	virtual void step ();
	
  private:
	CHKPTR(Stepper) OF1(Position) myKeys;
	CHKPTR(FeEdition) myEdition;
};  /* end class EditionStepper */



/* ************************************************************************ *
 * 
 *                    Class FeActualDataHolder 
 *
 * ************************************************************************ */




	/* Actually has a persistent individual DataHolder on the Server */

class FeActualDataHolder : public FeDataHolder {

/* Attributes for class FeActualDataHolder */
	CONCRETE(FeActualDataHolder)
	NOT_A_TYPE(FeActualDataHolder)
	AUTO_GC(FeActualDataHolder)
  public: /* client accessing */

	/* I'm completely reified.  Just return me. */
	
	virtual RPTR(FeRangeElement) again ();
	
	/* The actual data value */
	
	virtual RPTR(PrimValue) value ();
	
  public: /* server accessing */

	
	virtual RPTR(BeRangeElement) OR(NULL) fetchBe ();
	
	
	virtual RPTR(BeRangeElement) getOrMakeBe ();
	
  private: /* private: create */

	
	FeActualDataHolder (APTR(BeDataHolder) ARG(be), TCSJ);
	
  public: /* destruct */

	
	virtual void destruct ();
	
  private:
	CHKPTR(BeDataHolder) myBeDataHolder;
	friend class FeDataHolder;
};  /* end class FeActualDataHolder */



/* ************************************************************************ *
 * 
 *                    Class FeActualPlaceHolder 
 *
 * ************************************************************************ */




	/* Actually has a persistent individual PlaceHolder on the 
	Server, or used to, and now has a pointer to the rangeElement 
	it became. */

class FeActualPlaceHolder : public FePlaceHolder {

/* Attributes for class FeActualPlaceHolder */
	CONCRETE(FeActualPlaceHolder)
	NOT_A_TYPE(FeActualPlaceHolder)
	AUTO_GC(FeActualPlaceHolder)
  public: /* client accessing */

	
	virtual RPTR(FeRangeElement) again ();
	
	
	virtual BooleanVar canMakeIdentical (APTR(FeRangeElement) ARG(newIdentity));
	
	/* Consolidate this PlaceHolder to the newIdentity.  Return 
	true if successful. */
	/* Check permissions
			and forward the operation after coercing the newIdentity
			 to a persistent RangeElement. */
	/* myRangeElement will tell me to forward to another RangeElement. */
	
	virtual void makeIdentical (APTR(FeRangeElement) ARG(newIdentity));
	
	/* MyBeRangeElement will know it. */
	
	virtual RPTR(ID) owner ();
	
	
	virtual void removeFillDetector (APTR(FeFillDetector) ARG(detector));
	
  public: /* server accessing */

	
	virtual RPTR(BeRangeElement) OR(NULL) fetchBe ();
	
	/* myRangeElement has become something else.  Forward to the 
	new thing. */
	
	virtual void forwardTo (APTR(BeRangeElement) ARG(element));
	
	
	virtual RPTR(BeRangeElement) getOrMakeBe ();
	
  private: /* private: create */

	
	FeActualPlaceHolder (APTR(BeRangeElement) ARG(be), TCSJ);
	
  public: /* destruct */

	
	virtual void destruct ();
	
  private:
	CHKPTR(BeRangeElement) myRangeElement;
	friend class FePlaceHolder;
};  /* end class FeActualPlaceHolder */



/* ************************************************************************ *
 * 
 *                    Class FeVirtualDataHolder 
 *
 * ************************************************************************ */




	/* Fakes a DataHolder by having an Edition and a key. */

class FeVirtualDataHolder : public FeDataHolder {

/* Attributes for class FeVirtualDataHolder */
	CONCRETE(FeVirtualDataHolder)
	NOT_A_TYPE(FeVirtualDataHolder)
	AUTO_GC(FeVirtualDataHolder)
  public: /* accessing */

	/* Fetch from my Edition again, just in case I've been consolidated. */
	
	virtual RPTR(FeRangeElement) again ();
	
	/* This can do a version comparison (which seems a bit extreme). */
	
	virtual BooleanVar isIdentical (APTR(FeRangeElement) ARG(other));
	
	
	virtual RPTR(ID) owner ();
	
	
	virtual RPTR(PrimValue) value ();
	
  public: /* server accessing */

	
	virtual RPTR(BeRangeElement) OR(NULL) fetchBe ();
	
	/* Force the ent to generate a beRangeElement at myKey. */
	
	virtual RPTR(BeRangeElement) getOrMakeBe ();
	
  private: /* private: create */

	
	FeVirtualDataHolder (
			APTR(PrimValue) ARG(value), 
			APTR(Position) ARG(key), 
			APTR(BeEdition) ARG(edition))
	;
	
  private:
	CHKPTR(PrimValue) myValue;
	CHKPTR(Position) myKey;
	CHKPTR(BeEdition) myEdition;
	friend class FeDataHolder;
};  /* end class FeVirtualDataHolder */



/* ************************************************************************ *
 * 
 *                    Class FeVirtualPlaceHolder 
 *
 * ************************************************************************ */




	/* Fakes a PlaceHolder by having an Edition and a key. */

class FeVirtualPlaceHolder : public FePlaceHolder {

/* Attributes for class FeVirtualPlaceHolder */
	CONCRETE(FeVirtualPlaceHolder)
	NOT_A_TYPE(FeVirtualPlaceHolder)
	AUTO_GC(FeVirtualPlaceHolder)
  public: /* client accessing */

	
	virtual RPTR(FeRangeElement) again ();
	
	
	virtual BooleanVar canMakeIdentical (APTR(FeRangeElement) ARG(newIdentity));
	
	/* Consolidate this PlaceHolder to the newIdentity.  Return 
	true if successful. */
	/* Check permissions
			and coerce both of us and have the BeRangeElements try. */
	
	virtual void makeIdentical (APTR(FeRangeElement) ARG(newIdentity));
	
	
	virtual RPTR(ID) owner ();
	
	
	virtual void removeFillDetector (APTR(FeFillDetector) ARG(detector));
	
  public: /* server accessing */

	
	virtual RPTR(BeRangeElement) OR(NULL) fetchBe ();
	
	/* Force the ent to generate a beRangeElement at myKey. */
	
	virtual RPTR(BeRangeElement) getOrMakeBe ();
	
  private: /* private: create */

	
	FeVirtualPlaceHolder (APTR(BeEdition) ARG(edition), APTR(Position) ARG(key));
	
  private:
	CHKPTR(BeEdition) myEdition;
	CHKPTR(Position) myKey;
	friend class FePlaceHolder;
};  /* end class FeVirtualPlaceHolder */



/* ************************************************************************ *
 * 
 *                    Class RevisionDetectorExecutor 
 *
 * ************************************************************************ */




	/* This class informs its work when its last detector has gone away. */

class RevisionDetectorExecutor : public XnExecutor {

/* Attributes for class RevisionDetectorExecutor */
	CONCRETE(RevisionDetectorExecutor)
	NOT_A_TYPE(RevisionDetectorExecutor)
	AUTO_GC(RevisionDetectorExecutor)
  public: /* create */

	
	static RPTR(XnExecutor) make (APTR(FeWork) ARG(work));
	
  protected: /* protected: create */

	
	RevisionDetectorExecutor (APTR(FeWork) ARG(work), TCSJ);
	
  public: /* execute */

	
	virtual void execute (Int32 ARG(arg));
	
  private:
	CHKPTR(FeWork) myWork;
};  /* end class RevisionDetectorExecutor */



/* ************************************************************************ *
 * 
 *                    Class StatusDetectorExecutor 
 *
 * ************************************************************************ */




	/* This class informs its work when its last status detector 
	has gone away. */

class StatusDetectorExecutor : public XnExecutor {

/* Attributes for class StatusDetectorExecutor */
	CONCRETE(StatusDetectorExecutor)
	NOT_A_TYPE(StatusDetectorExecutor)
	AUTO_GC(StatusDetectorExecutor)
  public: /* create */

	
	static RPTR(XnExecutor) make (APTR(FeWork) ARG(work));
	
  public: /* executing */

	
	virtual void execute (Int32 ARG(arg));
	
  protected: /* protected: create */

	
	StatusDetectorExecutor (APTR(FeWork) ARG(work), TCSJ);
	
  private:
	CHKPTR(FeWork) myWork;
};  /* end class StatusDetectorExecutor */



#endif /* NKERNELP_HXX */

