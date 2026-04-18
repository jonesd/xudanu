'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:07:04 pm'!

FeDataHolder subclass: #FeVirtualDataHolder
	instanceVariableNames: '
		myValue {PrimValue}
		myKey {Position}
		myEdition {BeEdition}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-nkernel'!
FeVirtualDataHolder comment:
'Fakes a DataHolder by having an Edition and a key.'!

(FeVirtualDataHolder getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!FeVirtualDataHolder methodsFor: 'accessing'!

{FeRangeElement} again
	"Fetch from my Edition again, just in case I've been consolidated."
	
	^myEdition fetch: myKey!

{BooleanVar} isIdentical: other {FeRangeElement}

	"This can do a version comparison (which seems a bit extreme)."
	Dean shouldImplement.
	^false "fodder"!

{ID} owner

	^myEdition ownerAt: myKey!

{PrimValue} value
	^myValue! !

!FeVirtualDataHolder methodsFor: 'server accessing'!

{BeRangeElement | NULL} fetchBe

	^NULL!

{BeRangeElement} getOrMakeBe
	"Force the ent to generate a beRangeElement at myKey."
	
	^myEdition getOrMakeBe: myKey! !

!FeVirtualDataHolder methodsFor: 'private: create'!

create: value {PrimValue}
	with: key {Position}
	with: edition {BeEdition}
	
	super create.
	myValue := value.
	myKey := key.
	myEdition := edition.! !