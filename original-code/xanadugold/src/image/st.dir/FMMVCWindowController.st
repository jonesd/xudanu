'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:56:52 pm'!

StandardSystemController subclass: #FMMVCWindowController
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'FM-Events'!



!FMMVCWindowController methodsFor: 'control'!

controlInitialize

	super controlInitialize.
	view dispatcher warpDrive refresh: view insetDisplayBox.!

idle

	view dispatcher dispatchCycle! !

!FMMVCWindowController methodsFor: 'menu messages'!

close
	status _ #closed.
	view erase.
	model release!

{void} redButtonActivity
	((view labelDisplayBox containsPoint: sensor cursorPoint)
		or: [(model respondsTo: #yellowButtonMenu) not])
		ifTrue: [super redButtonActivity]
		ifFalse: [self yellowButtonActivity]!

{void} yellowButtonActivity
	(model respondsTo: #yellowButtonMenu)
		ifTrue: 
			[| menu {PopUpMenu} sel {Symbol} |
			menu _ model yellowButtonMenu.
			sel _ menu startUp.
			sel == nil | (sel = 0) ifFalse: 
				[view topView dispatcher submitMenuEvent: (Sequence string:
sel)]]
		ifFalse: [super yellowButtonActivity]! !