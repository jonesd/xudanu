'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:48:36 pm'!

ArrayedCollection subclass: #IntegerArray
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Collections-Arrayed'!
IntegerArray comment:
'IntegerArray is an abstract superclass for specialized Arrays whose elements are restricted to small ranges of integers.  Concrete classes are ByteArray (element values between 0 and 255) and WordArray (element values between 0 and 65535).'!


!IntegerArray methodsFor: 'accessing'!

replaceFrom: start to: stop withString: aString startingAt: repStart 
	"This destructively replaces elements from start to stop in the receiver
	starting at index, repStart, in the string, aString.  Answer the
	receiver."
	| repOff |
	repOff _ repStart - start.
	start to: stop do:
		[:index |
		self at: index put: (aString at: repOff + index) asInteger]! !

!IntegerArray methodsFor: 'converting'!

asByteString
	"Answer an instance of ByteString which is = to self."

	^ByteString fromIntegerArray: self!

asString
	"Answer a String created from the elements of the receiver."

	^String fromIntegerArray: self!

asTwoByteString
	"Answer an instance of TwoByteString which is = to self."

	^TwoByteString fromIntegerArray: self! !

!IntegerArray methodsFor: 'bit counting'!

countBits
	"Answer the number of on bits (1's) in the receiver."

	| count |
	count _ 0.
	self do:
		[:element |
		| bits |
		bits _ element.
		[bits ~= 0] whileTrue:
			[count _ count + 1.
			bits _ bits bitAnd: bits - 1]].
	^count! !

!IntegerArray methodsFor: 'printing'!

printOn: aStream 
	| printSize |
	aStream nextPutAll: self class name.
	printSize _ self size.
	printSize > self maxPrintElements
		ifTrue:
			[aStream nextPutAll: ' of size ';
				print: self size.
			printSize _ self maxPrintElements].
	aStream nextPutAll: ' ('.
	1 to: printSize do:
		[:index |
		(self at: index) printOn: aStream.
		aStream space].
	printSize < self size ifTrue: [aStream nextPutAll: '...(more)...'].
	aStream nextPut: $)! !

!IntegerArray methodsFor: 'user interface'!

inspect
	"Create and schedule a SequenceableCollectionInspector in which the user 
	can examine the receiver's variables."

	InspectorView open: (SequenceableCollectionInspector inspect: self)! !

!IntegerArray methodsFor: 'private: private'!

defaultElement
	^0!

maxPrintElements
	"Answer the maximum number of elements to print
	before eliding the rest."

	^50! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

IntegerArray class
	instanceVariableNames: ''!


!IntegerArray class methodsFor: 'instance creation'!

fromString: aString
	"Answer a new instance of the receiver created from the elements of aString."

	^(self new: aString size)
		replaceFrom: 1 to: aString size withString: aString startingAt: 1! !