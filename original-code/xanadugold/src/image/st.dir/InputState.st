'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:51:44 pm'!

Object subclass: #InputState
	instanceVariableNames: 'x y bitState lshiftState rshiftState ctrlState lockState metaState keyboardQueue metaKeyState otherMetaKey1State otherMetaKey2State otherMetaKey3State '
	classVariableNames: 'BitMax BitMin CtrlKey EmergencyInterruptKey IdleSemaphore InputProcess InputSemaphore InterruptKey LetterCKey LockKey LshiftKey MetaKey OtherMeta1 OtherMeta2 OtherMeta3 RshiftKey '
	poolDictionaries: ''
	category: 'System-Support'!
InputState comment:
'Class InputState represents the state of the user input devices.

Instance Variables:
	x  <Integer> mouse X location 
	y  <Integer> mouse Y location 
	bitState  <Integer> mouse button and keyset state 
	lshiftState  <1 or 0> state of left shift key 
	rshiftState  <1 or 0> state of right shift key 
	ctrlState  <2 or 0> state of ctrl key 
	lockState  <4 or 0> state of shift-lock key 
	metaState  <Integer> combined state of the meta keys 
	keyboardQueue  <SharedQueue> of keyboard characters 
	metaKeyState  <Integer>
	otherMetaKey1State  <Integer>
	otherMetaKey2State  <Integer>
	otherMetaKey3State  <Integer>
		
Class Variables:
	InputSemaphore	<Semaphore>
		Signalled by the VM when input is available.
	IdleSemaphore	<Semaphore>
		Signalled by InputState>>run when Smalltalk goes "active" (e.g. mouse cursor enters display area.)
	
	These are all integers defined in the class message initialize. that represent particular key presses.
		BitMax
		BitMin
		CtrlKey
		EmergencyInterruptKey
		InputProcess
		InterruptKey
		LetterCKey
		LockKey
		LshiftKey
		MetaKey
		OtherMeta1
		OtherMeta2
		OtherMeta3
		RshiftKey
'!


!InputState methodsFor: 'initialize-release'!

install
	"Initialize and connect the receiver to the hardware.  Terminate the old input 
	process if any."

	InputProcess == nil ifFalse: [InputProcess terminate].
	self initState.
	InputSemaphore _ Semaphore new.
	IdleSemaphore _ Semaphore new.
	InputProcess _ [IdleSemaphore signal. self run] newProcess.
	InputProcess priority: Processor lowIOPriority.
	InputProcess resume.
	self primInputSemaphore: InputSemaphore! !

!InputState methodsFor: 'keyboard'!

ctrlDown
	"Answer whether the control key is down."

	^ctrlState ~= 0!

keyboardNext
	"Remove and answer the next key in the keyboard buffer."

	^[keyboardQueue next] valueUninterruptably!

keyboardPeek
	"Answer the next key in the keyboard buffer but do not remove it."

	^[keyboardQueue peek] valueUninterruptably!

leftShiftDown
	"Answer whether the left shift key is down."

	^lshiftState ~= 0!

{BooleanVar} lockDown
	^lockState ~~ 0!

{BooleanVar}metaDown
	^metaState ~~ 0! !

!InputState methodsFor: 'mouse'!

mouseButtons
	"Answer the status of the mouse buttons--an Integer between 0 and 7."

	^bitState bitAnd: 7!

mousePoint
	"Answer the coordinates of the mouse location."
	IdleSemaphore wait.
	IdleSemaphore signal.
	^x@y! !

!InputState methodsFor: 'cursor'!

cursorPoint: aPoint 
	"Set the current cursor position to be aPoint."

	self primCursorLocPut: aPoint.
	x _ aPoint x.
	y _ aPoint y! !

!InputState methodsFor: 'private: private'!

initState

	x _ y _ 0.
	keyboardQueue _ SharedQueue new: 50.
	ctrlState _ lshiftState _ rshiftState _ lockState _ metaState _ metaKeyState _ 0.
	otherMetaKey1State _ otherMetaKey2State _ otherMetaKey3State _ 0.
	bitState _ 0!

keyAt: keyNumber put: value 
	| index |
	index _ keyNumber bitAnd: 255.
	(index < BitMin or: ["Get rid of meta bits"
		index > OtherMeta3])
		ifTrue: ["Not a potential special character"
			value = 1 ifTrue: ["only look at down strokes"
				index = InterruptKey
					ifTrue: [(lshiftState ~= 0 or: [(keyNumber bitAnd: 256)
								~= 0])
							ifTrue: [self forkEmergencyEvaluatorAt: Processor userInterruptPriority]
							ifFalse: [[ControlManager interruptLockedSignal
										handle: [:ex | ex return]
										do: [ScheduledControllers interruptName: 'User Interrupt']] fork]]
					ifFalse: [index = EmergencyInterruptKey
							ifTrue: [self forkEmergencyEvaluatorAt: Processor userInterruptPriority]
							ifFalse: [^keyboardQueue nextPut: (KeyboardEvent
												code: index
												meta: (metaState bitOr: (keyNumber bitShift: -8)))]]]]
		ifFalse: 
			[self setStateFor: index with: value.
			metaState _ (((((ctrlState bitOr: (lshiftState bitOr: rshiftState))
						bitOr: lockState)
						bitOr: metaKeyState)
						bitOr: otherMetaKey1State)
						bitOr: otherMetaKey2State)
						bitOr: otherMetaKey3State]!

metaInput: word 
	| args numA opcode |
	numA _ word bitAnd: 15.
	opcode _ (word bitShift: -4) bitAnd: 15.
	numA > 0 ifTrue: 
			[args _ Array new: numA.
			1 to: numA do: 
				[:i | 
				InputSemaphore wait.
				args at: i put: self primInputWord]].
"resize"	opcode = 9 ifTrue: [ControlManager lastDisplayExtent: (args at: 1) @ (args at: 2)]
"child"	ifFalse: [opcode = 16rE
					ifTrue: [| pcls |
							pcls _ ExternalProcess defaultClass.
							pcls notNil ifTrue: [pcls reapSome]]
"exit"	ifFalse: [opcode = 8 ifTrue: [IdleSemaphore initSignals]
"enter"	ifFalse: [opcode = 7 ifTrue: [IdleSemaphore signal]
"close"	ifFalse: [opcode = 16rA ifTrue: []
"open"	ifFalse: [opcode = 16rB ifTrue: []
"repaint"ifFalse: [opcode = 16rC ifTrue: []
"quit"	ifFalse: [opcode = 16rD ifTrue: []
		ifFalse: ["Unknown opcode"]]]]]]]]!

primCursorLocPut: aPoint 
	"Set the cursor to the point on the screen specified by the 
	argument aPoint.  Fail if the argument is not a Point.  Essential. See 
	Object documentation whatIsAPrimitive."

	<primitive: 91>
	^self primCursorLocPutAgain: aPoint rounded!

primCursorLocPutAgain: aPoint 
	"Set the cursor to the point on the screen specified by the 
	argument aPoint.  Fail if the argument is not a Point.  Essential. See 
	Object documentation whatIsAPrimitive."

	<primitive: 91>
	^self primitiveFailed!

primInputSemaphore: aSemaphore 
	"Install the argument (a Semaphore) as the object to be signalled whenever 
	an input event occurs. The semaphore will be signaled once for every 
	word placed in the input buffer by an I/O device. Fail if the argument is 
	neither a Semaphore nor nil. Essential. See Object whatIsAPrimitive."

	<primitive: 93>
	^self primitiveFailed!

primInputWord
	"Return the next word from the input buffer and remove the word from the 
	buffer. This message should be sent just after the input semaphore 
	finished a wait (was sent a signal by an I/O device). Fail of the input 
	buffer is empty. Essential. See Object documentation whatIsAPrimitive."

	<primitive: 95>
	^self primitiveFailed!

primMousePt
	"Poll the mouse to find out its position.  Return a Point.  Fail if event-driven 
	tracking is used instead of polling.  Optional.  See Object documentation 
	whatIsAPrimitive. "

	<primitive: 90>
	^x @ y!

primSampleInterval: anInteger 
	"Set the minimum time span between event driven mouse position 
	samples.  The argument is a number of milliseconds.  Fail if the argument 
	is not a SmallInteger.  Essential.  See Object documentation 
	whatIsAPrimitive. "

	<primitive: 94>
	^self primitiveFailed!

run
	"This is the loop that actually processes input events."

	| word type param |
	[true]
		whileTrue: 
			[InputSemaphore wait.
			"Test for mouse X/Y events here to avoid an activation."
			word _ self primInputWord.
			type _ word bitShift: -12.
			param _ word bitAnd: 4095.
"Mouse X"	type = 1 ifTrue: [x _ param]
"Mouse Y"	ifFalse: [type = 2 ifTrue: [y _ param]
"Key down"	ifFalse: [type = 3 ifTrue: [self keyAt: param put: 1]
"Key up"	ifFalse: [type = 4 ifTrue: [self keyAt: param put: 0]
"MetaInput"ifFalse: [type = 7 ifTrue: [self metaInput: word]
"Delta time"ifFalse: [type = 0 ifTrue: []
"Reset time"ifFalse: [type = 5 ifTrue: [self primInputWord; primInputWord]
			ifFalse: [self error: 'Bad event type']]]]]]]]!

setStateFor: index with: state
	"Set the state keys"

	| mask | 
	index = LshiftKey ifTrue: [^lshiftState _ state].
	index = RshiftKey ifTrue: [^rshiftState _ state].
	index = CtrlKey ifTrue: [^ctrlState _ state bitShift: 1].
	index = LockKey ifTrue: [^lockState _ state bitShift: 2].
	index = MetaKey ifTrue: [^metaKeyState _ state bitShift: 3].
	index = OtherMeta1 ifTrue: [^otherMetaKey1State _ state bitShift: 4].
	index = OtherMeta2 ifTrue: [^otherMetaKey2State _ state bitShift: 5].
	index = OtherMeta3 ifTrue: [^otherMetaKey3State _ state bitShift: 6].
	(index >= BitMin and: [index <= BitMax])
		ifTrue: [mask _ 1 bitShift: index - BitMin.
				state = 1
					ifTrue: [bitState _ bitState bitOr: mask]
					ifFalse: [bitState _ bitState bitAnd: -1 - mask]]! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

InputState class
	instanceVariableNames: ''!


!InputState class methodsFor: 'class initialization'!

initialize
	"Define parameters"

	"InputState initialize"

	InterruptKey	 _ 25.			"25 for Ctrl-Y, 3 for Ctrl-C, 206 for Ctrl-."
	EmergencyInterruptKey _ 249.	"249 for Ctrl-Shift-Y, 227 for Ctrl-Shift-C, 222 for Ctrl-Shift-."
	BitMin _ 128.  "Min mouse/keyset bit code"
	BitMax _ 135.  "Max mouse/keyset bit code"
	LshiftKey _ 136.
	RshiftKey _ 137.
	CtrlKey _ 138.
	LockKey _ 139.
	MetaKey _ 140.
	OtherMeta1 _ 141.
	OtherMeta2 _ 142.
	OtherMeta3 _ 143! !

!InputState class methodsFor: 'key settings'!

emergencyInterruptKey
	"Answer the code for the key that causes an emergency interrupt."

	^EmergencyInterruptKey!

emergencyInterruptKey: anInteger
	"Set the code for the key that causes an emergency interrupt."

	EmergencyInterruptKey _ anInteger!

interruptKey
	"Answer the code for the key that causes an interrupt."

	^InterruptKey!

interruptKey: anInteger
	"Set the code for the key that causes an interrupt."

	InterruptKey _ anInteger! !

!InputState class methodsFor: 'private: private-initialization'!

idleReset
	"Only used in juntas"
	IdleSemaphore _ Semaphore new.
	IdleSemaphore signal! !

InputState initialize!
