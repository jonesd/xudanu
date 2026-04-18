'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:01:46 pm'!

Heaper subclass: #SnarfHandle
	instanceVariableNames: '
		mySnarfID {UInt4}
		myContents {char star}
		myUrdi {Urdi}
		isWritable {BooleanVar}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Urdi'!

(SnarfHandle getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!SnarfHandle methodsFor: 'accessing'!

{char star} getDataP
	^myContents!

{Int4} getDataSize
	^myContents count!

{SnarfID} getSnarfID
	^mySnarfID!

{BooleanVar} isWritable
	^isWritable!

{void} makeWritable
	isWritable _ true!

{SnarfID} snarfID
	^mySnarfID!

{void} thaw
	"Release the memory buffer locked into place for this snarfHandle."
	
	self unimplemented.
	isWritable ifTrue: [myUrdi writeHandle: mySnarfID with: myContents].
	myUrdi releaseHandle: mySnarfID.! !

!SnarfHandle methodsFor: 'data manipulation'!

{void} at: index {Int32} put32: word {Int32}
	"Store the supplied word into the snarf starting at index.  Put the high byte first."

	isWritable assert: 'Must be writable'.
	myContents at: index storeUInt: (word bitShiftRight: 24).
	myContents at: index+1 storeUInt: ((word bitShiftRight: 16) bitAnd: 255).
	myContents at: index+2 storeUInt: ((word bitShiftRight: 8) bitAnd: 255).
	myContents at: index+3 storeUInt: (word bitAnd: 255).!

{Int32} get32: index {Int32} 
	"Return the Int4 represented by the 4 bytes starting at index, high byte first.  This must return a negative number when appropriate."

	| guts {String} result {Int32} |
	guts _ myContents gutsOf.
	result _ guts basicAt: index + 1.
	result _ (result bitShift: 8) + (guts basicAt: index + 2).
	result _ (result bitShift: 8) + (guts basicAt: index + 3).
	result _ (result bitShift: 8) + (guts basicAt: index + 4).
	^result!

{void} moveBytes: start {Int4} with: newStart {Int4} with: nBytes {Int4}
	isWritable assert: 'Must be writable'.
	myContents at: newStart storeMany: myContents with: nBytes with: start! !

!SnarfHandle methodsFor: 'printing'!

{void} printOn: oo {ostream reference}
	oo << self getCategory name << '(' << mySnarfID << ')'! !

!SnarfHandle methodsFor: 'protected: destruct'!

{void} destruct
	"When a handle keeping a snarf in memory is destroyed, the snarf can then move around or go off to disk."

	isWritable ifTrue: [myUrdi writeHandle: mySnarfID with: myContents].
	myUrdi releaseHandle: mySnarfID.
	super destruct! !

!SnarfHandle methodsFor: 'create'!

create: snarfID {SnarfID} with: contents {UInt32Array} with: urdi {Urdi}
	super create.
	mySnarfID _ snarfID.
	myContents _ contents.
	myUrdi _ urdi.
	isWritable _ false! !