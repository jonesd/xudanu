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

#ifndef WRAPPERP_HXX
#define WRAPPERP_HXX


#ifndef TOFUX_HXX
#include "tofux.hxx"
#endif /* TOFUX_HXX */

#ifndef INTVARX_HXX
#include "intvarx.hxx"
#endif /* INTVARX_HXX */

#ifndef WRAPPERX_HXX
#include "wrapperx.hxx"
#endif /* WRAPPERX_HXX */

#ifndef WRAPPERP_OXX
#include "wrapperp.oxx"
#endif /* WRAPPERP_OXX */


#ifndef NKERNELX_OXX
#include "nkernelx.oxx"
#endif /* NKERNELX_OXX */

#ifndef PARRAYX_OXX
#include "parrayx.oxx"
#endif /* PARRAYX_OXX */

#ifndef SEQUENCX_OXX
#include "sequencx.oxx"
#endif /* SEQUENCX_OXX */


/*  */
/*  */




/* ************************************************************************ *
 * 
 *                    Class FeAbstractWrapperSpec 
 *
 * ************************************************************************ */




	/* NO CLASS COMMENT */

class FeAbstractWrapperSpec : public FeWrapperSpec {

/* Attributes for class FeAbstractWrapperSpec */
	CONCRETE(FeAbstractWrapperSpec)
	AUTO_GC(FeAbstractWrapperSpec)
  public: /* pseudo constructors */

	
	static RPTR(FeAbstractWrapperSpec) make (APTR(FeAbstractWrapperDef) ARG(def));
	
  public: /* accessing */

	
	virtual BooleanVar certify (APTR(FeEdition) ARG(edition));
	
	/* Add a new concrete spec to the list, keeping it 
	topologically sorted so that if A wraps B, A precedes B */
	
	virtual void setupConcreteSubSpec (APTR(FeConcreteWrapperSpec) ARG(spec));
	
  public: /* create */

	
	FeAbstractWrapperSpec (APTR(FeAbstractWrapperDef) ARG(def), TCSJ);
	
  public: /* for wrappers only */

	
	virtual void endorse (APTR(FeEdition) ARG(edition));
	
  public: /* vulnerable */

	
	virtual RPTR(FeWrapper) OR(NULL) fetchWrap (APTR(FeEdition) ARG(edition));
	
  private:
	CHKPTR(PtrArray) OF1(FeConcreteWrapperSpec) myConcreteSpecs;
};  /* end class FeAbstractWrapperSpec */



/* ************************************************************************ *
 * 
 *                    Class FeConcreteWrapperSpec 
 *
 * ************************************************************************ */




	/* NO CLASS COMMENT */

class FeConcreteWrapperSpec : public FeWrapperSpec {

/* Attributes for class FeConcreteWrapperSpec */
	CONCRETE(FeConcreteWrapperSpec)
	NO_GC(FeConcreteWrapperSpec)
  protected: /* protected: */

	
	virtual void setup ();
	
  public: /* accessing */

	
	virtual BooleanVar certify (APTR(FeEdition) ARG(edition)) DEFERRED_FUNC;
	
	/* Whether I can wrap the given type */
	
	virtual BooleanVar wraps (APTR(FeConcreteWrapperSpec) ARG(other)) DEFERRED_FUNC;
	
  public: /* create */

	
	FeConcreteWrapperSpec (APTR(FeWrapperDef) ARG(def), TCSJ);
	
  public: /* for wrappers only */

	/* Endorse an Edition as being of this type */
	
	virtual void endorse (APTR(FeEdition) ARG(edition));
	
  public: /* vulnerable */

	
	virtual RPTR(FeWrapper) OR(NULL) fetchWrap (APTR(FeEdition) ARG(edition)) DEFERRED_FUNC;
	

};  /* end class FeConcreteWrapperSpec */



/* ************************************************************************ *
 * 
 *                    Class   FeDirectWrapperSpec 
 *
 * ************************************************************************ */




	/* NO CLASS COMMENT */

class FeDirectWrapperSpec : public FeConcreteWrapperSpec {

/* Attributes for class FeDirectWrapperSpec */
	CONCRETE(FeDirectWrapperSpec)
	NO_GC(FeDirectWrapperSpec)
  public: /* pseudo constructors */

	
	static RPTR(FeDirectWrapperSpec) make (APTR(FeDirectWrapperDef) ARG(def));
	
  public: /* accessing */

	
	virtual BooleanVar wraps (APTR(FeConcreteWrapperSpec) ARG(other));
	
  private: /* private: */

	/* Try to certify as this type. If successful, return TRUE 
	and endorse it; if not, return FALSE. */
	
	virtual BooleanVar certify (APTR(FeEdition) ARG(edition));
	
  public: /* create */

	
	FeDirectWrapperSpec (APTR(FeDirectWrapperDef) ARG(def), TCSJ);
	
  public: /* vulnerable */

	
	virtual RPTR(FeWrapper) fetchWrap (APTR(FeEdition) ARG(edition));
	

};  /* end class FeDirectWrapperSpec */



/* ************************************************************************ *
 * 
 *                    Class   FeIndirectWrapperSpec 
 *
 * ************************************************************************ */




	/* NO CLASS COMMENT */

class FeIndirectWrapperSpec : public FeConcreteWrapperSpec {

/* Attributes for class FeIndirectWrapperSpec */
	CONCRETE(FeIndirectWrapperSpec)
	AUTO_GC(FeIndirectWrapperSpec)
  public: /* pseudo constructors */

	
	static RPTR(FeIndirectWrapperSpec) make (APTR(FeIndirectWrapperDef) ARG(def));
	
  public: /* accessing */

	
	virtual BooleanVar wraps (APTR(FeConcreteWrapperSpec) ARG(other));
	
  private: /* private: */

	/* Try to certify as this type. If successful, return TRUE 
	and endorse it; if not, return FALSE. */
	
	virtual BooleanVar certify (APTR(FeEdition) ARG(inner));
	
	
	virtual RPTR(FeIndirectWrapperDef) indirectDef ();
	
  protected: /* protected: */

	
	virtual void setup ();
	
  public: /* create */

	
	FeIndirectWrapperSpec (APTR(FeIndirectWrapperDef) ARG(def), TCSJ);
	
  public: /* vulnerable */

	
	virtual RPTR(FeWrapper) OR(NULL) fetchWrap (APTR(FeEdition) ARG(edition));
	
  private:
	CHKPTR(FeConcreteWrapperSpec) myInner;
};  /* end class FeIndirectWrapperSpec */



/* ************************************************************************ *
 * 
 *                    Class FeWrapperDef 
 *
 * ************************************************************************ */




	/* ?I: names
		?P: strings
		?P: PackOBits */

class FeWrapperDef : public Heaper {

/* Attributes for class FeWrapperDef */
	DEFERRED(FeWrapperDef)
	EQ(FeWrapperDef)
	AUTO_GC(FeWrapperDef)
  public: /* pseudo constructors */

	
	static RPTR(FeWrapperDef) abstract (
			APTR(Sequence) ARG(wrapperName), 
			APTR(Sequence) OR(NULL) ARG(superName), 
			FeWrapperSpecHolder OR(NULL) ARG(holder))
	;
	
	
	static RPTR(FeWrapperDef) makeDirect (
			APTR(Sequence) ARG(wrapperName), 
			APTR(Sequence) OR(NULL) ARG(superName), 
			FeWrapperSpecHolder OR(NULL) ARG(holder), 
			FeDirectWrapperMaker ARG(maker), 
			FeDirectWrapperChecker ARG(checker))
	;
	
	
	static RPTR(FeWrapperDef) makeIndirect (
			APTR(Sequence) ARG(wrapperName), 
			APTR(Sequence) OR(NULL) ARG(superName), 
			FeWrapperSpecHolder OR(NULL) ARG(holder), 
			APTR(Sequence) OR(NULL) ARG(innerName), 
			FeIndirectWrapperMaker ARG(maker), 
			FeIndirectWrapperChecker ARG(checker))
	;
	
  public: /* accessing */

	
	virtual RPTR(Sequence) OR(NULL) fetchSuperDefName ();
	
	/* Make a WrapperSpec for this definition and return it */
	
	virtual RPTR(FeWrapperSpec) makeSpec () DEFERRED_FUNC;
	
	
	virtual RPTR(Sequence) name ();
	
	/* Tell whoever cares about the spec for this type */
	
	virtual void setSpec (APTR(FeWrapperSpec) ARG(spec));
	
  public: /* create */

	
	FeWrapperDef (
			APTR(Sequence) ARG(name), 
			APTR(Sequence) OR(NULL) ARG(superName), 
			FeWrapperSpecHolder OR(NULL) ARG(holder))
	;
	
  private:
	CHKPTR(Sequence) myName;
	CHKPTR(Sequence) OR(NULL) mySuperDefName;
	FeWrapperSpecHolder mySpecHolder;
};  /* end class FeWrapperDef */



/* ************************************************************************ *
 * 
 *                    Class   FeAbstractWrapperDef 
 *
 * ************************************************************************ */




	/* NO CLASS COMMENT */

class FeAbstractWrapperDef : public FeWrapperDef {

/* Attributes for class FeAbstractWrapperDef */
	CONCRETE(FeAbstractWrapperDef)
	EQ(FeAbstractWrapperDef)
	NO_GC(FeAbstractWrapperDef)
  public: /* create */

	
	FeAbstractWrapperDef (
			APTR(Sequence) ARG(name), 
			APTR(Sequence) OR(NULL) ARG(superName), 
			FeWrapperSpecHolder OR(NULL) ARG(holder))
	;
	
  public: /* accessing */

	
	virtual RPTR(FeWrapperSpec) makeSpec ();
	

	friend class FeWrapperDef;
};  /* end class FeAbstractWrapperDef */



/* ************************************************************************ *
 * 
 *                    Class   FeDirectWrapperDef 
 *
 * ************************************************************************ */




	/* NO CLASS COMMENT */

class FeDirectWrapperDef : public FeWrapperDef {

/* Attributes for class FeDirectWrapperDef */
	CONCRETE(FeDirectWrapperDef)
	EQ(FeDirectWrapperDef)
	NO_GC(FeDirectWrapperDef)
  public: /* accessing */

	
	virtual BooleanVar check (APTR(FeEdition) ARG(edition));
	
	
	virtual RPTR(FeWrapperSpec) makeSpec ();
	
	
	virtual RPTR(FeWrapper) makeWrapper (APTR(FeEdition) ARG(edition));
	
  public: /* create */

	
	FeDirectWrapperDef (
			APTR(Sequence) ARG(name), 
			APTR(Sequence) OR(NULL) ARG(superName), 
			FeWrapperSpecHolder OR(NULL) ARG(holder), 
			FeDirectWrapperMaker ARG(maker), 
			FeDirectWrapperChecker ARG(checker))
	;
	
  private:
	FeDirectWrapperMaker myMaker;
	FeDirectWrapperChecker myChecker;
	friend class FeWrapperDef;
};  /* end class FeDirectWrapperDef */



/* ************************************************************************ *
 * 
 *                    Class   FeIndirectWrapperDef 
 *
 * ************************************************************************ */




	/* NO CLASS COMMENT */

class FeIndirectWrapperDef : public FeWrapperDef {

/* Attributes for class FeIndirectWrapperDef */
	CONCRETE(FeIndirectWrapperDef)
	EQ(FeIndirectWrapperDef)
	AUTO_GC(FeIndirectWrapperDef)
  public: /* accessing */

	
	virtual BooleanVar check (APTR(FeEdition) ARG(inner));
	
	
	virtual RPTR(Sequence) innerDefName ();
	
	
	virtual RPTR(FeWrapperSpec) makeSpec ();
	
	
	virtual RPTR(FeWrapper) makeWrapper (APTR(FeEdition) ARG(edition), APTR(FeWrapper) ARG(inner));
	
  public: /* create */

	
	FeIndirectWrapperDef (
			APTR(Sequence) ARG(name), 
			APTR(Sequence) OR(NULL) ARG(superName), 
			FeWrapperSpecHolder OR(NULL) ARG(holder), 
			FeIndirectWrapperMaker ARG(maker), 
			FeIndirectWrapperChecker ARG(checker))
	;
	
	
	FeIndirectWrapperDef (
			APTR(Sequence) ARG(name), 
			APTR(Sequence) OR(NULL) ARG(superName), 
			FeWrapperSpecHolder OR(NULL) ARG(holder), 
			APTR(Sequence) OR(NULL) ARG(inner), 
			FeIndirectWrapperMaker ARG(maker), 
			FeIndirectWrapperChecker ARG(checker))
	;
	
  private:
	CHKPTR(Sequence) myInner;
	FeIndirectWrapperMaker myMaker;
	FeIndirectWrapperChecker myChecker;
	friend class FeWrapperDef;
	friend class FeWrapperDef;
};  /* end class FeIndirectWrapperDef */



#endif /* WRAPPERP_HXX */

