'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:59:12 pm'!

View subclass: #ScreenPlayView
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Tools-ScreenPlay'!


!ScreenPlayView methodsFor: 'instance creation'!

create: screenPlay {ScreenPlay} 
	| headerView {TextView} bodyView {TextView} pendingEventView {TextView} |
	self model: screenPlay.
	headerView _ TextView
				on: screenPlay header
				aspect: #contents
				change: #contents:
				menu: #textMenu.
	self
		addSubView: headerView
		in: (0.0 @ 0.0 corner: 0.33 @ 0.2)
		borderWidth: 1.
	EnvironmentInspector
		inspectorFor: (EnvironmentInspector new environment: screenPlay environment)
		in: self
		box: (0.33 @ 0.0 corner: 1.0 @ 0.2).
	bodyView _ TextView
				on: screenPlay body
				aspect: #contents
				change: #contents:
				menu: #textMenu.
	self
		addSubView: bodyView
		in: (0.0 @ 0.2 corner: 1.0 @ 0.8)
		borderWidth: 1.
	pendingEventView _ CodeView
				on: screenPlay
				aspect: #eventText
				change: #acceptEvent:from:
				menu: #eventMenu
				initialSelection: '**'.
	self
		addSubView: pendingEventView
		in: (0.0 @ 0.8 corner: 1.0 @ 1.0)
		borderWidth: 1! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

ScreenPlayView class
	instanceVariableNames: ''!


!ScreenPlayView class methodsFor: 'smalltalk: smalltalk instance creation'!

{void} openOn: aScreenPlay {ScreenPlay} 
	| newView {ScreenPlayView} topView {StandardSystemView} |
	newView _ ScreenPlayView make: aScreenPlay.
	topView _ StandardSystemView new.
	topView controller: (SpecialTopController make: aScreenPlay).
	topView label: 'a ScreenPlay'.
	topView minimumSize: 160 @ 120.
	topView borderWidth: 1.
	topView addSubView: newView.
	topView controller open! !

!ScreenPlayView class methodsFor: 'instance creation'!

{ScreenPlayView} make: aScreenPlay {ScreenPlay}
	^ ScreenPlayView create: aScreenPlay! !