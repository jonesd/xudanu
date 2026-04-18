'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:05:07 pm'!

Sighting subclass: #ActualSighting
	instanceVariableNames: 'myNumber {IntegerVar}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Xcvr'!

(ActualSighting getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #COPY; add: #NOT.A.TYPE; yourself)!

!ActualSighting methodsFor: 'creation'!

create: number {IntegerVar}
	super create.
	myNumber _ number.! !

!ActualSighting methodsFor: 'accessing'!

{BooleanVar} isProxy
	"Return true if this is a sighting for a proxy object."
	
	^false!

{IntegerVar} number
	^myNumber! !

!ActualSighting methodsFor: 'printing'!

{void} printOn: oo {ostream reference}
	oo << self getCategory name << '(' << myNumber << ')'.! !

!ActualSighting methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	myNumber _ receiver receiveIntegerVar.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	xmtr sendIntegerVar: myNumber.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

ActualSighting class
	instanceVariableNames: ''!

(ActualSighting getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #COPY; add: #NOT.A.TYPE; yourself)!

!ActualSighting class methodsFor: 'create'!

{Sighting} make: num {IntegerVar}
	^self create: num! !