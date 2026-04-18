'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:56:41 pm'!

XnDependent subclass: #ListConverterSchnert
	instanceVariableNames: '
		myFromList {ListModel}
		myFromCategory {Category star}
		myToList {ListModel}
		myToCategory {Category star}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'FM-Builders'!
ListConverterSchnert comment:
'Maintains two list models in sync, using CONVERT to translate individual elements from one list to the other'!

(ListConverterSchnert getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!ListConverterSchnert methodsFor: 'create'!

create: fromList {ListModel} with: fromCategory {Category star} with: toList {ListModel} with: toCategory {Category star}
	super create.
	myFromList _ fromList.
	myFromCategory _ fromCategory.
	myToList _ toList.
	myToCategory _ toCategory.
	myFromList addDependent: self.
	myToList addDependent: self! !

!ListConverterSchnert methodsFor: 'updating'!

{void} update: change {UpdateRecord} from: model {XnModel}
	| reversed {BooleanVar} |
	myFromList == model ifTrue:
		[reversed _ false]
	ifFalse: [myToList == model ifTrue:
		[reversed _ true]
	ifFalse:
		[^VOID]].
	(change isKindOf: SingleReplaceUR) ifTrue:
		[self updateSingleReplace: reversed]
	ifFalse: [(change isKindOf: DeletionUR) ifTrue:
		[self updateDeletion: reversed
			with: (change basicCast: DeletionUR) region]
	ifFalse: [(change isKindOf: InsertionUR) ifTrue:
		[self updateInsertion: reversed
			with: (change basicCast: InsertionUR) position
			with: (change basicCast: InsertionUR) count]
	ifFalse: [(change isKindOf: RearrangeUpdate) ifTrue:
		[self updateRearrange: reversed
			with: (change basicCast: RearrangeUpdate) cut1
			with: (change basicCast: RearrangeUpdate) cut2
			with: (change basicCast: RearrangeUpdate) cut3]
	ifFalse: [(change isKindOf: RegionUR) ifTrue:
		[self unimplemented.
		"self updateRegion: reversed
			with: (change basicCast: RegionUR) region"]
	ifFalse:
		["maybe just ignore?"
		Heaper BLAST: #UnknownUpdate]]]]]! !

!ListConverterSchnert methodsFor: 'private: updating'!

{void} updateDeletion: reversed {BooleanVar} with: region {XnRegion}
	"update a deletion in one list"
	(self selectFromList: reversed not) wipe: region!

{void} updateInsertion: reversed {BooleanVar} with: position {Position} with: count {IntegerVar}
	"something has been inserted in one list"
	count ~= 1 ifTrue: [self unimplemented].
	(self selectFromList: reversed not)
		insert: (position cast: IntegerPos) asIntegerVar
		with: (Converter getConversion: (self selectFromCategory: reversed not)
			with: ((self selectFromList: reversed) get: (position cast: IntegerPos) asIntegerVar))!

{void} updateRearrange: reversed {BooleanVar} with: cut1 {IntegerVar} with: cut2 {IntegerVar} with: cut3 {IntegerVar}
	"propagate a rearrange"
	(self selectFromList: reversed not) rearrange: cut1 with: cut2 with: cut3!

{void} updateReplace: reversed {BooleanVar} with: region {XnRegion}
	"elements have been replaced"
	(region count = 1 and: [region isKindOf: IntegerRegion])
		ifFalse: [self unimplemented].
	(self selectFromList: reversed not)
		replace: (region basicCast: IntegerRegion) start
		with: (Converter getConversion: (self selectFromCategory: reversed not)
			with: ((self selectFromList: reversed) get: (region basicCast: IntegerRegion) start))!

{void} updateSingleReplace: reversed {BooleanVar}
	"the entire contents have been replaced"
	| from {ListModel} to {ListModel} cat {Category star} |
	self hack. "should have a replace entire table operation"
	from _ self selectFromList: reversed.
	to _ self selectFromList: reversed not.
	cat _ self selectFromCategory: reversed not.
	to wipe: to domain.
	from domain stepper forEach: [ :key {Position} |
		to replace: (key cast: IntegerPos) asIntegerVar
			with: (Converter getConversion: cat
				with: (from get: (key cast: IntegerPos) asIntegerVar))]! !

!ListConverterSchnert methodsFor: 'accessing'!

{Category star} fromCategory
	^myFromCategory!

{ListModel} fromList
	^myFromList!

{Category star} toCategory
	^myToCategory!

{ListModel} toList
	^myToList! !

!ListConverterSchnert methodsFor: 'private: accessing'!

{Category star} selectFromCategory: from {BooleanVar}
	"return fromCategory if true, toCategory if false"
	from ifTrue: [^myFromCategory] ifFalse: [^myToCategory]!

{ListModel} selectFromList: from {BooleanVar}
	"return fromList if true, toList if false"
	from ifTrue: [^myFromList] ifFalse: [^myToList]! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

ListConverterSchnert class
	instanceVariableNames: ''!

(ListConverterSchnert getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!ListConverterSchnert class methodsFor: 'pseudo constructors'!

make: fromList {ListModel} with: fromCategory {Category star} with: toList {ListModel} with: toCategory {Category star}
	^self create: fromList with: fromCategory with: toList with: toCategory! !