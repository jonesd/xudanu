'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:07:49 pm'!

SequenceEdge subclass: #AfterSequence
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-tumbler'!

(AfterSequence getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #COPY; add: #NOT.A.TYPE; yourself)!

!AfterSequence methodsFor: 'accessing'!

{Position} position

	^self sequence!

{SequenceEdge} transformedBy: dsp {SequenceMapping}

	^AfterSequence make: ((dsp of: self sequence) cast: Sequence)! !

!AfterSequence methodsFor: 'create'!

create: sequence {Sequence}

	super create: sequence.! !

!AfterSequence methodsFor: 'printing'!

{void} printTransitionOn: oo {ostream reference}
	with: entering {BooleanVar}
	with: touchesPrevious {BooleanVar}

	
	oo << ' '.
	entering ifTrue: [oo << '('].
	(touchesPrevious and: [entering not]) ifFalse:
		[oo << self sequence].
	entering ifFalse: [oo << ']']! !

!AfterSequence methodsFor: 'comparing'!

{BooleanVar} follows: pos {Position}

	^self sequence isGE: (pos cast: Sequence)!

{BooleanVar} isEqual: other {Heaper}

	other cast: AfterSequence into: [ :after |
		^after sequence isEqual: self sequence]
	others:
		[^false].
	^ false "compiler fodder"!

{BooleanVar} isFollowedBy: next {TransitionEdge unused}

	^false!

{BooleanVar} isGE: other {TransitionEdge}

	other cast: BeforeSequencePrefix into: [ :prefix |
		^(self sequence comparePrefix: prefix sequence with: prefix limit) >= Int32Zero]
	cast: SequenceEdge into: [ :edge |
		^self sequence isGE: edge sequence].
	^ false "compiler fodder"!

{BooleanVar} touches: other {TransitionEdge}

	other cast: BeforeSequencePrefix into: [ :prefix |
		^false]
	cast: SequenceEdge into: [ :edge |
		^self sequence isEqual: edge sequence].
	^ false "compiler fodder"! !

!AfterSequence methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

AfterSequence class
	instanceVariableNames: ''!

(AfterSequence getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #COPY; add: #NOT.A.TYPE; yourself)!

!AfterSequence class methodsFor: 'pseudo constructors'!

{SequenceEdge} make: sequence {Sequence}

	^self create: sequence! !