'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:56:49 pm'!

Heaper subclass: #EventGenerator
	instanceVariableNames: 'eventTime lastClick clickNum clickTime point stateBits debug '
	classVariableNames: 'AnyButtonMask ClickInterval ControlMask DownEvents LockMask MenuMask MetaBitState MetaMask SelectMask ShiftMask UpEvents WindowMask '
	poolDictionaries: ''
	category: 'FM-Events'!


!EventGenerator methodsFor: 'create/delete'!

create
	stateBits _ clickNum _ 0.
	eventTime _ Time millisecondClockValue copy.
	point _ 0@0.
	debug _ false.
	clickTime _ eventTime - (ClickInterval + 1).! !

!EventGenerator methodsFor: 'controlling'!

{long}newMetaState
	| mb{long} |
	mb _ 0.
	Sensor selectDownFn ifTrue: [mb _ mb + SelectMask].
	Sensor menuDownFn ifTrue: [mb _ mb + MenuMask].
	Sensor windowDownFn ifTrue: [mb _ mb + WindowMask].
	Sensor shiftDownFn ifTrue: [mb _ mb + ShiftMask].
	Sensor controlDownFn ifTrue: [mb _ mb + ControlMask].
	Sensor lockDownFn ifTrue: [mb _ mb + LockMask].
	Sensor metaDownFn ifTrue: [mb _ mb + MetaMask].
	^mb!

{PointPos}newMousePoint
	^Sensor mousePoint - Sensor currentCursor offset!

queueEvents: eventQueue with: dsp {Dsp}
	"Since we aren't hooked into the primitive event semaphore, 
	fake observing state transitions. Note that all mouse motion 
	events come before button transitions.  This should really 
	return the first event after queuing subsequent events, 
	just for efficiency."

	| op os |
	op _ point.
	point _ dsp inverseOf: (PointPos make.Point: self newMousePoint).
	os _ stateBits.
	stateBits _ self newMetaState.
	eventTime _ Time millisecondClockValue.
	(point isEqual: op) ifFalse: 
		[eventQueue queue: (TraverseEvent make: eventTime with: point with: stateBits with: op)].
	Sensor keyboardPressed
		ifTrue: 
			[lastClick _ nil.
			eventQueue queue: 
					(KeyEvent make: eventTime with: point with: stateBits with: Sensor keyboard)].
	os ~~ stateBits
		ifTrue: 
			[| xor i |
			xor _ os bitXor: stateBits.
			i _ 1.
			[0 = xor]
				whileFalse: 
					[(xor bitAnd: 1) ~= 0 ifTrue: [0 = (os bitAnd: 1)
							ifTrue: 
								[| eventKey |
								eventKey _ DownEvents at: i.
								eventQueue queue: 
										(ButtonEvent make: eventTime with: point
											with: stateBits with: eventKey
											with: ((eventKey = lastClick and: [eventTime - clickTime < ClickInterval])
												ifTrue: [clickNum _ clickNum + 1]
												ifFalse: [clickNum _ 1])).
								clickTime _ eventTime]
							ifFalse: 
								[eventQueue queue: 
										(ButtonEvent make: eventTime with: point
											with: stateBits with: (UpEvents at: i) with: clickNum).
								lastClick _ DownEvents at: i.
								clickTime _ eventTime]].
					xor _ xor bitShift: -1.
					os _ os bitShift: -1.
					i _ i + 1]]!

queueEvents: controller with: warp on: eventQueue
	"Since we aren't hooked into the primitive event semaphore, 
	fake observing state transitions. Note that all mouse motion 
	events come before button transitions.  This should really 
	return the first event after queuing subsequent events, 
	just for efficiency."

	| op os |
	op _ point.
	point _ warp untransform.Point: (PointPos make.Point: self newMousePoint).
	os _ stateBits.
	stateBits _ self newMetaState.
	eventTime _ Time millisecondClockValue.
	(point isEqual: op) ifFalse: 
		[eventQueue queue: (TraverseEvent make: eventTime with: point with: stateBits with: op)
			for: controller].
	Sensor keyboardPressed
		ifTrue: 
			[lastClick _ nil.
			eventQueue queue: 
					(KeyEvent make: eventTime with: point with: stateBits with: Sensor keyboard)
				for: controller].
	os ~~ stateBits
		ifTrue: 
			[| xor i |
			xor _ os bitXor: stateBits.
			i _ 1.
			[0 = xor]
				whileFalse: 
					[(xor bitAnd: 1) ~= 0 ifTrue: [0 = (os bitAnd: 1)
							ifTrue: 
								[| eventKey |
								eventKey _ DownEvents at: i.
								eventQueue queue: 
										(ButtonEvent make: eventTime with: point
											with: stateBits with: eventKey
											with: ((eventKey = lastClick and: [eventTime - clickTime < ClickInterval])
												ifTrue: [clickNum _ clickNum + 1]
												ifFalse: [clickNum _ 1]))
									for: controller.
								clickTime _ eventTime]
							ifFalse: 
								[eventQueue queue: 
										(ButtonEvent make: eventTime with: point
											with: stateBits with: (UpEvents at: i) with: clickNum)
									for: controller.
								lastClick _ DownEvents at: i.
								clickTime _ eventTime]].
					xor _ xor bitShift: -1.
					os _ os bitShift: -1.
					i _ i + 1]]! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

EventGenerator class
	instanceVariableNames: ''!


!EventGenerator class methodsFor: 'smalltalk: initialization'!

linkTimeNonInherited
	"EventGenerator linkTimeNonInherited"

	DownEvents _ #(windowDown menuDown selectDown) , (Array new: 5) , #(shiftDown controlDown lockDown metaDown).
	UpEvents _ #(windowUp menuUp selectUp) , (Array new: 5) , #(shiftUp controlUp lockUp metaUp).
	AnyButtonMask _ 7.
	WindowMask _ 1.
	MenuMask _ 2.
	SelectMask _ 4.
	ShiftMask _ 256.
	ControlMask _ 512.
	LockMask _ 1024.
	MetaMask _ 2048.
	MetaBitState _ ShiftMask + ControlMask + LockMask + MetaMask.
	ClickInterval _ 1000 "milliseconds between click and double-click."! !

!EventGenerator class methodsFor: 'smalltalk: macros: constants'!

ControlMask
	^ControlMask!

LockMask
	^LockMask!

MetaMask
	^MetaMask!

ShiftMask
	^ShiftMask! !

!EventGenerator class methodsFor: 'pseudo constructors'!

make
	^ self create! !