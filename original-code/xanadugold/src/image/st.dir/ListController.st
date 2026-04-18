'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:49:39 pm'!

ScrollController subclass: #ListController
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Interface-Lists'!
ListController comment:
'A ListController is kind of ScrollController that assumes that the view is a kind of ListView.  Therefore, scrolling means moving the items in a textual list (menu) up or down. In addition, I provide the red button activity of determining when the red button is selecting an item in the list.'!


!ListController methodsFor: 'control defaults'!

isControlActive
	^super isControlActive & sensor blueButtonPressed not! !

!ListController methodsFor: 'marker adjustment'!

computeMarkerRegion
	| viewList |
	viewList _ view list.
	^ 0@0 extent: 10 @
			((viewList clippingRectangle height asFloat /
						viewList compositionRectangle height *
							scrollBar inside height)
					rounded min: scrollBar inside height)!

markerDelta
	| viewList |
	viewList _ view list.
	^(marker top - self scrollBarOnlyArea top) -
		((viewList clippingRectangle top -
				viewList compositionRectangle top) asFloat /
			viewList compositionRectangle height asFloat *
			self scrollBarOnlyArea height asFloat) rounded! !

!ListController methodsFor: 'scrolling'!

canScroll
	| viewList |
	viewList _ view list.
	^viewList compositionRectangle height - viewList clippingRectangle height 
		> (viewList lineGrid // 2)!

scrollAmount
	^sensor cursorPoint y - self scrollBarOnlyArea top!

scrollView: anInteger
	| viewList maximumAmount minimumAmount amount |
	viewList _ view list.
	maximumAmount _
		viewList clippingRectangle top -
		viewList compositionRectangle top max: 0.
	minimumAmount _
		viewList clippingRectangle bottom -
		viewList compositionRectangle bottom min: 0.
	amount _
		(anInteger min: maximumAmount) max:
		minimumAmount.
	amount ~= 0
		ifTrue:
			[view deselect.
			viewList scrollBy: amount negated.
			view isSelectionBoxClipped
				"ifTrue: [ self changeModelSelection: 0]  compile this code to deselect
					when the selection is scrolled outside of the visible region"
				ifFalse: [ view displaySelectionBox ]]!

scrollViewDown
	self scrollView: self scrollAmount.!

scrollViewUp
	self scrollView: (self scrollAmount) negated.!

viewDelta
	| viewList |
	viewList _ view list.
	^(viewList clippingRectangle top -
			viewList compositionRectangle top -
			((marker top - self scrollBarOnlyArea top) asFloat /
				self scrollBarOnlyArea height asFloat *
				viewList compositionRectangle height asFloat))
		roundTo: viewList lineGrid! !

!ListController methodsFor: 'menu messages'!

redButtonActivity
	| noSelectionMovement oldSelection trialSelection nextSelection |
	noSelectionMovement _ true.
	oldSelection _ view selection.
	[sensor redButtonPressed]
		whileTrue: 
			[trialSelection _ view findSelection: sensor cursorPoint.
			trialSelection ~~ nil
				ifTrue: 
					[nextSelection _ trialSelection.
					view moveSelectionBox: nextSelection.
					nextSelection ~= oldSelection ifTrue: [noSelectionMovement _ false]]].
	nextSelection ~~ nil & (nextSelection = oldSelection
			ifTrue: [noSelectionMovement]
			ifFalse: [true]) ifTrue: [self changeModelSelection: nextSelection]! !

!ListController methodsFor: 'private: private'!

changeModelSelection: anInteger 
	model toggleListIndex: anInteger! !