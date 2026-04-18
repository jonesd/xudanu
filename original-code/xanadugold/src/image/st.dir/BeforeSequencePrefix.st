'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:07:50 pm'!

SequenceEdge subclass: #BeforeSequencePrefix
	instanceVariableNames: 'myLimit {IntegerVar}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-tumbler'!

(BeforeSequencePrefix getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #COPY; add: #NOT.A.TYPE; yourself)!

!BeforeSequencePrefix methodsFor: 'comparing'!

{BooleanVar} follows: pos {Position}

	^ (self sequence isEqual: (pos cast: Sequence)) not and: [self sequence isGE: pos]!

{BooleanVar} isEqual: other {Heaper}

	other cast: BeforeSequencePrefix into: [ :prefix |
		^myLimit = prefix limit
			and: [prefix sequence isEqual: self sequence]]
	others:
		[^false].
	^ false "compiler fodder"!

{BooleanVar} isFollowedBy: next {TransitionEdge unused}

	^false!

{BooleanVar} isGE: other {TransitionEdge}

	| diff {Int32} |
	other cast: BeforeSequencePrefix into: [ :prefix |
		diff := self sequence comparePrefix: prefix sequence
			with: (myLimit min: prefix limit).
		diff ~= Int32Zero ifTrue:
			[^diff > Int32Zero].
		^myLimit >= prefix limit]
	cast: SequenceEdge into: [ :before |
		^(self sequence comparePrefix: before sequence with: myLimit) > Int32Zero].
	^ false "compiler fodder"!

{BooleanVar} touches: other {TransitionEdge}

	other cast: BeforeSequencePrefix into: [ :before |
		^myLimit = before limit
			and: [(self sequence comparePrefix: before sequence with: myLimit - 1) = Int32Zero
			and: [((self sequence integerAt: myLimit) - (before sequence integerAt: myLimit)) abs <= 1]]]
	others:
		[^false].
	^ false "compiler fodder"! !

!BeforeSequencePrefix methodsFor: 'accessing'!

{IntegerVar} limit

	^myLimit!

{Position} position

	Heaper BLAST: #NotInSpace.
	^NULL "fodder"!

{SequenceEdge} transformedBy: dsp {SequenceMapping}

	^BeforeSequencePrefix create: ((dsp of: self sequence) cast: Sequence)
		with: myLimit + dsp shift! !

!BeforeSequencePrefix methodsFor: 'create'!

create: sequence {Sequence} with: limit {IntegerVar}

	super create: sequence.
	myLimit := limit.! !

!BeforeSequencePrefix methodsFor: 'printing'!

{void} printOn: oo {ostream reference}

	oo << self getCategory name << '(' << myLimit << ', ' << self sequence << ')'!

{void} printTransitionOn: oo {ostream reference}
	with: entering {BooleanVar}
	with: touchesPrevious {BooleanVar}
	
	oo << ' '.
	entering ifTrue: [oo << '('].
	(touchesPrevious and: [entering not]) ifFalse:
		[Ravi thingToDo. "Eliminate strings of zeros / stars, print UInt8Arrays as strings"
		(IntegerVarZero min: self sequence shift) to: (myLimit + 1 max: IntegerVarZero) do:
			[ :i {IntegerVar} |
			i == IntegerVarZero ifTrue:
				[oo << '!!']
			ifFalse: [i ~= self sequence shift ifTrue:
				[oo << '.']].
			(i = myLimit and: [entering not]) ifTrue:
				[oo << ((self sequence integerAt: i) - 1)]
			ifFalse: [i <= myLimit ifTrue:
				[oo << (self sequence integerAt: i)]
			ifFalse:
				[oo << '*']]]].
	entering ifFalse: [oo << ')']! !

!BeforeSequencePrefix methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	myLimit _ receiver receiveIntegerVar.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	xmtr sendIntegerVar: myLimit.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

BeforeSequencePrefix class
	instanceVariableNames: ''!

(BeforeSequencePrefix getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #COPY; add: #NOT.A.TYPE; yourself)!

!BeforeSequencePrefix class methodsFor: 'pseudo constructors'!

{TransitionEdge} above: sequence {Sequence} with: limit {IntegerVar}

	limit < sequence shift ifTrue:
		[^self create: (Sequence using: limit with: ((PrimSpec integerVar
				arrayWith: (PrimSpec integerVar value: 1)) cast: PrimIntegerArray)) with: limit].
	limit < (sequence shift + sequence count) ifTrue:
		[| newCount {Int32} hisCount {Int32} |
		newCount _ (limit - sequence shift + 1) DOTasLong.
		hisCount _ sequence secretNumbers count.
		^self create: (Sequence
			using: sequence shift
			with: (((sequence secretNumbers
							copy: (newCount min: hisCount)
							with: Int32Zero
							with: Int32Zero
							with: (newCount - hisCount max: Int32Zero)) cast: PrimIntegerArray)
				at: (limit - sequence shift) DOTasLong
				hold: (sequence integerAt: limit) + 1
				with: true))
			with: limit].
	"Ravi knownBug." "creates huge arrays if (limit - sequence shift) is too big"
	^self create: (Sequence
			using: sequence shift
			with: (sequence secretNumbers
				at: (limit - sequence shift) DOTasLong
				hold: (sequence integerAt: limit) + 1))
		with: limit!

{TransitionEdge} below: sequence {Sequence} with: limit {IntegerVar}

	limit < sequence shift ifTrue:
		[^self create: Sequence zero with: limit].
	limit < (sequence shift + sequence count) ifTrue:
		[| newCount {Int32} hisCount {Int32} |
		newCount _ (limit - sequence shift + 1) DOTasLong.
		hisCount _ sequence secretNumbers count.
		^self create: (Sequence
						using: sequence shift
						with: ((sequence secretNumbers
							copy: (newCount min: hisCount)
							with: Int32Zero
							with: Int32Zero
							with: (newCount - hisCount max: Int32Zero)) cast: PrimIntegerArray))
				with: limit].
	^self create: sequence with: limit! !