'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:49:31 pm'!

Object subclass: #ControlManager
	instanceVariableNames: 'scheduledControllers activeController activeControllerProcess screenController interruptLock '
	classVariableNames: 'InterruptLockedSignal LastDisplayExtent '
	poolDictionaries: ''
	category: 'Interface-Framework'!
ControlManager comment:
'Class ControlManager represents the top level control over scheduling which controller of a view on the screen the user is actively using.  ScheduledControllers is the global reference to an instance of ControlManager, the one attached to the Project currently being used.
   
Instance Variables:
	scheduledControllers	<OrderedCollection> of Controllers, usually ScheduledControllers
	activeController		<Controller> usually a ScheduledController
	activeControllerProcess	<Process>
	screenController 		<ScreenController> also appears in ScheduledControllers
	isLocked				<Boolean> true if handling #interruptName:

Class Variables:
	InterruptLockSignal		<Signal> raised when #interruptName: is sent while already being handled
	LastDisplayExtent		<Point> the most recent display size change registered by the input mechanism.
'!


!ControlManager methodsFor: 'initialize-release'!

initialize
	"Initialize the receiver to refer to only the background controller."
	| screenView |
	screenController _ ScreenController new.
	screenView _ FormView new.
	screenView model: (InfiniteForm with: Form gray) controller: screenController.
	screenView window: Display boundingBox.
	scheduledControllers _ OrderedCollection with: screenController.
	interruptLock _ false!

release
	scheduledControllers == nil
		ifFalse: 
			[scheduledControllers 
				do: [:controller | (controller isKindOf: Controller)
								ifTrue: [controller view release]
								ifFalse: [controller release]].
			scheduledControllers _ nil]! !

!ControlManager methodsFor: 'accessing'!

activeController
	"Answer the currently active controller."

	^activeController!

activeController: aController 
	"Set aController to be the currently active controller.   Give the user control in it."

	activeController _ aController.
	self promote: aController.
	activeControllerProcess _ 
			[Controller badControllerSignal
				handle: [:ex | self halt. aController closeAndUnschedule.
						self removeInvalidControllers.
						Transcript show: 'Bad controller whose view is nil.'.
						ex return]
				"If the active controller 's view is nil, BadControllerSignal is raised"
				do: [aController startUp].
			self searchForActiveController] newProcess.
	activeControllerProcess priority: Processor userSchedulingPriority.
	activeControllerProcess resume!

activeController: aController andProcess: aProcess 
	"Set aController to be the currently active controller and aProcess to be the
	the process that is handles controller scheduling activities in the system."
	

	self inActiveControllerProcess
		ifTrue: 
			[aController~~nil
				ifTrue: [(scheduledControllers includes: aController)
							ifTrue: [self promote: aController]
							ifFalse: [self error: 'Old controller not scheduled']].
			activeController controlTerminate.
			activeController _ aController.
			activeController == nil
				ifFalse: [activeController controlInitialize].
			activeControllerProcess _ aProcess.
			activeControllerProcess resume]
		ifFalse: 
			[self error: 'New active controller process must be set from old one']!

activeControllerNoTerminate: aController andProcess: aProcess 
	"Set aController to be the currently active controller and aProcess to be the
	the process that handles controller scheduling activities in the system.
	This message differs from activeController:andProcess: in that it does not send
	controlTerminate to the currently active controller."
	

	self inActiveControllerProcess
		ifTrue: 
			[aController~~nil
				ifTrue: [(scheduledControllers includes: aController)
							ifTrue: [self promote: aController]
							ifFalse: [self error: 'Old controller not scheduled']].
			activeController _ aController.
			activeController == nil
				ifFalse: [activeController controlInitialize].
			activeControllerProcess _ aProcess.
			activeControllerProcess resume]
		ifFalse: 
			[self error: 'New active controller process must be set from old one']!

activeControllerProcess
	"Answer the process that is currently handling controller scheduling activities
	in the system."
	^activeControllerProcess!

isScheduled: aController
	"Answer whether the argument aController is one of the scheduled
	controllers."

	^scheduledControllers includes: aController!

removeInvalidControllers
	"If any scheduledControllers would interfere with the display of a notifier, unschedule them."

	activeController == nil
		ifFalse:	[activeController view == nil
			ifTrue:	[activeController _ nil]].
	scheduledControllers _ scheduledControllers select: [ :i | i view ~~ nil]!

scheduledControllers
	"Answer a copy of the ordered collection of scheduled controllers."
	^scheduledControllers copy! !

!ControlManager methodsFor: 'scheduling'!

findWindow
	"Present a menu of window titles, and activate the one that gets chosen"
	| controllers labels index |
	controllers _ OrderedCollection new.
	labels _ String streamContents:
		[:strm |
		scheduledControllers do:
			[:controller | controller == screenController ifFalse:
				[controllers addLast: controller.
				strm nextPutAll: (controller view label contractTo: 40); cr]].
		strm skip: -1  "drop last cr"].
	index _ (PopUpMenu labels: labels) startUp.
	index > 0 ifTrue:
		[self activeController: (controllers at: index).
		(activeController view labelDisplayBox
			intersect: Display boundingBox) area < 200
				ifTrue: [activeController move].
		Processor terminateActive]!

inActiveControllerProcess
	"Answer whether the active scheduling process is the actual active process in the system."

	^activeControllerProcess == Processor activeProcess!

interruptName: title
	"Raise a signal on the active scheduling process.
	The default handler of the signal creates a notifier."

	| currentLock |
	currentLock _ interruptLock.
	interruptLock _ true.
	currentLock
		ifTrue:	[^self class interruptLockedSignal raise].
	activeControllerProcess interruptWith:
			[[Object userInterruptSignal 
					raiseRequestWith: thisContext sender sender sender sender sender
					errorString: title] valueNowOrOnUnwindDo: [interruptLock _ false]]!

promote: aController
	"Make aController be the first scheduled controller in the ordered collection."
	
	scheduledControllers remove: aController.
	scheduledControllers addFirst: aController!

promoteToSecond: aController
	"Make aController be the first scheduled controller in the ordered collection."
	
	scheduledControllers remove: aController.
	scheduledControllers add: aController after: scheduledControllers first!

pullBottomToTop
	"Make the last scheduled view which wants control be the first one.  Used for implementing the message under to a scheduled controller."

	scheduledControllers reverseDo:
		[:controller |
		(controller isControlWanted and: [controller ~~ screenController]) ifTrue:
			[^scheduledControllers addFirst: (scheduledControllers remove: controller)]]!

scheduleActive: aController 
	"Make aController be scheduled as the active controller.  Presumably the active
	scheduling process asked to schedule this controller and that a new process associated
	this controller takes control.  So this is the last act of the active scheduling process."

	Cursor normal show.
	self scheduleActiveNoTerminate: aController.
	Processor terminateActive!

scheduleActiveNoTerminate: aController 
	"Make aController be the active controller.  Presumably the process that requested
	the new active controller wants to keep control to do more activites before the
	new controller can take control.  Therefore, do not terminate the currently
	active process."

	self schedulePassive: aController.
	self scheduled: aController
		from: Processor activeProcess!

scheduleOnBottom: aController 
	"Make aController be scheduled as a scheduled controller, but not the active one.
	Put it at the end of the ordered collection of controllers."

	scheduledControllers addLast: aController!

schedulePassive: aController 
	"Make aController be scheduled as a scheduled controller, but not the active one.
	Put it at the beginning of the ordered collection of controllers."

	scheduledControllers addFirst: aController!

searchForActiveController
	"Find a scheduled controller that wants control and give control to it.  If none
	wants control, then see if the System Menu has been requested."

	| newController |
	(activeControllerProcess == nil or: [activeControllerProcess == Processor activeProcess])
		ifFalse: [^self].
	activeController _ nil.
	Object errorSignal 
		handle: [:ex | "bad controller"
				ScheduledControllers removeInvalidControllers.
				ex restart]
		"If the active controller's view is nil, MessageNotUnderstoodSignal 
		is raised and caught as ErrorSignal by the handler."
		do: 
		[[Processor yield.
	 	newController _ scheduledControllers 
			detect:
				[:aController |
				aController isControlWanted and:
							[aController ~~ screenController]]
			ifNone:
				[screenController isControlWanted
					ifTrue: [screenController]
					ifFalse: [nil]].
		newController isNil]
			whileTrue].
	self activeController: newController.
	Processor terminateActive!

unschedule: aController
	"Remove the view, aController, from the collection of scheduled controllers."

	scheduledControllers remove: aController ifAbsent: []! !

!ControlManager methodsFor: 'displaying'!

displaySafe: aBlock forController: aController 
	"Put the display of the view for the argument aController at the top of all
	views and evaluate the argument aBlock."

	| intersects |
	(scheduledControllers includes: aController)
		ifFalse: [^nil].
	activeController == aController ifTrue: [^aBlock value].
	activeController == nil
		ifTrue: 
			[aController showOnDisplay.
			aBlock value.
			aController saveDisplayBits.
			^self promote: aController].
	(intersects _ activeController intersectsDisplayBoxOf: aController)
		ifTrue: [activeController saveDisplayBits].
	aController showOnDisplay.
	aBlock value.
	aController saveDisplayBits.
	intersects ifTrue: [activeController showOnDisplay; flushDisplayBits].
	self promoteToSecond: aController!

redraw
	"Redisplay all of the scheduled views on the display screen."

	| aPoint |
	aPoint _ 0@0.
	self unschedule: screenController.
	self scheduleOnBottom: screenController.
	screenController view window: Display boundingBox.
	scheduledControllers
		reverseDo: 
			[:aController | 
			aController view display; deEmphasize.
			(aController view viewport intersects: Display boundingBox)
				ifFalse:
					[(Display boundingBox containsPoint: (aPoint _ aPoint + (10@10)))
						ifFalse: [aPoint _ 10@10].
					aController view moveTo: aPoint].
			aController saveDisplayBits].
	Cursor normal show!

restore
	"Redisplay all of the scheduled views on the screen."

	LastDisplayExtent == nil
		ifFalse: 
			[| ns |
			ns _ LastDisplayExtent.
			LastDisplayExtent _ nil.
			DisplayScreen displaySize: ns].
	self redraw! !

!ControlManager methodsFor: 'restoring'!

backgroundFormFor: aRectangle
	"Answer the background bits for aRectangle no matter what the background is."

	|backgroundBits background|
	backgroundBits _ Form extent: aRectangle extent.
	background _ screenController model.
	background class == InfiniteForm
		ifTrue: [background
					displayOn: backgroundBits
					at: 0 @ 0
					clippingBox: backgroundBits boundingBox
					rule: Form over
					mask: Form black]
		ifFalse: [(background isKindOf: Form)
				ifTrue: [backgroundBits
							copyBits: aRectangle
							from: background
							at: 0 @ 0
							clippingBox: backgroundBits boundingBox
							rule: Form over
							mask: nil]
				ifFalse: [backgroundBits gray]].
	^backgroundBits!

restoreOn: aRegion for: aView 
	"Clear the display area aRegion for the requesting view aView."

	| controller controllers regions indx hisRegion bits reg cache pt background|
	"Force to a display boundary that won't leave a white line."
	background _ screenController model.
	background class == InfiniteForm
		ifTrue: [pt _ background form extent.
				reg _ Rectangle
					origin: (aRegion origin - (pt - (1@1)) grid: pt)
					corner: aRegion corner]
		ifFalse: [reg _ aRegion].
	"get the controllers that have views that intersect the view being erased"
	controllers _ OrderedCollection new: scheduledControllers size.
	regions _ OrderedCollection new: scheduledControllers size.
	indx _ 1.
	[indx <= scheduledControllers size]
		whileTrue: 
			[controller _ scheduledControllers at: indx.
			((controller ~= screenController and: [controller view ~= aView])
				and: [(hisRegion _ controller view displayRegion) intersects: reg])
				ifTrue: 
					[controllers add: controller.
					regions add: hisRegion].
			indx _ indx + 1].

	"put the cached bits from intersecting views on the display with double buffering"
	bits _  self backgroundFormFor: reg.
	(controllers size to: 1 by: -1)
		do: 
			[:i | 
			controller _ controllers at: i.
			(cache _ controller labelForm) == nil
				ifFalse: [cache displayOn: bits at: controller view labelDisplayBox origin - reg origin].
			(cache _ controller viewForm) == nil
				ifFalse: [cache displayOn: bits at: controller view displayBox origin - reg origin]].
	"bits displayOn: Display at: reg origin"
	bits displayOn: Display at: reg origin clippingBox: aRegion rule: Form over mask: nil!

saveActiveViewsBits
	"Cache the view image of the active controller, if there is one."

	activeController ~= nil ifTrue: [activeController saveDisplayBits]! !

!ControlManager methodsFor: 'backgrounds'!

background: color 
	"Set the background color."
	"ScheduledControllers background: Form lightGray."

	self backgroundForm: (InfiniteForm with: color)!

backgroundForm: aDisplayObject
	"Set the background form by changing the screenController's model."
	"Display white.  Pen new spiral: 1000 angle: 89; home; spiral: 1000 angle: -89. 	
	ScheduledControllers backgroundForm: (Form fromDisplay: Display boundingBox)."

	screenController view model: aDisplayObject.
	self restore! !

!ControlManager methodsFor: 'private: private'!

deactivate

	self flushDisplayBits.
	activeController _ nil.
	activeControllerProcess _ nil!

flushDisplayBits
	"Get rid of the cached bits."

	scheduledControllers do: [:aController | aController flushDisplayBits]!

scheduled: aController from: aProcess
	activeControllerProcess==aProcess 
		ifTrue: 
			[activeController ~~ nil
					ifTrue: [activeController controlTerminate].
			aController centerCursorInView.
			self activeController: aController]
		ifFalse:
			[aController view displaySafe: []]! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

ControlManager class
	instanceVariableNames: ''!


!ControlManager class methodsFor: 'instance creation'!

new
	^super new initialize! !

!ControlManager class methodsFor: 'accessing'!

lastDisplayExtent: aPoint
	"Set a shared variable to the size of the last display area."

	LastDisplayExtent _ aPoint!

newScheduler: controlManager
	"When switching projects, the control scheduler has to be exchanged.  The
	active one is the one associated with the current project."

	ScheduledControllers deactivate.
	Smalltalk at: #ScheduledControllers put: controlManager.
	ScheduledControllers restore.
	controlManager searchForActiveController! !

!ControlManager class methodsFor: 'class initialization'!

initialize
	"Initialize signals"
	"ControlManager initialize"

	InterruptLockedSignal _ (Object errorSignal newSignalMayProceed: false)
		notifierString: 'There is currently no active controller';
		nameClass: self message: #interruptLockedSignal! !

!ControlManager class methodsFor: 'Signal constants'!

interruptLockedSignal

	^InterruptLockedSignal! !

ControlManager initialize!
