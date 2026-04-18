'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:56:39 pm'!

FMDirector subclass: #FMListDirector
	instanceVariableNames: '
		myModelList {ListModel of: Heaper}
		myViewList {ListModel of: Viewer}
		myController {MultiController}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'FM-Builders'!

(FMListDirector getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!FMListDirector methodsFor: 'private: private updating'!

{void} updateDeletion: deleteRec {DeletionUR}

	myViewList wipe: deleteRec region.
	"myController remove: deleteRec region"!

{void} updateInsertion: insertRec {InsertionUR}
	| newBuilding {FMBuilding} |
	Scaffold fluidBind: self scaffold during: 
		[newBuilding _ Scaffold fluidGet build: (myModelList fetch: insertRec index)].
	myViewList insert: (insertRec index) with: newBuilding view.
	newBuilding controller ~~ NULL ifTrue: 
		[myController add: newBuilding controller with: insertRec position]! !

!FMListDirector methodsFor: 'protected: creation'!

{void} destruct
	myModelList ~~ NULL ifTrue: [myModelList removeDependent: self].
	myModelList _ NULL.
	myViewList _ NULL.
	myController _ NULL.
	super destruct.! !

!FMListDirector methodsFor: 'creation'!

create: list {ListModel} with: views {ListModel of: Viewer}
	super create.
	myModelList _ list.
	myViewList _ views.
	myController _ NULL.
	myModelList addDependent: self!

create: list {ListModel} with: views {ListModel of: Viewer} with: controls {MultiController}
	super create.
	myModelList _ list.
	myViewList _ views.
	myController _ controls.
	myModelList addDependent: self! !

!FMListDirector methodsFor: 'private: updating'!

{void} update: updateRecord {UpdateRecord} from: other {XnModel unused} 
	"This is the method which dispatches the different update 
	messages"
	"Should this deal with RearrangeUpdate?? -ech; yes heh 18 March 1991"

	(updateRecord isKindOf: InsertionUR)
		ifTrue: [self updateInsertion: (updateRecord basicCast: InsertionUR)]
	ifFalse: [(updateRecord isKindOf: DeletionUR)
		ifTrue: [self updateDeletion: (updateRecord basicCast: DeletionUR)]
	ifFalse: [(updateRecord isKindOf: SimpleUpdateRecord)
		ifTrue: [self updateAll]
	ifFalse: [self updateAll "catchall"]]].
	^VOID!

{void} updateAll
 
	| stomp {TableStepper} mcTable {IntegerTable} |
	Scaffold fluidBind: self scaffold during: [
		myViewList wipe: myViewList domain.
		mcTable _ myController controllers cast: IntegerTable.
		mcTable wipeAll: myController controllers domain.
		stomp _ myModelList asTable stepper.
		stomp forEach: [:elem {Heaper} | | newBuilding
{FMBuilding} |
			newBuilding _ Scaffold fluidGet build: elem.
			myViewList insert: stomp index with: newBuilding view.
			newBuilding controller ~~ NULL ifTrue: 
				[mcTable at: stomp position introduce: newBuilding
controller]]]! !

!FMListDirector methodsFor: 'printing'!

{void}printOn: aStream{ostream reference}
	aStream << self getCategory name << '('
	
	<< ' not really implemented ' << ') '! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

FMListDirector class
	instanceVariableNames: ''!

(FMListDirector getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!FMListDirector class methodsFor: 'pseudo constructor'!

make: list {ListModel} with: views {ListModel of: Viewer}
	^self create: list with: views!

make: list {ListModel} with: views {ListModel of: Viewer}
with: controls {MultiController}

	^ FMListDirector create: list with: views with: controls! !