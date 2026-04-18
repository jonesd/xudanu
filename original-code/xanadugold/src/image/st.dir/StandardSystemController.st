'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:49:38 pm'!

MouseMenuController subclass: #StandardSystemController
	instanceVariableNames: 'status labelForm viewForm '
	classVariableNames: 'RedIsBlueInTab '
	poolDictionaries: ''
	category: 'Interface-Support'!
StandardSystemController comment:
'Class StandardSystemController represents a controller for StandardSystemViews, that is, those views that are at the top level of a project in the system user interface.  It is a kind of MouseMenuController that creates a blue button menu for moving, framing, collapsing, and closing its views, and for selecting views under its view.

Instance Variables:
	status		<Symbol> condition, either 
					#active--keep control as long as the cursor is inside the view if a 
								button is pressed
					#inactive -- no longer in control, deEmphasize any highlighting
					#open -- visible on the screen
					#closed -- unschedule the instance from the project 
	labelForm	<Form> the image of the label for a view that is displayed at the upper left edge
	viewForm	<Form> the image of the view itself, whether open or collapsed

Class Variables:
	MenuWhenCollapsed 			<ActionMenu> valid selections when the view is collapsed
	RedIsBlueInTab					<Boolean> true if the select button is recognized in the label tab as providing access to the view menu
	ScheduledBlueButtonMenu		<PopUpMenu>
	ScheduledBlueButtonMessages	<Array of: Symbols>
'!


!StandardSystemController methodsFor: 'initialize-release'!

{PopUpMenu} blueButtonMenu
	"Initial menu for manipulating the window itself.  Can be changed later."
		
	^PopUpMenu fromPrefixedArray: #(
		(all		'new label'		newLabel	'')
		-
		(long	'under'			under		'')
		(long	'move'			move		'')
		(all		'frame'			frame		'')
		(all		'collapse'			collapse	'')
		-
		(live	'close'	( 
			(live	'confirm'		close		'') ) )
		(dead	'close'			close		''))!

initialize
	super initialize.
	status _ #inactive.! !

!StandardSystemController methodsFor: 'control defaults'!

isControlActive
 
	^status == #active
		and: [sensor anyButtonPressed
				ifTrue: [(view containsPoint: sensor cursorPoint)
						ifTrue: [view isCollapsed
									ifTrue: [view subViewWantingControl ~~ nil]
									ifFalse: [true]]
						ifFalse: [false]]
			ifFalse: [true]]!

isControlWanted

	self viewHasCursor ifFalse: [^false].
	^view isCollapsed
		ifTrue: [view subViewWantingControl ~~ nil]
		ifFalse: [true]! !

!StandardSystemController methodsFor: 'basic control sequence'!

controlInitialize
	view refreshDisplay.
	self flushDisplayBits.
	status _ #active!

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
			self controlActivity.
			status ~~ #closed ifTrue: [self idle]]!

controlTerminate
	status == #closed
		ifTrue: 
			[view ~~ nil ifTrue: [view release].
			self flushDisplayBits.
			ScheduledControllers unschedule: self.
			^self].
	status == #inactive
		ifTrue: 
			[view deEmphasize.
			self saveDisplayBits.
			ScheduledControllers pullBottomToTop.
			^self].
	view deEmphasize.
	self saveDisplayBits!

idle
	"do nothing"! !

!StandardSystemController methodsFor: 'menu messages'!

blueButtonActivity
	"Menu for manipulating the window itself."
	"Use this menu if collapsed.  Punt to superclass if expanded."

	| selector |
	view isCollapsed
		ifTrue:
			[(selector _ (PopUpMenu fromPrefixedArray: #(
						(all		'new label'		newLabel	'')	"All are standard smalltalk."
						-
						(long	'under'			under		'')
						(all		'move'			move		'')
						(long	'expand'		expand		'')
						-
						(all		'close'			close		'') )) startUp) ~= 0
				ifTrue: [self menuMessageReceiver perform: selector]]
		ifFalse:
			[^super blueButtonActivity]!

close
	"The receiver's view should be removed from the screen and from the
	collection of scheduled views."

	model changeRequest  "check for changes in progress"
		ifFalse: [^self].
	status _ #closed.
	view erase!

collapse
	"Get the receiver's view to change to a collapsed view on the screen. "

	| oldFrame lastIconFrame| 
	lastIconFrame _ view lastIconFrame.
	view deEmphasize.
	oldFrame _ view displayBox.
	view erase.
	view collapse.
	lastIconFrame == nil
		ifTrue: [self moveIcon.]
		ifFalse: [view
					align: view displayBox origin
					with: lastIconFrame origin.
				Display zoom: oldFrame to: view displayBox].
	view displayEmphasized!

expand
	"Expand the collapsed view."

	view restoreFullView!

frame
	"The receiver's view was collapsed;  open it again and ask the user to
	designate its rectangular area.  The save code is used for expand"

	view erase.
	self moveOpened.
	self trackFrame.
	view displayEmphasized!

move
	"Move the view to a new position on the display."

	view erase.
	view isCollapsed 
		ifTrue: [self moveIcon]
		ifFalse: [self moveOpened].
	view displayEmphasized!

newLabel
	"Prompt the user for a new label."

	| newLabel |
	newLabel _ FillInTheBlank request: 'Type the new label' initialAnswer: view label.
	newLabel = ''
		ifFalse: [view deEmphasize.
				view newLabel: newLabel.
				view emphasize].!

redButtonActivity
	"Do the view button activity if the class variable is true, otherwise do nothing."

	(RedIsBlueInTab and:
		[view isCollapsed or: [view labelDisplayBox containsPoint: sensor cursorPoint]])
			ifTrue: [^self blueButtonActivity]
			ifFalse: [^super redButtonActivity]!

under
	"Deactive the receiver's scheduled view and pass control to any view that
	might be positioned directly underneath it and the cursor."

	status _ #inactive!

yellowButtonActivity
	^(view labelDisplayBox containsPoint: sensor cursorPoint )
	ifTrue: [ self blueButtonActivity]
	ifFalse:[ super yellowButtonActivity]! !

!StandardSystemController methodsFor: 'scheduling'!

closeAndUnschedule
	"Erase the receiver's view and remove it from the collection of scheduled controllers."

	status _ #closed.
	view erase.
	view release.
	ScheduledControllers unschedule: self!

closeAndUnscheduleNoErase
	"Remove the scheduled view from the collection of scheduled controllers.
	Set its status to closed but do not erase."

	status _ #closed.
	view release.
	ScheduledControllers unschedule: self!

open
	"Create an area on the screen in which the receiver's scheduled controller can
	be displayed.  Make it the active controller."
	
	view window: view window viewport: (sensor cursorPoint extent: view minimumSize).
	status _ #open.
	self moveOpened.
	self trackFrame.
	ScheduledControllers scheduleActive: self!

openDisplayAt: aPoint 
	"Create an area with origin aPoint in which the receiver's scheduled
	view can be displayed.  If necessary, translate so the view is completely
	on the screen.  Make it the active view."

	view align: view viewport center with: aPoint.
	view translateBy:
		(view displayBox amountToTranslateWithin: Display boundingBox).
	view viewport.
	status _ #open.
	ScheduledControllers scheduleActive: self!

openNoTerminate
	"Create an area in which the receiver's scheduled view can
	be displayed.  Make it the active view.  Do not terminate the currently active
	process."

	view window: view window viewport: (sensor cursorPoint extent: view minimumSize).
	status _ #open.
	self moveOpened.
	self trackFrame.
	ScheduledControllers scheduleActiveNoTerminate: self!

openNoTerminateDisplayAt: aPoint 
	"Create an area with origin aPoint in which the receiver's scheduled view can
	be displayed.  Make it the active view.  Do not terminate the currently active
	process."

	view resizeMinimumCenteredAt: aPoint.
	status _ #open.
	ScheduledControllers scheduleActiveNoTerminate: self! !

!StandardSystemController methodsFor: 'bit caching'!

flushDisplayBits
	"Get rid of the cached bits."

	StandardSystemView fillHoles
		ifTrue: [labelForm _ nil.
				viewForm _ nil]!

intersectsDisplayBoxOf: aController 
	"Answer whether the receiver's view's display region intersects the 
	display region for aController's view."

	^aController view displayRegion intersects: view displayRegion!

isActiveController
	"Answer whether the receiver is the active controller."

	^self == ScheduledControllers activeController!

labelForm
	"Answer the cached label form."

	^labelForm!

refreshDisplay
	"Redisplay the image of the receiver's view."

	(StandardSystemView fillHoles and: [view isCollapsed not])
		ifTrue: 
			[(labelForm == nil or: [viewForm == nil])
				ifTrue: [view displayEmphasized]
				ifFalse: [labelForm displayOn: Display at: view labelDisplayBox origin.
						viewForm displayOn: Display at: view displayBox origin.
						view emphasize]]
		ifFalse: [view displayEmphasized]!

saveDisplayBits
	"Cache the receiver's view's image."

	StandardSystemView fillHoles
		ifTrue: [labelForm _ view labelBits.
				viewForm _ view viewBits]!

showOnDisplay
	"Redisplay the image of the receiver's view."

	(StandardSystemView fillHoles)
		ifTrue: 
			[(labelForm == nil or: [viewForm == nil])
				ifTrue: [view display]
				ifFalse: [labelForm displayOn: Display at: view labelDisplayBox origin.
						viewForm displayOn: Display at: view displayBox origin]]
		ifFalse: [view displayEmphasized]!

viewForm
	"Answer the cached view form."

	^viewForm! !

!StandardSystemController methodsFor: 'private: private'!

moveIcon
	"Ask the user to designate a new origin position for the receiver's icon. "

	| form |
	sensor cursorPoint: view displayBox origin.
	form _ view image.
	Cursor blank
		showWhile: [form follow: [sensor maybeGriddedCursorPoint] while: [sensor noButtonPressed]].
	view window: view window viewport: (sensor maybeGriddedCursorPoint extent: view displayBox extent).
	sensor waitNoButton.
	sensor cursorPoint: view displayBox center!

moveOpened
	"Ask the user to designate a new origin position for the receiver's view."

	| form frame location background offset |
	frame _ view displayBox.
	form _ Form extent: (view labelDisplayBox extent).
	offset _ (0@form extent y).
	location _ view labelDisplayBox origin.
	background _ form backgroundAt: location.
	form _ view labelForm.
	form displayAt: location.
	sensor cursorPoint: location + offset.
	Cursor origin
		showWhile:
			[Display
				outline: [frame _ (frame moveTo: sensor maybeGriddedCursorPoint) rounded]
				do: [form moveTo: frame origin - offset restoring: background]
				while: [ sensor anyButtonPressed not]
				width: 2
				halftone: Form gray.
			background display].
	view window: view window viewport: frame!

trackFrame
	"Track the mouse and set the displayBox of the view"

	| frame background startPoint | 
	frame _ view displayBox.
	view minimumSize = view maximumSize ifTrue: [^self].
	background _ Form fromDisplay: view labelDisplayBox.
	view displayLabel.
	startPoint _ frame corner.
	sensor cursorPoint: ((frame corner
						max: sensor cursorPoint)
						min: frame origin + view maximumSize).
	Cursor corner
		showWhile: 
			[Display
				outline: [frame corner: ((sensor maybeGriddedCursorPoint
										max: (frame origin + view minimumSize))
										min: (frame origin + view maximumSize))]
				while: [Sensor anyButtonPressed]
				width: 2
				halftone: Form gray].
	"If the user didn't drag the mouse, then he's still focussed on the origin."
	startPoint = frame corner ifTrue: [sensor cursorPoint: frame origin].
	background displayAt: view labelDisplayBox origin.
	view window: view window viewport: frame.! !

!StandardSystemController methodsFor: 'smalltalk: passe'!

initializeBlueButtonMenu
	"Initial menu for manipulating the window itself.  Can be changed later."
	
	self passe! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

StandardSystemController class
	instanceVariableNames: ''!


!StandardSystemController class methodsFor: 'class initialization'!

initialize
	"Initialize the class variables."

	"StandardSystemController initialize.
	StandardSystemController allInstances do: [:sc |
		 sc initializeBlueButtonMenu]"

	RedIsBlueInTab _ true.	"Default: do not pop up blue button menu in title tab."! !

!StandardSystemController class methodsFor: 'class variable access'!

isRedBlueInTab
	"Answer whether red button behaves like blue in the title tab."
	^RedIsBlueInTab!

isRedBlueInTab: aBoolean
	"Set whether red button should behave like blue in the title tab."
	" StandardSystemController isRedBlueInTab: true "

	RedIsBlueInTab _ aBoolean! !

StandardSystemController initialize!
