'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:07:04 pm'!

FePlaceHolder subclass: #FeVirtualPlaceHolder
	instanceVariableNames: '
		myEdition {BeEdition}
		myKey {Position}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-nkernel'!
FeVirtualPlaceHolder comment:
'Fakes a PlaceHolder by having an Edition and a key.'!

(FeVirtualPlaceHolder getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!FeVirtualPlaceHolder methodsFor: 'client accessing'!

{FeRangeElement} again

	^myEdition get: myKey!

{BooleanVar} canMakeIdentical: newIdentity {FeRangeElement}

	(self isIdentical: newIdentity) ifFalse:
		[self unimplemented].
	^true!

{void} makeIdentical: newIdentity {FeRangeElement}
	"Consolidate this PlaceHolder to the newIdentity.  Return true if successful."

	"Check permissions
		and coerce both of us and have the BeRangeElements try."
	self thingToDo.  "This doesn't need to force newIdentity into a BeRangeElement."
	
	(CurrentKeyMaster fluidGet hasAuthority: self owner)
		ifFalse: [Heaper BLAST: #MustBeOwner].
	self getOrMakeBe makeIdentical: newIdentity getOrMakeBe!

{ID} owner

	^myEdition ownerAt: myKey!

{void} removeFillDetector: detector {FeFillDetector}

	Heaper BLAST: #NotInSet! !

!FeVirtualPlaceHolder methodsFor: 'server accessing'!

{BeRangeElement | NULL} fetchBe

	^NULL!

{BeRangeElement} getOrMakeBe
	"Force the ent to generate a beRangeElement at myKey."
	
	^myEdition getOrMakeBe: myKey! !

!FeVirtualPlaceHolder methodsFor: 'private: create'!

create: edition {BeEdition} with: key {Position}

	super create.
	myEdition := edition.
	myKey := key! !