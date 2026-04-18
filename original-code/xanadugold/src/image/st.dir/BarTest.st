'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:05:05 pm'!

Heaper subclass: #BarTest
	instanceVariableNames: 'myFoo {FooTest}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Calc'!

(BarTest getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #EQ; add: #COPY; yourself)!

!BarTest methodsFor: 'accessing'!

{char star} sayMe

	^'Bar'.!

{char star} sayOther

	^myFoo sayMe!

{char star} sayOtherOther

	^myFoo sayOther! !

!BarTest methodsFor: 'creation'!

create: foo {FooTest}

	super create.
	myFoo _ foo! !

!BarTest methodsFor: 'printing'!

{void} printOn: oo {ostream reference}
	oo << self getCategory name << '(' << self hashForEqual << ', Foo#' << myFoo hashForEqual << ')'! !

!BarTest methodsFor: 'generated:'!

actualHashForEqual ^self asOop!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	myFoo _ receiver receiveHeaper.!

isEqual: other ^self == other!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	xmtr sendHeaper: myFoo.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

BarTest class
	instanceVariableNames: ''!

(BarTest getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #EQ; add: #COPY; yourself)!

!BarTest class methodsFor: 'creation'!

make: foo {FooTest}

	^self create: foo! !