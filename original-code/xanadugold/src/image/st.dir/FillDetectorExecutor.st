'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:08:34 pm'!

XnExecutor subclass: #FillDetectorExecutor
	instanceVariableNames: 'myPlaceHolder {BePlaceHolder}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-brange1'!
FillDetectorExecutor comment:
'This class notifies its place holder when its last fill detector has gone away.'!

(FillDetectorExecutor getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!FillDetectorExecutor methodsFor: 'protected: create'!

create: placeHolder {BePlaceHolder}
	super create.
	myPlaceHolder := placeHolder.! !

!FillDetectorExecutor methodsFor: 'execute'!

{void} execute: arg {Int32}
	arg == Int32Zero ifTrue: [
		myPlaceHolder removeLastDetector]! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

FillDetectorExecutor class
	instanceVariableNames: ''!

(FillDetectorExecutor getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!FillDetectorExecutor class methodsFor: 'create'!

{XnExecutor} make: placeHolder {BePlaceHolder}
	^ self create: placeHolder! !