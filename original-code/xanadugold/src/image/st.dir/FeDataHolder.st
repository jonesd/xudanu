'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:06:57 pm'!

FeRangeElement subclass: #FeDataHolder
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-nkernel'!
FeDataHolder comment:
'The kind of FeRangeElement that represents a piece of data in the Server, along with its identity.'!

(FeDataHolder getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #ON.CLIENT; add: #DEFERRED; yourself)!

!FeDataHolder methodsFor: 'client accessing'!

{FeRangeElement} again

	self subclassResponsibility!

{BooleanVar} canMakeIdentical: newIdentity {FeRangeElement}
	
	"Check that it is data with the same value,
		and check permissions,
		and forward the operation after coercing the newIdentity to a persistent RangeElement."
	
	^((newIdentity isKindOf: FeDataHolder)
			and: [((newIdentity cast: FeDataHolder) value isEqual: self value)])!

{void} makeIdentical: newIdentity {FeRangeElement}
	"Allow consolidation of data in 1st product."
	| ckm {FeKeyMaster} |
	"Check that it is data with the same value,
		and check permissions,
		and forward the operation after coercing the newIdentity to a persistent RangeElement."
	
	self thingToDo. "better blast"
	ckm := CurrentKeyMaster fluidGet.
	((newIdentity isKindOf: FeDataHolder)
			and: [((newIdentity cast: FeDataHolder) value isEqual: self value)
			and: [ckm hasAuthority: self owner]])
		ifTrue: [Heaper BLAST: #CantMakeIdentical].
	self getOrMakeBe makeIdentical: newIdentity getOrMakeBe!

{PrimValue CLIENT} value
	"Essential.  The actual data value"
	
	self subclassResponsibility! !

!FeDataHolder methodsFor: 'server accessing'!

{BeRangeElement | NULL} fetchBe

	self subclassResponsibility!

{BeRangeElement} getOrMakeBe

	self subclassResponsibility! !

!FeDataHolder methodsFor: 'printing'!

{void} printOn: oo {ostream reference}

	oo << 'DataHolder(' << self value << ')'! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

FeDataHolder class
	instanceVariableNames: ''!

(FeDataHolder getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #ON.CLIENT; add: #DEFERRED; yourself)!

!FeDataHolder class methodsFor: 'creation'!

{FeDataHolder} fake: value {PrimValue}
	with: key {Position}
	with: edition {BeEdition}
	
	^FeVirtualDataHolder create: value with: key with: edition.!

{FeDataHolder CLIENT} make: value {PrimValue}
	"Make a single DataHolder with the given value"
	
	^FeDataHolder on: (CurrentGrandMap fluidGet newDataHolder: value)!

{FeDataHolder} on: be {BeDataHolder}

	| result {FeDataHolder} |
	result := FeActualDataHolder create: be.
	be addFeRangeElement: result.
	^result! !

!FeDataHolder class methodsFor: 'smalltalk: system'!

info.stProtocol
"{PrimValue CLIENT} value
"! !