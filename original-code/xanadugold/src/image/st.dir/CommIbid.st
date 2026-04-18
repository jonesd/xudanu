'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:05:09 pm'!

Heaper subclass: #CommIbid
	instanceVariableNames: 'myNumber {IntegerVar}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Xcvr'!

(CommIbid getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #COPY; yourself)!

!CommIbid methodsFor: 'creation'!

create: number {IntegerVar}
	super create.
	myNumber _ number.! !

!CommIbid methodsFor: 'accessing'!

{IntegerVar} number
	^myNumber! !

!CommIbid methodsFor: 'printing'!

{void} printOn: oo {ostream reference}
	oo << self getCategory name << '(' << myNumber << ')'.! !

!CommIbid methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	myNumber _ receiver receiveIntegerVar.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	xmtr sendIntegerVar: myNumber.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

CommIbid class
	instanceVariableNames: ''!

(CommIbid getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #COPY; yourself)!

!CommIbid class methodsFor: 'creation'!

make: number {IntegerVar} 
	^self create: number! !