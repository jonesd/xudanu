'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:52:41 pm'!

IdentityDictionary variableSubclass: #HandleRegistry
	instanceVariableNames: 'lock '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'OS-Support'!
HandleRegistry comment:
'A HandleRegistry is an IdentityDictionary whose values all respond to a #key message.  The elements of a HandleRegistry are "registered" using their response to the #key message as the dictionary key, and the element as the value.  Access functions are all implemented as critical regions (so multiple
processes may operate on instances at the same time).

Instance Variables: *indexed*
	lock		<Semaphore> Mutex semaphore protecting accesses

'!


!HandleRegistry methodsFor: 'initialize-release'!

initialize
	"Initialize the registry by creating the mutex semaphore."

	lock _ Semaphore forMutualExclusion!

release
	"Broadcast a release message to all registrants."

	self values do: [:value | value release]! !

!HandleRegistry methodsFor: 'accessing'!

at: key
	"Answer the value at key.  If key is not found, return nil."

	| p |
	lock critical: [p _ super at: key ifAbsent: [nil]].
	^p!

register: handleThingy
	"Register the handleThingy, that is, put the handleThingy
	as a value in the dictionary, where the key is the handleThingy's
	reponse to #key.  Don't register if the response is nil."

	handleThingy key == nil ifTrue: [^self].
	lock critical: [super at: handleThingy key put: handleThingy]!

unregister: handleThingy
	"Unregister the handleThingy.  If it is not present, do nothing."

	handleThingy key == nil ifTrue: [^self].
	lock critical: [super removeKey: handleThingy key ifAbsent: []]!

values
	"Answer a Bag containing the receiver's values."

	^lock critical: [super values]! !

!HandleRegistry methodsFor: 'printing'!

printOn: aStream  
	"Append to the argument aStream a sequence of characters that identifies the receiver."

	| tooMany |
	tooMany _ aStream position + self maxPrint.
	aStream nextPutAll: 'a '.
	aStream nextPutAll: self class name.
	aStream nextPutAll: ' protected by '.
	lock printOn: aStream.
	aStream nextPutAll: ' with ('.
	self associationsDo: 
		[:element | 
		aStream position > tooMany ifTrue: [aStream nextPutAll: '...etc...)'. ^self].
		element printOn: aStream.
		aStream space].
	aStream nextPut: $)! !

!HandleRegistry methodsFor: 'copying'!

copyEmpty: aSize
	"Answer a copy of the receiver that contains no elements.

	This method should be redefined in subclasses that add
	instance variables, so that the state of those variables
	is preserved"

	| copy |
	copy _ super copyEmpty: aSize.
	copy lock: lock.
	^copy! !

!HandleRegistry methodsFor: 'private: private-accessing'!

lock: sem

	lock _ sem! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

HandleRegistry class
	instanceVariableNames: ''!


!HandleRegistry class methodsFor: 'instance creation'!

new: size 
	"Create a new registry."

	^(super new: size) initialize! !