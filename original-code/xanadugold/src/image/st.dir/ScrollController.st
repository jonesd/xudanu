'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:49:37 pm'!

MouseMenuController subclass: #ScrollController
	instanceVariableNames: 'scrollBar marker '
	classVariableNames: 'HaltedScrollBar SavedArea YellowMenuForm '
	poolDictionaries: ''
	category: 'Interface-Support'!
ScrollController comment:
'Class ScrollController represents control for scrolling using a scrollBar.  It is a MouseMenuController that creates a scrollBar, rather than menus.  Its subclasses add the button menus.  Instances of ScrollController keep control as long as the cursor is inside the view or the scrollBar area.

A scrollBar is a rectangular area representing the length of the information being viewed.  It contains an inner rectangle whose top y-coordinate represents the relative position of the information visible on the screen with respect to all of the information, and whose size represents the relative amount of that information visible on the screen.  The user controls which part of the information is visible by pressing the red button.  If the cursor is to the right of the inner rectangle, the window onto the visible information moves upward, if the cursor is to the left, the window moves downward, and if the cursor is inside, the inner rectangle is grabbed and moved to a desired position.  

Instance Variables:
	scrollBar	<Quadrangle> inside white, the outer rectangle
	marker		<Quadrangle> inside gray, the inner rectangle

Class Variables:

	HaltedScrollBar	
<Form> the area the scrollBar overlaps that needs restoration should the view be interrupted

	SavedArea	
<Form> the area the scrollBar overlaps, restored whenever the scrollBar is hidden during normal operation
	'!


!ScrollController methodsFor: 'initialize-release'!

initialize
	super initialize.
	scrollBar _ Quadrangle new.
	scrollBar borderWidthLeft: 2 right: 0 top: 2 bottom: 2.
	marker _ Quadrangle new.
	marker borderWidthLeft: 0 right: 0 top: 1 bottom: 1.
	marker insideColor: Form gray! !

!ScrollController methodsFor: 'basic control sequence'!

controlInitialize
	"The scrollbar has a two-pixel border, and for alignment it assumes that this sub-view
	has a one-pixel border and shares another one-pixel border from its neighbor/super view"
	super controlInitialize.
	scrollBar region: (0 @ 0 extent: 12 @ (view displayBox height + 2)).
	marker region: self computeMarkerRegion.
	scrollBar _ scrollBar align: scrollBar topRight with: view displayBox topLeft - (0@1).
	marker _ marker align: marker topCenter with: scrollBar inside topCenter.
	self class getSavedAreaFor: scrollBar.
	scrollBar displayOn: Display.
	self moveMarker!

controlLoop
	"Sent by Controller|startUp as part of the standard control sequence. 
	Controller|controlLoop sends the message Controller|isControlActive to test 
	for loop termination. As long as true is returned, the loop continues. When 
	false is returned, the loop ends. Each time through the loop, the message 
	Controller|controlActivity is sent."

	[self isControlActive]
		whileTrue: 
			[BackgroundDelay == nil
				ifTrue: [Processor yield]
				ifFalse: [BackgroundDelay wait].
			self controlActivity. self idle]!

controlTerminate
	super controlTerminate.
	self class restoreSavedArea! !

!ScrollController methodsFor: 'control defaults'!

controlActivity
	self computeMarkerRegion.
	self scrollBarContainsCursor
		ifTrue: [self scroll]
		ifFalse: [super controlActivity]!

isControlActive
	^self viewHasCursor | self scrollBarContainsCursor!

isControlWanted
	^self viewHasCursor!

yellowMenuActivity
	sensor anyButtonPressed ifTrue: [self yellowButtonActivity]! !

!ScrollController methodsFor: 'scrolling'!

canScroll
	"Answer whether there is information that is not visible and can be seen
	by scrolling."
	^marker region height < self scrollBarOnlyArea height!

scroll
	"Check to see whether the user wishes to jump, scroll up, or scroll down."

	Cursor scroll showWhile: [[self scrollBarContainsCursor]
			whileTrue: 
				[Processor yield.
				Sensor redButtonPressed
					ifTrue: [self scrollUp]
					ifFalse: [Sensor blueButtonPressed
							ifTrue: [self scrollDown]
							ifFalse: [Sensor yellowButtonPressed ifTrue: [self scrollAbsolute]]]]]!

scrollAmount
	"Answer the number of bits of y-coordinate should be scrolled.  This is a 
	default determination based on the view's preset display transformation."

	^((view inverseDisplayTransform: sensor cursorPoint)
		- (view inverseDisplayTransform: self scrollBarOnlyArea topCenter)) y!

scrollView
	"The scroll bar jump method was used so that the view should be updated to
	correspond to the location of the scroll bar gray area."
	self scrollView: self viewDelta!

scrollView: anInteger 
	"If anInteger is not zero, tell the reciever's view to scroll by anInteger amount."

	anInteger ~= 0
		ifTrue: 
			[view scrollBy: 0 @ 
				((anInteger min: view window top - view boundingBox top)
						max: view window top - view boundingBox bottom).
			view clearInside.
			view display]!

scrollViewDown
	"Scroll the receiver's view down the default amount."
	self scrollView: self scrollAmount!

scrollViewUp
	"Scroll the receiver's view up the default amount."
	self scrollView: self scrollAmount negated!

viewDelta
	"Answer an integer that indicates how much the view should be scrolled.
	The scroll bar has been moved and now the view must be so the amount to
	scroll is computed as a ratio of the current scroll bar position."

	^view window top - view boundingBox top -
		((marker top - self scrollBarOnlyArea top) asFloat /
			self scrollBarOnlyArea height asFloat *
				view boundingBox height asFloat) rounded! !

!ScrollController methodsFor: 'cursor'!

changeCursor: aCursor 
	"The current cursor should be set to be aCursor."
	sensor currentCursor ~~ aCursor ifTrue: [aCursor show]!

markerContainsCursor
	"Answer whether the gray area inside the scroll bar area contains the cursor."
	^marker inside containsPoint: sensor cursorPoint!

scrollBarContainsCursor
	"Answer whether the cursor is anywhere within the scroll bar area."
	^scrollBar containsPoint: sensor cursorPoint!

scrollBarOnlyContainsCursor
	"Answer whether the cursor is anywhere within the scroll bar area."
	^self scrollBarOnlyArea containsPoint: sensor cursorPoint!

yellowMenuContainsCursor
	"Answer whether the cursor is anywhere within the yellow menu area."
	^self yellowMenuArea containsPoint: sensor cursorPoint! !

!ScrollController methodsFor: 'marker adjustment'!

computeMarkerRegion
	"Answer the rectangular area in which the gray area of the scroll bar
	should be displayed."

	^0@0 extent: 10 @
			((view window height asFloat /
						view boundingBox height *
							scrollBar inside height)
				 rounded min: scrollBar inside height)!

markerDelta
	^marker top 
		- self scrollBarOnlyArea top  
		- ((view window top - view boundingBox top) asFloat 
			/ view boundingBox height asFloat *
				self scrollBarOnlyArea height asFloat) rounded!

markerRegion: aRectangle 
	"Set the area defined by aRectangle as the marker.  Fill it with gray tone."

	Display fill: marker mask: scrollBar insideColor.
	marker region: aRectangle.
	marker _ marker align: marker topCenter with: scrollBar inside topCenter!

moveMarker
	"The view window has changed.  Update the marker."

	self moveMarker: self markerDelta negated!

moveMarker: anInteger
	"Update the marker so that is is translated by an amount corresponding to
	a distance of anInteger, constrained within the boundaries of the scroll bar."

	Display fill: marker mask: scrollBar insideColor.
	marker _ marker translateBy: 0 @
				((anInteger min: self scrollBarOnlyArea bottom - marker bottom) max:
					self scrollBarOnlyArea top - marker top).
	marker displayOn: Display! !

!ScrollController methodsFor: 'private: private'!

displayScrollBar
	scrollBar displayOn: Display.
	"YellowMenuForm displayOn: Display at: scrollBar inside topLeft"!

scrollBarOnlyArea
	^scrollBar inside topLeft "+ (0@YellowMenuForm height)"
		corner: scrollBar inside bottomRight - (8@0)!

yellowMenuArea
	"^scrollBar inside topLeft extent: YellowMenuForm extent."
	^scrollBar inside topRight - (8@0)
		corner: scrollBar inside bottomRight! !

!ScrollController methodsFor: 'private'!

scrollAbsolute
	| oldMarker |
	self canScroll ifTrue: [Cursor marker showWhile: 
		[[sensor anyButtonPressed] whileTrue:
			[oldMarker _ marker.
			marker _ marker translateBy:
				0@((sensor cursorPoint y - marker center y min:
					scrollBar inside bottom - marker bottom) max: scrollBar inside top - marker top).
			(oldMarker areasOutside: marker), (marker areasOutside: oldMarker) do:
				[:region | Display fill: region rule: Form reverse mask: Form gray].
			self scrollView]].
		scrollBar display.
		self moveMarker]!

scrollDown
	Cursor down showWhile:
	[self canScroll
		ifTrue: 
			[self scrollViewDown.
			self moveMarker].
	sensor waitNoButton]!

scrollUp
	Cursor up showWhile:
	[self canScroll
		ifTrue: 
			[self scrollViewUp.
			self moveMarker].
	sensor waitNoButton]! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

ScrollController class
	instanceVariableNames: ''!


!ScrollController class methodsFor: 'scrollbar access'!

getSavedAreaFor: aScrollBar 
	"Cache the a form representing the area of the display screen on 
	which the scroll bar will be displayed."

	SavedArea _ Form fromDisplay: aScrollBar.
	SavedArea offset: aScrollBar origin!

haltedScrollBar
	"Answer the image of the scroll bar that was interrupted."

	| tmp |
	tmp _ HaltedScrollBar.
	HaltedScrollBar _ nil.
	^tmp!

haltScrollBar
	"If the cached display area contains information, then restore the 
	display to that form."

	SavedArea == nil
		ifTrue: [HaltedScrollBar _ nil]
		ifFalse: 
			[HaltedScrollBar _ Form fromDisplay: (SavedArea boundingBox translateBy: SavedArea offset).
			HaltedScrollBar offset: SavedArea offset.
			self restoreSavedArea]!

restoreHaltedScrollBar: aHaltedScrollBar 
	"Redisplay the image of the scroll bar that exists before an interrupt occurred."

	aHaltedScrollBar == nil
		ifFalse: 
			[SavedArea _ Form fromDisplay: (aHaltedScrollBar boundingBox translateBy: aHaltedScrollBar offset).
			SavedArea offset: aHaltedScrollBar offset.
			aHaltedScrollBar display]!

restoreSavedArea
	"If an image was saved before the scroll bar was displayed, then 
	restore it to the screen."

	SavedArea notNil
		ifTrue: 
			[SavedArea displayOn: Display.
			SavedArea _ nil]! !

!ScrollController class methodsFor: 'class initialization'!

dontDoYellowMenu
	"ScrollController dontDoYellowMenu"
	YellowMenuForm _  Form extent: 0@0!

initialize
	"ScrollController initialize"
	YellowMenuForm _ 
		(Form
	extent: 30@16
	fromArray: #( 0 0 0 0 3847 33728 6540 50784 4299 25648 4300 58416 4299 25648 4300 58416 4299 25648 6604 58992 4039 58352 1923 49632 0 0 0 0 0 0 65535 65535)
	offset: 0@0)! !

ScrollController initialize!
