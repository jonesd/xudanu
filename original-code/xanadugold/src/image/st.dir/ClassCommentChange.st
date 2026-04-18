'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:51:53 pm'!

ClassOtherChange subclass: #ClassCommentChange
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'System-Changes'!
ClassCommentChange comment:
'Class ClassCommentChange represents a change to some part of a class comment.'!


!ClassCommentChange methodsFor: 'accessing'!

text
	"Answer the text displayed by the receiver."

	^file == nil
		ifTrue: [className, ' comment:
', (Smalltalk at: className) comment printString]
		ifFalse: [super text]! !

!ClassCommentChange methodsFor: 'checking'!

checkWith: aChecker
	aChecker changesAt: className, '<', type, '>' add: self! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

ClassCommentChange class
	instanceVariableNames: ''!


!ClassCommentChange class methodsFor: 'instance creation'!

new
	^super new type: #comment! !