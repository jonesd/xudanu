'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:49:43 pm'!

CodeController subclass: #OnlyWhenSelectedCodeController
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Interface-Text'!
OnlyWhenSelectedCodeController comment:
'An OnlyWhenSelectedCodeController is a code controller that will not take control unless its model has some selection.'!


!OnlyWhenSelectedCodeController methodsFor: 'control defaults'!

isControlWanted
	view isSelected
		ifFalse: 
			[sensor yellowButtonPressed ifTrue: [view flash].
			self deselect.
			^false].
	^self viewHasCursor! !