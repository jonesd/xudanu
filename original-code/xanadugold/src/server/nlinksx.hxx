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

#ifndef NLINKSX_HXX
#define NLINKSX_HXX


#ifndef TOFUX_HXX
#include "tofux.hxx"
#endif /* TOFUX_HXX */

#ifndef INTVARX_HXX
#include "intvarx.hxx"
#endif /* INTVARX_HXX */

#ifndef NLINKSX_OXX
#include "nlinksx.oxx"
#endif /* NLINKSX_OXX */


#ifndef INITX_HXX
#include "initx.hxx"
#endif /* INITX_HXX */

#ifndef WRAPPERX_HXX
#include "wrapperx.hxx"
#endif /* WRAPPERX_HXX */


#ifndef FILTERX_OXX
#include "filterx.oxx"
#endif /* FILTERX_OXX */

#ifndef IDX_OXX
#include "idx.oxx"
#endif /* IDX_OXX */

#ifndef NKERNELX_OXX
#include "nkernelx.oxx"
#endif /* NKERNELX_OXX */

#ifndef PARRAYX_OXX
#include "parrayx.oxx"
#endif /* PARRAYX_OXX */

#ifndef SEQUENCX_OXX
#include "sequencx.oxx"
#endif /* SEQUENCX_OXX */

#ifndef STEPPERX_OXX
#include "stepperx.oxx"
#endif /* STEPPERX_OXX */


/*  */
/*  */




/* ************************************************************************ *
 * 
 *                    Class FeHyperLink 
 *
 * ************************************************************************ */



/* Initializers for FeHyperLink */







	/* Contains a named table of HyperRefs and a set of Works 
	which describe the usage and/or format of the link. */

class FeHyperLink : public FeWrapper {

/* Attributes for class FeHyperLink */
	CONCRETE(FeHyperLink)
	ON_CLIENT(FeHyperLink)
	NO_GC(FeHyperLink)

/* Initializers for FeHyperLink */



friend class INIT_TIME_NAME(FeHyperLink,initTimeNonInherited);

  private: /* private: wrapping */

	/* Check that it has the right fields in the right places. 
	Ignore other contents. */
	
	static BooleanVar check (APTR(FeEdition) ARG(edition));
	
	
	static RPTR(FeHyperLink) construct (APTR(FeEdition) ARG(edition));
	
	/* Just create a new wrapper */
	
	static RPTR(FeWrapper) makeWrapper (APTR(FeEdition) ARG(edition));
	
	
	static void setSpec (APTR(FeWrapperSpec) ARG(wrap));
	
  public: /* pseudo constructors */

	/* A Filter for links of the specified types */
	
	static RPTR(Filter) linkFilter (APTR(IDRegion) ARG(types));
	
	/* Make a standard two-ended link */
	
	static CLIENT RPTR(FeHyperLink) make (
			APTR(FeSet) ARG(types), 
			APTR(FeHyperRef) ARG(leftEnd), 
			APTR(FeHyperRef) ARG(rightEnd))
	;
	
	
	static RPTR(FeWrapperSpec) spec ();
	
  public: /* accessing */

	/* Get the HyperRef at the given name; blast if none there */
	
	virtual CLIENT RPTR(FeHyperRef) endAt (APTR(Sequence) ARG(name));
	
	/* The names of all of the ends of this link */
	
	virtual CLIENT RPTR(SequenceRegion) endNames ();
	
	/* The various type documents describing this kind of Link. 
	These documents are typically Editions with descriptions at 
	each linkEnd key describing what is at that Link End.
		The reason for having several is to allow type hierarchies 
	to be constructed and searched for, by including all super 
	types of a link in its link type list.
		The Link should be endorsed with all the IDs of all the types.
		What if someone endorses it further (or unendorses it?) */
	
	virtual CLIENT RPTR(FeSet) OF1(FeWork) linkTypes ();
	
	/* Change/add a Link end */
	
	virtual CLIENT RPTR(FeHyperLink) withEnd (APTR(Sequence) ARG(name), APTR(FeHyperRef) ARG(linkEnd));
	
	/* Replace the set of type documents describing this kind of Link */
	
	virtual CLIENT RPTR(FeHyperLink) withLinkTypes (APTR(FeSet) OF1(FeWork) ARG(types));
	
	/* Remove a Link end */
	
	virtual CLIENT RPTR(FeHyperLink) withoutEnd (APTR(Sequence) ARG(name));
	
  private: /* private: create */

	
	FeHyperLink (APTR(FeEdition) ARG(edition), APTR(FeWrapperSpec) ARG(spec));
	


  /* ---------- Static Member variables (class vars) ----------- */
  private:
	static GPTR(FeWrapperSpec) TheHyperLinkSpec;
};  /* end class FeHyperLink */



/* ************************************************************************ *
 * 
 *                    Class FeHyperRef 
 *
 * ************************************************************************ */



/* Initializers for FeHyperRef */







	/* Represents a single attachment to some material in context. */

class FeHyperRef : public FeWrapper {

/* Attributes for class FeHyperRef */
	DEFERRED(FeHyperRef)
	ON_CLIENT(FeHyperRef)
	NO_GC(FeHyperRef)

/* Initializers for FeHyperRef */



friend class INIT_TIME_NAME(FeHyperRef,initTimeNonInherited);

  protected: /* protected: wrapping */

	/* Check that it has the right fields in the right places. 
	Ignore other contents. */
	
	static BooleanVar check (APTR(FeEdition) ARG(edition));
	
	
	static void setSpec (APTR(FeWrapperSpec) ARG(spec));
	
  public: /* pseudo constructors */

	
	static RPTR(FeWrapperSpec) spec ();
	
  public: /* accessing */

	/* A Work frozen on the contents of the Work at the time the 
	HyperRef was made */
	
	virtual CLIENT RPTR(FeWork) originalContext ();
	
	/* The path of labels down from the top-level Edition */
	
	virtual CLIENT RPTR(FePath) pathContext ();
	
	/* Change (or remove if NULL) the originalContext */
	
	virtual CLIENT RPTR(FeHyperRef) withOriginalContext (APTR(FeWork) OR(NULL) ARG(work));
	
	/* Change (or remove if NULL) the pathContext */
	
	virtual CLIENT RPTR(FeHyperRef) withPathContext (APTR(FePath) OR(NULL) ARG(path));
	
	/* Change (or remove if NULL) the workContext */
	
	virtual CLIENT RPTR(FeHyperRef) withWorkContext (APTR(FeWork) OR(NULL) ARG(work));
	
	/* The Work whose state this is attached to. */
	
	virtual CLIENT RPTR(FeWork) workContext ();
	
  protected: /* protected: create */

	
	FeHyperRef (APTR(FeEdition) ARG(edition), APTR(FeWrapperSpec) ARG(spec));
	
	/* Make a new HyperRef of the same type with different contents */
	
	virtual RPTR(FeHyperRef) makeNew (APTR(FeEdition) ARG(edition)) DEFERRED_FUNC;
	


  /* ---------- Static Member variables (class vars) ----------- */
  private:
	static GPTR(FeWrapperSpec) TheHyperRefSpec;
};  /* end class FeHyperRef */



/* ************************************************************************ *
 * 
 *                    Class   FeMultiRef 
 *
 * ************************************************************************ */



/* Initializers for FeMultiRef */







	/* An undifferentiated set of HyperRefs */

class FeMultiRef : public FeHyperRef {

/* Attributes for class FeMultiRef */
	CONCRETE(FeMultiRef)
	ON_CLIENT(FeMultiRef)
	NO_GC(FeMultiRef)

/* Initializers for FeMultiRef */



friend class INIT_TIME_NAME(FeMultiRef,initTimeNonInherited);

  private: /* private: wrapping */

	/* Check that it has the right fields in the right places. 
	Ignore other contents. */
	
	static BooleanVar check (APTR(FeEdition) ARG(edition));
	
	/* Create a new wrapper and endorse it */
	
	static RPTR(FeMultiRef) construct (APTR(FeEdition) ARG(edition));
	
	/* Just create a new wrapper */
	
	static RPTR(FeWrapper) makeWrapper (APTR(FeEdition) ARG(edition));
	
	
	static void setSpec (APTR(FeWrapperSpec) ARG(wrap));
	
  public: /* creation */

	/* Make a new MultiRef. At least one of the parameters must 
	be non-NULL. The originalContext, if supplied,  must be a 
	frozen Work. */
	
	static CLIENT RPTR(FeMultiRef) make (
			APTR(PtrArray) OF1(FeHyperRef) OR(NULL) ARG(refs), 
			APTR(FeWork) ARG(workContext) = NULL, 
			APTR(FeWork) ARG(originalContext) = NULL, 
			APTR(FePath) ARG(pathContext) = NULL)
	;
	
	
	static RPTR(FeWrapperSpec) spec ();
	
  private: /* private: */

	/* The Edition holding the HyperRefs */
	
	virtual RPTR(FeEdition) refsEdition ();
	
	/* With a different refs Edition */
	
	virtual RPTR(FeMultiRef) withRefsEdition (APTR(FeEdition) ARG(edition));
	
  public: /* accessing */

	/* Remove those not in the other Refs from the set. */
	
	virtual CLIENT RPTR(FeMultiRef) intersect (APTR(FeMultiRef) ARG(other));
	
	/* Remove the other Refs from the set. */
	
	virtual CLIENT RPTR(FeMultiRef) minus (APTR(FeMultiRef) ARG(other));
	
	/* All the HyperRefs in the collection */
	
	virtual CLIENT RPTR(Stepper) OF1(FeHyperRef) refs ();
	
	/* Add the other Refs into the set. */
	
	virtual CLIENT RPTR(FeMultiRef) unionWith (APTR(FeMultiRef) ARG(other));
	
	/* Add a Ref to the set */
	
	virtual CLIENT RPTR(FeMultiRef) with (APTR(FeHyperRef) ARG(ref));
	
	/* Add a Ref to the set */
	
	virtual CLIENT RPTR(FeMultiRef) without (APTR(FeHyperRef) ARG(ref));
	
  protected: /* protected: */

	/* Make a new HyperRef of the same type with different contents */
	
	virtual RPTR(FeHyperRef) makeNew (APTR(FeEdition) ARG(edition));
	
  private: /* private: create */

	
	FeMultiRef (APTR(FeEdition) ARG(edition), APTR(FeWrapperSpec) ARG(spec));
	


  /* ---------- Static Member variables (class vars) ----------- */
  private:
	static GPTR(FeWrapperSpec) TheMultiRefSpec;
};  /* end class FeMultiRef */



/* ************************************************************************ *
 * 
 *                    Class   FeSingleRef 
 *
 * ************************************************************************ */



/* Initializers for FeSingleRef */







	/* Represents a single attachment to some material in the 
	context of a Work, and maybe a Path beneath it. */

class FeSingleRef : public FeHyperRef {

/* Attributes for class FeSingleRef */
	CONCRETE(FeSingleRef)
	ON_CLIENT(FeSingleRef)
	NO_GC(FeSingleRef)

/* Initializers for FeSingleRef */



friend class INIT_TIME_NAME(FeSingleRef,initTimeNonInherited);

  private: /* private: wrapping */

	/* Check that it has the right fields in the right places. 
	Ignore other contents. */
	
	static BooleanVar check (APTR(FeEdition) ARG(edition));
	
	/* Create a new wrapper and endorse it */
	
	static RPTR(FeSingleRef) construct (APTR(FeEdition) ARG(edition));
	
	/* Just create a new wrapper */
	
	static RPTR(FeWrapper) makeWrapper (APTR(FeEdition) ARG(edition));
	
	
	static void setSpec (APTR(FeWrapperSpec) ARG(wrap));
	
  public: /* creation */

	/* Make a new SingleRef. At least one of the parameters must 
	be non-NULL. The originalContext, if supplied,  must be a 
	frozen Work. */
	
	static CLIENT RPTR(FeSingleRef) make (
			APTR(FeEdition) OR(NULL) ARG(material), 
			APTR(FeWork) ARG(workContext) = NULL, 
			APTR(FeWork) ARG(originalContext) = NULL, 
			APTR(FePath) ARG(pathContext) = NULL)
	;
	
	
	static RPTR(FeWrapperSpec) spec ();
	
  public: /* accessing */

	/* The material to which this HyperRef is attached. */
	
	virtual CLIENT RPTR(FeEdition) excerpt ();
	
	/* Make this Ref point at different material. */
	
	virtual CLIENT RPTR(FeSingleRef) withExcerpt (APTR(FeEdition) ARG(excerpt));
	
  protected: /* protected: */

	/* Make a new HyperRef of the same type with different contents */
	
	virtual RPTR(FeHyperRef) makeNew (APTR(FeEdition) ARG(edition));
	
  private: /* private: create */

	
	FeSingleRef (APTR(FeEdition) ARG(edition), APTR(FeWrapperSpec) ARG(spec));
	


  /* ---------- Static Member variables (class vars) ----------- */
  private:
	static GPTR(FeWrapperSpec) TheSingleRefSpec;
};  /* end class FeSingleRef */



/* ************************************************************************ *
 * 
 *                    Class FePath 
 *
 * ************************************************************************ */



/* Initializers for FePath */







	/* A sequence of Labels, used for context information in a LinkEnd. */

class FePath : public FeWrapper {

/* Attributes for class FePath */
	CONCRETE(FePath)
	ON_CLIENT(FePath)
	NO_GC(FePath)

/* Initializers for FePath */



friend class INIT_TIME_NAME(FePath,initTimeNonInherited);

  public: /* pseudo constructors */

	
	static CLIENT RPTR(FePath) make (APTR(PtrArray) OF1(FeLabel) ARG(labels));
	
	
	static RPTR(FeWrapperSpec) spec ();
	
  private: /* private: wrapping */

	
	static BooleanVar check (APTR(FeEdition) ARG(edition));
	
	
	static RPTR(FePath) construct (APTR(FeEdition) ARG(edition));
	
	
	static RPTR(FeWrapper) makeWrapper (APTR(FeEdition) ARG(edition));
	
	
	static void setSpec (APTR(FeWrapperSpec) ARG(wrap));
	
  public: /* operations */

	/* Follow a path down into an Edition and return what is at 
	the end of the path. Fail if at any point there is not 
	precisely one choice. */
	
	virtual CLIENT RPTR(FeRangeElement) follow (APTR(FeEdition) ARG(edition));
	
  private: /* private: create */

	
	FePath (APTR(FeEdition) ARG(edition), APTR(FeWrapperSpec) ARG(spec));
	


  /* ---------- Static Member variables (class vars) ----------- */
  private:
	static GPTR(FeWrapperSpec) ThePathSpec;
};  /* end class FePath */



#endif /* NLINKSX_HXX */

