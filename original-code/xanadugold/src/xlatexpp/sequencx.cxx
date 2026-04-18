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

#ifndef SEQUENCX_CXX
#define SEQUENCX_CXX


#ifndef CHOOSEX_HXX
#include "choosex.hxx"
#endif /* CHOOSEX_HXX */

#ifndef SEQUENCX_HXX
#include "sequencx.hxx"
#endif /* SEQUENCX_HXX */

#ifndef SEQUENCX_IXX
#include "sequencx.ixx"
#endif /* SEQUENCX_IXX */

#ifndef SEQUENCP_HXX
#include "sequencp.hxx"
#endif /* SEQUENCP_HXX */

#ifndef SEQUENCP_IXX
#include "sequencp.ixx"
#endif /* SEQUENCP_IXX */


#ifndef NXCVRX_HXX
#include "nxcvrx.hxx"
#endif /* NXCVRX_HXX */

#ifndef PRIMVALX_HXX
#include "primvalx.hxx"
#endif /* PRIMVALX_HXX */

#ifndef SETX_HXX
#include "setx.hxx"
#endif /* SETX_HXX */

#ifndef SPACER_HXX
#include "spacer.hxx"
#endif /* SPACER_HXX */

#ifndef XFRSPECX_HXX
#include "xfrspecx.hxx"
#endif /* XFRSPECX_HXX */




/* ************************************************************************ *
 * 
 *                    Class Sequence 
 *
 * ************************************************************************ */



/* Initializers for Sequence */

GPTR(Sequence) Sequence::TheZero = NULL;



BEGIN_INIT_TIME(Sequence,initTimeNonInherited) {
	REQUIRES (IntegerVarArray);
	CONSTRUCT(Sequence::TheZero,Sequence,(IntegerVarZero, IntegerVarArray::zeros(Int32Zero)));
} END_INIT_TIME(Sequence,initTimeNonInherited);



/* Initializers for Sequence */






/* pseudo constructors */


RPTR(Sequence) Sequence::numbers (APTR(PrimIntegerArray) digits){
	Int32 first;
	Int32 last;
	
	first = digits->indexPastInteger(IntegerVarZero);
	if (first == -1) {
		WPTR(Sequence) 	returnValue;
		returnValue = Sequence::zero();
		return returnValue;
	}
	last = 
			digits->indexPastInteger(IntegerVarZero, -1, -1);
	RETURN_CONSTRUCT(Sequence,(first, CAST(PrimIntegerArray,digits->copy(last - first + 1, first))));
}


RPTR(Sequence) Sequence::one (IntegerVar a){
	/* A single element Sequence */
	
	if (a == IntegerVarZero) {
		WPTR(Sequence) 	returnValue;
		returnValue = Sequence::zero();
		return returnValue;
	}
	RETURN_CONSTRUCT(Sequence,(IntegerVarZero, CAST(PrimIntegerArray,PrimSpec::integerVar()->arrayWith(PrimSpec::integerVar()->value(a)))));
}


RPTR(Sequence) Sequence::string (char * string){
	RETURN_CONSTRUCT(Sequence,(IntegerVarZero, UInt8Array::string(string)));
}


RPTR(Sequence) Sequence::three (
		IntegerVar a, 
		IntegerVar b, 
		IntegerVar c)
{
	/* A three element Sequence */
	
	if (c == IntegerVarZero) {
		WPTR(Sequence) 	returnValue;
		returnValue = Sequence::two(a, b);
		return returnValue;
	}
	RETURN_CONSTRUCT(Sequence,(IntegerVarZero, CAST(PrimIntegerArray,PrimSpec::integerVar()->arrayWithThree(PrimSpec::integerVar()->value(a), PrimSpec::integerVar()->value(b), PrimSpec::integerVar()->value(c)))));
}


RPTR(Sequence) Sequence::two (IntegerVar a, IntegerVar b){
	/* A two element Sequence */
	
	if (b == IntegerVarZero) {
		WPTR(Sequence) 	returnValue;
		returnValue = Sequence::one(a);
		return returnValue;
	}
	RETURN_CONSTRUCT(Sequence,(IntegerVarZero, CAST(PrimIntegerArray,PrimSpec::integerVar()->arrayWithTwo(PrimSpec::integerVar()->value(a), PrimSpec::integerVar()->value(b)))));
}
/* private: */


void Sequence::printArrayOn (ostream& oo, APTR(PrimIntegerArray) numbers){
	/* Print a sequence of numbers separated by dots. Deal with 
	strings specially. */
	
	if (numbers->isKindOf(cat_UInt8Array)) {
		oo << "<" << numbers << ">";
	} else {
		{
			Int32 LoopFinal = numbers->count();
			Int32 i = Int32Zero;
			for (;;) {
				if (i >= LoopFinal){
					break;
				}
				{
					if (i > Int32Zero) {
						oo << ".";
					}
					oo << numbers->integerAt(i);
				}
				i += 1;
			}
		}
	}
}


void Sequence::printOn (
		ostream& oo, 
		IntegerVar shift, 
		APTR(PrimIntegerArray) numbers)
{
	/* Print a sequence of numbers separated by dots. Deal with 
	strings specially. */
	
	if (shift < -numbers->count()) {
		Sequence::printArrayOn(oo, numbers);
		oo << ".";
		Sequence::printZerosOn(oo, -shift - numbers->count());
		oo << "!0";
	} else {
		if (shift < IntegerVarZero) {
			Sequence::printArrayOn(oo, CAST(PrimIntegerArray,numbers->copy((-shift).asLong())));
			oo << "!";
			Sequence::printArrayOn(oo, CAST(PrimIntegerArray,numbers->copy(-1, (-shift).asLong())));
		} else {
			oo << "0!";
			if (shift > IntegerVarZero) {
				Sequence::printZerosOn(oo, shift);
				oo << ".";
			}
			Sequence::printArrayOn(oo, numbers);
		}
	}
}


void Sequence::printZerosOn (ostream& oo, IntegerVar shift){
	/* Print a sequence of zeros separated by dots. Deal with 
	large numbers specially. */
	
	if (shift > 7) {
		oo << "...(" << shift << ")...";
	} else {
		{
			IntegerVar LoopFinal = shift - 1;
			IntegerVar i = IntegerVarZero;
			for (;;) {
				if (i >= LoopFinal){
					break;
				}
				{
					oo << "0.";
				}
				i += 1;
			}
		}
		oo << "0";
	}
}


RPTR(Sequence) Sequence::usingx (IntegerVar shift, APTR(PrimIntegerArray) numbers){
	/* Don't need to make a copy of the array */
	
	Int32 start;
	Int32 stop;
	
	start = numbers->indexPastInteger(IntegerVarZero);
	if (start < Int32Zero) {
		WPTR(Sequence) 	returnValue;
		returnValue = Sequence::zero();
		return returnValue;
	}
	stop = 
			numbers->indexPastInteger(IntegerVarZero, -1, -1);
	{	BooleanVar crutch_Flag;
		/* start != Int32Zero || stop < numbers->count() - 1 */
		
		crutch_Flag = start != Int32Zero;
		if(!crutch_Flag) {
			crutch_Flag = stop < numbers->count() - 1;
		}
		if (crutch_Flag) {
			RETURN_CONSTRUCT(Sequence,(shift + start, CAST(PrimIntegerArray,numbers->copy(stop - start, start))));
		} else {
			RETURN_CONSTRUCT(Sequence,(shift, numbers));
		}
	}
}
/* Represents an infinite sequence of integers (of which only a 
finite number can be non-zero). They are lexically ordered, and there 
is a "decimal point" between the numbers at -1 and 0.

Implementation note:
The array should have no zeros at either end, and noone else should 
have a pointer to it. */


/* accessing */


RPTR(XnRegion) Sequence::asRegion (){
	WPTR(XnRegion) 	returnValue;
	returnValue = SequenceRegion::usingx(FALSE, CAST(PtrArray,PrimSpec::pointer()->arrayWithTwo(BeforeSequence::make (this), AfterSequence::make (this))));
	return returnValue;
}


IntegerVar Sequence::firstIndex (){
	/* The smallest index with a non-zero number. Blasts if it is 
	all zeros. */
	
	if (myNumbers->count() == Int32Zero) {
		BLAST(ZeroSequence);
	}
	return myShift;
}


IntegerVar Sequence::integerAt (IntegerVar index){
	/* The number at the given index in the Sequence. Returns 
	zeros beyond either end of the array. */
	
	IntegerVar i;
	
	i = index - myShift;
	{	BooleanVar crutch_Flag;
		/* i >= IntegerVarZero && i < this->count() */
		
		crutch_Flag = i >= IntegerVarZero;
		if(crutch_Flag) {
			crutch_Flag = i < this->count();
		}
		if (crutch_Flag) {
			return myNumbers->integerAt(i.asLong());
		} else {
			return IntegerVarZero;
		}
	}
}


RPTR(PrimIntegerArray) Sequence::integers (){
	/* Essential. The numbers in this Sequence. This is a copy of 
	the array, so you may modify it.
		Note that two Sequences which are isEqual, may actually have 
	arrays of numbers which have different specs. Also, the array 
	will not have any zeros at the beginning or end. */
	
	return CAST(PrimIntegerArray,myNumbers->copy());
}


BooleanVar Sequence::isZero (){
	/* Whether all the numbers in the sequence are zero */
	
	return myNumbers->count() == Int32Zero;
}


IntegerVar Sequence::lastIndex (){
	/* The largest index with a non-zero number. Blasts if it is 
	all zeros. */
	
	if (myNumbers->count() == Int32Zero) {
		BLAST(ZeroSequence);
	}
	return myShift + myNumbers->count() - 1;
}
/* private: comparing */


Int32 Sequence::comparePrefix (APTR(Sequence) other, IntegerVar n){
	/* Compare my numbers up to and including index n with the 
	corresponding numbers in the other Sequence. Return -1, 0 or 
	1 depending on whether they are <, =, or > the other. */
	
	IntegerVar diff;
	
	{	BooleanVar crutch_Flag;
		/* this->isZero() || myShift > n */
		
		crutch_Flag = this->isZero();
		if(!crutch_Flag) {
			crutch_Flag = myShift > n;
		}
		if (crutch_Flag) {
			{	BooleanVar crutch_Flag;
				/* other->isZero() || other->shift() > n */
				
				crutch_Flag = other->isZero();
				if(!crutch_Flag) {
					crutch_Flag = other->shift() > n;
				}
				if (crutch_Flag) {
					return Int32Zero;
				}
			}
			if (other->secretNumbers()->integerAt(Int32Zero) > IntegerVarZero) {
				return -1;
			} else {
				return 1;
			}
		}
	}
	{	BooleanVar crutch_Flag;
		/* other->isZero() || other->shift() > n */
		
		crutch_Flag = other->isZero();
		if(!crutch_Flag) {
			crutch_Flag = other->shift() > n;
		}
		if (crutch_Flag) {
			if (myNumbers->integerAt(Int32Zero) > IntegerVarZero) {
				return 1;
			} else {
				return -1;
			}
		}
	}
	diff = myShift - other->shift();
	if (diff < IntegerVarZero) {
		if (myNumbers->integerAt(Int32Zero) > IntegerVarZero) {
			return 1;
		} else {
			return -1;
		}
	}
	if (diff > IntegerVarZero) {
		if (other->secretNumbers()->integerAt(Int32Zero) > IntegerVarZero) {
			return -1;
		} else {
			return 1;
		}
	}
	return myNumbers->compare(other->secretNumbers(), min(n - myShift + 1, max(myNumbers->count(), other->secretNumbers()->count())).asLong());
}
/* testing */


UInt32 Sequence::actualHashForEqual (){
	return myShift.asLong() ^ myNumbers->elementsHash();
}


BooleanVar Sequence::isEqual (APTR(Heaper) other){
	BEGIN_CHOOSE(other) {
		BEGIN_KIND(Sequence,sequence) {
			{	BooleanVar crutch_Flag;
				/* myShift == sequence->shift() && myNumbers->contentsEqual(sequence->secretNumbers()) */
				
				crutch_Flag = myShift == sequence->shift();
				if(crutch_Flag) {
					crutch_Flag = myNumbers->contentsEqual(sequence->secretNumbers());
				}
				return crutch_Flag;
			}
		} END_KIND;
		BEGIN_OTHERS {
			return FALSE;
		} END_OTHERS;
	} END_CHOOSE;
	/* compiler fodder */
	return FALSE;
}


BooleanVar Sequence::isGE (APTR(Position) other){
	/* Whether this sequence is greater than or equal to the 
	other sequence, using a lexical comparison of their 
	corresponding numbers. */
	
	SPTR(Sequence) o;
	
	o = CAST(Sequence,other);
	if (this->isZero()) {
		{	BooleanVar crutch_Flag;
			/* o->isZero() || o->secretNumbers()->integerAt(Int32Zero) <= IntegerVarZero */
			
			crutch_Flag = o->isZero();
			if(!crutch_Flag) {
				crutch_Flag = o->secretNumbers()->integerAt(Int32Zero) <= IntegerVarZero;
			}
			return crutch_Flag;
		}
	}
	{	BooleanVar crutch_Flag;
		/* o->isZero() || myShift < o->shift() */
		
		crutch_Flag = o->isZero();
		if(!crutch_Flag) {
			crutch_Flag = myShift < o->shift();
		}
		if (crutch_Flag) {
			{	BooleanVar crutch_Flag;
				/* this->isZero() || myNumbers->integerAt(Int32Zero) >= IntegerVarZero */
				
				crutch_Flag = this->isZero();
				if(!crutch_Flag) {
					crutch_Flag = myNumbers->integerAt(Int32Zero) >= IntegerVarZero;
				}
				return crutch_Flag;
			}
		}
	}
	if (myShift > o->shift()) {
		return o->secretNumbers()->integerAt(Int32Zero) <= IntegerVarZero;
	}
	if (myShift < o->shift()) {
		return myNumbers->integerAt(Int32Zero) >= IntegerVarZero;
	}
	return myNumbers->compare(o->secretNumbers()) >= Int32Zero;
}
/* private: */
/* printing */


void Sequence::printOn (ostream& oo){
	Sequence::printOn(oo, myShift, myNumbers);
}
/* create */


Sequence::Sequence (IntegerVar shift, APTR(PrimIntegerArray) numbers) {
	myShift = shift;
	myNumbers = numbers;
}
/* operations */


RPTR(Sequence) Sequence::first (){
	/* The sequence consisting of all numbers in this one up to 
	but not including the first zero, or the entire thing if 
	there are no zeros */
	/* | zero {Int32} |
		zero := myNumbers indexOfInteger: IntegerVarZero.
		zero < Int32Zero ifTrue:
			[^self]
		ifFalse:
			[^Sequence create: ((myNumbers copy: zero) cast: 
	PrimIntegerArray)] */
	
	BLAST(NOT_YET_IMPLEMENTED);
	/* fodder */
	return NULL;
}


RPTR(Sequence) Sequence::minus (APTR(Sequence) other){
	/* A sequence with the corresponding numbers subtracted from 
	each other */
	
	Int32 diff;
	SPTR(PrimIntegerArray) result;
	
	/* Ravi -- Thing to do !!!! */
	
	/* Only increase representation size when necessary */
	/* Known bug !!!! */
	
	/* large difference in shifts creates huge array */
	diff = (other->shift() - myShift).asLong();
	if (diff > Int32Zero) {
		result = CAST(PrimIntegerArray,PrimSpec::integerVar()->copyGrow(myNumbers, max(diff + other->secretNumbers()->count() - myNumbers->count(), Int32Zero)));
		result->subtractElements(diff, other->secretNumbers());
		WPTR(Sequence) 	returnValue;
		returnValue = Sequence::usingx(myShift, result);
		return returnValue;
	} else {
		result = CAST(PrimIntegerArray,PrimSpec::integerVar()->copy(myNumbers, -1, Int32Zero, -diff, max((other->shift() + other->count() - (myShift + myNumbers->count())).asLong(), Int32Zero)));
		result->subtractElements(-diff, other->secretNumbers());
		WPTR(Sequence) 	returnValue;
		returnValue = Sequence::usingx(other->shift(), result);
		return returnValue;
	}
}


RPTR(Sequence) Sequence::plus (APTR(Sequence) other){
	/* A sequence with the corresponding numbers added to each other */
	
	Int32 diff;
	SPTR(PrimIntegerArray) result;
	
	/* Ravi -- Thing to do !!!! */
	
	/* Only increase representation size when necessary */
	/* Known bug !!!! */
	
	/* large difference in shifts creates huge array */
	diff = (other->shift() - myShift).asLong();
	if (diff > Int32Zero) {
		result = CAST(PrimIntegerArray,PrimSpec::integerVar()->copyGrow(myNumbers, max(diff + other->secretNumbers()->count() - myNumbers->count(), Int32Zero)));
		result->addElements(diff, other->secretNumbers());
		WPTR(Sequence) 	returnValue;
		returnValue = Sequence::usingx(myShift, result);
		return returnValue;
	} else {
		result = CAST(PrimIntegerArray,PrimSpec::integerVar()->copy(myNumbers, -1, Int32Zero, -diff, max((other->shift() + other->count() - (myShift + myNumbers->count())).asLong(), Int32Zero)));
		result->addElements(Int32Zero, other->secretNumbers());
		WPTR(Sequence) 	returnValue;
		returnValue = Sequence::usingx(other->shift(), result);
		return returnValue;
	}
}


RPTR(Sequence) Sequence::rest (){
	/* The sequence consisting of all numbers in this one after 
	but not including the first zero, or a null sequence if there 
	are no zeros */
	/* | zero {Int32} |
		zero := myNumbers indexOfInteger: IntegerVarZero.
		zero < Int32Zero ifTrue:
			[^Sequence zero]
		ifFalse:
			[^Sequence create: ((myNumbers
				copy: -1 with: 1 + zero) cast: PrimIntegerArray)] */
	
	BLAST(NOT_YET_IMPLEMENTED);
	/* fodder */
	return NULL;
}


RPTR(Sequence) Sequence::shift (IntegerVar offset){
	/* Shift the numbers by some number of places. Positive 
	shifts make it less significant, negative shifts make it more 
	significant. */
	
	{	BooleanVar crutch_Flag;
		/* offset == IntegerVarZero || myNumbers->count() == Int32Zero */
		
		crutch_Flag = offset == IntegerVarZero;
		if(!crutch_Flag) {
			crutch_Flag = myNumbers->count() == Int32Zero;
		}
		if (crutch_Flag) {
			return this;
		}
	}
	RETURN_CONSTRUCT(Sequence,(myShift + offset, myNumbers));
}


RPTR(Sequence) Sequence::with (IntegerVar index, IntegerVar number){
	/* Change a single element of the sequence. */
	
	{	BooleanVar crutch_Flag;
		/* index >= myShift && index - myShift < myNumbers->count() */
		
		crutch_Flag = index >= myShift;
		if(crutch_Flag) {
			crutch_Flag = index - myShift < myNumbers->count();
		}
		if (crutch_Flag) {
			if (number == IntegerVarZero) {
				if (index == myShift) {
					RETURN_CONSTRUCT(Sequence,(myShift + 1, CAST(PrimIntegerArray,myNumbers->copy(myNumbers->count() - 1, 1))));
				}
				if (index == myShift + myNumbers->count()) {
					RETURN_CONSTRUCT(Sequence,(myShift + 1, CAST(PrimIntegerArray,myNumbers->copy(myNumbers->count() - 1))));
				}
			}
			RETURN_CONSTRUCT(Sequence,(myShift, myNumbers->hold((index - myShift).asLong(), number)));
		}
	}
	if (number == IntegerVarZero) {
		return this;
	}
	if (index < myShift) {
		SPTR(PrimIntegerArray) result;
		
		result = CAST(PrimIntegerArray,CAST(PrimIntegerSpec,myNumbers->spec())->combine(CAST(PrimIntegerSpec,PrimSpec::toHold(number)))->copy(myNumbers, -1, Int32Zero, (myShift - index).asLong()));
		result->storeInteger(Int32Zero, number);
		RETURN_CONSTRUCT(Sequence,(index, result));
	}
	RETURN_CONSTRUCT(Sequence,(myShift, myNumbers->hold((index - myShift).asLong(), number)));
}


RPTR(Sequence) Sequence::withFirst (IntegerVar number){
	/* A Sequence with all my numbers followed by the given one */
	
	BLAST(NOT_YET_IMPLEMENTED);
	/* fodder */
	return NULL;
}


RPTR(Sequence) Sequence::withLast (IntegerVar number){
	/* A Sequence with all my numbers followed by the given one */
	
	RETURN_CONSTRUCT(Sequence,(myShift, myNumbers->hold(myNumbers->count(), number)));
}


RPTR(Sequence) Sequence::withRest (APTR(Sequence) other){
	/* A sequence containing all the numbers in this one, 
	followed by the other one, separated by a single zero. */
	
	SPTR(PrimIntegerSpec) spec;
	SPTR(PrimIntegerArray) result;
	
	spec = CAST(PrimIntegerSpec,myNumbers->spec())->combine(CAST(PrimIntegerSpec,other->secretNumbers()->spec()));
	result = CAST(PrimIntegerArray,spec->copyGrow(myNumbers, other->count().asLong() + 1));
	result->storeMany(this->count().asLong() + 1, other->secretNumbers());
	RETURN_CONSTRUCT(Sequence,(myShift, result));
}



/* ************************************************************************ *
 * 
 *                    Class SequenceMapping 
 *
 * ************************************************************************ */


/* private: pseudo constructors */


RPTR(SequenceMapping) SequenceMapping::make (IntegerVar shift, APTR(Sequence) translation){
	RETURN_CONSTRUCT(SequenceMapping,(shift, translation));
}
/* Transforms a Sequence by shifting some amount, and then adding 
another Sequence to it. */


/* accessing */


BooleanVar SequenceMapping::isIdentity (){
	{	BooleanVar crutch_Flag;
		/* myShift == IntegerVarZero && myTranslation->isZero() */
		
		crutch_Flag = myShift == IntegerVarZero;
		if(crutch_Flag) {
			crutch_Flag = myTranslation->isZero();
		}
		return crutch_Flag;
	}
}
/* transforming */


RPTR(Position) SequenceMapping::inverseOf (APTR(Position) position){
	BEGIN_CHOOSE(position) {
		BEGIN_KIND(Sequence,sequence) {
			WPTR(Position) 	returnValue;
			returnValue = sequence->minus(myTranslation)->shift(-myShift);
			return returnValue;
		} END_KIND;
	} END_CHOOSE;
	/* compiler fodder */
	return NULL;
}


RPTR(XnRegion) SequenceMapping::inverseOfAll (APTR(XnRegion) reg){
	/* Ravi -- Thing to do !!!! */
	
	/* make this more efficient */
	WPTR(XnRegion) 	returnValue;
	returnValue = this->inverse()->ofAll(reg);
	return returnValue;
}


RPTR(Position) SequenceMapping::of (APTR(Position) position){
	BEGIN_CHOOSE(position) {
		BEGIN_KIND(Sequence,sequence) {
			WPTR(Position) 	returnValue;
			returnValue = sequence->shift(myShift)->plus(myTranslation);
			return returnValue;
		} END_KIND;
	} END_CHOOSE;
	/* compiler fodder */
	return NULL;
}


RPTR(XnRegion) SequenceMapping::ofAll (APTR(XnRegion) reg){
	BEGIN_CHOOSE(reg) {
		BEGIN_KIND(SequenceRegion,seq) {
			SPTR(PtrArray) OF1(SequenceEdge) edges;
			SPTR(PtrArray) OF1(SequenceEdge) newEdges;
			
			edges = seq->secretTransitions();
			newEdges = PtrArray::nulls(edges->count());
			{
				Int32 LoopFinal = edges->count();
				Int32 i = Int32Zero;
				for (;;) {
					if (i >= LoopFinal){
						break;
					}
					{
						newEdges->store(i, CAST(SequenceEdge,edges->fetch(i))->transformedBy(this));
					}
					i += 1;
				}
			}
			WPTR(XnRegion) 	returnValue;
			returnValue = SequenceRegion::usingx(seq->startsInside(), newEdges);
			return returnValue;
		} END_KIND;
	} END_CHOOSE;
	/* fodder */
	return NULL;
}
/* combining */


RPTR(Dsp) SequenceMapping::compose (APTR(Dsp) dsp){
	/* Return the composition of the two Dsps. Two Dsps of the 
	same space are always composable.
		(a->compose(b) ->minus(b))->isEqual (a)
		(a->compose(b) ->of(pos))->isEqual (a->of (b->of (pos)) */
	
	BEGIN_CHOOSE(dsp) {
		BEGIN_KIND(SequenceMapping,other) {
			WPTR(Dsp) 	returnValue;
			returnValue = SequenceMapping::make (myShift + other->shift(), CAST(Sequence,this->of(other->translation())));
			return returnValue;
		} END_KIND;
	} END_CHOOSE;
	/* compiler fodder */
	return NULL;
}


RPTR(Mapping) SequenceMapping::inverse (){
	WPTR(Mapping) 	returnValue;
	returnValue = SequenceMapping::make (-myShift, Sequence::zero()->minus(myTranslation)->shift(myShift));
	return returnValue;
}


RPTR(Dsp) SequenceMapping::inverseCompose (APTR(Dsp) dsp){
	BEGIN_CHOOSE(dsp) {
		BEGIN_KIND(SequenceMapping,other) {
			WPTR(Dsp) 	returnValue;
			returnValue = SequenceMapping::make (myShift - other->shift(), CAST(Sequence,this->inverseOf(other->translation())));
			return returnValue;
		} END_KIND;
	} END_CHOOSE;
	/* compiler fodder */
	return NULL;
}


RPTR(Dsp) SequenceMapping::minus (APTR(Dsp) dsp){
	BEGIN_CHOOSE(dsp) {
		BEGIN_KIND(SequenceMapping,other) {
			WPTR(Dsp) 	returnValue;
			returnValue = SequenceMapping::make (myShift - other->shift(), CAST(Sequence,this->inverseOf(other->translation())));
			return returnValue;
		} END_KIND;
	} END_CHOOSE;
	/* compiler fodder */
	return NULL;
}
/* private: create */


SequenceMapping::SequenceMapping (IntegerVar shift, APTR(Sequence) translation) {
	myShift = shift;
	myTranslation = translation;
}



/* ************************************************************************ *
 * 
 *                    Class SequenceRegion 
 *
 * ************************************************************************ */



/* Initializers for SequenceRegion */

GPTR(SequenceManager) SequenceRegion::TheManager = NULL;
GPTR(SequenceRegion) SequenceRegion::TheEmptySequenceRegion = NULL;
GPTR(SequenceRegion) SequenceRegion::TheFullSequenceRegion = NULL;



BEGIN_INIT_TIME(SequenceRegion,initTimeNonInherited) {
	REQUIRES (EdgeManager);
	CONSTRUCT(SequenceRegion::TheManager,SequenceManager,());
	REQUIRES (Sequence);
	REQUIRES (SequenceSpace);
	REQUIRES (PtrArray);
	CONSTRUCT(SequenceRegion::TheEmptySequenceRegion,SequenceRegion,(FALSE, PtrArray::empty()));
	CONSTRUCT(SequenceRegion::TheFullSequenceRegion,SequenceRegion,(TRUE, PtrArray::empty()));
} END_INIT_TIME(SequenceRegion,initTimeNonInherited);



/* Initializers for SequenceRegion */






/* pseudo constructors */


RPTR(SequenceRegion) SequenceRegion::above (APTR(Sequence) sequence){
	RETURN_CONSTRUCT(SequenceRegion,(FALSE, CAST(PtrArray,PrimSpec::pointer()->arrayWith(BeforeSequence::make (sequence)))));
}


RPTR(SequenceRegion) SequenceRegion::below (APTR(Sequence) sequence){
	RETURN_CONSTRUCT(SequenceRegion,(TRUE, CAST(PtrArray,PrimSpec::pointer()->arrayWith(AfterSequence::make (sequence)))));
}


RPTR(SequenceRegion) SequenceRegion::prefixedBy (APTR(Sequence) sequence, IntegerVar limit){
	/* All sequences matching the given up to and including the 
	number at limit */
	
	RETURN_CONSTRUCT(SequenceRegion,(FALSE, CAST(PtrArray,PrimSpec::pointer()->arrayWithTwo(BeforeSequencePrefix::below(sequence, limit), BeforeSequencePrefix::above(sequence, limit)))));
}


RPTR(SequenceRegion) SequenceRegion::strictlyAbove (APTR(Sequence) sequence){
	RETURN_CONSTRUCT(SequenceRegion,(FALSE, CAST(PtrArray,PrimSpec::pointer()->arrayWith(AfterSequence::make (sequence)))));
}


RPTR(SequenceRegion) SequenceRegion::strictlyBelow (APTR(Sequence) sequence){
	RETURN_CONSTRUCT(SequenceRegion,(TRUE, CAST(PtrArray,PrimSpec::pointer()->arrayWith(BeforeSequence::make (sequence)))));
}
/* private: */


RPTR(SequenceRegion) SequenceRegion::usingx (BooleanVar startsInside, APTR(PtrArray) OF1(TransitionEdge) transitions){
	/* Make a new region, reusing the given array. No one else 
	should ever modify it! */
	
	RETURN_CONSTRUCT(SequenceRegion,(startsInside, transitions));
}
/* constants */
/* Represents a Region of Sequences. We can efficiently represent 
unions of intervals, delimited either by individual sequences or by a 
match with all sequences prefixed by some sequence up to some index. */


/* create */


SequenceRegion::SequenceRegion (BooleanVar startsInside, APTR(PtrArray) OF1(TransitionEdge) transitions) {
	myStartsInside = startsInside;
	myTransitions = transitions;
	myTransitionsCount = transitions->count();
}


SequenceRegion::SequenceRegion (
		BooleanVar startsInside, 
		APTR(PtrArray) OF1(TransitionEdge) transitions, 
		Int32 count) 
{
	myStartsInside = startsInside;
	myTransitions = transitions;
	myTransitionsCount = count;
}
/* accessing */


RPTR(XnRegion) SequenceRegion::asSimpleRegion (){
	WPTR(XnRegion) 	returnValue;
	returnValue = SequenceRegion::TheManager->asSimpleRegion(this);
	return returnValue;
}


RPTR(CoordinateSpace) SequenceRegion::coordinateSpace (){
	WPTR(CoordinateSpace) 	returnValue;
	returnValue = SequenceSpace::make ();
	return returnValue;
}


RPTR(Sequence) SequenceRegion::lowerBound (){
	/* The largest sequence such that all the positions in the 
	region are >= it.  Does not necessarily lie in the region.  
	For example, the region of all numbers > 2.3 has a lowerBound 
	of 2.3. Mathematically, this is called the 'greatest lower bound'. */
	
	return CAST(Sequence,SequenceRegion::TheManager->greatestLowerBound(this));
}


RPTR(Sequence) SequenceRegion::lowerEdge (){
	/* Essential. The Sequence associated with the lower edge of 
	the Region. To find out where the boundary is in relation to 
	this sequence, check lowerEdgeType. BLASTS if unbounded below. */
	
	if (myTransitionsCount == Int32Zero) {
		BLAST(InvalidRequest);
	}
	WPTR(Sequence) 	returnValue;
	returnValue = CAST(SequenceEdge,myTransitions->fetch(Int32Zero))->sequence();
	return returnValue;
}


IntegerVar SequenceRegion::lowerEdgePrefixLimit (){
	/* Essential. If lowerEdgeType is prefix, then it includes an 
	Sequence matching each integer in the lowerEdge up to and 
	including lowerEdgePrefixLimit. */
	
	if (myTransitionsCount == Int32Zero) {
		BLAST(InvalidRequest);
	}
	BEGIN_CHOOSE(myTransitions->fetch(Int32Zero)) {
		BEGIN_KIND(BeforeSequencePrefix,prefix) {
			prefix->limit();
		} END_KIND;
	} END_CHOOSE;
	/* compiler fodder */
	return -1;
}


Int32 SequenceRegion::lowerEdgeType (){
	/* Essential. The kind of Sequence associated with the lower 
	edge of the Region. If SequenceRegion::inclusive then it 
	includes the lowerEdge; if exclusive, then it does not; if 
	prefix, then it includes any Sequence matching each integer 
	in the lowerEdge up to and including lowerEdgePrefixLimit. */
	
	if (myTransitionsCount == Int32Zero) {
		BLAST(InvalidRequest);
	}
	BEGIN_CHOOSE(myTransitions->fetch(Int32Zero)) {
		BEGIN_KIND(BeforeSequence,before) {
			return SequenceRegion::INCLUSIVE();
		} END_KIND;
		BEGIN_KIND(AfterSequence,after) {
			return SequenceRegion::EXCLUSIVE();
		} END_KIND;
		BEGIN_KIND(BeforeSequencePrefix,prefix) {
			return SequenceRegion::PREFIX();
		} END_KIND;
	} END_CHOOSE;
	/* compiler fodder */
	return -1;
}


RPTR(Sequence) SequenceRegion::upperBound (){
	/* The smallest Sequence such that all the positions in the 
	region are <= it.  Does not necessarily lie in the region.  
	For example, the region of all numbers < 2.3 has an 
	upperBound of 2.3. Mathematically, this is called the 'least 
	upper bound'. */
	
	return CAST(Sequence,SequenceRegion::TheManager->leastUpperBound(this));
}


RPTR(Sequence) SequenceRegion::upperEdge (){
	/* Essential. The Sequence associated with the upper edge of 
	the Region. To find out where the boundary is in relation to 
	this sequence, check upperEdgeType. BLASTS if unbounded below. */
	
	if (myTransitionsCount == Int32Zero) {
		BLAST(InvalidRequest);
	}
	WPTR(Sequence) 	returnValue;
	returnValue = CAST(SequenceEdge,myTransitions->fetch(myTransitionsCount - 1))->sequence();
	return returnValue;
}


IntegerVar SequenceRegion::upperEdgePrefixLimit (){
	/* Essential. If upperEdgeType is prefix, then it includes a 
	Sequence matching each integer in the upperEdge up to and 
	including upperEdgePrefixLimit. */
	
	if (myTransitionsCount == Int32Zero) {
		BLAST(InvalidRequest);
	}
	BEGIN_CHOOSE(myTransitions->fetch(myTransitionsCount - 1)) {
		BEGIN_KIND(BeforeSequencePrefix,prefix) {
			prefix->limit();
		} END_KIND;
	} END_CHOOSE;
	/* fodder */
	return IntegerVarZero;
}


Int32 SequenceRegion::upperEdgeType (){
	/* Essential. The kind of Sequence associated with the upper 
	edge of the Region. If SequenceRegion::inclusive then it 
	includes the upperEdge; if exclusive, then it does not; if 
	prefix, then it includes any Sequence matching each integer 
	in the upperEdge up to and including upperEdgePrefixLimit. */
	
	if (myTransitionsCount == Int32Zero) {
		BLAST(InvalidRequest);
	}
	BEGIN_CHOOSE(myTransitions->fetch(Int32Zero)) {
		BEGIN_KIND(BeforeSequence,before) {
			return SequenceRegion::EXCLUSIVE();
		} END_KIND;
		BEGIN_KIND(AfterSequence,after) {
			return SequenceRegion::INCLUSIVE();
		} END_KIND;
		BEGIN_KIND(BeforeSequencePrefix,prefix) {
			return SequenceRegion::PREFIX();
		} END_KIND;
	} END_CHOOSE;
	/* compiler fodder */
	return -1;
}
/* testing */


UInt32 SequenceRegion::actualHashForEqual (){
	return this->getCategory()->hashForEqual() ^ myTransitions->elementsHash(myTransitionsCount) ^ (myStartsInside ? 255 : UInt32Zero);
}


BooleanVar SequenceRegion::hasMember (APTR(Position) position){
	return SequenceRegion::TheManager->hasMember(this, position);
}


BooleanVar SequenceRegion::isEmpty (){
	return SequenceRegion::TheManager->isEmpty(this);
}


BooleanVar SequenceRegion::isEnumerable (APTR(OrderSpec) /* order *//* = NULL*/){
	return this->isFinite();
}


BooleanVar SequenceRegion::isEqual (APTR(Heaper) other){
	BEGIN_CHOOSE(other) {
		BEGIN_KIND(SequenceRegion,region) {
			{	BooleanVar crutch_Flag;
				/* myStartsInside == region->startsInside() && myTransitionsCount == region->secretTransitionsCount() && 
									myTransitions->elementsEqual(Int32Zero, region->secretTransitions(), Int32Zero, myTransitionsCount) */
				
				crutch_Flag = myStartsInside == region->startsInside();
				if(crutch_Flag) {
					crutch_Flag = myTransitionsCount == region->secretTransitionsCount();
					if(crutch_Flag) {
						crutch_Flag = myTransitions->elementsEqual(Int32Zero, region->secretTransitions(), Int32Zero, myTransitionsCount);
					}
				}
				return crutch_Flag;
			}
		} END_KIND;
		BEGIN_OTHERS {
			return FALSE;
		} END_OTHERS;
	} END_CHOOSE;
	/* compiler fodder */
	return FALSE;
}


BooleanVar SequenceRegion::isFinite (){
	return SequenceRegion::TheManager->isFinite(this);
}


BooleanVar SequenceRegion::isFull (){
	return SequenceRegion::TheManager->isFull(this);
}


BooleanVar SequenceRegion::isSimple (){
	return SequenceRegion::TheManager->isSimple(this);
}


BooleanVar SequenceRegion::isSubsetOf (APTR(XnRegion) other){
	return SequenceRegion::TheManager->isSubsetOf(this, other);
}
/* protected: enumerating */


RPTR(Stepper) OF1(Position) SequenceRegion::actualStepper (APTR(OrderSpec) order){
	BLAST(SHOULD_NOT_IMPLEMENT);
	/* fodder */
	return NULL;
}
/* enumerating */


IntegerVar SequenceRegion::count (){
	return SequenceRegion::TheManager->count(this);
}


RPTR(ScruSet) OF1(XnRegion) SequenceRegion::distinctions (){
	WPTR(ScruSet) OF1(XnRegion) 	returnValue;
	returnValue = SequenceRegion::TheManager->distinctions(this);
	return returnValue;
}


RPTR(Stepper) SequenceRegion::simpleRegions (APTR(OrderSpec) order/* = NULL*/){
	WPTR(Stepper) 	returnValue;
	returnValue = SequenceRegion::TheManager->simpleRegions(this, order);
	return returnValue;
}


RPTR(Stepper) OF1(Position) SequenceRegion::stepper (APTR(OrderSpec) order/* = NULL*/){
	if (!this->isFinite()) {
		BLAST(NotEnumerable);
	}
	RETURN_CONSTRUCT(SequenceStepper,(myTransitions, myTransitionsCount));
}
/* operations */


RPTR(XnRegion) SequenceRegion::complement (){
	WPTR(XnRegion) 	returnValue;
	returnValue = SequenceRegion::TheManager->complement(this);
	return returnValue;
}


RPTR(XnRegion) SequenceRegion::intersect (APTR(XnRegion) other){
	WPTR(XnRegion) 	returnValue;
	returnValue = SequenceRegion::TheManager->intersect(this, other);
	return returnValue;
}


RPTR(XnRegion) SequenceRegion::simpleUnion (APTR(XnRegion) other){
	WPTR(XnRegion) 	returnValue;
	returnValue = SequenceRegion::TheManager->simpleUnion(this, other);
	return returnValue;
}


RPTR(XnRegion) SequenceRegion::unionWith (APTR(XnRegion) other){
	WPTR(XnRegion) 	returnValue;
	returnValue = SequenceRegion::TheManager->unionWith(this, other);
	return returnValue;
}


RPTR(XnRegion) SequenceRegion::with (APTR(Position) pos){
	WPTR(XnRegion) 	returnValue;
	returnValue = SequenceRegion::TheManager->with(this, pos);
	return returnValue;
}
/* printing */


void SequenceRegion::printOn (ostream& oo){
	SequenceRegion::TheManager->printRegionOn(this, oo);
}
/* secret */
/* hooks: */


void SequenceRegion::receiveSequenceRegion (APTR(Rcvr) rcvr){
	myTransitions = PtrArray::nulls(myTransitionsCount);
	{
		Int32 LoopFinal = myTransitionsCount;
		Int32 i = Int32Zero;
		for (;;) {
			if (i >= LoopFinal){
				break;
			}
			{
				myTransitions->store(i, rcvr->receiveHeaper());
			}
			i += 1;
		}
	}
}


void SequenceRegion::sendSequenceRegion (APTR(Xmtr) xmtr){
	{
		Int32 LoopFinal = myTransitionsCount;
		Int32 i = Int32Zero;
		for (;;) {
			if (i >= LoopFinal){
				break;
			}
			{
				xmtr->sendHeaper(myTransitions->fetch(i));
			}
			i += 1;
		}
	}
}



/* ************************************************************************ *
 * 
 *                    Class SequenceSpace 
 *
 * ************************************************************************ */



/* Initializers for SequenceSpace */

GPTR(SequenceSpace) SequenceSpace::TheSequenceSpace = NULL;



BEGIN_INIT_TIME(SequenceSpace,initTimeNonInherited) {
	REQUIRES (Sequence);
	CONSTRUCT(SequenceSpace::TheSequenceSpace,SequenceSpace,());
} END_INIT_TIME(SequenceSpace,initTimeNonInherited);



/* Initializers for SequenceSpace */






/* rcvr creation */


RPTR(Heaper) SequenceSpace::make (APTR(Rcvr) rcvr){
	CAST(SpecialistRcvr,rcvr)->registerIbid(SequenceSpace::TheSequenceSpace);
	WPTR(Heaper) 	returnValue;
	returnValue = SequenceSpace::TheSequenceSpace;
	return returnValue;
}
/* creation */
/* The space of all Sequences */


/* create */


SequenceSpace::SequenceSpace () 
	: CoordinateSpace(SequenceRegion::usingx(FALSE, PtrArray::empty())
		, SequenceRegion::usingx(TRUE, PtrArray::empty())
		, SequenceMapping::make (IntegerVarZero, Sequence::zero())
		, SequenceUpOrder::make ()) 
{
	
}
/* temporary */
/* making */


RPTR(SequenceRegion) SequenceSpace::above (APTR(Sequence) sequence, BooleanVar inclusive){
	/* Essential. All sequences >= sequence if inclusive, > 
	sequence if not. */
	
	if (inclusive) {
		WPTR(SequenceRegion) 	returnValue;
		returnValue = SequenceRegion::usingx(FALSE, CAST(PtrArray,PrimSpec::pointer()->arrayWith(BeforeSequence::make (sequence))));
		return returnValue;
	} else {
		WPTR(SequenceRegion) 	returnValue;
		returnValue = SequenceRegion::usingx(FALSE, CAST(PtrArray,PrimSpec::pointer()->arrayWith(AfterSequence::make (sequence))));
		return returnValue;
	}
}


RPTR(SequenceRegion) SequenceSpace::below (APTR(Sequence) sequence, BooleanVar inclusive){
	/* Essential. All sequences <= sequence if inclusive, < 
	sequence if not. */
	
	if (inclusive) {
		WPTR(SequenceRegion) 	returnValue;
		returnValue = SequenceRegion::usingx(TRUE, CAST(PtrArray,PrimSpec::pointer()->arrayWith(AfterSequence::make (sequence))));
		return returnValue;
	} else {
		WPTR(SequenceRegion) 	returnValue;
		returnValue = SequenceRegion::usingx(TRUE, CAST(PtrArray,PrimSpec::pointer()->arrayWith(BeforeSequence::make (sequence))));
		return returnValue;
	}
}


RPTR(SequenceRegion) SequenceSpace::interval (APTR(Sequence) start, APTR(Sequence) stop){
	/* Return a region of all sequence >= lower and < upper. */
	/* Ravi thingToDo. */
	/* use a single constructor */
	/* Performance */
	
	return CAST(SequenceRegion,this->above(start, TRUE)->intersect(this->below(stop, FALSE)));
}


RPTR(SequenceMapping) SequenceSpace::mapping (IntegerVar shift, APTR(Sequence) translation/* = NULL*/){
	/* A transformation which shifts a value by some number of 
	places and then adds a translation to it. */
	
	/* Thing to do !!!! */
	
	/* better name for this method */
	if (translation == NULL) {
		WPTR(SequenceMapping) 	returnValue;
		returnValue = SequenceMapping::make (shift, Sequence::zero());
		return returnValue;
	}
	WPTR(SequenceMapping) 	returnValue;
	returnValue = SequenceMapping::make (shift, translation);
	return returnValue;
}


RPTR(Sequence) SequenceSpace::position (APTR(PrimArray) arg, IntegerVar shift){
	/* Essential. A sequence using the given numbers and shift. 
	Leading and trailing zeros will be stripped, and a copy will 
	be made so that noone modifies it */
	/* IntegerVars cannot have default arguments */
	
	SPTR(PrimIntegerArray) numbers;
	
	numbers = CAST(PrimIntegerArray,arg);
	if (numbers == NULL) {
		WPTR(Sequence) 	returnValue;
		returnValue = Sequence::usingx(shift, IntegerVarArray::zeros(Int32Zero));
		return returnValue;
	}
	WPTR(Sequence) 	returnValue;
	returnValue = Sequence::usingx(shift, CAST(PrimIntegerArray,numbers->copy()));
	return returnValue;
}


RPTR(SequenceRegion) SequenceSpace::prefixedBy (APTR(Sequence) sequence, IntegerVar limit){
	/* Essential. All sequences which match the given one up to 
	and including the given index. */
	
	WPTR(SequenceRegion) 	returnValue;
	returnValue = SequenceRegion::usingx(FALSE, CAST(PtrArray,PrimSpec::pointer()->arrayWithTwo(BeforeSequencePrefix::below(sequence, limit), BeforeSequencePrefix::above(sequence, limit))));
	return returnValue;
}
/* testing */


UInt32 SequenceSpace::actualHashForEqual (){
	/* is equal to any basic space on the same category of positions */
	
	return this->getCategory()->hashForEqual() + 1;
}


BooleanVar SequenceSpace::isEqual (APTR(Heaper) anObject){
	/* is equal to any basic space on the same category of positions */
	
	return anObject->getCategory() == this->getCategory();
}



/* ************************************************************************ *
 * 
 *                    Class SequenceEdge 
 *
 * ************************************************************************ */


/* testing */


UInt32 SequenceEdge::actualHashForEqual (){
	return this->sequence()->hashForEqual() ^ this->getCategory()->hashForEqual();
}
/* accessing */


RPTR(Sequence) SequenceEdge::sequence (){
	return (Sequence*) mySequence;
}
/* printing */


void SequenceEdge::printOn (ostream& oo){
	oo << this->getCategory()->name() << "(" << mySequence << ")";
}
/* create */


SequenceEdge::SequenceEdge (APTR(Sequence) sequence, TCSJ) {
	mySequence = sequence;
}



/* ************************************************************************ *
 * 
 *                    Class   AfterSequence 
 *
 * ************************************************************************ */


/* pseudo constructors */


RPTR(SequenceEdge) AfterSequence::make (APTR(Sequence) sequence){
	RETURN_CONSTRUCT(AfterSequence,(sequence, tcsj));
}
/* accessing */


RPTR(Position) AfterSequence::position (){
	WPTR(Position) 	returnValue;
	returnValue = this->sequence();
	return returnValue;
}


RPTR(SequenceEdge) AfterSequence::transformedBy (APTR(SequenceMapping) dsp){
	WPTR(SequenceEdge) 	returnValue;
	returnValue = AfterSequence::make (CAST(Sequence,dsp->of(this->sequence())));
	return returnValue;
}
/* create */


AfterSequence::AfterSequence (APTR(Sequence) sequence, TCSJ) 
	: SequenceEdge(sequence, tcsj) {
	
}
/* printing */


void AfterSequence::printTransitionOn (
		ostream& oo, 
		BooleanVar entering, 
		BooleanVar touchesPrevious)
{
	oo << " ";
	if (entering) {
		oo << "(";
	}
	{	BooleanVar crutch_Flag;
		/* touchesPrevious && !entering */
		
		crutch_Flag = touchesPrevious;
		if(crutch_Flag) {
			crutch_Flag = !entering;
		}
		if (!crutch_Flag) {
			oo << this->sequence();
		}
	}
	if (!entering) {
		oo << "]";
	}
}
/* comparing */


BooleanVar AfterSequence::follows (APTR(Position) pos){
	return this->sequence()->isGE(CAST(Sequence,pos));
}


BooleanVar AfterSequence::isEqual (APTR(Heaper) other){
	BEGIN_CHOOSE(other) {
		BEGIN_KIND(AfterSequence,after) {
			return after->sequence()->isEqual(this->sequence());
		} END_KIND;
		BEGIN_OTHERS {
			return FALSE;
		} END_OTHERS;
	} END_CHOOSE;
	/* compiler fodder */
	return FALSE;
}


BooleanVar AfterSequence::isFollowedBy (APTR(TransitionEdge) /* next */){
	return FALSE;
}


BooleanVar AfterSequence::isGE (APTR(TransitionEdge) other){
	BEGIN_CHOOSE(other) {
		BEGIN_KIND(BeforeSequencePrefix,prefix) {
			return this->sequence()->comparePrefix(prefix->sequence(), prefix->limit()) >= Int32Zero;
		} END_KIND;
		BEGIN_KIND(SequenceEdge,edge) {
			return this->sequence()->isGE(edge->sequence());
		} END_KIND;
	} END_CHOOSE;
	/* compiler fodder */
	return FALSE;
}


BooleanVar AfterSequence::touches (APTR(TransitionEdge) other){
	BEGIN_CHOOSE(other) {
		BEGIN_KIND(BeforeSequencePrefix,prefix) {
			return FALSE;
		} END_KIND;
		BEGIN_KIND(SequenceEdge,edge) {
			return this->sequence()->isEqual(edge->sequence());
		} END_KIND;
	} END_CHOOSE;
	/* compiler fodder */
	return FALSE;
}



/* ************************************************************************ *
 * 
 *                    Class   BeforeSequence 
 *
 * ************************************************************************ */


/* pseudo constructors */


RPTR(SequenceEdge) BeforeSequence::make (APTR(Sequence) sequence){
	RETURN_CONSTRUCT(BeforeSequence,(sequence, tcsj));
}
/* comparing */


BooleanVar BeforeSequence::follows (APTR(Position) pos){
	return !CAST(Sequence,pos)->isGE(this->sequence());
}


BooleanVar BeforeSequence::isEqual (APTR(Heaper) other){
	BEGIN_CHOOSE(other) {
		BEGIN_KIND(BeforeSequence,before) {
			return before->sequence()->isEqual(this->sequence());
		} END_KIND;
		BEGIN_OTHERS {
			return FALSE;
		} END_OTHERS;
	} END_CHOOSE;
	/* compiler fodder */
	return FALSE;
}


BooleanVar BeforeSequence::isFollowedBy (APTR(TransitionEdge) next){
	BEGIN_CHOOSE(next) {
		BEGIN_KIND(AfterSequence,after) {
			return this->sequence()->isEqual(after->sequence());
		} END_KIND;
		BEGIN_OTHERS {
			return FALSE;
		} END_OTHERS;
	} END_CHOOSE;
	/* compiler fodder */
	return FALSE;
}


BooleanVar BeforeSequence::isGE (APTR(TransitionEdge) other){
	BEGIN_CHOOSE(other) {
		BEGIN_KIND(BeforeSequencePrefix,prefix) {
			return this->sequence()->comparePrefix(prefix->sequence(), prefix->limit()) >= Int32Zero;
		} END_KIND;
		BEGIN_KIND(BeforeSequence,before) {
			return this->sequence()->isGE(before->sequence());
		} END_KIND;
		BEGIN_KIND(AfterSequence,after) {
			return !after->sequence()->isGE(this->sequence());
		} END_KIND;
	} END_CHOOSE;
	/* compiler fodder */
	return FALSE;
}


BooleanVar BeforeSequence::touches (APTR(TransitionEdge) other){
	BEGIN_CHOOSE(other) {
		BEGIN_KIND(BeforeSequencePrefix,prefix) {
			return FALSE;
		} END_KIND;
		BEGIN_KIND(SequenceEdge,edge) {
			return this->sequence()->isEqual(edge->sequence());
		} END_KIND;
	} END_CHOOSE;
	/* compiler fodder */
	return FALSE;
}
/* accessing */


RPTR(Position) BeforeSequence::position (){
	WPTR(Position) 	returnValue;
	returnValue = this->sequence();
	return returnValue;
}


RPTR(SequenceEdge) BeforeSequence::transformedBy (APTR(SequenceMapping) dsp){
	WPTR(SequenceEdge) 	returnValue;
	returnValue = BeforeSequence::make (CAST(Sequence,dsp->of(this->sequence())));
	return returnValue;
}
/* create */


BeforeSequence::BeforeSequence (APTR(Sequence) sequence, TCSJ) 
	: SequenceEdge(sequence, tcsj) {
	
}
/* printing */


void BeforeSequence::printTransitionOn (
		ostream& oo, 
		BooleanVar entering, 
		BooleanVar touchesPrevious)
{
	oo << " ";
	if (entering) {
		oo << "[";
	}
	{	BooleanVar crutch_Flag;
		/* touchesPrevious && !entering */
		
		crutch_Flag = touchesPrevious;
		if(crutch_Flag) {
			crutch_Flag = !entering;
		}
		if (!crutch_Flag) {
			oo << this->sequence();
		}
	}
	if (!entering) {
		oo << ")";
	}
}



/* ************************************************************************ *
 * 
 *                    Class   BeforeSequencePrefix 
 *
 * ************************************************************************ */


/* pseudo constructors */


RPTR(TransitionEdge) BeforeSequencePrefix::above (APTR(Sequence) sequence, IntegerVar limit){
	if (limit < sequence->shift()) {
		RETURN_CONSTRUCT(BeforeSequencePrefix,(Sequence::usingx(limit, CAST(PrimIntegerArray,PrimSpec::integerVar()->arrayWith(PrimSpec::integerVar()->value(1)))), limit));
	}
	if (limit < sequence->shift() + sequence->count()) {
		Int32 newCount;
		Int32 hisCount;
		
		newCount = (limit - sequence->shift() + 1).asLong();
		hisCount = sequence->secretNumbers()->count();
		RETURN_CONSTRUCT(BeforeSequencePrefix,(Sequence::usingx(sequence->shift(), 
					CAST(PrimIntegerArray,sequence->secretNumbers()->copy(min(newCount, hisCount), Int32Zero, Int32Zero, max(newCount - hisCount, Int32Zero)))->hold((limit - sequence->shift()).asLong(), sequence->integerAt(limit) + 1, TRUE)), limit));
	}
	/* Ravi knownBug. */
	/* creates huge arrays if (limit - sequence shift) is too big */
	RETURN_CONSTRUCT(BeforeSequencePrefix,(Sequence::usingx(sequence->shift(), sequence->secretNumbers()->hold((limit - sequence->shift()).asLong(), sequence->integerAt(limit) + 1)), limit));
}


RPTR(TransitionEdge) BeforeSequencePrefix::below (APTR(Sequence) sequence, IntegerVar limit){
	if (limit < sequence->shift()) {
		RETURN_CONSTRUCT(BeforeSequencePrefix,(Sequence::zero(), limit));
	}
	if (limit < sequence->shift() + sequence->count()) {
		Int32 newCount;
		Int32 hisCount;
		
		newCount = (limit - sequence->shift() + 1).asLong();
		hisCount = sequence->secretNumbers()->count();
		RETURN_CONSTRUCT(BeforeSequencePrefix,(Sequence::usingx(sequence->shift(), CAST(PrimIntegerArray,sequence->secretNumbers()->copy(min(newCount, hisCount), Int32Zero, Int32Zero, max(newCount - hisCount, Int32Zero)))), limit));
	}
	RETURN_CONSTRUCT(BeforeSequencePrefix,(sequence, limit));
}
/* comparing */


BooleanVar BeforeSequencePrefix::follows (APTR(Position) pos){
	{	BooleanVar crutch_Flag;
		/* !this->sequence()->isEqual(CAST(Sequence,pos)) && this->sequence()->isGE(pos) */
		
		crutch_Flag = !this->sequence()->isEqual(CAST(Sequence,pos));
		if(crutch_Flag) {
			crutch_Flag = this->sequence()->isGE(pos);
		}
		return crutch_Flag;
	}
}


BooleanVar BeforeSequencePrefix::isEqual (APTR(Heaper) other){
	BEGIN_CHOOSE(other) {
		BEGIN_KIND(BeforeSequencePrefix,prefix) {
			{	BooleanVar crutch_Flag;
				/* myLimit == prefix->limit() && prefix->sequence()->isEqual(this->sequence()) */
				
				crutch_Flag = myLimit == prefix->limit();
				if(crutch_Flag) {
					crutch_Flag = prefix->sequence()->isEqual(this->sequence());
				}
				return crutch_Flag;
			}
		} END_KIND;
		BEGIN_OTHERS {
			return FALSE;
		} END_OTHERS;
	} END_CHOOSE;
	/* compiler fodder */
	return FALSE;
}


BooleanVar BeforeSequencePrefix::isFollowedBy (APTR(TransitionEdge) /* next */){
	return FALSE;
}


BooleanVar BeforeSequencePrefix::isGE (APTR(TransitionEdge) other){
	Int32 diff;
	
	BEGIN_CHOOSE(other) {
		BEGIN_KIND(BeforeSequencePrefix,prefix) {
			diff = this->sequence()->comparePrefix(prefix->sequence(), min(myLimit, prefix->limit()));
			if (diff != Int32Zero) {
				return diff > Int32Zero;
			}
			return myLimit >= prefix->limit();
		} END_KIND;
		BEGIN_KIND(SequenceEdge,before) {
			return this->sequence()->comparePrefix(before->sequence(), myLimit) > Int32Zero;
		} END_KIND;
	} END_CHOOSE;
	/* compiler fodder */
	return FALSE;
}


BooleanVar BeforeSequencePrefix::touches (APTR(TransitionEdge) other){
	BEGIN_CHOOSE(other) {
		BEGIN_KIND(BeforeSequencePrefix,before) {
			{	BooleanVar crutch_Flag;
				/* myLimit == before->limit() && this->sequence()->comparePrefix(before->sequence(), myLimit - 1) == Int32Zero && abs(this->sequence()->integerAt(myLimit) - before->sequence()->integerAt(myLimit)) <= 1 */
				
				crutch_Flag = myLimit == before->limit();
				if(crutch_Flag) {
					crutch_Flag = this->sequence()->comparePrefix(before->sequence(), myLimit - 1) == Int32Zero;
					if(crutch_Flag) {
						crutch_Flag = abs(this->sequence()->integerAt(myLimit) - before->sequence()->integerAt(myLimit)) <= 1;
					}
				}
				return crutch_Flag;
			}
		} END_KIND;
		BEGIN_OTHERS {
			return FALSE;
		} END_OTHERS;
	} END_CHOOSE;
	/* compiler fodder */
	return FALSE;
}
/* accessing */


IntegerVar BeforeSequencePrefix::limit (){
	return myLimit;
}


RPTR(Position) BeforeSequencePrefix::position (){
	BLAST(NotInSpace);
	/* fodder */
	return NULL;
}


RPTR(SequenceEdge) BeforeSequencePrefix::transformedBy (APTR(SequenceMapping) dsp){
	RETURN_CONSTRUCT(BeforeSequencePrefix,(CAST(Sequence,dsp->of(this->sequence())), myLimit + dsp->shift()));
}
/* create */


BeforeSequencePrefix::BeforeSequencePrefix (APTR(Sequence) sequence, IntegerVar limit) 
	: SequenceEdge(sequence, tcsj) {
	myLimit = limit;
}
/* printing */


void BeforeSequencePrefix::printOn (ostream& oo){
	oo << this->getCategory()->name() << "(" << myLimit << ", " << this->sequence() << ")";
}


void BeforeSequencePrefix::printTransitionOn (
		ostream& oo, 
		BooleanVar entering, 
		BooleanVar touchesPrevious)
{
	oo << " ";
	if (entering) {
		oo << "(";
	}
	{	BooleanVar crutch_Flag;
		/* touchesPrevious && !entering */
		
		crutch_Flag = touchesPrevious;
		if(crutch_Flag) {
			crutch_Flag = !entering;
		}
		if (!crutch_Flag) {
			/* Ravi -- Thing to do !!!! */
			
			/* Eliminate strings of zeros / stars, print 
				UInt8Arrays as strings */
			{
				IntegerVar LoopFinal = max(myLimit + 1, IntegerVarZero);
				IntegerVar i = min(IntegerVarZero, this->sequence()->shift());
				for (;;) {
					if (i > LoopFinal){
						break;
					}
					{
						if (i == IntegerVarZero) {
							oo << "!";
						} else {
							if (i != this->sequence()->shift()) {
								oo << ".";
							}
						}
						{	BooleanVar crutch_Flag;
							/* i == myLimit && !entering */
							
							crutch_Flag = i == myLimit;
							if(crutch_Flag) {
								crutch_Flag = !entering;
							}
							if (crutch_Flag) {
								oo << this->sequence()->integerAt(i) - 1;
							} else {
								if (i <= myLimit) {
									oo << this->sequence()->integerAt(i);
								} else {
									oo << "*";
								}
							}
						}
					}
					i += 1;
				}
			}
		}
	}
	if (!entering) {
		oo << ")";
	}
}



/* ************************************************************************ *
 * 
 *                    Class SequenceManager 
 *
 * ************************************************************************ */


/* Specialized object for managing TumblerSpace objects. Is a type so 
that inlining could potentially be used. */


/* protected: */


RPTR(Position) SequenceManager::edgePosition (APTR(TransitionEdge) edge){
	WPTR(Position) 	returnValue;
	returnValue = CAST(SequenceEdge,edge)->sequence();
	return returnValue;
}


RPTR(XnRegion) SequenceManager::makeNew (BooleanVar startsInside, APTR(PtrArray) OF1(TransitionEdge) transitions){
	WPTR(XnRegion) 	returnValue;
	returnValue = this->makeNew(startsInside, transitions, transitions->count());
	return returnValue;
}


RPTR(XnRegion) SequenceManager::makeNew (
		BooleanVar startsInside, 
		APTR(PtrArray) OF1(TransitionEdge) transitions, 
		Int32 count)
{
	RETURN_CONSTRUCT(SequenceRegion,(startsInside, transitions, count));
}


RPTR(PtrArray) OF1(TransitionEdge) SequenceManager::posTransitions (APTR(Position) pos){
	return CAST(PtrArray,PrimSpec::pointer()->arrayWithTwo(BeforeSequence::make (CAST(Sequence,pos)), AfterSequence::make (CAST(Sequence,pos))));
}


BooleanVar SequenceManager::startsInside (APTR(XnRegion) region){
	return CAST(SequenceRegion,region)->startsInside();
}


RPTR(PtrArray) OF1(TransitionEdge) SequenceManager::transitions (APTR(XnRegion) region){
	WPTR(PtrArray) OF1(TransitionEdge) 	returnValue;
	returnValue = CAST(SequenceRegion,region)->secretTransitions();
	return returnValue;
}


Int32 SequenceManager::transitionsCount (APTR(XnRegion) region){
	return CAST(SequenceRegion,region)->secretTransitionsCount();
}

	/* automatic 0-argument constructor */
SequenceManager::SequenceManager() {}



/* ************************************************************************ *
 * 
 *                    Class SequenceStepper 
 *
 * ************************************************************************ */


/* operations */


WPTR(Heaper) SequenceStepper::fetch (){
	if (myIndex < myTransitionsCount) {
		WPTR(Heaper) 	returnValue;
		returnValue = CAST(SequenceEdge,myTransitions->fetch(myIndex))->sequence();
		return returnValue;
	} else {
		return NULL;
	}
}


BooleanVar SequenceStepper::hasValue (){
	return myIndex < myTransitionsCount;
}


void SequenceStepper::step (){
	myIndex += 2;
}
/* create */


RPTR(Stepper) SequenceStepper::copy (){
	RETURN_CONSTRUCT(SequenceStepper,(myIndex, myTransitions, myTransitionsCount));
}


SequenceStepper::SequenceStepper (APTR(PtrArray) OF1(IDEdge) transitions, Int32 count) {
	myIndex = Int32Zero;
	myTransitions = transitions;
	myTransitionsCount = count;
}


SequenceStepper::SequenceStepper (
		Int32 index, 
		APTR(PtrArray) OF1(IDEdge) transitions, 
		Int32 count) 
{
	myIndex = index;
	myTransitions = transitions;
	myTransitionsCount = count;
}



/* ************************************************************************ *
 * 
 *                    Class SequenceUpOrder 
 *
 * ************************************************************************ */


/* pseudo constructors */


RPTR(OrderSpec) SequenceUpOrder::make (){
	RETURN_CONSTRUCT(SequenceUpOrder,());
}
/* testing */


UInt32 SequenceUpOrder::actualHashForEqual (){
	return this->getCategory()->hashForEqual();
}


BooleanVar SequenceUpOrder::follows (APTR(Position) x, APTR(Position) y){
	return CAST(Sequence,x)->secretNumbers()->compare(CAST(Sequence,y)->secretNumbers()) >= Int32Zero;
}


BooleanVar SequenceUpOrder::isEqual (APTR(Heaper) other){
	return other->isKindOf(cat_SequenceUpOrder);
}


BooleanVar SequenceUpOrder::isFullOrder (APTR(XnRegion) /* keys *//* = NULL*/){
	return TRUE;
}


BooleanVar SequenceUpOrder::preceeds (APTR(XnRegion) before, APTR(XnRegion) after){
	SPTR(SequenceRegion) first;
	SPTR(SequenceRegion) second;
	
	first = CAST(SequenceRegion,before);
	second = CAST(SequenceRegion,after);
	if (!first->isBoundedBelow()) {
		return TRUE;
	}
	if (!second->isBoundedBelow()) {
		return FALSE;
	}
	return !CAST(SequenceEdge,first->secretTransitions()->fetch(Int32Zero))->isGE(CAST(SequenceEdge,second->secretTransitions()->fetch(Int32Zero)));
}
/* accessing */


RPTR(Arrangement) SequenceUpOrder::arrange (APTR(XnRegion) region){
	SPTR(Stepper) stepper;
	SPTR(PtrArray) array;
	
	if (!region->isFinite()) {
		BLAST(MustBeFinite);
	}
	stepper = CAST(SequenceRegion,region)->stepper();
	array = CAST(PtrArray,stepper->stepMany());
	if (!stepper->atEnd()) {
		BLAST(NOT_YET_IMPLEMENTED);
	}
	WPTR(Arrangement) 	returnValue;
	returnValue = ExplicitArrangement::make (array);
	return returnValue;
}


RPTR(CoordinateSpace) SequenceUpOrder::coordinateSpace (){
	WPTR(CoordinateSpace) 	returnValue;
	returnValue = SequenceSpace::make ();
	return returnValue;
}

	/* automatic 0-argument constructor */
SequenceUpOrder::SequenceUpOrder() {}

#ifndef SEQUENCX_SXX
#include "sequencx.sxx"
#endif /* SEQUENCX_SXX */


#ifndef SEQUENCP_SXX
#include "sequencp.sxx"
#endif /* SEQUENCP_SXX */



#endif /* SEQUENCX_CXX */

