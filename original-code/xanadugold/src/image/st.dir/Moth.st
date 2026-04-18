'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:00:25 pm'!

Chameleon subclass: #Moth
	instanceVariableNames: 'myD {IntegerVar}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Chameleon'!

(Moth getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #(MAY.BECOME Butterfly ); add: #COPY; yourself)!

!Moth methodsFor: 'becoming'!

{void} molt
	(Butterfly new.Become: self) create! !

!Moth methodsFor: 'instance creation'!

create: d {IntegerVar}
	super create.
	myD _ d.! !

!Moth methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	myD _ receiver receiveIntegerVar.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	xmtr sendIntegerVar: myD.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

Moth class
	instanceVariableNames: ''!

(Moth getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #(MAY.BECOME Butterfly ); add: #COPY; yourself)!

!Moth class methodsFor: 'instance creation'!

make
	^self create: 4! !