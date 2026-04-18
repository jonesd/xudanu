'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:49:18 pm'!

Object subclass: #CompiledCode
	instanceVariableNames: 'bytes misc firstLiteral secondLiteral source '
	classVariableNames: 'NormalFrameSize NPCMapErrorSignal SourceInfoCache '
	poolDictionaries: 'OpcodePool '
	category: 'Kernel-Methods'!
CompiledCode comment:
'Class CompiledCode is an abstract class that represents compiled code for HPS.  Subclasses represent compiled methods and compiled blocks.

Subclasses must implement:
	accessing
		homeMethod
	testing
		isBlockMethod

CompiledCode has three formats.
	Short - bytes and misc are SmallIntegers.
		Up to 6 bytes are in bytes[29:6] + misc[29:6],
		up to 2 literals are in firstLiteral + secondLiteral;
		misc[5] = 1 if this is a block method,
		misc[4] = 1 if frame needed,
		misc[3:2] = numArgs, misc[1:0] = numTemps.
	non-Short - bytes is a ByteArray, misc is an Array.
		The first element of bytes is a flag byte.
			Normal - flag is < 16r80.
				flag[6] = 1 if frame is likely to become hybrid,
				flag[5] = 1 if this is a block method,
				flag[4] = 1 if frame is needed,
				flag[3:2] = numArgs, flag[1:0] = numTemps.
				Code starts in bytes[2].
			Long - flag is >= 16r80.
				flag[6:5] = as for normal format,
				flag[4] = 1 if this refers to instance variables of a Context,
				flag[3] = 1 if this is an unwind method (BlockClosure>>valueOnUnwindDo:),
				flag[2] = 1 if this is a marked exception-handler propagate/handle method,
				flag[1:0] are unused;
				bytes[2] = numArgs, bytes[3] = numTemps,
				bytes[4] = frame size (0 means no frame).
				Code starts in bytes[5].

Compiled code for methods and blocks are represented by subclasses, CompiledMethod and CompiledBlock, even though there is a flag in the header to indicate this distinction for the benefit of the VM.

The source instance variable currently holds an integer, for backward compatibility.  This integer is a file index (index in SourceFiles -1) + a position in that file * 4.  Note that this holds the same information as the old 3-byte method trailer, but encoded differently, and without the limitation of 4 Mb per file.

Instance Variables:
	bytes	<SmallInteger | ByteArray>
	misc	<SmallInteger | Array>
	firstLiteral	<Object>
	secondLiteral	<Object>
	source	<nil | Integer>

Class Variables:
	NormalFrameSize	<SmallInteger>
	NPCMapErrorSignal	<Signal> N-PC not found in map
	SourceInfoCache <Association> between a CompiledMethod and a MethodNodeHolder

Pool Dictionary:
	OpcodePool	<Dictionary>'!


!CompiledCode methodsFor: 'source code management'!

cacheSourceInfo: sourceInfo
	"Save a reference to the receiver's current source information."

	SourceInfoCache _ Association key: self value: sourceInfo!

fileIndex
	"Answer 1 if the source code of the receiver is on the *.sources file
	and 2 if it is on the *.changes file.  If the receiver has no stored
	source code, answer 0.  This is not compatible with old CompiledMethod
	protocol."

	source == nil ifTrue: [^0].
	^source \\ 4 + 1!

filePosition
	"Answer the position of this method's source code
	on its file."

	source == nil ifTrue: [self error: 'This method has no stored source'].
	^source // 4!

getSource
	"Answer the source code for the receiver.  Answer nil if there are
	no source files specified in the global SourceFiles, or if this method
	has no stored source."

	SourceFiles == nil ifTrue: [^nil].
	self hasSource ifFalse: [^nil].
	^Cursor read
		showWhile: 
			[(RemoteString
				newFileNumber: self fileIndex
				position: self filePosition) string]!

getSourceForUserIfNone: aBlock
	"Answer the string corresponding to the source code for the argument.
	If source code is not available, answer the result of evaluating aBlock."

	Sensor leftShiftDown ifTrue: [^aBlock value].  "don't use the stored source"
	^self getSourceStringForUserIfNone: aBlock!

getSourceStringForUserIfNone: aBlock
	"Answer the string corresponding to the source code for the argument.
	If source code is not available, answer the result of evaluating aBlock."

	| newSource index | 
	newSource _ self getSource.
	newSource == nil ifTrue: [^aBlock value].  "no stored source"
	((newSource at: newSource size) isSeparator)
		ifTrue:
			[index _ newSource size. "tidy up for file out"
			[((newSource at: index) isSeparator)
				and: [index > 1]]
				whileTrue: [index _ index - 1].
			newSource _ newSource copyFrom: 1 to: index].
	^newSource!

hasSource
	"Answer whether there is a CompiledMethod that has source for the receiver."

	^self methodWithSource notNil!

putSource: sourceStr class: class category: catName inFile: fileIndex 
	"Print an expression that is a message to the argument, class, asking the
	class to accept the source code, sourceStr, as a method in category, catName.
	This is part of the format for writing descriptions of methods on files.
	If no sources are specified, i.e., SourceFile is nil, then do nothing.
	If the fileIndex is 1, print on *.sources;  if it is 2, print on *.changes."

	| file remoteString |
	SourceFiles == nil ifTrue: [^self].
	file _ SourceFiles at: fileIndex.
	class printCategoryChunk: catName on: file.
	file cr.
	remoteString _ 
		RemoteString
			newString: sourceStr
			onFileNumber: fileIndex
			toFile: file.
	file nextChunkPut: ' '; commit.
	self setSourcePosition: remoteString position inFile: fileIndex!

putSource: sourceStr inFile: fileIndex 
	"Store the source code for the receiver on an external file.
	If no sources are specified, i.e., SourceFile is nil, then do nothing.
	If the fileIndex is 1, print on *.sources;  if it is 2, print on *.changes."

	| file remoteString |
	SourceFiles == nil ifTrue: [^self].
	file _ SourceFiles at: fileIndex.
	file cr; nextPut: $!!; nextChunkPut: 'Behavior method'; cr.
	remoteString _ 
		RemoteString
			newString: sourceStr
			onFileNumber: fileIndex
			toFile: file.
	file nextChunkPut: ' '; commit.
	self setSourcePosition: remoteString position inFile: fileIndex!

setSourcePosition: position inFile: fileIndex 
	"Store the location of the source code for the receiver in the 
	receiver. The location consists of which source file (*.sources or 
	*.changes) and the position in that file."

	(fileIndex between: 1 and: 4)
		ifFalse: [^self error: 'invalid file number'].
	source _ position * 4 + (fileIndex - 1)!

sourceInfoIfCached
	"Answer the source of information for the receiver if it was 
	previously saved, otherwise answer nil."

	SourceInfoCache == nil ifTrue: [^nil].
	SourceInfoCache key == self ifTrue: [^SourceInfoCache value].
	^nil! !

!CompiledCode methodsFor: 'accessing'!

endPC
	"Answer a pointer to the end of the receiver."

	^self bytesSize!

fieldsTouched
	"Answer a Set of fields touched by this method."

	| scanner indexSet index |

	indexSet _ Set new.
	self withAllBlockMethodsDo:
		[:meth |
		scanner _ InstructionStream on: meth.
		scanner	
			scanFor: 
				[:x | 
				((index _ scanner peekForInstVarRead) notNil or:
				 [(index _ scanner peekForInstVarWrite) notNil])
					ifTrue: [indexSet add: index].
				false	"keep scanning"]].
	^indexSet!

frameSize
	"Answer the size of the literal frame for the receiver."

	self isShort ifTrue: [^(misc anyMask: 16) ifTrue: [NormalFrameSize] ifFalse: [0]].
	self isNormal ifTrue: [^((bytes at: 1) anyMask: 16) ifTrue: [NormalFrameSize] ifFalse: [0]].
	^bytes at: 4!

homeMethod
	"If this is the CompiledMethod for a block, answer the
	CompiledMethod for the enclosing method; otherwise
	answer this method."

	^self subclassResponsibility!

initialPC
	"Answer the initial pointer into the receiver's code."

	^1!

mclass
	"Answer the class in which this compiled code
	was compiled.  If not known, answer nil."

	^nil!

methodSize
	"Answer statistics about the receiver."

	^self methodSizeAvoiding: IdentitySet new!

numArgs
	"Answer the number of arguments required by the receiver."

	self isShort ifTrue: [^(misc bitShift: -2) bitAnd: 3].
	self isNormal ifTrue: [^((bytes at: 1) bitShift: -2) bitAnd: 3].
	^bytes at: 2!

numTemps
	"Answer the number of locals including both arguments and temps."

	^self numArgs + self numTempsOnly!

numTempsOnly
	"Answer the number of temps exclusive
	of arguments.  Unfortunately numTemps
	is established as meaning args + temps."

	self isShort ifTrue: [^misc bitAnd: 3].
	self isNormal ifTrue: [^(bytes at: 1) bitAnd: 3].
	^bytes at: 3!

withFrame
	"Answer a version of this method that
	is guaranteed to have a frame."

	self frameSize = 0 ifFalse: [^self].
	^self shallowCopy forceFrame! !

!CompiledCode methodsFor: 'accessing-bytes'!

byteAt: index
	"Answer the byte at position index."

	(bytes isInteger)  "self isShort"
		ifTrue:
			[index = 1 ifTrue: [^(bytes bitShift: -22) bitAnd: 16rFF].
			index = 2 ifTrue: [^(bytes bitShift: -14) bitAnd: 16rFF].
			index = 3 ifTrue: [^(bytes bitShift: -6) bitAnd: 16rFF].
			index = 4 ifTrue: [^(misc bitShift: -22) bitAnd: 16rFF].
			index = 5 ifTrue: [^(misc bitShift: -14) bitAnd: 16rFF].
			index = 6 ifTrue: [^(misc bitShift: -6) bitAnd: 16rFF].
			^self subscriptBoundsError: index].
	index <= 0 ifTrue: [^self subscriptBoundsError: index].
	^(bytes at: 1) < 16r80
		ifTrue: [bytes at: index + 1]
		ifFalse: [bytes at: index + 4]!

byteAt: index put: aByte
	"Store the argument aByte at position index in the method."

	"This is only used at the end of code generation to fix up block creation sequences.
	*** CompiledCode MUST BE IMMUTABLE ***
	or the execution mechanism will get confused."

	self isShort
		ifTrue:
			[index = 1 ifTrue: [bytes _ (bytes bitAnd: 16r3FC00000) + (aByte bitShift: 22).  ^aByte].
			index = 2 ifTrue: [bytes _ (bytes bitAnd: 16r3FC000) + (aByte bitShift: 14).  ^aByte].
			index = 3 ifTrue: [bytes _ (bytes bitAnd: 16r3FC0) + (aByte bitShift: 6).  ^aByte].
			index = 4 ifTrue: [misc _ (misc bitAnd: 16r3FC00000) + (aByte bitShift: 22).  ^aByte].
			index = 5 ifTrue: [misc _ (misc bitAnd: 16r3FC000) + (aByte bitShift: 14).  ^aByte].
			index = 6 ifTrue: [misc _ (misc bitAnd: 16r3FC0) + (aByte bitShift: 6).  ^aByte].
			^self subscriptBoundsError: index].
	index <= 0 ifTrue: [^self subscriptBoundsError: index].
	^(bytes at: 1) < 16r80
		ifTrue: [bytes at: index + 1 put: aByte]
		ifFalse: [bytes at: index + 4 put: aByte]!

bytes
	"Answer the bytes of this method."

	| index shortBytes | 
	self isShort
		ifTrue:
			["Extract the bytes from the header"
			index _ 6.
			[(self byteAt: index) between: OpNoOp and: OpNoOp + 3] whileTrue: [index _ index - 1].
			shortBytes _ ByteArray new: index.
			1 to: index do: [:i | shortBytes at: i put: (self byteAt: i)].
			^shortBytes].
	^bytes copyFrom: (self isLong ifTrue: [5] ifFalse: [2]) to: bytes size!

bytesIncludes: aByte
	"Answer true if aByte appears anywhere
	in the bytes of this method."

	bytes isInteger  "self isShort"
		ifTrue:
			[^((bytes bitShift: -22) bitAnd: 16rFF) = aByte or:
			 [((bytes bitShift: -14) bitAnd: 16rFF) = aByte or:
			  [((bytes bitShift: -6) bitAnd: 16rFF) = aByte or:
			   [((misc bitShift: -22) bitAnd: 16rFF) = aByte or:
			    [((misc bitShift: -14) bitAnd: 16rFF) = aByte or:
			     [((misc bitShift: -6) bitAnd: 16rFF) = aByte]]]]]]
		ifFalse:
			[(self isLong ifTrue: [4] ifFalse: [1]) to: bytes size do:
				[:i | (bytes at: i) = aByte ifTrue: [^true]].
			^false]!

bytesSize
	"Answer the size of the bytes."

	bytes isInteger  "self isShort"
		ifTrue:
			["Extract the bytes from the header"
			| size byte |
			size _ 6.
			[(byte _ self byteAt: size) >= OpNoOp and:
			 [byte <= (OpNoOp + 2)]]
				whileTrue: [size _ size - 1].
			^size].
	^bytes size -
		((bytes at: 1) >= 16r80 "self isLong"
			ifTrue: [4] ifFalse: [1])! !

!CompiledCode methodsFor: 'accessing-literals'!

{Collection of: Association} allLiteralAssociations

	| result {Collection of: Association} |
	result _ OrderedCollection new.
	self allLiteralsDo: [:lit |
		(lit isKindOf: Association)
			ifTrue: [result add: lit]].
	^result!

{void} allLiteralsDo: aBlock
	"Do aBlock for each non-code literal, but walk into contained code literals trasitively to find them"
	
	self literalsDo: [:lit |
		(lit isKindOf: CompiledCode)
			ifTrue: [lit allLiteralsDo: aBlock]
			ifFalse: [aBlock value: lit]]!

includesLiteral: lit
	"Answer whether the method includes the literal lit."

	"*** This is not quite right.  It includes system-
	generated literals: BlockClosures,
	and the superclass for super sends.  ***"

	firstLiteral == nil ifTrue: [^false].  "no literals"
	firstLiteral == lit ifTrue: [^true].
	secondLiteral == nil ifTrue: [^false].  "just one literal"
	secondLiteral == lit ifTrue: [^true].
	self isShort ifTrue: [^false].  "two literals"
	1 to: misc size do: [:i | (misc at: i) == lit ifTrue: [^true]].
	^false!

literalAt: index
	firstLiteral isNil ifTrue: [self error: 'No literals'.  ^nil].
	index = 1 ifTrue: [^firstLiteral].
	secondLiteral isNil ifTrue: [self error: 'Only one literal'.  ^nil].
	index = 2 ifTrue: [^secondLiteral].
	self isShort ifTrue: [self error: 'Only two literals'.  ^nil].
	^misc at: index - 2!

literalAt: index put: lit
	"This is only used during code generation
	to replace a copying block by a full block,
	in case a subsequent store requires it."
	firstLiteral isNil ifTrue: [self error: 'No literals'.  ^nil].
	index = 1 ifTrue: [^firstLiteral _ lit].
	secondLiteral isNil ifTrue: [self error: 'Only one literal'.  ^nil].
	index = 2 ifTrue: [^secondLiteral _ lit].
	self isShort ifTrue: [self error: 'Only two literals'.  ^nil].
	^misc at: index - 2 put: lit!

literals
	firstLiteral isNil ifTrue: [^#()].  "no literals"
	secondLiteral isNil ifTrue: [^Array with: firstLiteral].  "just one literal"
	self isShort ifTrue: [^Array with: firstLiteral with: secondLiteral].  "two literals"
	^(Array with: firstLiteral with: secondLiteral) , misc!

literalsDo: aBlock
	firstLiteral == nil ifTrue: [^self].  "no literals"
	aBlock value: firstLiteral.
	secondLiteral == nil ifTrue: [^self].  "just one literal"
	aBlock value: secondLiteral.
	self isShort ifTrue: [^self].  "two literals"
	misc do: aBlock!

{IdentitySet of: Symbol} literalSymbols
	
	| result {IdentitySet of: Symbol} |
	result _ IdentitySet new.
	self literals do: [:el |
		result addAll: el literalSymbols].
	^result!

messages
	"Answer a Set of all the message selectors sent by this method."

	| scanner selectorSet selector |
	selectorSet _ Set new.
	self withAllBlockMethodsDo:
		[:meth |
		scanner _ InstructionStream on: meth.
		scanner	
			scanFor: 
				[:byte | 
				selector _ scanner peekForSelector.
				selector == nil ifFalse: [selectorSet add: selector].
				false	"keep scanning"]].
	^selectorSet!

numLiterals
	firstLiteral isNil ifTrue: [^0].  "no literals"
	secondLiteral isNil ifTrue: [^1].  "just one literal"
	self isShort ifTrue: [^2].  "two literals"
	^2 + misc size! !

!CompiledCode methodsFor: 'accessing-PC map'!

nFromVPC: intVPC
	"Convert a V-PC to an N-PC.  The V-PC is a positive
SmallInteger, an index in the receiver's bytes; the N-PC is a
negative SmallInteger, the negative of a machine PC offset within the
translated code.  Fail if intVPC is not a positive SmallInteger, or is
out of range, or if there is no N-PC corresponding to the V-PC."
	<primitive: 520>
	^self error: 'V-PC not found in map'!

nFromVPCnoFail: intVPC
	"Convert a V-PC to an N-PC.
	Return nil if intVPC is not a positive SmallInteger, or is
	out of range, or if there is no N-PC corresponding to the V-PC."
	<primitive: 520>
	^nil!

vFromNPC: intNPC
	"Convert an N-PC to a V-PC, the inverse of nFromVPC.
Fail if intNPC is not a negative SmallInteger, or is out of range, or if
there is no V-PC corresponding to the N-PC."
	<primitive: 521>
	^CompiledCode nPCMapErrorSignal raise! !

!CompiledCode methodsFor: 'testing'!

isBlockMethod
	"Answer whether this is the compiled
	code for a block."
	^self subclassResponsibility!

isLong
	^self isShort not and: [(bytes at: 1) >= 16r80]!

isMarked
	"Answer true if method is marked."

	^false!

isMarkedForHandle
	"Answer true if marked for handle."

	^false!

isMarkedForPropagate
	"Answer true if marked for propagate."

	^false!

isMarkedForUnwind
	"Answer true if marked for unwind."

	^false!

isNormal
	^self isShort not and: [(bytes at: 1) < 16r80]!

isQuick
	^self frameSize = 0!

isShort
	^bytes isInteger!

needsHybridFrame
	self isShort ifTrue: [^false].
	^bytes first anyMask: 64!

readsField: varIndex 
	"Answer whether the receiver loads the instance variable indexed
	by the argument."

	| scanner |
	self withAllBlockMethodsDo:
		[:meth |
		scanner _ InstructionStream on: meth.
		(scanner scanFor: [:byte | scanner peekForInstVarRead = varIndex])
			ifTrue: [^true]].
	^false!

refersToLiteral: aLiteral
	"Answer true if this method (or any submethod)
	refers to the given literal.  We duplicate the code
	of literalsDo: for speed."

	firstLiteral == nil ifTrue: [^false].  "no literals"
	(firstLiteral refersToLiteral: aLiteral) ifTrue: [^true].
	secondLiteral == nil ifTrue: [^false].  "just one literal"
	(secondLiteral refersToLiteral: aLiteral) ifTrue: [^true].
	self isShort ifTrue: [^false].  "two literals"
	1 to: misc size do: [:i | ((misc at: i) refersToLiteral: aLiteral) ifTrue: [^true]].
	^false!

{BooleanVar} refersTowardsLiteral: aLiteral
	"Answer true if this method (or any submethod)
	refers to the given literal.  We duplicate the code
	of literalsDo: for speed."

	firstLiteral == nil ifTrue: [^false].  "no literals"
	(firstLiteral refersTowardsLiteral: aLiteral) ifTrue: [^true].
	secondLiteral == nil ifTrue: [^false].  "just one literal"
	(secondLiteral refersTowardsLiteral: aLiteral) ifTrue: [^true].
	self isShort ifTrue: [^false].  "two literals"
	1 to: misc size do: [:i | 
		((misc at: i) refersTowardsLiteral: aLiteral) ifTrue: [^true]].
	^false!

returnsStaticVariable
	"If this method just returns the value of
	a static variable, answer the Association,
	otherwise answer nil."
	^((self byteAt: 1) = OpLoadStatic and:
	 [(self byteAt: 2) = OpReturn])
		ifTrue: [self literalAt: 1]
		ifFalse: [nil]!

sendsSpecialSelector: index
	"Answer whether the receiver sends
	the special selector with the given index."

	| scanner index0 |
	index0 _ index - 1.
	self withAllBlockMethodsDo:
		[:meth |
		"Make a quick check"
		((meth bytesIncludes: index0) or: [index0 <= MaxShortSpecialSend and: [(meth bytesIncludes: OpSpecialSend + index0) or: [index0 = 0 and: [meth bytesIncludes: OpSendAdd1]]]]) ifTrue:
			[scanner _ InstructionStream on: meth.
			(scanner scanFor: [:byte | scanner peekForSpecialSelector: index0])
				ifTrue: [^true]]].
	^false!

usesContextInstVars
	self isLong ifFalse: [^false].
	^bytes first anyMask: 16!

writesField: varIndex 
	"Answer whether the receiver stores into the instance variable indexed
	by the argument."

	| scanner |
	self withAllBlockMethodsDo:
		[:meth |
		scanner _ InstructionStream on: meth.
		(scanner scanFor: [:byte | scanner peekForInstVarWrite = varIndex])
			ifTrue: [^true]].
	^false! !

!CompiledCode methodsFor: 'enumerating'!

withAllBlockMethodsDo: aBlock
	"Recursively enumerate the collection of methods
	(including block methods) that are included in
	this method."

	| cl |
	aBlock value: self.
	self literalsDo:
		[:lit |
		cl _ lit class.
		(cl == CompiledBlock or: [cl == CompiledLocalBlock])
			ifTrue: [lit withAllBlockMethodsDo: aBlock]
			ifFalse:
				[cl == BlockClosure
					ifTrue: [lit method withAllBlockMethodsDo: aBlock]]]! !

!CompiledCode methodsFor: 'comparing'!

= aMethod

	self == aMethod ifTrue: [^true].
	self class = aMethod class ifFalse: [^false].
	bytes = aMethod bytesInstVar ifFalse: [^false].
	self isShort ifTrue:
		[misc = aMethod miscInstVar ifFalse: [^false]].
	self numLiterals = aMethod numLiterals ifFalse: [^false].
	1 to: self numLiterals do:
		[:litIndex | | lit |
		((lit _ self literalAt: litIndex) class == Association
				ifTrue:	[lit == (aMethod literalAt: litIndex)]
				ifFalse:	[lit = (aMethod literalAt: litIndex)])
			ifFalse:	[^false]].
	^true!

hash
	^bytes hash bitXor: misc hash! !

!CompiledCode methodsFor: 'printing'!

printSymbolicOn: aStream
	"Print a symbolic representation of my contents
	on aStream." 

	aStream nextPutAll:
		(self isShort ifTrue: ['short'] ifFalse: [self isLong ifTrue: ['long'] ifFalse: ['normal']]).
	aStream space.
	self class printOn: aStream.
	aStream nextPutAll: ' numArgs='; print: self numArgs.
	aStream nextPutAll: ' numTemps='; print: self numTempsOnly.
	aStream nextPutAll: ' frameSize='; print: self frameSize.
	aStream cr; cr.
	aStream nextPutAll: 'literals: ('.
	self literalsDo: [:lit |
		(lit isMemberOf: Association)
			ifTrue: [aStream nextPut: ${; nextPutAll: lit key; nextPut: $}]
			ifFalse: [lit printOn: aStream].
		aStream space].
	aStream nextPut: $).
	aStream cr; cr.
	(InstructionPrinter on: self) printInstructionsOn: aStream!

symbolic
	"Answer a symbolic representation of my contents
	as a String."

	| aStream |
	aStream _ (String new: 400) writeStream.
	self printSymbolicOn: aStream.
	^aStream contents!

who 
	"Answer an Array of the class in which the receiver is defined and
	the selector to which it corresponds. "

	| sel |
	Smalltalk allBehaviorsDo:
		[:class |
		sel _ class selectorAtMethod: self ifAbsent: [nil].
		sel notNil ifTrue: [^Array with: class with: sel]]! !

!CompiledCode methodsFor: 'fileIn/Out'!

resolveSource
	"Put the source code onto the changes file"

	source == nil
		ifFalse:	[self putSource: source inFile: 2].!

storeBinaryOn: stream 
	"Put a binary representation of the receiver into stream."

	| codePtr |
	codePtr _ source.
	[source == nil
		ifFalse:	[source _ self getSource].
	super storeBinaryOn: stream]
		valueNowOrOnUnwindDo: [source _ codePtr]! !

!CompiledCode methodsFor: 'private: private'!

bytesInstVar
	^bytes!

compare: aMethod mapping: dict
	"Compare against aMethod.  dict is a correspondence
	between block methods in me and block methods in
	aMethod's ancestors."
	self == aMethod ifTrue: [^true].
	self class = aMethod class ifFalse: [^false].
	bytes = aMethod bytesInstVar ifFalse: [^false].
	self isShort ifTrue:
		[misc = aMethod miscInstVar ifFalse: [^false]].
	self numLiterals = aMethod numLiterals ifFalse: [^false].
	self literals with: aMethod literals do:
		[:mine :its |
		mine class = its class ifFalse: [^false].
		(mine isKindOf: CompiledCode)
			ifTrue:
				[(dict includesKey: mine)
					ifTrue:
						[(dict at: mine) == its ifFalse: [^false]]
					ifFalse:
						[dict at: mine put: its.
						(mine compare: its mapping: dict) ifFalse: [^false]]]
			ifFalse:
				[(mine isMemberOf: BlockClosure)
					ifTrue:
						[dict at: mine method put: its method.
						(mine method compare: its method mapping: dict) ifFalse: [^false]]
					ifFalse: [mine = its ifFalse: [^false]]]].
	^true!

forceFrame
	"Force this method to have a frame. 
	This is only done after a shallowCopy."
	self isShort
		ifTrue: 
			[misc _ misc bitOr: 16.
			^self].
	self isNormal
		ifTrue: 
			[bytes _ bytes copy.
			bytes at: 1 put: ((bytes at: 1) bitOr: 16).
			^self].
	"self isLong"
	bytes _ bytes copy.
	bytes at: 4 put: (self numTemps + 1 max: NormalFrameSize).
	^self!

forceLong
	"Force this method to be in long format.
	This is only done before the method
	is ever executed."
	| tempBytes |
	self isLong ifTrue: [^self].
	" Now we know self isShort or self isNormal. "
	tempBytes _ (ByteArray
			with: 16r80 + (self needsHybridFrame ifTrue: [16r40] ifFalse: [0]) +
				(self isBlockMethod ifTrue: [16r20] ifFalse: [0])
			with: self numArgs
			with: self numTempsOnly
			with: self frameSize) ,
		self bytes.
	self isShort ifTrue: [misc _ #()].  "no extra literals"
	bytes _ tempBytes!

methodSizeAvoiding: mset
	"Accumulate statistics"
	| objs space bsize lsize lms |
	(mset includes: self)
		ifTrue:  "avoid visiting method twice"
			[^#(0 0 0 0)].
	mset add: self.
	objs _ 1.
	space _ self class instSize * 4.
	self isShort
		ifTrue: [lsize _ bsize _ 0]
		ifFalse:
			[(lsize _ misc size * 4) = 0 ifFalse:  "all empty literal arrays are shared"
				[objs _ objs + 1].
			objs _ objs + 1.  bsize _ bytes size].
	"Account for block methods"
	self literalsDo:
		[:lit |
		lms _ nil.
		(lit isMemberOf: self class)
			ifTrue: [lms _ lit methodSizeAvoiding: mset]
			ifFalse:
				[(lit isMemberOf: BlockClosure)
					ifTrue:
						[objs _ objs + 1.
						space _ space + lit class instSize * 4.
						lms _ lit method methodSizeAvoiding: mset]].
		lms isNil ifFalse:
			[objs _ objs + lms first.
			space _ space + (lms at: 2).
			lsize _ lsize + (lms at: 3).
			bsize _ bsize + (lms at: 4)]].
	^Array with: objs with: space with: lsize with: bsize!

methodWithSource
	"Answer the CompiledMethod (this one, or,
	if a block, an outer one) which supplies the
	source code for this method.  If none,
	answer nil."

	source notNil ifTrue: [^self].
	^nil!

miscInstVar
	^misc!

shortBytes: b flags: flags
	"The bytes are short enough that they
	fit in a short method.  Repack them into
	the two header words."
	| copy |
	copy _ ByteArray new: 6 withAll: OpNoOp.
	copy replaceFrom: 1 to: b size with: b.
	bytes _ ((((self signExtend: (copy at: 1)) bitShift: 8) + (copy at: 2) bitShift: 8) + (copy at: 3) bitShift: 6).
	misc _ ((((self signExtend: (copy at: 4)) bitShift: 8) + (copy at: 5) bitShift: 8) + (copy at: 6) bitShift: 6) + flags.
	^true!

signExtend: byte
	^byte >= 16r80 ifTrue: [byte - 16r100] ifFalse: [byte]! !

!CompiledCode methodsFor: 'private: private-initialize-release'!

initBytes: b literals: l numArgs: na numTemps: nt maxDepth: m needsFrame: nf inBlock: bf hybrid: hf forContext: cf
	| lsize flags |
	lsize _ l size.
	lsize = 0
		ifTrue:
			[firstLiteral _ secondLiteral _ nil.  misc _ #()]
		ifFalse:
			[firstLiteral _ l first.
			lsize = 1
				ifTrue:
					[secondLiteral _ nil.  misc _ #()]
				ifFalse:
					[secondLiteral _ l at: 2.
					misc _ lsize <= 2 ifTrue: [#()] ifFalse: [l asArray copyFrom: 3 to: l size]]].
	"Check for long format required"
	flags _ (hf ifTrue: [64] ifFalse: [0]) + (bf ifTrue: [32] ifFalse: [0]).
	(na > 3 or: [nt > 3 or: [m > NormalFrameSize or: [cf]]])
		ifTrue:
			[cf ifTrue: [flags _ flags + 16].
			bytes _ (ByteArray with: 16r80 + flags with: na with: nt with: m) , b.
			^self].
	"Check if short format is possible"
	flags _ flags + (nf ifTrue: [16] ifFalse: [0]) + (na bitShift: 2) + nt.
	(flags < 64 and: [b size <= 6 and: [lsize <= 2]])
		ifTrue:
			[self shortBytes: b flags: flags.
			^self].
	"Use normal format"
	bytes _ (ByteArray with: flags) , b.
	^self! !

!CompiledCode methodsFor: 'backward compatibility'!

at: byteIndex
	^self byteAt: byteIndex!

scanFor: specialByte
	^false! !

!CompiledCode methodsFor: 'copying'!

deepCopy
	"Answer a copy of the receiver with its own copy of each instance 
	variable. This doesn't make sense for CompiledCode."

	^self deepCopyError! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

CompiledCode class
	instanceVariableNames: ''!


!CompiledCode class methodsFor: 'class initialization'!

initialize
	"CompiledCode initialize"
	| es |
	NormalFrameSize _ 12.
	es _ Object errorSignal.
	NPCMapErrorSignal _ es newSignal 
		notifierString: 'N-PC not found in map';
		nameClass: self message: #nPCMapErrorSignal.! !

!CompiledCode class methodsFor: 'statistics'!

methodsForClass: cl selector: sym
	| meth |
	meth _ Compiler compileClass: cl selector: sym.
	^meth isNil
		ifTrue: [#()]
		ifFalse: [meth withAllBlockMethods]! !

!CompiledCode class methodsFor: 'signal access'!

nPCMapErrorSignal

	^NPCMapErrorSignal! !

!CompiledCode class methodsFor: 'fileIn/Out'!

readBinaryFrom: stream tag: tag
	"Answer object appearing next in stream."

	| newObject |
	newObject _ super readBinaryFrom: stream tag: tag.
	newObject resolveSource.
	^newObject! !

CompiledCode initialize!
