'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:01:44 pm'!

ReadMemStream subclass: #DirectReadStream
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Urdi'!


"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

DirectReadStream class
	instanceVariableNames: ''!



!DirectReadStream class methodsFor: 'creation'!

{XnReadStream} make: dataP {UInt1 star} with: start {Int4} with: count {Int4}
	^self create: dataP with: start with: count! !