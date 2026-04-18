'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:01:57 pm'!

RegionTester subclass: #SequenceTester
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Spaces-Basic'!

(SequenceTester getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #(COPY boot ); yourself)!

!SequenceTester methodsFor: 'init'!

{ImmuSet of: XnRegion} initExamples
	| sequences {SetAccumulator} result {SetAccumulator} base {ImmuSet} |
	sequences := SetAccumulator make.
	sequences step: (Sequence zero).
	sequences step: (Sequence one: 1).
	sequences step: (Sequence two: 1 with: 2).
	sequences step: (Sequence two: 1 with: -2).
	(sequences value cast: ImmuSet) stepper forEach: [ :tum {Sequence} |
		sequences step: (tum shift: 2).
		sequences step: (tum shift: -2)].
	result := SetAccumulator make.
	(sequences value cast: ScruSet) stepper forEach: [ :sequence {Sequence} |
		result step: (SequenceSpace make prefixedBy: sequence
			with: sequence shift + sequence count).
		result step: (SequenceSpace make prefixedBy: sequence
			with: sequence shift + sequence count) complement.
		result step: (SequenceSpace make above: sequence with: true).
		result step: (SequenceSpace make above: sequence with: false).
		result step: (SequenceSpace make below: sequence with: true).
		result step: (SequenceSpace make below: sequence with: false)].
	base := result value cast: ImmuSet.
	base stepper forEach: [ :r {SequenceRegion} |
		base stepper forEach: [ :r2 {SequenceRegion} |
			r hashForEqual < r2 hashForEqual ifTrue:
				[result step: (r unionWith: r2).
				result step: (r intersect: r2)]]].
	^result value cast: ImmuSet! !

!SequenceTester methodsFor: 'testing'!

{void} testExtraOn: oo {ostream reference}
	| withLeadingZeros {Sequence} withoutLeadingZeros {Sequence} withTrailingZeros {Sequence} withoutTrailingZeros {Sequence} |
	withLeadingZeros _ Sequence numbers: ((PrimSpec integerVar arrayWithThree: (PrimSpec integerVar value: IntegerVarZero)
		  										 with: (PrimSpec integerVar value: 2) 
		  										 with: (PrimSpec integerVar value: 5)) cast: PrimIntegerArray).  
	withoutLeadingZeros _ (Sequence numbers: ((PrimSpec integerVar arrayWithTwo: (PrimSpec integerVar value: 2) 
		  										 with: (PrimSpec integerVar value: 5)) cast: PrimIntegerArray)) shift: 1.
	(withLeadingZeros hashForEqual == withoutLeadingZeros hashForEqual)
		ifFalse: [oo << 'Sequence::numbers() misses leading zeros']
		ifTrue: [oo << 'Sequence::numbers() correctly counts leading zeros'].

	oo << '
'.

	withTrailingZeros _ Sequence numbers: ((PrimSpec integerVar arrayWithThree: (PrimSpec integerVar value: 5)
		  										 with: (PrimSpec integerVar value: 2) 
		  										 with: (PrimSpec integerVar value: IntegerVarZero)) cast: PrimIntegerArray).  
	withoutTrailingZeros _ (Sequence create: IntegerVarZero
		    with:  ((PrimSpec integerVar arrayWithTwo: (PrimSpec integerVar value: 5) 
		  										 with: (PrimSpec integerVar value: 2)) cast: PrimIntegerArray)).
	(withTrailingZeros hashForEqual == withoutTrailingZeros hashForEqual)
		ifFalse: [oo << 'Sequence::numbers() misses trailing zeros'.]
		ifTrue: [oo << 'Sequence::numbers() correctly counts trailing zeros'.].
	oo << '
'.! !

!SequenceTester methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

SequenceTester class
	instanceVariableNames: ''!

(SequenceTester getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #(COPY boot ); yourself)!