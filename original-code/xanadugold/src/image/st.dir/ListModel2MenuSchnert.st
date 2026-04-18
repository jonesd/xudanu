'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:59:02 pm'!

XnModel subclass: #ListModel2MenuSchnert
	instanceVariableNames: '
		myTable {ListModel of: PackOBits}
		myMenu {VariableModel of: PopUpMenu}
		myTransform {BlockContext}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Tapestry-Smalltalk version'!

(ListModel2MenuSchnert getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!ListModel2MenuSchnert methodsFor: 'private: private updating'!

{void} updateMenu
	| labels {String} between {String} |

	between _ ''.
	labels _ ''.
	myTable asTable stepper forEach: [ :each {Heaper} |
		labels _ labels , between , (myTransform value: each).
		between _ '
'].
	myMenu setValue: (PopUpMenu labels: labels)! !

!ListModel2MenuSchnert methodsFor: 'updating'!

{void} update: change {UpdateRecord} from: model {XnModel} 
	model == (myTable basicCast: XnModel) ifTrue: [self updateMenu]! !

!ListModel2MenuSchnert methodsFor: 'create'!

create: table {ListModel of: PackOBits} with: menu {VariableModel of: PopUpMenu} with: transform {BlockContext}
	super create.
	myTable _ table.
	myMenu _ menu.
	myTransform _ transform.
	table addDependent: self.
	self updateMenu! !

!ListModel2MenuSchnert methodsFor: 'protected: creation'!

{void} destruct
	myTable removeDependent: self.
	super destruct! !