'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:51:43 pm'!

Object subclass: #InputSensor
	instanceVariableNames: ''
	classVariableNames: 'CurrentCursor CurrentCursorGridding CurrentInputState '
	poolDictionaries: ''
	category: 'System-Support'!
InputSensor comment:
'Class InputSensor represents an interface to the user input devices.  There is at least one global instance of the class, whose name is Sensor.

Class Variables:
	CurrentCursor		<Cursor> reference to the cursor that is currently being displayed
	CurrentInputState	<InputState> for accessing the hardware'!


!InputSensor methodsFor: 'keyboard'!

ctrlDown
	"Answer whether the control key is down."

	^self primCtrlDown!

flushKeyboard
	"Remove all characters from the keyboard buffer."

	[self keyboardPressed]
		whileTrue: [self keyboard]!

keyboard
	"Answer the next character from the keyboard buffer as a fully decoded 
	(ASCII) character."

	^self primKbdNext keyCharacter!

keyboardEvent
	"Answer the next character from the keyboard buffer as a KeyboardEvent."

	^self primKbdNext!

keyboardPeek
	"Answer the next character in the keyboard buffer or false if it is empty.   
	self keyboardPressed must be true, else an error is reported."

	self keyboardPressed ifTrue: [^self primKbdPeek keyCharacter].
	self error: 'Cant peek when nothing there'!

keyboardPressed
	"Answer false if the keyboard buffer is empty, else true."

	"The keyboard queue only contains real keystrokes, so
	just test if it is non-empty."

	^self primKbdPeek notNil!

leftShiftDown
	"Answer whether the left shift key is down."

	^self primLeftShiftDown! !

!InputSensor methodsFor: 'mouse'!

anyButtonPressed
	"Answer whether a mouse button is being pressed."

	^self buttons > 0!

blueButtonPressed
	"Answer whether only the blue mouse button is being pressed."

	^ self buttons = 1!

mousePoint
	"Answer a Point indicating the coordinates of the current mouse location."

	^CurrentInputState mousePoint!

mousePointNext
	"Answer the next mouse point if red button or tablet is down; false otherwise."

	self redButtonPressed ifTrue: [^self mousePoint].
	^false!

noButtonPressed
	"Answer whether any mouse button is not being pressed."

	^self anyButtonPressed == false!

redButtonPressed
	"Answer whether only the red mouse button is being pressed."

	^self buttons = 4!

waitButton
	"Wait for the user to press any mouse button and then answer with the 
	current location of the cursor."

	[self anyButtonPressed] whileFalse.
	^self cursorPoint!

waitClickButton
	"Wait for the user to click (press and then release) any mouse button and then
	answer with the current location of the cursor."

	self waitButton.
	^self waitNoButton!

waitNoButton
	"Wait for the user to release any mouse button and then answer with the 
	current location of the cursor."

	[self anyButtonPressed] whileTrue.
	^self cursorPoint!

yellowButtonPressed
	"Answer whether only the yellow mouse button is being pressed."

	^ self buttons = 2! !

!InputSensor methodsFor: 'current cursor'!

currentCursor
	"Answer the instance of Cursor currently displayed."

	^CurrentCursor!

currentCursor: newCursor 
	"Set newCursor to be the displayed Cursor form."

	CurrentCursor _ newCursor.
	Cursor currentCursor: CurrentCursor!

cursorPoint
	"Answer a Point indicating the cursor location."

	^self mousePoint!

cursorPoint: aPoint 
	"Set aPoint to be the current cursor location."

	^self primCursorLocPut: aPoint!

maybeGriddedCursorPoint
	"Answer a Point indicating the cursor location.  If leftShiftDown, then answer gridded
	version of cursor position"

	self leftShiftDown
		ifTrue: [^self cursorPoint]
		ifFalse: 
			[CurrentCursorGridding = nil
				ifTrue: [CurrentCursorGridding _ 8@8].
			^self cursorPoint grid: CurrentCursorGridding]! !

!InputSensor methodsFor: 'private: private'!

buttons
	^self primMouseButtons!

primCtrlDown
	^CurrentInputState ctrlDown!

primCursorLocPut: pt 
	CurrentInputState cursorPoint: pt!

primKbdNext
	^CurrentInputState keyboardNext!

primKbdPeek
	^CurrentInputState keyboardPeek!

primLeftShiftDown
	^CurrentInputState leftShiftDown!

primMouseButtons
	^CurrentInputState mouseButtons!

primMousePt
	"Poll the mouse to find out its position. Return a Point. Fail if event-driven 
	tracking is used instead of polling. Optional. See Object documentation 
	whatIsAPrimitive. "

	<primitive: 90>
	^CurrentInputState mousePoint! !

!InputSensor methodsFor: 'FM control'!

{BooleanVar} controlDownFn
	^ self ctrlDown!

{BooleanVar} lockDownFn
	^ CurrentInputState lockDown!

menuDownFn
	^ self yellowButtonPressed!

{BooleanVar} metaDownFn
	^ CurrentInputState metaDown!

selectDownFn
	^ self redButtonPressed!

{BooleanVar} shiftDownFn
	^ self leftShiftDown!

windowDownFn
	^ self blueButtonPressed! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

InputSensor class
	instanceVariableNames: ''!


!InputSensor class methodsFor: 'class initialization'!

install
	"Create an instance of InputState for accessing the hardware, and 
	save it in the class variable CurrentInputState."

	CurrentInputState _ InputState new.
	CurrentInputState install! !

!InputSensor class methodsFor: 'constants'!

default
	"Answer the default system InputSensor, Sensor."

	^Sensor!

initSensor
	"Create the default system InputSensor, Sensor."

	Sensor _ InputSensor new! !

!InputSensor class methodsFor: 'gridding'!

{void} grid: aPoint {Point}
	"InputSensor grid: 8@8"
	CurrentCursorGridding _ aPoint! !