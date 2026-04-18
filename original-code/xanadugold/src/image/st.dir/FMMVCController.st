'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:56:50 pm'!

MouseMenuController subclass: #FMMVCController
	instanceVariableNames: '
		controller {UNKNOWN}
		events {UNKNOWN}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'FM-Events'!
FMMVCController comment:
'FMVCController is a Smalltalk controller that handles the conversion of the Smalltalk MVC user interface
handling into something that FM prefers.  It is responsible for setting up and calling the routines that create and
dispatch FMEvents and it also controls the FM viewer display process.'!



!FMMVCController methodsFor: 'accessing'!

{void} fmController: fmc {FMController} 
	fmc == nil
		ifTrue: [controller _ FMController make]
		ifFalse: [controller _ fmc]! !

!FMMVCController methodsFor: 'basic control'!

controlActivity
	| box {RectangleFlugleSpeizer} |
	box _ view insetDisplayBox.
	self view drive refresh: box.
	"MessageTally mySpy: ["
	[box containsPoint: Sensor mousePoint]
		whileTrue: [events runNextFor: controller on: view warp.
			view displayView]
	"]"!

debugDisplay
	view halt.
	view recompose.
	view displayView!

{void}inspectController
	controller inspect!

{void}inspectView
	model inspect!

{BooleanVar} isControlActive
	^super isControlActive & sensor blueButtonPressed not!

{void}yellowButtonActivity
	"Menu for FM Stuff (to be documented with FM)"
	
	| menu {PopUpMenu} sel {Symbol} |
	
	menu _ PopUpMenu fromArray: #(
		('inspect view'		inspectView		'')
		('inspect controller'	inspectController	'')
		('debug display'		debugDisplay		'') ).
		
	sel _ menu startUp.
	sel == nil | (sel = 0) ifFalse: [self perform: sel].! !

!FMMVCController methodsFor: 'create/delete'!

{void}initialize
	super initialize.
	events _ EventQueue create!

{void} release
	controller destruct.
	events destruct.
	events _ NULL.
	super release! !