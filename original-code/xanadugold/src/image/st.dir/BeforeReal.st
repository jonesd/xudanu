'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:07:50 pm'!

RealEdge subclass: #BeforeReal
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-tumbler'!

(BeforeReal getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #COPY; add: #NOT.A.TYPE; yourself)!

!BeforeReal methodsFor: 'printing'!

{void} printTransitionOn: oo {ostream reference}
	with: entering {BooleanVar}
	with: touchesPrevious {BooleanVar}
	
	oo << ' '.
	entering ifTrue: [oo << '['].
	(touchesPrevious and: [entering not]) ifFalse:
		[oo << self position].
	entering ifFalse: [oo << ')']! !

!BeforeReal methodsFor: 'comparing'!

{BooleanVar} follows: pos {Position}
	
	^((pos cast: RealPos) isGE: self position) not!

{BooleanVar} isEqual: other {Heaper}

	other
		cast: BeforeReal into: [:after |
			^self position isEqual: after position]
		others: [^false].
	^false "fodder"!

{BooleanVar} isFollowedBy: next {TransitionEdge}
	
	next 
		cast: AfterReal into: [:after |
			^self position isEqual: after position]
		others: [^false].
	^false "fodder"!

{BooleanVar} isGE: other {TransitionEdge}
	
	other 
		cast: BeforeReal into: [:before |
			^self position isGE: before position]
		cast: AfterReal into: [:after |
			^(after position isGE: self position) not].
	^false "fodder"! !

!BeforeReal methodsFor: 'creation'!

create: pos {RealPos}

	super create: pos.! !

!BeforeReal methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

BeforeReal class
	instanceVariableNames: ''!

(BeforeReal getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #COPY; add: #NOT.A.TYPE; yourself)!

!BeforeReal class methodsFor: 'create'!

{RealEdge} make: pos {RealPos}

	^self create: pos! !