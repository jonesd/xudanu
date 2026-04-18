'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:00:23 pm'!

Chameleon subclass: #Butterfly
	instanceVariableNames: '
		myE {IntegerVar}
		myF {Heaper}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Chameleon'!

(Butterfly getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #COPY; yourself)!

!Butterfly methodsFor: 'instance creation'!

create
	super create.
	myE _ IntegerVar0.
	myF _ NULL.! !

!Butterfly methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	myE _ receiver receiveIntegerVar.
	myF _ receiver receiveHeaper.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	xmtr sendIntegerVar: myE.
	xmtr sendHeaper: myF.! !