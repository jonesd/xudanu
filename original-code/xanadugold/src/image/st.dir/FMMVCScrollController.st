'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:56:51 pm'!

ScrollController subclass: #FMMVCScrollController
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'FM-Events'!
FMMVCScrollController comment:
'FMVCScrollController is a Smalltalk controller that is used with a FMVCScrolledView to provide a "harness" 
in which to display a FM view.'!



!FMMVCScrollController methodsFor: 'basic control'!

controlLoop

	"self isControlActive
		ifTrue: [MessageTally mySpy: [super controlLoop]]"
	super controlLoop!

idle
	view topView dispatcher dispatchCycle!

{BooleanVar} isControlActive
	^ self scrollBarContainsCursor | super isControlActive!

{void} yellowButtonActivity
	| menu {PopUpMenu} sel {Symbol} modelMenu {BooleanVar} |
	(view topView model respondsTo: #yellowButtonMenu)
		ifTrue: [menu _ view topView model yellowButtonMenu.
			modelMenu _ true]
		ifFalse: [menu _ PopUpMenu fromArray: #(
		('inspect view'		inspectView		'')
		('inspect controller'	inspectController	'')
		('debug display'		debugDisplay		'') ).
			modelMenu _ false].
	sel _ menu startUp.
	sel == nil | (sel = 0) ifFalse: [modelMenu
		ifTrue: [ view topView dispatcher submitMenuEvent: (Tumbler string: sel) ]
		ifFalse: [self perform: sel]]! !

!FMMVCScrollController methodsFor: 'scrolling'!

computeMarkerRegion
	"Answer the rectangular area in which the gray area of the scroll bar
	should be displayed."
	| total used grey pos |
	used _ model enclosure height.
	total _ view scrolledHeight.
	grey _ (used asFloat / (total max: 1) * scrollBar inside height) rounded
		min: scrollBar inside height.
	"pos _ ((view offset negated asFloat /  (total - used)) * (scrollBar inside height - grey)) rounded."
	"^0@pos extent: 10 @ grey"
	^ 0@0 extent: 10 @ grey!

markerDelta
	^marker top 
		- self scrollBarOnlyArea top  
		+ (view offset asFloat 
			/ (model enclosure height max: 1) asFloat *
				self scrollBarOnlyArea height asFloat) rounded!

scrollAmount
	"Answer the number of bits of y-coordinate should be scrolled.  This is a 
	default determination based on the view's preset display transformation."

	^sensor cursorPoint y - self scrollBarOnlyArea top!

scrollView: anInteger 
	"If anInteger is not zero, tell the reciever's view to scroll by anInteger amount."

	anInteger ~= 0
		ifTrue: 
			[view offset: view offset + anInteger.
			view displayView]!

viewDelta
	"Answer an integer that indicates how much the view should be scrolled.
	The scroll bar has been moved and now the view must be so the amount to
	scroll is computed as a ratio of the current scroll bar position."

	^model enclosure top -
		((marker top - self scrollBarOnlyArea top) asFloat /
			self scrollBarOnlyArea height asFloat *
				model enclosure height asFloat) rounded! !

!FMMVCScrollController methodsFor: 'menu messages'!

debugDisplay
	view topView dispatcher setDebug: (view topView
dispatcher debug not)!

{void} inspectController
	self inspect!

{void} inspectView
	model inspect! !