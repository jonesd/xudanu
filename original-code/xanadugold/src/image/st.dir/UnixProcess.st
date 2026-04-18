'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:52:52 pm'!

ExternalProcess subclass: #UnixProcess
	instanceVariableNames: 'exitStatus exitSemaphore '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'OS-Unix'!
UnixProcess comment:
'Class UnixProcess provides a reference to a (heavyweight) Unix process which was created as a child of the running Smalltalk.  Instances are created from return values of primitives which "fork&exec" new (heavyweight) processes.  After you create them, the main interesting thing to do with a UnixProcess is to wait for it to be done and look at its returned status.

UnixProcesses are reaped by the InputState thread; that is, when the InputState process is told that some child died, it queries the VM for the process''es handle and exit status.  It then uses the registry to inform the UnixProcess (which updates instance vars and signals semaphores).

Instance Variables:
	exitStatus	<SmallInteger>
				The returned result from an exited process.  Not valid
				until the process is known to have exited.  Interpretation
				of the value is by prior agreement with the invoked process.
				0 typically means that all went well.
	exitSemaphore	<Semaphore>
				Signalled (by the UnixProcess reaper mechanism defined
				in the metaclass and invoked by InputState>>run) when
				the process exits.
'!


!UnixProcess methodsFor: 'accessing'!

status
	"Return my exit status.  Only meaningful if the process has exited."
	"Actually, nil means that the process (seemingly) hasn't exited yet."
	^exitStatus! !

!UnixProcess methodsFor: 'testing'!

isActive
	"Return true if the UnixProcess is still thought to be running."
	^exitSemaphore notNil & (exitStatus == nil)!

isExited
	"Return true if the UnixProcess has exited."
	^exitStatus notNil!

isOK
	"Return true if the UnixProcess is still thought to be running and accessable."
	^self isActive & handle notNil!

isZombie
	"Return true if the UnixProcess is still thought to be running but is inacessable."
	^self isActive & handle == nil! !

!UnixProcess methodsFor: 'synchronization'!

kill: sig
	"send a signal to this process.  Sig is a SmallInteger, interpretation is by OS standards."
	<primitive: 683>
	^self reportError!

wait
	"Block the caller until I have exited."
	"Since there could be many waiters, each waiter signals the 
	semaphore an extra time in order to permit everyone to proceed."

	self isExited | (exitSemaphore == nil)
		ifFalse: 
			[exitSemaphore wait.
			exitSemaphore signal]! !

!UnixProcess methodsFor: 'printing'!

printOn: aStream 
	"Append to the argument aStream a sequence of characters that 
	identifies the receiver."

	aStream nextPutAll: 'a '.
	aStream nextPutAll: self class name.
	handle == nil
		ifTrue: 
			[aStream nextPutAll: ' (Inactive: exitStatus '.
			exitStatus printOn: aStream]
		ifFalse: 
			[aStream nextPutAll: '(Active: pid '.
			handle printOn: aStream].
	errorCode == nil
		ifFalse: 
			[aStream nextPutAll: ', '.
			self printErrorDescriptionOn: aStream].
	aStream nextPut: $)! !

!UnixProcess methodsFor: 'private: private-initialize/release'!

done: v 
	"Handle a process which has exited."
	"Record the status, remove me from the active list and awaken any waiters."

	self class unregister: self.
	exitStatus _ v.
	handle _ nil.
	exitSemaphore == nil ifFalse: [exitSemaphore signal]!

initialize
	"Create the semaphore to be signaled when the process has exited."

	exitSemaphore _ Semaphore new.
	^super initialize!

release
	"Break the reference to the (presumably non-existant) process."

	| s |
	self class unregister: self.
	s _ exitSemaphore.
	super release.
	exitSemaphore _ nil.
	s == nil ifFalse: [s signal]! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

UnixProcess class
	instanceVariableNames: ''!


!UnixProcess class methodsFor: 'class initialization'!

hookupTo: pn
	"You have become the default class for ExternalProcess.  Prepare yourself."

	"Do nothing."! !

!UnixProcess class methodsFor: 'instance creation'!

forkJob: progName arguments: args
	"Fork & exec a new unix process.  The program to exec is named
	by progName (String).  Pass it the arguments args (Array of String),
	the default environment and the default stdin/stdout/stderr.
	Answer a UnixProcess."

	^self forkJob: progName arguments: args environment: nil descriptors: nil.!

forkJob: progName arguments: args descriptors: fds
	"Fork & exec a new unix process.  The program to exec is named
	by progName (String).  Pass it the arguments args (Array of String),
	the default environment and the accessors fds
	(Array with: stdin with: stdout with: stderr).  Answer a UnixProcess."

	^self forkJob: progName arguments: args environment: nil descriptors: fds!

forkJob: progName arguments: args environment: env descriptors: fds
	"Fork & exec a new unix process.  The program to exec is named
	by progName (String).  Pass it the arguments args (Array of String),
	the environment env (CEnvironment) and the accessors fds
	(Array with: stdin with: stdout with: stderr).  Answer a UnixProcess."

	| proc pid |
	pid _ self primFork: progName arguments: args environment: env descriptors: fds errorTo: (self errorReporter new).
	proc _ super handle: pid.
	^proc!

forkJob: progName descriptors: fds
	"Fork & exec a new unix process.  The program to exec is named
	by progName (String).  Pass it no arguments,
	the default environment and the accessors fds
	(Array with: stdin with: stdout with: stderr).  Answer a UnixProcess."

	^self forkJob: progName arguments: nil environment: nil descriptors: fds! !

!UnixProcess class methodsFor: 'defaulting'!

defaultClass
	"Answer the appropriate concrete class."
	"I'm quite concrete!!"

	^self!

errorReporter
	"Answer the appropriate class for error interpretation."

	^UnixErrorHolder! !

!UnixProcess class methodsFor: 'process reaping'!

reapSome
	"Find all exited child processes and reap them."
	"This routine may be called from a high priority process,
	so we fork off a thread to do the ``done'' signaling."

	| result process |
	[(result _ self reapOne) == nil]
		whileFalse: 
			[process _ self findRegistrant: (result at: 1).
			process == nil ifFalse: [[process done: (result at: 2)] forkAt: Processor userInterruptPriority]]! !

!UnixProcess class methodsFor: 'examples'!

cshBullet: string
	"Execute a csh command, and ignore the reply.
	Not appropriate if the command would return a long reply (>= 4096 bytes)
	since the process would never exit."
	"UnixProcess cshBullet: 'rm useless.file'"

	| cmd proc connection|
	connection _ self pipeConnectionFor: 'csh'
			arguments: #('-ft')
			setProcessDescriptor: [:pd | proc _ pd].
	cmd _ connection writeStream.
	[cmd nextPutAll: string; cr; commit.
	proc wait]
		valueNowOrOnUnwindDo: [cmd close].
	proc release!

cshOne: string 
	"Invoke a c-shell, pass it the string as a command and return the 
	result (a String)."
	"UnixProcess cshOne: 'ls -l'"

	| cmd proc reply connection |
	connection _ self pipeConnectionFor: 'csh'
			arguments: #('-ft')
			setProcessDescriptor: [:pd | proc _ pd].
	cmd _ connection readAppendStream.
	[cmd nextPutAll: string; cr; commit.
	reply _ cmd contents.
	proc wait]
		valueNowOrOnUnwindDo: [cmd close].
	proc release.
	^reply!

directoryListing
	"Return a directory listing using the Unix ls command"
	"UnixProcess directoryListing"

	| cmd proc reply connection |
	connection _ self pipeConnectionFor: 'ls'
			arguments: #('-a' '-l')
			setProcessDescriptor: [:pd | proc _ pd].
	cmd _ connection readStream.
	[reply _ cmd contents.
	proc wait]
		valueNowOrOnUnwindDo: [cmd close].
	proc release.
	^reply! !

!UnixProcess class methodsFor: 'private: private'!

pipeConnectionFor: aName arguments: startupArguments setProcessDescriptor: pdBlock 
	"Start a new job on the program called aName, passing 
	startupArguments and setting up pipes to communicate to the new 
	job. Answer an ExternalConnection which can communicate to the 
	job. Pass the process descriptor into the block pdBlock."

	| fdPair outputReadEnd outputWriteEnd inputReadEnd inputWriteEnd processDescriptor externalConnection |
	
	[fdPair _ UnixPipeAccessor openPair.
	outputReadEnd _ fdPair at: 1.
	outputWriteEnd _ fdPair at: 2.
	"Open a pipe for child's input"
	fdPair _ UnixPipeAccessor openPair.
	inputReadEnd _ fdPair at: 1.
	inputWriteEnd _ fdPair at: 2.	"stderr"
	processDescriptor _ self
				forkJob: aName
				arguments: startupArguments
				descriptors: (Array
						with: inputReadEnd
						with: outputWriteEnd
						with: outputWriteEnd)]
		valueOnUnwindDo: ["Close open accessors on error."
			(Array
				with: outputReadEnd
				with: outputWriteEnd
				with: inputReadEnd
				with: inputWriteEnd)
				do: [:ioa | ioa notNil ifTrue: [ioa close]]].
	"Close unshared FD's"
	outputWriteEnd close.
	inputReadEnd close.
	externalConnection _ ExternalConnection new.
	externalConnection input: outputReadEnd.
	externalConnection output: inputWriteEnd.
	pdBlock value: processDescriptor.
	^externalConnection!

primFork: nm arguments: args environment: env descriptors: fds errorTo: errorHolder
	"Fork & exec a new unix process.  The program to exec is named
	by progName (String).  Pass it the arguments args (Array of String),
	the environment env (CEnvironment) and the accessors fds
	(Array with: stdin with: stdout with: stderr).  Answer a unix pid."

	<primitive: 681>
	errorHolder reportFor: self.
	^nil!

reapOne
	"Returns an (Array with: pid with: status) for an exited process."

	<primitive: 682>
	^nil! !