'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:48:42 pm'!

BitBlt subclass: #Pen
	instanceVariableNames: 'frame location direction penDown '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Graphics-Primitives'!
Pen comment:
'Instances of class Pen can scribble on the screen, drawing and printing at any angle.

Instance Variables: 
	frame			<Rectangle> in which the pen can draw
	location		<Point>		current location of the pen
	direction		<Integer>	angle in which the pen is heading, where
								270 is the top of the display, 0 is to the right
	penDown		<Boolean>	true if the pen leaves marks when it moves, false otherwise
'!


!Pen methodsFor: 'initialize-release'!

defaultNib: widthInteger 
	"Nib is the tip of a pen.  This is an easy way to set up a default pen
	in the shape of a dot whose diameter is widthInteger."

	self sourceForm: (Form dotOfSize: widthInteger)! !

!Pen methodsFor: 'accessing'!

direction
	"Answer the receiver's current direction.  270 is towards the top of the screen."

	^direction!

frame
	"Answer the rectangle in which the receiver can draw."

	^frame!

frame: aRectangle 
	"Set the rectangle in which the receiver can draw to be aRectangle."

	frame _ aRectangle.
	self clipRect: aRectangle!

location
	"Answer the Point at which the receiver is currently located."

	^location!

sourceForm: aForm
	"Set the form of the marks left by the receiver to be aForm."

	sourceForm _ aForm.
	width _ aForm width.
	height _ aForm height.!

width: anInteger 
	"Provide an error notification that setting the receiver's width with 
	this message is not allowed."

	self error: 'Pen widths cannot be reset this way;  use defaultNib: or specify a new source form using sourceForm: '! !

!Pen methodsFor: 'coloring'!

black
	"Set the receiver's mask to the black form."

	self mask: Form black!

fillIn: aBlock
	"Draw an outline expressed by the algorithm in the argument aBlock."

	^ aBlock value!

white
	"Set the receiver's mask to the white form."

	self mask: Form white! !

!Pen methodsFor: 'moving'!

down
	"Set the state of the receiver's pen to down (drawing)."

	penDown _ true!

go: distance 
	"Move the receiver in its current direction a number of bits equal to   
	the argument, distance.  If the pen is down, a line will be drawn   
	using the receiver's form source as the shape of the drawing brush."

	| dir |
	direction = 0 ifTrue: [^self goto: location + (distance @ 0)].
	direction = 90 ifTrue: [^self goto: location + (0 @ distance)].
	direction = 180 ifTrue: [^self goto: location - (distance @ 0)].
	direction = 270 ifTrue: [^self goto: location - (0 @ distance)].
	dir _ direction degreesToRadians.
	dir _ dir cos @ dir sin.
	self goto: dir * distance + location!

goto: aPoint 
	"Move the receiver to position aPoint.  If the pen is down, a line will be drawn
	from the current position to the new one using the receiver's form source as the
	shape of the drawing brush.  The receiver's set direction does not change."

	| old |
	old _ location.
	location _ aPoint.
	penDown ifTrue: [self drawFrom: old to: location]!

home
	"Place the receiver at the center of its frame."

	location _ frame center!

north
	"Set the receiver's direction to facing toward the top of the display 
	screen. "

	direction _ 270!

place: aPoint 
	"Set the receiver at position aPoint.  No lines are drawn."

	location _ aPoint!

turn: degrees 
	"Change the direction that the receiver faces by an amount equal to 
	the argument, degrees."

	direction _ direction + degrees \\ 360!

up
	"Set the state of the receiver's pen to up (not drawing)."

	penDown _ false! !

!Pen methodsFor: 'geometric designs'!

dragon: orderNumber 
	"Draws a dragon curve of order orderNumber in the center of the screen.  Writes 
	directly into the display bitmap."

	" Pen new dragon: 8."

	orderNumber = 0
		ifTrue: [self go: 10]
		ifFalse: [orderNumber > 0
				ifTrue: [self dragon: orderNumber - 1; turn: 90; dragon: 1 - orderNumber]
				ifFalse: [self dragon: -1 - orderNumber; turn: -90; dragon: 1 + orderNumber]]!

filberts: n side: s 
	"Two Hilbert curve fragments back to back form a Hilbert tile.  Draw four 
	interlocking tiles of order n directly on the display. "

	"Pen new filberts: 3 side: 10."

	| n2 |
	n2 _ 1 bitShift: n - 1.
	self up; go: 0 - n2 * s; down.
	1 to: 4 do: 
		[:i | 
		self
			fillIn: 
				[self hilbert: n side: s.
				self go: s.
				self hilbert: n side: s.
				self go: s].
		self black.
		self hilbert: n side: s.
		self go: s.
		self hilbert: n side: s.
		self go: s.
		self up.
		self go: n2 - 1 * s.
		self turn: -90.
		self go: n2 * s.
		self turn: 180.
		self down]!

hilbert: n side: s 
	"Draws an nth level Hilbert curve directly into the display bitmap.  A 
	Hilbert curve is a space-filling curve. "

	"(Pen new) hilbert: 3 side: 8. 

	(Pen new sourceForm: Cursor wait) combinationRule: Form under; 
	hilbert: 3 side: 25."

	| a m |
	n = 0 ifTrue: [^self turn: 180].
	n > 0
		ifTrue: 
			[a _ 90.
			m _ n - 1]
		ifFalse: 
			[a _ -90.
			m _ n + 1].
	self turn: a.
	self hilbert: 0 - m side: s.
	self turn: a; go: s.
	self hilbert: m side: s.
	self turn: 0 - a; go: s; turn: 0 - a.
	self hilbert: m side: s.
	self go: s; turn: a.
	self hilbert: 0 - m side: s.
	self turn: a!

hilberts: n 
	"Demonstrates the space-filling nature of Hilbert curves by drawing n 
	levels of nested curves on the screen."
	
	"Display white.  Pen new hilberts: 4."

	| s |
	self up; go: 128; down.
	1 to: n do: 
		[:i | 
		s _ 256 bitShift: 0 - i.
		self defaultNib: n - i + 1.
		self up; go: 0 - s // 2; turn: -90; go: s // 2; turn: 90; down.
		self hilbert: i side: s.
		self go: s.
		self hilbert: i side: s.
		self go: s]!

mandala: npoints diameter: d 
	"On a circle of diameter d, place n points.  Draw all possible connecting 
	lines directly on the display." 
	
	"Pen new mandala: 30 diameter: 400"

	| l points |
	l _ (3.14 * d / npoints) rounded.
	self home; up; turn: -90; go: d // 2; turn: 90; go: 0 - l // 2.
	points _ Array new: npoints.
	1 to: npoints do: 
		[:i | 
		points at: i put: location rounded.
		self go: l; turn: 360 // npoints].
	self down.
	npoints // 2
		to: 1
		by: -1
		do: 
			[:i | 
			1 to: npoints do: 
				[:j | 
				self place: (points at: j).
				self goto: (points at: j + i - 1 \\ npoints + 1)]]!

spiral: n angle: a 
	"Draw a double squiral directly on the display."
	
	"Display white.  
	Pen new spiral: 200 angle: 89; home; spiral: 200 angle: -89."
	
	1 to: n do: 
		[:i | self go: i; turn: a]! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

Pen class
	instanceVariableNames: ''!


!Pen class methodsFor: 'instance creation'!

new
	"Answer a new Pen that can draw on the entire display screen, with 
	a 1X1 black pen, starting from the center of the screen and heading 
	towards the top."

	| quill |
	quill _ super new.
	quill destForm: Display.
	quill frame: Display boundingBox.
	quill sourceOrigin: 0 @ 0.
	quill mask: Form black.
	quill defaultNib: 1.
	quill combinationRule: Form under.
	quill down.
	quill home.
	quill north.
	^quill! !

!Pen class methodsFor: 'examples'!

penSampler
	"Draws a spiral in gray with a pen that is 4 pixels wide."
	
	"Pen penSampler"

	| bic |  
	bic _ Pen new. 
	bic mask: Form gray.
	bic defaultNib: 4.
	bic combinationRule: Form under.
	1 to: 50 do: [:i | bic go: i*4. bic turn: 89]! !