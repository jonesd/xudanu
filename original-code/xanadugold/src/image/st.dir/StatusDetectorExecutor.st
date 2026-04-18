'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:07:07 pm'!

XnExecutor subclass: #StatusDetectorExecutor
	instanceVariableNames: 'myWork {FeWork}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-nkernel'!
StatusDetectorExecutor comment:
'This class informs its work when its last status detector has gone away.'!

(StatusDetectorExecutor getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!StatusDetectorExecutor methodsFor: 'executing'!

{void} execute: arg {Int32}
	arg == Int32Zero ifTrue: [
		myWork removeLastStatusDetector]! !

!StatusDetectorExecutor methodsFor: 'protected: create'!

create: work {FeWork}
	super create.
	myWork := work.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

StatusDetectorExecutor class
	instanceVariableNames: ''!

(StatusDetectorExecutor getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!StatusDetectorExecutor class methodsFor: 'create'!

{XnExecutor} make: work {FeWork}
	^ self create: work! !