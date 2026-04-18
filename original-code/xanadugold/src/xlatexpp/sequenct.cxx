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

#ifndef SEQUENCT_CXX
#define SEQUENCT_CXX


#ifndef CHOOSEX_HXX
#include "choosex.hxx"
#endif /* CHOOSEX_HXX */

#ifndef SEQUENCT_HXX
#include "sequenct.hxx"
#endif /* SEQUENCT_HXX */

#ifndef SEQUENCT_IXX
#include "sequenct.ixx"
#endif /* SEQUENCT_IXX */


#ifndef PARRAYX_HXX
#include "parrayx.hxx"
#endif /* PARRAYX_HXX */

#ifndef PRIMVALX_HXX
#include "primvalx.hxx"
#endif /* PRIMVALX_HXX */

#ifndef SETX_HXX
#include "setx.hxx"
#endif /* SETX_HXX */




/* ************************************************************************ *
 * 
 *                    Class SequenceTester 
 *
 * ************************************************************************ */


/* init */


RPTR(ImmuSet) OF1(XnRegion) SequenceTester::initExamples (){
	SPTR(SetAccumulator) sequences;
	SPTR(SetAccumulator) result;
	SPTR(ImmuSet) base;
	
	sequences = SetAccumulator::make ();
	sequences->step(Sequence::zero());
	sequences->step(Sequence::one(1));
	sequences->step(Sequence::two(1, 2));
	sequences->step(Sequence::two(1, -2));
	BEGIN_FOR_EACH(Sequence,tum,(CAST(ImmuSet,sequences->value())->stepper())) {
		sequences->step(tum->shift(2));
		sequences->step(tum->shift(-2));
	} END_FOR_EACH;
	result = SetAccumulator::make ();
	BEGIN_FOR_EACH(Sequence,sequence,(CAST(ScruSet,sequences->value())->stepper())) {
		result->step(SequenceSpace::make ()->prefixedBy(sequence, sequence->shift() + sequence->count()));
		result->step(SequenceSpace::make ()->prefixedBy(sequence, sequence->shift() + sequence->count())->complement());
		result->step(SequenceSpace::make ()->above(sequence, TRUE));
		result->step(SequenceSpace::make ()->above(sequence, FALSE));
		result->step(SequenceSpace::make ()->below(sequence, TRUE));
		result->step(SequenceSpace::make ()->below(sequence, FALSE));
	} END_FOR_EACH;
	base = CAST(ImmuSet,result->value());
	BEGIN_FOR_EACH(SequenceRegion,r,(base->stepper())) {
		BEGIN_FOR_EACH(SequenceRegion,r2,(base->stepper())) {
			if (r->hashForEqual() < r2->hashForEqual()) {
				result->step(r->unionWith(r2));
				result->step(r->intersect(r2));
			}
		} END_FOR_EACH;
	} END_FOR_EACH;
	return CAST(ImmuSet,result->value());
}
/* testing */


void SequenceTester::testExtraOn (ostream& oo){
	SPTR(Sequence) withLeadingZeros;
	SPTR(Sequence) withoutLeadingZeros;
	SPTR(Sequence) withTrailingZeros;
	SPTR(Sequence) withoutTrailingZeros;
	
	withLeadingZeros = Sequence::numbers(CAST(PrimIntegerArray,PrimSpec::integerVar()->arrayWithThree(PrimSpec::integerVar()->value(IntegerVarZero), PrimSpec::integerVar()->value(2), PrimSpec::integerVar()->value(5))));
	withoutLeadingZeros = Sequence::numbers(CAST(PrimIntegerArray,PrimSpec::integerVar()->arrayWithTwo(PrimSpec::integerVar()->value(2), PrimSpec::integerVar()->value(5))))->shift(1);
	if (withLeadingZeros->hashForEqual() == withoutLeadingZeros->hashForEqual()) {
		oo << "Sequence::numbers() correctly counts leading zeros";
	} else {
		oo << "Sequence::numbers() misses leading zeros";
	}
	oo << "\n";
	withTrailingZeros = Sequence::numbers(CAST(PrimIntegerArray,PrimSpec::integerVar()->arrayWithThree(PrimSpec::integerVar()->value(5), PrimSpec::integerVar()->value(2), PrimSpec::integerVar()->value(IntegerVarZero))));
	CONSTRUCT(withoutTrailingZeros,Sequence,(IntegerVarZero, CAST(PrimIntegerArray,PrimSpec::integerVar()->arrayWithTwo(PrimSpec::integerVar()->value(5), PrimSpec::integerVar()->value(2)))));
	if (withTrailingZeros->hashForEqual() == withoutTrailingZeros->hashForEqual()) {
		oo << "Sequence::numbers() correctly counts trailing zeros";
	} else {
		oo << "Sequence::numbers() misses trailing zeros";
	}
	oo << "\n";
}

	/* automatic 0-argument constructor */
SequenceTester::SequenceTester() {}

#ifndef SEQUENCT_SXX
#include "sequenct.sxx"
#endif /* SEQUENCT_SXX */



#endif /* SEQUENCT_CXX */

