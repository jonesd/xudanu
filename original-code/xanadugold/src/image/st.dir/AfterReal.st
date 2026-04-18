'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:07:49 pm'!

RealEdge subclass: #AfterReal
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-tumbler'!

(AfterReal getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #COPY; add: #NOT.A.TYPE; yourself)!

!AfterReal methodsFor: 'comparing'!

{BooleanVar} follows: pos {Position}
	
	^self position isGE: (pos cast: RealPos)!

{BooleanVar} isEqual: other {Heaper}

	other
		cast: AfterReal into: [:after |
			^self position isEqual: after position]
		others: [^false].
	^false "fodder"!

{BooleanVar} isFollowedBy: next {TransitionEdge}

	^false!

{BooleanVar} isGE: other {TransitionEdge}
	
	^self position isGE: (other cast: RealEdge) position! !

!AfterReal methodsFor: 'printing'!

{void} printTransitionOn: oo {ostream reference}
	with: entering {BooleanVar}
	with: touchesPrevious {BooleanVar}
	
	oo << ' '.
	entering ifTrue: [oo << '('].
	(touchesPrevious and: [entering not]) ifFalse:
		[oo << self position].
	entering ifFalse: [oo << ']']! !

!AfterReal methodsFor: 'creation'!

create: pos {RealPos}

	super create: pos.! !

!AfterReal methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

AfterReal class
	instanceVariableNames: ''!

(AfterReal getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #COPY; add: #NOT.A.TYPE; yourself)!

!AfterReal class methodsFor: 'create'!

{RealEdge} make: pos {RealPos}

	^self create: pos! !