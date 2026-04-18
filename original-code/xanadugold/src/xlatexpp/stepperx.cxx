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

#ifndef STEPPERX_CXX
#define STEPPERX_CXX


#ifndef CHOOSEX_HXX
#include "choosex.hxx"
#endif /* CHOOSEX_HXX */

#ifndef STEPPERX_HXX
#include "stepperx.hxx"
#endif /* STEPPERX_HXX */

#ifndef STEPPERX_IXX
#include "stepperx.ixx"
#endif /* STEPPERX_IXX */

#ifndef STEPPERP_HXX
#include "stepperp.hxx"
#endif /* STEPPERP_HXX */

#ifndef STEPPERP_IXX
#include "stepperp.ixx"
#endif /* STEPPERP_IXX */


#ifndef INTEGERX_HXX
#include "integerx.hxx"
#endif /* INTEGERX_HXX */

#ifndef SPACEX_HXX
#include "spacex.hxx"
#endif /* SPACEX_HXX */




/* ************************************************************************ *
 * 
 *                    Class Accumulator 
 *
 * ************************************************************************ */


/* creation */
/* An Accumulator is a thing which collects a sequence of objects one 
at a time for some purpose.  Typically, this purpose is to construct 
a new object out of all the collected objects.  When used in this 
way, one can think of the Accumulator as being sort of like a 
pseudo-constructor which is spread out in time, and whose arguments 
are identified by the sequence they occur in.  Accumulators are 
typically used in loops.
	
	A (future) example of an Accumulator which is not like "a 
pseudo-constructor spread out in time" is a communications stream 
between two threads (or even coroutines) managed by an Accumulator / 
Stepper pair.  The producer process produces by putting objects into 
his Accumulator, and the consuming process consumes by pulling values 
out of his Stepper.  If you want to stretch the analogy, I suppose 
you can see the Accumulator of the pair as a pseudo-constructor which 
constructs the Stepper, but *overlapped* in time.
	
	It is normally considered bad style for two methods/functions to be 
pointing at the same Acumulator.  As long as Accumulators are used 
locally and without aliasing (i.e., as if they were pass-by-value 
Vars), these implementationally side-effecty objects can be 
understood applicatively.  If a copy of an Accumulator can be passed 
instead of a pointer to the same one, this is to be prefered.  This 
same comment applies even more so for Steppers.
	
	Example:  To build a set consisting of some transform of the 
elements of an existing set (what Smalltalk would naturally do with 
"collect:"), a natural form for the loop would be:
	
	SPTR(Accumulator) acc = setAccumulator();
	FOR_EACH(Heaper,each,oldSet->stepper(), {
		acc->step (transform (each));
	});
	return CAST(ImmuSet,acc->value());
	
	See class Stepper for documentation of FOR_EACH. */


/* deferred operations */
/* deferred creation */

	/* automatic 0-argument constructor */
Accumulator::Accumulator() {}



/* ************************************************************************ *
 * 
 *                    Class Stepper 
 *
 * ************************************************************************ */



/* Initializers for Stepper */

WPTR(Stepper) Stepper::TheEmptyStepper = NULL;



BEGIN_INIT_TIME(Stepper,initTimeNonInherited) {
	CONSTRUCT_ON(PERSISTENT,Stepper::TheEmptyStepper,EmptyStepper,());
} END_INIT_TIME(Stepper,initTimeNonInherited);



/* Initializers for Stepper */






/* pseudo constructors */


RPTR(Stepper) Stepper::itemStepper (APTR(Heaper) item){
	/* A Stepper which will enumerate only this one element. 
	Useful for implementing 
		singleton collections. */
	
	if (item == NULL) {
		WPTR(Stepper) 	returnValue;
		returnValue = Stepper::TheEmptyStepper;
		return returnValue;
	} else {
		WPTR(Stepper) 	returnValue;
		returnValue = ItemStepper::make (item);
		return returnValue;
	}
}
/* Steppers provide a common way to enumerate the elements of any 
abstraction which acts as a collection.  This simplifies the 
protocols of the various collection classes, as they now merely have 
to provide messages to create the appropriate steppers, which then 
handle the rest of the job.  Also, the Stepper steps over the set of 
elements which existed *at the time* the stepper was returned.  If 
you're stepping over the elements of a changable collection, and the 
elements are changing while you are stepping, any other rule could 
lead to confusion.
	
	Smalltalk's collections provide the protocol to enumerate their 
elements directly.  Having the collection change during stepping is 
the source of a famous Smalltalk bug. Clu and Alphard both have 
"Iterators" which are much like our Steppers, but these other 
languages both specify (as a pre-condition) that the collection not 
be changed while the Iterator is active.  This burdens the programmer 
with ensuring a non-local property that we know of know way of 
robustly checking for in real programs.
	
	Steppers and Accumulators are sort of duals.  Steppers are typically 
used in loops as a source of values to be consumed by the loop body.  
Accumulators are typically used as a sink for values which are 
produced in the loop body.  One can (and sometimes does) interact 
with a Stepper explicitly through its protocol.  However, for the 
typical case of just executing a loop body in turn for each 
successive element should be written using the FOR_EACH macro.  The 
syntax of the macro is:
	
	FOR_EACH(ElementType,varName, (stepperValuedExpr), {
		Loop body (varName is in scope)
		});
	
	For example:
	
	FOR_EACH(Position,each,(reg->stepper()), {
		doSomethingWith (each);
		});
		
	is roughly equivalent to (see macro definition for exact equivalence):
	
	for(SPTR(Stepper) stomp = reg->stepper(); stomp->hasValue(); stomp->step()) {
		SPTR(Position) each = CAST(Position,stomp->fetch());
		doSomethingWith (each);
	}
	stomp->destroy();
	
	Since the Stepper is necessarily exhausted if we fall out the end of 
a FOR_EACH, and there isn't anything useful we can do with an 
exhausted stepper, it's no great loss for FOR_EACH to destroy it.  
Doing so substantially unburdens the garbage collector.  In addition, 
the means we are planning to use to lower the overhead of having the 
Stepper step over a snapshot of the collection depends on (for its 
efficiency) the Stepper being destroyed promptly if it is dropped 
without stepping it to exhaustion.
	
	Not all Steppers will eventually terminate.  For example, a Stepper 
which enumerates all the primes is perfectly reasonable.  When using 
Steppers (and especially FOR_EACH), you should be confident that you 
haven't just introduced an infinite loop into your program.  See 
Stepper::hasValue().
	
	It is normally considered bad style for two methods/functions to be 
pointing at the same Stepper.  As long as Steppers are used locally 
and without aliasing (i.e., as if they were pass-by-value Vars), 
these implementationally side-effecty objects can be understood 
applicatively.  If a copy of an Stepper can be passed instead of a 
pointer to the same one, this is to be prefered.  See Accumulator.
	
	Subclasses of Stepper can provide more protocol.  See TableStepper. */


/* create */
/* operations */


BooleanVar Stepper::atEnd (){
	/* Iff I have a current value (i.e. this message returns 
	FALSE), then I am not exhasted. 'fetch' and 'get' will both 
	return this value, and I can be 'step'ped to my next state. 
	As I am stepped, eventually I may become exhausted (the 
	reverse of all the above), which is a permanent condition. 
		
		Note that not all steppers have to be exhaustable. A Stepper 
	which enumerates all primes is perfectly reasonable. Assuming 
	otherwise will create infinite loops.  See class comment. */
	
	return !this->hasValue();
}


WPTR(Heaper) Stepper::get (){
	/* Essential.  BLAST if exhasted.  Else return current 
	element. I return wimpily since most items returned are held 
	by collections. If I create a new object, I should cache it. */
	
	SPTR(Heaper) val;
	
	val = this->fetch();
	if (val == NULL) {
		BLAST(EmptyStepper);
	}
	WPTR(Heaper) 	returnValue;
	returnValue = val;
	return returnValue;
}


RPTR(PrimArray) Stepper::stepMany (Int32 count/* = -1*/){
	/* Collects the remaining elements in the stepper into an 
	array. Returns an array of no more than count elements (or 
	some arbitrary chunk if the count is negative). The fact that 
	you got fewer elements that you asked for does not mean that 
	the stepper is atEnd, since there may be some reason to break 
	the result up into smaller chunks; you should always check. */
	
	SPTR(Accumulator) result;
	Int32 n;
	
	if (count >= Int32Zero) {
		n = count;
	} else {
		n = 1000;
	}
	CONSTRUCT(result,PtrArrayAccumulator,(n, tcsj));
	n = Int32Zero;
	for (;;) {	BooleanVar crutch_Flag;
		/* this->hasValue() && (count < Int32Zero && n < 1000 || n < count) */
		
		crutch_Flag = this->hasValue();
		if(crutch_Flag) {
			crutch_Flag = count < Int32Zero;
			if(crutch_Flag) {
				crutch_Flag = n < 1000;
			}
			if(!crutch_Flag) {
				crutch_Flag = n < count;
			}
		}
		if (crutch_Flag) {
			result->step(this->fetch());
			this->step();
			n += 1;
		} else {
			break;
		}
	}
	return CAST(PrimArray,result->value());
}


RPTR(Heaper) Stepper::theOne (){
	/* If there is precisely one element in the stepper return 
	it; if not, blast without changing the state of the Stepper */
	
	SPTR(Stepper) other;
	SPTR(Heaper) result;
	
	if (!this->hasValue()) {
		BLAST(MustHaveOneValue);
	}
	other = this->copy();
	result = other->fetch();
	other->step();
	if (other->hasValue()) {
		BLAST(MustHaveOneValue);
	}
	WPTR(Heaper) 	returnValue;
	returnValue = result;
	return returnValue;
}

	/* automatic 0-argument constructor */
Stepper::Stepper() {}



/* ************************************************************************ *
 * 
 *                    Class   TableStepper 
 *
 * ************************************************************************ */


/* creation */
/* For enumerating the key->value associations of a table.  A typical 
use (for a table whose range elements were all Foos) might be:
	
	SPTR(TableStepper) stomp = table->stepper();
	FOR_EACH(Foo,f,stomp, {
		doSomethingWith(stomp->key(), z);
	});
	
	Each iteration of the loop would correspond to an association of the 
table (snapshotted at the time "->stepper()" was sent).  For each 
association, "f" (a pointer to Foo) points at the range element, 
while "stomp->key()" provides the domain element.  See ScruTable::stepper. */


/* special */


IntegerVar TableStepper::index (){
	/* Unboxed version of TableStepper::key.  See class comment 
	in XuInteger. */
	
	return CAST(IntegerPos,this->position())->asIntegerVar();
}
/* create */
/* operations */


RPTR(PrimArray) TableStepper::stepManyPairs (Int32 count/* = -1*/){
	/* An array of the remaining elements in alternating 
	positions in the array
			[k1, v1, k2, v2, k3, v3, ...]
		Returns an array of up to count * 2 elements (or some 
	arbitrary number if count is negative), and steps the stepper 
	the corresponding number of times. You should check whether 
	the stepper is atEnd, since it can stop before the number you 
	give it because of some internal limit or grouping issue. */
	
	SPTR(Accumulator) result;
	Int32 n;
	
	if (count >= Int32Zero) {
		n = count * 2;
	} else {
		n = 1000;
	}
	CONSTRUCT(result,PtrArrayAccumulator,(n, tcsj));
	n = Int32Zero;
	for (;;) {	BooleanVar crutch_Flag;
		/* this->hasValue() && (count < Int32Zero && n < 1000 || n < count) */
		
		crutch_Flag = this->hasValue();
		if(crutch_Flag) {
			crutch_Flag = count < Int32Zero;
			if(crutch_Flag) {
				crutch_Flag = n < 1000;
			}
			if(!crutch_Flag) {
				crutch_Flag = n < count;
			}
		}
		if (crutch_Flag) {
			result->step(this->position());
			result->step(this->fetch());
			this->step();
			n += 1;
		} else {
			break;
		}
	}
	return CAST(PrimArray,result->value());
}

	/* automatic 0-argument constructor */
TableStepper::TableStepper() {}



/* ************************************************************************ *
 * 
 *                    Class EmptyStepper 
 *
 * ************************************************************************ */


/* This is a Stepper when you just want to step across a single item. */


/* protected: destruct */


void EmptyStepper::destruct (){
	/* This object is a canonical single instance, so its 
	destructor should only be called after main has exited. */
	
	if (!Initializer::inStaticDestruction()) BLAST(SanityViolation);
	
	this->Stepper::destruct();
}
/* create */


RPTR(Stepper) EmptyStepper::copy (){
	return this;
}


void EmptyStepper::destroy (){
	/* No */
	
	
}
/* operations */


WPTR(Heaper) EmptyStepper::fetch (){
	return NULL;
}


BooleanVar EmptyStepper::hasValue (){
	return FALSE;
}


void EmptyStepper::step (){
	
}

	/* automatic 0-argument constructor */
EmptyStepper::EmptyStepper() {}



/* ************************************************************************ *
 * 
 *                    Class ItemStepper 
 *
 * ************************************************************************ */



/* Initializers for ItemStepper */

GPTR(InstanceCache) ItemStepper::SomeSteppers = NULL;



BEGIN_INIT_TIME(ItemStepper,initTimeNonInherited) {
	ItemStepper::SomeSteppers = InstanceCache::make (8);
} END_INIT_TIME(ItemStepper,initTimeNonInherited);



/* Initializers for ItemStepper */






/* create */


RPTR(Stepper) ItemStepper::make (APTR(Heaper) item){
	SPTR(Heaper) result;
	
	result = ItemStepper::SomeSteppers->fetch();
	if (result == NULL) {
		RETURN_CONSTRUCT(ItemStepper,(item, tcsj));
	} else {
		WPTR(Stepper) 	returnValue;
		returnValue = new (result) ItemStepper(item, tcsj);
		return returnValue;
	}
}
/* This is a Stepper when you just want to step across a single item. */


/* create */


RPTR(Stepper) ItemStepper::copy (){
	if (myItem == NULL) {
		return this;
	} else {
		SPTR(Heaper) result;
		
		result = ItemStepper::SomeSteppers->fetch();
		if (result == NULL) {
			RETURN_CONSTRUCT(ItemStepper,(myItem, tcsj));
		} else {
			WPTR(Stepper) 	returnValue;
			returnValue = new (result) ItemStepper(myItem, tcsj);
			return returnValue;
		}
	}
}


ItemStepper::ItemStepper (APTR(Heaper) OR(NULL) item, TCSJ) {
	myItem = item;
}


void ItemStepper::destroy (){
	if (!ItemStepper::SomeSteppers->store(this)) {
		this->Stepper::destroy();
	}
}
/* operations */


WPTR(Heaper) ItemStepper::fetch (){
	return (Heaper*) myItem;
}


BooleanVar ItemStepper::hasValue (){
	return myItem != NULL;
}


void ItemStepper::step (){
	myItem = NULL;
}



/* ************************************************************************ *
 * 
 *                    Class PtrArrayAccumulator 
 *
 * ************************************************************************ */


/* To save array copies, this class will hand out its internal array 
if the size is right.  If it does so it remembers so that if new 
elements are introduced, a copy can be made for further use. */


/* operations */


RPTR(Accumulator) PtrArrayAccumulator::copy (){
	RETURN_CONSTRUCT(PtrArrayAccumulator,(CAST(PtrArray,myValues->copy()), myN));
}


void PtrArrayAccumulator::step (APTR(Heaper) x){
	if (!(myN + 1 < myValues->count())) {
		myValues = CAST(PtrArray,myValues->copyGrow(myValues->count() + 1));
	}
	myValues->store(myN, x);
	myN += 1;
}


RPTR(Heaper) PtrArrayAccumulator::value (){
	if (myValues->count() == myN) {
		myValuesGiven = TRUE;
		return (PtrArray*) myValues;
	} else {
		WPTR(Heaper) 	returnValue;
		returnValue = myValues->copy(myN);
		return returnValue;
	}
}
/* create */


PtrArrayAccumulator::PtrArrayAccumulator () {
	myValues = PtrArray::nulls(2);
	myN = UInt32Zero;
	myValuesGiven = FALSE;
}


PtrArrayAccumulator::PtrArrayAccumulator (UInt32 count, TCSJ) {
	myValues = PtrArray::nulls(count);
	myN = UInt32Zero;
	myValuesGiven = FALSE;
}


PtrArrayAccumulator::PtrArrayAccumulator (APTR(PtrArray) values, UInt32 n) {
	myValues = values;
	myN = n;
	myValuesGiven = FALSE;
}



/* ************************************************************************ *
 * 
 *                    Class PtrArrayStepper 
 *
 * ************************************************************************ */


/* creation */


RPTR(TableStepper) PtrArrayStepper::ascending (APTR(PtrArray) array){
	/* Note: this being a low level operation, and there being no 
	lightweight form of immutable or lazily copied PtrArray, it 
	is my caller's responsibility to pass me a PtrArray which 
	will in fact not be changed during the life of this stepper.  
	This is an unchecked an uncheckable precondition on my clients. */
	
	RETURN_CONSTRUCT(PtrArrayStepper,(array, Int32Zero, array->count(), 1));
}


RPTR(TableStepper) PtrArrayStepper::descending (APTR(PtrArray) array){
	/* Note: this being a low level operation, and there being no 
	lightweight form of immutable or lazily copied PtrArray, it 
	is my caller's responsibility to pass me a PtrArray which 
	will in fact not be changed during the life of this stepper.  
	This is an unchecked an uncheckable precondition on my clients. */
	
	RETURN_CONSTRUCT(PtrArrayStepper,(array, array->count() - 1, -1, -1));
}
/* A Stepper for stepping over the elements of a PtrArray in 
ascending or descending order.  This is a TableStepper even though it 
is stepping over a PtrArray instead of a table.  Should probably 
eventually be generalized to PrimArrays. NOT.A.TYPE */


/* operations */


RPTR(Stepper) PtrArrayStepper::copy (){
	RETURN_CONSTRUCT(PtrArrayStepper,(CAST(PtrArray,myArray->copy()), myIndex, myPastEnd, myStep));
}


WPTR(Heaper) PtrArrayStepper::fetch (){
	if (myIndex >= myPastEnd) {
		return NULL;
	}
	WPTR(Heaper) 	returnValue;
	returnValue = myArray->fetch(myIndex);
	return returnValue;
}


BooleanVar PtrArrayStepper::hasValue (){
	return myIndex < myPastEnd;
}


void PtrArrayStepper::step (){
	myIndex += myStep;
}
/* special */


IntegerVar PtrArrayStepper::index (){
	if (myIndex >= myPastEnd) {
		BLAST(EmptyStepper);
	}
	return myIndex;
}


RPTR(Position) PtrArrayStepper::position (){
	if (myIndex >= myPastEnd) {
		BLAST(EmptyStepper);
	}
	WPTR(Position) 	returnValue;
	returnValue = IntegerPos::make (myIndex);
	return returnValue;
}
/* private: creation */


PtrArrayStepper::PtrArrayStepper (
		APTR(PtrArray) array, 
		Int32 start, 
		Int32 pastEnd, 
		Int32 step) 
{
	myArray = array;
	myIndex = start;
	myPastEnd = pastEnd;
	myStep = step;
}

#ifndef STEPPERX_SXX
#include "stepperx.sxx"
#endif /* STEPPERX_SXX */


#ifndef STEPPERP_SXX
#include "stepperp.sxx"
#endif /* STEPPERP_SXX */



#endif /* STEPPERX_CXX */

