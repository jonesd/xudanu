'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:02:58 pm'!

XnDependent subclass: #List2SelectionSchnert
	instanceVariableNames: '
		myList {ListModel}
		mySelection {SelectionObject}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-winmod'!
List2SelectionSchnert comment:
'This schnert is used to keep a selection in synch with a list.  If items are added, removed or rearranged in the listmodel, the selection is updated to reflect those changes.'!

(List2SelectionSchnert getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!List2SelectionSchnert methodsFor: 'create'!

create: list {ListModel} with: selection {SelectionObject}
	super create.
	myList _ list.
	mySelection _ selection.
	myList addDependent: self!

{void} destruct

	myList removeDependent: self.
	myList _ NULL.
	super destruct! !

!List2SelectionSchnert methodsFor: 'updating'!

{void} update: change {UpdateRecord} from: model {XnModel} 
	myList == model
		ifTrue: [(change isKindOf: InsertionUR)
			ifTrue: [self updateInsertion: 
				((change quickCast: InsertionUR) position cast: IntegerPos) asIntegerVar]
	ifFalse: [(change isKindOf: DeletionUR)
		ifTrue: [self updateDeletion: (change quickCast: DeletionUR) region]
	ifFalse: [(change isKindOf: NewContentsUpdate)
		ifTrue: [self updateNewContents]
	ifFalse: [(change isKindOf: RearrangeUpdate)
		ifTrue:[self updateRearrange: (change basicCast: RearrangeUpdate)]]]]]! !

!List2SelectionSchnert methodsFor: 'private: updating'!

{void} updateDeletion: keys {XnRegion}
	mySelection select: (((keys complement cast: IntegerRegion) compactor
			ofAll: mySelection selection)
		intersect: ((keys complement cast: IntegerRegion) compacted))!

{void} updateInsertion: key {IntegerVar}
	mySelection select: (((IntegerMapping make: 1) restrict: (IntegerRegion after: key))
		ofAll: mySelection selection)!

{void} updateNewContents
	mySelection select: IntegerRegion make!

{void} updateRearrange: ur {RearrangeUpdate}

	| cut1 {IntegerVar} cut2 {IntegerVar} cut3 {IntegerVar} map {Mapping} |
	
	cut1 _ ur cut1.
	cut2 _ ur cut2.
	cut3 _ ur cut3.
	
	map _ ((((IntegerMapping make
			restrict: (IntegerRegion make: IntegerVar0 with: cut1))
		combine: ((IntegerMapping make: cut3 - cut2)
			restrict: (IntegerRegion make: cut1 with: cut2)))
		combine: ((IntegerMapping make: cut1 - cut2)
			restrict: (IntegerRegion make: cut2 with: cut3)))
		combine: (IntegerMapping make
			restrict: (IntegerRegion after: cut3))).
	mySelection select: (map ofAll: mySelection selection)! !

!List2SelectionSchnert methodsFor: 'printing'!

{void}printOn: aStream {ostream reference}
	aStream << self getCategory name << '('
	
	<< 'myList = '  << myList  
	<< 	'mySelection = ' << 	mySelection << ')'! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

List2SelectionSchnert class
	instanceVariableNames: ''!

(List2SelectionSchnert getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!List2SelectionSchnert class methodsFor: 'pseudo constructors'!

make: list {ListModel} with: selection {SelectionObject}
	^self create: list with: selection! !