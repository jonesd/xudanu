'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:59:56 pm'!

AbstractRecorderFinder subclass: #CumulativeRecorderFinder
	instanceVariableNames: '
		myGenerators {ImmuSet of: AnyRecorderFinder}
		myCurrent {ImmuSet of: SimpleRecorderFinder}
		myOthers {ImmuSet of: SimpleRecorderFinder | AnyRecorderFinder}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Be-Canopy'!
CumulativeRecorderFinder comment:
'Propagates a change to all recorders which might be interested in it, and picking up all elements which might newly be made visible by it. The generators make new finders as we pass by additional Edition boundaries. Also holds onto a collection of simple finders looking for recorders triggered by specific Works or Editions. The current set contains those which might record the current edition, and are passed to all Recorders. The others are only passed to Recorders with the directContainersOnly flag off.'!

(CumulativeRecorderFinder getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #COPY; add: #NOT.A.TYPE; yourself)!

!CumulativeRecorderFinder methodsFor: 'recording'!

{void} checkRecorder: recorder {ResultRecorder}
	with: fossil {RecorderFossil}

	myCurrent stepper forEach: [ :current {SimpleRecorderFinder} |
		current checkRecorder: recorder with: fossil].
	recorder isDirectOnly ifFalse:
		[myOthers stepper forEach: [ :other {SimpleRecorderFinder} |
			other checkRecorder: recorder with: fossil]]! !

!CumulativeRecorderFinder methodsFor: 'create'!

create: flags {UInt32}
	with: generators {ImmuSet of: AnyRecorderFinder}
	with: current {ImmuSet of: SimpleRecorderFinder}
	with: others {ImmuSet of: SimpleRecorderFinder | AnyRecorderFinder}
	
	super create: flags.
	myGenerators := generators.
	myCurrent := current.
	myOthers := others.! !

!CumulativeRecorderFinder methodsFor: 'accessing'!

{ImmuSet of: AnyRecorderFinder} current

	^myCurrent!

{PropFinder} findPast: edition {BeEdition}
	
	| newCurrent {SetAccumulator} |
	newCurrent := SetAccumulator make.
	myGenerators stepper forEach: [ :gen {AnyRecorderFinder} |
		| next {PropFinder} |
		next := gen nextFinder: edition.
		next isEmpty ifFalse:
			[newCurrent step: (next cast: SimpleRecorderFinder) "cast will catch algorithm bugs in a place from which they are easier to fix" ]].
	^CumulativeRecorderFinder
		make: myGenerators
		with: (newCurrent value cast: ImmuSet)
		with: (myOthers unionWith: myCurrent)!

{ImmuSet of: AnyRecorderFinder} generators

	^myGenerators!

{BooleanVar} match: prop {Prop}

	myGenerators stepper forEach: [ :gen {PropFinder} |
		(gen match: prop) ifTrue: [^true]].
	^false!

{ImmuSet of: SimpleRecorderFinder | AnyRecorderFinder} others

	^myOthers!

{PropFinder} pass: parent {CanopyCrum}

	parent cast: SensorCrum into: [ :p |
		| newGenerators {SetAccumulator} newCurrent {SetAccumulator}
		  newOthers {SetAccumulator} past {PropFinder} |
		newGenerators := SetAccumulator make.
		myGenerators stepper forEach: [ :gen {PropFinder} |
			past := gen pass: p.
			past isEmpty ifFalse:
				[newGenerators step: past]].
		(newGenerators value cast: ImmuSet) isEmpty ifTrue:
			[^PropFinder closedPropFinder].
		newCurrent := SetAccumulator make.
		myCurrent stepper forEach: [ :current {PropFinder} |
			past := current pass: p.
			past isEmpty ifFalse:
				[newCurrent step: past]].
		newOthers := SetAccumulator make.
		myOthers stepper forEach: [ :other {PropFinder} |
			past := other pass: p.
			past isEmpty ifFalse:
				[newOthers step: past]].
		^CumulativeRecorderFinder
			make: (newGenerators value cast: ImmuSet)
			with: (newCurrent value cast: ImmuSet)
			with: (newOthers value cast: ImmuSet)].
	^NULL "fodder"! !

!CumulativeRecorderFinder methodsFor: 'testing'!

{UInt32} actualHashForEqual

	^(myGenerators hashForEqual
		bitXor: myCurrent hashForEqual)
		bitXor: myOthers hashForEqual!

{BooleanVar} isEqual: heaper {Heaper}

	heaper cast: CumulativeRecorderFinder into: [ :other |
		^(myGenerators isEqual: other generators)
			and: [(myCurrent isEqual: other current)
			and: [myOthers isEqual: other others]]]
	others:
		[^false].
	^false "fodder"! !

!CumulativeRecorderFinder methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	myGenerators _ receiver receiveHeaper.
	myCurrent _ receiver receiveHeaper.
	myOthers _ receiver receiveHeaper.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	xmtr sendHeaper: myGenerators.
	xmtr sendHeaper: myCurrent.
	xmtr sendHeaper: myOthers.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

CumulativeRecorderFinder class
	instanceVariableNames: ''!

(CumulativeRecorderFinder getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #COPY; add: #NOT.A.TYPE; yourself)!

!CumulativeRecorderFinder class methodsFor: 'create'!

{PropFinder} make: generators {ImmuSet of: SimpleRecorderFinder}
	with: current {ImmuSet of: SimpleRecorderFinder}
	with: others {ImmuSet of: SimpleRecorderFinder}
	
	| f {UInt32} |
	generators isEmpty ifTrue:
		[^PropFinder closedPropFinder].
	Ravi thingToDo. "since current & generators can have at most two elements, represent them explicitly as two OR(NULL) pointers? or make special SmallImmuSet class?"
	f := UInt32Zero.
	generators stepper forEach: [ :g {AnyRecorderFinder} |
		f := f bitOr: g flags].
	current stepper forEach: [ :c {SimpleRecorderFinder} |
		f := f bitOr: c flags].
	others stepper forEach: [ :o {AbstractRecorderFinder} |
		f := f bitOr: o flags].
	^self create: f
		with: generators
		with: current
		with: others! !