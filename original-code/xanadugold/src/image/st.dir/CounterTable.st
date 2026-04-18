'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:01:26 pm'!

Heaper subclass: #CounterTable
	instanceVariableNames: 'myCounters {MuTable of: ID and: Counter}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Monitoring'!

(CounterTable getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!CounterTable methodsFor: 'create'!

create
	super create.
	myCounters _ MuTable make: SequenceSpace make! !

!CounterTable methodsFor: 'counting'!

{void} countBool: name {char vector} with: value
	| counter {BooleanCounter} |
	counter _ (self fetchCounter: name) cast: BooleanCounter.
	counter == NULL ifTrue:
		[counter _ BooleanCounter create.
		self addCounter: name with: counter].
	counter count: value!

{void} countHeaper: name {char vector} with: value
	(value isKindOf: Position) ifTrue:
		[ | counter {PositionCounter} key {Position} |
		counter _ (self fetchCounter: name) cast: PositionCounter.
		key _ value quickCast: Position.
		counter == NULL ifTrue:
			[counter _ PositionCounter create: key coordinateSpace.
			self addCounter: name with: counter].
		counter count: key]
	ifFalse:
		[ | counter {HeaperCounter} |
		counter _ (self fetchCounter: name) cast: HeaperCounter.
		counter == NULL ifTrue:
			[counter _ HeaperCounter create.
			self addCounter: name with: counter].
		counter count: value]!

{void} countInt: name {char vector} with: value
	| counter {IntegerCounter} |
	counter _ (self fetchCounter: name) cast: IntegerCounter.
	counter == NULL ifTrue:
		[counter _ IntegerCounter create.
		self addCounter: name with: counter].
	counter count: value!

{void} reset
	myCounters _ MuTable make: SequenceSpace make! !

!CounterTable methodsFor: 'private: private'!

{void} addCounter: name {char vector} with: counter {Counter}
	myCounters at: (Sequence string: name) store: counter!

{Counter} fetchCounter: name {char vector}
	^(myCounters fetch: (Sequence string: name)) quickCast: Counter! !

!CounterTable methodsFor: 'printing'!

{void} printOn: oo {ostream reference}
	myCounters domain stepper forEach: [ :name {Sequence} | | counter {Counter} counts {TableStepper} |
		counter _ myCounters get: name.
		oo << name << ' (' << counter total << ')
'.
		(counts _ counter results stepper) forEach: [ :each {IntegerPos} |
			oo << '	' << each asIntegerVar << ':	' << counts position << '
']]! !

!CounterTable methodsFor: 'smalltalk: passe'!

count: name with: value
	
	self passe! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

CounterTable class
	instanceVariableNames: ''!

(CounterTable getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!CounterTable class methodsFor: 'smalltalk: initialization'!

initTimeNonInherited
	self REQUIRES: IntegerSpace.
	self REQUIRES: HeaperSpace.
	self REQUIRES: SequenceSpace.
	self REQUIRES: MuTable.
	Tally fluidSet: CounterTable make!

staticTimeNonInherited

	CounterTable defineFluid: #Tally with: Emulsion globalEmulsion with: [NULL]! !

!CounterTable class methodsFor: 'pseudo constructors'!

make
	^CounterTable create! !