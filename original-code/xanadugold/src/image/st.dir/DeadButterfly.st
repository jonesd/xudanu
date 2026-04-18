'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:04:26 pm'!

Chameleon subclass: #DeadButterfly
	instanceVariableNames: '
		myJ {IntegerVar}
		myK {Heaper}
		myL {Heaper}
		myM {Heaper}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Cxx-class-stuff'!

(DeadButterfly getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #COPY; yourself)!

!DeadButterfly methodsFor: 'instance creation'!

create
	super create.
	myJ _ IntegerVar0.
	myK _ NULL.! !

!DeadButterfly methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	myJ _ receiver receiveIntegerVar.
	myK _ receiver receiveHeaper.
	myL _ receiver receiveHeaper.
	myM _ receiver receiveHeaper.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	xmtr sendIntegerVar: myJ.
	xmtr sendHeaper: myK.
	xmtr sendHeaper: myL.
	xmtr sendHeaper: myM.! !