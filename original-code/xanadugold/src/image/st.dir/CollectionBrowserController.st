'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:49:56 pm'!

StandardSystemController subclass: #CollectionBrowserController
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Interface-Structures'!
CollectionBrowserController comment:
'An CollectionBrowserController represents a kind of StandardSystemsController that requires confirmation from the user before the view on the display screen can be closed.'!


!CollectionBrowserController methodsFor: 'menu messages'!

close
	"Remove the receiver's view from the screen and from the collection 
	of scheduled views. First see if the model is in a state to close. If 
	not, that is, if the model has changed and its dependents are in the 
	process of reacting to the change or if the model has previously 
	initiated a close, do nothing."

	model changeRequest ifFalse: [^self].
	model closeRequest ifFalse: [^self].
	status := #closed.
	view erase!

newLabel
	"Prompt the user for a new label. Notify the model as to the new 
	label. If the user types nothing, then do nothing."

	| newLabel |
	newLabel := FillInTheBlank request: 'Type the new label' initialAnswer: view label.
	newLabel = ''
		ifFalse: 
			[view deEmphasize.
			view newLabel: newLabel.
			view emphasize.
			model newLabel: newLabel]! !