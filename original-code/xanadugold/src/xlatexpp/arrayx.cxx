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

#ifndef ARRAYX_CXX
#define ARRAYX_CXX


#ifndef CHOOSEX_HXX
#include "choosex.hxx"
#endif /* CHOOSEX_HXX */

#ifndef ARRAYX_HXX
#include "arrayx.hxx"
#endif /* ARRAYX_HXX */

#ifndef ARRAYX_IXX
#include "arrayx.ixx"
#endif /* ARRAYX_IXX */

#ifndef ARRAYP_HXX
#include "arrayp.hxx"
#endif /* ARRAYP_HXX */

#ifndef ARRAYP_IXX
#include "arrayp.ixx"
#endif /* ARRAYP_IXX */


#ifndef INTEGERX_HXX
#include "integerx.hxx"
#endif /* INTEGERX_HXX */

#ifndef INTTABR_HXX
#include "inttabr.hxx"
#endif /* INTTABR_HXX */




/* ************************************************************************ *
 * 
 *                    Class MuArray 
 *
 * ************************************************************************ */


/* creation */


RPTR(MuArray) MuArray::array (APTR(Heaper) obj0){
	/* A new XnArray initialized with a single element, 'obj0', 
	stored at index 0. */
	
	SPTR(MuArray) table;
	
	table = MuArray::make (1);
	table->atIntStore(IntegerVar0, obj0);
	WPTR(MuArray) 	returnValue;
	returnValue = table;
	return returnValue;
}


RPTR(MuArray) MuArray::array (APTR(Heaper) obj0, APTR(Heaper) obj1){
	/* A new XnArray initialized with a two elements stored at 
	indicies 0 and 1. */
	
	SPTR(MuArray) table;
	
	table = MuArray::make (2);
	table->atIntStore(IntegerVar0, obj0);
	table->atIntStore(1, obj1);
	WPTR(MuArray) 	returnValue;
	returnValue = table;
	return returnValue;
}


RPTR(MuArray) MuArray::array (
		APTR(Heaper) obj0, 
		APTR(Heaper) obj1, 
		APTR(Heaper) obj2)
{
	/* A new XuArray initialized with a three elements stored at 
	indicies 0, 1, and 2. */
	
	SPTR(MuArray) table;
	
	table = MuArray::make (3);
	table->atIntStore(IntegerVar0, obj0);
	table->atIntStore(1, obj1);
	table->atIntStore(2, obj2);
	WPTR(MuArray) 	returnValue;
	returnValue = table;
	return returnValue;
}


RPTR(MuArray) MuArray::array (
		APTR(Heaper) obj0, 
		APTR(Heaper) obj1, 
		APTR(Heaper) obj2, 
		APTR(Heaper) obj3)
{
	/* A new XuArray initialized with a four elements stored at 
	indicies 0 through 3. */
	
	SPTR(MuArray) table;
	
	table = MuArray::make (4);
	table->atIntStore(IntegerVar0, obj0);
	table->atIntStore(1, obj1);
	table->atIntStore(2, obj2);
	table->atIntStore(3, obj3);
	WPTR(MuArray) 	returnValue;
	returnValue = table;
	return returnValue;
}


RPTR(TableAccumulator) MuArray::arrayAccumulator (){
	/* Returns an Accumulator which will produce an XuArray of 
	the elements 
		accumulated into it in order of accumulation. See XuArray. 
	Equivalent to 
		'tableAccumulator()'. Eventually either he or I should be 
	declared obsolete. */
	
	WPTR(TableAccumulator) 	returnValue;
	returnValue = ArrayAccumulator::make (MuArray::array());
	return returnValue;
}


RPTR(TableAccumulator) MuArray::arrayAccumulator (APTR(MuArray) onArray){
	/* An accumulator which will accumulate by appending elements 
	onto the end of 
		'onArray'. It is an error for anyone else to modify 
	'onArray' between creating 
		this accumulator and accumulating into it. acc->value() will 
	return 'onArray' 
		itself. */
	
	WPTR(TableAccumulator) 	returnValue;
	returnValue = ArrayAccumulator::make (onArray);
	return returnValue;
}


RPTR(MuArray) MuArray::make (IntegerVar someSize){
	/* 'someSize' is a hint about how big we should expect the 
	array to need to grow. */
	
	RETURN_CONSTRUCT(ActualArray,(someSize, tcsj));
}


RPTR(ScruTable) MuArray::offsetScruArray (APTR(MuArray) array, APTR(Dsp) dsp){
	/* The resulting ScruTable is a view onto 'array'. It is a 
	view in which each key 
		is offset by 'dsp' from where it is in 'array'. By saying it 
	is a view, we mean 
		that as 'array' is modified, the view tracks the changes. */
	
	WPTR(ScruTable) 	returnValue;
	returnValue = OffsetScruArray::make (array, dsp);
	return returnValue;
}
/* The class XuArray is intended to model zero-based arrays with 
integer keys (indices).
	
	This makes them like the array primitive in C and C++.  There is an 
additional constraint, which is they are to have simple domains.  
Therefore they should not be constructed with non-contiguous 
sections.  This is not currently enforced.  Given that it is 
enforced, an XuArray with count N would have as its domain exactly 
the integers from 0 to N-1.
	
	There is some controversy over whether XuArray should be a type and 
enforce this contraint (by BLASTing if an attempt is made to violate 
the constraint), or whether XuArray is just a specialized 
implementation for when an IntegerTable happens to meet this 
constraint; in which case it should "become" a more general 
implementation when an attempt is made to violate the constraint (see 
"Type Safe Become").  In the latter case, XuArray will probably be 
made a private class as well.  Please give us your opinion.
	
	XuArray provides no additional protocol. */


/* accessing */


RPTR(CoordinateSpace) MuArray::coordinateSpace (){
	WPTR(CoordinateSpace) 	returnValue;
	returnValue = IntegerSpace::make ();
	return returnValue;
}


RPTR(ScruTable) MuArray::offsetSubTableBetween (
		IntegerVar startIndex, 
		IntegerVar stopIndex, 
		IntegerVar /* firstIndex */)
{
	/* Return a table which contains the elements from start to 
	stop, starting at firstIndex.
		Zero-based subclasses will blast if firstIndex is non-zero */
	
	WPTR(ScruTable) 	returnValue;
	returnValue = this->subTableBetween(startIndex, stopIndex);
	return returnValue;
}


RPTR(ScruTable) MuArray::transformedBy (APTR(Dsp) dsp){
	if (dsp->inverse()->isEqual(dsp)) {
		return this;
	} else {
		WPTR(ScruTable) 	returnValue;
		returnValue = MuArray::offsetScruArray(this, dsp);
		return returnValue;
	}
}
/* creation */
/* testing */


BooleanVar MuArray::includesIntKey (IntegerVar aKey){
	{	BooleanVar crutch_Flag;
		/* aKey >= IntegerVar0 && aKey < this->count() */
		
		crutch_Flag = aKey >= IntegerVar0;
		if(crutch_Flag) {
			crutch_Flag = aKey < this->count();
		}
		return crutch_Flag;
	}
}


BooleanVar MuArray::isEmpty (){
	return this->count() == IntegerVar0;
}
/* runs */
/* enumerating */


RPTR(Heaper) MuArray::theOne (){
	if (this->count() != 1) {
		BLAST(NotOneElement);
	}
	WPTR(Heaper) 	returnValue;
	returnValue = this->intFetch(IntegerVar0);
	return returnValue;
}
/* bulk operations */


void MuArray::wipeAll (APTR(XnRegion) region){
	/* I 'wipe' from myself all associations whose key 
		is in 'region'. See MuTable::wipe */
	
	if (!region->coordinateSpace()->isEqual(this->coordinateSpace())) {
		BLAST(WrongCoordSpace);
	}
	if (this->isEmpty()) {
		return;
		
	}
	if (!region->isSimple()) {
		BLAST(NotSimple);
	}
	BEGIN_FOR_EACH(IntegerPos,p,(region->intersect(this->domain())->stepper(IntegerSpace::make ()->getDescending()))) {
		this->intWipe(p->asIntegerVar());
	} END_FOR_EACH;
}
/* overload junk */


RPTR(Heaper) MuArray::store (APTR(Position) key, APTR(Heaper) value){
	WPTR(Heaper) 	returnValue;
	returnValue = this->atIntStore(CAST(IntegerPos,key)->asIntegerVar(), value);
	return returnValue;
}


RPTR(Heaper) MuArray::fetch (APTR(Position) key){
	WPTR(Heaper) 	returnValue;
	returnValue = this->intFetch(CAST(IntegerPos,key)->asIntegerVar());
	return returnValue;
}


BooleanVar MuArray::includesKey (APTR(Position) aKey){
	return this->includesIntKey(CAST(IntegerPos,aKey)->asIntegerVar());
}


RPTR(XnRegion) MuArray::runAt (APTR(Position) key){
	WPTR(XnRegion) 	returnValue;
	returnValue = this->runAtInt(CAST(IntegerPos,key)->asIntegerVar());
	return returnValue;
}


BooleanVar MuArray::wipe (APTR(Position) key){
	return this->intWipe(CAST(IntegerPos,key)->asIntegerVar());
}

	/* automatic 0-argument constructor */
MuArray::MuArray() {}



/* ************************************************************************ *
 * 
 *                    Class ActualArray 
 *
 * ************************************************************************ */


/* testing */


UInt32 ActualArray::fastHash (){
	return tally + cat_ActualArray->hashForEqual();
}


BooleanVar ActualArray::isEmpty (){
	return tally == UInt32Zero;
}
/* accessing */


RPTR(Heaper) ActualArray::atIntStore (IntegerVar index, APTR(Heaper) value){
	/* store the new value at the specified position.  Note that 
	this is an insertion iff
		the index is the same as the tally (that is, we're adding at 
	the first empty position
		at the end of the array). */
	
	UInt32 reali;
	SPTR(Heaper) old;
	
	if (value == NULL) {
		BLAST(NullInsertion);
	}
	{	BooleanVar crutch_Flag;
		/* index < IntegerVar0 || index > tally */
		
		crutch_Flag = index < IntegerVar0;
		if(!crutch_Flag) {
			crutch_Flag = index > tally;
		}
		if (crutch_Flag) {
			BLAST(NotInDomain);
		}
	}
	reali = index.asLong();
	if (reali == tally) {
		if (reali >= elements->count()) {
			this->enlarge();
		}
		tally += 1;
	}
	old = elements->fetch(reali);
	elements->store(reali, value);
	WPTR(Heaper) 	returnValue;
	returnValue = old;
	return returnValue;
}


RPTR(CoordinateSpace) ActualArray::coordinateSpace (){
	WPTR(CoordinateSpace) 	returnValue;
	returnValue = IntegerSpace::make ();
	return returnValue;
}


IntegerVar ActualArray::count (){
	return tally;
}


RPTR(XnRegion) ActualArray::domain (){
	WPTR(XnRegion) 	returnValue;
	returnValue = IntegerRegion::make (IntegerVar0, tally);
	return returnValue;
}


IntegerVar ActualArray::highestIndex (){
	return tally - 1;
}


RPTR(Heaper) ActualArray::intFetch (IntegerVar index){
	register UInt32 idx;
	
	{	BooleanVar crutch_Flag;
		/* (idx = index.asLong()) >= tally || index < IntegerVar0 */
		
		crutch_Flag = (idx = index.asLong()) >= tally;
		if(!crutch_Flag) {
			crutch_Flag = index < IntegerVar0;
		}
		if (crutch_Flag) {
			return NULL;
		} else {
			WPTR(Heaper) 	returnValue;
			returnValue = elements->fetch(idx);
			return returnValue;
		}
	}
}


BooleanVar ActualArray::intWipe (IntegerVar index){
	/* Remove if the index is the last thing in the table. 
		 Blast if the index is some other element of the table.  
		 *Ignore* the request if it is any element not in the table. */
	
	register Int32 reali;
	
	reali = index.asLong();
	if (reali == tally - 1) {
		elements->store(reali, NULL);
		tally -= 1;
		return TRUE;
	}
	/* Now the error that results from a specialized implementation. */
	{	BooleanVar crutch_Flag;
		/* reali >= Int32Zero && reali < tally */
		
		crutch_Flag = reali >= Int32Zero;
		if(crutch_Flag) {
			crutch_Flag = reali < tally;
		}
		if (crutch_Flag) {
			BLAST(IncompleteAbstraction);
		}
	}
	return FALSE;
}


IntegerVar ActualArray::lowestIndex (){
	return IntegerVar0;
}


RPTR(ScruTable) ActualArray::offsetSubTableBetween (
		IntegerVar startIndex, 
		IntegerVar stopIndex, 
		IntegerVar firstIndex)
{
	WPTR(ScruTable) 	returnValue;
	returnValue = this->MuArray::offsetSubTableBetween(startIndex, stopIndex, firstIndex);
	return returnValue;
}


RPTR(ScruTable) ActualArray::subTable (APTR(XnRegion) reg){
	WPTR(ScruTable) 	returnValue;
	returnValue = this->subTableBetween(CAST(IntegerRegion,reg)->start(), CAST(IntegerRegion,reg)->stop());
	return returnValue;
}


RPTR(ScruTable) ActualArray::subTableBetween (IntegerVar start, IntegerVar stop){
	IntegerVar begin;
	IntegerVar end;
	SPTR(MuArray) newArray;
	SPTR(XnRegion) reg;
	
	if (start < IntegerVar0) {
		begin = IntegerVar0;
	} else {
		begin = start;
	}
	if (stop > this->count()) {
		end = this->count();
	} else {
		end = stop;
	}
	newArray = MuArray::make (end - begin);
	reg = IntegerRegion::make (begin, end);
	BEGIN_FOR_EACH(IntegerPos,pos,(reg->stepper())) {
		newArray->atIntIntroduce(pos->asIntegerVar() - begin, this->intFetch(pos->asIntegerVar()));
	} END_FOR_EACH;
	if (begin > IntegerVar0) {
		WPTR(ScruTable) 	returnValue;
		returnValue = OffsetScruArray::make (newArray, IntegerMapping::make (begin));
		return returnValue;
	} else {
		WPTR(ScruTable) 	returnValue;
		returnValue = newArray;
		return returnValue;
	}
}
/* creation */


RPTR(ScruTable) ActualArray::copy (){
	RETURN_CONSTRUCT(ActualArray,(CAST(PtrArray,elements->copy()), tally));
}


RPTR(ScruTable) ActualArray::emptySize (IntegerVar /* size */){
	WPTR(ScruTable) 	returnValue;
	returnValue = MuArray::make (elements->count());
	return returnValue;
}
/* private: creation */


ActualArray::ActualArray () {
	/* The optional argument just hints at the number of elements
		 to eventually be added.  It makes no difference semantically. */
	
	elements = PtrArray::nulls(4);
	tally = UInt32Zero;
}


ActualArray::ActualArray (IntegerVar size, TCSJ) {
	/* The optional argument just hints at the number of elements
		 to eventually be added.  It makes no difference semantically. */
	
	UInt32 newSize;
	
	if (size > 4) {
		newSize = size.asLong();
	} else {
		newSize = 4;
	}
	elements = PtrArray::nulls(newSize);
	tally = UInt32Zero;
}


ActualArray::ActualArray (APTR(PtrArray) OF1(Heaper) newElems, UInt32 newTally) {
	elements = newElems;
	tally = newTally;
}


void ActualArray::destruct (){
	{elements->destroy();  elements = NULL /* don't want stale (S/CHK)PTRs */;}
	elements = NULL;
	this->MuArray::destruct();
}
/* runs */


RPTR(XnRegion) ActualArray::runAtInt (IntegerVar anIdx){
	IntegerVar idx;
	SPTR(Heaper) lastObj;
	BooleanVar notDone;
	
	idx = anIdx;
	{	BooleanVar crutch_Flag;
		/* idx < IntegerVar0 || idx >= tally */
		
		crutch_Flag = idx < IntegerVar0;
		if(!crutch_Flag) {
			crutch_Flag = idx >= tally;
		}
		if (crutch_Flag) {
			WPTR(XnRegion) 	returnValue;
			returnValue = IntegerRegion::make ();
			return returnValue;
		}
	}
	lastObj = this->intGet(idx);
	notDone = TRUE;
	for (;;) {	BooleanVar crutch_Flag;
		/* idx < tally && notDone */
		
		crutch_Flag = idx < tally;
		if(crutch_Flag) {
			crutch_Flag = notDone;
		}
		if (crutch_Flag) {
			if (this->intGet(idx)->isEqual(lastObj)) {
				idx += 1;
			} else {
				notDone = FALSE;
			}
		} else {
			break;
		}
	}
	WPTR(XnRegion) 	returnValue;
	returnValue = IntegerRegion::make (anIdx, idx);
	return returnValue;
}
/* printing */


void ActualArray::printOn (ostream& aStream){
	aStream << this->getCategory()->name();
	this->printOnWithSimpleSyntax(aStream, "[", ",", "]");
}
/* private: private */


RPTR(PtrArray) ActualArray::elementsArray (){
	/* return the elements array for rapid processing */
	
	return (PtrArray*) elements;
}


UInt32 ActualArray::endOffset (){
	/* return the size of the elements array for rapid processing */
	
	return tally - 1;
}


void ActualArray::enlarge (){
	/* Enlarge the receiver to contain more slots filled with nil. */
	
	SPTR(PtrArray) OF1(Heaper) newElements;
	WPTR(PtrArray) OF1(Heaper) oldElements;
	
	newElements = CAST(PtrArray,elements->copyGrow(elements->count()));
	/* Just for the hell of it, I make this robust for 
		asynchronous readers... */
	oldElements = elements;
	elements = newElements;
	{oldElements->destroy();  oldElements = NULL /* don't want stale (S/CHK)PTRs */;}
}


UInt32 ActualArray::maxElements (){
	/* return the size of the elements array for rapid processing */
	
	return elements->count();
}


UInt32 ActualArray::startOffset (){
	/* return the size of the elements array for rapid processing */
	
	return UInt32Zero;
}
/* enumerating */


RPTR(TableStepper) ActualArray::stepper (APTR(OrderSpec) order/* = NULL*/){
	if (order == NULL) {
		WPTR(TableStepper) 	returnValue;
		returnValue = AscendingArrayStepper::make (this, IntegerVar0, tally - 1);
		return returnValue;
	} else {
		if (order->followsInt(1, IntegerVar0)) {
			WPTR(TableStepper) 	returnValue;
			returnValue = AscendingArrayStepper::make (this);
			return returnValue;
		} else {
			WPTR(TableStepper) 	returnValue;
			returnValue = IntegerTableStepper::make (this, order);
			return returnValue;
		}
	}
}
/* overload junk */


RPTR(Heaper) ActualArray::store (APTR(Position) key, APTR(Heaper) value){
	WPTR(Heaper) 	returnValue;
	returnValue = this->atIntStore(CAST(IntegerPos,key)->asIntegerVar(), value);
	return returnValue;
}


RPTR(Heaper) ActualArray::fetch (APTR(Position) key){
	WPTR(Heaper) 	returnValue;
	returnValue = this->intFetch(CAST(IntegerPos,key)->asIntegerVar());
	return returnValue;
}


RPTR(XnRegion) ActualArray::runAt (APTR(Position) anIdx){
	WPTR(XnRegion) 	returnValue;
	returnValue = this->runAtInt(CAST(IntegerPos,anIdx)->asIntegerVar());
	return returnValue;
}


BooleanVar ActualArray::wipe (APTR(Position) key){
	return this->intWipe(CAST(IntegerPos,key)->asIntegerVar());
}



/* ************************************************************************ *
 * 
 *                    Class ArrayAccumulator 
 *
 * ************************************************************************ */


/* create */


RPTR(TableAccumulator) ArrayAccumulator::make (APTR(MuArray) onTable){
	RETURN_CONSTRUCT(ArrayAccumulator,(onTable, tcsj));
}
/* protected: create */


ArrayAccumulator::ArrayAccumulator (APTR(MuArray) onTable, TCSJ) {
	arrayInternal = onTable;
}
/* operations */


void ArrayAccumulator::step (APTR(Heaper) obj){
	if (arrayInternal->isEmpty()) {
		arrayInternal->atIntStore(IntegerVar0, obj);
	} else {
		arrayInternal->atIntIntroduce(CAST(IntegerRegion,arrayInternal->domain())->stop(), obj);
	}
}


RPTR(Heaper) ArrayAccumulator::value (){
	return (MuArray*) arrayInternal;
}
/* create */


RPTR(Accumulator) ArrayAccumulator::copy (){
	WPTR(Accumulator) 	returnValue;
	returnValue = ArrayAccumulator::make (CAST(MuArray,arrayInternal->copy()));
	return returnValue;
}



/* ************************************************************************ *
 * 
 *                    Class ArrayStepper 
 *
 * ************************************************************************ */


/* operations */


WPTR(Heaper) ArrayStepper::get (){
	WPTR(Heaper) 	returnValue;
	returnValue = arrayInternal->intGet(indexInternal);
	return returnValue;
}
/* special */


IntegerVar ArrayStepper::index (){
	return indexInternal;
}


RPTR(Position) ArrayStepper::position (){
	WPTR(Position) 	returnValue;
	returnValue = IntegerPos::make (indexInternal);
	return returnValue;
}
/* protected: accessing */


RPTR(ActualArray) ArrayStepper::array (){
	return (ActualArray*) arrayInternal;
}


void ArrayStepper::setIndex (Int32 i){
	indexInternal = i;
}
/* create */
/* protected: create */


ArrayStepper::ArrayStepper (APTR(MuArray) array, TCSJ) {
	arrayInternal = CAST(ActualArray,array->copy());
	indexInternal = Int32Zero;
}


ArrayStepper::ArrayStepper (APTR(MuArray) array, IntegerVar index) {
	arrayInternal = CAST(ActualArray,array->copy());
	indexInternal = index.asLong();
}



/* ************************************************************************ *
 * 
 *                    Class   AscendingArrayStepper 
 *
 * ************************************************************************ */


/* create */


RPTR(TableStepper) AscendingArrayStepper::make (APTR(ActualArray) array){
	RETURN_CONSTRUCT(AscendingArrayStepper,(array, tcsj));
}


RPTR(TableStepper) AscendingArrayStepper::make (APTR(ActualArray) array, IntegerVar index){
	RETURN_CONSTRUCT(AscendingArrayStepper,(array, index));
}


RPTR(TableStepper) AscendingArrayStepper::make (
		APTR(ActualArray) array, 
		IntegerVar start, 
		IntegerVar stop)
{
	RETURN_CONSTRUCT(AscendingArrayStepper,(array, start, stop));
}
/* create */


RPTR(Stepper) AscendingArrayStepper::copy (){
	WPTR(Stepper) 	returnValue;
	returnValue = AscendingArrayStepper::make (this->array(), this->index(), lastValueInternal);
	return returnValue;
}
/* protected: create */


AscendingArrayStepper::AscendingArrayStepper (APTR(ActualArray) array, TCSJ) 
	: ArrayStepper(array, tcsj) {
	lastValueInternal = array->endOffset();
}


AscendingArrayStepper::AscendingArrayStepper (APTR(ActualArray) array, IntegerVar index) 
	: ArrayStepper(array, index) {
	lastValueInternal = array->endOffset();
}


AscendingArrayStepper::AscendingArrayStepper (
		APTR(ActualArray) array, 
		IntegerVar start, 
		IntegerVar stop) 

	: ArrayStepper(array, start) {
	lastValueInternal = stop.asLong();
}
/* operations */


WPTR(Heaper) AscendingArrayStepper::fetch (){
	if (this->hasValue()) {
		WPTR(Heaper) 	returnValue;
		returnValue = this->array()->elementsArray()->fetch(this->index().asLong());
		return returnValue;
	} else {
		return NULL;
	}
}


BooleanVar AscendingArrayStepper::hasValue (){
	return this->index() <= lastValueInternal;
}


void AscendingArrayStepper::step (){
	this->setIndex(this->index().asLong() + 1);
}
/* printing */


void AscendingArrayStepper::printOn (ostream& oo){
	oo << this->getCategory()->name() << " on " << this->array()->subTableBetween(this->index(), lastValueInternal);
}



/* ************************************************************************ *
 * 
 *                    Class OffsetArrayStepper 
 *
 * ************************************************************************ */


/* create */


RPTR(TableStepper) OffsetArrayStepper::make (APTR(TableStepper) arrayStepper, APTR(Dsp) aDsp){
	RETURN_CONSTRUCT(OffsetArrayStepper,(arrayStepper, aDsp));
}
/* operations */


WPTR(Heaper) OffsetArrayStepper::fetch (){
	WPTR(Heaper) 	returnValue;
	returnValue = myArrayStepper->fetch();
	return returnValue;
}


WPTR(Heaper) OffsetArrayStepper::get (){
	WPTR(Heaper) 	returnValue;
	returnValue = myArrayStepper->get();
	return returnValue;
}


BooleanVar OffsetArrayStepper::hasValue (){
	return myArrayStepper->hasValue();
}


void OffsetArrayStepper::step (){
	myArrayStepper->step();
}
/* special */


IntegerVar OffsetArrayStepper::index (){
	return myDsp->ofInt(myArrayStepper->index());
}


RPTR(Position) OffsetArrayStepper::position (){
	WPTR(Position) 	returnValue;
	returnValue = myDsp->of(myArrayStepper->position());
	return returnValue;
}
/* protected: create */


OffsetArrayStepper::OffsetArrayStepper (APTR(TableStepper) onStepper, APTR(Dsp) aDsp) {
	myArrayStepper = onStepper;
	myDsp = aDsp;
}
/* create */


RPTR(Stepper) OffsetArrayStepper::copy (){
	WPTR(Stepper) 	returnValue;
	returnValue = OffsetArrayStepper::make (CAST(TableStepper,myArrayStepper->copy()), myDsp);
	return returnValue;
}



/* ************************************************************************ *
 * 
 *                    Class OffsetScruArray 
 *
 * ************************************************************************ */


/* create */


RPTR(ScruTable) OffsetScruArray::make (APTR(MuArray) array, APTR(Dsp) dsp){
	RETURN_CONSTRUCT(OffsetScruArray,(array, dsp));
}
/* accessing */


RPTR(CoordinateSpace) OffsetScruArray::coordinateSpace (){
	WPTR(CoordinateSpace) 	returnValue;
	returnValue = myArray->coordinateSpace();
	return returnValue;
}


IntegerVar OffsetScruArray::count (){
	return myArray->count();
}


RPTR(XnRegion) OffsetScruArray::domain (){
	WPTR(XnRegion) 	returnValue;
	returnValue = myDsp->ofAll(myArray->domain());
	return returnValue;
}


RPTR(Heaper) OffsetScruArray::fetch (APTR(Position) anIndex){
	WPTR(Heaper) 	returnValue;
	returnValue = myArray->intFetch(myDsp->inverseOfInt(CAST(IntegerPos,anIndex)->asIntegerVar()));
	return returnValue;
}


RPTR(Heaper) OffsetScruArray::intFetch (IntegerVar idx){
	WPTR(Heaper) 	returnValue;
	returnValue = myArray->intFetch(myDsp->inverseOfInt(idx));
	return returnValue;
}


RPTR(ScruTable) OffsetScruArray::subTable (APTR(XnRegion) encl){
	SPTR(IntegerRegion) lr;
	
	lr = CAST(IntegerRegion,encl);
	WPTR(ScruTable) 	returnValue;
	returnValue = myArray->subTableBetween(myDsp->inverseOfInt(lr->start()), myDsp->inverseOfInt(lr->stop()));
	return returnValue;
}


RPTR(ScruTable) OffsetScruArray::subTableBetween (IntegerVar startLoc, IntegerVar endLoc){
	WPTR(ScruTable) 	returnValue;
	returnValue = OffsetScruArray::make (CAST(MuArray,myArray->subTableBetween(myDsp->inverseOfInt(startLoc), myDsp->inverseOfInt(endLoc))), myDsp);
	return returnValue;
}


RPTR(ScruTable) OffsetScruArray::transformedBy (APTR(Dsp) dsp){
	if (myDsp->inverse()->isEqual(dsp)) {
		return (MuArray*) myArray;
	} else {
		WPTR(ScruTable) 	returnValue;
		returnValue = OffsetScruArray::make (myArray, dsp->compose(myDsp));
		return returnValue;
	}
}
/* runs */


RPTR(XnRegion) OffsetScruArray::runAt (APTR(Position) key){
	WPTR(XnRegion) 	returnValue;
	returnValue = this->runAtInt(CAST(IntegerPos,key)->asIntegerVar());
	return returnValue;
}


RPTR(XnRegion) OffsetScruArray::runAtInt (IntegerVar anIdx){
	WPTR(XnRegion) 	returnValue;
	returnValue = myDsp->ofAll(myArray->runAtInt(myDsp->inverseOfInt(anIdx)));
	return returnValue;
}
/* testing */


UInt32 OffsetScruArray::actualHashForEqual (){
	return cat_OffsetScruArray->hashForEqual() + myArray->hashForEqual() + myDsp->hashForEqual();
}


BooleanVar OffsetScruArray::includesIntKey (IntegerVar aKey){
	return myArray->includesIntKey(myDsp->inverseOfInt(aKey));
}


BooleanVar OffsetScruArray::includesKey (APTR(Position) aKey){
	return this->includesIntKey(CAST(IntegerPos,aKey)->asIntegerVar());
}


BooleanVar OffsetScruArray::isEmpty (){
	return myArray->isEmpty();
}


BooleanVar OffsetScruArray::isEqual (APTR(Heaper) other){
	BEGIN_CHOOSE(other) {
		BEGIN_KIND(OffsetScruArray,osa) {
			{	BooleanVar crutch_Flag;
				/* osa->innerArray()->isEqual(myArray) && osa->innerArray()->isEqual(myArray) */
				
				crutch_Flag = osa->innerArray()->isEqual(myArray);
				if(crutch_Flag) {
					crutch_Flag = osa->innerArray()->isEqual(myArray);
				}
				return crutch_Flag;
			}
		} END_KIND;
		BEGIN_OTHERS {
			return FALSE;
		} END_OTHERS;
	} END_CHOOSE;
	/* fodder */
	return FALSE;
}
/* printing */


void OffsetScruArray::printOn (ostream& aStream){
	aStream << this->getCategory()->name() << "(" << myDsp << ", " << myArray << ")";
}
/* protected: create */


OffsetScruArray::OffsetScruArray (APTR(MuArray) array, APTR(Dsp) dsp) {
	myArray = array;
	myDsp = dsp;
}
/* creation */


RPTR(ScruTable) OffsetScruArray::copy (){
	WPTR(ScruTable) 	returnValue;
	returnValue = OffsetScruArray::make (CAST(MuArray,myArray->copy()), myDsp);
	return returnValue;
}


RPTR(ScruTable) OffsetScruArray::empty (){
	WPTR(ScruTable) 	returnValue;
	returnValue = myArray->emptySize(4);
	return returnValue;
}


RPTR(ScruTable) OffsetScruArray::emptySize (IntegerVar size){
	WPTR(ScruTable) 	returnValue;
	returnValue = myArray->emptySize(size);
	return returnValue;
}
/* conversion */


RPTR(ImmuTable) OffsetScruArray::asImmuTable (){
	WPTR(ImmuTable) 	returnValue;
	returnValue = ImmuTable::offsetImmuTable(myArray->asImmuTable(), myDsp);
	return returnValue;
}


RPTR(MuTable) OffsetScruArray::asMuTable (){
	SPTR(MuTable) newArray;
	SPTR(TableStepper) s;
	
	newArray = myArray->emptySize(myArray->count())->asMuTable();
	BEGIN_FOR_EACH(Heaper,e,(s = myArray->stepper())) {
		newArray->atIntStore(myDsp->ofInt(s->index()), e);
	} END_FOR_EACH;
	WPTR(MuTable) 	returnValue;
	returnValue = newArray;
	return returnValue;
}
/* enumerating */


RPTR(TableStepper) OffsetScruArray::stepper (APTR(OrderSpec) order/* = NULL*/){
	WPTR(TableStepper) 	returnValue;
	returnValue = OffsetArrayStepper::make (myArray->stepper(order), myDsp);
	return returnValue;
}
/* private: private */


RPTR(MuArray) OffsetScruArray::innerArray (){
	return (MuArray*) myArray;
}


RPTR(Dsp) OffsetScruArray::innerDsp (){
	return (Dsp*) myDsp;
}

#ifndef ARRAYX_SXX
#include "arrayx.sxx"
#endif /* ARRAYX_SXX */


#ifndef ARRAYP_SXX
#include "arrayp.sxx"
#endif /* ARRAYP_SXX */



#endif /* ARRAYX_CXX */

