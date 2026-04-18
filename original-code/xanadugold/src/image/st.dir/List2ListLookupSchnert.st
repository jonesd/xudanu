'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:02:53 pm'!

XnDependent subclass: #List2ListLookupSchnert
	instanceVariableNames: '
		myFromList {ListModel}
		myToList {ListModel}
		myLookup {LookupTool}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-usermod'!

(List2ListLookupSchnert getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!List2ListLookupSchnert methodsFor: 'creation'!

create: fromList {ListModel} with: toList {ListModel} with: lookup {LookupTool}

	super create.
	myFromList _ fromList.
	myToList _ toList.
	myLookup _ lookup.
	myFromList addDependent: self.
	self updateSingleReplace! !

!List2ListLookupSchnert methodsFor: 'updating'!

{void} update: ur {UpdateRecord} from: sender {XnModel}

	(ur isKindOf: SingleReplaceUR)
		ifTrue: [self updateSingleReplace]
	ifFalse: [(ur isKindOf: DeletionUR)
		ifTrue: [self updateDeletion: (ur basicCast: DeletionUR) region]
	ifFalse: [(ur isKindOf: InsertionUR)
		ifTrue: [self updateInsertion: (ur basicCast: InsertionUR) position
					with: (ur basicCast: InsertionUR) count]
	ifFalse: [(ur isKindOf: RearrangeUpdate)
		ifTrue: [| ra {RearrangeUpdate wimpy} |
			ra _ ur basicCast: RearrangeUpdate.
			self updateRearrange: ra cut1 with: ra cut2 with: ra cut3]
	ifFalse: [(ur isKindOf: RegionUR)
		ifTrue: [self updateReplace: (ur basicCast: RegionUR) region]]]]]! !

!List2ListLookupSchnert methodsFor: 'private: updating'!

{void} updateDeletion: region {XnRegion}
	"update a deletion in one list"
	myToList wipe: region!

{void} updateInsertion: pos {Position} with: count {IntegerVar}

	| iPos {IntegerVar} |
	count ~= 1 ifTrue: [self unimplemented. ^ VOID].
	iPos _ (pos cast: IntegerPos) asIntegerVar.
	myToList insert: iPos with: (myLookup lookup: (myFromList get: iPos))!

{void} updateRearrange: cut1 {IntegerVar} with: cut2 {IntegerVar} with: cut3 {IntegerVar}
	"propagate a rearrange"
	myToList rearrange: cut1 with: cut2 with: cut3!

{void} updateReplace: region {XnRegion} 
	"elements have been replaced"

	| fromPos {IntegerVar} |
	(region count = 1 and: [region isKindOf: IntegerRegion])
		ifFalse: [self unimplemented].
	fromPos _ (region basicCast: IntegerRegion) start.
	myToList replace: fromPos with: (myLookup lookup: (myFromList get: fromPos))!

{void} updateSingleReplace
	"the entire contents have been replaced"

	myToList wipe: myToList domain.
	myFromList domain stepper forEach: [ :key {Position} |
		myToList replace: (key cast: IntegerPos) asIntegerVar with: 
			(myLookup lookup: (myFromList get: (key cast: IntegerPos) asIntegerVar))]! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

List2ListLookupSchnert class
	instanceVariableNames: ''!

(List2ListLookupSchnert getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!List2ListLookupSchnert class methodsFor: 'make'!

make: from {ListModel} with: to {ListModel} with: look {LookupTool}
	^ self create: from with: to with: look! !