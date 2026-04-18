'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:59:12 pm'!

StandardSystemController subclass: #SpecialTopController
	instanceVariableNames: 'mySpy {Object}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Tools-ScreenPlay'!



!SpecialTopController methodsFor: 'menu messages'!

close
	mySpy prepareToClose.
	super close!

{void} newLabel
	"Prompt the user for a new label. Notify the model as to the new 
	label. If the user types nothing, then do nothing."

	| newLabel |
	newLabel := FillInTheBlank request: 'Type the new label' initialAnswer: view label.
	newLabel = ''
		ifFalse: 
			[newLabel _ mySpy getNewLabel: newLabel.
			view deEmphasize.
			view newLabel: newLabel.
			view emphasize].! !

!SpecialTopController methodsFor: 'instance creation'!

create: ntptc {Object}
	mySpy _ ntptc! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

SpecialTopController class
	instanceVariableNames: ''!



!SpecialTopController class methodsFor: 'instance creation'!

{SpecialTopController} make: ntptc {Object}
	^ SpecialTopController create: ntptc! !