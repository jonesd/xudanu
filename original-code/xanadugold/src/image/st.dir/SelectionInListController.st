'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:49:41 pm'!

ListController subclass: #SelectionInListController
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Interface-Lists'!
SelectionInListController comment:
'Class SelectionListController is designed to support the pluggable SelectionInListViews.  As its operation is parameterized in the view, it must ask its view for current selection and for menu options.'!


!SelectionInListController methodsFor: 'menu messages'!

redButtonActivity
	| selectionMovement oldSelection trialSelection nextSelection |
	selectionMovement _ false.
	oldSelection _ view selection.
	[sensor redButtonPressed]
		whileTrue: 
			[trialSelection _ view findSelection: sensor cursorPoint.
			trialSelection ~~ nil
				ifTrue: 
					[nextSelection _ trialSelection.
					view moveSelectionBox: nextSelection.
					nextSelection ~= oldSelection ifTrue: 
						[selectionMovement _ true.
						Sensor leftShiftDown ifTrue: 
							[view changeModelSelection: nextSelection.
							oldSelection _ nextSelection]]]].
	nextSelection == nil ifTrue: [^self].
	nextSelection = oldSelection ifTrue:
		[selectionMovement ifTrue: [^self].
		nextSelection _ 0.
		view moveSelectionBox: nextSelection].
	model changeRequest ifFalse:
			[view moveSelectionBox: oldSelection.
			^ view flash].
	view changeModelSelection: nextSelection!

yellowButtonActivity
	| index menu |
	menu _ view yellowButtonMenu.
	menu == nil
		ifTrue:
			[view flash.
			super controlActivity]
		ifFalse: 
			[index _ menu startUpYellowButton.
			index ~= 0 
				ifTrue:
					[self controlTerminate.
					model perform: (menu selectorAt: index).
					self controlInitialize]]! !

!SelectionInListController methodsFor: 'control defaults'!

isControlWanted
	view isEmpty ifTrue: [^ false].
	^super isControlWanted! !