'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:48:37 pm'!

ArrayedCollection variableSubclass: #WeakArray
	instanceVariableNames: 'dependents {UNKNOWN}'
	classVariableNames: '
		FinalizationProcess {UNKNOWN} 
		FinalizationSemaphore {UNKNOWN} 
		QueueOverflowSignal {UNKNOWN} '
	poolDictionaries: ''
	category: 'Collections-Arrayed'!



!WeakArray methodsFor: 'accessing'!

indexOf: oldValue replaceWith: newValue startingAt: startIndex stoppingAt: 
stopIndex 
	"Searches the specified portion of the receiver for the first reference 
	to oldValue, replacing that reference with newValue, and answers
	the 1-based index at which the oldValue was found. Zero is returned if
	the oldValue cannot be found. The search is restricted to and inclusive
	of the specified start and stop indices. The primitive fails if the start and
	stop indices are not SmallIntegers or if either is out of range."

	<primitive: 422>
	self primitiveFailed! !

!WeakArray methodsFor: 'dependents access'!

addDependent: anObject
	"Add anObject as one of the receiver's dependents."

	dependents _ dependents asDependentsWith: anObject.
	^anObject!

dependents
	"Answer a Collection of the objects that are dependent on the receiver; that 
is, the objects that should be notified if the receiver changes."

	^dependents asDependentsAsCollection!

removeDependent: anObject
	"Remove the argument, anObject, as one of the receiver's dependents."

	dependents _ dependents asDependentsWithout: anObject.
	^anObject! !

!WeakArray methodsFor: 'adding'!

grow
	"The receiver becomes larger."
	"This is not a copy of the receiver, so all shared references survive."

	| newWeakArray |
	newWeakArray _ self class new: self size + self growSize.
	newWeakArray
		replaceFrom: 1
		to: self size
		with: self.
	newWeakArray myDependents: dependents.
	self become: newWeakArray.
	newWeakArray breakDependents!

growToAtLeast: anInteger 
	"The receiver becomes at least as large as anInteger."
	"This is not a copy of the receiver, so all shared references survive."

	| newWeakArray |
	anInteger <= self size
		ifTrue: [^self].
	newWeakArray _ self class new: anInteger + self growSize.
	newWeakArray
		replaceFrom: 1
		to: self size
		with: self.
	newWeakArray myDependents: dependents.
	self become: newWeakArray.
	newWeakArray breakDependents! !

!WeakArray methodsFor: 'copying'!

copy
	"Answer another instance just like the receiver. 
	Do not copy the dependents list."

	^super copy breakDependents! !

!WeakArray methodsFor: 'enumerating'!

forAllDeadIndicesDo: aBlock 
	"Evaluate aBlock with each of the receiver's dead indices as the argument."

	self forAllDeadIndicesDo: aBlock replacingCorpsesWith: 0!

forAllDeadIndicesDo: aBlock replacingCorpsesWith: newValue
	"Evaluate aBlock with each of the receiver's dead indices as the argument and 
replace the value at each dead index with newValue."

	| deadIndex |
	deadIndex _ self size.
	[deadIndex >= 1]
		whileTrue: 
			[deadIndex _ self
						indexOf: 0
						replaceWith: newValue
						startingAt: deadIndex
						stoppingAt: 1.
			deadIndex == 0
				ifFalse: 
					[aBlock value: deadIndex.
					deadIndex _ deadIndex - 1]]!

nilAllCorpsesAndDo: aBlock 
	"Evaluate aBlock with each of the receiver's dead indices as the argument and 
replace the values at each dead index with nil."

	self forAllDeadIndicesDo: aBlock replacingCorpsesWith: nil! !

!WeakArray methodsFor: 'printing'!

storeOn: aStream 
	"Append to the argument aStream a sequence of characters that is an
	expression whose evaluation creates an object similar to the receiver.
	For a WeakArray, the general format is
		((class-name new: size) 
			instVarAt: index put: variable;
			at: index put: element; at: nextIndex put: element; yourself)"

	aStream nextPutAll: '(('.
	aStream nextPutAll: self class name.
	aStream nextPutAll: ' new: '.
	aStream store: self size.
	aStream nextPut: $).
	1 to: self class instSize do:
		[:i |
		aStream nextPutAll: ' instVarAt: ';
			store: i;
			nextPutAll: ' put: ';
			store: (self instVarAt: i);
			nextPut: $;].
	(self storeElementsFrom: 1 to: self size on: aStream)
		ifFalse: [aStream nextPutAll: '; yourself'].
	aStream nextPut: $)! !

!WeakArray methodsFor: 'private: private'!

breakDependents
	"Deallocate the receiver's dependents."

	dependents _ nil!

myDependents
	"Answer the receivers dependents or nil."

	^dependents!

myDependents: anObject 
	"Set the receiver's dependents to anObject"

	dependents _ anObject!

species
	"Answer the kind of collection that should be used when the various 
enumeration messages are sent to a WeakArray."

	^Array! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

WeakArray class
	instanceVariableNames: ''!



!WeakArray class methodsFor: 'class initialization'!

initialize
	"Causes the WeakArray and finalization mechanism to be installed."
	"WeakArray initialize."

	QueueOverflowSignal _ (Object errorSignal newSignalMayProceed: false)
		notifierString: 'Finalization Queue Overflowed';
		nameClass: self message: #queueOverflowSignal.
	self installFinalizationMechanism! !

!WeakArray class methodsFor: 'finalization'!

fetchFromFinalizationQueue
	"Answers and removes the next object from the finalization queue. 
	Answers nil if the queue is empty and raises the 
	QueueOverflowSignal if the primitive fails, since
	the only circumstance under which the primitive
	can fail is if the queue has overflowed."

	<primitive: 301>
	^self queueOverflowSignal raise!

innerFinalizationLoop
	"Sends every WeakArray on the finalization queue a changed 
	message."

	self queueOverflowSignal
		handle: 
			[:ex | 
			WeakArray allInstancesDo: [:weakArray | weakArray changed: #ElementExpired].
			ex return]
		do: 
			[| griefStrickenWeakArray |
			[(griefStrickenWeakArray _ self fetchFromFinalizationQueue) == nil]
				whileFalse: [griefStrickenWeakArray changed: #ElementExpired]]!

installFinalizationMechanism
	"Creates a process to handle object finalization, causes that process 
	to wait on a semaphore, and then registers that sempahore with 
	the Virtual Machine so that it can be signalled whenever object 
	finalization is required."

	FinalizationProcess == nil ifFalse: [FinalizationProcess terminate].
	FinalizationSemaphore _ Semaphore new.
	FinalizationProcess _ [self outerFinalizationLoop] newProcess.
	FinalizationProcess priority: Processor highIOPriority.
	FinalizationProcess resume.
	self installFinalizationSemaphore: FinalizationSemaphore!

installFinalizationSemaphore: semaphore 
	"Causes the Virtual Machine to signal the semaphore if any weak 
	references should expire. The primitive fails if the argument is neither a 
	semaphore nor nil (passing in nil instead of a semaphore is one way 
	of suppressing the finalization signal). Returns the receiver if the
	primitive succeeds."
	"In addition, this primitive registers the receiver in the 
	well-known-oop registry's weakArrayClass slot. This is a temporary 
	way of dynamically registering the WeakArray class with the Virtual
	Machine. This particular side effect will be removed when WeakArrays are 
	incorporated into the standard system rather than simply supported 
	as a file in."

	<primitive: 300>
	self primitiveFailed!

outerFinalizationLoop
	"Forks a process that will sends every WeakArray on the finalization 
	queue a changed message."

	
	[FinalizationSemaphore wait.
	[self innerFinalizationLoop]
		forkAt: Processor lowIOPriority] repeat!

queueOverflowSignal
	"Answers a value indicating whether the Virtual Machine's 
	finalization queue has overflowed."

	^QueueOverflowSignal! !

!WeakArray class methodsFor: 'instance creation'!

new
	| result |
	result _ super new.
	WeakArray someInstance.
	^result!

new: count
	| result |
	result _ super new: count.
	WeakArray someInstance.
	^result! !

WeakArray initialize!
