'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:08:31 pm'!

XnExecutor subclass: #RevisionWatcherExecutor
	instanceVariableNames: 'myWork {BeWork}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-brange2'!
RevisionWatcherExecutor comment:
'This executor tells its BeWork when the last of its revision watchers have gone away.'!

(RevisionWatcherExecutor getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!RevisionWatcherExecutor methodsFor: 'protected: create'!

create: work {BeWork}
	super create.
	myWork := work! !

!RevisionWatcherExecutor methodsFor: 'execute'!

{void} execute: arg {Int32}
	arg == Int32Zero ifTrue: [
		myWork removeLastRevisionWatcher]! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

RevisionWatcherExecutor class
	instanceVariableNames: ''!

(RevisionWatcherExecutor getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!RevisionWatcherExecutor class methodsFor: 'create'!

{XnExecutor} make: work {BeWork}
	^ self create: work! !