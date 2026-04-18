'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:48:47 pm'!

Form subclass: #DisplayScreen
	instanceVariableNames: ''
	classVariableNames: 'SavedExtent '
	poolDictionaries: ''
	category: 'Graphics-Display Objects'!
DisplayScreen comment:
'There is only one instance of of the class DisplayScreen, Display.  It is a global used to handle general client requests to deal with the whole display screen.  The instance name provides a way to distinguish this special instance from all other Forms.

Class Variables:
	SavedExtent	<Point>'!


!DisplayScreen methodsFor: 'initialize-release'!

postSnapshot
	"Initialize the screen after completing a snapshot."

	self class displayExtent: SavedExtent!

preSnapshot
	"Create a blank screen that will be shown while a system snapshot is made."

	SavedExtent _ self extent.
	self class displaySize: 384@256.
	self gray.! !

!DisplayScreen methodsFor: 'alerting'!

flash: aRectangle 
	"Complement twice the area of the screen defined by the argument, aRectangle."

	2 timesRepeat:
		[self fill: aRectangle
			rule: Form reverse
			mask: Form black.
		(Delay forMilliseconds: 60) wait]!

ringBell
	"Give the user an audible signal."
	"Display ringBell"

	<primitive: 705>
	^self flash: self boundingBox! !

!DisplayScreen methodsFor: 'displaying'!

beDisplay
	"Tell the interpreter to use the receiver as the current display image.  Fail if the 
	form is too wide to fit on the physical display.  Essential.  See Object 
	documentation whatIsAPrimitive."

	<primitive: 102>
	self primitiveFailed! !

!DisplayScreen methodsFor: 'zooming'!

slink: startRect to: stopRect
	"Display an evolving rectangle dynamically."

	"Display slink: (100@100 extent: 300@100) to: (600@600 extent: 10@10)."

	^self slink: startRect to: stopRect speed: 4000!

slink: startRect to: stopRect duration: milliseconds
	"Display an evolving rectangle dynamically.  Show each intermediate rectangle such that the 
	entire animation takes the desired amount of time."

	"Display slink: (100@100 extent: 300@100) to: (600@600 extent: 10@10) duration: 2000.
	Display slink: (600@600 extent: 10@10) to: (100@100 extent: 300@100) duration: 200."

	| originDelta cornerDelta pixels | 
	originDelta _ stopRect origin - startRect origin.
	cornerDelta _ stopRect corner - startRect corner.
		"maximum number of positions for the fastest edge"
	pixels _ (originDelta x abs max: originDelta y abs)
				max: (cornerDelta x abs max: cornerDelta y abs).
	^self slink: startRect to: stopRect speed: pixels*1000//milliseconds!

slink: startRect to: stopRect speed: pixelsPerSecond
	"Display an evolving rectangle dynamically.  Show each intermediate 
	rectangle such that the fastest edge moves at a constant desired 
	speed.  In practice, it may be necessary to skip some rectangles in 
	order to keep up.  When finished. slink the rectangles back in."

	"Display slink: (100@100 extent: 300@100) to: (600@600 extent: 10@10) speed: 500."

	| originDelta cornerDelta nSteps period currentOrigin currentCorner step nextTime overtime samples stepRate rects | 
	originDelta _ stopRect origin - startRect origin.
	cornerDelta _ stopRect corner - startRect corner.
	stepRate _ pixelsPerSecond//1000 max: 1.			"minimum pixels/sample"
	period _ stepRate*1000//pixelsPerSecond max: 1.	"msec per sample"
		"maximum number of positions for the fastest edge"
	nSteps _ ((originDelta x abs max: originDelta y abs)
				max: (cornerDelta x abs max: cornerDelta y abs)) // stepRate.
	nSteps _ nSteps max: 1.
		"position increment for each corner"
	originDelta _ originDelta / nSteps asFloat.
	cornerDelta _ cornerDelta / nSteps asFloat.
	currentOrigin _ startRect origin.
	currentCorner _ startRect corner.
	rects _ OrderedCollection new.
	step _ 0.
	nextTime _ Time millisecondClockValue.
		[[(overtime _ Time millisecondClockValue - nextTime) < 0]
			whileTrue: [(Delay untilMilliseconds: nextTime) wait].
		samples _ (overtime // period) + 1.
		currentOrigin _ currentOrigin + (originDelta * samples).
		currentCorner _ currentCorner + (cornerDelta * samples).
		nextTime _ nextTime + (period * samples).
		(step _ step + samples) <= nSteps]
			whileTrue:
				[rects add: (currentOrigin corner: currentCorner).
				Display border:  (currentOrigin corner: currentCorner) width: 2 rule: Form reverse mask: Form gray].

	"now reel those rectangles back in"
	rects do: [:r | Display border:  r width: 2 rule: Form reverse mask: Form gray]!

zoom: startRect to: stopRect
	"Display an evolving rectangle dynamically."

	"Display zoom: (100@100 extent: 300@100) to: (600@600 extent: 10@10)."

	^self zoom: startRect to: stopRect speed: 2000!

zoom: startRect to: stopRect duration: milliseconds 
	"Display an evolving rectangle dynamically.  Show each intermediate 
	rectangle such that the entire animation takes the desired amount of 
	time. "

	"Display zoom: (100@100 extent: 300@100) to: (600@600 extent: 10@10) duration: 2000. 
	Display zoom: (600@600 extent: 10@10) to: (100@100 extent: 300@100) duration: 200."

	| originDelta cornerDelta pixels |
	originDelta _ stopRect origin - startRect origin.
	cornerDelta _ stopRect corner - startRect corner.
	"maximum number of positions for the fastest edge"
	pixels _ (originDelta x abs max: originDelta y abs)
				max: (cornerDelta x abs max: cornerDelta y abs).
	^self
		zoom: startRect
		to: stopRect
		speed: pixels * 1000 // milliseconds!

zoom: startRect to: stopRect speed: pixelsPerSecond
	"Display an evolving rectangle dynamically.  Show each intermediate 
	rectangle such that the fastest edge moves at a constant desired 
	speed.  In practice, it may be necessary to skip some rectangles in 
	order to keep up."

	"Display zoom: (100@100 extent: 300@100) to: (600@600 extent:10@10) speed: 500."

	| originDelta cornerDelta nSteps period currentOrigin currentCorner step nextTime overtime samples stepRate | 
	originDelta _ stopRect origin - startRect origin.
	cornerDelta _ stopRect corner - startRect corner.
	stepRate _ pixelsPerSecond//1000 max: 1.			"minimum pixels/sample"
	period _ stepRate*1000//pixelsPerSecond max: 1.	"msec per sample"
		"maximum number of positions for the fastest edge"
	nSteps _ ((originDelta x abs max: originDelta y abs)
				max: (cornerDelta x abs max: cornerDelta y abs)) // stepRate.
	nSteps _ nSteps max: 1.
		"position increment for each corner"
	originDelta _ originDelta / nSteps asFloat.
	cornerDelta _ cornerDelta / nSteps asFloat.
	currentOrigin _ startRect origin.
	currentCorner _ startRect corner.
	step _ 0.
	nextTime _ Time millisecondClockValue.
	self outline: [currentOrigin corner: currentCorner]
		while: [[(overtime _ Time millisecondClockValue - nextTime) < 0] whileTrue:
					[(Delay untilMilliseconds: nextTime) wait].
				samples _ (overtime // period) + 1.
				currentOrigin _ currentOrigin + (originDelta * samples).
				currentCorner _ currentCorner + (cornerDelta * samples).
				nextTime _ nextTime + (period * samples).
				(step _ step + samples) <= nSteps]
		width: 2
		halftone: Form gray! !

!DisplayScreen methodsFor: 'outlining'!

outline: rectBlock do: effectBlock while: durationBlock width: borderWidth halftone: halftone
	"Display an evolving rectangle dynamically.
	rectBlock supplies a rectangle, durationBlock supplies true, then false to terminate.
	effectBlock is executed at each iteration." 

	| oldRect edges rect | 
	oldRect _ rectBlock value rounded.
	edges _ oldRect areasOutside: (oldRect insetBy: borderWidth).
	edges do: [:edge | self fill: edge rule: Form reverse mask: halftone].
	[durationBlock value] whileTrue:
		[rect _ rectBlock value rounded.
		rect = oldRect
			ifFalse:
				[edges do: [:edge | self fill: edge rule: Form reverse mask: halftone].
				effectBlock value.
				edges _ rect areasOutside: (rect insetBy: borderWidth).
				edges do: [:edge | self fill: edge rule: Form reverse mask: halftone].
				oldRect _ rect]].
	edges do: [:edge | self fill: edge rule: Form reverse mask: halftone].
	^ oldRect!

outline: rectBlock while: durationBlock width: borderWidth halftone: halftone
	"Display an evolving rectangle dynamically.
	rectBlock supplies a rectangle, durationBlock supplies true, then false to 
terminate." 

	^self outline: rectBlock do: [] while: durationBlock width: borderWidth halftone: halftone! !

!DisplayScreen methodsFor: 'private: private'!

bitsClass
	^DisplayBitmap! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

DisplayScreen class
	instanceVariableNames: ''!


!DisplayScreen class methodsFor: 'current display'!

currentDisplay: form 
	"Make the argument, form, be the form representing the current display
	screen.  Provide an error notification if form is not an instance of the receiver."

	form class == self
		ifTrue: 
			["We know the bits are a DisplayBitmap."
			Display become: form.
			Display beDisplay]
		ifFalse: [self error: 'form should be DisplayForm']!

displayExtent: extent 
	"Make the width and height of the current display screen form be extent, and refresh the (new) display."

	self displaySize: extent.
	"now grow to new size"
	ScheduledControllers redraw!

displayHeight: height 
	"Make the height of the current display screen form be the argument, height."

	^self displayExtent: self boundingBox width @ height!

displaySize: extent 
	"Make the width and height of the current display screen form be extent."

	| w |
	Display lightGray.
	w _ extent x.
	"shrink to 16 to release old bitmap"
	DisplayScreen currentDisplay: 
		(DisplayScreen extent: w @ 16).
	DisplayScreen currentDisplay: 
		(DisplayScreen extent: w @ extent y).! !

!DisplayScreen class methodsFor: 'display box access'!

boundingBox
	"Answer the bounding box for the form representing the current display screen."

	^Display boundingBox! !