'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:07:55 pm'!

Position subclass: #Sequence
	instanceVariableNames: '
		myShift {IntegerVar}
		myNumbers {PrimIntegerArray}'
	classVariableNames: 'TheZero {Sequence} '
	poolDictionaries: ''
	category: 'Xanadu-tumbler'!
Sequence comment:
'Represents an infinite sequence of integers (of which only a finite number can be non-zero). They are lexically ordered, and there is a "decimal point" between the numbers at -1 and 0.

Implementation note:
The array should have no zeros at either end, and noone else should have a pointer to it.'!

(Sequence getOrMakeCxxClassDescription)
	friends:
'/* friends for class Sequence */
friend class AfterSequence;
friend class BeforeSequence;
friend class BeforeSequencePrefix;
friend class SequenceUpOrder;
friend class SequenceSpace;';
	attributes: ((Set new) add: #CONCRETE; add: #ON.CLIENT; add: #COPY; yourself)!

!Sequence methodsFor: 'accessing'!

{XnRegion} asRegion

	^SequenceRegion using: false
		with: ((PrimSpec pointer
			arrayWithTwo: (BeforeSequence make: self)
			with: (AfterSequence make: self)) cast: PtrArray)!

{CoordinateSpace INLINE} coordinateSpace

	^SequenceSpace make!

{IntegerVar INLINE} count
	"How many numbers in the sequence, not counting leading or trailing zeros"
	
	^myNumbers count!

{IntegerVar CLIENT} firstIndex
	"The smallest index with a non-zero number. Blasts if it is all zeros."
	
	myNumbers count = Int32Zero ifTrue:
		[Heaper BLAST: #ZeroSequence].
	^myShift!

{IntegerVar CLIENT} integerAt: index {IntegerVar}
	"The number at the given index in the Sequence. Returns zeros beyond either end of the array."
	
	| i {IntegerVar} |
	i := index - myShift.
	(i >= IntegerVarZero and: [i < self count]) ifTrue:
		[^myNumbers integerAt: i DOTasLong]
	ifFalse:
		[^IntegerVarZero]!

{PrimIntegerArray CLIENT} integers
	"Essential. The numbers in this Sequence. This is a copy of the array, so you may modify it.
	Note that two Sequences which are isEqual, may actually have arrays of numbers which have different specs. Also, the array will not have any zeros at the beginning or end."
	
	^myNumbers copy cast: PrimIntegerArray!

{BooleanVar CLIENT} isZero
	"Whether all the numbers in the sequence are zero"
	
	^myNumbers count == Int32Zero!

{IntegerVar CLIENT} lastIndex
	"The largest index with a non-zero number. Blasts if it is all zeros."
	
	myNumbers count = Int32Zero ifTrue:
		[Heaper BLAST: #ZeroSequence].
	^myShift + myNumbers count - 1!

{IntegerVar INLINE} shift
	"The amount by which the numbers are shifted. Positive means less significant, negative means more significant. This is contrary to the usual arithmetic notions, but it is the right thing for arrays."
	
	^myShift! !

!Sequence methodsFor: 'private: comparing'!

{Int32} comparePrefix: other {Sequence} with: n {IntegerVar}
	"Compare my numbers up to and including index n with the corresponding numbers in the other Sequence. Return -1, 0 or 1 depending on whether they are <, =, or > the other."
	
	| diff {IntegerVar} |
	(self isZero or: [myShift > n]) ifTrue:
		[(other isZero or: [other shift > n]) ifTrue: [^Int32Zero].
		(other secretNumbers integerAt: Int32Zero) > IntegerVarZero
			ifTrue: [^-1]
			ifFalse: [^1]].
	(other isZero or: [other shift > n]) ifTrue:
		[(myNumbers integerAt: Int32Zero) > IntegerVarZero
			ifTrue: [^1]
			ifFalse: [^-1]].
	diff := myShift - other shift.
	diff < IntegerVarZero ifTrue:
		[(myNumbers integerAt: Int32Zero) > IntegerVarZero
			ifTrue: [^1]
			ifFalse: [^-1]].
	diff > IntegerVarZero ifTrue:
		[(other secretNumbers integerAt: Int32Zero) > IntegerVarZero
			ifTrue: [^-1]
			ifFalse: [^1]].
	^myNumbers compare: other secretNumbers
		with: (n - myShift + 1 min: (myNumbers count max: other secretNumbers count)) DOTasLong! !

!Sequence methodsFor: 'testing'!

{UInt32} actualHashForEqual

	^myShift DOTasLong bitXor: myNumbers elementsHash!

{BooleanVar} isEqual: other {Heaper}

	other cast: Sequence into: [ :sequence |
		^myShift = sequence shift
			and: [myNumbers contentsEqual: sequence secretNumbers]]
	others:
		[^false].
	^ false "compiler fodder"!

{BooleanVar} isGE: other {Position}
	"Whether this sequence is greater than or equal to the other sequence, using a lexical comparison of their corresponding numbers."
	
	| o {Sequence} |
	o _ other cast: Sequence.
	(self isZero) ifTrue:
		[^o isZero
			or: [(o secretNumbers integerAt: Int32Zero) <= IntegerVarZero]].
	(o isZero or: [myShift < o shift]) ifTrue:
		[^self isZero
			or: [(myNumbers integerAt: Int32Zero) >= IntegerVarZero]].
	myShift > o shift ifTrue:
		[^(o secretNumbers integerAt: Int32Zero) <= IntegerVarZero].
	myShift < o shift ifTrue:
		[^(myNumbers integerAt: Int32Zero) >= IntegerVarZero].
	^(myNumbers compare: o secretNumbers) >= Int32Zero! !

!Sequence methodsFor: 'private:'!

{PrimIntegerArray INLINE} secretNumbers
	"The array itself, for internal use"
	
	^myNumbers! !

!Sequence methodsFor: 'printing'!

{void} printOn: oo {ostream reference}

	Sequence printOn: oo with: myShift with: myNumbers! !

!Sequence methodsFor: 'create'!

create: shift {IntegerVar} with: numbers {PrimIntegerArray}

	super create.
	myShift := shift.
	myNumbers := numbers.! !

!Sequence methodsFor: 'operations'!

{Sequence} first
	"The sequence consisting of all numbers in this one up to but not including the first zero, or the entire thing if there are no zeros"
	
	"| zero {Int32} |
	zero := myNumbers indexOfInteger: IntegerVarZero.
	zero < Int32Zero ifTrue:
		[^self]
	ifFalse:
		[^Sequence create: ((myNumbers copy: zero) cast: PrimIntegerArray)]"
	Someone shouldImplement.
	^NULL "fodder"!

{Sequence} minus: other {Sequence}
	"A sequence with the corresponding numbers subtracted from each other"
	
	| diff {Int32} result {PrimIntegerArray} |
	Ravi thingToDo. "Only increase representation size when necessary"
	Ravi knownBug. "large difference in shifts creates huge array"
	diff := (other shift - myShift) DOTasLong.
	diff > Int32Zero ifTrue:
		[result := (PrimSpec integerVar copyGrow: myNumbers
			with: (diff + other secretNumbers count - myNumbers count max: Int32Zero)) cast: PrimIntegerArray.
		result at: diff subtractElements: other secretNumbers.
		^Sequence using: myShift with: result]
	ifFalse:
		[result := (PrimSpec integerVar copy: myNumbers
			with: -1
			with: Int32Zero
			with: diff negated
			with: ((other shift + other count - (myShift + myNumbers count)) DOTasLong max: Int32Zero)) cast: PrimIntegerArray.
		result at: diff negated subtractElements: other secretNumbers.
		^Sequence using: other shift with: result]!

{Sequence} plus: other {Sequence}
	"A sequence with the corresponding numbers added to each other"
	
	| diff {Int32} result {PrimIntegerArray} |
	Ravi thingToDo. "Only increase representation size when necessary"
	Ravi knownBug. "large difference in shifts creates huge array"
	diff := (other shift - myShift) DOTasLong.
	diff > Int32Zero ifTrue:
		[result := (PrimSpec integerVar copyGrow: myNumbers
			with: (diff + other secretNumbers count - myNumbers count max: Int32Zero)) cast: PrimIntegerArray.
		result at: diff addElements: other secretNumbers.
		^Sequence using: myShift with: result]
	ifFalse:
		[result := (PrimSpec integerVar copy: myNumbers
			with: -1
			with: Int32Zero
			with: diff negated
			with: ((other shift + other count - (myShift + myNumbers count)) DOTasLong max: Int32Zero)) cast: PrimIntegerArray.
		result at: Int32Zero addElements: other secretNumbers.
		^Sequence using: other shift with: result]!

{Sequence} rest
	"The sequence consisting of all numbers in this one after but not including the first zero, or a null sequence if there are no zeros"
	
	"| zero {Int32} |
	zero := myNumbers indexOfInteger: IntegerVarZero.
	zero < Int32Zero ifTrue:
		[^Sequence zero]
	ifFalse:
		[^Sequence create: ((myNumbers
			copy: -1 with: 1 + zero) cast: PrimIntegerArray)]"
	Someone shouldImplement.
	^NULL "fodder"!

{Sequence} shift: offset {IntegerVar}
	"Shift the numbers by some number of places. Positive shifts make it less significant, negative shifts make it more significant."
	
	(offset == IntegerVarZero or: [myNumbers count == Int32Zero]) ifTrue: [^self].
	^Sequence create: myShift + offset
		with: myNumbers!

{Sequence CLIENT} with: index {IntegerVar} with: number {IntegerVar}
	"Change a single element of the sequence."
	
	(index >= myShift and: [index - myShift < myNumbers count]) ifTrue:
		[number = IntegerVarZero ifTrue:
			[index = myShift ifTrue:
				[^Sequence create: myShift + 1
					with: ((myNumbers copy: myNumbers count - 1 with: 1) cast: PrimIntegerArray)].
			index = (myShift + myNumbers count) ifTrue:
				[^Sequence create: myShift + 1
					with: ((myNumbers copy: myNumbers count - 1) cast: PrimIntegerArray)]].
		^Sequence create: myShift
			with: (myNumbers at: (index - myShift) DOTasLong hold: number)].
	number = IntegerVarZero ifTrue:
		[^self].
	index < myShift ifTrue:
		[ | result {PrimIntegerArray} |
		result := (((myNumbers spec cast: PrimIntegerSpec) combine: ((PrimSpec toHold: number) cast: PrimIntegerSpec))
			copy: myNumbers
			with: -1
			with: Int32Zero
			with: (myShift - index) DOTasLong) cast: PrimIntegerArray.
		result at: Int32Zero storeInteger: number.
		^Sequence create: index with: result].
	^Sequence create: myShift
		with: (myNumbers at: (index - myShift) DOTasLong hold: number)!

{Sequence} withFirst: number {IntegerVar}
	"A Sequence with all my numbers followed by the given one"
	
	Ravi shouldImplement.
	^NULL "fodder"!

{Sequence} withLast: number {IntegerVar}
	"A Sequence with all my numbers followed by the given one"
	
	^Sequence create: myShift
		with: (myNumbers at: myNumbers count hold: number)!

{Sequence} withRest: other {Sequence}
	"A sequence containing all the numbers in this one, followed by the other one, separated by a single zero."
	
	| spec {PrimIntegerSpec} result {PrimIntegerArray} |
	spec := (myNumbers spec cast: PrimIntegerSpec) combine: (other secretNumbers spec cast: PrimIntegerSpec).
	result := (spec copyGrow: myNumbers with: other count DOTasLong + 1) cast: PrimIntegerArray.
	result at: self count DOTasLong + 1 storeMany: other secretNumbers.
	^Sequence create: myShift with: result! !

!Sequence methodsFor: 'smalltalk: passe'!

{BooleanVar} isEmpty
	"Whether there are no non-zero numbers in the Sequence"
	self passe.
	^myNumbers count == Int32Zero!

{IntegerVar} numberAt: index {IntegerVar}

	self passe "integerAt"!

{PrimIntegerArray} numbers

	self passe. "integers"! !

!Sequence methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	myShift _ receiver receiveIntegerVar.
	myNumbers _ receiver receiveHeaper.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	xmtr sendIntegerVar: myShift.
	xmtr sendHeaper: myNumbers.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

Sequence class
	instanceVariableNames: ''!

(Sequence getOrMakeCxxClassDescription)
	friends:
'/* friends for class Sequence */
friend class AfterSequence;
friend class BeforeSequence;
friend class BeforeSequencePrefix;
friend class SequenceUpOrder;
friend class SequenceSpace;';
	attributes: ((Set new) add: #CONCRETE; add: #ON.CLIENT; add: #COPY; yourself)!

!Sequence class methodsFor: 'pseudo constructors'!

{Sequence} numbers: digits {PrimIntegerArray}
 
	|first {Int32} last {Int32} |
	first := digits indexPastInteger: IntegerVarZero.
	first = -1 ifTrue: [^ Sequence zero].
	last := digits indexPastInteger: IntegerVarZero with: -1 with: -1.
	^ self create: first with: ((digits copy: last - first + 1 with: first) cast: PrimIntegerArray)!

{Sequence} one: a {IntegerVar}
	"A single element Sequence"
	
	a = IntegerVarZero ifTrue:
		[^self zero].
	^self create: IntegerVarZero with: ((PrimSpec integerVar arrayWith: (PrimSpec integerVar value: a)) cast: PrimIntegerArray)!

{Sequence} string: string {Character star}

	^self create: IntegerVarZero with: (UInt8Array string: string)!

{Sequence} three: a {IntegerVar} with: b {IntegerVar} with: c {IntegerVar}
	"A three element Sequence"
	
	c = IntegerVarZero ifTrue:
		[^self two: a with: b].
	^self create: IntegerVarZero
		  with: ((PrimSpec integerVar arrayWithThree: (PrimSpec integerVar value: a)
		  										 with: (PrimSpec integerVar value: b) 
		  										 with: (PrimSpec integerVar value: c)) cast: PrimIntegerArray)!

{Sequence} two: a {IntegerVar} with: b {IntegerVar}
	"A two element Sequence"
	
	b = IntegerVarZero ifTrue:
		[^self one: a].
	^self create: IntegerVarZero
		    with: ((PrimSpec integerVar arrayWithTwo: (PrimSpec integerVar value: a)
		    										  with: (PrimSpec integerVar value: b)) cast: PrimIntegerArray)!

{Sequence INLINE} zero

	^TheZero! !

!Sequence class methodsFor: 'private:'!

{void} printArrayOn: oo {ostream reference} with: numbers {PrimIntegerArray}
	"Print a sequence of numbers separated by dots. Deal with strings specially."
	
	(numbers isKindOf: UInt8Array) ifTrue:
		[oo << '<' << numbers << '>']
	ifFalse:
		[Int32Zero almostTo: numbers count do: [ :i {Int32} |
			i > Int32Zero ifTrue:
				[oo << '.'].
			oo << (numbers integerAt: i)]]!

{void} printOn: oo {ostream reference}
	with: shift {IntegerVar}
	with: numbers {PrimIntegerArray}
	"Print a sequence of numbers separated by dots. Deal with strings specially."
	
	shift < numbers count negated ifTrue:
		[self printArrayOn: oo with: numbers.
		oo << '.'.
		self printZerosOn: oo with: shift negated - numbers count.
		oo << '!!0']
	ifFalse: [shift < IntegerVarZero ifTrue:
		[self printArrayOn: oo with: ((numbers copy: shift negated DOTasLong) cast: PrimIntegerArray).
		oo << '!!'.
		self printArrayOn: oo
			with: ((numbers copy: -1 with: shift negated DOTasLong) cast: PrimIntegerArray)]
	ifFalse:
		[oo << '0!!'.
		shift > IntegerVarZero ifTrue:
			[self printZerosOn: oo with: shift.
			oo << '.'].
		self printArrayOn: oo with: numbers]]!

{void} printZerosOn: oo {ostream reference}
	with: shift {IntegerVar}
	"Print a sequence of zeros separated by dots. Deal with large numbers specially."
	
	shift > 7 ifTrue:
		[oo << '...(' << shift << ')...']
	ifFalse:
		[IntegerVarZero almostTo: shift - 1 do: [ :i {IntegerVar} |
			oo << '0.'].
		oo << '0']!

{Sequence} using: shift {IntegerVar} with: numbers {PrimIntegerArray}
	"Don't need to make a copy of the array"
	
	| start {Int32} stop {Int32} |
	start := numbers indexPastInteger: IntegerVarZero.
	start < Int32Zero ifTrue:
		[^self zero].
	stop := numbers indexPastInteger: IntegerVarZero with: -1 with: -1.
	(start ~= Int32Zero or: [stop < (numbers count - 1)])
		ifTrue: [^self create: shift + start
			with: ((numbers copy: stop - start with: start) cast: PrimIntegerArray)]
		ifFalse: [^self create: shift with: numbers]! !

!Sequence class methodsFor: 'smalltalk: init'!

initTimeNonInherited

	self REQUIRES: IntegerVarArray.
	TheZero := self create: IntegerVarZero with: (IntegerVarArray zeros: Int32Zero).!

linkTimeNonInherited

	TheZero := NULL.! !

!Sequence class methodsFor: 'smalltalk: system'!

info.stProtocol
"{IntegerVar CLIENT} firstIndex
{IntegerVar CLIENT} integerAt: index {IntegerVar}
{PrimIntegerArray CLIENT} integers
{BooleanVar CLIENT} isZero
{IntegerVar CLIENT} lastIndex
{Sequence CLIENT} with: index {IntegerVar} with: number {IntegerVar}
"! !