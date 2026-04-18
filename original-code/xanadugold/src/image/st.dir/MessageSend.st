'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:49:23 pm'!

Message subclass: #MessageSend
	instanceVariableNames: 'receiver isSuper baseClass '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Kernel-Methods'!
MessageSend comment:
'A MessageSend represents a specific invocation of a Message.  It is essentially a message send represented as an object, and supports protocol for evaluating that send.

Instance Variables:
	receiver	<Object> the receiver of the message
	isSuper		<Boolean> whether this was a ''super'' message send
	baseClass	<Behavior> the class above which a super search should begin--this should be either the receiver''s class or one of its superclasses'!


!MessageSend methodsFor: 'accessing'!

receiver
	"Answer the receiver of the message send."

	^receiver!

receiver: anObject
	"Set the receiver of the message send."

	receiver := anObject! !

!MessageSend methodsFor: 'evaluating'!

{String} evalString
	| numArgs {Integer} writeStream {WriteStream} keywords {Array of: String} |
	numArgs _ self selector numArgs.
	writeStream _ WriteStream on: (String new: 16).
	writeStream print: self receiver; nextPut: $ .
	numArgs = 0
		ifTrue: [writeStream nextPutAll: selector]
		ifFalse: [keywords _ self selector keywords.
			1 to: numArgs do: 
				[:i {Integer} | 
				writeStream nextPutAll: (keywords at: i);
					 nextPut: $ ;
					 print: (self arguments at: i);
					 nextPut: $ ]].
	^writeStream contents!

value
	"Evaluate the message send."

	isSuper
		ifTrue:	[^self error: 'I can''t do that yet']
		ifFalse:	[^receiver perform: selector withArguments: args]! !

!MessageSend methodsFor: 'printing'!

printOn: aStream 
	"Append to the argument aStream a sequence of characters that identifies the receiver.
	The general format is
		a Message with receiver: receiver, selector: selector and arguments: arguments"

	aStream nextPutAll: 'MessageSend['; print: receiver.
	args isEmpty
		ifFalse: [selector keywords with: args do: [ :key :arg |
			aStream space; nextPutAll: key; space; print: arg]]
		ifTrue: [aStream space; nextPutAll: selector].
	aStream nextPut: $].
	aStream nextPutAll: 'a MessageSend with receiver: '.
	receiver printOn: aStream.
	aStream nextPutAll: ', selector: '.
	selector printOn: aStream.
	aStream nextPutAll: ' and arguments: '.
	args printOn: aStream.
	^aStream! !

!MessageSend methodsFor: 'private: private'!

setReceiver: anObject selector: aSymbol arguments: anArray

	receiver := anObject.
	selector := aSymbol.
	args := anArray.
	isSuper := false!

storeForExecutionOn: aStream
	"Add a description of the receiver to the argument aStream."
	aStream nextPut: receiver.
	aStream nextPut: selector.
	aStream nextPut: args size.
	1 to: args size do:
		[ :i | aStream nextPut: (args at: i)].! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

MessageSend class
	instanceVariableNames: ''!


!MessageSend class methodsFor: 'instance creation'!

receiver: anObject selector: aSymbol

	^self new setReceiver: anObject selector: aSymbol arguments: (Array new: 0)!

receiver: anObject selector: aSymbol argument: anArg

	^self new setReceiver: anObject selector: aSymbol arguments: (Array with: anArg)!

receiver: anObject selector: aSymbol arguments: anArray

	^self new setReceiver: anObject selector: aSymbol arguments: anArray! !