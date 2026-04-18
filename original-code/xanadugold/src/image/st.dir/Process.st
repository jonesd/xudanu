'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:49:24 pm'!

Link subclass: #Process
	instanceVariableNames: 'suspendedContext priority myList interruptProtect '
	classVariableNames: 'TerminateSignal '
	poolDictionaries: ''
	category: 'Kernel-Processes'!
Process comment:
'Class Process represents an independent path of control in the system.  This path of control may be stopped (by sending the instance the message suspend) in such a way that it can later be restarted (by sending the instance the message resume).  When any one of several paths of control can be advanced, the single instance of ProcessorScheduler named Processor determines which one will actually be advanced partly using the instance''s priority.

Instance Variables: 
		suspendedContext	<Context> activeContext at time of process suspension
		priority				<Integer> partial indication of relative scheduling
		myList				<LinkedList> on which the receiver suspended
		interruptProtect	<Semaphore> mutex to guard against
							#interruptWith: race conditions.

Class Variables:
	TerminateSignal	<Signal> A Process was created without a handler for the terminateSignal

'!


!Process methodsFor: 'changing process state'!

interruptWith: aBlock
	"Force the receiver to interrupt whatever it is
	doing and to evaluate aBlock. The result of the
	evaluation is discarded. When the evaluation is
	completed, the receiver goes back to whatever it
	was doing before (including, if relevant, waiting
	on a semaphore.).  Only one interrupter allowed
	at a time."

	Processor activeProcess == self
		ifTrue: [interruptProtect critical: aBlock]
		ifFalse:
			["We have to do this carefully,
			in case the receiver was waiting on a
			Semaphore.  Also, we can't just return
			from the interrupt in the normal way,
			because an interrupted process isn't
			expecting a value to get returned."
			"We guarantee that interruptProtect
			will only be signaled once in the following
			code"
			interruptProtect wait.
			[| savedList interruptContext savedContext |
			savedList _ myList.
			myList notNil ifTrue: [self suspend].
			savedContext _ suspendedContext.
			interruptContext _
				[aBlock valueOnUnwindDo:
					["If the receiver successfully resumed execution,
					but the block's execution did not terminate
					normally, signal the interruptProtect"
					interruptProtect signal].
				"The following method signals interruptProtect,
				but can only be invoked if aBlock ran to completion,
				which would mean that none of the unwind blocks 
				in this method had run"
				self setContext: savedContext andList: savedList
				] newContext.
			interruptContext sender: savedContext.
			suspendedContext _ interruptContext.
			self resume] valueOnUnwindDo:
				["If this unwind block runs, the receiver was
				not successfully resumed, and so interruptProtect
				could not be signaled from within interruptContext"
				interruptProtect signal]]!

resume
	"Allow the process that the receiver represents to continue. Put the receiver
	in line to become the activeProcess. Fail if the receiver is already waiting
	in a queue (in a Semaphore or ProcessScheduler). Essential. See Object
	documentation whatIsAPrimitive."

	<primitive: 87>
	self primitiveFailed!

suspend
	"Stop the process that the receiver represents in such a way that it can be 
	restarted at a later time (by sending the receiver the message resume). If 
	the receiver represents the activeProcess, suspend it. Otherwise simply
	remove the receiver from the list of waiting processes, either in the
	scheduler or a semaphore. Essential. See Object documentation whatIsAPrimitive."

	<primitive: 88>
	myList == nil
		ifTrue: [self error: 'This process was not active']
		ifFalse: [self primitiveFailed]!

suspendUnconditionally
	"Stop the process that the receiver represents in such a way that it can be 
	restarted at a later time (by sending the receiver the message resume). If 
	the receiver represents the activeProcess, suspend it. Otherwise simply
	remove the receiver from the list of waiting processes, either in the
	scheduler or a semaphore. Essential. See Object documentation whatIsAPrimitive."

	<primitive: 88>
	myList == nil  "OK if already suspended"
		ifFalse: [self primitiveFailed]!

terminate
	"Terminate the receiver process,
	by sending the Process terminateSignal."

	Processor activeProcess == self
		ifTrue: 
			[Signal noHandlerSignal
				handle:
					[:ex |
					"This is only invoked for old Processes
					that don't have a handler for the
					terminateSignal."
					ex parameter signal == Process terminateSignal
						ifFalse: [ex reject].
					"For such processes, just forget about unwinding."
					ex return]
				do: [Process terminateSignal raise].
			self terminateNoSignal]
		ifFalse: 
			[self interruptWith: [self terminate]]!

terminateNoSignal
	"Terminate the receiver process
	(and release all its contexts)
	directly, without using the
	Process terminateSignal or
	running unwind blocks."

	| context |
	Processor activeProcess == self
		ifTrue: 
			[thisContext sender == nil ifFalse: [thisContext sender terminateTo: nil].
			self suspend]
		ifFalse: 
			["remove me first, then destroy me"
			self suspendUnconditionally.
			context _ suspendedContext.
			suspendedContext _ nil.
			context == nil ifFalse: [context release]]! !

!Process methodsFor: 'changing suspended state'!

install: aContext 
	"Replace the suspendedContext with aContext."

	self == Processor activeProcess
		ifTrue: [^self error: 'The active process cannot install contexts'].
	suspendedContext _ aContext!

popTo: aContext 
	"Replace the suspendedContext with aContext, releasing all contexts 
	between the currently suspendedContext and it."

	self == Processor activeProcess
		ifTrue: [^self error: 'The active process cannot pop contexts'].
	suspendedContext terminateTo: aContext.
	suspendedContext sender: nil.
	suspendedContext _ aContext! !

!Process methodsFor: 'accessing'!

offList
	"Inform the receiver that it has been taken off a list that it was suspended
	on.  This is to break a backpointer."

	myList _ nil!

priority
	"Answer the priority of the receiver."
	^priority!

priority: anInteger 
	"Set the receiver's priority to anInteger."

	anInteger<=Processor highestPriority
		ifTrue: [priority _ anInteger]
		ifFalse: [self error: 'priority too high']!

suspendedContext
	"Answer the context the receiver has suspended."
	^suspendedContext!

suspendingList
	"Answer the list on which the receiver has been suspended."
	^myList! !

!Process methodsFor: 'printing'!

printOn: aStream 
	"Append to the argument aStream a sequence of characters that identifies the receiver."

	super printOn: aStream.
	aStream nextPutAll: ' in '.
	suspendedContext printOn: aStream! !

!Process methodsFor: 'private: private'!

setContext: savedContext andList: savedList
	"Carefully restore the state of an interrupted process.  Evaluate
	aBlock just before resuming the process"

	[| waitContext |
	(savedContext method == (Semaphore compiledMethodAt: #wait) and:
	 [savedContext receiver == savedList])
		ifTrue:
			["Go back to waiting on the Semaphore"
			waitContext _ [savedList wait] newContext.
			waitContext sender: savedContext sender.
			suspendedContext _ waitContext.
			self resume.
			interruptProtect signal]
		ifFalse:
			[suspendedContext _ savedContext.
			savedList notNil ifTrue: [self resume].
			interruptProtect signal].
	] forkAt: priority.
	"We continue to run"
	self suspend.
	self error: 'Should never get here!!'

	"| p |
	p _ [5 timesRepeat: [(Delay forSeconds: 1) wait. Transcript show: 'hi ']] newProcess.
	p resume.
	[(Delay forMilliseconds: 2500) wait.
	p interruptWith: [Transcript show: 'hello ']] fork"!

suspendedContext: aContext 
	suspendedContext _ aContext! !

!Process methodsFor: 'initialization'!

initialize

	interruptProtect _ Semaphore forMutualExclusion! !

!Process methodsFor: 'privileged evaluation'!

uninterruptablyDo: aBlock
	"Execute the block, without interrupts (from Process>>interruptWith:)
	with respect to the receiver (process), which may or may not be the
	currently active process. Note that this does not prevent preemption
	by higher priority processes. Use this facility VERY sparingly!!"

	^interruptProtect critical: aBlock! !

!Process methodsFor: 'copying'!

deepCopy
	"Answer a copy of the receiver with its own copy of each instance 
	variable. This doesn't make sense for Processes."

	^self deepCopyError! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

Process class
	instanceVariableNames: ''!


!Process class methodsFor: 'instance creation'!

forContext: aContext priority: anInteger 
	"Answer an instance of me that has suspended aContext at priority anInteger."

	| newProcess |
	newProcess _ self new.
	newProcess suspendedContext: aContext.
	newProcess priority: anInteger.
	^newProcess!

new
	"Make a new instance, initializing the interruptProtect semaphore."

	^super new initialize! !

!Process class methodsFor: 'Signal constants'!

terminateSignal
	"Answer the Signal that is sent
	to terminate a process."
	^TerminateSignal! !