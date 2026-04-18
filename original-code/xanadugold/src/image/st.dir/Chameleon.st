'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:00:24 pm'!

Heaper subclass: #Chameleon
	instanceVariableNames: '
		myA {IntegerVar}
		myB {Heaper}
		myC {BooleanVar}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Chameleon'!

(Chameleon getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #COPY; yourself)!

!Chameleon methodsFor: 'instance creation'!

create
	super create.
	myA _ IntegerVar0.
	myB _ NULL.
	myC _ false.!

create: a {IntegerVar} with: b {Heaper} with: c {BooleanVar}
	super create.
	myA _ a.
	myB _ b.
	myC _ c.! !

!Chameleon methodsFor: 'accessing'!

{void} explain: oo {ostream reference}
	oo << self getCategory name << '
'.! !

!Chameleon methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	myA _ receiver receiveIntegerVar.
	myB _ receiver receiveHeaper.
	myC _ receiver receiveBooleanVar.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	xmtr sendIntegerVar: myA.
	xmtr sendHeaper: myB.
	xmtr sendBooleanVar: myC.! !