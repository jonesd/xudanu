'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:59:09 pm'!

XnModel subclass: #VariableTable2MenuSchnert
	instanceVariableNames: '
		myTable {VariableModel of: ScruTable}
		myMenu {VariableModel of: PopUpMenu}
		myTransform {BlockContext}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Tapestry-Smalltalk version'!

(VariableTable2MenuSchnert getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!VariableTable2MenuSchnert methodsFor: 'private: private updating'!

{void} updateMenu
	| labels {String} between {String} |
	between _ ''.
	labels _ ''.
	(myTable asTable) stepper forEach: [ :each {PackOBits} |
		labels _ labels , between , (each convert: MuWordArray) gutsOf.
		between _ '
'].
	myMenu setValue: (PopUpMenu labels: labels)! !

!VariableTable2MenuSchnert methodsFor: 'updating'!

{void} update: change {UpdateRecord unused} from: model
{XnModel} 
	model == (myTable basicCast: XnModel) ifTrue: [self
updateMenu]! !

!VariableTable2MenuSchnert methodsFor: 'create'!

create: table {ListModel of: PackOBits} with: menu {VariableModel of: PopUpMenu} with: transform {BlockContext}
	super create.
	myTable _ table.
	table addDependent: self.
	myMenu _ menu.
	myTransform _ transform.
	self updateMenu! !