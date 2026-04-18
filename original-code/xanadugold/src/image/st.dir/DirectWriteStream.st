'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:01:45 pm'!

WriteMemStream subclass: #DirectWriteStream
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Urdi'!



!DirectWriteStream methodsFor: 'accessing'!

{void} flush! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

DirectWriteStream class
	instanceVariableNames: ''!



!DirectWriteStream class methodsFor: 'creation'!

{XnWriteStream} make: dataP {UInt1 star} with: start {Int4} with: count {Int4}
	^self create: dataP with: start with: count! !