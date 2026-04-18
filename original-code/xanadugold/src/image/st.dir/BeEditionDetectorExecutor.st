'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:08:33 pm'!

XnExecutor subclass: #BeEditionDetectorExecutor
	instanceVariableNames: 'myEdition {BeEdition}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-brange3'!
BeEditionDetectorExecutor comment:
'This class notifies its edition when its last detector has gone.'!

(BeEditionDetectorExecutor getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!BeEditionDetectorExecutor methodsFor: 'protected: create'!

create: edition {BeEdition}
	super create.
	myEdition := edition.! !

!BeEditionDetectorExecutor methodsFor: 'execute'!

{void} execute: arg {Int32}
	arg == Int32Zero ifTrue: [
		myEdition removeLastDetector].! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

BeEditionDetectorExecutor class
	instanceVariableNames: ''!

(BeEditionDetectorExecutor getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!BeEditionDetectorExecutor class methodsFor: 'creation'!

{XnExecutor} make: edition {BeEdition}
	^ self create: edition! !