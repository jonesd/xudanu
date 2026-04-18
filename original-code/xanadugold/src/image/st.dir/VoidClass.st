'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:56:06 pm'!

Object subclass: #VoidClass
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'X++ Translator'!


!VoidClass methodsFor: 'primitive methods'!

== anObject 
	"Answer true if the receiver and the argument are the same object (have the same 
	object pointer) and false otherwise. Do not redefine the message == in any 
	other class!! Essential. No Lookup. See documentation in Object metaclass."

	<primitive: 110>
	self primitiveFailed!

class
	"Answer the object which is the receiver's class. Essential. See 
	documentation in Object metaclass."

	<primitive: 111>
	self primitiveFailed!

identityHash
	"Answer a SmallInteger whose value reflects the identity, not the contents,
	of the receiver.  Essential.  See documentation in Object metaclass."


	<primitive: 75>
	self primitiveFailed!

name
	^ 'VOID'!

printOn: aStream 
	"Append to the argument aStream a sequence of characters that identifies the receiver."


	aStream << 'VOID'!

printString
	"Answer a String whose characters are a description of the receiver."

	| aStream |
	aStream _ WriteStream on: (String new: 16).
	self printOn: aStream.
	^aStream contents!

~~ anObject 
	"Answer true if the receiver and the argument are not the same object 
	(have the same object pointer) and false otherwise."


	^(self == anObject) not! !

!VoidClass methodsFor: 'override messages'!

= other
	self error: 'Death To Carter!!'!

isEqual: other
	self error: 'Death To Carter!!'!

~= other
	self error: 'Death To Carter!!'! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

VoidClass class
	instanceVariableNames: ''!


!VoidClass class methodsFor: 'initialization'!

initialize
	"VoidClass initialize"

	Smalltalk at: #VOID put: self new! !

VoidClass initialize!
