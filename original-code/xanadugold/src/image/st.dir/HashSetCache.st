'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:00:26 pm'!

Heaper subclass: #HashSetCache
	instanceVariableNames: '
		mySize {UInt32}
		myElements {PtrArray}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Collection-Cache'!

(HashSetCache getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #EQ; add: #COPY; yourself)!

!HashSetCache methodsFor: 'accessing'!

{BooleanVar} hasMember: aHeaper {Heaper}
	| index {UInt32 register} val {Heaper | NULL} |
	index _ aHeaper hashForEqual \\ mySize.
	(index < UInt32Zero or: [index >= mySize]) ifTrue: [Heaper BLAST: #ModuloFailed].
	val _ myElements fetch: index.
	^val ~~ NULL and: [aHeaper isEqual: val]!

{void} store: aHeaper {Heaper} 
	| index {UInt32 register} |
	index _ aHeaper hashForEqual \\ mySize.
	(index < UInt32Zero or: [index >= mySize]) ifTrue: [Heaper BLAST: #ModuloFailed].
	myElements at: index store: aHeaper!

{void} wipe: aHeaper {Heaper} 
	| index {UInt32 register} val {Heaper | NULL} |
	index _ aHeaper hashForEqual \\ mySize.
	(index < UInt32Zero or: [index >= mySize]) ifTrue: [Heaper BLAST: #ModuloFailed].
	val _ myElements fetch: index.
	(val ~~ NULL and: [aHeaper isEqual: val])
		ifTrue: [myElements at: index store: NULL]! !

!HashSetCache methodsFor: 'create/delete'!

create: size {UInt32}
	super create.
	mySize _ size.
	myElements _ PtrArray nulls: mySize! !

!HashSetCache methodsFor: 'protected: creation'!

{void} destruct
	myElements _ NULL.
	mySize _ UInt32Zero.
	super destruct! !

!HashSetCache methodsFor: 'generated:'!

actualHashForEqual ^self asOop!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	mySize _ receiver receiveUInt32.
	myElements _ receiver receiveHeaper.!

isEqual: other ^self == other!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	xmtr sendUInt32: mySize.
	xmtr sendHeaper: myElements.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

HashSetCache class
	instanceVariableNames: ''!

(HashSetCache getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #EQ; add: #COPY; yourself)!

!HashSetCache class methodsFor: 'pseudo-constructors'!

make
	^self create: 10!

make: size {UInt32}
	^self create: size! !