'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:49:40 pm'!

ListController subclass: #LockedListController
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Interface-Lists'!
LockedListController comment:
'Class LockedListController represents a ListController that blocks new selections if the model is locked, i.e., has been changed in some way that still requires completion.'!


!LockedListController methodsFor: 'control defaults'!

controlActivity
	self normalResponseTest ifTrue: [^super controlActivity].
	self feedbackResponseTest ifTrue: [^view flash]! !

!LockedListController methodsFor: 'model access'!

feedbackResponseTest
	"Answer whether the receiver should respond to any user button requests."
	^sensor anyButtonPressed | self scrollBarContainsCursor!

normalResponseTest
	"Answer whether the receiver can proceed with selections--depends
	on whether the model is locked."
	^model isUnlocked! !