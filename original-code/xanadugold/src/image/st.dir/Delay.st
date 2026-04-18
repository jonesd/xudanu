'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:49:24 pm'!

Object subclass: #Delay
	instanceVariableNames: 'delayDuration resumptionTime delaySemaphore delayInProgress '
	classVariableNames: 'AccessProtect ActiveDelay SnapshotTime SuspendedDelays TimingSemaphore '
	poolDictionaries: ''
	category: 'Kernel-Processes'!
Delay comment:
'Class Delay represents a real time delay in the execution of a Process.  An instance of Delay will respond to the message #wait by suspending the active process for a certain amount of time.  The time for resumption of the active process is specified when the Delay is created.  
	 
The resumption time can be specified relative to the current time with the messages {Delay forMilliseconds: anInteger} and
{Delay forSeconds: anInteger}. Delays created in this way can be sent the message #wait again after they have finished a previous delay. 
	 
The resumption time can also be specified at an absolute time with respect to the system''s millisecond clock with the message {Delay untilMillisecond: anInteger}. Delays created in this way cannot be sent the message #wait repeatedly.

Instance Variables: 
	delayDuration		<Integer> number of milliseconds to delay process
	resumptionTime		<Integer> value of millisecond clock at which to resume
	delaySemaphore	<Semaphore> on which to delay process
	delayInProgress		<Boolean> true if delaying now

Class Variables:
	AccessProtect		<Semaphore>
	ActiveDelay		<Semaphore>
	SnapshotTime		<Array>
	SuspendedDelays	<SortedCollection> of Delays
	TimingSemaphore 	<Semaphore>
	'!


!Delay methodsFor: 'accessing'!

delaySemaphore
	"Answer the semaphore which will be signaled when the
	delay expires."

	^delaySemaphore!

resumptionTime
	"Answer the value of the system's millisecondClock at which the receiver's 
	suspended Process will resume."

	^resumptionTime! !

!Delay methodsFor: 'process delay'!

disable
	"Remove the receiver from the queue of delayed processes to be serviced."

	AccessProtect wait.
	delayInProgress ifTrue:
		[ActiveDelay == self
			ifTrue: [SuspendedDelays isEmpty
						ifTrue: [Processor signal: nil atTime: 0.
								ActiveDelay _ nil]
						ifFalse: [SuspendedDelays removeFirst activate]]
			ifFalse: [SuspendedDelays remove: self].
		delaySemaphore terminateProcess.
		delayInProgress _ false].
	AccessProtect signal!

startup
	"Signal the delay's semaphore in the amount of time specified when the 
	receiver was initialized."

	"(ActiveDelay == nil or: [ActiveDelay resumptionTime  > Time millisecondClockValue])
		ifFalse: [TimingSemaphore signal]."
	AccessProtect wait.
	self setResumption.
	ActiveDelay == nil
		ifTrue: [self activate]
		ifFalse: [resumptionTime < ActiveDelay resumptionTime
				ifTrue: 
					[SuspendedDelays add: ActiveDelay.
					self activate]
				ifFalse: 
					[SuspendedDelays add: self]].
	AccessProtect signal!

wait
	"Suspend the active process for an amount of time specified when the 
	receiver was initialized."

	self startup.
	delaySemaphore wait! !

!Delay methodsFor: 'testing'!

inProgress
	"Answer true if the delay is still pending."

	^delayInProgress! !

!Delay methodsFor: 'private: private'!

activate
	"For the moment, the receiver will be the next Delay to resume the
	reciever's suspended process."

	ActiveDelay _ self.
	TimingSemaphore initSignals.
	Processor signal: TimingSemaphore atTime: resumptionTime!

delay: millisecondCount 
	delayDuration _ millisecondCount.
	delayInProgress _ false.
	delaySemaphore _ Semaphore new!

delayInProgress: aBoolean

	delayInProgress _ aBoolean!

postSnapshot
	"Reset the resumption time on a returnFromSnapshot"

	(delayInProgress and: [resumptionTime ~~ nil])
		ifTrue:
			[| pendingDelay |
			"convert from old relative time to absolute time"
			pendingDelay _ resumptionTime - (SnapshotTime at: 1).
			pendingDelay _ (SnapshotTime at: 2) * 1000 + pendingDelay.
			"convert from absolute time to new relative time"
			pendingDelay _ pendingDelay - (Time totalSeconds * 1000).
			pendingDelay _ pendingDelay max: 0.
			resumptionTime _ Time millisecondClockValue + pendingDelay]!

reactivate
	"Make sure the timer is armed to go off for this delay."

	delayInProgress ifTrue:
		[TimingSemaphore initSignals.
		Processor signal: TimingSemaphore atTime: resumptionTime]

	"if false then the timer has already fired for this delay and it is waiting (on AccessProtect) to resume"!

resume
	"The receiver's delay duration has expired, the process the receiver
	suspended will resume now. "

	Processor signal: nil atTime: 0.
	delayInProgress _ false.
	delaySemaphore signal!

resumption: millisecondCount 
	delayDuration _ nil.
	resumptionTime _ millisecondCount.
	delayInProgress _ false.
	delaySemaphore _ Semaphore new!

setResumption
	delayInProgress
		ifTrue: [self error: 'This Delay is already waiting']
		ifFalse: 
			[delayDuration == nil
				ifTrue: [resumptionTime == nil ifTrue: [self error: 'uninitialized Delay']]
				ifFalse: [resumptionTime _ Time millisecondClockValue + delayDuration].
			delayInProgress _ true]! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

Delay class
	instanceVariableNames: ''!


!Delay class methodsFor: 'class initialization'!

initialize
	"Initialize class variables that keep track of active Delays."

	"Delay initialize."

	TimingSemaphore _ Semaphore new.
	AccessProtect _ Semaphore forMutualExclusion.
	SuspendedDelays _ 
		SortedCollection sortBlock: 
			[:oldDelay :addedDelay | 
			oldDelay resumptionTime <= addedDelay resumptionTime].
	ActiveDelay _ nil.
	self initializeTimingProcess! !

!Delay class methodsFor: 'instance creation'!

forMilliseconds: millisecondCount 
	"Answer a new instance that will delay the active process for 
	millisecondCount milliseconds when sent the message wait."

	^self new delay: millisecondCount!

forSeconds: secondCount 
	"Answer a new instance that will delay the active process for secondCount seconds when sent the message wait."

	^self new delay: (secondCount * 1000) rounded!

untilMilliseconds: millisecondCount 
	"Answer a new instance that will delay the active process until the 
	system's millisecond clock value is millisecondCount when sent the 
	message wait."

	^self new resumption: millisecondCount! !

!Delay class methodsFor: 'general inquiries'!

millisecondClockValue
	"Answer the current value of the system's millisecond clock."

	^Time millisecondClockValue! !

!Delay class methodsFor: 'snapshots'!

install
	"When returning from a snapshot, reset all delays to be relative
	to the current absolute time"

	ActiveDelay~~nil
		ifTrue: [ActiveDelay postSnapshot.
				  SuspendedDelays do: [ :delay | delay postSnapshot].
				  ActiveDelay reactivate].
	AccessProtect signal!

postSnapshot
	"After making a snapshot, exit the critical section preventing
	Delays from firing"

	AccessProtect signal!

preSnapshot
	"Before making a snapshot, enter a critical section that prevents
	Delays from firing.  Then, record the current absolute time, so
	that Delays can be updated on returning from snapshot"

	AccessProtect wait.
	SnapshotTime _ Array with: Time millisecondClockValue with: Time totalSeconds! !

!Delay class methodsFor: 'examples'!

testAbsoluteDelayOf: delay for: testCount label: label 
	"Example use of Delay.

	Transcript cr. 
	 Delay testAbsoluteDelayOf: 1000 for: 10 label: 'A'. 
	 Delay testAbsoluteDelayOf: 1500 for: 10 label: 'B'.
	"

	| time |
	time _ Delay millisecondClockValue.
	[1 to: testCount do: 
		[:index | 
		(Delay untilMilliseconds: time + (index * delay)) wait.
		Transcript show: label.
		Transcript show: index printString.
		Transcript space]]
		forkAt: Processor userInterruptPriority!

testRelativeDelayOf: delay for: testCount label: label 
	"Example use of Delay."
	"Transcript cr. 
	 Delay testRelativeDelayOf: 1000 for: 10 label: 'A'. 
	 Delay testRelativeDelayOf: 1500 for: 10 label: 'B'"

	| myDelay |
	myDelay _ Delay forMilliseconds: delay.
	[1 to: testCount do: 
		[:index | 
		myDelay wait.
		Transcript show: label.
		Transcript show: index printString.
		Transcript space]]
		forkAt: Processor userInterruptPriority! !

!Delay class methodsFor: 'private: private'!

initializeTimingProcess
	[[true]
		whileTrue: 
			[TimingSemaphore wait.
			AccessProtect wait.
			ActiveDelay == nil
				ifFalse:
					[ActiveDelay delayInProgress: false.
					ActiveDelay resume].
			SuspendedDelays isEmpty
				ifTrue: [ActiveDelay _ nil]
				ifFalse: [SuspendedDelays removeFirst activate].
			AccessProtect signal]]
		forkAt: Processor timingPriority! !

Delay initialize!
