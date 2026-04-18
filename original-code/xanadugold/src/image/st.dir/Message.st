'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:49:23 pm'!

Object subclass: #Message
	instanceVariableNames: 'selector args '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Kernel-Methods'!
Message comment:
'Class Message represents a selector and its argument values.  

Generally, the system does not use instances of Message.  However, when a message is not understood by its receiver, the interpreter will make up a Message (to capture the information involved in an actual message transmission) and send it as an argument with the message doesNotUnderstand:.

Instance Variables:
	selector	<Symbol>
	args		<Array>'!


!Message methodsFor: 'accessing'!

arguments
	"Answer the arguments of the receiver."
	^args!

selector
	"Answer the selector of the receiver."
	^selector! !

!Message methodsFor: 'printing'!

printOn: aStream 
	"Append to the argument aStream a sequence of characters that identifies the receiver.
	The general format is
		a Message with selector: selector and arguments: arguments"
	aStream nextPutAll: 'Message['.
	args isEmpty
		ifFalse: [selector keywords with: args do: [ :key :arg |
			aStream space; nextPutAll: key; space; print: arg]]
		ifTrue: [aStream nextPutAll: selector].
	aStream nextPut: $].
	"aStream nextPutAll: 'a Message with selector: '.
	selector printOn: aStream.
	aStream nextPutAll: ' and arguments: '.
	args printOn: aStream."
	^aStream!

storeOn: aStream  
	"Append to the argument aStream a sequence of characters that is 
	an expression whose evaluation creates a message similar 
	to the receiver. The general format for messages is
		( Message selector: selector arguments: args)"

	aStream nextPut: $(.
	aStream nextPutAll: 'Message selector: '.
	selector storeOn: aStream.
	aStream nextPutAll: ' arguments: '.
	args storeOn: aStream.
	aStream nextPut: $)! !

!Message methodsFor: 'private: private'!

setSelector: aSymbol arguments: anArray 
	selector _ aSymbol.
	args _ anArray! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

Message class
	instanceVariableNames: ''!


!Message class methodsFor: 'instance creation'!

selector: aSymbol
	"Answer an instance of me with unary selector, aSymbol."

	^self new setSelector: aSymbol arguments: (Array new: 0)!

selector: aSymbol argument: anObject 
	"Answer an instance of me whose selector is aSymbol and single argument
	is anObject."

	^self new setSelector: aSymbol arguments: (Array with: anObject)!

selector: aSymbol arguments: anArray 
	"Answer an instance of me with selector, aSymbol, and arguments,
	anArray."

	^self new setSelector: aSymbol arguments: anArray! !