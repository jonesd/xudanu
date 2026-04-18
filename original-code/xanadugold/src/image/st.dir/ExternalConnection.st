'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:52:44 pm'!

Object subclass: #ExternalConnection
	instanceVariableNames: 'inputDescriptor outputDescriptor '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'OS-Streaming'!
ExternalConnection comment:
'Instances of ExternalConnection hold ioAccessors for input and output.  ExternalConnections can not be reopened although subclasses might be able to.

Instance Variables:
	inputDescriptor  	<IOAccessor>
	outputDescriptor	<IOAccessor>'!


!ExternalConnection methodsFor: 'accessing'!

dataSize
	"Answer zero since the receiver can't know the amount of data
	assoicated with the connection."

	^0!

input
	"Answer the receiver's input descriptor."

	^inputDescriptor!

input: anAccessor
	"Change the receiver's input descriptor."

	inputDescriptor _ anAccessor!

lineEndConvention
	"Answer a default line end convention for the receiver."

	^inputDescriptor lineEndConvention!

name
	"Answer nil since the receiver knows no name."

	^nil!

output
	"Answer the receiver's output descriptor."

	^outputDescriptor!

output: anAccessor
	"Change the receiver's output descriptor."

	outputDescriptor _ anAccessor! !

!ExternalConnection methodsFor: 'iobuffer creation'!

defaultIoBufferInMode: binaryFlag
	"Answer a default ioBuffer approiate to the receiver with either binary or text mode."

	^IOBuffer on: self mode: binaryFlag!

ioBufferInMode: binaryFlag
	"Answer a default ioBuffer appropriate to the receiver with either binary or text mode."

	^IOBuffer on: self mode: binaryFlag! !

!ExternalConnection methodsFor: 'status'!

close
	"Close the receiver."

	self closeInput.
	self closeOutput!

closeInput
	"Close the receiver's input descriptor.  If the output descriptor is the same as the input descriptor
	then set it to nil."

	inputDescriptor == nil
		ifFalse: [inputDescriptor == outputDescriptor
					ifTrue: [outputDescriptor _ nil].
				inputDescriptor close.
				inputDescriptor _ nil]!

closeOutput
	"Close the receiver's output descriptor.  If the input descriptor is the same as the output descriptor
	then set it to nil."

	outputDescriptor == nil
		ifFalse: [outputDescriptor == inputDescriptor
					ifTrue: [inputDescriptor _ nil].
				outputDescriptor close.
				outputDescriptor _ nil]!

invalidate
	"Forget any descriptors.
	The sender is asserting that the state of the receiver is invalid."

	inputDescriptor _ nil.
	outputDescriptor _ nil!

isActive
	"Answer true if the receiver is active (open),  answer false otherwise."

	^outputDescriptor ~~ nil or: [inputDescriptor ~~ nil]!

release
	"Release any descriptors."

	inputDescriptor == nil ifFalse: [inputDescriptor release].
	outputDescriptor == nil
			ifFalse: [inputDescriptor == outputDescriptor
						ifFalse: [outputDescriptor release]].
	inputDescriptor _ nil.
	outputDescriptor _ nil! !

!ExternalConnection methodsFor: 'testing'!

canPersist
	"Answer a boolean as to whether the receiver can be reopened.
	The default is false."

	^false! !

!ExternalConnection methodsFor: 'stream creation'!

readAppendStream
	"Answer a readAppendStream on the receiver."

	^ExternalReadAppendStream on: self!

readStream
	"Answer a readStream on the receiver."

	^ExternalReadStream on: self!

writeStream
	"Answer a writeStream on the receiver."

	^ExternalWriteStream on: self! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

ExternalConnection class
	instanceVariableNames: ''!


!ExternalConnection class methodsFor: 'instance creation'!

inputAccessor: anInputAccessor outputAccessor: anOutputAccessor
	"Answer an instance of the receiver using anInputAccessor for input
	and anOutputAccessor for output."

	| connection |
	connection _ self new.
	connection input: anInputAccessor.
	connection output: anOutputAccessor.
	^connection!

ioAccessor: anIOAccessor
	"Answer an instance of the receiver using anIOAccessor for both input and output."

	^self inputAccessor: anIOAccessor outputAccessor: anIOAccessor! !