'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:07:57 pm'!

CoordinateSpace subclass: #SequenceSpace
	instanceVariableNames: ''
	classVariableNames: 'TheSequenceSpace {SequenceSpace} '
	poolDictionaries: ''
	category: 'Xanadu-tumbler'!
SequenceSpace comment:
'The space of all Sequences'!

(SequenceSpace getOrMakeCxxClassDescription)
	friends:
'/* friends for class SequenceSpace */

friend class Sequence;
';
	attributes: ((Set new) add: #PSEUDO.COPY; add: #CONCRETE; add: #ON.CLIENT; yourself)!

!SequenceSpace methodsFor: 'create'!

create
	
	super create: (SequenceRegion using: false with: PtrArray empty)
		with: (SequenceRegion using: true with: PtrArray empty)
		with: (SequenceMapping make: IntegerVarZero with: Sequence zero)
		with: SequenceUpOrder make! !

!SequenceSpace methodsFor: 'temporary'!

{Sequence CLIENT login INLINE} position: numbers {PrimArray}

	^self position: numbers with: IntegerVarZero! !

!SequenceSpace methodsFor: 'making'!

{SequenceRegion CLIENT} above: sequence {Sequence} with: inclusive {BooleanVar}
	"Essential. All sequences >= sequence if inclusive, > sequence if not."
	
	inclusive ifTrue:
		[^SequenceRegion using: false
			with: ((PrimSpec pointer arrayWith: (BeforeSequence make: sequence)) cast: PtrArray)]
	ifFalse:
		[^SequenceRegion using: false
			with: ((PrimSpec pointer arrayWith: (AfterSequence make: sequence)) cast: PtrArray)]!

{SequenceRegion CLIENT} below: sequence {Sequence} with: inclusive {BooleanVar}
	"Essential. All sequences <= sequence if inclusive, < sequence if not."
	
	inclusive ifTrue:
		[^SequenceRegion using: true
			with: ((PrimSpec pointer arrayWith: (AfterSequence make: sequence)) cast: PtrArray)]
	ifFalse:
		[^SequenceRegion using: true
			with: ((PrimSpec pointer arrayWith: (BeforeSequence make: sequence)) cast: PtrArray)]!

{SequenceRegion CLIENT} interval: start {Sequence} with: stop {Sequence}
	"Return a region of all sequence >= lower and < upper."
	
	"Ravi thingToDo." "use a single constructor" "Performance"
	^((self above: start with: true)
		intersect: (self below: stop with: false)) cast: SequenceRegion!

{SequenceMapping CLIENT} mapping: shift {IntegerVar}
	with: translation {Sequence default: NULL}
	"A transformation which shifts a value by some number of places and then adds a translation to it."
	
	self thingToDo. "better name for this method"
	translation == NULL ifTrue:
		[^SequenceMapping make: shift with: Sequence zero].
	^SequenceMapping make: shift with: translation!

{Sequence CLIENT login} position: arg {PrimArray}
	with: shift {IntegerVar}
	"Essential. A sequence using the given numbers and shift. Leading and trailing zeros will be stripped, and a copy will be made so that noone modifies it"
	"IntegerVars cannot have default arguments"
	
	| numbers {PrimIntegerArray} |
	numbers _ arg cast: PrimIntegerArray.
	numbers == NULL ifTrue:
		[^Sequence using: shift with: (IntegerVarArray zeros: Int32Zero)].
	^Sequence using: shift with: (numbers copy cast: PrimIntegerArray)!

{SequenceRegion CLIENT} prefixedBy: sequence {Sequence}
	with: limit {IntegerVar}
	"Essential. All sequences which match the given one up to and including the given index."
	
	^SequenceRegion using: false
		with: ((PrimSpec pointer
			arrayWithTwo: (BeforeSequencePrefix below: sequence with: limit)
			with: (BeforeSequencePrefix above: sequence with: limit)) cast: PtrArray)! !

!SequenceSpace methodsFor: 'smalltalk: passe'!

{Sequence} sequence: numbers {PrimIntegerArray | NULL}
	with: shift {IntegerVar | IntegerVarZero}

	self passe "position"!

{SequenceRegion} sequencesAfter: sequence {Sequence}
	"Essential. All sequences greater than or equal to the given sequence.
	Should this just be supplanted by CoordinateSpace::region ()?"
	self passe.
	^SequenceRegion using: false
		with: (PrimSpec pointer arrayWith: (BeforeSequence make: sequence))!

{SequenceRegion} sequencesBefore: sequence {Sequence}
	"Essential. All sequences less than or equal to the given sequence.
	Should this just be supplanted by CoordinateSpace::region ()?"
	
	self passe.
	^SequenceRegion using: true
		with: (PrimSpec pointer arrayWith: (AfterSequence make: sequence))!

{SequenceRegion} sequencesPrefixedBy: sequence {Sequence}
	with: limit {IntegerVar}
	"Essential. All sequences which match the given one up to and including the given index.
	Should this just be supplanted by CoordinateSpace::region ()?"
	self passe.
	^SequenceRegion using: false
		with: (PrimSpec pointer
			arrayWithTwo: (BeforeSequencePrefix below: sequence with: limit)
			with: (BeforeSequencePrefix above: sequence with: limit))!

{SequenceMapping} shiftAndTranslation

	self passe!

{SequenceDsp} shiftAndTranslation: shift {IntegerVar}

	self passe!

{SequenceDsp} shiftAndTranslation: shift {IntegerVar}
	with: translation {Sequence}

	self passe! !

!SequenceSpace methodsFor: 'testing'!

{UInt32} actualHashForEqual
	"is equal to any basic space on the same category of positions"

	^self getCategory hashForEqual + 1!

{BooleanVar} isEqual: anObject {Heaper}
	"is equal to any basic space on the same category of positions"

	^anObject getCategory == self getCategory! !

!SequenceSpace methodsFor: 'smalltalk: defaults'!

{SequenceMapping CLIENT} mapping: shift {IntegerVar}
	"A transformation which shifts a value by some number of places and then adds a translation to it."
	
	^self mapping: shift with: NULL! !

!SequenceSpace methodsFor: 'generated:'!

{void} sendSelfTo: xmtr {Xmtr}! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

SequenceSpace class
	instanceVariableNames: ''!

(SequenceSpace getOrMakeCxxClassDescription)
	friends:
'/* friends for class SequenceSpace */

friend class Sequence;
';
	attributes: ((Set new) add: #PSEUDO.COPY; add: #CONCRETE; add: #ON.CLIENT; yourself)!

!SequenceSpace class methodsFor: 'rcvr creation'!

{Heaper} make.Rcvr: rcvr {Rcvr}
	(rcvr cast: SpecialistRcvr) registerIbid: TheSequenceSpace.
	^TheSequenceSpace! !

!SequenceSpace class methodsFor: 'creation'!

{SequenceSpace INLINE} implicitReceiver
	"Get the receiver for wire requests."
	^TheSequenceSpace!

{SequenceSpace CLIENT login INLINE} make
	^TheSequenceSpace! !

!SequenceSpace class methodsFor: 'smalltalk: init'!

initTimeNonInherited

	self REQUIRES: Sequence.
	TheSequenceSpace := self create!

linkTimeNonInherited

	TheSequenceSpace := NULL! !

!SequenceSpace class methodsFor: 'smalltalk: system'!

info.stProtocol
"{SequenceRegion CLIENT} above: sequence {Sequence} with: inclusive {BooleanVar}
{SequenceRegion CLIENT} below: sequence {Sequence} with: inclusive {BooleanVar}
{SequenceRegion CLIENT} interval: lower {Region} with: upper {Sequence}
{SequenceMapping CLIENT} mapping: shift {IntegerVar} with: translation {Sequence}
{Sequence CLIENT} position: numbers {PrimIntegerArray}
{Sequence CLIENT} position: numbers {PrimIntegerArray | NULL} with: shift {IntegerVar | IntegerVarZero}
{SequenceRegion CLIENT} prefixedBy: sequence {Sequence} with: limit {IntegerVar}
"! !