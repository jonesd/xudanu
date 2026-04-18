'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:02:34 pm'!

MuSet subclass: #WimpyMuSet
	instanceVariableNames: 'mySet {MuSet}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Collection-Wimpy'!
WimpyMuSet comment:
'Note that this is not a COPY class.  Wimpy COPY collections are guaranteed to break if a GC happens
while they are being received.'!

(WimpyMuSet getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #COPY; yourself)!

!WimpyMuSet methodsFor: 'enumerating'!

{IntegerVar} count
	^mySet count!

{Stepper} stepper
	^WimpyStepper create: (mySet stepper)! !

!WimpyMuSet methodsFor: 'accessing'!

{void} introduce: anElement {Heaper}
	| cell {Heaper} |
	cell _ WimpyCell create: anElement.
	mySet introduce: cell!

{void} remove: anElement {Heaper}
	| cell {Heaper} |
	cell _ WimpyCell create: anElement.
	mySet remove: cell!

{void} store: anElement {Heaper}
	| cell {Heaper} |
	cell _ WimpyCell create: anElement.
	mySet store: cell!

{void} wipe: anElement {Heaper}
	| cell {Heaper} |
	cell _ WimpyCell create: anElement.
	mySet wipe: cell! !

!WimpyMuSet methodsFor: 'testing'!

{BooleanVar} hasMember: someone {Heaper}
	| cell {Heaper} |
	cell _ WimpyCell create: someone.
	^mySet hasMember: cell!

{BooleanVar} isEmpty
	^mySet isEmpty! !

!WimpyMuSet methodsFor: 'creation'!

{ScruSet} copy
	^WimpyMuSet create: (mySet copy cast: MuSet)!

create: set {MuSet}
	super create.
	mySet _ set! !

!WimpyMuSet methodsFor: 'private: enumerating'!

{Stepper} immuStepper
	self hack.
	^ self stepper! !

!WimpyMuSet methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	mySet _ receiver receiveHeaper.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	xmtr sendHeaper: mySet.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

WimpyMuSet class
	instanceVariableNames: ''!

(WimpyMuSet getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #COPY; yourself)!

!WimpyMuSet class methodsFor: 'pseudo-constructors'!

make
	^self create: MuSet make!

make: set {MuSet}
	^self create: set! !