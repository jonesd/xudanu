'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:52:43 pm'!

OSErrorHolder subclass: #OSHandle
	instanceVariableNames: 'handle '
	classVariableNames: 'PlatFilenameClasses PlatIOClasses PlatProcessClasses PrevPlatformID '
	poolDictionaries: ''
	category: 'OS-Support'!
OSHandle comment:
'Class OSHandle is an abstract class.  Instances of its subclasses are used as references to entities known to the host operating system.  These references do not meaningfully persist across snapshots.

Typically, a subclass will need some kind of registry for all active instances (to deal with snapshots, or to de-multiplex asynchronous status messages from the VM).  Class messages are provided for maintaining such a registry.

Subclasses must implement:
	in class protocol
		class accessing
			defaultClass
			defaultClass:

Instance Variables:
	handle	<SmallInteger>
			nil indicates that this reference is not meaningful.
			Other values are some opaque handle used by the VM
			to refer to the underlying external entity.

Class Variables:
	PlatFilenameClasses, PlatIOClasses, PlatProcessClasses
						<Dictionary>
						Keeps correspondences between platform identification
						strings and corresponding concrete subclasses.
	PrevPlatformID		<String>
						The platform-type identification string returned at
						the last start-up.  Used to determine whether a different
						set of concrete classes needs to be "hooked-up".
'!


!OSHandle methodsFor: 'initialize-release'!

initialize
	"Intialize the receiver's instance variables."
	"Do nothing, nil is right for the abstract class."!

release
	"Deactivate and unregister the receiver."

	self class unregister: self.
	handle _ nil.
	errorCode _ 0! !

!OSHandle methodsFor: 'accessing'!

key
	"Answer the key that the receiver is to be registered under."

	^handle! !

!OSHandle methodsFor: 'private: private'!

handle: h 
	"Only the receiveer's metaclass should set its handle (it needs to be done at 
	instance-creation time)."

	handle _ h! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

OSHandle class
	instanceVariableNames: ''!


!OSHandle class methodsFor: 'class initialization'!

clearRegistry
	"If the receiver has a registry, broadcast to all elements that they are released."

	"This is temporary debugging code."
	Transcript cr; nextPutAll: 'Clearing registry of '; print: self name.
	Transcript nextPutAll: ' -- called by '; print: thisContext sender; cr; endEntry.
	self registry == nil ifFalse: [self registry release]!

initialize
	"OSHandle initialize."

	"Protect against multiple initialize's; but I sure wish that dependents had set semantics."
	Smalltalk removeDependent: self.
	Smalltalk addDependent: self.
	self initPlatClasses! !

!OSHandle class methodsFor: 'class accessing'!

defaultClass
	"Answer the appropriate concrete subclass for this platform."

	^self subclassResponsibility!

defaultClass: c
	"Record the appropriate concrete subclass for this platform."

	^self subclassResponsibility! !

!OSHandle class methodsFor: 'registry'!

findRegistrant: han 
	"Find the registrant corresponding to this external handle."

	| reg |
	reg _ self registry.
	^reg == nil
		ifTrue: [nil]
		ifFalse: [reg at: han]!

register: oh 
	"Register the argument."

	self registry register: oh!

registry
	"Answer with the registry."
	"Subclasses must override if they have registries."

	^nil!

unregister: uh 
	"Remove the argument from the registry."

	self registry unregister: uh! !

!OSHandle class methodsFor: 'system startup'!

forceHookup
	"Pretend that we've never hooked up before, for debugging and juntas."
	"OSHandle forceHookup"

	PrevPlatformID _ nil.
	self install!

install
	"Deal with returning from snapshot, namely:
		* zonk invalid instances
		* hookup if platform changed and do any installations."

	OSHandle registry release.
	OSHandle allSubclassesDo: [:sc | sc registry release].
	FileDirectory releaseExternalReferences.
	self checkHookup.
	ExternalProcess defaultClass install.
	IOAccessor defaultClass install.
	Filename defaultClass install! !

!OSHandle class methodsFor: 'private: private-initialization/installation'!

checkHookup
	"See if we need to re-hook default subclasses."

	| ps |
	ps _ self informVM.
	ps notNil
		ifTrue:
			[ps = PrevPlatformID
				ifFalse: 
					[PrevPlatformID _ ps.
					self hookupFor: ps]]!

hookupFor: ps
	"hook-up default subclasses."

	| id dpc dioc dfn |
	id _ ps copyUpTo: Character space.
	Transcript cr; show: 'Current platform "', ps, '" differs from one where snapshot was made...'.

	dpc _ Smalltalk at: (PlatProcessClasses at: id ifAbsent: [#ExternalProcess]).
	ExternalProcess defaultClass: dpc.
	dpc hookupTo: ps.

	dioc _ Smalltalk at: (PlatIOClasses at: id ifAbsent: [#IOAccessor]).
	IOAccessor defaultClass: dioc.
	dioc hookupTo: ps.

	dfn _ Smalltalk at: (PlatFilenameClasses at: id ifAbsent: [#Filename]).
	Filename defaultClass: dfn.
	dfn hookupTo: ps.

	Transcript cr; nextPutAll: '...hooked up.'; cr; endEntry!

hookupTo: pn
	"You have become the default class for some OSHandle subclass.  Prepare yourself."

	"Can't do ^self subclassResponsibility because we might break return-from-snapshot."
	Transcript cr; show: 'Warning -- No concrete class for ', self class name!

informVM
	"Answers platform identifier string. 
	Must be sent before any new-IO is done."

	| platName infoArray |
	infoArray _ Array
				with: OSErrorHolder
				with: ExternalProcess
				with: IOAccessor.
	platName _ self primInformVM: infoArray.
	platName isNil ifTrue: [Transcript cr; nextPutAll: '****** VM not equipped to handle NewIO *******'; cr; endEntry].
	^platName!

initPlatClasses
	"Build the dictionaries of the specific concrete classes for
	known platforms."
	"OSHandle initPlatClasses"

	PlatProcessClasses _ Dictionary new.
	PlatProcessClasses at: 'unix' put: #UnixProcess.
	PlatIOClasses _ Dictionary new.
	PlatIOClasses at: 'unix' put: #UnixIOAccessor.
	PlatIOClasses at: 'dos' put: #DosIOAccessor.
	PlatIOClasses at: 'mac' put: #MacIOAccessor.
	PlatFilenameClasses _ Dictionary new.
	PlatFilenameClasses at: 'unix' put: #UnixFilename.
	PlatFilenameClasses at: 'dos' put: #DosFilename.
	PlatFilenameClasses at: 'mac' put: #MacFilename.!

primInformVM: array
	"Give newIO the 3 magic metaclasses (error-holder, process & accessor).
	Answers platform type ID string."

	<primitive: 699>
	^nil! !

!OSHandle class methodsFor: 'private: private-instance creation'!

handle: fd 
	"Make an instance from a raw handle."
	"Don't use this unless you really know what you're doing!!"

	| u |
	u _ self new initialize handle: fd.
	self register: u.
	^u! !

OSHandle initialize!
