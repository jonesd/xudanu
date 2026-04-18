'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:00:36 pm'!

ImmuSet subclass: #TinyImmuSet
	instanceVariableNames: 'elementInternal {Heaper}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Collection-Sets'!
TinyImmuSet comment:
'This is an efficient implementation of ImmuSets for zero and one element sets.'!

(TinyImmuSet getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; add: #COPY; yourself)!

!TinyImmuSet methodsFor: 'protected: creation'!

create: only {Heaper}
	"Initialize a singleton immuset"
	super create.
	elementInternal _ only! !

!TinyImmuSet methodsFor: 'enumerating'!

{IntegerVar} count
	^ 1!

{Stepper} stepper
	^Stepper itemStepper: elementInternal!

{Heaper} theOne
	^ elementInternal! !

!TinyImmuSet methodsFor: 'adding-removing'!

{ImmuSet} with: anElement {Heaper} 
	(elementInternal isEqual: anElement)
		ifTrue: [^self]
		ifFalse: [| nuSet {MuSet} |
					nuSet _ MuSet make.Heaper: anElement.
					nuSet introduce: elementInternal.
					^ImmuSet make: nuSet]!

{ImmuSet} without: anElement {Heaper}
	(elementInternal isEqual: anElement) ifTrue: [^ ImmuSet make].
	^ self! !

!TinyImmuSet methodsFor: 'accessing'!

{BooleanVar} hasMember: someone {Heaper}
	^ elementInternal isEqual: someone!

{BooleanVar} isEmpty
	^ false!

{BooleanVar} isSubsetOf: another {ScruSet}
	^ another hasMember: elementInternal! !

!TinyImmuSet methodsFor: 'operations'!

{ImmuSet} intersect: another {ScruSet} 
	(another hasMember: elementInternal)
		ifTrue: [^ self]
		ifFalse: [^ ImmuSet make]!

{ImmuSet} minus: another {ScruSet}
	(another hasMember: elementInternal) 
		ifTrue: [^ ImmuSet make]
		ifFalse: [^ self]!

{ImmuSet} unionWith: another {ScruSet}
	another isEmpty 
		ifTrue: [^ self]
		ifFalse:
			[| nuSet {MuSet} |
			(another hasMember: elementInternal) ifTrue: [ ^ another asImmuSet ].
			another count > 5 ifTrue: [^another asImmuSet unionWith: self].
			nuSet _ MuSet make.Heaper: elementInternal.
			nuSet storeAll: another.
			^ ImmuSet make: nuSet]! !

!TinyImmuSet methodsFor: 'conversion'!

{MuSet} asMuSet
	^ MuSet make.Heaper: elementInternal! !

!TinyImmuSet methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	elementInternal _ receiver receiveHeaper.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	xmtr sendHeaper: elementInternal.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

TinyImmuSet class
	instanceVariableNames: ''!

(TinyImmuSet getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; add: #COPY; yourself)!

!TinyImmuSet class methodsFor: 'create'!

{ImmuSet} make: aHeaper {Heaper}
	^ self create: aHeaper! !