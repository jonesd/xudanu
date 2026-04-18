'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:07:01 pm'!

FeRangeElement subclass: #FePlaceHolder
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-nkernel'!
FePlaceHolder comment:
'Represents a piece of pure identity in the Server.'!

(FePlaceHolder getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #DEFERRED; yourself)!

!FePlaceHolder methodsFor: 'accessing'!

{void} addFillDetector: detector {FeFillDetector}

	self getOrMakeBe cast: BePlaceHolder into: [ :p |
		p addDetector: detector]
	others:
		["in case it changed behind our backs"
		detector filled: self again]!

{FeRangeElement} again

	self subclassResponsibility!

{BooleanVar} canMakeIdentical: newIdentity {FeRangeElement}

	self subclassResponsibility!

{void} makeIdentical: newIdentity {FeRangeElement}

	self subclassResponsibility! !

!FePlaceHolder methodsFor: 'server accessing'!

{BeRangeElement | NULL} fetchBe

	self subclassResponsibility!

{BeRangeElement} getOrMakeBe

	self subclassResponsibility! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

FePlaceHolder class
	instanceVariableNames: ''!

(FePlaceHolder getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #DEFERRED; yourself)!

!FePlaceHolder class methodsFor: 'creation'!

{FePlaceHolder} fake: edition {BeEdition} with: key {Position}

	^FeVirtualPlaceHolder create: edition with: key!

{FePlaceHolder} on: be {BeRangeElement}

	| result {FeRangeElement} |
	result := FeActualPlaceHolder create: be.
	be addFeRangeElement: result.
	^result cast: FePlaceHolder! !

!FePlaceHolder class methodsFor: 'smalltalk: passe'!

{FePlaceHolder} grand: iD {ID}

	self passe.! !