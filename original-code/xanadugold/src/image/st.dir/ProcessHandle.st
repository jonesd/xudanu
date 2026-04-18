'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:50:09 pm'!

Object subclass: #ProcessHandle
	instanceVariableNames: 'process controller interrupted resumeContext proceedValue haltedScrollBar '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Tools-Programming'!
ProcessHandle comment:
'A ProcessHandle holds the state of an interrupted process.  It is capable of cutting back the process''s stack, terminating the process, or causing it to resume again.

Instance Variables:
	process		<Process> the interrupted process
	controller	<nil | Controller> standard system controller associated with the process, if there was one
	interrupted	<Boolean> true if it was interrupted with control-c, false if it was suspended by a program message send
	resumeContext	<Context> context in which to continue the process if possible
	proceedValue	<Object> used as the result as though the method were evaluated
	haltedScrollBar	<Form> the ScrollController''s halted scroll bar image'!


!ProcessHandle methodsFor: 'initialize-release'!

release
	process _ nil.  "break all cycles"
	controller _ nil.
	resumeContext _ nil.
	proceedValue _ nil! !

!ProcessHandle methodsFor: 'access'!

interrupted
	"Answer whether the process was interrupted by a control-c."

	^ interrupted!

interrupted: aBoolean
	"The argument aBoolean is true if the process was interrupted with a control-c."

	interrupted _ aBoolean!

proceedValue
	"Answer the result to be used as though the method were evaluated."

	^ proceedValue!

proceedValue: value
	"Set value to be the result to used as though the method were evaluated."

	proceedValue _ value!

topContext
	"Answer the context in which to continue the process, if possible."

	^ resumeContext!

topContext: aContext
	"Set aContext to be the context in which to continue the process, if possible."

	resumeContext _ aContext! !

!ProcessHandle methodsFor: 'control'!

proceed
	"Continue evaluation of the process."

	interrupted ifTrue: [resumeContext push: proceedValue].
	self resumeProcess!

resumeProcess
	"Continue the process--start it up again from the point of interrupt.  
	If there was a controller associated with the interrupted process, 
	make it be the active controller."

	| aScheduledController suspendedContext isCurrent p |
	aScheduledController _ ScheduledControllers activeController.
	aScheduledController view erase.
	suspendedContext _ process suspendedContext.
	suspendedContext method == (Process compiledMethodAt: #terminate)
		ifFalse:
			[resumeContext == suspendedContext ifFalse:
				[(suspendedContext hasSender: resumeContext)
					ifTrue: [process popTo: resumeContext]
					ifFalse: [process install: resumeContext]]. 
			controller == nil
				ifFalse:	[ScheduledControllers
						activeControllerNoTerminate: controller  "NoTerminate"
						andProcess: process]].
	"if old process was terminated, just terminate current one"
	isCurrent _ controller ~~ nil.
	p _ process.
	self release.  "must precede close because it tries to terminate"
	aScheduledController closeAndUnscheduleNoErase.
	isCurrent
		ifTrue:	[ScrollController restoreHaltedScrollBar: haltedScrollBar.
				Processor terminateActive]
		ifFalse:	[p resume.
				ScheduledControllers searchForActiveController]!

terminate
	"Halt the evaluate of the process forever."

	process == nil ifFalse: [process terminate].
	self release! !

!ProcessHandle methodsFor: 'private: private'!

process: aProcess controller: aController interrupted: aBoolean resumeContext: aContext
	process _ aProcess.
	controller _ aController.
	interrupted _ aBoolean.
	resumeContext _ aContext.
	proceedValue _ nil.
	haltedScrollBar _ ScrollController haltedScrollBar.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

ProcessHandle class
	instanceVariableNames: ''!


!ProcessHandle class methodsFor: 'instance creation'!

on: aProcess at: aContext interrupted: aBoolean
	"Answer a new instance of the receiver."

	^ self new
		process: aProcess
		controller: (ScheduledControllers activeControllerProcess == aProcess
					ifTrue: [ScheduledControllers activeController]
					ifFalse: [nil])
		interrupted: aBoolean
		resumeContext: aContext! !