'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:06:55 pm'!

FePlaceHolder subclass: #FeActualPlaceHolder
	instanceVariableNames: 'myRangeElement {BeRangeElement}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-nkernel'!
FeActualPlaceHolder comment:
'Actually has a persistent individual PlaceHolder on the Server, or used to, and now has a pointer to the rangeElement it became.'!

(FeActualPlaceHolder getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!FeActualPlaceHolder methodsFor: 'client accessing'!

{FeRangeElement} again

Dean shouldImplement.  "This must hold onto an FeRangeElement so that the label is properly maintained."
	myRangeElement cast: BePlaceHolder into: [:pl | ^self  "No change."]
		others: [^myRangeElement makeFe: NULL].
	^NULL "fodder"!

{BooleanVar} canMakeIdentical: newIdentity {FeRangeElement}

	(self isIdentical: newIdentity) ifFalse:
		[self unimplemented].
	^true!

{void} makeIdentical: newIdentity {FeRangeElement}
	"Consolidate this PlaceHolder to the newIdentity.  Return true if successful."
	
	"Check permissions
		and forward the operation after coercing the newIdentity
		 to a persistent RangeElement."
		
	"myRangeElement will tell me to forward to another RangeElement."
	
	(CurrentKeyMaster fluidGet hasAuthority: self owner) ifFalse:
		[Heaper BLAST: #MustBeOwner].
	myRangeElement makeIdentical: newIdentity getOrMakeBe!

{ID} owner
	"MyBeRangeElement will know it."
	
	^myRangeElement owner!

{void} removeFillDetector: detector {FeFillDetector}

	(Heaper isDestructed: myRangeElement) ifFalse:
		[myRangeElement cast: BePlaceHolder into: [ :p |
			p removeDetector: detector]
		others: []]! !

!FeActualPlaceHolder methodsFor: 'server accessing'!

{BeRangeElement | NULL} fetchBe

	^myRangeElement!

{void} forwardTo: element {BeRangeElement}
	"myRangeElement has become something else.  Forward to the new thing."
	
	myRangeElement removeFeRangeElement: self.
	myRangeElement _ element.
	myRangeElement addFeRangeElement: self.!

{BeRangeElement} getOrMakeBe

	^myRangeElement! !

!FeActualPlaceHolder methodsFor: 'private: create'!

create: be {BeRangeElement}

	super create.
	myRangeElement := be.! !

!FeActualPlaceHolder methodsFor: 'destruct'!

{void} destruct

	myRangeElement removeFeRangeElement: self.
	super destruct.! !