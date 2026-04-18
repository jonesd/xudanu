'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:56:54 pm'!

FMEvent subclass: #UserEvent
	instanceVariableNames: '
		pointInternal {PointPos}
		stateBits {UInt4}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'FM-Events'!

(UserEvent getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!UserEvent methodsFor: 'static testing'!

{BooleanVar} isControlDown
	"Return true if the Control key is currently down."

	^(stateBits bitAnd: EventGenerator ControlMask) ~~ UInt32Zero!

{BooleanVar}isLockDown
	"Return true if the Lock key is currently down."

	^(stateBits bitAnd: EventGenerator LockMask) ~~ UInt32Zero!

{BooleanVar}isMetaDown
	"Return true if the Meta key is currently down."

	^(stateBits bitAnd: EventGenerator MetaMask) ~~ UInt32Zero!

{BooleanVar}isShiftDown
	"Return true if the Shift key is currently down."

	^(stateBits bitAnd: EventGenerator ShiftMask) ~~ UInt32Zero!

{BooleanVar} visible: region {XnRegion} in: aView {Viewer} 
	"True if this event occurs in the visible portion of 
	view. This doesn't currently handle occlusion."

	self thingToDo. "Make this handle occlusion"
	^(region asSimpleRegion quickCast: PointRegion)
		hasMember: (aView globalDsp inverseOf: pointInternal)! !

!UserEvent methodsFor: 'accessing'!

{PointPos} pointIn: aView {Viewer}
	^(aView globalDsp inverseOf: pointInternal) quickCast: PointPos! !

!UserEvent methodsFor: 'protected: protected'!

{PointPos} globalPoint
	^pointInternal! !

!UserEvent methodsFor: 'create'!

create: time {TimeVar} with: point{PointPos} with: metaBits{UInt32}
	super create: time.
	pointInternal _ point.
	stateBits _ metaBits! !

!UserEvent methodsFor: 'printing'!

{void}printOn: aStream{ostream reference}
	super printOn: aStream.
	aStream << ' pos: '<< pointInternal! !