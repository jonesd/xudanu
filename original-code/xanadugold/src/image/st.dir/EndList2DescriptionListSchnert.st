'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:04:44 pm'!

XnDependent subclass: #EndList2DescriptionListSchnert
	instanceVariableNames: '
		myEndModel {LinkEndsModel}
		myDescriptionListModel {ListModel of: AttributedTextModel}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-linkmkr'!
EndList2DescriptionListSchnert comment:
'This class maintains the relationship of the visible list of linkends (the description list) with the actual list (a LinkEndsModel)'!

(EndList2DescriptionListSchnert getOrMakeCxxClassDescription)
	friends:
'/* friends for class EndList2DescriptionListSchnert */
friend SPTR(EndList2DescriptionListSchnert) endList2DescriptionListSchnert (
													LinkEndsModel * onEndList, 
													ListModel * descriptions);';
	attributes: ((Set new) add: #CONCRETE; yourself)!

!EndList2DescriptionListSchnert methodsFor: 'private: creation'!

create: linkEnds {LinkEndsModel} with: descList {ListModel}
	super create.
	myEndModel _ linkEnds.
	myDescriptionListModel _ descList.
	myEndModel addDependent: self.
	myDescriptionListModel addDependent: self!

{void} destruct

	myEndModel removeDependent: self.
	myDescriptionListModel removeDependent: self.
	myEndModel _ NULL.
	myDescriptionListModel _ NULL.
	super destruct! !

!EndList2DescriptionListSchnert methodsFor: 'private: actions'!

{void} insertEndUpdate: index {IntegerVar} 
	myDescriptionListModel removeDependent: self.
	myDescriptionListModel insert: index with: (myEndModel fetchDescription: index).
	myDescriptionListModel addDependent: self!

{void} removeDescriptionUpdate: region {XnRegion}
	"disconnect the dependency during the op so we don't get an infinite cycle."
	
	myEndModel removeDependent: self.
	myEndModel wipe: region.
	myEndModel addDependent: self!

{void} removeEndUpdate: region {XnRegion} 
	"disconnect dependency while updating the other so we don't get 
	infinite cycle"

	myDescriptionListModel removeDependent: self.
	myDescriptionListModel wipe: region.
	myDescriptionListModel addDependent: self! !

!EndList2DescriptionListSchnert methodsFor: 'updating'!

{void} update: ur {UpdateRecord} from: sender {XnModel}
	sender == myEndModel
		ifTrue: [(ur isKindOf: InsertionUR)
			ifTrue: [self insertEndUpdate: (ur basicCast: InsertionUR) index]
		ifFalse: [(ur isKindOf: DeletionUR)
			ifTrue: [self removeEndUpdate: (ur basicCast: DeletionUR) region]
		ifFalse: [Heaper BLAST: #INVALID.U.UPDATE.U.RECORD]]]
	ifFalse: [(sender == myDescriptionListModel)
		ifTrue: [(ur isKindOf: DeletionUR)
			ifTrue: [self removeDescriptionUpdate: (ur basicCast: DeletionUR) region]
			ifFalse: [Heaper BLAST: #INVALID.U.UPDATE.U.RECORD]]
	ifFalse: [Heaper BLAST: #WhyDidIGetThis.U.Interogative]]! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

EndList2DescriptionListSchnert class
	instanceVariableNames: ''!

(EndList2DescriptionListSchnert getOrMakeCxxClassDescription)
	friends:
'/* friends for class EndList2DescriptionListSchnert */
friend SPTR(EndList2DescriptionListSchnert) endList2DescriptionListSchnert (
													LinkEndsModel * onEndList, 
													ListModel * descriptions);';
	attributes: ((Set new) add: #CONCRETE; yourself)!

!EndList2DescriptionListSchnert class methodsFor: 'pseudo constructors'!

make: onEndList {LinkEndsModel} with: descriptions {ListModel}

	^ self create: onEndList with: descriptions! !