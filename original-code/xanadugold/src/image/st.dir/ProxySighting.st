'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:05:11 pm'!

Sighting subclass: #ProxySighting
	instanceVariableNames: 'myNumber {IntegerVar}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Xcvr'!

(ProxySighting getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #COPY; add: #NOT.A.TYPE; yourself)!

!ProxySighting methodsFor: 'creation'!

create: number {IntegerVar}
	super create.
	myNumber _ number.! !

!ProxySighting methodsFor: 'accessing'!

{BooleanVar} isProxy
	"Return true if this is a sighting for a proxy object."
	
	^true!

{IntegerVar} number
	^myNumber! !

!ProxySighting methodsFor: 'printing'!

{void} printOn: oo {ostream reference}
	oo << self getCategory name << '(' << myNumber << ')'.! !

!ProxySighting methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	myNumber _ receiver receiveIntegerVar.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	xmtr sendIntegerVar: myNumber.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

ProxySighting class
	instanceVariableNames: ''!

(ProxySighting getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #COPY; add: #NOT.A.TYPE; yourself)!

!ProxySighting class methodsFor: 'create'!

{Sighting} make: num {IntegerVar}
	^self create: num! !