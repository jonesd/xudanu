'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:04:44 pm'!

XnDependent subclass: #LinkTypeList2WordArrayListSchnert
	instanceVariableNames: '
		myLinkTypeList {ListModel of: PackOBits}
		myLinkTypeNameList {ListModel of: MuWordArray}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-linkmkr'!
LinkTypeList2WordArrayListSchnert comment:
'This class maintains a list of readable link types from the linkType list in the UserModel'!

(LinkTypeList2WordArrayListSchnert getOrMakeCxxClassDescription)
	friends:
'/* friends for class LinkTypeList2WordArrayListSchnert */
friend SPTR(LinkTypeList2WordArrayListSchnert)
	 linkTypeList2WordArrayListSchnert (ListModel * a, ListModel * b);';
	attributes: ((Set new) add: #CONCRETE; yourself)!

!LinkTypeList2WordArrayListSchnert methodsFor: 'private: creation'!

create: onLinkTypes {ListModel} with: linkTypeDescriptions {ListModel}

	super create.
	myLinkTypeList _ onLinkTypes.
	myLinkTypeNameList _ linkTypeDescriptions! !

!LinkTypeList2WordArrayListSchnert methodsFor: 'updating'!

{void} syncLists

	myLinkTypeNameList wipe: (myLinkTypeNameList domain).
	IntegerVar0 almostTo: myLinkTypeList count do: [:index {IntegerVar} |
		myLinkTypeNameList insert: index with: (self extractAndConvertToWordArray: index)].!

{void} update: ur {UpdateRecord} from: sender {XnModel}
	sender == myLinkTypeList
		ifTrue: [(ur isKindOf: InsertionUR)
			ifTrue: [self insertLinkUpdate: (ur basicCast:
InsertionUR) index]
		ifFalse: [(ur isKindOf: DeletionUR)
			ifTrue: [self removeLinkUpdate: (ur basicCast:
DeletionUR) region]
		ifFalse: [Heaper BLAST: #INVALID.U.UPDATE.U.RECORD]]]
	ifFalse: [(sender == myLinkTypeNameList)
		ifTrue: ["nada fer now"]
	ifFalse: [Heaper BLAST: #WhyDidIGetThis.U.Interogative]]! !

!LinkTypeList2WordArrayListSchnert methodsFor: 'private: schnerting'!

{Pair of: MuWordArray and: MuWordArray} extractAndConvertToWordArray: index {IntegerVar} 
	| linkTypeDoc {LinkTypeDescription} res {MuWordArray}
	 left {MuWordArray} right {MuWordArray} first {MuWordArray} |
	linkTypeDoc _ LinkTypeDescription
		defaultDescription: Application fluidGet user keyMaster
		with: ((myLinkTypeList get: index) cast: ID).
	left _ (linkTypeDoc leftLabel cast: XuText) asDataTable asMuTable cast: MuWordArray.
	right _ (linkTypeDoc rightLabel cast: XuText) asDataTable asMuTable cast: MuWordArray.
	res _ left copy cast: MuWordArray.
	res introduceAll: (MuWordArray make.charVector: ' ... ') with: (IntegerMapping make: res count).
	res introduceAll: right with: (IntegerMapping make: res count).
	first _ res.
	res _ right copy cast: MuWordArray.
	res introduceAll: (MuWordArray make.charVector: ' ... ') with: (IntegerMapping make: res count).
	res introduceAll: left with: (IntegerMapping make: res count).

	linkTypeDoc destroy.
	^Pair make: first with: res!

{void} insertLinkUpdate: where {IntegerVar}

	myLinkTypeNameList insert: where with: (self extractAndConvertToWordArray: where)!

{void} removeLinkUpdate: where {XnRegion}

	myLinkTypeNameList wipe: where! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

LinkTypeList2WordArrayListSchnert class
	instanceVariableNames: ''!

(LinkTypeList2WordArrayListSchnert getOrMakeCxxClassDescription)
	friends:
'/* friends for class LinkTypeList2WordArrayListSchnert */
friend SPTR(LinkTypeList2WordArrayListSchnert)
	 linkTypeList2WordArrayListSchnert (ListModel * a, ListModel * b);';
	attributes: ((Set new) add: #CONCRETE; yourself)!

!LinkTypeList2WordArrayListSchnert class methodsFor: 'pseudoConstructors'!

make: a {ListModel} with: b {ListModel}
	^ self create: a with: b! !