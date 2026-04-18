'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:59:09 pm'!

Object subclass: #STTestWindow
	instanceVariableNames: '
		myTop {UNKNOWN}
		myController {UNKNOWN}
		myBuilding {UNKNOWN}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Testing-Front End Tools'!



!STTestWindow methodsFor: 'windowing'!

open

	myTop  _ FMMVCWindow make: self with: 'Test Viewer' with: 100@200.
	myTop addSubView: (FMVCScrolledView make: myBuilding)
		in: (0@0 corner: 1@1)
		borderWidth: 1.

	myController _ myTop controller.
	myController initialize; open! !

!STTestWindow methodsFor: 'creation'!

create: onBuilding {FMBuilding}

	myBuilding _ onBuilding! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

STTestWindow class
	instanceVariableNames: ''!



!STTestWindow class methodsFor: 'pseudoconstructors'!

make: onBuilding {FMBuilding}

	^ self create: onBuilding! !