'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:05:05 pm'!

Heaper subclass: #FooTest
	instanceVariableNames: 'myBar {BarTest}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Calc'!

(FooTest getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #EQ; add: #COPY; yourself)!

!FooTest methodsFor: 'creation'!

create

	super create.
	myBar _ BarTest make: self! !

!FooTest methodsFor: 'accessing'!

{char star} sayMe

	^'Foo'.!

{char star} sayOther

	^myBar sayMe!

{char star} sayOtherOther

	^myBar sayOther! !

!FooTest methodsFor: 'printing'!

{void} printOn: oo {ostream reference}
	oo << self getCategory name << '(' << self hashForEqual << ', Bar#' << myBar hashForEqual << ')'! !

!FooTest methodsFor: 'generated:'!

actualHashForEqual ^self asOop!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	myBar _ receiver receiveHeaper.!

isEqual: other ^self == other!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	xmtr sendHeaper: myBar.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

FooTest class
	instanceVariableNames: ''!

(FooTest getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #EQ; add: #COPY; yourself)!

!FooTest class methodsFor: 'creation'!

make
	^self create! !