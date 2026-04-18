'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:07:50 pm'!

SequenceEdge subclass: #BeforeSequence
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-tumbler'!

(BeforeSequence getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #COPY; add: #NOT.A.TYPE; yourself)!

!BeforeSequence methodsFor: 'comparing'!

{BooleanVar} follows: pos {Position}

	^((pos cast: Sequence) isGE: self sequence) not!

{BooleanVar} isEqual: other {Heaper}

	other cast: BeforeSequence into: [ :before |
		^before sequence isEqual: self sequence]
	others:
		[^false].
	^ false "compiler fodder"!

{BooleanVar} isFollowedBy: next {TransitionEdge}

	next cast: AfterSequence into: [ :after |
		^self sequence isEqual: after sequence]
	others:
		[^false].
	^ false "compiler fodder"!

{BooleanVar} isGE: other {TransitionEdge}

	other cast: BeforeSequencePrefix into: [ :prefix |
		^(self sequence comparePrefix: prefix sequence with: prefix limit) >= Int32Zero]
	cast: BeforeSequence into: [ :before |
		^self sequence isGE: before sequence]
	cast: AfterSequence into: [ :after |
		^(after sequence isGE: self sequence) not].
	^ false "compiler fodder"!

{BooleanVar} touches: other {TransitionEdge}

	other cast: BeforeSequencePrefix into: [ :prefix |
		^false]
	cast: SequenceEdge into: [ :edge |
		^self sequence isEqual: edge sequence].
	^ false "compiler fodder"! !

!BeforeSequence methodsFor: 'accessing'!

{Position} position

	^self sequence!

{SequenceEdge} transformedBy: dsp {SequenceMapping}

	^BeforeSequence make: ((dsp of: self sequence) cast: Sequence)! !

!BeforeSequence methodsFor: 'create'!

create: sequence {Sequence}

	super create: sequence.! !

!BeforeSequence methodsFor: 'printing'!

{void} printTransitionOn: oo {ostream reference}
	with: entering {BooleanVar}
	with: touchesPrevious {BooleanVar}

	oo << ' '.
	entering ifTrue: [oo << '['].
	(touchesPrevious and: [entering not]) ifFalse:
		[oo << self sequence].
	entering ifFalse: [oo << ')']! !

!BeforeSequence methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

BeforeSequence class
	instanceVariableNames: ''!

(BeforeSequence getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #COPY; add: #NOT.A.TYPE; yourself)!

!BeforeSequence class methodsFor: 'pseudo constructors'!

{SequenceEdge} make: sequence {Sequence}

	^self create: sequence! !