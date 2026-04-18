'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:52:41 pm'!

OSHandle subclass: #IOAccessor
	instanceVariableNames: ''
	classVariableNames: 'DefaultClass KnownFDs '
	poolDictionaries: 'IOConstants '
	category: 'OS-Support'!
IOAccessor comment:
'Class IOAccessor is an abstract class.  Instances of its subclasses are references to an OS "file connection" entity.  Those instances are used to perform IO to the various kinds of stream-like services an OS provides (e.g. at least disk files but probably also IPC facilities like pipes).

A whole bunch of class messages in subclasses are provided to create the various flavors of "file connections".  It is intended that you ask this class which concrete subclass to use to instanciate an accessor of a given type, for example:
		port1 _ IOAccessor defaultForSerial open.
rather than
		port1 _ UnixReallTtyAccessor open.

Immediate subclasses add OS-specific behavior and implementation for various platforms (Unix vs. Mac, etc).  As a convience to future implementors (e.g. ports to new platforms), IOAccessor can be used as a concrete class to provide "essential protocol" for bootstrapping -- permitting (at least) disk file file-in and file-out in particular.

Class Variables:
	DefaultClass	<Metaclass> Appropriate concrete subclass for this platform.
	KnownFDs		<HandleRegistry>

Pool Dictionaries:
	IOConstants	<Dictionary> of characters keyed by symbols
'!


!IOAccessor methodsFor: 'initialize-release'!

close
	"Inform the OS that the accessor's handle should be released.
	Also, remove registry references."

	self isActive ifTrue: [self primClose].
	super release! !

!IOAccessor methodsFor: 'accessing'!

bufferSize
	"Answer the recommended buffer size for this accessor."

	^self class errorSignal handle: [:ex | ex returnWith: 1024] do: [(self primBufferSize)]!

commit
	"Advise OS to synch dirty buffers associated with this accessor.
	Overridden by DiskFileAccessors"

	^self!

fileSize
	"Answer the size of the file (which is being accessed) in bytes."

	^self primGetSize!

truncateTo: position 
	"Shortens the file to the given length (in bytes)."

	<primitive: 664>
	self reportError! !

!IOAccessor methodsFor: 'testing'!

isActive
	"Answer true if the accessor is really connected to something."

	^handle notNil! !

!IOAccessor methodsFor: 'positioning'!

seekTo: position
	"Set the `file pointer' to specified position (a positive integer), nil arg means set-to-end.
	Note that writes to accessors in append mode always write at the
	end, no matter where you position it first."

	^self primSeekTo: position! !

!IOAccessor methodsFor: 'data transfer'!

readInto: buffer 
	"buffer is a byte-object, the place where IO is performed."
	"Returns a SmallInteger, which is a count of the number of bytes 
	actually read."

	^self
		readInto: buffer
		startingAt: 1
		for: buffer sizeInBytes!

readInto: buffer startingAt: index for: count 
	"buffer is a byte-object, the place where IO is performed. 
	index is a SmallInteger, the starting-point in the buffer. 
	count is a SmallInteger, the maximum number of bytes to be read."
	"Returns a SmallInteger, which is a count of the number of bytes 
	actually read."

	^self
		primReadInto: buffer
		startingAt: index
		for: count!

readInto: buffer startingAt: index for: count untilFalse: aBlock 
	"buffer is a byte-object, the place where IO is performed. 
	index is a SmallInteger, the starting-point in the buffer. 
	count is a SmallInteger, the maximum number of bytes to be read. 
	aBlock is a one-arg block which is sent the count thus far. 
	While it evaluates to true, reads will be repeated (unless an 
	error occurs or the count is satisfied. The block can access 
	the buffer in order to determine the result."
	"Returns a SmallInteger, which is a count of the number of bytes 
	read."

	| start result total |
	start _ index.
	total _ 0.
	[result _ self
				primReadInto: buffer
				startingAt: start
				for: count - total.
	start _ start + result.
	total _ total + result.
	(aBlock value: total)
		and: [total < count]] whileTrue.
	^total!

readInto: buffer untilFalse: aBlock 
	"buffer is a byte-object, the place where IO is performed. 
	aBlock is a one-arg block which is sent the count thus far. 
	While it evaluates to true, reads will be repeated (unless an 
	error occurs or the count is satisfied. The block can access 
	the buffer in order to determine the result."
	"Returns a SmallInteger, which is a count of the number of bytes 
	read."

	^self
		readInto: buffer
		startingAt: 1
		for: buffer sizeInBytes
		untilFalse: aBlock!

writeAll: buffer 
	"buffer is a byte-object, the place where IO is performed."
	"Returns a SmallInteger, which is the count of the bytes written, 
	which should be the same as buffer size unless there was an error."

	^self
		writeFrom: buffer
		startingAt: 1
		forSure: buffer sizeInBytes!

writeFrom: buffer 
	"buffer is a byte-object, the place where IO is performed."
	"Returns a SmallInteger, which is the count of the bytes actually
	written."

	^self
		writeFrom: buffer
		startingAt: 1
		for: buffer sizeInBytes!

writeFrom: buffer startingAt: index for: count 
	"buffer is a byte-object, the place where IO is performed. 
	index is a SmallInteger, the starting-point in the buffer. 
	count is a SmallInteger, the maximum number of bytes to be written."
	"Returns a SmallInteger, which is the count of the bytes actually 
	written."

	^self
		primWriteFrom: buffer
		startingAt: index
		for: count!

writeFrom: buffer startingAt: index for: count untilFalse: aBlock 
	"buffer is a byte-object, the place where IO is performed. 
	index is a SmallInteger, the starting-point in the buffer. 
	count is a SmallInteger, the maximum number of bytes to be written. 
	aBlock is a one-arg block which is sent the count thus far. 
	While it evaluates to true, writes will be repeated (unless an 
	error occurs or the count is satisfied. The block can access 
	the buffer in order to determine the result."
	"Answers a SmallInteger, which is a count of the number of bytes 
	written."

	| start result total |
	start _ index.
	total _ 0.
	[result _ self
				primWriteFrom: buffer
				startingAt: start
				for: count - total.
	start _ start + result.
	total _ total + result.
	(aBlock value: total)
		and: [total < count]] whileTrue.
	^total!

writeFrom: buffer startingAt: index forSure: count 
	"buffer is a byte-object, the place where IO is performed. 
	index is a SmallInteger, the starting-point in the buffer. 
	count is a SmallInteger, the number of bytes that must be written."
	"Returns a SmallInteger, which is the count of the bytes written 
	which should be count unless an error occured."

	| start result total |
	start _ index.
	total _ 0.
	[total < count]
		whileTrue:
			[result _ self primWriteFrom: buffer startingAt: start for: count - total.
			start _ start + result.
			total _ total + result].
	^total! !

!IOAccessor methodsFor: 'constants'!

lineEndConvention
	"Answer the character that is the end of line convention."

	^LineEndTransparent!

readPauseInterval
	"Answer an appropriate number of milliseconds to wait
	for unready accessors."

	^Smalltalk frills ifTrue: [200] ifFalse: [400]!

writePauseInterval
	"Answer an appropriate number of milliseconds to wait for
	unready accessors."

	^Smalltalk frills ifTrue: [200] ifFalse: [400]! !

!IOAccessor methodsFor: 'connections'!

asExternalConnection
	"Answer anExternalConnection on the receiver."

	^self connectionClass ioAccessor: self! !

!IOAccessor methodsFor: 'stream creation'!

readAppendStream
	"Answer a readAppend stream connected to the receiver."

	^self asExternalConnection readAppendStream!

readStream
	"Answer a read stream connected to the receiver."

	^self asExternalConnection readStream!

writeStream
	"Answer a read stream connected to the receiver."

	^self asExternalConnection writeStream! !

!IOAccessor methodsFor: 'printing'!

printOn: aStream 
	"Write the printed representation of the receiver on aStream."

	aStream nextPutAll: 'an '.
	aStream nextPutAll: (self isActive
			ifTrue: ['active']
			ifFalse: ['inactive']).
	aStream space.
	aStream nextPutAll: self class name.
	errorCode == nil
		ifFalse: 
			[aStream nextPut: $(.
			self printErrorDescriptionOn: aStream.
			aStream nextPut: $)]! !

!IOAccessor methodsFor: 'private: private-primitives'!

primBufferSize
	"Returns suggested buffer size in bytes (SmallInteger)."

	<primitive: 611>
	self reportError!

primClose
	"Close the accessor."

	<primitive: 651>
	self reportErrorProceeding!

primGetSize
	"Returns fileSize in bytes (SmallInteger)."

	<primitive: 666>
	self reportError!

primReadInto: buffer startingAt: index for: count 
	"buffer is a byte-object, the place where IO is performed. 
	index is a SmallInteger, the starting-point in the buffer. 
	count is a SmallInteger, the number of bytes to be read."
	"Returns a SmallInteger, which is the count of the bytes read. 
	Essential."

	<primitive: 660>
	^self reportErrorProceeding!

primSeekTo: position 
	"Set to specified position (a positive integer). 
	nil arg means set-to-end. Returns self. Essential."

	<primitive: 662>
	self reportErrorProceeding.
	^self!

primWriteFrom: buffer startingAt: index for: count 
	"buffer is a byte-object, the place where IO is performed. 
	index is a SmallInteger, the starting-point in the buffer. 
	count is a SmallInteger, the number of bytes to be written."
	"Returns a SmallInteger, which is the count of the bytes written. 
	Essential."

	<primitive: 661>
	^self reportErrorProceeding! !

!IOAccessor methodsFor: 'defaults'!

connectionClass
	"Answer a default connection class for the receiver."

	^ExternalConnection!

defaultClass
	^self class defaultClass! !

!IOAccessor methodsFor: 'synchronization'!

ioWait
	"Wait until the accessor has data available for reading or writing."

	| sem |
	sem _ Semaphore new.
	(self setSem: sem forWrite: false) ifTrue: [^self].
	(self setSem: sem forWrite: true) ifTrue: [^self].
	sem wait!

ioWaitWithTimeoutMs: ms
	"Wait until the accessor has data available for reading/writing, or
	the timeout expires."
	"Answer true if timeout expired."
	| sem d |
	d _ Delay forMilliseconds: ms.
	sem _ d delaySemaphore.
	(self setSem: sem forWrite: false) ifTrue: [^false].
	(self setSem: sem forWrite: true) ifTrue: [^false].
	d startup.
	"Wait for data arrival or alarm expiry."
	sem wait.
	^d inProgress not!

readWait
	"Wait until the accessor has data available for reading."

	| sem |
	(self setSem: (sem _ Semaphore new) forWrite: false)
		ifFalse: [sem wait]!

readWaitWithTimeoutMs: ms
	"Wait until the accessor has data available for reading, or
	the timeout expires."
	"Answer true if timeout expired."
	| sem d |
	d _ Delay forMilliseconds: ms.
	sem _ d delaySemaphore.
	(self setSem: sem forWrite: false) ifTrue: [^false].
	d startup.
	"Wait for data arrival or alarm expiry."
	sem wait.
	^d inProgress not!

setSem: sem forWrite: bool
	"Signal this semaphore when the fd is ready for an IO operation.
	bool is true if the fd is for writing, false if for reading."

	self subclassResponsibility!

writeWait
	"Wait until the accessor has data available for writing."

	| sem |
	(self setSem: (sem _ Semaphore new) forWrite: true)
		ifFalse: [sem wait]!

writeWaitWithTimeoutMs: ms
	"Wait until the accessor has data available for writing, or
	the timeout expires."
	"Returns true if timeout expired."
	| sem d |
	"Set up expiry alarm."
	d _ Delay forMilliseconds: ms.
	sem _ d delaySemaphore.
	(self setSem: sem forWrite: true) ifTrue: [^false].
	d startup.
	"Wait for data arrival or alarm expiry."
	sem wait.
	^d inProgress not! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

IOAccessor class
	instanceVariableNames: ''!


!IOAccessor class methodsFor: 'class initialization'!

clearRegistry
	"Remove all registered accessor, and free the registry."

	super clearRegistry.
	KnownFDs _ nil!

initialize
	"Set up the registry -- actually only needs doing at hook-up time."
	"IOAccessor initialize"

	self = IOAccessor
		ifTrue: 
			[DefaultClass _ self.
			self clearRegistry.
			self makeRegistry]!

install
	"You are the default class for IOAccessor.  Install yourself."
	"Do nothing."!

makeRegistry
	"Create the handle registry."

	KnownFDs _ HandleRegistry new: 25! !

!IOAccessor class methodsFor: 'class accessing'!

defaultClass: cls
	"Set the default class.  Only done at start-up time."

	DefaultClass _ cls!

registry
	"Return the handle registry."

	^KnownFDs! !

!IOAccessor class methodsFor: 'instance creation'!

openFileAppendOnly: nm
	"Create a new accessor on the named file for appending only."

	^self openFileNamed: nm direction: self appendOnly creation: self mayCreate!

openFileNamed: nm direction: rwMode creation: creationRule 
	"Return an accessor on the file named (a String or Filename) with
	the appropriate read/write mode."

	| u fd |
	fd _ self defaultForFiles
				primOpenFileNamed: nm asString
				direction: rwMode
				creation: creationRule
				errorInto: self defaultForFiles errorReporter new.
	u _ self defaultForFiles handle: fd.
	^u!

openFileReadAppend: nm
	"Create a new accessor on the named file for reading and appending."

	^self openFileNamed: nm direction: self readAppend creation: self mayCreate!

openFileReadOnly: nm
	"Create a new accessor on the named file for reading only."

	^self openFileNamed: nm direction: self readOnly creation: self noCreate!

openFileWriteOnly: nm
	"Create a new accessor on the named file for writing only."

	^self openFileNamed: nm direction: self writeOnly creation: self truncateOrCreate! !

!IOAccessor class methodsFor: 'defaults'!

defaultClass
	"Answer the appropriate class for platform IOAccessors."
	"Should use dynamic lookup?"

	^DefaultClass!

defaultForFiles
	"Return the appropriate class for real (disk) files."

	| dc |
	dc _ self defaultClass.
	dc == IOAccessor ifTrue: [^self]
		ifFalse: [^dc defaultForFiles]!

defaultForIPC
	"Return the appropriate class for inter-process communications."

	| dc |
	dc _ self defaultClass.
	dc == IOAccessor ifTrue: [^self]
		ifFalse: [^dc defaultForIPC]!

defaultForSerial
	"Return the appropriate class for serial (rs-232) communications."

	| dc |
	dc _ self defaultClass.
	dc == IOAccessor ifTrue: [^self]
		ifFalse: [^dc defaultForSerial]! !

!IOAccessor class methodsFor: 'constants-creation'!

mayCreate
	"Open creation code for: create if non-existant (only for rwMode ~=0)."

	^1!

mustCreate
	"Open creation code for: create, prior existance is an error (legal 
	only for rwMode =={1|2})."

	^4!

noCreate
	"Open creation code for: non-existance is an error (only mode for 
	rwMode=0)."

	^0!

truncateNoCreate
	"Open creation code for: non-existance is an error, truncate file to 0 
	bytes (only for rwMode =={1|2})."

	^2!

truncateOrCreate
	"Open creation code for: truncate to 0 bytes if it exists, create if it 
	does not (only for rwMode =={2|3})."

	^3! !

!IOAccessor class methodsFor: 'constants-direction'!

appendOnly
	"Open direction code for: write-only, writes beginning from eof."

	^3!

readAppend
	"Open direction code for: read/write, writes beginning from eof."

	^4!

readOnly
	"Open direction code for: read-only."

	^0!

readWrite
	"Open direction code for: read/write."

	^2!

writeOnly
	"Open direction code for: write-only."

	^1! !

!IOAccessor class methodsFor: 'utilities'!

closeAll
	"Throw-away all current accessors.
	Doing this will probably screw-up your sources/changes file, watch out!!"
	"IOAccessor closeAll"

	KnownFDs values do: [:v | v close]!

closeSockets
	"Throw-away all current accessors.
	Doing this will probably screw-up your sources/changes file, watch out!!"
	"IOAccessor closeSockets"

	KnownFDs values do: [:v | (v isKindOf: UnixSocketAccessor) ifTrue: [v close]]!

convertStringForPlatform: aString
	"Convert aString, which has Smalltalk end of line conventions,
	to conform to platform end of line conventions"

	| conv |
	conv _ self defaultClass new lineEndConvention.
	conv = LineEndCR
		ifTrue: [^aString copy].
	conv = LineEndLF
		ifTrue: [^aString copy replaceAllChar: CR with: LF].
	conv = LineEndCRLF
		ifTrue: [^aString copyReplaceAll: (String with: CR)
							with: (String with: CR with: LF)].
	self error: 'Undefined line-end convention'.

	"IOAccessor convertStringForPlatform: 'abcde
fghij'"!

convertStringFromPlatform: aString
	"Convert aString, which has platform end of line conventions,
	to conform to Smalltalk end of line conventions"

	| conv |
	conv _ self defaultClass new lineEndConvention.
	conv = LineEndCR
		ifTrue: [^aString copy].
	conv = LineEndLF
		ifTrue: [^aString copy replaceAllChar: LF with: CR].
	conv = LineEndCRLF
		ifTrue: [^aString copyReplaceAll: (String with: CR with: LF)
							with: (String with: CR)].
	self error: 'Undefined line-end convention'.! !

!IOAccessor class methodsFor: 'private: private'!

primOpenFileNamed: nm direction: rwMode creation: creationRule errorInto: errorHolder
	"nm is a String, which is interpreted according to OS conventions.
	 rwMode is a SmallInteger, which can have the values:
		0 read-only.
		1 write-only.
		2 read/write.
		3 write-only, writes beginning from eof (e.g. append).
		4 read/write, beginning from eof (e.g. append).
	 creationRule is a SmallInteger, which can have the values:
		0 non-existance is an error (only mode for rwMode=0).
		1 create if non-existant  (only for rwMode ~=0).
		2 non-existance is an error, truncate file to 0 bytes (only for rwMode =={1|2}).
		3 truncate to 0 bytes if it exists, create if it does not (only for rwMode =={2|3}). 
		4 create, prior existance is an error (legal only for rwMode =={1|2}).
	File protection if it is created is under the default OS rules. Essential."

	<primitive: 650>
	^errorHolder reportFor: self! !

IOAccessor initialize!
