'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:07:00 pm'!

FePlaceHolder subclass: #FeGrandPlaceHolder
	instanceVariableNames: 'myID {ID}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-nkernel'!
FeGrandPlaceHolder comment:
'Fakes a PlaceHolder in the GrandMap by just remembering the key.'!

(FeGrandPlaceHolder getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #OBSOLETE; add: #SMALLTALK.ONLY; add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!FeGrandPlaceHolder methodsFor: 'client accessing'!

{FeRangeElement} again

	^CurrentGrandMap fluidGet getOrMakeFe: myID!

{BooleanVar} canMakeIdentical: newIdentity {FeRangeElement}

	(self isIdentical: newIdentity) ifFalse:
		[self unimplemented].
	^true!

{void} makeIdentical: newIdentity {FeRangeElement}
	"Consolidate this PlaceHolder to the newIdentity.  Return true if successful."

	"Check permissions
		and then try storing the other guy into the grandMap."
	self thingToDo.  "This doesn't need to force newIdentity into a BeRangeElement."
	
	(CurrentKeyMaster fluidGet hasAuthority: self owner)
		ifFalse: [Heaper BLAST: #MustBeOwner].
	(CurrentGrandMap fluidGet at: myID tryIntroduce: newIdentity getOrMakeBe)
		ifFalse: [Heaper BLAST: #CantMakeIdentical]!

{ID} owner

	"Ask the GrandMap who owns this ID"
	^CurrentGrandMap fluidGet placeOwnerID: myID!

{void} removeFillDetector: detector {FeFillDetector}

	Heaper BLAST: #NotInSet! !

!FeGrandPlaceHolder methodsFor: 'server accessing'!

{BeRangeElement | NULL} fetchBe

	^NULL!

{BeRangeElement} getOrMakeBe
	"Create a new persistent PlaceHolder and register it in the GrandMap."

	| result {BeRangeElement} |
	InitialOwner fluidBind: self owner during:
		[result _ CurrentGrandMap fluidGet newPlaceHolder.
		(CurrentGrandMap fluidGet at: myID tryIntroduce: result)
			ifTrue: [^result]
			ifFalse: [^self again getOrMakeBe]]! !

!FeGrandPlaceHolder methodsFor: 'private: create'!

create: iD {ID}

	super create.
	myID := iD! !