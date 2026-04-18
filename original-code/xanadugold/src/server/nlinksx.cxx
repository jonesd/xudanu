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

#ifndef NLINKSX_CXX
#define NLINKSX_CXX


#ifndef CHOOSEX_HXX
#include "choosex.hxx"
#endif /* CHOOSEX_HXX */

#ifndef NLINKSX_HXX
#include "nlinksx.hxx"
#endif /* NLINKSX_HXX */

#ifndef NLINKSX_IXX
#include "nlinksx.ixx"
#endif /* NLINKSX_IXX */


#ifndef BRANGE2X_HXX
#include "brange2x.hxx"
#endif /* BRANGE2X_HXX */

#ifndef FILTERX_HXX
#include "filterx.hxx"
#endif /* FILTERX_HXX */

#ifndef IDX_HXX
#include "idx.hxx"
#endif /* IDX_HXX */

#ifndef INTEGERX_HXX
#include "integerx.hxx"
#endif /* INTEGERX_HXX */

#ifndef NKERNELX_HXX
#include "nkernelx.hxx"
#endif /* NKERNELX_HXX */

#ifndef PARRAYX_HXX
#include "parrayx.hxx"
#endif /* PARRAYX_HXX */

#ifndef SEQUENCX_HXX
#include "sequencx.hxx"
#endif /* SEQUENCX_HXX */

#ifndef SPACEX_HXX
#include "spacex.hxx"
#endif /* SPACEX_HXX */

#ifndef STEPPERX_HXX
#include "stepperx.hxx"
#endif /* STEPPERX_HXX */




/* ************************************************************************ *
 * 
 *                    Class FeHyperLink 
 *
 * ************************************************************************ */



/* Initializers for FeHyperLink */

GPTR(FeWrapperSpec) FeHyperLink::TheHyperLinkSpec = NULL;



BEGIN_INIT_TIME(FeHyperLink,initTimeNonInherited) {
	DIRECTWRAPPER("HyperLink","Wrapper",FeHyperLink);
} END_INIT_TIME(FeHyperLink,initTimeNonInherited);



/* Initializers for FeHyperLink */






/* private: wrapping */


BooleanVar FeHyperLink::check (APTR(FeEdition) edition){
	/* Check that it has the right fields in the right places. 
	Ignore other contents. */
	
	{	BooleanVar crutch_Flag;
		/* FeWrapper::checkDomainHas(edition, Sequence::string("Link:LinkTypes")->asRegion()) && FeWrapper::checkSubEdition(edition, Sequence::string("Link:LinkTypes"), FeSet::spec(), FALSE) && 
							FeWrapper::checkSubEditions(edition, edition->domain()->without(Sequence::string("Link:LinkTypes")), FeHyperRef::spec(), TRUE) */
		
		crutch_Flag = FeWrapper::checkDomainHas(edition, Sequence::string("Link:LinkTypes")->asRegion());
		if(crutch_Flag) {
			crutch_Flag = FeWrapper::checkSubEdition(edition, Sequence::string("Link:LinkTypes"), FeSet::spec(), FALSE);
			if(crutch_Flag) {
				crutch_Flag = FeWrapper::checkSubEditions(edition, edition->domain()->without(Sequence::string("Link:LinkTypes")), FeHyperRef::spec(), TRUE);
			}
		}
		if (!crutch_Flag) {
			return FALSE;
		}
	}
	if (edition->includesKey(Sequence::string("Link:LinkTypes"))) {
		SPTR(FeEdition) sub;
		
		sub = CAST(FeEdition,edition->get(Sequence::string("Link:LinkTypes")));
		BEGIN_FOR_EACH(FeRangeElement,r,(sub->stepper())) {
			{	BooleanVar crutch_Flag;
				/* r->isKindOf(cat_FeEdition) && FeHyperRef::spec()->certify(CAST(FeEdition,r)) */
				
				crutch_Flag = r->isKindOf(cat_FeEdition);
				if(crutch_Flag) {
					crutch_Flag = FeHyperRef::spec()->certify(CAST(FeEdition,r));
				}
				if (!crutch_Flag) {
					return FALSE;
				}
			}
		} END_FOR_EACH;
	}
	return TRUE;
}


RPTR(FeHyperLink) FeHyperLink::construct (APTR(FeEdition) edition){
	FeHyperLink::spec()->endorse(edition);
	edition->endorse(FeServer::endorsementRegion(CAST(IDRegion,CurrentAuthor.fluidGet()->asRegion()), FeServer::iDsOfRange(CAST(FeEdition,edition->get(Sequence::string("Link:LinkTypes"))))));
	return CAST(FeHyperLink,FeHyperLink::makeWrapper(edition));
}


RPTR(FeWrapper) FeHyperLink::makeWrapper (APTR(FeEdition) edition){
	/* Just create a new wrapper */
	
	RETURN_CONSTRUCT(FeHyperLink,(edition, FeHyperLink::spec()));
}


void FeHyperLink::setSpec (APTR(FeWrapperSpec) wrap){
	FeHyperLink::TheHyperLinkSpec = wrap;
}
/* pseudo constructors */


RPTR(Filter) FeHyperLink::linkFilter (APTR(IDRegion) types){
	/* A Filter for links of the specified types */
	
	BLAST(NOT_YET_IMPLEMENTED);
	/* fodder */
	return NULL;
}


RPTR(FeHyperLink) FeHyperLink::make (
		APTR(FeSet) types, 
		APTR(FeHyperRef) leftEnd, 
		APTR(FeHyperRef) rightEnd)
{
	/* Make a standard two-ended link */
	
	SPTR(PtrArray) OF1(FeEdition) values;
	
	BEGIN_FOR_EACH(FeRangeElement,t,(types->stepper())) {
		if (!t->isKindOf(cat_FeWork)) {
			BLAST(InvalidParameter);
		}
	} END_FOR_EACH;
	values = PtrArray::nulls(3);
	/* Put the values in the array in alphabetical order of keys */
	values->store(Int32Zero, leftEnd->edition());
	values->store(1, types->edition());
	values->store(2, rightEnd->edition());
	WPTR(FeHyperLink) 	returnValue;
	returnValue = FeHyperLink::construct(
			FeEdition::fromArray(values, Sequence::string("Link:LinkTypes")->asRegion()->with(Sequence::string("Link:LeftEnd"))->with(Sequence::string("Link:RightEnd")), SequenceSpace::make ()->getAscending()));
	return returnValue;
}


RPTR(FeWrapperSpec) FeHyperLink::spec (){
	WPTR(FeWrapperSpec) 	returnValue;
	returnValue = FeHyperLink::TheHyperLinkSpec;
	return returnValue;
}
/* Contains a named table of HyperRefs and a set of Works which 
describe the usage and/or format of the link. */


/* accessing */


RPTR(FeHyperRef) FeHyperLink::endAt (APTR(Sequence) name){
	/* Get the HyperRef at the given name; blast if none there */
	
	if (name->isEqual(Sequence::string("Link:LinkTypes"))) {
		BLAST(MustUseDifferentLinkEndKey);
	}
	return CAST(FeHyperRef,FeHyperRef::spec()->wrap(CAST(FeEdition,this->edition()->get(name))));
}


RPTR(SequenceRegion) FeHyperLink::endNames (){
	/* The names of all of the ends of this link */
	
	return CAST(SequenceRegion,this->edition()->domain()->without(Sequence::string("HyperLink:LinkTypes")));
}


RPTR(FeSet) OF1(FeWork) FeHyperLink::linkTypes (){
	/* The various type documents describing this kind of Link. 
	These documents are typically Editions with descriptions at 
	each linkEnd key describing what is at that Link End.
		The reason for having several is to allow type hierarchies 
	to be constructed and searched for, by including all super 
	types of a link in its link type list.
		The Link should be endorsed with all the IDs of all the types.
		What if someone endorses it further (or unendorses it?) */
	
	return CAST(FeSet,FeSet::spec()->wrap(CAST(FeEdition,this->edition()->get(Sequence::string("Link:LinkTypes")))));
}


RPTR(FeHyperLink) FeHyperLink::withEnd (APTR(Sequence) name, APTR(FeHyperRef) linkEnd){
	/* Change/add a Link end */
	
	if (name->isEqual(Sequence::string("Link:LinkTypes"))) {
		BLAST(MustUseDifferentLinkEndName);
	}
	WPTR(FeHyperLink) 	returnValue;
	returnValue = FeHyperLink::construct(this->edition()->with(name, linkEnd->edition()));
	return returnValue;
}


RPTR(FeHyperLink) FeHyperLink::withLinkTypes (APTR(FeSet) OF1(FeWork) types){
	/* Replace the set of type documents describing this kind of Link */
	
	WPTR(FeHyperLink) 	returnValue;
	returnValue = FeHyperLink::construct(this->edition()->with(Sequence::string("Link:LinkTypes"), types->edition()));
	return returnValue;
}


RPTR(FeHyperLink) FeHyperLink::withoutEnd (APTR(Sequence) name){
	/* Remove a Link end */
	
	if (name->isEqual(Sequence::string("Link:LinkTypes"))) {
		BLAST(MustUseDifferentLinkEndName);
	}
	WPTR(FeHyperLink) 	returnValue;
	returnValue = FeHyperLink::construct(this->edition()->without(name));
	return returnValue;
}
/* private: create */


FeHyperLink::FeHyperLink (APTR(FeEdition) edition, APTR(FeWrapperSpec) spec) 
	: FeWrapper(edition, spec) {
	
}



/* ************************************************************************ *
 * 
 *                    Class FeHyperRef 
 *
 * ************************************************************************ */



/* Initializers for FeHyperRef */

GPTR(FeWrapperSpec) FeHyperRef::TheHyperRefSpec = NULL;



BEGIN_INIT_TIME(FeHyperRef,initTimeNonInherited) {
	ABSTRACTWRAPPER("HyperRef","Wrapper",FeHyperRef);
} END_INIT_TIME(FeHyperRef,initTimeNonInherited);



/* Initializers for FeHyperRef */






/* protected: wrapping */


BooleanVar FeHyperRef::check (APTR(FeEdition) edition){
	/* Check that it has the right fields in the right places. 
	Ignore other contents. */
	
	{	BooleanVar crutch_Flag;
		/* edition->coordinateSpace()->isEqual(SequenceSpace::make ()) && edition->domain()->intersects(Sequence::string("HyperRef:PathContext")->asRegion()->with(Sequence::string("HyperRef:WorkContext"))->with(Sequence::string("HyperRef:OriginalContext"))) && FeWrapper::checkSubWork(edition, Sequence::string("HyperRef:WorkContext"), FALSE) && 
									FeWrapper::checkSubWork(edition, Sequence::string("HyperRef:OriginalContext"), FALSE) && 
											FeWrapper::checkSubEdition(edition, Sequence::string("HyperRef:PathContext"), FePath::spec(), FALSE) */
		
		crutch_Flag = edition->coordinateSpace()->isEqual(SequenceSpace::make ());
		if(crutch_Flag) {
			crutch_Flag = edition->domain()->intersects(Sequence::string("HyperRef:PathContext")->asRegion()->with(Sequence::string("HyperRef:WorkContext"))->with(Sequence::string("HyperRef:OriginalContext")));
			if(crutch_Flag) {
				crutch_Flag = FeWrapper::checkSubWork(edition, Sequence::string("HyperRef:WorkContext"), FALSE);
				if(crutch_Flag) {
					crutch_Flag = FeWrapper::checkSubWork(edition, Sequence::string("HyperRef:OriginalContext"), FALSE);
					if(crutch_Flag) {
						crutch_Flag = FeWrapper::checkSubEdition(edition, Sequence::string("HyperRef:PathContext"), FePath::spec(), FALSE);
					}
				}
			}
		}
		return crutch_Flag;
	}
}


void FeHyperRef::setSpec (APTR(FeWrapperSpec) spec){
	FeHyperRef::TheHyperRefSpec = spec;
}
/* pseudo constructors */


RPTR(FeWrapperSpec) FeHyperRef::spec (){
	WPTR(FeWrapperSpec) 	returnValue;
	returnValue = FeHyperRef::TheHyperRefSpec;
	return returnValue;
}
/* Represents a single attachment to some material in context. */


/* accessing */


RPTR(FeWork) FeHyperRef::originalContext (){
	/* A Work frozen on the contents of the Work at the time the 
	HyperRef was made */
	
	return CAST(FeWork,this->edition()->get(Sequence::string("HyperRef:OriginalContext")));
}


RPTR(FePath) FeHyperRef::pathContext (){
	/* The path of labels down from the top-level Edition */
	
	return CAST(FePath,FePath::spec()->wrap(CAST(FeEdition,this->edition()->get(Sequence::string("HyperRef:PathContext")))));
}


RPTR(FeHyperRef) FeHyperRef::withOriginalContext (APTR(FeWork) OR(NULL) work){
	/* Change (or remove if NULL) the originalContext */
	
	if (work == NULL) {
		WPTR(FeHyperRef) 	returnValue;
		returnValue = this->makeNew(this->edition()->without(Sequence::string("HyperRef:OriginalContext")));
		return returnValue;
	} else {
		if (CAST(BeWork,work->fetchBe())->fetchEditClub() != NULL) {
			BLAST(MustBeFrozen);
		}
		WPTR(FeHyperRef) 	returnValue;
		returnValue = this->makeNew(this->edition()->with(Sequence::string("HyperRef:OriginalContext"), work));
		return returnValue;
	}
}


RPTR(FeHyperRef) FeHyperRef::withPathContext (APTR(FePath) OR(NULL) path){
	/* Change (or remove if NULL) the pathContext */
	
	if (path == NULL) {
		WPTR(FeHyperRef) 	returnValue;
		returnValue = this->makeNew(this->edition()->without(Sequence::string("HyperRef:PathContext")));
		return returnValue;
	} else {
		WPTR(FeHyperRef) 	returnValue;
		returnValue = this->makeNew(this->edition()->with(Sequence::string("HyperRef:PathContext"), path->edition()));
		return returnValue;
	}
}


RPTR(FeHyperRef) FeHyperRef::withWorkContext (APTR(FeWork) OR(NULL) work){
	/* Change (or remove if NULL) the workContext */
	
	if (work == NULL) {
		WPTR(FeHyperRef) 	returnValue;
		returnValue = this->makeNew(this->edition()->without(Sequence::string("HyperRef:WorkContext")));
		return returnValue;
	} else {
		WPTR(FeHyperRef) 	returnValue;
		returnValue = this->makeNew(this->edition()->with(Sequence::string("HyperRef:WorkContext"), work));
		return returnValue;
	}
}


RPTR(FeWork) FeHyperRef::workContext (){
	/* The Work whose state this is attached to. */
	
	return CAST(FeWork,this->edition()->get(Sequence::string("HyperRef:WorkContext")));
}
/* protected: create */


FeHyperRef::FeHyperRef (APTR(FeEdition) edition, APTR(FeWrapperSpec) spec) 
	: FeWrapper(edition, spec) {
	
}



/* ************************************************************************ *
 * 
 *                    Class   FeMultiRef 
 *
 * ************************************************************************ */



/* Initializers for FeMultiRef */

GPTR(FeWrapperSpec) FeMultiRef::TheMultiRefSpec = NULL;



BEGIN_INIT_TIME(FeMultiRef,initTimeNonInherited) {
	DIRECTWRAPPER("MultiRef","HyperRef",FeMultiRef);
} END_INIT_TIME(FeMultiRef,initTimeNonInherited);



/* Initializers for FeMultiRef */






/* private: wrapping */


BooleanVar FeMultiRef::check (APTR(FeEdition) edition){
	/* Check that it has the right fields in the right places. 
	Ignore other contents. */
	
	SPTR(FeEdition) refs;
	
	{	BooleanVar crutch_Flag;
		/* FeHyperRef::check(edition) && FeWrapper::checkSubEdition(edition, Sequence::string("MultiRef:Refs"), NULL, TRUE) && 
							(refs = CAST(FeEdition,edition->get(Sequence::string("MultiRef:Refs"))))->coordinateSpace()->isKindOf(cat_IDSpace) && 
									FeWrapper::checkSubEditions(refs, refs->domain(), FeHyperRef::spec(), TRUE) */
		
		crutch_Flag = FeHyperRef::check(edition);
		if(crutch_Flag) {
			crutch_Flag = FeWrapper::checkSubEdition(edition, Sequence::string("MultiRef:Refs"), NULL, TRUE);
			if(crutch_Flag) {
				crutch_Flag = (refs = CAST(FeEdition,edition->get(Sequence::string("MultiRef:Refs"))))->coordinateSpace()->isKindOf(cat_IDSpace);
				if(crutch_Flag) {
					crutch_Flag = FeWrapper::checkSubEditions(refs, refs->domain(), FeHyperRef::spec(), TRUE);
				}
			}
		}
		return crutch_Flag;
	}
}


RPTR(FeMultiRef) FeMultiRef::construct (APTR(FeEdition) edition){
	/* Create a new wrapper and endorse it */
	
	FeMultiRef::spec()->endorse(edition);
	return CAST(FeMultiRef,FeMultiRef::makeWrapper(edition));
}


RPTR(FeWrapper) FeMultiRef::makeWrapper (APTR(FeEdition) edition){
	/* Just create a new wrapper */
	
	RETURN_CONSTRUCT(FeMultiRef,(edition, FeMultiRef::spec()));
}


void FeMultiRef::setSpec (APTR(FeWrapperSpec) wrap){
	FeMultiRef::TheMultiRefSpec = wrap;
}
/* creation */


RPTR(FeMultiRef) FeMultiRef::make (
		APTR(PtrArray) OF1(FeHyperRef) OR(NULL) refs, 
		APTR(FeWork) workContext/* = NULL*/, 
		APTR(FeWork) originalContext/* = NULL*/, 
		APTR(FePath) pathContext/* = NULL*/)
{
	/* Make a new MultiRef. At least one of the parameters must 
	be non-NULL. The originalContext, if supplied,  must be a 
	frozen Work. */
	
	SPTR(FeEdition) result;
	SPTR(FeEdition) refEdition;
	
	{	BooleanVar crutch_Flag;
		/* refs == NULL && workContext == NULL && originalContext == NULL && pathContext == NULL */
		
		crutch_Flag = refs == NULL;
		if(crutch_Flag) {
			crutch_Flag = workContext == NULL;
			if(crutch_Flag) {
				crutch_Flag = originalContext == NULL;
				if(crutch_Flag) {
					crutch_Flag = pathContext == NULL;
				}
			}
		}
		if (crutch_Flag) {
			BLAST(MustSupplySomeHyperRefInformation);
		}
	}
	{	BooleanVar crutch_Flag;
		/* originalContext != NULL && CAST(BeWork,originalContext->fetchBe())->fetchEditClub() != NULL */
		
		crutch_Flag = originalContext != NULL;
		if(crutch_Flag) {
			crutch_Flag = CAST(BeWork,originalContext->fetchBe())->fetchEditClub() != NULL;
		}
		if (crutch_Flag) {
			BLAST(OriginalContextMustBeFrozen);
		}
	}
	if (refs == NULL) {
		refEdition = FeEdition::empty(IDSpace::unique());
	} else {
		SPTR(PtrArray) OF1(FeEdition) array;
		
		array = PtrArray::nulls(refs->count());
		{
			Int32 LoopFinal = refs->count();
			Int32 i = Int32Zero;
			for (;;) {
				if (i >= LoopFinal){
					break;
				}
				{
					array->store(i, CAST(FeHyperRef,refs->get(i))->edition());
				}
				i += 1;
			}
		}
		refEdition = FeEdition::fromArray(array, IDSpace::unique()->newIDs(array->count()));
	}
	result = FeEdition::fromOne(Sequence::string("MultiRef:Refs"), refEdition);
	if (workContext != NULL) {
		result = result->with(Sequence::string("HyperRef:WorkContext"), workContext);
	}
	if (originalContext != NULL) {
		result = result->with(Sequence::string("HyperRef:OriginalContext"), originalContext);
	}
	if (pathContext != NULL) {
		result = result->with(Sequence::string("HyperRef:PathContext"), pathContext->edition());
	}
	WPTR(FeMultiRef) 	returnValue;
	returnValue = FeMultiRef::construct(result);
	return returnValue;
}


RPTR(FeWrapperSpec) FeMultiRef::spec (){
	WPTR(FeWrapperSpec) 	returnValue;
	returnValue = FeMultiRef::TheMultiRefSpec;
	return returnValue;
}
/* An undifferentiated set of HyperRefs */


/* private: */


RPTR(FeEdition) FeMultiRef::refsEdition (){
	/* The Edition holding the HyperRefs */
	
	return CAST(FeEdition,this->edition()->get(Sequence::string("MultiRef:Refs")));
}


RPTR(FeMultiRef) FeMultiRef::withRefsEdition (APTR(FeEdition) edition){
	/* With a different refs Edition */
	
	/* Ravi -- Thing to do !!!! */
	
	/* check about preserving labels */
	WPTR(FeMultiRef) 	returnValue;
	returnValue = FeMultiRef::construct(this->edition()->with(Sequence::string("MultiRef:Refs"), edition));
	return returnValue;
}
/* accessing */


RPTR(FeMultiRef) FeMultiRef::intersect (APTR(FeMultiRef) other){
	/* Remove those not in the other Refs from the set. */
	
	WPTR(FeMultiRef) 	returnValue;
	returnValue = this->withRefsEdition(this->refsEdition()->sharedWith(other->refsEdition()));
	return returnValue;
}


RPTR(FeMultiRef) FeMultiRef::minus (APTR(FeMultiRef) other){
	/* Remove the other Refs from the set. */
	
	WPTR(FeMultiRef) 	returnValue;
	returnValue = this->withRefsEdition(this->refsEdition()->notSharedWith(other->refsEdition()));
	return returnValue;
}


RPTR(Stepper) OF1(FeHyperRef) FeMultiRef::refs (){
	/* All the HyperRefs in the collection */
	
	BLAST(NOT_YET_IMPLEMENTED);
	/* fodder */
	return NULL;
}


RPTR(FeMultiRef) FeMultiRef::unionWith (APTR(FeMultiRef) other){
	/* Add the other Refs into the set. */
	
	SPTR(FeEdition) added;
	SPTR(FeEdition) result;
	SPTR(Stepper) stepper;
	SPTR(PrimArray) more;
	
	added = other->refsEdition()->notSharedWith(this->refsEdition());
	if (added->isEmpty()) {
		return this;
	}
	result = this->refsEdition();
	stepper = added->stepper();
	while (stepper->hasValue()) {
		more = stepper->stepMany();
		result = result->combine(FeEdition::fromArray(more, CAST(IDSpace,this->refsEdition()->coordinateSpace())->newIDs(more->count())));
	}
	WPTR(FeMultiRef) 	returnValue;
	returnValue = this->withRefsEdition(result);
	return returnValue;
}


RPTR(FeMultiRef) FeMultiRef::with (APTR(FeHyperRef) ref){
	/* Add a Ref to the set */
	
	if (this->refsEdition()->positionsOf(ref->edition())->isEmpty()) {
		WPTR(FeMultiRef) 	returnValue;
		returnValue = this->withRefsEdition(this->refsEdition()->with(CAST(IDSpace,this->refsEdition()->coordinateSpace())->newID(), ref->edition()));
		return returnValue;
	} else {
		return this;
	}
}


RPTR(FeMultiRef) FeMultiRef::without (APTR(FeHyperRef) ref){
	/* Add a Ref to the set */
	
	SPTR(XnRegion) keys;
	
	if ((keys = this->refsEdition()->positionsOf(ref->edition()))->isEmpty()) {
		return this;
	} else {
		WPTR(FeMultiRef) 	returnValue;
		returnValue = this->withRefsEdition(this->refsEdition()->copy(keys->complement()));
		return returnValue;
	}
}
/* protected: */


RPTR(FeHyperRef) FeMultiRef::makeNew (APTR(FeEdition) edition){
	/* Make a new HyperRef of the same type with different contents */
	
	WPTR(FeHyperRef) 	returnValue;
	returnValue = FeMultiRef::construct(edition);
	return returnValue;
}
/* private: create */


FeMultiRef::FeMultiRef (APTR(FeEdition) edition, APTR(FeWrapperSpec) spec) 
	: FeHyperRef(edition, spec) {
	
}



/* ************************************************************************ *
 * 
 *                    Class   FeSingleRef 
 *
 * ************************************************************************ */



/* Initializers for FeSingleRef */

GPTR(FeWrapperSpec) FeSingleRef::TheSingleRefSpec = NULL;



BEGIN_INIT_TIME(FeSingleRef,initTimeNonInherited) {
	DIRECTWRAPPER("SingleRef","HyperRef",FeSingleRef);
} END_INIT_TIME(FeSingleRef,initTimeNonInherited);



/* Initializers for FeSingleRef */






/* private: wrapping */


BooleanVar FeSingleRef::check (APTR(FeEdition) edition){
	/* Check that it has the right fields in the right places. 
	Ignore other contents. */
	
	{	BooleanVar crutch_Flag;
		/* FeHyperRef::check(edition) && 
					FeWrapper::checkSubEdition(edition, Sequence::string("HyperRef:AttachedMaterial"), NULL, FALSE) */
		
		crutch_Flag = FeHyperRef::check(edition);
		if(crutch_Flag) {
			crutch_Flag = FeWrapper::checkSubEdition(edition, Sequence::string("HyperRef:AttachedMaterial"), NULL, FALSE);
		}
		return crutch_Flag;
	}
}


RPTR(FeSingleRef) FeSingleRef::construct (APTR(FeEdition) edition){
	/* Create a new wrapper and endorse it */
	
	FeSingleRef::spec()->endorse(edition);
	return CAST(FeSingleRef,FeSingleRef::makeWrapper(edition));
}


RPTR(FeWrapper) FeSingleRef::makeWrapper (APTR(FeEdition) edition){
	/* Just create a new wrapper */
	
	RETURN_CONSTRUCT(FeSingleRef,(edition, FeSingleRef::spec()));
}


void FeSingleRef::setSpec (APTR(FeWrapperSpec) wrap){
	FeSingleRef::TheSingleRefSpec = wrap;
}
/* creation */


RPTR(FeSingleRef) FeSingleRef::make (
		APTR(FeEdition) OR(NULL) material, 
		APTR(FeWork) workContext/* = NULL*/, 
		APTR(FeWork) originalContext/* = NULL*/, 
		APTR(FePath) pathContext/* = NULL*/)
{
	/* Make a new SingleRef. At least one of the parameters must 
	be non-NULL. The originalContext, if supplied,  must be a 
	frozen Work. */
	
	SPTR(FeEdition) result;
	
	{	BooleanVar crutch_Flag;
		/* material == NULL && workContext == NULL && originalContext == NULL && pathContext == NULL */
		
		crutch_Flag = material == NULL;
		if(crutch_Flag) {
			crutch_Flag = workContext == NULL;
			if(crutch_Flag) {
				crutch_Flag = originalContext == NULL;
				if(crutch_Flag) {
					crutch_Flag = pathContext == NULL;
				}
			}
		}
		if (crutch_Flag) {
			BLAST(MustSupplySomeHyperRefInformation);
		}
	}
	{	BooleanVar crutch_Flag;
		/* originalContext != NULL && CAST(BeWork,originalContext->fetchBe())->fetchEditClub() != NULL */
		
		crutch_Flag = originalContext != NULL;
		if(crutch_Flag) {
			crutch_Flag = CAST(BeWork,originalContext->fetchBe())->fetchEditClub() != NULL;
		}
		if (crutch_Flag) {
			BLAST(OriginalContextMustBeFrozen);
		}
	}
	result = FeEdition::empty(SequenceSpace::make ());
	if (workContext != NULL) {
		result = result->with(Sequence::string("HyperRef:WorkContext"), workContext);
	}
	if (originalContext != NULL) {
		result = result->with(Sequence::string("HyperRef:OriginalContext"), originalContext);
	}
	if (material != NULL) {
		result = result->with(Sequence::string("HyperRef:Excerpt"), material);
	}
	if (pathContext != NULL) {
		result = result->with(Sequence::string("HyperRef:PathContext"), pathContext->edition());
	}
	WPTR(FeSingleRef) 	returnValue;
	returnValue = FeSingleRef::construct(result);
	return returnValue;
}


RPTR(FeWrapperSpec) FeSingleRef::spec (){
	WPTR(FeWrapperSpec) 	returnValue;
	returnValue = FeSingleRef::TheSingleRefSpec;
	return returnValue;
}
/* Represents a single attachment to some material in the context of 
a Work, and maybe a Path beneath it. */


/* accessing */


RPTR(FeEdition) FeSingleRef::excerpt (){
	/* The material to which this HyperRef is attached. */
	
	return CAST(FeEdition,this->edition()->get(Sequence::string("HyperRef:Excerpt")));
}


RPTR(FeSingleRef) FeSingleRef::withExcerpt (APTR(FeEdition) excerpt){
	/* Make this Ref point at different material. */
	
	WPTR(FeSingleRef) 	returnValue;
	returnValue = FeSingleRef::construct(this->edition()->with(Sequence::string("HyperRef:Excerpt"), excerpt));
	return returnValue;
}
/* protected: */


RPTR(FeHyperRef) FeSingleRef::makeNew (APTR(FeEdition) edition){
	/* Make a new HyperRef of the same type with different contents */
	
	WPTR(FeHyperRef) 	returnValue;
	returnValue = FeSingleRef::construct(edition);
	return returnValue;
}
/* private: create */


FeSingleRef::FeSingleRef (APTR(FeEdition) edition, APTR(FeWrapperSpec) spec) 
	: FeHyperRef(edition, spec) {
	
}



/* ************************************************************************ *
 * 
 *                    Class FePath 
 *
 * ************************************************************************ */



/* Initializers for FePath */

GPTR(FeWrapperSpec) FePath::ThePathSpec = NULL;



BEGIN_INIT_TIME(FePath,initTimeNonInherited) {
	DIRECTWRAPPER("Path","Wrapper",FePath);
} END_INIT_TIME(FePath,initTimeNonInherited);



/* Initializers for FePath */






/* pseudo constructors */


RPTR(FePath) FePath::make (APTR(PtrArray) OF1(FeLabel) labels){
	return CAST(FePath,FePath::spec()->wrap(FeEdition::fromArray(labels)));
}


RPTR(FeWrapperSpec) FePath::spec (){
	WPTR(FeWrapperSpec) 	returnValue;
	returnValue = FePath::ThePathSpec;
	return returnValue;
}
/* private: wrapping */


BooleanVar FePath::check (APTR(FeEdition) edition){
	/* Ravi -- Thing to do !!!! */
	
	/* check that there are only labels here */
	{	BooleanVar crutch_Flag;
		/* edition->domain()->isKindOf(cat_IntegerRegion) && CAST(IntegerRegion,edition->domain())->isCompacted() */
		
		crutch_Flag = edition->domain()->isKindOf(cat_IntegerRegion);
		if(crutch_Flag) {
			crutch_Flag = CAST(IntegerRegion,edition->domain())->isCompacted();
		}
		return crutch_Flag;
	}
}


RPTR(FePath) FePath::construct (APTR(FeEdition) edition){
	FePath::spec()->endorse(edition);
	return CAST(FePath,FePath::makeWrapper(edition));
}


RPTR(FeWrapper) FePath::makeWrapper (APTR(FeEdition) edition){
	RETURN_CONSTRUCT(FePath,(edition, FePath::spec()));
}


void FePath::setSpec (APTR(FeWrapperSpec) wrap){
	FePath::ThePathSpec = wrap;
}
/* A sequence of Labels, used for context information in a LinkEnd. */


/* operations */


RPTR(FeRangeElement) FePath::follow (APTR(FeEdition) edition){
	/* Follow a path down into an Edition and return what is at 
	the end of the path. Fail if at any point there is not 
	precisely one choice. */
	
	SPTR(FeRangeElement) result;
	SPTR(FeLabel) label;
	
	result = edition;
	{
		IntegerVar LoopFinal = this->edition()->count();
		IntegerVar index = IntegerVarZero;
		for (;;) {
			if (index >= LoopFinal){
				break;
			}
			{
				label = CAST(FeLabel,this->edition()->get(IntegerPos::make (index)));
				result = CAST(FeEdition,result)->get(CAST(FeEdition,result)->positionsLabelled(label)->theOne());
			}
			index += 1;
		}
	}
	WPTR(FeRangeElement) 	returnValue;
	returnValue = result;
	return returnValue;
}
/* private: create */


FePath::FePath (APTR(FeEdition) edition, APTR(FeWrapperSpec) spec) 
	: FeWrapper(edition, spec) {
	
}

#ifndef NLINKSX_SXX
#include "nlinksx.sxx"
#endif /* NLINKSX_SXX */



#endif /* NLINKSX_CXX */

