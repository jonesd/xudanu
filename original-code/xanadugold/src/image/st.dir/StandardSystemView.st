'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:49:39 pm'!

View subclass: #StandardSystemView
	instanceVariableNames: 'labelFrame labelText isLabelComplemented savedSubViews minimumSize maximumSize iconView iconText lastFrame cacheRefresh '
	classVariableNames: 'FillInHoles '
	poolDictionaries: ''
	category: 'Interface-Support'!
StandardSystemView comment:
'Class StandardSystemView represents a view that has a label above its top left corner.  The text in the label identifies the kind of view.  In addition to a label, the class add control over the maximum and minimum size of the display box of its instances.  The default controller for a StandardSystemView is StandardSystemController.  The elements of ScheduledControllers, the sole instance of ControlManager, usually contain controllers for instances of StandardSystemView.

Instance Variables:
	labelFrame				<Quadrangle>
	labelText				<Paragraph>
	isLabelComplemented	<Boolean> true if the label is complemented
	savedSubViews			<Array> of Views
	minimumSize				<Point> representing minimum width and height
	maximumSize			<Point> representing maximum width and height
	iconView				<Icon> the image of the receiver when collapsed
	iconText				<String> to be displayed in the collapsed view of the receiver
	lastFrame				<Rectangle> the last open size of the receiver
	cacheRefresh			<Boolean>

Class Variables:
	FillInHoles		<Boolean> indicating whether or not to maintain a "clean" screen by caching image information
								and replacing any areas changed by moving or reframing views.'!


!StandardSystemView methodsFor: 'initialize-release'!

initialize
	super initialize.
	self insideColor: Form white.
	labelFrame _ Quadrangle new.
	labelFrame region: (Rectangle origin: 0 @ 0 extent: 50 @ 20).
	labelFrame insideColor: Form white.
	labelFrame
		borderWidthLeft: 2
		right: 2
		top: 2
		bottom: 0.
	self label: nil.
	isLabelComplemented _ false.
	minimumSize _ 50 @ 50.
	self maximumSize: nil.
	cacheRefresh _ true!

release
	self expand.
	iconView == nil ifFalse: [iconView release].
	super release! !

!StandardSystemView methodsFor: 'testing'!

containsPoint: aPoint 
	^(super containsPoint: aPoint)
		| (self labelDisplayBox containsPoint: aPoint)!

isCollapsed
	"Answer whether the scheduled view is collapsed (true) or expanded (false)."
	^savedSubViews ~~ nil! !

!StandardSystemView methodsFor: 'label access'!

deEmphasizeLabel
	"If the label is highlighted, reverse it."

	isLabelComplemented
		ifTrue: 
			[self reverseLabel.
			isLabelComplemented _ false]!

emphasizeLabel
	"Highlight the label."

	isLabelComplemented
		ifFalse: 
			[self reverseLabel.
			isLabelComplemented _ true]!

label
	"Answer the string that appears in the receiver's label."
	^labelText isNil
		ifTrue: [^'']
		ifFalse: [labelText asString]!

label: aString 
	"Set aString to be the receiver's label."
	aString == nil 
		ifTrue: 
			[labelText _ nil.
			labelFrame region: (0 @ 0 extent: 0 @ 0)]
		ifFalse:
			[labelText _ (Text string: aString emphasis: 1) asParagraph.
			labelFrame region: (0 @ 0 extent: labelText boundingBox extent + (8 @ 4))].
	iconText isNil & iconView notNil
		ifTrue:
			[iconView text: self label asText].!

labelDisplayBox
	"Answer the rectangle that borders the visible parts of the receiver's label on the
	display screen."

	^labelFrame
		align: (self isCollapsed
				ifTrue: [labelFrame topLeft]
				ifFalse: [labelFrame bottomLeft])
		with: self displayBox topLeft!

labelForm
	"Answer with a form that contains the label text."

	| form formBox |
	form _ Form extent: labelFrame extent.
	labelFrame displayOn: form.
	labelText isNil
		ifFalse:
			[formBox _ form boundingBox.
			labelText
				displayOn: form
				at: (formBox center -
						(labelText boundingBox center -
							labelText boundingBox topLeft))
				clippingBox: formBox].
	^form!

labelFrame
	"Answer the bounding box for the label."
	^labelFrame!

labelFrame: aQuadrangle 
	"Set the bounding box for the label to be aQuadrangle."
	labelFrame _ aQuadrangle!

newLabel: aString 
	"Set aString to be the new label text."

	| oldLabelDisplayBox oldLabelComplemented |
	oldLabelDisplayBox _ self labelDisplayBox.
	oldLabelComplemented _ isLabelComplemented.
	self label: aString.
	"change label"
	self iconView isNil 
		ifFalse: [self iconView isFromLabel
					ifTrue: [| v |
							v _ IconView on: self iconFromLabel.
							self isCollapsed
								ifTrue:	[self erase.
										self removeSubView: iconView.
										self addSubView: (iconView _ v).
										self window: nil.
										self setTransformation: (WindowingTransformation scale: nil translation: self transformation translation)]
								ifFalse:	[iconView _ v]]
					ifFalse: [self iconText: aString]].
	self isCollapsed
		ifTrue: 
			[self iconView isFromLabel
				ifTrue: [self display]
				ifFalse: [self iconText: aString].
			oldLabelComplemented ifTrue: [self emphasize]]
		ifFalse: 
			[oldLabelDisplayBox width > self labelDisplayBox width
				ifTrue: [self eraseRectangle: oldLabelDisplayBox].
			self displayView.
			oldLabelComplemented ifTrue: [self emphasizeLabel]]! !

!StandardSystemView methodsFor: 'size'!

maximumSize
	"Answer a point representing the maximum width and height of the receiver."

	^maximumSize == nil
		ifTrue: [Display extent]
		ifFalse: [maximumSize]!

maximumSize: aPointOrNil
	"Set the argument, aPoint, to be the maximum width and height of the receiver."
	maximumSize _ aPointOrNil!

minimumSize
	"Answer a point representing the minimum width and height of the receiver."
	^minimumSize!

minimumSize: aPoint 
	"Set the argument, aPoint, to be the minimum width and height of the receiver."
	minimumSize _ aPoint! !

!StandardSystemView methodsFor: 'framing'!

collapse
	"If the receiver is not already collapsed, change its view to be that of its icon only."

	| icon |
	self isCollapsed ifFalse: 
			[lastFrame _ self displayBox.
			savedSubViews _ Array with: subViews with: window with: viewport.
			self resetSubViews.
			iconText isNil & labelText isNil ifTrue: [self label: 'No Label'].
			iconView isNil ifTrue: 
					[icon _ Icon constantNamed: #default.
					icon isNil
						ifTrue: [iconView _ IconView on: self iconFromLabel]
						ifFalse: 
							[iconView _ IconView on: icon.
							iconView text: self label asText]].
			self addSubView: iconView.
			self window: nil.
			self setTransformation: (WindowingTransformation scale: nil translation: self transformation translation)]!

erase
	"Clear the display box of the receiver to be gray, as in the screen background."

	isLabelComplemented _ false.
	FillInHoles
		ifTrue: [ScheduledControllers restoreOn: self displayRegion for: self]
		ifFalse: [self clear: Form gray.
				Display fill: self labelDisplayBox region mask: Form gray]!

eraseLabel
	"Erase label."

	ScheduledControllers restoreOn: self labelDisplayBox for: self!

eraseRectangle: aRectangle
	"Erase aRectangle of the receiver's display area."

	ScheduledControllers restoreOn: aRectangle for: self!

expand
	"If the receiver is collapsed, change its view to be that of all of its subviews,
	not its icon alone."

	self isCollapsed ifTrue:
			[self removeSubView: iconView.
			subViews _ savedSubViews at: 1.
			window _ savedSubViews at: 2.
			viewport _ savedSubViews at: 3.
			savedSubViews _ nil]!

getFrame
	"Ask the user to designate a rectangular area in which the receiver should be displayed."

	|frame |
	viewport == nil
		ifTrue: [frame _ Sensor cursorPoint extent: self minimumSize]
		ifFalse: [frame _ self displayBox.
				Sensor cursorPoint: frame origin].
	Sensor waitNoButton.
	Cursor origin
		showWhile: 
			[Display
				outline: [frame _ Sensor maybeGriddedCursorPoint extent: frame extent]
				while: [Sensor anyButtonPressed not]
				width: 2
				halftone: Form gray].
	self minimumSize = self maximumSize ifTrue: [^frame].
	Sensor cursorPoint: ((frame corner
												max: Sensor cursorPoint)
												min: frame origin + self maximumSize).
	Cursor corner
		showWhile: 
			[Display
				outline: [frame corner: ((Sensor cursorPoint
												max: (frame origin + self minimumSize))
												min: (frame origin + self maximumSize))]
				while: [Sensor anyButtonPressed]
				width: 2
				halftone: Form gray].
	^frame!

lastFullFrame
	"Answer the last open frame of the receiver."

	^ lastFrame!

moveTo: aPoint
	"Move the view to aPoint.  Turn off lastFrame cache.
	Typically used when view is off-screen to get back on."

	self erase.
	self align: self viewport topLeft with: aPoint.
	self display.
	lastFrame _ nil!

resize
	"Determine the rectangular area for the receiver, adjusted to the minimum
	and maximum sizes."

	| aRectangle |
	aRectangle _ self getFrame.
	aRectangle _ aRectangle origin extent:
					((aRectangle extent max: minimumSize) min: self maximumSize).
	self window: self window viewport: aRectangle.!

resizeMinimumCenteredAt: aPoint 
	"Determine the rectangular area for the receiver, adjusted so that it is centered
	a position, aPoint."

	| aRectangle |
	aRectangle _ 0 @ 0 extent: self minimumSize.
	aRectangle _ aRectangle align: aRectangle center with: aPoint.
	self window: self window viewport: aRectangle!

restoreFullView
	"The receiver was collapsed;  open it again to original size or user's selection."

	| oldFrame | 
	self erase.
	oldFrame _ self displayBox.
	self expand.
	lastFrame == nil
		ifTrue: [self resize]
		ifFalse: [Display zoom: oldFrame to: lastFrame.
				self window: self window viewport: self viewport].
	self displayEmphasized.
	lastFrame _ oldFrame! !

!StandardSystemView methodsFor: 'controller access'!

defaultControllerClass
	^StandardSystemController! !

!StandardSystemView methodsFor: 'displaying'!

displayEmphasized
	"Display the receiver with the label highlighted to indicate
	that it is active."

	self display.
	self emphasize.!

displayLabel
	"Display the label of the receiver at the upper left corner of the viewing area."

	| clippingBox labelDisplayBox |
	clippingBox _ self clippingBox.
	labelDisplayBox _ self labelDisplayBox.
	self isCollapsed ifTrue: [^self].
	(labelDisplayBox intersect: clippingBox) displayOn: Display.
	labelText isNil
		ifFalse:
			[isLabelComplemented _ false.
			labelText asForm
				displayOn: Display
				at: (labelDisplayBox center -
						(labelText boundingBox center -
							labelText boundingBox topLeft))
				clippingBox: clippingBox]!

displayRegion
	"Answer the rectangular area of the display in which the receiver 
	can be displayed."

	^self labelDisplayBox merge: self displayBox!

displaySafe: aBlock
	"Put the display of the receiver at the top of all
	views and evaluate the argument aBlock."

	ScheduledControllers displaySafe: aBlock forController: self controller!

displayView
	"Paint an image of the receiver on the display screen."

	| clippingBox labelDisplayBox |
	clippingBox _ self clippingBox.
	labelDisplayBox _ self labelDisplayBox.
	self isCollapsed ifTrue: [^self].
	(labelDisplayBox intersect: clippingBox) displayOn: Display.
	labelText isNil
		ifFalse:
			[isLabelComplemented _ false.
			labelText asForm
				displayOn: Display
				at: (labelDisplayBox center -
						(labelText boundingBox center -
							labelText boundingBox topLeft))
				clippingBox: clippingBox]!

refreshDisplay
	"Redisplay the receiver."

	self cacheRefresh
		ifTrue: [controller refreshDisplay]
		ifFalse: [self displayEmphasized]! !

!StandardSystemView methodsFor: 'deEmphasizing'!

deEmphasizeView
	self isCollapsed ifFalse: [self deEmphasizeLabel]!

emphasizeView
	self isCollapsed ifFalse: [self emphasizeLabel]! !

!StandardSystemView methodsFor: 'clipping box access'!

clippingBox
	"Answer the rectangular area in which the receiver can show its label."

	^self isTopView
		ifTrue: [self labelDisplayBox]
		ifFalse: [super insetDisplayBox]! !

!StandardSystemView methodsFor: 'bordering'!

borderWidth
	self isCollapsed
		ifTrue: [^0]
		ifFalse: [^super borderWidth]!

insideColor
	self isCollapsed
		ifTrue: [^nil]
		ifFalse: [^super insideColor]! !

!StandardSystemView methodsFor: 'icon access'!

icon
	"Answer the model, icon, of the collapsed view of the receiver."

	^iconView model!

icon: anIcon 
	"Set the icon for this view to be anIcon and display."

	self icon: anIcon display: true!

icon: anIcon display: displaying
	"Set the icon for this view to be anIcon and display if displaying is true."
	| shouldEmphasize icon |
	icon _ anIcon.
	icon isNil ifTrue: [icon _ Icon constantNamed: #default ifAbsent: [nil]].
	icon isNil ifTrue: [icon _ self iconFromLabel].
	iconView isNil
		ifTrue: 
			[iconView _ IconView new model: icon.
			iconView text: self iconText]
		ifFalse: 
			[iconView model: icon.
			iconView newIcon].
	self isCollapsed
		ifTrue: 
			[shouldEmphasize _ isLabelComplemented.
			"Need to update my display location info to reflect the fact that   
			 my shape (which is currently that of my icon) has changed."
			displaying ifTrue: [ self erase ].
			insetDisplayBox _ iconView insetDisplayBox copy.
			window _ iconView window.
			viewport _ iconView viewport.
			displaying ifTrue: [ self display.
				shouldEmphasize ifTrue: [self emphasize]]]!

iconFromLabel
	"Answer an icon that looks like the receiver's title tab."

	| iconForm box |
	iconForm _ Form extent: labelFrame corner + (0 @ 2).
	box _ iconForm computeBoundingBox.
	iconForm black.
	iconForm reverse: (box insetBy: 2).
	labelText asParagraph
		displayOn: iconForm
		at: 4 @ 2
		clippingBox: box.
	^Icon new form: iconForm textRect: nil!

iconText
	"Answer the text that shows in the receiver's label."

	^iconText isNil
		ifTrue: [self label asText]
		ifFalse: [iconText]!

iconText: string
	"Set the text that should show as the label when the receiver is collapsed."

	iconText _ string.
	iconView text: self iconText.
	self isCollapsed
		ifTrue:
			[self display]!

iconView
	"Answer the collapsed view of the receiver."

	^iconView!

image
	"Answer the icon form from the iconView."

	^iconView image!

lastIconFrame
	"Answer the last frame area of the collapsed view of the receiver."

	^ lastFrame! !

!StandardSystemView methodsFor: 'bit caching'!

cacheRefresh
	"Answer a Boolean depending on whether to redisplay with cached bits."

	^cacheRefresh!

cacheRefresh: aBoolean
	"Set as to whether to redisplay with cached bits."

	cacheRefresh _ aBoolean!

labelBits
	"Answer the labelBits or nil if collapsed."

	^self isCollapsed
		ifTrue: [nil]
		ifFalse: [Form fromDisplay: self labelDisplayBox]!

viewBits
	"Answer the viewBits or the icon if collapsed."

	^self isCollapsed
		ifTrue: [self image]
		ifFalse: [Form fromDisplay: self displayBox]! !

!StandardSystemView methodsFor: 'private: private'!

reverseLabel
	"Reverse the label."

	labelText isNil ifFalse: [Display reverse: self labelDisplayBox inside]! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

StandardSystemView class
	instanceVariableNames: ''!


!StandardSystemView class methodsFor: 'class initialization'!

initialize

	FillInHoles _ false.! !

!StandardSystemView class methodsFor: 'instance creation'!

model: aModel label: labelText minimumSize: minimumSize 
	"Answer a new instance of the receiver that is a view on the model 
	aModel, with label text labelText and the minimum size of the 
	rectangular area set to minimumSize."

	| view |
	view _ self new.
	view model: aModel.
	view label: labelText.
	view minimumSize: minimumSize.
	view borderWidth: 1.
	^view! !

!StandardSystemView class methodsFor: 'class var messages'!

fillHoles
	"Answer whether holes in the screen created by manipulating views 
	should be filled automatically."

	^FillInHoles!

fillInHoles
	"Set the Boolean flag indicating that holes in the display created by 
	manipulating a standard system view should be filled automatically."

	FillInHoles _ true!

leaveHoles
	"Set the Boolean flag indicating that holes in the display created by 
	manipulating a standard system view should not be filled automatically."

	FillInHoles _ false! !

StandardSystemView initialize!
