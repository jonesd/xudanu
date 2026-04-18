'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:50:01 pm'!

ListSelectionController subclass: #BetterOutlineController
	instanceVariableNames: 'lastTime '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Framework-List'!


!BetterOutlineController methodsFor: 'control'!

redButtonActivity
	"Determine which item in the list is selected. Send a message to the 
	model indicating the number of the selected item."

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
					nextSelection ~= oldSelection ifTrue: [selectionMovement _ true]]].
	nextSelection isNil ifTrue: 
		[nextSelection _ oldSelection].
	nextSelection = oldSelection
		ifTrue: [(model isLeaf: model currentSelection)
			ifFalse: [(model isOpen: (model currentSelection)) 
						ifTrue: [view browser closeCurrent]
						ifFalse: [view browser openCurrent].
				 self updateMarker.
				selectionMovement ifFalse: [^ self]].
			nextSelection _ 0.
			view moveSelectionBox: nextSelection]
		ifFalse: [view moveSelectionBox: nextSelection].
	view channelChangeRequest
		ifFalse: 
			[view moveSelectionBox: oldSelection.
			^view flash].
	self changeModelSelection: nextSelection! !

!BetterOutlineController methodsFor: 'marker'!

updateMarker
	"A variation of moveMarker--only redisplay the marker in the scrollbar
	if an actual change has occurred in the positioning of the paragraph."

	| newMarkerRegion |
	newMarkerRegion _ self computeMarkerRegion.
	newMarkerRegion extent ~= marker region extent
		ifTrue: 
			[self markerRegion: newMarkerRegion.
			self moveMarker]! !