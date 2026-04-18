'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:56:55 pm'!

Heaper subclass: #EventGenerator.U.XView
	instanceVariableNames: '
		window {Xv.U.opaque var}
		lastClick {IntegerVar}
		clickNum {IntegerVar}
		point {PointPos}
		stateBits {long}
		debug {BooleanVar}'
	classVariableNames: '
		AnyButtonMask {int smalltalk} 
		ClickInterval {int smalltalk} 
		ControlMask {int smalltalk} 
		DownEvents {int smalltalk} 
		LockMask {int smalltalk} 
		MenuMask {int smalltalk} 
		MetaBitState {int smalltalk} 
		MetaMask {int smalltalk} 
		SelectMask {int smalltalk} 
		ShiftMask {int smalltalk} 
		UpEvents {int smalltalk} 
		WindowMask {int smalltalk} '
	poolDictionaries: ''
	category: 'FM-Events-SunView'!

(EventGenerator.U.XView getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!EventGenerator.U.XView methodsFor: 'create/delete'!

create
	super create.
	stateBits _ UInt32Zero.
	clickNum _ IntegerVar0.
	window _NULL.
	point _ PointPos make.
	debug _ false! !

!EventGenerator.U.XView methodsFor: 'controlling'!

{void} queueEvents: controller {FMController} with: warp {Warp} on: eventQueue {EventQueue.U.XView} 
	"XView version differs from smalltalk version in that it is completely interrupt driven."

	self unimplemented! !

!EventGenerator.U.XView methodsFor: 'printing'!

{void}printOn: aStream {ostream reference}
	aStream << self getCategory name << '('
		<<	'window = '  << window
		<<		'lastClick = ' <<  window
		<<		'clickNum =  '  << window
		<<		'point = '  << window
		<<		'stateBits = ' << window
		<<		'debug = ' << window  << ')'! !