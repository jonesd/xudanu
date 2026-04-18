'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:51:55 pm'!

Change subclass: #OtherChange
	instanceVariableNames: 'text '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'System-Changes'!
OtherChange comment:
'Class OtherChange represents a non-classifiable change, i.e., a doIt.  It caches text to reduce disk accesses.

Instance Variable:
	text	<String>'!


!OtherChange methodsFor: 'accessing'!

name
	^self defaultName: '  doIt '!

parameters
	^self text!

text
	"Answer the text displayed by the receiver."

	text == nil ifTrue: [text _ super text].
	^text!

text: aString
	text _ aString.
	file _ nil! !

!OtherChange methodsFor: 'checking'!

checkWith: aChecker
	"Discard comments and 'From ...' messages if from the current system"
	| myText aStream first |
	myText _ self text.
	myText isEmpty ifTrue: [^self].
	aStream _ ReadStream on: myText.
	first _ aStream next.
	first = $" ifTrue:
		[aStream skipThrough: $"; skipSeparators.
		aStream atEnd ifTrue: [^self]].
	first = $' ifTrue:
		[first _ 'From ', Smalltalk version, ' on '.
		myText size > first size ifTrue:
			[(aStream next: first size) = first ifTrue: [^self]]].
	aChecker addDoIt: self! !