'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:07:00 pm'!

FeRangeElement subclass: #FeIDHolder
	instanceVariableNames: 'myBeIDHolder {BeIDHolder}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-nkernel'!
FeIDHolder comment:
'An object for having an ID in the range of an Edition. Tentative feature.'!

(FeIDHolder getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #ON.CLIENT; add: #CONCRETE; yourself)!

!FeIDHolder methodsFor: 'accessing'!

{FeRangeElement} again

	^self!

{BooleanVar} canMakeIdentical: newIdentity {FeRangeElement}

	(self isIdentical: newIdentity) ifFalse:
		[self unimplemented].
	^true!

{ID CLIENT} iD
	"Essential.  The ID in this holder."
	
	^myBeIDHolder iD!

{void} makeIdentical: newIdentity {FeRangeElement}

	(self isIdentical: newIdentity) ifFalse:
		[self unimplemented]! !

!FeIDHolder methodsFor: 'server accessing'!

{BeRangeElement | NULL} fetchBe

	^myBeIDHolder!

{BeRangeElement} getOrMakeBe

	^myBeIDHolder! !

!FeIDHolder methodsFor: 'private: create'!

create: be {BeIDHolder}

	super create.
	myBeIDHolder := be.! !

!FeIDHolder methodsFor: 'printing'!

{void} printOn: oo {ostream reference}

	oo << 'IDHolder(' << self iD << ')'! !

!FeIDHolder methodsFor: 'destruct'!

{void} destruct

	myBeIDHolder removeFeRangeElement: self.
	super destruct.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

FeIDHolder class
	instanceVariableNames: ''!

(FeIDHolder getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #ON.CLIENT; add: #CONCRETE; yourself)!

!FeIDHolder class methodsFor: 'creation'!

{FeIDHolder CLIENT} make: iD {ID}
	"Essential. Make a single IDHolder with the given ID. Tentative feature."
	
	^FeIDHolder on: (CurrentGrandMap fluidGet newIDHolder: iD)!

{FeIDHolder} on: be {BeIDHolder}

	| result {FeIDHolder} |
	result := self create: be.
	be addFeRangeElement: result.
	^result! !

!FeIDHolder class methodsFor: 'smalltalk: system'!

info.stProtocol
"{ID CLIENT} iD
"! !