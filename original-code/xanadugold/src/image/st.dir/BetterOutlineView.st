'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:50:02 pm'!

ListSelectionView subclass: #BetterOutlineView
	instanceVariableNames: 'browserInternal '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Framework-List'!


!BetterOutlineView methodsFor: 'accessing'!

browser
	^ browserInternal! !

!BetterOutlineView methodsFor: 'controller access'!

defaultControllerClass
	"Answer the default controller class for the receiver."

	^BetterOutlineController! !

!BetterOutlineView methodsFor: 'setting'!

browser: newBrowser 
	browserInternal _ newBrowser! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

BetterOutlineView class
	instanceVariableNames: ''!


!BetterOutlineView class methodsFor: 'instance creation'!

on: aModel menuChannel: menuChannel changeRequestChannel: changeRequestChannel 
	"Create an instance of the receiver for the object aModel. Get the 
	translation for the menu messages from menuChannel. Broadcasting 
	changes comes via changeRequestChannel. aModel has to 
	understand the message list."

	self error: 'should use on:menuChannel:changeRequestChannel:with:'!

on: aModel menuChannel: menuChannel changeRequestChannel: changeRequestChannel with: treeBrowser
	"Create an instance of the receiver for the object aModel. Get the 
	translation for the menu messages from menuChannel. Broadcasting 
	changes comes via changeRequestChannel. aModel has to 
	understand the message list."

	| lv |
	lv := self new model: aModel.
	lv menuChannel: menuChannel.
	lv changeRequestChannel: changeRequestChannel.
	lv browser: treeBrowser.
	^lv! !