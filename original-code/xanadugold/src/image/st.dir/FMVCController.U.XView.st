'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:56:56 pm'!

Heaper subclass: #FMVCController.U.XView
	instanceVariableNames: '
		controller {Controller.X}
		events {EventQueue.U.XView}'
	classVariableNames: '
		Menu {UNKNOWN} 
		MenuString {UNKNOWN} '
	poolDictionaries: ''
	category: 'FM-Events-SunView'!

(FMVCController.U.XView getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!FMVCController.U.XView methodsFor: 'create/delete'!

create
	super create.
	events _ EventQueue.U.XView create!

{void}initialize
	super initialize!

{void}release
	controller destroy.
	super release! !

!FMVCController.U.XView methodsFor: 'accessing'!

{void} fmController: fmc {FMVCController.U.XView} 
	fmc == NULL
		ifTrue: [controller _ FMController make]
		ifFalse: [controller _ fmc]! !