'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:52:39 pm'!

OSHandle subclass: #ExternalProcess
	instanceVariableNames: ''
	classVariableNames: 'ChildProcesses DefaultClass '
	poolDictionaries: ''
	category: 'OS-Support'!
ExternalProcess comment:
'Class ExternalProcess is an abstract class.  An instance of one of its subclasses is a reference to a (heavyweight) OS-level process which was created as a child of the running Smalltalk.  Instances are typically created from return values of primitives which "fork&exec" new (heavyweight) processes.

As a subclass of OSHandle, ExternalProcess inherits the handle instance variable which is used to hold an identifier of the process which is meaningful to the underlying OS.

Class Variables:
	ChildProcesses	<HandleRegistry>
	DefaultClass	<MetaClass> The correct concrete subclass for this platform.'!

"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

ExternalProcess class
	instanceVariableNames: ''!


!ExternalProcess class methodsFor: 'class initialization'!

clearRegistry
	"Break all the references in my registry and free it."

	super clearRegistry.
	ChildProcesses _ nil!

initialize
	"ExternalProcess initialize"
	"Assume no concrete subclass is available. 
	Set up registry."

	self = ExternalProcess
		ifTrue: 
			[DefaultClass _ self.
			self clearRegistry.
			self makeRegistry]!

install
	"You are the default class for ExternalProcess.  Install yourself."
	"Do nothing for abstract classes."!

makeRegistry
	"Set up the handle registry."

	ChildProcesses _ HandleRegistry new: 10! !

!ExternalProcess class methodsFor: 'class access'!

defaultClass: cls
	"Assign the appropriate concrete class for this platform.
	Typically done only when resuming a snapshot on a different
	platform."

	DefaultClass _ cls!

registry
	"Return my handle registry."

	^ChildProcesses! !

!ExternalProcess class methodsFor: 'process reaping'!

reapSome
	"Find all exited child processes and reap them."
	"This routine may be called from a high priority process."
	"Should be ^self subclassResponsibility but we don't want to break
	InputState>>run.  When subclassResponsibility is implemented with
	signals, then we wouldn't worry."! !

!ExternalProcess class methodsFor: 'defaulting'!

defaultClass
	"Answer the appropriate concrete subclass for this platform."

	^DefaultClass! !

ExternalProcess initialize!
