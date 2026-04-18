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

#ifndef WRAPPERX_HXX
#define WRAPPERX_HXX


#ifndef TOFUX_HXX
#include "tofux.hxx"
#endif /* TOFUX_HXX */

#ifndef INTVARX_HXX
#include "intvarx.hxx"
#endif /* INTVARX_HXX */

#ifndef WRAPPERX_OXX
#include "wrapperx.oxx"
#endif /* WRAPPERX_OXX */


#ifndef INITX_HXX
#include "initx.hxx"
#endif /* INITX_HXX */


#ifndef CROSSX_OXX
#include "crossx.oxx"
#endif /* CROSSX_OXX */

#ifndef FILTERX_OXX
#include "filterx.oxx"
#endif /* FILTERX_OXX */

#ifndef IDX_OXX
#include "idx.oxx"
#endif /* IDX_OXX */

#ifndef INTEGERX_OXX
#include "integerx.oxx"
#endif /* INTEGERX_OXX */

#ifndef NKERNELX_OXX
#include "nkernelx.oxx"
#endif /* NKERNELX_OXX */

#ifndef PARRAYX_OXX
#include "parrayx.oxx"
#endif /* PARRAYX_OXX */

#ifndef SEQUENCX_OXX
#include "sequencx.oxx"
#endif /* SEQUENCX_OXX */

#ifndef SPACEX_OXX
#include "spacex.oxx"
#endif /* SPACEX_OXX */

#ifndef STEPPERX_OXX
#include "stepperx.oxx"
#endif /* STEPPERX_OXX */

#ifndef TABLESX_OXX
#include "tablesx.oxx"
#endif /* TABLESX_OXX */

#ifndef WRAPPERP_OXX
#include "wrapperp.oxx"
#endif /* WRAPPERP_OXX */


/*  */
/*  */
/* Function pointer types for wrappers */

typedef void (*FeWrapperSpecHolder) (APTR(FeWrapperSpec));
typedef SPTR(FeWrapper) (*FeDirectWrapperMaker) (APTR(FeEdition));
typedef SPTR(FeWrapper) (*FeIndirectWrapperMaker) (APTR(FeEdition), APTR(FeWrapper));
typedef BooleanVar (*FeDirectWrapperChecker) (APTR(FeEdition));
typedef BooleanVar (*FeIndirectWrapperChecker) (APTR(FeEdition));

#define ABSTRACTWRAPPER(wrapperName,superName,className) \
	REQUIRES(Sequence); \
	REQUIRES(FeWrapperSpec); \
	FeWrapperSpec::registerAbstract (wrapperName, superName, className::setSpec)

#define DIRECTWRAPPER(wrapperName,superName,className) \
	REQUIRES(Sequence); \
	REQUIRES(FeWrapperSpec); \
	FeWrapperSpec::registerDirect (wrapperName, superName, \
		className::makeWrapper, className::check, className::setSpec)
		
#define INDIRECTWRAPPER(wrapperName,superName,innerName,className) \
	REQUIRES(Sequence); \
	REQUIRES(FeWrapperSpec); \
	FeWrapperSpec::registerDirect (wrapperName, superName, innerName, \
		className::makeWrapper, className::check, className::setSpec)





/* ************************************************************************ *
 * 
 *                    Class FeWrapper 
 *
 * ************************************************************************ */



/* Initializers for FeWrapper */







	/* An object which wraps an Edition, providing additional 
	functionality for manipulating it and enforcing invariants on 
	the format.
	
	Implementation note:
	
	The fact that you cannot get the spec of a Wrapper is 
	deliberate. You can merely check that it is a kind of Edition 
	you know, but no more; this makes it easy to compatibly add 
	new leaf classes below existing ones. */

class FeWrapper : public Heaper {

/* Attributes for class FeWrapper */
	DEFERRED(FeWrapper)
	ON_CLIENT(FeWrapper)
	EQ(FeWrapper)
	AUTO_GC(FeWrapper)

/* Initializers for FeWrapper */



friend class INIT_TIME_NAME(FeWrapper,initTimeNonInherited);

  private: /* private: wrapping */

	
	static void setSpec (APTR(FeWrapperSpec) ARG(spec));
	
  public: /* accessing */

	
	static RPTR(FeWrapperSpec) spec ();
	
  protected: /* protected: checking */

	/* Checks that the domain is in the right coordinate space 
	and is a superset of the given region */
	
	static BooleanVar checkDomainHas (APTR(FeEdition) ARG(edition), APTR(XnRegion) ARG(required));
	
	/* Checks that the domain is in the right coordinate space 
	and a subset of the given region */
	
	static BooleanVar checkDomainIn (APTR(FeEdition) ARG(edition), APTR(XnRegion) ARG(limit));
	
	/* If there is a SubEdition at a key in an edition, and if a 
	spec is supplied, that it can be certified as the given type */
	
	static BooleanVar checkSubEdition (
			APTR(FeEdition) ARG(parent), 
			APTR(Position) ARG(key), 
			APTR(FeWrapperSpec) OR(NULL) ARG(spec), 
			BooleanVar ARG(required))
	;
	
	/* Check that everything in the region is an Edition, which 
	can be certified with the given type */
	
	static BooleanVar checkSubEditions (
			APTR(FeEdition) ARG(parent), 
			APTR(XnRegion) ARG(keys), 
			APTR(FeWrapperSpec) ARG(spec), 
			BooleanVar ARG(required))
	;
	
	/* Whether there is an Edition there which can be 
	successfully converted into a zero based Sequence */
	
	static BooleanVar checkSubSequence (
			APTR(FeEdition) ARG(edition), 
			APTR(Position) ARG(key), 
			BooleanVar ARG(required))
	;
	
	/* If there is a SubWork at a key in an edition */
	
	static BooleanVar checkSubWork (
			APTR(FeEdition) ARG(parent), 
			APTR(Position) ARG(key), 
			BooleanVar ARG(required))
	;
	
  public: /* accessing */

	/* Essential. The primitive Edition this is wrapping. */
	
	virtual CLIENT RPTR(FeEdition) edition ();
	
	/* Essential. The next Wrapper inside this one; blasts if 
	this wraps an Edition directly. */
	
	virtual CLIENT RPTR(FeWrapper) inner ();
	
	/* Essential. Return TRUE if this is wrapped as the given 
	spec, or any one of its subtypes */
	
	virtual BooleanVar isWrapperOf (APTR(FeWrapperSpec) ARG(spec));
	
  protected: /* protected: create */

	
	FeWrapper (APTR(FeEdition) ARG(edition), APTR(FeWrapperSpec) ARG(spec));
	
	
	FeWrapper (
			APTR(FeEdition) ARG(edition), 
			APTR(FeWrapper) ARG(inner), 
			APTR(FeWrapperSpec) ARG(spec))
	;
	
  private:
	CHKPTR(FeEdition) myEdition;
	CHKPTR(FeWrapper) OR(NULL) myInner;
	CHKPTR(FeWrapperSpec) mySpec;

  /* ---------- Static Member variables (class vars) ----------- */
  private:
	static GPTR(FeWrapperSpec) TheWrapperSpec;
};  /* end class FeWrapper */



/* ************************************************************************ *
 * 
 *                    Class   FeSet 
 *
 * ************************************************************************ */



/* Initializers for FeSet */







	/* An undifferentiated set of RangeElements. */

class FeSet : public FeWrapper {

/* Attributes for class FeSet */
	CONCRETE(FeSet)
	ON_CLIENT(FeSet)
	NO_GC(FeSet)

/* Initializers for FeSet */



friend class INIT_TIME_NAME(FeSet,initTimeNonInherited);

  public: /* pseudo constructors */

	
	static CLIENT RPTR(FeSet) make ();
	
	
	static CLIENT RPTR(FeSet) make (APTR(PtrArray) OF1(FeRangeElement) ARG(works));
	
	
	static RPTR(FeWrapperSpec) spec ();
	
  private: /* private: wrapping */

	
	static BooleanVar check (APTR(FeEdition) ARG(edition));
	
	
	static RPTR(FeSet) construct (APTR(FeEdition) ARG(edition));
	
	
	static RPTR(FeWrapper) makeWrapper (APTR(FeEdition) ARG(edition));
	
	
	static void setSpec (APTR(FeWrapperSpec) ARG(wrap));
	
  private: /* private: */

	
	virtual RPTR(IDSpace) iDSpace ();
	
  public: /* accessing */

	/* The number of elements in the set */
	
	virtual CLIENT IntegerVar count ();
	
	/* Whether the set includes the given RangeElement */
	
	virtual CLIENT BooleanVar includes (APTR(FeRangeElement) ARG(value));
	
	/* Return those elements which are in both sets */
	
	virtual CLIENT RPTR(FeSet) intersect (APTR(FeSet) ARG(other));
	
	/* Remove some RangeElements from the set */
	
	virtual CLIENT RPTR(FeSet) minus (APTR(FeSet) ARG(other));
	
	/* A stepper over the elements in the set */
	
	virtual RPTR(Stepper) OF1(FeRangeElement) stepper ();
	
	/* If there is exactly one element, then return it */
	
	virtual CLIENT RPTR(FeRangeElement) theOne ();
	
	/* Return those elements which are in either set */
	
	virtual CLIENT RPTR(FeSet) unionWith (APTR(FeSet) ARG(other));
	
	/* Add a RangeElement to the set */
	
	virtual CLIENT RPTR(FeSet) with (APTR(FeRangeElement) ARG(value));
	
	/* Remove a RangeElement from the set */
	
	virtual CLIENT RPTR(FeSet) without (APTR(FeRangeElement) ARG(value));
	
  protected: /* protected: create */

	
	FeSet (APTR(FeEdition) ARG(edition), APTR(FeWrapperSpec) ARG(spec));
	
  public: /* printing */

	
	virtual void printOn (ostream& ARG(oo));
	


  /* ---------- Static Member variables (class vars) ----------- */
  private:
	static GPTR(FeWrapperSpec) TheSetSpec;
};  /* end class FeSet */



/* ************************************************************************ *
 * 
 *                    Class   FeText 
 *
 * ************************************************************************ */



/* Initializers for FeText */







	/* Handles a integer-indexed, contiguous, zero-based Edition 
	of RangeElements */

class FeText : public FeWrapper {

/* Attributes for class FeText */
	CONCRETE(FeText)
	ON_CLIENT(FeText)
	NO_GC(FeText)

/* Initializers for FeText */



friend class INIT_TIME_NAME(FeText,initTimeNonInherited);

  private: /* private: wrapping */

	
	static BooleanVar check (APTR(FeEdition) ARG(edition));
	
	/* Called from internal code to create and endorse new 
	Editions. Does not check the contents; assumes that it will 
	only be called by trusted code. */
	
	static RPTR(FeText) construct (APTR(FeEdition) ARG(edition));
	
	
	static RPTR(FeWrapper) makeWrapper (APTR(FeEdition) ARG(edition));
	
	
	static void setSpec (APTR(FeWrapperSpec) ARG(wrap));
	
  public: /* pseudo constructors */

	
	static CLIENT RPTR(FeText) make (APTR(PrimArray) ARG(data) = NULL);
	
	
	static RPTR(FeWrapperSpec) spec ();
	
  public: /* text manipulation */

	/* The Edition of the actual contents, without any style 
	information. You should use this instead of edition() when 
	you want to get the Edition for comparisons, queries, etc. 
	Future styled text implementations will not store the 
	contents as directly as we do now. */
	
	virtual CLIENT RPTR(FeEdition) contents ();
	
	/* The number of elements in the string */
	
	virtual CLIENT IntegerVar count ();
	
	/* All the text lying within the region, with the gaps 
	compressed out. */
	
	virtual CLIENT RPTR(FeText) extract (APTR(IntegerRegion) ARG(region));
	
	/* Insert new information into the Edition at the given 
	point, pushing everything after it forward. */
	
	virtual CLIENT RPTR(FeText) insert (IntegerVar ARG(position), APTR(FeText) ARG(text));
	
	/* Insert a virtual copy of the region of text before the 
	given position, and remove it from its current location. If 
	the position is one past the last character, then it will be 
	inserted after the end. If the region is discontiguous, then 
	the contiguous pieces are concatenated together, in sequence, 
	and inserted. */
	
	virtual CLIENT RPTR(FeText) move (IntegerVar ARG(pos), APTR(IntegerRegion) ARG(region));
	
	/* Replaces a region of text with a virtual copy of text from 
	another document.
		If the destination region lies to the left of the domain, 
	inserts before the beginning; if it intersects the domain, 
	insert at the first common position; if it lies after the 
	end, insert after the end. Fails with
			BLAST(AmbiguousReplacement) if the region is empty.
		May be used to copy information within a single document.
		This operation may not be particularly useful with 
	non-simple destination regions. */
	
	virtual CLIENT RPTR(FeText) replace (APTR(IntegerRegion) ARG(dest), APTR(FeText) ARG(other));
	
  private: /* private: */

	/* Check that information can be inserted at the position. 
	Blast if not. */
	
	virtual void validate (IntegerVar ARG(pos));
	
  protected: /* protected: create */

	
	FeText (APTR(FeEdition) ARG(edition), APTR(FeWrapperSpec) ARG(spec));
	
  public: /* printing */

	
	virtual void printOn (ostream& ARG(oo));
	


  /* ---------- Static Member variables (class vars) ----------- */
  private:
	static GPTR(FeWrapperSpec) TheTextSpec;
};  /* end class FeText */



/* ************************************************************************ *
 * 
 *                    Class FeWrapperSpec 
 *
 * ************************************************************************ */



/* Initializers for FeWrapperSpec */





/* exceptions: exceptions */

PROBLEM_LIST(WrapFailureFilter,1,(CannotWrap));



	/* Handles wrapping, certification, and filtering for a 
	wrapper type and its subtypes (if there are any) */

class FeWrapperSpec : public Heaper {

/* Attributes for class FeWrapperSpec */
	DEFERRED(FeWrapperSpec)
	ON_CLIENT(FeWrapperSpec)
	EQ(FeWrapperSpec)
	AUTO_GC(FeWrapperSpec)

/* Initializers for FeWrapperSpec */



friend class INIT_TIME_NAME(FeWrapperSpec,initTimeNonInherited);

  public: /* registering wrappers */

	
	static void registerAbstract (
			char * ARG(wrapperName), 
			char OR(NULL) * ARG(superName), 
			FeWrapperSpecHolder OR(NULL) ARG(holder))
	;
	
	
	static void registerDirect (
			char * ARG(wrapperName), 
			char OR(NULL) * ARG(superName), 
			FeDirectWrapperMaker ARG(maker), 
			FeDirectWrapperChecker ARG(checker), 
			FeWrapperSpecHolder ARG(holder))
	;
	
	
	static void registerIndirect (
			char * ARG(wrapperName), 
			char OR(NULL) * ARG(superName), 
			char OR(NULL) * ARG(innerName), 
			FeIndirectWrapperMaker ARG(maker), 
			FeIndirectWrapperChecker ARG(checker), 
			FeWrapperSpecHolder ARG(holder))
	;
	
  private: /* private: */

	
	static void mustSetup ();
	
  public: /* accessing */

	/* Get the local Wrapper spec with the given identifier, or 
	NULL if there is none */
	
	static RPTR(FeWrapperSpec) OR(NULL) fetch (APTR(Sequence) ARG(identifier));
	
	/* Get the local Wrapper spec with the given identifier, or 
	blast if there is none */
	
	static CLIENT RPTR(FeWrapperSpec) get (APTR(Sequence) ARG(identifier));
	
	/* Get the endorsements for the named wrapper space */
	
	static RPTR(CrossRegion) getEndorsements (APTR(Sequence) ARG(identifier));
	
	/* Get the wrapper spec corresponding to the given endorsement */
	
	static RPTR(FeWrapperSpec) getFromEndorsement (APTR(Tuple) ARG(endorsement));
	
	/* The names of all of the known wrappers */
	
	static RPTR(XnRegion) OF1(Sequence) knownWrappers ();
	
	/* Get the local Wrapper spec with the given identifier, or 
	NULL if there is none */
	
	static void setupWrapperSpecs ();
	
	/* A table mapping from wrapper names to endorsements */
	
	static void setWrapperEndorsements (APTR(ScruTable) OF2(Sequence,CrossRegion) ARG(endorsements));
	
  public: /* accessing */

	/* Whether the Edition passes the invariants of this type so 
	that it could be certified. Always checks the actual contents 
	and endorses if they are acceptable. */
	
	virtual BooleanVar certify (APTR(FeEdition) ARG(edition)) DEFERRED_FUNC;
	
	/* A filter which selects for Editions which have been 
	endorsed as belonging to this type. */
	
	virtual CLIENT RPTR(Filter) filter ();
	
	/* Whether an Edition is already endorsed as being of this 
	type. Equivalent to
			this->filter ()->match (edition->endorsements ()) */
	
	virtual BooleanVar isCertified (APTR(FeEdition) ARG(edition));
	
	/* The name for this type */
	
	virtual CLIENT RPTR(Sequence) name ();
	
	/* The Edition wrapped with my type of Wrapper. If it does 
	not have endorsements, will attempt to certify. Blasts if 
	there is more than one valid wrapping. */
	
	virtual CLIENT RPTR(FeWrapper) wrap (APTR(FeEdition) ARG(edition));
	
  public: /* vulnerable */

	
	virtual RPTR(FeWrapper) OR(NULL) fetchWrap (APTR(FeEdition) ARG(edition)) DEFERRED_FUNC;
	
	/* Whether this is the same as or a kind of the other spec */
	
	virtual BooleanVar isSubSpecOf (APTR(FeWrapperSpec) ARG(other));
	
  protected: /* protected: */

	/* Add some more endorsements to filter for */
	
	virtual void addToFilter (APTR(CrossRegion) ARG(endorsements));
	
	
	virtual RPTR(FeWrapperDef) def ();
	
	/* The immediate supertype, or NULL if this is the generic 
	Wrapper type */
	
	virtual RPTR(FeAbstractWrapperSpec) OR(NULL) fetchSuperSpec ();
	
	/* Do the required setup for this spec in the context of a 
	table of all known specs */
	
	virtual void setup ();
	
  public: /* create */

	
	FeWrapperSpec (APTR(FeWrapperDef) ARG(def), TCSJ);
	
  public: /* for wrappers only */

	/* Endorse the Edition as being of this type. Blasts if this 
	is an abstract type.
		Should only be called from the code implementing the type, 
	or code which it trusts. We may eventually add a system to 
	enforce this. */
	
	virtual void endorse (APTR(FeEdition) ARG(edition)) DEFERRED_SUBR;
	
	
	virtual RPTR(CrossRegion) endorsements ();
	
  private:
	CHKPTR(FeWrapperDef) myDef;
	CHKPTR(CrossRegion) myEndorsements;
	CHKPTR(Filter) myFilter;
	CHKPTR(FeAbstractWrapperSpec) OR(NULL) mySuperSpec;

  /* ---------- Static Member variables (class vars) ----------- */
  private:
	static GPTR(MuTable) OF2(Tumbler,FeWrapperDef) TheWrapperDefs;
	static GPTR(MuTable) OF2(Tumbler,CrossRegion) TheWrapperEndorsements;
	static GPTR(MuTable) OF2(Tuple,FeWrapperSpec) TheWrappersFromEndorsements;
	static GPTR(MuTable) OF2(Tumbler,FeWrapperSpec) TheWrapperSpecs;
/* Friends for class FeWrapperSpec */
/* friends for class FeWrapperSpec */
friend class FeWrapper;



};  /* end class FeWrapperSpec */



#endif /* WRAPPERX_HXX */

