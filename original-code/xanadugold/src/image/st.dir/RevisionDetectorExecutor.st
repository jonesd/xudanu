'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:07:07 pm'!

XnExecutor subclass: #RevisionDetectorExecutor
	instanceVariableNames: 'myWork {FeWork}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-nkernel'!
RevisionDetectorExecutor comment:
'This class informs its work when its last detector has gone away.'!

(RevisionDetectorExecutor getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!RevisionDetectorExecutor methodsFor: 'protected: create'!

create: work {FeWork}
	super create.
	myWork := work! !

!RevisionDetectorExecutor methodsFor: 'execute'!

{void} execute: arg {Int32}
	arg == Int32Zero ifTrue: [
		myWork removeLastRevisionDetector]! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

RevisionDetectorExecutor class
	instanceVariableNames: ''!

(RevisionDetectorExecutor getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!RevisionDetectorExecutor class methodsFor: 'create'!

{XnExecutor} make: work {FeWork}
	^ self create: work! !