'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:51:48 pm'!

Stream subclass: #BinaryStorage
	instanceVariableNames: 'policy objects stream lastId '
	classVariableNames: 'BinaryErrorSignal FalseTag FloatTag FormatErrorSignal HeaderErrorSignal NegateTag NilTag OpCharacter OpcodeMask OpcodeShift OperandMask OpId OpInteger OpPolicy OpPrefix OpString OpSymbol OpTag SendTag TrueTag '
	poolDictionaries: ''
	category: 'System-Binary Storage'!
BinaryStorage comment:
'Class BinaryStorage represents the storage of object structures in binary on a data stream for subsequent reloading, or read in such objects.  Objects to be written fall into two categories: ''manifest'' objects, for which only the contents or value matter, and other objects, for which the object identity matters as well.

To write an object, the BinaryStorage sends the message
	anObject storeBinaryOn: aBinaryStorage
anObject must write itself out using only the public message (store:) and the primitive value-writing messages in the category ''storing-objects''.  In particular, the implementation of this message in non-manifest objects must begin with
	aBinaryStorage storeRecordOfClass: self class
so that the class of the object is recorded properly on the stream.

When reading, the BinaryStorage treats manifest and other objects differently.  The algorithms for reading manifest objects are built in.  (It is obviously necessary to keep these algorithms consistent with the scattered implementations of storeBinaryOn: in the manifest object classes, but we don''t know how to put the algorithms in just one place for the purpose of doing this.)  For other objects, the object''s class is sent the message
	aClass readBinaryFrom: aBinaryStorage tag: id
The implementation of this message must start by creating an object (normally, the object that will be returned as the value of the method) and ''register'' it by sending
	aBinaryStorage register: newObject id: id
This is needed in case there are multiple references to the object, or circular references within the object''s contents that point back to the object itself.  The method must then read the contents of the object back using the primitive value-reading messages in the category ''reading-objects'', or the public message nextItem.

The foregoing is not the whole story;  see BinaryStoragePolicy for more details.

Instance Variables:
	policy	<BinaryStoragePolicy>   defines policy for external references 
	objects	<IdentityDictionary key: Object value: Integer>   objects with ids 
	stream	<Stream>   data stream 
	lastId	<Integer>   last id assigned

Class Variables:
	BinaryErrorSignal	<Signal> BOSS error
	FormatErrorSignal	<Signal> Incompatible BOSS file format
	HeaderErrorSignal	<Signal> Invalid BOSS file
	
	The following variables are SmallIntegers used to denote various kinds of objects that might be stored.
	FalseTag
	FloatTag
	NegateTag
	NilTag
	OpCharacter 
	OpcodeMask 
	OpcodeShift 
	OperandMask 
	OpId 	
	OpInteger
	OpPolicy
	OpPrefix
	OpString
	OpSymbol
	OpTag
	SendTag
	TrueTag 

Implementation notes
-------------------

The private encode/decode messages define the storage representation for the four kinds of primitive objects (tags, integers, strings, and byte arrays): all other storing and reading messages are ultimately defined using encode/decode.
'!


!BinaryStorage methodsFor: 'initialize-release'!

close
	"Close the stream that the receiver is accessing."

	stream close!

initialize
	"Initialize the receiver so that it has a new standard binary storage 
	policy and its variables are property initialized."

	policy _ StandardBSPolicy new.
	self initializeObjects!

on: aStream 
	"Create a new instance of the receiver on aStream, making sure 
	that this stream can handle binary reading and writing."

	(aStream class canUnderstand: #binary)
		ifTrue: [aStream binary].
	stream _ aStream.
	self initialize! !

!BinaryStorage methodsFor: 'stream writing'!

nextPut: object
	"Put a binary representation of object into the receiver."

	| objectId | 
	object isManifest 
		ifTrue: [object storeBinaryOn: self]
		ifFalse:
			[(objectId _ objects at: object ifAbsent: [nil]) == nil
				ifTrue:
					[objects at: object put: (lastId _ lastId + 1).
					policy storeNew: object on: self]
				ifFalse: [self encodeId: objectId]]!

nextPutClasses: classes 
	"Store a collection of classes. The semantics are equivalent to 
	fileOut, i.e., only the code is written, not the values of the class 
	variables or class instance variables."

	"This message is inappropriate for a 
	runtime environment, since it relies on 
	the SystemOrganization being present."

	| classSet |
	self nextPut: classes size.
	classSet _ IdentitySet new: classes size * 2.
	classSet addAll: classes.
	classes do: [:c | "for fast membership check"
		"each class will be removed from classSet as it is stored"
		self storeClass: c from: classSet]!

print: object 
	"Create an error indicating that this request to store text is not 
	possible."

	self error: 'BOSS streams do not store text'!

store: object 
	"Create an error indicating that this request to store text is not 
	possible."

	self error: 'BOSS streams do not store text'! !

!BinaryStorage methodsFor: 'storing-policy'!

nextPTagPut: pTag
	"Store a policy tag. "

	self encodeOpcode: OpPolicy operand: pTag! !

!BinaryStorage methodsFor: 'storing-objects'!

inClass: aClass do: aBlock
	"Evaluate aBlock with the local naming
	environment bound to that of aClass. "

	^policy inClass: aClass do: aBlock!

storeBoolean: bool
	self encodeTag:
		(bool 
			ifTrue: [TrueTag]
			ifFalse: [FalseTag])!

storeBytes: byteObject
	self encodeBytes: byteObject!

storeCharacter: aChar
	self encodeOpcode: OpCharacter operand: aChar asInteger!

storeFloat: aFloat
	| m f e zeros |
	" We encode Floats in a canonical form
	that is independent of internal representation. "
	self encodeTag: FloatTag.
	f _ aFloat.
	f = 0.0
		ifTrue: [e _ 0. m _ 0]
		ifFalse:
			[" Reduce f to an integer.
			We can make a good guess at how many
			significant bits it has, but we might be wrong
			if f is a multi-precision Float. "
			" The invariant below is that aFloat =
			f (later m) timesTwoPower: e negated. "
			e _ 23 - f exponent.
			f _ f timesTwoPower: e.
			[f fractionPart = 0.0]
				whileFalse:
					[e _ e + 8.
					f _ f timesTwoPower: 8].
			" Now remove trailing zeros.
			(m bitAnd: m negated) is a trick to isolate
			the least significant bit in m. "
			m _ f truncated.
			zeros _ (m bitAnd: m negated) highBit - 1.
			e _ e - zeros.
			m _ m bitShift: zeros negated].
	self nextPut: e; nextPut: m!

storeInteger: integer
	integer < 0
		ifTrue: [self encodeTag: NegateTag; storeInteger: integer negated]
		ifFalse: [self encodeOpcode: OpInteger operand: integer]!

storeNil
	self encodeTag: NilTag!

storeOther: anObject
	" Store an object with no special syntax "
	policy storeOther: anObject on: self!

storeRecordOfClass: class
	policy storeRecordOfClass: class on: self!

storeSend: aMessageSend

	self encodeTag: SendTag.
	aMessageSend storeForExecutionOn: self!

storeString: string
	self encodeString: string opcode: OpString!

storeSymbol: symbol
	self encodeString: symbol opcode: OpSymbol! !

!BinaryStorage methodsFor: 'stream reading'!

atEnd
	"Answer whether the receiver's input stream reached its end."

	^stream atEnd!

contents
	"Answer the current contents of the receiver's input stream."

	| cont |
	cont _ (Array new: 20) writeStream.
	[stream atEnd] whileFalse: [cont nextPut: self next].
	^cont contents!

next
	"Answer the next object in the input stream."

	| byte op operand |
	byte _ self decodeOpByte.
	op _ byte bitAnd: OpcodeMask.
	operand _ byte bitAnd: OperandMask.
	[op = OpPrefix]
		whileTrue:
			[" Accumulate operand prefixes "
			byte _ self decodeOpByte.
			op _ byte bitAnd: OpcodeMask.
			operand _ (operand bitShift: OpcodeShift) +
				(byte bitAnd: OperandMask)].
	op = OpTag
		ifFalse:
			[	" Handle policy tags "
			op = OpPolicy		ifTrue: [^policy nextWithTag: operand from: self].
				" Handle special references "
			op = OpId			ifTrue: [^objects at: operand].
				" Handle registered (non-manifest) objects "
			op = OpString		ifTrue: [^self register: (self decodeString: operand)].
			op = OpSymbol		ifTrue: [^self register: (self decodeString: operand) asSymbol].
				" Handle manifest objects "
			op = OpInteger		ifTrue: [^operand].
			op = OpCharacter	ifTrue: [^Character value: operand].
			self error: 'Unknown BOSS opcode'.
			^nil].
		" Handle special kinds of references "
	operand = SendTag			ifTrue: [^self nextSend].
		" Handle manifest objects "
	operand = NegateTag		ifTrue: [^self next "(integer)" negated].
	operand = NilTag			ifTrue: [^nil].
	operand = TrueTag			ifTrue: [^true].
	operand = FalseTag			ifTrue: [^false].
	operand = FloatTag			ifTrue:
			[| expt mant |
			expt _ self next.  mant _ self next.
			^mant asFloat timesTwoPower: expt negated].
	self error: 'Unknown BOSS tag'.
	^nil!

nextClasses
	"Read a collection of classes. The semantics are equivalent to fileIn, 
	i.e., we only read the code and declarations, not the values of class 
	variables or class instance variables."

	| count allClasses |
	count _ self next.
	allClasses _ OrderedCollection new: count.
	1 to: count do: 
		[:i | 
		| c |
		c _ self next.
		c readBinaryContentsFrom: self."class creation expression"
		c class instanceVariableNames: self next."Now do the metaclass."
		c class readBinaryContentsFrom: self.
		allClasses addLast: c].
	^allClasses! !

!BinaryStorage methodsFor: 'reading-objects'!

assignId
	"Assign and answer the next sequential object id."

	^lastId _ lastId + 1!

readBytes: byteClass size: size
	^self decodeBytes: byteClass size: size!

register: anObject id: objId
	"Associate anObject with the key identification objId."

	objects at: objId put: anObject! !

!BinaryStorage methodsFor: 'state accessing'!

currentState
	"Answer the last assigned localId. This provides a primitive form of 
	checkpointing, so that one can preload a BinaryStorage with a set 
	of objects whose localIds can be available when storing many 
	different objects subsequently."

	^lastId!

currentState: id
	"Set the last assigned localId. This has the effect of 
	rolling back the localId table to a checkpoint."

	id <= lastId
		ifFalse:
			[^self error: 'Invalid lastId'].
	id = lastId ifTrue: [^self].
	id < 0
		ifTrue: [self initializeObjects]
		ifFalse:
			[| keep |
			keep _ IdentityDictionary new: (id * 2 max: 256).
			objects associationsDo:
				[:assoc | assoc value <= id ifTrue:
					[keep add: assoc]].
			objects _ keep].
	lastId _ id! !

!BinaryStorage methodsFor: 'private: private'!

checkHeader
	| check format aChar |
	check _ self decodeString: 5.
	check = 'BOSS ' ifFalse: [HeaderErrorSignal raise].
	format _ 0.
	[(aChar _ (self decodeString: 1) first) isDigit]
		whileTrue:
			[format _ format * 10 + aChar digitValue].
	aChar = Character space ifFalse: [HeaderErrorSignal
raise].
	format = self streamFormatNumber ifFalse:
[FormatErrorSignal raiseWith: format]!

initializeObjects
	lastId _ -1.  "first actual id is 0"
	objects _ IdentityDictionary new: 256!

writeHeader
	self encodeString: 'BOSS ' , self streamFormatNumber printString , ' '! !

!BinaryStorage methodsFor: 'private: private-storing'!

encodeId: objId
	self encodeOpcode: OpId operand: objId!

encodeOpcode: op operand: int
	" Encode an opcode, with an associated
	non-negative integer operand.
	Use as many prefix bytes as necessary. "
	int > OperandMask
		ifTrue:
			[self encodeOpcode: OpPrefix operand: (int bitShift: OpcodeShift negated)].
	self encodeOpByte: op + (int bitAnd: OperandMask)!

encodeString: aString opcode: op
	" Store a string or symbol. "

	self encodeOpcode: op operand: aString size.
	self encodeString: aString!

encodeTag: tagValue
	self encodeOpcode: OpTag operand: tagValue!

storeClass: c from: classes
	" Store a class from a collection of classes.
	Make sure the superclasses get stored first. "

	| kind |
	c isNil ifTrue: [^self].  "reached top of hierarchy"
	self storeClass: c superclass from: classes.
	(classes includes: c) ifFalse: [^self].  "not in set"
	classes remove: c.
	self encodeTag: SendTag.
	self nextPut: c superclass.
	kind _ c kindOfSubclass.
	kind _ kind copyFrom: 2 to: kind size - 1.  "HACK because kind includes leading and trailing blanks!!"
	self nextPut: (kind , 'instanceVariableNames:classVariableNames:poolDictionaries:category:') asSymbol.
	self nextPut: 5.  "# of args"
	self nextPut: c name.
	self nextPut: c instanceVariablesString.
	self nextPut: c classVariablesString.	
	self nextPut: c sharedPoolsString.
	self nextPut: (SystemOrganization categoryOfElement: c name) asString.
	c storeBinaryContentsOn: self.
	" Now do the metaclass. "
	self nextPut: c class instanceVariablesString.
	c class storeBinaryContentsOn: self! !

!BinaryStorage methodsFor: 'private: private-reading'!

nextSend
	| rcvr selector numArgs |
	rcvr _ self next.
	selector _ self next.  "Symbol"
	numArgs _ self next.  "Integer"
	numArgs = 0 ifTrue: [^rcvr perform: selector].
	numArgs = 1 ifTrue: [^rcvr perform: selector with: self next].
	numArgs = 2 ifTrue:
		[| arg1 |
		arg1 _ self next.
		^rcvr perform: selector with: arg1 with: self next].
	^rcvr perform: selector withArguments: ((1 to: numArgs) collect: [:i | self next])!

register: anObject
	objects at: self assignId put: anObject.
	^anObject! !

!BinaryStorage methodsFor: 'private: private-encoding'!

encodeBytes: bytes
	" Append the bytes to the output. "
	stream nextPutAll: bytes!

encodeOpByte: byte
	" Append an opcode/operand to the output. "
	stream nextPut: byte!

encodeString: aByteString
	" Append the characters of
	aByteString to the output. "
	
	1 to: aByteString size do: [:i |
		stream nextPut: (aByteString at: i) asInteger]! !

!BinaryStorage methodsFor: 'private: private-decoding'!

decodeBytes: bytesClass size: size
	| bytes |
	bytesClass == ByteArray
		ifTrue: [^stream next: size].
	bytes _ bytesClass new: size.
	1 to: bytes size do: [:i | bytes at: i put: stream next].
	^bytes!

decodeOpByte
	" Answer the next opcode/operand
	byte from the stream. "
	^stream next!

decodeString: size
	" Read and answer a String
	of the given size. "

	| aString |
	aString _ String new: size.
	1 to: size do: [:i | aString at: i put: (Character value: stream next)].
	^aString! !

!BinaryStorage methodsFor: 'private: private-constants'!

streamFormatNumber
	" Answer the format number supported by this
	version of this class. "
	^5! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

BinaryStorage class
	instanceVariableNames: ''!


!BinaryStorage class methodsFor: 'class initialization'!

initialize
	"BinaryStorage initialize"

	self initializeTags.
	self initializeSignals!

initializeSignals
	"BinaryStorage initializeSignals"

	BinaryErrorSignal _ Object errorSignal newSignalMayProceed: false.
	BinaryErrorSignal
		nameClass: self message: #errorSignal;
		notifierString: 'BOSS error'.
	HeaderErrorSignal _ BinaryErrorSignal newSignal.
	HeaderErrorSignal
		nameClass: self message: #headerErrorSignal;
		notifierString: 'Invalid BOSS file'.
	FormatErrorSignal _ BinaryErrorSignal newSignal.
	FormatErrorSignal
		nameClass: self message: #formatErrorSignal;
		notifierString: 'Incompatible BOSS file format'.!

initializeTags
	"BinaryStorage initializeTags"

	OpcodeMask _ 2r11100000.
	OperandMask _ 2r00011111.
	OpcodeShift _ 5.

	OpPrefix _ 0 bitShift: OpcodeShift.
	OpId _ 1 bitShift: OpcodeShift.
	OpCharacter _ 2 bitShift: OpcodeShift.
	OpInteger _ 3 bitShift: OpcodeShift.
	OpString _ 4 bitShift: OpcodeShift.
	OpSymbol _ 5 bitShift: OpcodeShift.
	OpPolicy _ 6 bitShift: OpcodeShift.
	OpTag _ 7 bitShift: OpcodeShift.

	SendTag _ 0.
	NegateTag _ 1.
	NilTag _ 2.
	TrueTag _ 3.
	FalseTag _ 4.
	FloatTag _ 5! !

!BinaryStorage class methodsFor: 'instance creation'!

read: aStream
	"Create a new instance of the receiver by reading from aStream."

	^self basicNew on: aStream; checkHeader!

write: aStream
	"Write a description of the receiver on aStream."

	^self basicNew on: aStream; writeHeader! !

!BinaryStorage class methodsFor: 'convenience messages'!

classesFrom: aStream 
	"Answer a list of classes that have been stored on the stream. The 
	stream should be positioned before the BOSS format header, and the 
	classes stored in the format used by #putClasses:"

	^(self read: aStream) nextClasses!

classesFromFileNamed: aFileName 
	"Answer a list of classes that have been stored on a file whose 
	name is passed as the argument. The classes should have been 
	stored in the format used by #putClasses:"

	| storage classes |
	storage _ self read: aFileName asFilename readStream.
	[classes _ storage nextClasses]
		valueNowOrOnUnwindDo: [storage close].
	^classes!

from: aStream 
	"Answer the next object on the stream. The object must be 
	immediately preceded by a BOSS format header"

	^(self read: aStream) next!

fromFileNamed: aFileName
	"Answer the first object in the BOSS file"

	| storage object |
	storage _ self read: aFileName asFilename readStream.
	[object _ storage next]
		valueNowOrOnUnwindDo: [storage close].
	^object!

put: anObject 
	"Answer a collection (String or IntegerArray) that represents the 
	argument in a 'binary' format that can be used to reconstruct the 
	object later"

	| storage strm |
	storage _ self write: (strm _ (self streamContentsClass new: 100) writeStream).
	[storage nextPut: anObject]
		valueNowOrOnUnwindDo: [storage close].
	^strm contents!

put: anObject onFileNamed: aFileName 
	"Store the argument onto a file in a 'binary' format that can be used 
	to reconstruct the object later"

	| storage |
	storage _ self write: aFileName asFilename writeStream.
	[storage nextPut: anObject]
		valueNowOrOnUnwindDo: [storage close].
	^storage!

putClasses: classes 
	"Answer a collection (String or IntegerArray) that represents the list 
	of classes in a binary format which may be used to reconstitute 
	them later in the same or another image"

	| storage strm |
	storage _ self write: (strm _ (self streamContentsClass new: 100) writeStream).
	[storage nextPutClasses: classes]
		valueNowOrOnUnwindDo: [storage close].
	^strm contents!

putClasses: classes onFileNamed: aFileName 
	"Store the list of classes on a file in a binary format which may be 
	used to reconstitute them later in the same or another image"

	| storage |
	storage _ self write: aFileName asFilename writeStream.
	[storage nextPutClasses: classes]
		valueNowOrOnUnwindDo: [storage close].
	^storage! !

!BinaryStorage class methodsFor: 'Signal constants'!

errorSignal
	" Answer the Signal that indicates
	a BOSS error. "

	^BinaryErrorSignal!

formatErrorSignal
	" Answer the Signal that indicates
	an incompatible BOSS file format. "
	^FormatErrorSignal!

headerErrorSignal
	" Answer the Signal that indicates
	an error in the BOSS file header. "
	^HeaderErrorSignal! !

!BinaryStorage class methodsFor: 'examples'!

example1
	"BinaryStorage from: BinaryStorage example1 readStream"
	^self put: #(15 -3.0 true #halt $a 'eh?' #(1 2 3))!

example2
	"BinaryStorage from: BinaryStorage example2 first readStream"
	^#(example2) collect: [:s | self put: (BinaryStorage class compiledMethodAt: s)]!

example3
	"BinaryStorage example3"

	^self put: BinaryStorage example3Object  "do this way so subclass will work"

	"| s | s _ BinaryStorage example3.
	MessageTally spyOn: [5 timesRepeat: [BinaryStorage from: s readStream]]"!

exampleClasses1
	"BinaryStorage exampleClasses1"
	^self putClasses: BinaryStorage withAllSubclasses!

exampleClasses2
	"BinaryStorage exampleClasses2"
	^self putClasses: BinaryStorage withAllSubclasses onFileNamed: 't'! !

!BinaryStorage class methodsFor: 'documentation'!

binaryDataStreamDetails
	"A BDS begins with a header.  The header contains a stream format version 
	number, used to verify overall representation compatibility.  The stream 
	format version is encoded as a string of decimal digits (ASCII characters), for 
	maximum independence from particular BOSS representations.

	In BOSS 1.0, the atomic types are: Integer, Float, ByteString, ByteSymbol, and 
	Character, and the objects nil, true, and false.  The representation of Integers 
	and Floats is independent of precision, exponent range, and byte ordering.

	The default storage representation of an object is simply its instance 
	variables.  The dependents are treated like an instance variable, i.e., they are 
	saved with the object even if the object is not a subclass of Model.

	As mentioned in (BinaryStorage class)>>storageFormats, the standard policy
	records references to classes, global objects, and static variables symbolically.
	For compatibility checking, a reference to a class or metaclass contains not 
	only the class name, but the complete list of instance variable names, the 
	instance format word, and a storage format version (obtained by sending 
	the message binaryStorageFormat to the class.) If any of the check parameters 
	do not match those obtained from the class when reading, the result is an 
	exception.
	"

	^self error: 'comment only'!

convenienceMessages
	"The following messages provide for creating a stream or opening a file, 
	reading or writing a single net or a collection of classes, and returning the 
	stream contents or closing the file:

	Storage
		''binaryData will be a ByteArray''

		binaryData := BinaryStorage put: anObject
		binaryData := BinaryStorage putClasses: classCollection
		BinaryStorage put: anObject onFileNamed: fileName
		BinaryStorage putClasses: classCollection onFileNamed: fileName

	Retreival
		''binaryData should be an instance of ByteArray''

		anObject := BinaryStorage from: binaryData
		classCollection := BinaryStorage classesFrom: binaryData
		anObject := BinaryStorage fromFileNamed: fileName
		classCollection := BinaryStorage classesFromFileNamed: fileName
	"

	^self error: 'comment only'!

creatingABinaryStorage
	"BOSS is represented by the class BinaryStorage.  

	A new instance of BinaryStorage using dataStream as a data source/sink 
	may be obtained by evaluating:

		bos := BinaryStorage read: dataStream
		bos := BinaryStorage write: dataStream

	The dataStream may be an instance of any subclass of Stream that is
	readable or writable respectively; specifically, it need not have any encoding
	or file-handling protocol.  However, the underlying collection must store binary 
	(e.g., ByteArray) as opposed to text (e.g., String) information.

	write: writes a header on the dataStream, which read: checks.  This is the 
	only distinction between read: and write: - a client may mix reading and 
	writing freely if the dataStream is positionable, using the checkpoint facility 
	described below.
	"

	^self error: 'comment only'!

encodingAlgorithms
	"BOSS uses a single-pass algorithm for both fetching and storing.

	When asked to store an object, a binaryStorage simply starts writing out the 
	net starting with that object.  In doing so, it assigns a localId to each non-
	manifest object it encounters.  (Manifest objects are those whose identity is 
	not interesting, specifically: integers, characters, and nil/true/false.)  If it 
	encounters a second reference to an object, it writes the localId instead of a 
	second copy of the object.

	Each time the binaryStorage encounters an object for the first time, it asks 
	its policy object to actually write out the object's contents (or a symbolic 
	external reference).  If the policy object has no special representation for the 
	object, it asks the object to write itself out using the message storeBinaryOn: 
	binaryStorage.  Implementations of this message then recursively invoke

		stream store: item

	to store the components of the receiver.

	When reading a net back in, a binaryStorage does exactly the same thing as 
	when writing.  In particular, it assigns localIds in the same order.  This 
	allows general circular or multiple references without the need to write 
	explicit ids on the BDS.
	"

	^self error: 'comment only'!

protocolsForBinaryStreams
	"Encoding is done principally through storeBinaryOn: stream instance-side methods.

	Decoding is done principally through readBinaryFrom: stream class-side methods.

	All atomic classes provide these methods.  Object provides a default by 
	simply forwarding the message to the stream (stream storeOther: self.)  In 
	turn, the stream forwards the message to the policy (policy storeOther: 
	anObject on: stream.)  The standard policy uses concrete (instance variable) 
	representations in a straightforward way.   Various collection classes have 
	more abstract representations, specifically those having hash invariants.
	"

	^self error: 'comment only'!

storageAndRetreival
	"The protocol of BinaryStorage is a subset of Stream protocol.  Specifically, 
	BinaryStorage understands the messages

		atEnd, contents, next, nextPut:

	and messages implemented in terms of them, such as nextPutAll:.  BinaryStorage
	specifically does not understand the character-oriented messages such as
	print: and store:, since each item in the stream is an arbitrary network of
	objects, not a character.

	BinaryStorage provides two special messages for reading and writing 
	collections of classes:

		bos nextPutClasses: classCollection
		classCollection := bos nextClasses

	nextPutClasses: sorts the classes into superclass order before writing them.  
	It writes out the same information as fileOut, i.e., (the equivalent of) the 
	class definition, all the method definitions (not including the source code), 
	and an initialize expression if appropriate.  Similarly, nextClasses has the 
	same effect as fileIn, except that the compiler is not required, and the method 
	source code is not loaded.
	"

	^self error: 'comment only'!

storageFormats
	"BOSS uses a compact, machine-independent binary data representation, 
	called a binary data stream (BDS).  

	A BDS consists of a stream of items, each starting with a one-byte tag 
	encoding the item's representation, and possibly its class as well.  The space 
	of tags is divided into standard tags, recognized by BinaryStorage, and policy 
	tags, used and recognized by BinaryStoragePolicy. 

	Standard items have three possible forms:
		- atom - the object is one of a set of frequently-used, typically-small 
			objects deserving an optimized representation: the tag encodes the 
			item's class, and possibly its value as well;
		- localId - the object is the same as some previously written object in 
			the net;
		- send - the object is the result of an arbitrary message to be evaluated
			at reading time.

	Note that there are no composite standard items: in BOSS, the 
	representation of composite items is a matter of policy, not mechanism.
	The minimal policy adds two more item types:
		- record - the object has internal structure, encoded in a sequence of 
			items;
		- dependents - the following object has dependents, which are stored 
			immediately following it.

	Finally, the standard policy adds an additional five types:
		- class reference - the object is a reference to a class, specified by name;
		- metaclass reference - the object is a reference to a metaclass, specified by 
			name;
		- global variable reference - the object is a reference to the Association for 
			a global variable such as the Transcript;
		- global object reference - the object is a global object such as the 
			Transcript;
		- local static reference - the object is a reference to the Association for a 
			static variable that is not global (class or pool variable).
	"

	^self error: 'comment only'!

storingMultipleObjectGroups
	"A common use of BOSS will be to store many relatively small objects on a 
	single file.  Since the overhead of storing checkable descriptions of classes is 
	substantial, BOSS provides a mechanism for storing a set of commonly 
	referenced objects (such as classes) only once, thereby initializing BOSS' table 
	of local object identifiers, and then creating a kind of simple checkpoint.  The 
	client can then restore the state to that checkpoint before writing or reading 
	individual object structures.  Note that this table is an in-memory object 
	structure: it is not actually stored on the file.

	To create a checkpoint, execute
		savedState := bos currentState

	At a later time, to return to the checkpoint, execute
		bos currentState: savedState

	A typical use of this facility might be the following:

		bos := BinaryStorage write: aFileStream.
		bos nextPut: wellKnownObjects.
		writeState := bos currentState.
			...
		bos currentState: writeState.
		net1Position := aFileStream position.
		bos nextPut: net1.
			...
		bos currentState: writeState.
		net2Position := aFileStream position.
		bos nextPut: net2.

	Then at some later time,

		bos := BinaryStorage read: bFileStream.
		bos next.  ''preload wellKnownObjects''
		readlState := bos currentState.
			...
		bos currentState: readState.
		bFileStream position: net1Position.
		net1 := bos next.
			...
		bos currentState: readState.
		bFileStream position: net2Position.
		net2 := bos next.

	Of course, the client is responsible for remembering net1Position and 
	net2Position.
	"

	^self error: 'comment only'!

whatIsAStoragePolicy
	"BOSS is implemented by two objects working together.  The BinaryStorage 
	provides generic facilities such as encoding and decoding of atomic objects, 
	bookkeeping for handling circular or multiple references to objects, and 
	parsing of stored objects being read.  Subclasses of BinaryStorage represent 
	different choices of how to handle these issues.  The BinaryStoragePolicy 
	decides where to 'cut' object nets when storing, by representing selected 
	objects by some kind of reference rather than by writing out their contents.  
	Subclasses of BinaryStoragePolicy represent different choices about cut 
	points and representation of external references.
	"

	^self error: 'comment only'! !

!BinaryStorage class methodsFor: 'private: private'!

streamContentsClass
	" Answer the class of the contents
	of the stream to be used for writing. "
	^ByteArray! !

!BinaryStorage class methodsFor: 'private: private-examples'!

example3Object
	^methodDict! !

BinaryStorage initialize!
