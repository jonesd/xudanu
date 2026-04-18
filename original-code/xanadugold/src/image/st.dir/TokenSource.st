'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:08:32 pm'!

Heaper subclass: #TokenSource
	instanceVariableNames: '
		myAvailable {Int32Array}
		myAvailableCount {Int32}
		myCeiling {Int32}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-tokens'!
TokenSource comment:
'Manage a set of integerVars as tokens.  The Available array is tokens that have been returned to the pool.  They get used in preference to allocating new ones so that we keep the numbers dense.'!

(TokenSource getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #EQ; yourself)!

!TokenSource methodsFor: 'accessing'!

{void} returnToken: token {Int32}
	token == myCeiling ifTrue: [
		myCeiling _ myCeiling - 1.
		^VOID
	].
	myAvailableCount >= myAvailable count ifTrue: [
		myAvailable _ (myAvailable copyGrow: myAvailableCount+1) cast: Int32Array.
	].
	myAvailable at: myAvailableCount storeInt: token.
	myAvailableCount _ myAvailableCount + 1.!

{Int32} takeToken
	myAvailableCount > Int32Zero ifTrue: [
		myAvailableCount _ myAvailableCount - 1.
		^myAvailable intAt: myAvailableCount.
	] ifFalse: [
		myCeiling _ myCeiling + 1.
		^myCeiling
	]! !

!TokenSource methodsFor: 'creation'!

create
	super create.
	myAvailable _ Int32Array make: 10.
	myAvailableCount _ Int32Zero.
	myCeiling _ Int32Zero! !

!TokenSource methodsFor: 'generated:'!

actualHashForEqual ^self asOop!

isEqual: other ^self == other! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

TokenSource class
	instanceVariableNames: ''!

(TokenSource getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #EQ; yourself)!

!TokenSource class methodsFor: 'creation'!

make
	^TokenSource create! !