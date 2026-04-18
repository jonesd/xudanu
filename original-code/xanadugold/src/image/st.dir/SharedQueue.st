'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:49:25 pm'!

Object subclass: #SharedQueue
	instanceVariableNames: 'contents accessProtect readSynch '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Kernel-Processes'!
SharedQueue2 comment:
'Class SharedQueue provides synchronized communication of arbitrary objects between Processes.  An object is sent by sending an instance the message nextPut: and received by sending it the message next.  If no object has been sent when a next message is sent, the Process requesting the object will be suspended until one is sent.

Instance Variables:
	contents	<OrderedCollection>
	accessProtect	<Semaphore>	
	readSynch 		<Semaphore>	
'!


!SharedQueue methodsFor: 'initialize-release'!

release
	contents _ nil! !

!SharedQueue methodsFor: 'accessing'!

next
	"Answer the object that was sent through the receiver first and has not yet  
	been received by anyone.  If no object has been sent, suspend the  
	requesting process until one is."

	readSynch wait.
	^accessProtect
		critical:
			[contents isEmpty
				ifTrue: 
					[self error: 'Error in SharedQueue synchronization'.
					 nil]
				ifFalse: 
					[contents removeFirst]]!

nextPut: value 
	"Send value through the receiver.  If a Process has been suspended waiting to 
	receive a value through the receiver, allow it to proceed."

	accessProtect critical: [contents addLast: value].
	readSynch signal.
	^value!

peek
	"Answer the object that was sent through the receiver first and has not yet 
	been received by anyone but do not remove it from the receiver. If no object has 
	been sent, answer nil."

	^accessProtect
		critical:
			[contents isEmpty
				ifTrue: [nil]
				ifFalse: [contents first]]!

size
	"Answer the number of objects that have been sent through the
	receiver and not yet received by anyone."

	^accessProtect critical: [contents size]! !

!SharedQueue methodsFor: 'testing'!

isEmpty
	"Answer whether any objects have been sent through the receiver
	and not yet received by anyone."

	^accessProtect critical: [contents isEmpty]! !

!SharedQueue methodsFor: 'private: private'!

init: size 
	contents _ OrderedCollection new: size.
	accessProtect _ Semaphore forMutualExclusion.
	readSynch _ Semaphore new! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

SharedQueue class
	instanceVariableNames: ''!


!SharedQueue class methodsFor: 'instance creation'!

new
	"Answer a new instance of SharedQueue that has 10 elements."

	^self new: 10!

new: anInteger
	"Answer a new instance of SharedQueue,
	allocating space for the given number of elements."

	^super new init: anInteger! !