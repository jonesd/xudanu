'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:06:13 pm'!

PtrArray variableSubclass: #SharedPtrArray
	instanceVariableNames: 'myShareCount {Int4}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-rparray'!

(SharedPtrArray getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #COPY; yourself)!

!SharedPtrArray methodsFor: 'accessing'!

{Int32 INLINE} shareCount
	^myShareCount!

{void INLINE} shareLess
	myShareCount _ myShareCount - 1!

{void INLINE} shareMore
	myShareCount _ myShareCount + 1!

{PrimSpec} spec

	^PrimSpec sharedPointer! !

!SharedPtrArray methodsFor: 'creation'!

create: count {Int32}

	super create: count.
	myShareCount := Int32Zero!

create: size {Int32}
	with: from {PrimIntegerArray}
	with: start {Int32}
	with: count {Int32}
	with: offset {Int32}
	
	super create: count with: from with: start with: count with: offset.
	myShareCount := Int32Zero! !

!SharedPtrArray methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	myShareCount _ receiver receiveHeaper.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	xmtr sendHeaper: myShareCount.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

SharedPtrArray class
	instanceVariableNames: ''!

(SharedPtrArray getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #COPY; yourself)!

!SharedPtrArray class methodsFor: 'pseudo constructors'!

make: count {Int32}

	^self create: count! !

!SharedPtrArray class methodsFor: 'smalltlak: passe'!

make: count {Int32} with: from {PtrArray}
	self passe.
	^self create: count with: from with: 0 with: from count with: 0! !