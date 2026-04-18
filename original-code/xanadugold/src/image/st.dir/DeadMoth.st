'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:00:24 pm'!

Chameleon subclass: #DeadMoth
	instanceVariableNames: '
		myG {IntegerVar}
		myH {Heaper}
		myI {BooleanVar}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Chameleon'!

(DeadMoth getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #COPY; yourself)!

!DeadMoth methodsFor: 'instance creation'!

create
	super create.
	myG _ IntegerVar0.
	myH _ NULL.
	myI _ false.! !

!DeadMoth methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	myG _ receiver receiveIntegerVar.
	myH _ receiver receiveHeaper.
	myI _ receiver receiveBooleanVar.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	xmtr sendIntegerVar: myG.
	xmtr sendHeaper: myH.
	xmtr sendBooleanVar: myI.! !