'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:01:51 pm'!

Object subclass: #Snefru
	instanceVariableNames: '
		inputBlockSize {UNKNOWN}
		outputBlockSize {UNKNOWN}
		maxWordCount {UNKNOWN}
		chunkSize {UNKNOWN}
		bufferSize {UNKNOWN}
		bufferSizeInWords {UNKNOWN}
		shiftTable {UNKNOWN}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Snefru'!



!Snefru methodsFor: 'Smalltalk instance creation'!

create
	"Initialize things that really should be manefest constants"
	
	inputBlockSize			_ 16.
	outputBlockSize			_ 4.	"4 or 8"
	maxWordCount			_ 16.
	chunkSize				_ inputBlockSize - outputBlockSize.
	bufferSize				_ 192	"3072".
	bufferSizeInWords		_ 336	"768".
	shiftTable				_ UInt32Array make: 4.
		shiftTable at: 0 put: 16.
		shiftTable at: 1 put: 8.
		shiftTable at: 2 put: 16.
		shiftTable at: 3 put: 24.
	
	^self! !

!Snefru methodsFor: 'Smalltalk hashing'!

{void} hash.quotedString: aHashArray {UInt4Ptr} with: aString {char star} with: aSecurityLevel {int}
	"Snefru 2 hash of a string"

	|  tCharStringPtr |
	
	"(tCharStringPtr _ CharPtr newZeroed: (aString size) + 1) putAll: aString."
	
	tCharStringPtr _ CharPtr withByteArray: ((ByteArray create: (aString size) + 1) replaceFrom: 1 to: aString size withString: aString startingAt: 1).
	
	self hash.ReadFunc.voidStar: aHashArray with: (FuncPtr class: ReadFunc message: #stringReadFunc:with:with:) with: tCharStringPtr with: aSecurityLevel.! !

!Snefru methodsFor: 'hashing'!

{void} hash.ReadFunc.voidStar: aHashArray {UInt4Ptr} with: aReadFunc {ReadFunc} with: aVoidP {void star} with: aSecurityLevel {int}
	"Snefru 2 hash of a string"

	|  breakSignal "i" buffer wordBuffer hashArray {UInt4"[16]"} bitCount {UInt4"[2]"} byteCount dataLoc hitEOF {boolean} |
	
	breakSignal _ Object errorSignal newSignalMayProceed: false.  		"Make this global????"
	
	buffer			_ CharPtr newZeroed: bufferSize.
	wordBuffer		_ UInt4Ptr withTypedPtr: buffer.
	hashArray		_ UInt4Ptr newZeroed: inputBlockSize.
	bitCount		_ UInt4Ptr newZeroed: 2.
	hitEOF			_ false.
	
	bitCount at: 0 put: 0.
	bitCount at: 1 put: 0.
	
	0 to: inputBlockSize - 1 do: [ :i {int} |
		hashArray at: i put: 0
	].
	
	byteCount _ 0.
	breakSignal handle: [:ex | ex returnWith: self] do: [
		[hitEOF not] whileTrue: [
			(byteCount ~= 0) ifTrue: [
				ErrAbort errAbort: 'Logic error near EOF'.
			].

			byteCount _ aReadFunc applyWith: aVoidP with: buffer with:bufferSize.
			(byteCount < 0) ifTrue: [
				ErrAbort errAbort: 'Error while reading from input.'.		"!!!!!!!! Can't test..."
			].
	
	"v"		(byteCount = 0) ifTrue: [breakSignal raise].
			(byteCount ~= bufferSize) ifTrue: [
				hitEOF _ true.			"Remember we saw EOF"
			].
			
			bitCount at: 1 put: ((bitCount at: 1) + (byteCount * 8)).
			((bitCount at: 1) < (byteCount * 8)) ifTrue: [
				bitCount at: 0 put: ((bitCount at: 0) + 1).
			].
			
			byteCount to: (bufferSize - 1) do: [ :i |
				buffer at: i put: 0.
			].
			
			"convertBytes (buffer, wordBuffer); equiv if not SUN byte order."
			
			dataLoc _ 0.
			
			[byteCount > 0] whileTrue: [
				((dataLoc + chunkSize) > bufferSize) ifTrue: [
					ErrAbort errAbort: 'logic error, buffer over run'
				].
				
				0 to: (chunkSize - 1) do: [ :i |
					hashArray at: (outputBlockSize + i) put: (wordBuffer at: (dataLoc + i)).
				].
				self hashNWith: hashArray with: inputBlockSize with: hashArray with: aSecurityLevel.
				
				dataLoc _ (dataLoc + chunkSize).
				
				byteCount _ (byteCount - (chunkSize * 4)).
			].
		].
	].
	
	0 to: (chunkSize - 1) do: [ :i {int} |
		hashArray at: (outputBlockSize + i) put: 0.
	].
	
	hashArray at: (inputBlockSize - 2) put: (bitCount at: 0).
	hashArray at: (inputBlockSize - 1) put: (bitCount at: 1).

	self hashNWith: aHashArray with: inputBlockSize with: hashArray with: aSecurityLevel.! !

!Snefru methodsFor: 'private: private hashing'!

{void} hashNWith: output {UInt4 vector "UInt4Ptr"} with: wordCount {int} with: input {UInt4 vector "UInt4Ptr"} with: localSecurityLevel {int}
	"General-case Snefru hash-a-chunk routine."
	self unimplemented.
	"|
		 mask			{UInt4}
		 block			{UInt4""[maxWordCount]"" vector var ""UInt4Ptr""}
		 sBoxEntry		{UInt4}
		 shift			{int}
		 ""i				{int}""
		 ""index			{int}""
		 next			{int}
		 last			{int}
		 ""byteInWord	{int}""
	|

	block _ UInt4Ptr newZeroed: maxWordCount.
	mask _ wordCount - 1.						""Assumes wordCount is power of 2""

	0 almostTo: wordCount do: [ :i {int} |
		block at: i put: (input at: i).
	].
	
	0 almostTo: localSecurityLevel do: [ :index {int} |
		0 almostTo: 4 do: [ :byteInWord {int} |
			0 almostTo: wordCount do: [ :i {int} |
				next _ (i + 1) bitAnd: mask.
				last _ (i + mask) bitAnd: mask.	""really (i-1)mod wordCount""
				sBoxEntry _ (StandardSBoxes at: ((2 * index) + ((i bitShift: -1) bitAnd: 1)) ) at: ((block at: i) bitAnd: 16rFF).
				block at: next put: ((block at: next) bitXor: sBoxEntry).
				block at: last put: ((block at: last) bitXor: sBoxEntry).
			].
			shift _ shiftTable at: byteInWord.
			0 almostTo: wordCount do: [ :i {int} |
				block at: i put: (
					((block at: i) bitShift: (shift negated)) bitOr:
					((block at: i) bitShift: (32 - shift))
				).
			].
		].
	].
	
	0 almostTo: outputBlockSize do: [ :i {int} |
		output at: i put: ((input at: i) bitXor: (block at: (mask - i))).
	]."! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

Snefru class
	instanceVariableNames: ''!



!Snefru class methodsFor: 'pseudoConstructors'!

{Snefru} make
	
	^Snefru create.! !