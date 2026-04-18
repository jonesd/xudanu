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

#ifndef WRAPPERX_CXX
#define WRAPPERX_CXX


#ifndef CHOOSEX_HXX
#include "choosex.hxx"
#endif /* CHOOSEX_HXX */

#ifndef WRAPPERX_HXX
#include "wrapperx.hxx"
#endif /* WRAPPERX_HXX */

#ifndef WRAPPERX_IXX
#include "wrapperx.ixx"
#endif /* WRAPPERX_IXX */

#ifndef WRAPPERP_HXX
#include "wrapperp.hxx"
#endif /* WRAPPERP_HXX */

#ifndef WRAPPERP_IXX
#include "wrapperp.ixx"
#endif /* WRAPPERP_IXX */


#ifndef BRANGE3X_HXX
#include "brange3x.hxx"
#endif /* BRANGE3X_HXX */

#ifndef GRANMAPX_HXX
#include "granmapx.hxx"
#endif /* GRANMAPX_HXX */

#ifndef IDX_HXX
#include "idx.hxx"
#endif /* IDX_HXX */

#ifndef INTEGERX_HXX
#include "integerx.hxx"
#endif /* INTEGERX_HXX */

#ifndef SPACEX_HXX
#include "spacex.hxx"
#endif /* SPACEX_HXX */

#ifndef STEPPERX_HXX
#include "stepperx.hxx"
#endif /* STEPPERX_HXX */




/* ************************************************************************ *
 * 
 *                    Class FeWrapper 
 *
 * ************************************************************************ */



/* Initializers for FeWrapper */

GPTR(FeWrapperSpec) FeWrapper::TheWrapperSpec = NULL;



BEGIN_INIT_TIME(FeWrapper,initTimeNonInherited) {
	ABSTRACTWRAPPER("Wrapper",NULL,FeWrapper);
} END_INIT_TIME(FeWrapper,initTimeNonInherited);



/* Initializers for FeWrapper */






/* private: wrapping */


void FeWrapper::setSpec (APTR(FeWrapperSpec) spec){
	FeWrapper::TheWrapperSpec = spec;
}
/* accessing */


RPTR(FeWrapperSpec) FeWrapper::spec (){
	WPTR(FeWrapperSpec) 	returnValue;
	returnValue = FeWrapper::TheWrapperSpec;
	return returnValue;
}
/* protected: checking */


BooleanVar FeWrapper::checkDomainHas (APTR(FeEdition) edition, APTR(XnRegion) required){
	/* Checks that the domain is in the right coordinate space 
	and is a superset of the given region */
	
	{	BooleanVar crutch_Flag;
		/* edition->coordinateSpace()->isEqual(required->coordinateSpace()) && required->isSubsetOf(edition->domain()) */
		
		crutch_Flag = edition->coordinateSpace()->isEqual(required->coordinateSpace());
		if(crutch_Flag) {
			crutch_Flag = required->isSubsetOf(edition->domain());
		}
		return crutch_Flag;
	}
}


BooleanVar FeWrapper::checkDomainIn (APTR(FeEdition) edition, APTR(XnRegion) limit){
	/* Checks that the domain is in the right coordinate space 
	and a subset of the given region */
	
	{	BooleanVar crutch_Flag;
		/* edition->coordinateSpace()->isEqual(limit->coordinateSpace()) && edition->domain()->isSubsetOf(limit) */
		
		crutch_Flag = edition->coordinateSpace()->isEqual(limit->coordinateSpace());
		if(crutch_Flag) {
			crutch_Flag = edition->domain()->isSubsetOf(limit);
		}
		return crutch_Flag;
	}
}


BooleanVar FeWrapper::checkSubEdition (
		APTR(FeEdition) parent, 
		APTR(Position) key, 
		APTR(FeWrapperSpec) OR(NULL) spec, 
		BooleanVar required)
{
	/* If there is a SubEdition at a key in an edition, and if a 
	spec is supplied, that it can be certified as the given type */
	
	SPTR(FeRangeElement) value;
	
	value = parent->fetch(key);
	if (value == NULL) {
		return !required;
	}
	{	BooleanVar crutch_Flag;
		/* value->isKindOf(cat_FeEdition) && (spec == NULL || spec->certify(CAST(FeEdition,value))) */
		
		crutch_Flag = value->isKindOf(cat_FeEdition);
		if(crutch_Flag) {
			crutch_Flag = spec == NULL;
			if(!crutch_Flag) {
				crutch_Flag = spec->certify(CAST(FeEdition,value));
			}
		}
		return crutch_Flag;
	}
}


BooleanVar FeWrapper::checkSubEditions (
		APTR(FeEdition) parent, 
		APTR(XnRegion) keys, 
		APTR(FeWrapperSpec) spec, 
		BooleanVar required)
{
	/* Check that everything in the region is an Edition, which 
	can be certified with the given type */
	
	BEGIN_FOR_EACH(Position,key,(keys->stepper())) {
		if (!FeWrapper::checkSubEdition(parent, key, spec, required)) {
			return FALSE;
		}
	} END_FOR_EACH;
	return TRUE;
}


BooleanVar FeWrapper::checkSubSequence (
		APTR(FeEdition) edition, 
		APTR(Position) key, 
		BooleanVar required)
{
	/* Whether there is an Edition there which can be 
	successfully converted into a zero based Sequence */
	
	SPTR(FeRangeElement) value;
	
	/* Hack !!!! */
	
	/* zones */
	value = edition->fetch(key);
	if (value == NULL) {
		return !required;
	}
	{	BooleanVar crutch_Flag;
		/* value->isKindOf(cat_FeEdition) && CAST(FeEdition,value)->coordinateSpace()->isEqual(IntegerSpace::make ()) && CAST(IntegerRegion,CAST(FeEdition,value)->domain())->isCompacted() */
		
		crutch_Flag = value->isKindOf(cat_FeEdition);
		if(crutch_Flag) {
			crutch_Flag = CAST(FeEdition,value)->coordinateSpace()->isEqual(IntegerSpace::make ());
			if(crutch_Flag) {
				crutch_Flag = CAST(IntegerRegion,CAST(FeEdition,value)->domain())->isCompacted();
			}
		}
		return crutch_Flag;
	}
}


BooleanVar FeWrapper::checkSubWork (
		APTR(FeEdition) parent, 
		APTR(Position) key, 
		BooleanVar required)
{
	/* If there is a SubWork at a key in an edition */
	
	SPTR(FeRangeElement) value;
	
	value = parent->fetch(key);
	if (value == NULL) {
		return !required;
	}
	{	BooleanVar crutch_Flag;
		/* value != NULL && value->isKindOf(cat_FeWork) */
		
		crutch_Flag = value != NULL;
		if(crutch_Flag) {
			crutch_Flag = value->isKindOf(cat_FeWork);
		}
		return crutch_Flag;
	}
}
/* An object which wraps an Edition, providing additional 
functionality for manipulating it and enforcing invariants on the format.

Implementation note:

The fact that you cannot get the spec of a Wrapper is deliberate. You 
can merely check that it is a kind of Edition you know, but no more; 
this makes it easy to compatibly add new leaf classes below existing ones. */


/* accessing */


RPTR(FeEdition) FeWrapper::edition (){
	/* Essential. The primitive Edition this is wrapping. */
	
	return (FeEdition*) myEdition;
}


RPTR(FeWrapper) FeWrapper::inner (){
	/* Essential. The next Wrapper inside this one; blasts if 
	this wraps an Edition directly. */
	
	if (myInner == NULL) {
		BLAST(NoInnerWrapper);
	}
	return (FeWrapper*) myInner;
}


BooleanVar FeWrapper::isWrapperOf (APTR(FeWrapperSpec) spec){
	/* Essential. Return TRUE if this is wrapped as the given 
	spec, or any one of its subtypes */
	
	return mySpec->isSubSpecOf(spec);
}
/* protected: create */


FeWrapper::FeWrapper (APTR(FeEdition) edition, APTR(FeWrapperSpec) spec) {
	myEdition = edition;
	myInner = NULL;
	mySpec = spec;
}


FeWrapper::FeWrapper (
		APTR(FeEdition) edition, 
		APTR(FeWrapper) inner, 
		APTR(FeWrapperSpec) spec) 
{
	myEdition = edition;
	myInner = inner;
	mySpec = spec;
}



/* ************************************************************************ *
 * 
 *                    Class   FeSet 
 *
 * ************************************************************************ */



/* Initializers for FeSet */

GPTR(FeWrapperSpec) FeSet::TheSetSpec = NULL;



BEGIN_INIT_TIME(FeSet,initTimeNonInherited) {
	DIRECTWRAPPER("Set","Wrapper",FeSet);
} END_INIT_TIME(FeSet,initTimeNonInherited);



/* Initializers for FeSet */






/* pseudo constructors */


RPTR(FeSet) FeSet::make (){
	WPTR(FeSet) 	returnValue;
	returnValue = FeSet::construct(FeEdition::empty(IDSpace::unique()));
	return returnValue;
}


RPTR(FeSet) FeSet::make (APTR(PtrArray) OF1(FeRangeElement) works){
	return CAST(FeSet,FeSet::spec()->wrap(FeEdition::fromArray(works, IDSpace::unique()->newIDs(works->count()))));
}


RPTR(FeWrapperSpec) FeSet::spec (){
	WPTR(FeWrapperSpec) 	returnValue;
	returnValue = FeSet::TheSetSpec;
	return returnValue;
}
/* private: wrapping */


BooleanVar FeSet::check (APTR(FeEdition) edition){
	{	BooleanVar crutch_Flag;
		/* edition->coordinateSpace()->isKindOf(cat_IDSpace) && edition->isFinite() */
		
		crutch_Flag = edition->coordinateSpace()->isKindOf(cat_IDSpace);
		if(crutch_Flag) {
			crutch_Flag = edition->isFinite();
		}
		return crutch_Flag;
	}
}


RPTR(FeSet) FeSet::construct (APTR(FeEdition) edition){
	FeSet::spec()->endorse(edition);
	return CAST(FeSet,FeSet::makeWrapper(edition));
}


RPTR(FeWrapper) FeSet::makeWrapper (APTR(FeEdition) edition){
	RETURN_CONSTRUCT(FeSet,(edition, FeSet::spec()));
}


void FeSet::setSpec (APTR(FeWrapperSpec) wrap){
	FeSet::TheSetSpec = wrap;
}
/* An undifferentiated set of RangeElements. */


/* private: */


RPTR(IDSpace) FeSet::iDSpace (){
	return CAST(IDSpace,this->edition()->coordinateSpace());
}
/* accessing */


IntegerVar FeSet::count (){
	/* The number of elements in the set */
	
	return this->edition()->count();
}


BooleanVar FeSet::includes (APTR(FeRangeElement) value){
	/* Whether the set includes the given RangeElement */
	
	return !this->edition()->keysOf(value)->isEmpty();
}


RPTR(FeSet) FeSet::intersect (APTR(FeSet) other){
	/* Return those elements which are in both sets */
	
	WPTR(FeSet) 	returnValue;
	returnValue = FeSet::construct(this->edition()->sharedWith(other->edition()));
	return returnValue;
}


RPTR(FeSet) FeSet::minus (APTR(FeSet) other){
	/* Remove some RangeElements from the set */
	
	WPTR(FeSet) 	returnValue;
	returnValue = FeSet::construct(this->edition()->notSharedWith(other->edition()));
	return returnValue;
}


RPTR(Stepper) OF1(FeRangeElement) FeSet::stepper (){
	/* A stepper over the elements in the set */
	
	WPTR(Stepper) OF1(FeRangeElement) 	returnValue;
	returnValue = this->edition()->stepper();
	return returnValue;
}


RPTR(FeRangeElement) FeSet::theOne (){
	/* If there is exactly one element, then return it */
	
	WPTR(FeRangeElement) 	returnValue;
	returnValue = this->edition()->theOne();
	return returnValue;
}


RPTR(FeSet) FeSet::unionWith (APTR(FeSet) other){
	/* Return those elements which are in either set */
	
	SPTR(FeEdition) added;
	SPTR(FeEdition) result;
	SPTR(Stepper) stepper;
	SPTR(PrimArray) more;
	
	/* Need to assign new IDs to avoid collisions */
	added = other->edition()->notSharedWith(this->edition());
	if (added->isEmpty()) {
		return this;
	}
	result = this->edition();
	stepper = added->stepper();
	while (stepper->hasValue()) {
		more = stepper->stepMany();
		result = result->combine(FeEdition::fromArray(more, CAST(IDSpace,this->edition()->coordinateSpace())->newIDs(more->count())));
	}
	WPTR(FeSet) 	returnValue;
	returnValue = FeSet::construct(result);
	return returnValue;
}


RPTR(FeSet) FeSet::with (APTR(FeRangeElement) value){
	/* Add a RangeElement to the set */
	
	if (this->includes(value)) {
		return this;
	} else {
		WPTR(FeSet) 	returnValue;
		returnValue = FeSet::construct(this->edition()->with(this->iDSpace()->newID(), value));
		return returnValue;
	}
}


RPTR(FeSet) FeSet::without (APTR(FeRangeElement) value){
	/* Remove a RangeElement from the set */
	
	WPTR(FeSet) 	returnValue;
	returnValue = FeSet::construct(this->edition()->notSharedWith(FeEdition::fromOne(IntegerPos::make (IntegerVar0), value)));
	return returnValue;
}
/* protected: create */


FeSet::FeSet (APTR(FeEdition) edition, APTR(FeWrapperSpec) spec) 
	: FeWrapper(edition, spec) {
	
}
/* printing */


void FeSet::printOn (ostream& oo){
	IntegerVar count;
	
	oo << this->getCategory()->name() << "(";
	count = IntegerVarZero;
	BEGIN_FOR_EACH(FeRangeElement,object,(this->stepper())) {
		if (count > IntegerVarZero) {
			oo << ", ";
			if (count > 5) {
				oo << "...)";
				return;
				
			}
		}
		oo << object;
	} END_FOR_EACH;
	oo << ")";
}



/* ************************************************************************ *
 * 
 *                    Class   FeText 
 *
 * ************************************************************************ */



/* Initializers for FeText */

GPTR(FeWrapperSpec) FeText::TheTextSpec = NULL;



BEGIN_INIT_TIME(FeText,initTimeNonInherited) {
	DIRECTWRAPPER("Text","Wrapper",FeText);
} END_INIT_TIME(FeText,initTimeNonInherited);



/* Initializers for FeText */






/* private: wrapping */


BooleanVar FeText::check (APTR(FeEdition) edition){
	{	BooleanVar crutch_Flag;
		/* IntegerSpace::make ()->isEqual(edition->coordinateSpace()) && CAST(IntegerRegion,edition->domain())->isCompacted() */
		
		crutch_Flag = IntegerSpace::make ()->isEqual(edition->coordinateSpace());
		if(crutch_Flag) {
			crutch_Flag = CAST(IntegerRegion,edition->domain())->isCompacted();
		}
		return crutch_Flag;
	}
}


RPTR(FeText) FeText::construct (APTR(FeEdition) edition){
	/* Called from internal code to create and endorse new 
	Editions. Does not check the contents; assumes that it will 
	only be called by trusted code. */
	
	FeText::spec()->endorse(edition);
	return CAST(FeText,FeText::makeWrapper(edition));
}


RPTR(FeWrapper) FeText::makeWrapper (APTR(FeEdition) edition){
	RETURN_CONSTRUCT(FeText,(edition, FeText::spec()));
}


void FeText::setSpec (APTR(FeWrapperSpec) wrap){
	FeText::TheTextSpec = wrap;
}
/* pseudo constructors */


RPTR(FeText) FeText::make (APTR(PrimArray) data/* = NULL*/){
	if (data == NULL) {
		WPTR(FeText) 	returnValue;
		returnValue = FeText::construct(FeEdition::empty(IntegerSpace::make ()));
		return returnValue;
	} else {
		WPTR(FeText) 	returnValue;
		returnValue = FeText::construct(FeEdition::fromArray(data));
		return returnValue;
	}
}


RPTR(FeWrapperSpec) FeText::spec (){
	WPTR(FeWrapperSpec) 	returnValue;
	returnValue = FeText::TheTextSpec;
	return returnValue;
}
/* Handles a integer-indexed, contiguous, zero-based Edition of 
RangeElements */


/* text manipulation */


RPTR(FeEdition) FeText::contents (){
	/* The Edition of the actual contents, without any style 
	information. You should use this instead of edition() when 
	you want to get the Edition for comparisons, queries, etc. 
	Future styled text implementations will not store the 
	contents as directly as we do now. */
	
	WPTR(FeEdition) 	returnValue;
	returnValue = this->edition();
	return returnValue;
}


IntegerVar FeText::count (){
	/* The number of elements in the string */
	
	return this->edition()->count();
}


RPTR(FeText) FeText::extract (APTR(IntegerRegion) region){
	/* All the text lying within the region, with the gaps 
	compressed out. */
	
	WPTR(FeText) 	returnValue;
	returnValue = FeText::construct(this->edition()->transformedBy(CAST(IntegerRegion,region->intersect(this->edition()->domain()))->compactor()));
	return returnValue;
}


RPTR(FeText) FeText::insert (IntegerVar position, APTR(FeText) text){
	/* Insert new information into the Edition at the given 
	point, pushing everything after it forward. */
	
	this->validate(position);
	WPTR(FeText) 	returnValue;
	returnValue = FeText::construct(text->edition()->transformedBy(IntegerMapping::make (position))->combine(this->edition()->transformedBy(IntegerMapping::make ()->restrict(IntegerRegion::before(position))->combine(IntegerMapping::make (text->count())->restrict(IntegerRegion::after(position))))));
	return returnValue;
}


RPTR(FeText) FeText::move (IntegerVar pos, APTR(IntegerRegion) region){
	/* Insert a virtual copy of the region of text before the 
	given position, and remove it from its current location. If 
	the position is one past the last character, then it will be 
	inserted after the end. If the region is discontiguous, then 
	the contiguous pieces are concatenated together, in sequence, 
	and inserted. */
	
	SPTR(IntegerRegion) moved;
	SPTR(IntegerRegion) left;
	
	this->validate(pos);
	moved = CAST(IntegerRegion,this->edition()->domain()->intersect(region));
	left = CAST(IntegerRegion,this->edition()->domain()->minus(region));
	WPTR(FeText) 	returnValue;
	returnValue = FeText::construct(this->edition()->transformedBy(CAST(IntegerRegion,left->intersect(IntegerRegion::before(pos)))->compactor()->combine(moved->compactor()->transformedBy(IntegerMapping::make (pos)))->combine(CAST(IntegerRegion,left->intersect(IntegerRegion::after(pos)))->compactor()->transformedBy(IntegerMapping::make (moved->unionWith(IntegerRegion::make (IntegerVar0, pos))->count())))));
	return returnValue;
}


RPTR(FeText) FeText::replace (APTR(IntegerRegion) dest, APTR(FeText) other){
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
	
	IntegerVar to;
	
	if (IntegerRegion::before(IntegerVar0)->intersects(dest)) {
		to = IntegerVar0;
	} else {
		if (dest->intersects(this->edition()->domain())) {
			to = CAST(IntegerRegion,dest->intersect(this->edition()->domain()))->start();
		} else {
			if (IntegerRegion::after(this->count())->intersects(dest)) {
				to = this->count();
			} else {
				BLAST(AmbiguousReplacement);
			}
		}
	}
	/* Thing to do !!!! */
	
	/* Do this all in one step */
	WPTR(FeText) 	returnValue;
	returnValue = this->extract(CAST(IntegerRegion,dest->complement()))->insert(to, other);
	return returnValue;
}
/* private: */


void FeText::validate (IntegerVar pos){
	/* Check that information can be inserted at the position. 
	Blast if not. */
	
	{	BooleanVar crutch_Flag;
		/* IntegerVar0 <= pos && pos <= this->count() */
		
		crutch_Flag = IntegerVar0 <= pos;
		if(crutch_Flag) {
			crutch_Flag = pos <= this->count();
		}
		if (!crutch_Flag) {
			BLAST(InvalidTextPosition);
		}
	}
}
/* protected: create */


FeText::FeText (APTR(FeEdition) edition, APTR(FeWrapperSpec) spec) 
	: FeWrapper(edition, spec) {
	
}
/* printing */


void FeText::printOn (ostream& oo){
	oo << this->getCategory()->name() << "(";
	/* (self edition copy: (IntegerRegion before: 100)) retrieve 
		forEach: [ :bundle {FeBundle} |
				bundle cast: FeArrayBundle into: [ :array |
					array array cast: UInt8Array into: [ :chars |
						oo << chars]
					others:
						[UInt32Zero almostTo: array array count do: [ :i {UInt32} |
							oo << (array get: i)]]]
				cast: FeElementBundle into: [ :element |
					]
				cast: FePlaceHolderBundle into: [ :places |
					]].
			(self edition isFinite not or: [self edition count > 
		100]) ifTrue:
				[oo << '...']. */
	oo << this->edition();
	/* for now */
	oo << ")";
}



/* ************************************************************************ *
 * 
 *                    Class FeWrapperSpec 
 *
 * ************************************************************************ */



/* Initializers for FeWrapperSpec */

GPTR(MuTable) OF2(Tumbler,FeWrapperDef) FeWrapperSpec::TheWrapperDefs = NULL;
GPTR(MuTable) OF2(Tumbler,FeWrapperSpec) FeWrapperSpec::TheWrapperSpecs = NULL;
GPTR(MuTable) OF2(Tumbler,CrossRegion) FeWrapperSpec::TheWrapperEndorsements = NULL;
GPTR(MuTable) OF2(Tuple,FeWrapperSpec) FeWrapperSpec::TheWrappersFromEndorsements = NULL;



BEGIN_INIT_TIME(FeWrapperSpec,initTimeNonInherited) {
	REQUIRES (SequenceSpace);
	REQUIRES (MuTable);
	FeWrapperSpec::TheWrapperDefs = MuTable::make (SequenceSpace::make ());
} END_INIT_TIME(FeWrapperSpec,initTimeNonInherited);


/* exceptions: exceptions */



/* Initializers for FeWrapperSpec */






/* registering wrappers */


void FeWrapperSpec::registerAbstract (
		char * wrapperName, 
		char OR(NULL) * superName, 
		FeWrapperSpecHolder OR(NULL) holder)
{
	SPTR(Sequence) wrapper;
	SPTR(Sequence) superWrapper;
	
	wrapper = Sequence::string(wrapperName);
	if (superName == NULL) {
		superWrapper = NULL;
	} else {
		superWrapper = Sequence::string(superName);
	}
	FeWrapperSpec::TheWrapperDefs->introduce(wrapper, 
			FeWrapperDef::abstract(wrapper, superWrapper, holder));
}


void FeWrapperSpec::registerDirect (
		char * wrapperName, 
		char OR(NULL) * superName, 
		FeDirectWrapperMaker maker, 
		FeDirectWrapperChecker checker, 
		FeWrapperSpecHolder holder)
{
	SPTR(Sequence) wrapper;
	SPTR(Sequence) superWrapper;
	
	wrapper = Sequence::string(wrapperName);
	if (superName == NULL) {
		superWrapper = NULL;
	} else {
		superWrapper = Sequence::string(superName);
	}
	FeWrapperSpec::TheWrapperDefs->introduce(wrapper, 
			FeWrapperDef::makeDirect(wrapper, superWrapper, holder, maker, checker));
}


void FeWrapperSpec::registerIndirect (
		char * wrapperName, 
		char OR(NULL) * superName, 
		char OR(NULL) * innerName, 
		FeIndirectWrapperMaker maker, 
		FeIndirectWrapperChecker checker, 
		FeWrapperSpecHolder holder)
{
	SPTR(Sequence) wrapper;
	SPTR(Sequence) superWrapper;
	SPTR(Sequence) innerWrapper;
	
	wrapper = Sequence::string(wrapperName);
	if (superName == NULL) {
		superWrapper = NULL;
	} else {
		superWrapper = Sequence::string(superName);
	}
	if (innerName == NULL) {
		innerWrapper = NULL;
	} else {
		innerWrapper = Sequence::string(innerName);
	}
	FeWrapperSpec::TheWrapperDefs->introduce(wrapper, 
			FeWrapperDef::makeIndirect(wrapper, superWrapper, holder, innerWrapper, maker, checker));
}
/* private: */


void FeWrapperSpec::mustSetup (){
	
	if (FeWrapperSpec::TheWrapperEndorsements == NULL) {
		FeWrapperSpec::setWrapperEndorsements(CurrentGrandMap.fluidGet()->wrapperEndorsements());
	}
}
/* accessing */


RPTR(FeWrapperSpec) OR(NULL) FeWrapperSpec::fetch (APTR(Sequence) identifier){
	/* Get the local Wrapper spec with the given identifier, or 
	NULL if there is none */
	
	FeWrapperSpec::mustSetup();
	return CAST(FeWrapperSpec,FeWrapperSpec::TheWrapperSpecs->fetch(identifier));
}


RPTR(FeWrapperSpec) FeWrapperSpec::get (APTR(Sequence) identifier){
	/* Get the local Wrapper spec with the given identifier, or 
	blast if there is none */
	
	SPTR(FeWrapperSpec) result;
	
	result = FeWrapperSpec::fetch(identifier);
	if (result == NULL) {
		BLAST(NotInTable);
	}
	WPTR(FeWrapperSpec) 	returnValue;
	returnValue = result;
	return returnValue;
}


RPTR(CrossRegion) FeWrapperSpec::getEndorsements (APTR(Sequence) identifier){
	/* Get the endorsements for the named wrapper space */
	
	FeWrapperSpec::mustSetup();
	return CAST(CrossRegion,FeWrapperSpec::TheWrapperEndorsements->get(identifier));
}


RPTR(FeWrapperSpec) FeWrapperSpec::getFromEndorsement (APTR(Tuple) endorsement){
	/* Get the wrapper spec corresponding to the given endorsement */
	
	FeWrapperSpec::mustSetup();
	return CAST(FeWrapperSpec,FeWrapperSpec::TheWrappersFromEndorsements->get(endorsement));
}


RPTR(XnRegion) OF1(Sequence) FeWrapperSpec::knownWrappers (){
	/* The names of all of the known wrappers */
	
	WPTR(XnRegion) OF1(Sequence) 	returnValue;
	returnValue = FeWrapperSpec::TheWrapperDefs->domain();
	return returnValue;
}


void FeWrapperSpec::setupWrapperSpecs (){
	/* Get the local Wrapper spec with the given identifier, or 
	NULL if there is none */
	
	FeWrapperSpec::TheWrapperSpecs = MuTable::make (SequenceSpace::make ());
	BEGIN_FOR_EACH(FeWrapperDef,def,(FeWrapperSpec::TheWrapperDefs->stepper())) {
		FeWrapperSpec::TheWrapperSpecs->introduce(def->name(), def->makeSpec());
	} END_FOR_EACH;
	BEGIN_FOR_EACH(FeWrapperSpec,spec,(FeWrapperSpec::TheWrapperSpecs->stepper())) {
		spec->setup();
	} END_FOR_EACH;
}


void FeWrapperSpec::setWrapperEndorsements (APTR(ScruTable) OF2(Sequence,CrossRegion) endorsements){
	/* A table mapping from wrapper names to endorsements */
	
	FeWrapperSpec::TheWrapperEndorsements = endorsements->asMuTable();
	FeWrapperSpec::setupWrapperSpecs();
	FeWrapperSpec::TheWrappersFromEndorsements = MuTable::make (CurrentGrandMap.fluidGet()->endorsementSpace());
	BEGIN_FOR_POSITIONS(Sequence,seq,CrossRegion,endorses,(endorsements->stepper())) {
		if (!endorses->isFinite()) {
			BLAST(FatalError);
		}
		/* Ravi -- Thing to do !!!! */
		
		/* implement stepper so that endorsements are allowed 
			to be regions */
			/* endorses stepper forEach: [ :endorse {Tuple} |
						TheWrappersFromEndorsements at: endorse
							introduce: (self get: seq)] */
		FeWrapperSpec::TheWrappersFromEndorsements->introduce(endorses->theOne(), FeWrapperSpec::get(seq));
	} END_FOR_POSITIONS;
}
/* Handles wrapping, certification, and filtering for a wrapper type 
and its subtypes (if there are any) */


/* accessing */


RPTR(Filter) FeWrapperSpec::filter (){
	/* A filter which selects for Editions which have been 
	endorsed as belonging to this type. */
	
	if (myFilter == NULL) {
		myFilter = CAST(Filter,CurrentGrandMap.fluidGet()->endorsementFilterSpace()->emptyRegion());
	}
	return (Filter*) myFilter;
}


BooleanVar FeWrapperSpec::isCertified (APTR(FeEdition) edition){
	/* Whether an Edition is already endorsed as being of this 
	type. Equivalent to
			this->filter ()->match (edition->endorsements ()) */
	
	return this->filter()->match(edition->endorsements());
}


RPTR(Sequence) FeWrapperSpec::name (){
	/* The name for this type */
	
	WPTR(Sequence) 	returnValue;
	returnValue = myDef->name();
	return returnValue;
}


RPTR(FeWrapper) FeWrapperSpec::wrap (APTR(FeEdition) edition){
	/* The Edition wrapped with my type of Wrapper. If it does 
	not have endorsements, will attempt to certify. Blasts if 
	there is more than one valid wrapping. */
	
	SPTR(FeWrapper) result;
	
	result = this->fetchWrap(edition);
	if (result == NULL) {
		BLAST(CannotWrap);
	}
	WPTR(FeWrapper) 	returnValue;
	returnValue = result;
	return returnValue;
}
/* vulnerable */


BooleanVar FeWrapperSpec::isSubSpecOf (APTR(FeWrapperSpec) other){
	/* Whether this is the same as or a kind of the other spec */
	
	{	BooleanVar crutch_Flag;
		/* this == other || other->isKindOf(cat_FeAbstractWrapperSpec) && this->fetchSuperSpec() != NULL && this->fetchSuperSpec()->isSubSpecOf(other) */
		
		crutch_Flag = this == other;
		if(!crutch_Flag) {
			crutch_Flag = other->isKindOf(cat_FeAbstractWrapperSpec);
			if(crutch_Flag) {
				crutch_Flag = this->fetchSuperSpec() != NULL;
				if(crutch_Flag) {
					crutch_Flag = this->fetchSuperSpec()->isSubSpecOf(other);
				}
			}
		}
		return crutch_Flag;
	}
}
/* protected: */


void FeWrapperSpec::addToFilter (APTR(CrossRegion) endorsements){
	/* Add some more endorsements to filter for */
	
	myFilter = CAST(Filter,this->filter()->unionWith(CurrentGrandMap.fluidGet()->endorsementFilterSpace()->anyFilter(endorsements)));
}


RPTR(FeWrapperDef) FeWrapperSpec::def (){
	return (FeWrapperDef*) myDef;
}


RPTR(FeAbstractWrapperSpec) OR(NULL) FeWrapperSpec::fetchSuperSpec (){
	/* The immediate supertype, or NULL if this is the generic 
	Wrapper type */
	
	return (FeAbstractWrapperSpec*) mySuperSpec;
}


void FeWrapperSpec::setup (){
	/* Do the required setup for this spec in the context of a 
	table of all known specs */
	
	{	BooleanVar crutch_Flag;
		/* mySuperSpec == NULL && myDef->fetchSuperDefName() != NULL */
		
		crutch_Flag = mySuperSpec == NULL;
		if(crutch_Flag) {
			crutch_Flag = myDef->fetchSuperDefName() != NULL;
		}
		if (crutch_Flag) {
			SPTR(CrossRegion) end;
			
			mySuperSpec = CAST(FeAbstractWrapperSpec,FeWrapperSpec::get(myDef->fetchSuperDefName()));
			myDef->setSpec(this);
			end = FeWrapperSpec::getEndorsements(this->name());
			myEndorsements = CAST(CrossRegion,this->endorsements()->unionWith(end));
			this->addToFilter(end);
		}
	}
}
/* create */


FeWrapperSpec::FeWrapperSpec (APTR(FeWrapperDef) def, TCSJ) {
	myDef = def;
	myEndorsements = NULL;
	myFilter = NULL;
	mySuperSpec = NULL;
}
/* for wrappers only */


RPTR(CrossRegion) FeWrapperSpec::endorsements (){
	if (myEndorsements == NULL) {
		myEndorsements = CAST(CrossRegion,CurrentGrandMap.fluidGet()->endorsementSpace()->emptyRegion());
	}
	return (CrossRegion*) myEndorsements;
}



/* ************************************************************************ *
 * 
 *                    Class FeAbstractWrapperSpec 
 *
 * ************************************************************************ */


/* pseudo constructors */


RPTR(FeAbstractWrapperSpec) FeAbstractWrapperSpec::make (APTR(FeAbstractWrapperDef) def){
	RETURN_CONSTRUCT(FeAbstractWrapperSpec,(def, tcsj));
}
/* accessing */


BooleanVar FeAbstractWrapperSpec::certify (APTR(FeEdition) edition){
	{
		Int32 LoopFinal = myConcreteSpecs->count();
		Int32 i = Int32Zero;
		for (;;) {
			if (i >= LoopFinal){
				break;
			}
			{
				if (CAST(FeConcreteWrapperSpec,myConcreteSpecs->fetch(i))->certify(edition)) {
					return TRUE;
				}
			}
			i += 1;
		}
	}
	return FALSE;
}


void FeAbstractWrapperSpec::setupConcreteSubSpec (APTR(FeConcreteWrapperSpec) spec){
	/* Add a new concrete spec to the list, keeping it 
	topologically sorted so that if A wraps B, A precedes B */
	
	Int32 pos;
	SPTR(PtrArray) OF1(FeConcreteWrapperSpec) copy;
	
	/* remember its endorsements */
	this->addToFilter(spec->endorsements());
	/* Look for the last wrapper in the array that can wrap this one */
	pos = myConcreteSpecs->count();
	for (;;) {	BooleanVar crutch_Flag;
		/* !(pos <= Int32Zero || CAST(FeConcreteWrapperSpec,myConcreteSpecs->fetch(pos - 1))->wraps(spec)) */
		
		crutch_Flag = pos <= Int32Zero;
		if(!crutch_Flag) {
			crutch_Flag = CAST(FeConcreteWrapperSpec,myConcreteSpecs->fetch(pos - 1))->wraps(spec);
		}
		crutch_Flag = !crutch_Flag;
		if (crutch_Flag) {
			pos -= 1;
		} else {
			break;
		}
	}
	/* Make a copy and insert it just after that one */
	copy = CAST(PtrArray,myConcreteSpecs->copyGrow(1));
	{
		Int32 LoopFinal = pos + 1;
		Int32 j = copy->count() - 1;
		for (;;) {
			if (j < LoopFinal){
				break;
			}
			{
				copy->store(j, copy->fetch(j - 1));
			}
			j -= 1;
		}
	}
	copy->store(pos, spec);
	myConcreteSpecs = copy;
	/* Recur upwards to add the spec to my parent */
	this->setup();
	if (this->fetchSuperSpec() != NULL) {
		this->fetchSuperSpec()->setupConcreteSubSpec(spec);
	}
}
/* create */


FeAbstractWrapperSpec::FeAbstractWrapperSpec (APTR(FeAbstractWrapperDef) def, TCSJ) 
	: FeWrapperSpec(def, tcsj) {
	myConcreteSpecs = PtrArray::empty();
}
/* for wrappers only */


void FeAbstractWrapperSpec::endorse (APTR(FeEdition) /* edition */){
	BLAST(MustBeConcreteWrapperSpec);
}
/* vulnerable */


RPTR(FeWrapper) OR(NULL) FeAbstractWrapperSpec::fetchWrap (APTR(FeEdition) edition){
	SPTR(FeConcreteWrapperSpec) sub;
	SPTR(FeWrapper) result;
	
	/* Ravi -- Thing to do !!!! */
	
	/* BLAST if there is an ambiguity; right now the only 
		possible one is between an empty Path and and an empty Text */
		/* If there are any endorsements that match mine, 
		pick a concrete type that isn't wrapped by anything else */
	sub = NULL;
	BEGIN_FOR_EACH(Tuple,end,(edition->endorsements()->intersect(this->endorsements())->stepper())) {
		SPTR(FeConcreteWrapperSpec) other;
		
		other = CAST(FeConcreteWrapperSpec,FeWrapperSpec::getFromEndorsement(end));
		{	BooleanVar crutch_Flag;
			/* sub == NULL || other->wraps(sub) */
			
			crutch_Flag = sub == NULL;
			if(!crutch_Flag) {
				crutch_Flag = other->wraps(sub);
			}
			if (crutch_Flag) {
				sub = other;
			}
		}
	} END_FOR_EACH;
	if (sub != NULL) {
		WPTR(FeWrapper) OR(NULL) 	returnValue;
		returnValue = sub->fetchWrap(edition);
		return returnValue;
	}
	/* There are no endorsements. Just walk through the 
		topological sort until you hit one which works */
	{
		Int32 LoopFinal = myConcreteSpecs->count();
		Int32 i = Int32Zero;
		for (;;) {
			if (i >= LoopFinal){
				break;
			}
			{
				BEGIN_CHOOSE(myConcreteSpecs->fetch(i)) {
					BEGIN_KIND(FeConcreteWrapperSpec,spec) {
						result = spec->fetchWrap(edition);
						if (result != NULL) {
							WPTR(FeWrapper) OR(NULL) 	returnValue;
							returnValue = result;
							return returnValue;
						}
					} END_KIND;
				} END_CHOOSE;
			}
			i += 1;
		}
	}
	return NULL;
}



/* ************************************************************************ *
 * 
 *                    Class FeConcreteWrapperSpec 
 *
 * ************************************************************************ */


/* protected: */


void FeConcreteWrapperSpec::setup (){
	this->FeWrapperSpec::setup();
	if (this->fetchSuperSpec() != NULL) {
		this->fetchSuperSpec()->setupConcreteSubSpec(this);
	}
}
/* accessing */
/* create */


FeConcreteWrapperSpec::FeConcreteWrapperSpec (APTR(FeWrapperDef) def, TCSJ) 
	: FeWrapperSpec(def, tcsj) {
	
}
/* for wrappers only */


void FeConcreteWrapperSpec::endorse (APTR(FeEdition) edition){
	/* Endorse an Edition as being of this type */
	
	
	edition->beEdition()->endorse(this->endorsements());
}
/* vulnerable */



/* ************************************************************************ *
 * 
 *                    Class   FeDirectWrapperSpec 
 *
 * ************************************************************************ */


/* pseudo constructors */


RPTR(FeDirectWrapperSpec) FeDirectWrapperSpec::make (APTR(FeDirectWrapperDef) def){
	RETURN_CONSTRUCT(FeDirectWrapperSpec,(def, tcsj));
}
/* accessing */


BooleanVar FeDirectWrapperSpec::wraps (APTR(FeConcreteWrapperSpec) other){
	return this == other;
}
/* private: */


BooleanVar FeDirectWrapperSpec::certify (APTR(FeEdition) edition){
	/* Try to certify as this type. If successful, return TRUE 
	and endorse it; if not, return FALSE. */
	
	if (CAST(FeDirectWrapperDef,this->def())->check(edition)) {
		this->endorse(edition);
		return TRUE;
	} else {
		return FALSE;
	}
}
/* create */


FeDirectWrapperSpec::FeDirectWrapperSpec (APTR(FeDirectWrapperDef) def, TCSJ) 
	: FeConcreteWrapperSpec(def, tcsj) {
	
}
/* vulnerable */


RPTR(FeWrapper) FeDirectWrapperSpec::fetchWrap (APTR(FeEdition) edition){
	{	BooleanVar crutch_Flag;
		/* this->isCertified(edition) || this->certify(edition) */
		
		crutch_Flag = this->isCertified(edition);
		if(!crutch_Flag) {
			crutch_Flag = this->certify(edition);
		}
		if (crutch_Flag) {
			WPTR(FeWrapper) 	returnValue;
			returnValue = CAST(FeDirectWrapperDef,this->def())->makeWrapper(edition);
			return returnValue;
		} else {
			return NULL;
		}
	}
}



/* ************************************************************************ *
 * 
 *                    Class   FeIndirectWrapperSpec 
 *
 * ************************************************************************ */


/* pseudo constructors */


RPTR(FeIndirectWrapperSpec) FeIndirectWrapperSpec::make (APTR(FeIndirectWrapperDef) def){
	RETURN_CONSTRUCT(FeIndirectWrapperSpec,(def, tcsj));
}
/* accessing */


BooleanVar FeIndirectWrapperSpec::wraps (APTR(FeConcreteWrapperSpec) other){
	{	BooleanVar crutch_Flag;
		/* this == other || myInner->wraps(other) */
		
		crutch_Flag = this == other;
		if(!crutch_Flag) {
			crutch_Flag = myInner->wraps(other);
		}
		return crutch_Flag;
	}
}
/* private: */


BooleanVar FeIndirectWrapperSpec::certify (APTR(FeEdition) inner){
	/* Try to certify as this type. If successful, return TRUE 
	and endorse it; if not, return FALSE. */
	
	if (this->indirectDef()->check(inner)) {
		this->endorse(inner);
		return TRUE;
	} else {
		return FALSE;
	}
}


RPTR(FeIndirectWrapperDef) FeIndirectWrapperSpec::indirectDef (){
	return CAST(FeIndirectWrapperDef,this->def());
}
/* protected: */


void FeIndirectWrapperSpec::setup (){
	this->FeConcreteWrapperSpec::setup();
	myInner = CAST(FeConcreteWrapperSpec,FeWrapperSpec::get(this->indirectDef()->innerDefName()));
}
/* create */


FeIndirectWrapperSpec::FeIndirectWrapperSpec (APTR(FeIndirectWrapperDef) def, TCSJ) 
	: FeConcreteWrapperSpec(def, tcsj) {
	myInner = NULL;
}
/* vulnerable */


RPTR(FeWrapper) OR(NULL) FeIndirectWrapperSpec::fetchWrap (APTR(FeEdition) edition){
	SPTR(FeWrapper) inner;
	
	inner = myInner->wrap(edition);
	{	BooleanVar crutch_Flag;
		/* this->isCertified(edition) || this->certify(edition) */
		
		crutch_Flag = this->isCertified(edition);
		if(!crutch_Flag) {
			crutch_Flag = this->certify(edition);
		}
		if (crutch_Flag) {
			WPTR(FeWrapper) OR(NULL) 	returnValue;
			returnValue = this->indirectDef()->makeWrapper(edition, inner);
			return returnValue;
		}
	}
	return NULL;
}



/* ************************************************************************ *
 * 
 *                    Class FeWrapperDef 
 *
 * ************************************************************************ */


/* pseudo constructors */


RPTR(FeWrapperDef) FeWrapperDef::abstract (
		APTR(Sequence) wrapperName, 
		APTR(Sequence) OR(NULL) superName, 
		FeWrapperSpecHolder OR(NULL) holder)
{
	RETURN_CONSTRUCT(FeAbstractWrapperDef,(wrapperName, superName, holder));
}


RPTR(FeWrapperDef) FeWrapperDef::makeDirect (
		APTR(Sequence) wrapperName, 
		APTR(Sequence) OR(NULL) superName, 
		FeWrapperSpecHolder OR(NULL) holder, 
		FeDirectWrapperMaker maker, 
		FeDirectWrapperChecker checker)
{
	RETURN_CONSTRUCT(FeDirectWrapperDef,(wrapperName, superName, holder, maker, checker));
}


RPTR(FeWrapperDef) FeWrapperDef::makeIndirect (
		APTR(Sequence) wrapperName, 
		APTR(Sequence) OR(NULL) superName, 
		FeWrapperSpecHolder OR(NULL) holder, 
		APTR(Sequence) OR(NULL) innerName, 
		FeIndirectWrapperMaker maker, 
		FeIndirectWrapperChecker checker)
{
	RETURN_CONSTRUCT(FeIndirectWrapperDef,(wrapperName, superName, holder, innerName, maker, checker));
}
/* ?I: names
	?P: strings
	?P: PackOBits */


/* accessing */


RPTR(Sequence) OR(NULL) FeWrapperDef::fetchSuperDefName (){
	return (Sequence*) mySuperDefName;
}


RPTR(Sequence) FeWrapperDef::name (){
	return (Sequence*) myName;
}


void FeWrapperDef::setSpec (APTR(FeWrapperSpec) spec){
	/* Tell whoever cares about the spec for this type */
	
	if (mySpecHolder != NULL) {
		(*(mySpecHolder)) (spec);
	}
}
/* create */


FeWrapperDef::FeWrapperDef (
		APTR(Sequence) name, 
		APTR(Sequence) OR(NULL) superName, 
		FeWrapperSpecHolder OR(NULL) holder) 
{
	myName = name;
	mySuperDefName = superName;
	mySpecHolder = holder;
}



/* ************************************************************************ *
 * 
 *                    Class   FeAbstractWrapperDef 
 *
 * ************************************************************************ */


/* create */


FeAbstractWrapperDef::FeAbstractWrapperDef (
		APTR(Sequence) name, 
		APTR(Sequence) OR(NULL) superName, 
		FeWrapperSpecHolder OR(NULL) holder) 

	: FeWrapperDef(name
		, superName
		, holder) 
{
	
}
/* accessing */


RPTR(FeWrapperSpec) FeAbstractWrapperDef::makeSpec (){
	WPTR(FeWrapperSpec) 	returnValue;
	returnValue = FeAbstractWrapperSpec::make (this);
	return returnValue;
}



/* ************************************************************************ *
 * 
 *                    Class   FeDirectWrapperDef 
 *
 * ************************************************************************ */


/* accessing */


BooleanVar FeDirectWrapperDef::check (APTR(FeEdition) edition){
	return (*(myChecker)) (edition);
}


RPTR(FeWrapperSpec) FeDirectWrapperDef::makeSpec (){
	WPTR(FeWrapperSpec) 	returnValue;
	returnValue = FeDirectWrapperSpec::make (this);
	return returnValue;
}


RPTR(FeWrapper) FeDirectWrapperDef::makeWrapper (APTR(FeEdition) edition){
	WPTR(FeWrapper) 	returnValue;
	returnValue = (*(myMaker)) (edition);
	return returnValue;
}
/* create */


FeDirectWrapperDef::FeDirectWrapperDef (
		APTR(Sequence) name, 
		APTR(Sequence) OR(NULL) superName, 
		FeWrapperSpecHolder OR(NULL) holder, 
		FeDirectWrapperMaker maker, 
		FeDirectWrapperChecker checker) 

	: FeWrapperDef(name
		, superName
		, holder) 
{
	myMaker = maker;
	myChecker = checker;
}



/* ************************************************************************ *
 * 
 *                    Class   FeIndirectWrapperDef 
 *
 * ************************************************************************ */


/* accessing */


BooleanVar FeIndirectWrapperDef::check (APTR(FeEdition) inner){
	return (*(myChecker)) (inner);
}


RPTR(Sequence) FeIndirectWrapperDef::innerDefName (){
	return (Sequence*) myInner;
}


RPTR(FeWrapperSpec) FeIndirectWrapperDef::makeSpec (){
	WPTR(FeWrapperSpec) 	returnValue;
	returnValue = FeIndirectWrapperSpec::make (this);
	return returnValue;
}


RPTR(FeWrapper) FeIndirectWrapperDef::makeWrapper (APTR(FeEdition) edition, APTR(FeWrapper) inner){
	WPTR(FeWrapper) 	returnValue;
	returnValue = (*(myMaker)) (edition, inner);
	return returnValue;
}
/* create */


FeIndirectWrapperDef::FeIndirectWrapperDef (
		APTR(Sequence) name, 
		APTR(Sequence) OR(NULL) superName, 
		FeWrapperSpecHolder OR(NULL) holder, 
		FeIndirectWrapperMaker maker, 
		FeIndirectWrapperChecker checker) 

	: FeWrapperDef(name
		, superName
		, holder) 
{
	myMaker = maker;
	myChecker = checker;
}


FeIndirectWrapperDef::FeIndirectWrapperDef (
		APTR(Sequence) name, 
		APTR(Sequence) OR(NULL) superName, 
		FeWrapperSpecHolder OR(NULL) holder, 
		APTR(Sequence) OR(NULL) inner, 
		FeIndirectWrapperMaker maker, 
		FeIndirectWrapperChecker checker) 

	: FeWrapperDef(name
		, superName
		, holder) 
{
	myInner = inner;
	myMaker = maker;
	myChecker = checker;
}

#ifndef WRAPPERX_SXX
#include "wrapperx.sxx"
#endif /* WRAPPERX_SXX */


#ifndef WRAPPERP_SXX
#include "wrapperp.sxx"
#endif /* WRAPPERP_SXX */



#endif /* WRAPPERX_CXX */

