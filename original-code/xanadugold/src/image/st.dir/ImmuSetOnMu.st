'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:00:35 pm'!

ImmuSet subclass: #ImmuSetOnMu
	instanceVariableNames: 'setInternal {MuSet}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Collection-Sets'!

(ImmuSetOnMu getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; add: #COPY; yourself)!

!ImmuSetOnMu methodsFor: 'accessing'!

{BooleanVar} hasMember: someone {Heaper}
	^ setInternal hasMember: someone!

{BooleanVar} isEmpty
	^ setInternal isEmpty!

{BooleanVar} isSubsetOf: another {ScruSet}
	^ setInternal isSubsetOf: another! !

!ImmuSetOnMu methodsFor: 'enumerating'!

{IntegerVar} count
	^ setInternal count!

{Stepper} stepper
	^ setInternal stepper!

{Heaper} theOne
	^ setInternal theOne! !

!ImmuSetOnMu methodsFor: 'operations'!

{ImmuSet} intersect: another {ScruSet} 
	another isEmpty
		ifTrue: [ ^ ImmuSet make ]
		ifFalse:
			[| tmp {MuSet} |
			tmp _ (setInternal copy) quickCast: MuSet.
			tmp restrictTo: another.
			^ ImmuSet from: tmp]!

{ImmuSet} minus: another {ScruSet}
	another isEmpty
		ifTrue: [ ^ self ]
		ifFalse:
			[|tmp {MuSet} |
			tmp _ (setInternal copy) quickCast: MuSet.
			tmp wipeAll: another.
			^ ImmuSet from: tmp]!

{ImmuSet} unionWith: another {ScruSet}
	another isEmpty
		ifTrue: [ ^ self ]
		ifFalse:
			[| tmp {MuSet} |
			setInternal count < another count ifTrue: [^another asImmuSet unionWith: setInternal].
			tmp _ setInternal copy quickCast: MuSet.
			tmp storeAll: another.
			^ ImmuSet from: tmp]! !

!ImmuSetOnMu methodsFor: 'adding-removing'!

{ImmuSet} with: anElement {Heaper}
	|tmp {MuSet} |
	tmp _ self asMuSet.
	tmp store: anElement.
	^ ImmuSetOnMu create.MuSet: tmp!

{ImmuSet} without: anElement {Heaper}
	
	|tmp {MuSet} |
	tmp _ (setInternal copy) quickCast: MuSet.
	tmp wipe: anElement.
	^ ImmuSet from: tmp! !

!ImmuSetOnMu methodsFor: 'conversion'!

{MuSet} asMuSet
	^ (setInternal copy) cast: MuSet! !

!ImmuSetOnMu methodsFor: 'protected: create'!

create.MuSet: fromSet {MuSet}
	"this set should be a copy for my own use"
	"the pseudo constructor enforces this"
	super create.
	setInternal _ fromSet!

{void} destruct
	setInternal destroy.
	super destruct! !

!ImmuSetOnMu methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	setInternal _ receiver receiveHeaper.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	xmtr sendHeaper: setInternal.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

ImmuSetOnMu class
	instanceVariableNames: ''!

(ImmuSetOnMu getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; add: #COPY; yourself)!

!ImmuSetOnMu class methodsFor: 'creation'!

{ImmuSet} make: aSet {MuSet}
	^ self create.MuSet: aSet! !