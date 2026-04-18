'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:52:51 pm'!

IOAccessor subclass: #UnixIOAccessor
	instanceVariableNames: ''
	classVariableNames: 'InProgressECode WouldBlockECode '
	poolDictionaries: ''
	category: 'OS-Unix'!
UnixIOAccessor comment:
'Class UnixIOAccessor is a reference to a Unix "file descriptor".  Instances of it (and its subclasses) are used to perform IO to the various kinds of stream-like services that Unix provides (pipes, fifos, sockets, disk files, serial lines, etc).

Class Variables:
	InProgressECode	<SmallInteger>
	WouldBlockECode	<SmallInteger> Answer the error code known as EWOULDBLOCK in C-land.
'!


!UnixIOAccessor methodsFor: 'initialize-release'!

close
	"Inform Unix that the accessor's handle should be released.
	Also, remove registry references."
	"Most errors occurring on close are uninteresting and are squelched.
	However, any error which indicates that a previous transation on the
	accessor was not completed should be signalled."

	self isActive ifTrue: [self errorReporter errorSignal
		handle: [:ex | (ex signal inheritsFrom: self errorReporter transferFaultSignal)
					ifTrue: [ex reject] ifFalse: [ex return]]
		do: [self primClose]].
	self release! !

!UnixIOAccessor methodsFor: 'testing'!

bytesForRead
	"Return the number of bytes available for reading."
	<primitive: 669>
	^self reportErrorProceeding! !

!UnixIOAccessor methodsFor: 'constants'!

lineEndConvention

	^LineEndLF! !

!UnixIOAccessor methodsFor: 'data transfer'!

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

	| start result total ms |
	start _ index.
	total _ 0.
	ms _ self readPauseInterval.
	
	[result _ self
				primNofailReadInto: buffer
				startingAt: start
				for: count - total.
	result == nil
		ifFalse: 
			[start _ start + result.
			total _ total + result]
		ifTrue: [errorCode = WouldBlockECode
				ifTrue: [self readWaitWithTimeoutMs: ms]
				ifFalse: [self reportError]].
	(aBlock value: total)
		and: [total < count]] whileTrue.
	^total!

writeFrom: buffer startingAt: index for: count untilFalse: aBlock 
	"buffer is a byte-object, the place where IO is performed. 
	index is a SmallInteger, the starting-point in the buffer. 
	count is a SmallInteger, the maximum number of bytes to be written. 
	aBlock is a one-arg block which is sent the count thus far. 
	While it evaluates to true, writes will be repeated (unless an 
	error occurs or the count is satisfied. The block can access 
	the buffer in order to determine the result."
	"Returns a SmallInteger, which is a count of the number of bytes 
	written."

	| start result total ms |
	start _ index.
	total _ 0.
	ms _ self writePauseInterval.
	
	[result _ self
				primNofailWriteFrom: buffer
				startingAt: start
				for: count - total.
	result == nil
		ifFalse: 
			[start _ start + result.
			total _ total + result]
		ifTrue: [errorCode = WouldBlockECode
				ifTrue: [self writeWaitWithTimeoutMs: ms]
				ifFalse: [self reportError]].
	(aBlock value: total)
		and: [total < count]] whileTrue.
	^total! !

!UnixIOAccessor methodsFor: 'private: private'!

primNofailReadInto: buffer startingAt: index for: count
	"buffer is a byte-object, the place where IO is performed. 
	index is a SmallInteger, the starting-point in the buffer. 
	count is a SmallInteger, the number of bytes to be read."
	"Returns a SmallInteger, which is the count of the bytes read."
	"WouldBlock is a potential error condition."

	<primitive: 660>
	^nil!

primNofailWriteFrom: buffer startingAt: index for: count
	"buffer is a byte-object, the place where IO is performed.
	 index is a SmallInteger, the starting-point in the buffer.
	 count is a SmallInteger, the number of bytes to be written."
	"Returns a SmallInteger, which is the count of the bytes written."
	<primitive: 661>
	^nil!

primReadInto: buffer startingAt: index for: count 
	"buffer is a byte-object, the place where IO is performed. 
	index is a SmallInteger, the starting-point in the buffer. 
	count is a SmallInteger, the number of bytes to be read."
	"Returns a SmallInteger, which is the count of the bytes read."
	"WouldBlock is a potential error condition."

	<primitive: 660>
	errorCode = WouldBlockECode
		ifTrue: 
			[self readWait.
			^self primReadInto: buffer startingAt: index for: count].
	^self reportErrorProceeding!

primWriteFrom: buffer startingAt: index for: count
	"buffer is a byte-object, the place where IO is performed.
	 index is a SmallInteger, the starting-point in the buffer.
	 count is a SmallInteger, the number of bytes to be written."
	"Returns a SmallInteger, which is the count of the bytes written."
	"WouldBlock is a potential error condition."
	<primitive: 661>
	errorCode = WouldBlockECode
		ifTrue: 
			[self writeWait.
			^self primWriteFrom: buffer startingAt: index for: count].
	^self reportErrorProceeding!

setSem: sem forWrite: bool
	"Signal this semaphore when the fd is ready for an IO operation.
	bool is true if the fd is for writing, false if for reading."
	<primitive: 668>
	^self reportError! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

UnixIOAccessor class
	instanceVariableNames: ''!


!UnixIOAccessor class methodsFor: 'class initialization'!

hookupTo: platname 

	"This shouldn't really be here, but *someone* needs to
	tell these guys to hook-up, it might as well be me."
	UnixTtyAccessor hookupTo: platname.
	UnixErrorHolder hookupTo: platname!

inProgressErrorCode: n
	"Assign the error code for ``operation in progress''."

	InProgressECode _ n!

install
	"Install any additional concrete Unix IO classes."
	"This should be moved somewhere else..."

	| usa |
	usa _ Smalltalk at: #UnixSocketAccessor ifAbsent: [nil].
	usa isNil ifFalse: [usa install]!

wouldBlockErrorCode: n
	"Assign the value for the wouldBlock error code."

	WouldBlockECode _ n! !

!UnixIOAccessor class methodsFor: 'defaulting'!

defaultClass
	"Answer the appropriate concrete subclass."

	^self!

defaultForFiles
	"Return the appropriate class for real (disk) files."

	^UnixDiskFileAccessor!

defaultForIPC
	"Return the appropriate class for inter-process communications."

	^Smalltalk at: #UnixSocketAccessor ifAbsent: [UnixPipeAccessor]!

defaultForSerial
	"Return the appropriate class for serial (rs-232) communications."

	^UnixRealTtyAccessor!

errorReporter
	"Answer the appropriate error code interpreter for me."

	^UnixErrorHolder! !