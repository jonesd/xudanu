'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:08:17 pm'!

Portal subclass: #PairPortal
	instanceVariableNames: '
		myReadStream {XnReadStream}
		myWriteStream {XnWriteStream}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-proman'!

(PairPortal getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!PairPortal methodsFor: 'accessing'!

{XnReadStream} readStream
	
	^myReadStream!

{XnWriteStream} writeStream
	
	^myWriteStream! !

!PairPortal methodsFor: 'protected: creation'!

create: readStr {XnReadStream} with: writeStr {XnWriteStream}
	super create.
	myReadStream _ readStr.
	myWriteStream _ writeStr!

{void} destruct
	myReadStream destroy.
	myWriteStream destroy.
	super destruct! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

PairPortal class
	instanceVariableNames: ''!

(PairPortal getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!PairPortal class methodsFor: 'creation'!

make: read {XnReadStream} with: write {XnWriteStream}
	^self create: read with: write! !