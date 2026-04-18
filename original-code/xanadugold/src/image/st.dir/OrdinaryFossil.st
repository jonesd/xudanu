'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:06:22 pm'!

Fossil subclass: #OrdinaryFossil
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-fossil'!
OrdinaryFossil comment:
'A Fossil for most ordinary kinds of Waldos.'!

(OrdinaryFossil getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #SHEPHERD.PATRIARCH; add: #COPY; add: #LOCKED; add: #OBSOLETE; add: #CONCRETE; yourself)!

!OrdinaryFossil methodsFor: 'protected: accessing'!

{Waldo} makeWaldo: km {KeyMaster unused} with: tip {Manipulator}

	^XuServer currentServer wrap: self workType with: tip! !

!OrdinaryFossil methodsFor: 'create'!

create: gm {GrandMap}
	with: iObject {IObject}
	with: workType {PackOBits}
	with: clubsAndFilters {ImmuTable of: ID and: Filter}
	with: user {ID}
	
	super create: gm with: iObject with: workType with: clubsAndFilters with: user.
	self newShepherd.
	self remember! !

!OrdinaryFossil methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.! !