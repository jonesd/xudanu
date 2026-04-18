'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 24 July 1995 at 7:59:06 pm'!

((CxxSystemOrganization tree childNamed: 'utility') ~= nil) ifTrue: [
	(CxxSystemOrganization tree childNamed: 'utility') destroyFiles]!

Object subclass: #ErrAbort
	instanceVariableNames: ''
	classVariableNames: 'ErrorInSnefruSignal {UNKNOWN} '
	poolDictionaries: ''
	category: 'Xanadu-Snefru'!


"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

ErrAbort class
	instanceVariableNames: ''!



!ErrAbort class methodsFor: 'accessing'!

{void} errAbort: msg {char star}

	#cerr << msg << '
'.
	self blast.ERROR.U.IN.U.SNEFRU raise.! !

!ErrAbort class methodsFor: 'exceptions: exceptions'!

blast.ERROR.U.IN.U.SNEFRU
	ErrorInSnefruSignal == nil ifTrue: [ErrorInSnefruSignal _ Signal new].
	ErrorInSnefruSignal notifierString: 'Error in Snefru'.
	^ErrorInSnefruSignal! !Object subclass: #ReadFunc
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Snefru'!


"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

ReadFunc class
	instanceVariableNames: ''!



!ReadFunc class methodsFor: 'accessing'!

{int var} stringReadFunc: param {void star} with: buffer {char star} with: bufSize {unsigned int}
	"Pseudo read() function for reading from strings."

	| src {char star vector} dst {char star} i {int unsigned var} |

	src _ param.
	dst _ buffer clone.
	i _ 0.
	[(i < bufSize) and: [src at ~= (0 asCharacter)]] whileTrue: [
		dst postInc put: ((src postInc at) asInteger).
		i _ i+1
	].
	
	^i! !Heaper subclass: #SnarfHandle
	instanceVariableNames: '
		mySnarfID {UInt4}
		myContents {char star}
		myUrdi {Urdi}
		isWritable {BooleanVar}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Urdi'!

(SnarfHandle getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!SnarfHandle methodsFor: 'accessing'!

{char star} getDataP
	^myContents!

{Int4} getDataSize
	^myContents count!

{SnarfID} getSnarfID
	^mySnarfID!

{BooleanVar} isWritable
	^isWritable!

{void} makeWritable
	isWritable _ true!

{SnarfID} snarfID
	^mySnarfID!

{void} thaw
	"Release the memory buffer locked into place for this snarfHandle."
	
	self unimplemented.
	isWritable ifTrue: [myUrdi writeHandle: mySnarfID with: myContents].
	myUrdi releaseHandle: mySnarfID.! !

!SnarfHandle methodsFor: 'data manipulation'!

{void} at: index {Int32} put32: word {Int32}
	"Store the supplied word into the snarf starting at index.  Put the high byte first."

	isWritable assert: 'Must be writable'.
	myContents at: index storeUInt: (word bitShiftRight: 24).
	myContents at: index+1 storeUInt: ((word bitShiftRight: 16) bitAnd: 255).
	myContents at: index+2 storeUInt: ((word bitShiftRight: 8) bitAnd: 255).
	myContents at: index+3 storeUInt: (word bitAnd: 255).!

{Int32} get32: index {Int32} 
	"Return the Int4 represented by the 4 bytes starting at index, high byte first.  This must return a negative number when appropriate."

	| guts {String} result {Int32} |
	guts _ myContents gutsOf.
	result _ guts basicAt: index + 1.
	result _ (result bitShift: 8) + (guts basicAt: index + 2).
	result _ (result bitShift: 8) + (guts basicAt: index + 3).
	result _ (result bitShift: 8) + (guts basicAt: index + 4).
	^result!

{void} moveBytes: start {Int4} with: newStart {Int4} with: nBytes {Int4}
	isWritable assert: 'Must be writable'.
	myContents at: newStart storeMany: myContents with: nBytes with: start! !

!SnarfHandle methodsFor: 'printing'!

{void} printOn: oo {ostream reference}
	oo << self getCategory name << '(' << mySnarfID << ')'! !

!SnarfHandle methodsFor: 'protected: destruct'!

{void} destruct
	"When a handle keeping a snarf in memory is destroyed, the snarf can then move around or go off to disk."

	isWritable ifTrue: [myUrdi writeHandle: mySnarfID with: myContents].
	myUrdi releaseHandle: mySnarfID.
	super destruct! !

!SnarfHandle methodsFor: 'create'!

create: snarfID {SnarfID} with: contents {UInt32Array} with: urdi {Urdi}
	super create.
	mySnarfID _ snarfID.
	myContents _ contents.
	myUrdi _ urdi.
	isWritable _ false! !Tester subclass: #SnarfTester
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Urdi'!

(SnarfTester getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #(COPY boot ); yourself)!

!SnarfTester methodsFor: 'testing'!

{void} allTestsOn: oo {ostream reference}
	"SnarfTester runTest."
	self testAllocationsOn: oo.!

{void} binaryCheck: a {XnRegion} with: b {XnRegion}
	| anb {XnRegion} amb {XnRegion} aub {XnRegion} |
	anb _ a intersect: b.
	(anb isEqual: (b intersect: a)) assert: 'intersect test failed.'.
	(anb isSubsetOf: a) assert: 'intersect/subset test failed.'.
	(anb isSubsetOf: b) assert: 'intersect/subset test failed.'.

	(a intersects: b) == anb isEmpty not assert: 'intersects test failed.'.
	amb _ a minus: b.
	(amb intersects: b) not assert: 'minus/intersect test failed.'.
	(amb isSubsetOf: a) assert: 'minus/subset test failed.'.
	
	aub _ a unionWith: b.
	(aub isEqual: (b unionWith: a)) assert: 'unionWith test failed.'.
	(a isSubsetOf: aub) assert: 'union/subset test failed.'.
	(b isSubsetOf: aub) assert: 'union/subset test failed.'.
	
	(((a isSubsetOf: b) and: [b isSubsetOf: a]) == (a isEqual: b)) assert: 'subset/equals test failed.'.!

{void} testAllocationsOn: oo {ostream reference}
	"packer _ snarfPacker create: UrdiVew create."
	| handle handler index |
	handle _ SnarfHandle create: 1 with: 5000.
	handler _ SnarfHandler create: handle.
	index _ handler allocate: 100.
	(handler refit: index with: 1000) assert: 'refit failed'.
	(handler refit: index with: 10) assert: 'refit failed'.
	(handler refit: index with: IntegerVar0) assert: 'refit failed'.!

{void} testBinaryRegionOpsOn: oo {ostream reference}
	myExampleRegions stepper forEach: [:one {XnRegion} |
		myExampleRegions stepper forEach: [:two {XnRegion} |
			one asOop <= two asOop ifTrue:
				[[oo << 'checking binary ops of ' << one << ' and ' << two << '
'] translateOnly. "smalltalk runs out of space"
				self binaryCheck: one with: two]]].
	oo << 'binary regions tests succeeded
'!

{void} testUnaryRegionOpsOn: oo {ostream reference}
	myExampleRegions stepper forEach: [:one {XnRegion} |
		[oo << 'checking unary ops of ' << one << '
'] translateOnly. "smalltalk runs out of space"
		self unaryCheck: one].
	oo << 'unary regions tests succeeded
'!

{void} unaryCheck: a {XnRegion}
	(a isEqual: a) assert: 'identity test failed.'.
	a isEmpty not == (a intersects: a) assert: 'intersects test failed.'.
	(a minus: a) isEmpty assert: 'self minus/isEmpty failed.'.
	(a isSubsetOf: a) assert: 'self subset test failed.'.
	((a intersect: a) isEqual: a) assert: 'intersect/isEqual test failed.'.
	a isFull == a complement isEmpty assert: 'infinity inverse test failed.'.
	(a intersect: a complement) isEmpty assert: 'intersect/complement test failed.'.
	((a minus: a complement) isEqual: a) assert: 'minus/complement test failed.'.
	(a complement complement isEqual: a) assert: 'double complement test failed.'.
	(a unionWith: a complement) isFull assert: 'union/complement test failed.'.! !

!SnarfTester methodsFor: 'protected: accessing'!

{ImmuSet of: XnRegion} exampleRegions
	^myExampleRegions! !

!SnarfTester methodsFor: 'protected: creation'!

create: name {char star}
	super create: name.
	myExampleRegions _ NULL.! !

!SnarfTester methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.! !Object subclass: #Snefru
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
	
	^Snefru create.! !Tester subclass: #SnefruTester
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Testing'!

(SnefruTester getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #(COPY boot ); yourself)!

!SnefruTester methodsFor: 'running tests'!

{void} allTestsOn: aStream {ostream reference} 
	"SnefruTester runTest: #allTestsOn:"
	"SnefruTester allTestsOn: cerr"

	aStream << '
Running all Snefru tests.
Test 1
'.
	self test1On: aStream.
	aStream << '
Test 2
'.
	self test2On: aStream! !

!SnefruTester methodsFor: 'testing'!

{void} test1On: aStream {ostream reference} 
	"Time millisecondsToRun: [self runTest: #test1On:] "
	"Time millisecondsToRun: [self test1On: cerr] "
	"should print: 'result = E6997849 44ED68A1 C762EA1E 90C77967' on System Transcript"

	"test creation"
	| tSnefru {Snefru vector var} hashBuffer {char vector} tLF {char var} |
	
	aStream << 'Doing test 1.  See IntegerTableTester for samples.
'.
	tSnefru _ Snefru make.
	tLF _ 'x'.
	tLF at: 1 put: (Character lf).
	hashBuffer _ UInt4Ptr newZeroed: 4.
	tSnefru hash.quotedString: hashBuffer with: '123456789' , tLF with: 2.

	aStream << 'result ='.
	0 almostTo: 4 do:
			[ :i {int} | aStream << ' '. (hashBuffer at: i) printOn: aStream base: 16.].
	aStream << '
'!

{void} test2On: aStream {ostream reference} 
	"Time millisecondsToRun: [self runTest: #test2On:] "

	"test creation"
	| tSnefru {Snefru vector var} hashBuffer {char vector} tLF {char var} |

	aStream << 'Doing test 2.  See IntegerTableTester for samples.
'.
	tSnefru _ Snefru make.
	tLF _ 'x'.
	tLF at: 1 put: (Character lf).
	hashBuffer _ UInt4Ptr newZeroed: 4.
	tSnefru hash.quotedString: hashBuffer with: '123456789' , tLF ,  'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa' with: 2.

	aStream << 'result ='.
	0 almostTo: 4 do:
			[ :i {int} | aStream << ' '. (hashBuffer at: i) printOn: aStream base: 16.].
	aStream << '
'! !

!SnefruTester methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

SnefruTester class
	instanceVariableNames: ''!

(SnefruTester getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #(COPY boot ); yourself)!

!SnefruTester class methodsFor: 'running tests'!

{void} allTestsOn: aStream {ostream reference} 
	"SnefruTester runTest: #allTestsOn:"
	"SnefruTester allTestsOn: cerr"

	aStream << '
Running all Snefru tests.
Test 1
'.
	self test1On: aStream.
	aStream << '
Test 2
'.
	self test2On: aStream! !

!SnefruTester class methodsFor: 'testing'!

{void} test1On: aStream {ostream reference} 
	"Time millisecondsToRun: [self runTest: #test1On:] "
	"Time millisecondsToRun: [self test1On: cerr] "
	"should print: 'result = E6997849 44ED68A1 C762EA1E 90C77967' on System Transcript"

	"test creation"
	| tSnefru {Snefru vector var} hashBuffer {char vector} tLF {char var} |
	
	aStream << 'Doing test 1.  See IntegerTableTester for samples.
'.
	tSnefru _ Snefru make.
	tLF _ 'x'.
	tLF at: 1 put: (Character lf).
	hashBuffer _ UInt4Ptr newZeroed: 4.
	tSnefru hash.quotedString: hashBuffer with: '123456789' , tLF with: 2.

	aStream << 'result ='.
	0 almostTo: 4 do:
			[ :i {int} | aStream << ' '. (hashBuffer at: i) printOn: aStream base: 16.].
	aStream << '
'!

{void} test2On: aStream {ostream reference} 
	"Time millisecondsToRun: [self runTest: #test2On:] "

	"test creation"
	| tSnefru {Snefru vector var} hashBuffer {char vector} tLF {char var} |

	aStream << 'Doing test 2.  See IntegerTableTester for samples.
'.
	tSnefru _ Snefru make.
	tLF _ 'x'.
	tLF at: 1 put: (Character lf).
	hashBuffer _ UInt4Ptr newZeroed: 4.
	tSnefru hash.quotedString: hashBuffer with: '123456789' , tLF ,  'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa' with: 2.

	aStream << 'result ='.
	0 almostTo: 4 do:
			[ :i {int} | aStream << ' '. (hashBuffer at: i) printOn: aStream base: 16.].
	aStream << '
'! !Heaper subclass: #Urdi
	instanceVariableNames: '
		myStream {void star}
		myHandles {MuArray of: SnarfHandle}
		myStageCount {UInt4}
		mySnarfCount {UInt4}
		mySnarfSize {UInt4}'
	classVariableNames: '
		CachedData {UNKNOWN} 
		CachedID {UNKNOWN} '
	poolDictionaries: ''
	category: 'Xanadu-Urdi'!

(Urdi getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!Urdi methodsFor: 'accessing'!

{Int4} getDataSizeOfSnarf: snarf {SnarfID}
	^mySnarfSize!

{UrdiView} makeReadView
	^self makeWriteView!

{UrdiView} makeWriteView
	^UrdiView create: self!

{Int4} usableSnarfs
	^mySnarfCount!

{Int4} usableStages
	^myStageCount! !

!Urdi methodsFor: 'private: private'!

{void} commitWrite
	| stpr {TableStepper} |
	(stpr _ myHandles stepper) forEach:  
		[:handle {SnarfHandle} |
		self positionStream: stpr index.
		myStream nextPutAll: handle getDataP gutsOf].
	myStream flush. 
	"myHandles destroy.
	myHandles _ IntegerTable make: myStageCount"!

{void} destruct
	self commitWrite.
	CachedID _ CachedData _ nil.
	myStream close.
	super destruct.!

{SnarfHandle} eraseHandle: snarfID {SnarfID}
	| handle {SnarfHandle} |
	snarfID < self usableSnarfs assert: 'nonexistent snarf'.
	handle _ SnarfHandle 
				create: snarfID 
				with: (UInt8Array make: mySnarfSize) 
				with: self.
	handle makeWritable.
	^handle!

{SnarfHandle} getHandle: snarfID {SnarfID}
	| handle {SnarfHandle} |
	self hack.
	"Need to check for multiple write handles on same snarf (when making writable) and too many write handles.  Also when
	getting erase handle."
	
	snarfID < self usableSnarfs assert: 'nonexistent snarf'.
	handle _ SnarfHandle 
				create: snarfID 
				with: (self readData: snarfID)
				with: self.
	^handle!

{Int4} headerSize
	"This is just the number of snarfs and their size."
	
	^8!

{void} positionStream: snarfID {SnarfID}
	"Position the stream to start at the location in the file of the give snarf."

	myStream position: snarfID * mySnarfSize + self headerSize!

{Int1Array} readData: snarfID {SnarfID}
	snarfID == CachedID
		ifTrue: [^CachedData]
		ifFalse:
			[self positionStream: snarfID.
			CachedData _ (myStream next: mySnarfSize) changeClassToThatOf: UInt8Array basicNew.
			CachedID _ snarfID.
			^CachedData]!

{void} releaseHandle: snarfID {SnarfID}
	myHandles intWipe: snarfID!

{void} writeHandle: snarfID {SnarfID} with: contents {UInt1Array}
	| class |
	self positionStream: snarfID.
	class _ contents class.
	contents changeClassToThatOf: String new.
	myStream nextPutAll: contents.
	contents changeClassToThatOf: class basicNew! !

!Urdi methodsFor: 'create'!

create: fileName {String}
	super create.
	myStageCount _ 50.
	myHandles _ IntegerTable make": myStageCount".
	myStream _ (Filename named: fileName) readWriteStream lineEndTransparent.
	mySnarfCount _ myStream nextLong.
	mySnarfCount == false ifTrue: [Heaper BLAST: #badLongInRead].
	mySnarfSize _ myStream nextLong.
	"These Proto collections are so we can directly use the object
	 returned from stream accessing operations."! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

Urdi class
	instanceVariableNames: ''!

(Urdi getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!Urdi class methodsFor: 'smalltalk: initialization'!

cleanupGarbage 
	CachedID _ CachedData _ nil!

initializePartition: fileName {String} 
	"Urdi initializePartition: 'ent.ent'"

	self initializePartition: fileName with: 30 with: 300!

initializePartition: fileName {String} with: snarfs {Int4} with: snarfSize {Int4}
	"Urdi initializePartition: 'ent.ent' with: 10 with: 30000"
	"Urdi initializePartition: 'tiny.ent' with: 10 with: 2000"

	| stream |
	stream _ (Filename named: fileName) readWriteStream lineEndTransparent.
	stream binary.
	stream nextLongPut: snarfs.
	stream nextLongPut: snarfSize.
	"stream next: snarfs * snarfSize put: 0."
	stream flush.
	stream close! !

!Urdi class methodsFor: 'global: make'!

make: string {String}
	^self create: string!

make: string {String} with: lruMax {Int4}
	^self create: string!

urdi: string {String}
	^self create: string!

urdi: string {String} with: lruMax {Int4}
	^self create: string! !Tester subclass: #UrdiTester
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Testing'!

(UrdiTester getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #(COPY boot ); yourself)!

!UrdiTester methodsFor: 'running tests'!

{void} allTestsOn: aStream {ostream reference} 
	"UrdiTester runTest: #allTestsOn:"
	"UrdiTester allTestsOn: cerr"

	aStream << '
Running all Urdi tests.
Test 1
'.
	self test1On: aStream.! !

!UrdiTester methodsFor: 'testing'!

{void} tapeTest1On: aStream {ostream reference} 
	"self runTest: #tapeTest1On:"
	"Time millisecondsToRun: [self tapeTest1On: cerr] "

	| tIOAccessor tString "tCharStringPtr" tByteArray |
	
	tIOAccessor _ IOAccessor openFileNamed: 'smalltalk:sd0d' direction: 2 "r/w" creation: 1 "create if not exist".
	aStream << 'tIOAccessor = '; << tIOAccessor; << '
'.
	tString _ '12345'.
	"(tCharStringPtr _ CharPtr newZeroed: 512) putAll: tString."
	
	(tByteArray _ ByteArray new: 512) replaceBytesFrom: 1 to: (tString size) with: tString startingAt: 1.
	
	aStream << 'tIOAccessor fileSize = '; << tIOAccessor fileSize; << '
'.
	"tIOAccessor seekTo: (512 * 3)."
	aStream << 'wrote: '; << (tIOAccessor writeAll: tByteArray); << '
'.
	aStream << 'tIOAccessor fileSize = '; << tIOAccessor fileSize; << '
'.
	tIOAccessor commit.
	aStream << 'tIOAccessor fileSize = '; << tIOAccessor fileSize; << '
'.	
	tIOAccessor close.
	aStream << 'tIOAccessor = '; << tIOAccessor; << '
'.!

{void} tapeTest2On: aStream {ostream reference} 
	"self runTest: #tapeTest2On:"

	| tIOAccessor tUInt1Ptr |
	
	tIOAccessor _ IOAccessor openFileNamed: 'smalltalk:sd0d' direction: 2 "r/w" creation: 1 "create if not exist".
	tUInt1Ptr _ UInt1Ptr newZeroed: 512.
	
	tUInt1Ptr put: 1.
	tIOAccessor writeAll: (tUInt1Ptr underlyingArray).
	tUInt1Ptr put: 2.
	tIOAccessor writeAll: (tUInt1Ptr underlyingArray).
	tUInt1Ptr put: 3.
	tIOAccessor writeAll: (tUInt1Ptr underlyingArray).
	tIOAccessor seekTo: (512).
	tUInt1Ptr put: 4.
	tIOAccessor writeAll: (tUInt1Ptr underlyingArray).
	tIOAccessor commit.
	tIOAccessor close.! !

!UrdiTester methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

UrdiTester class
	instanceVariableNames: ''!

(UrdiTester getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #(COPY boot ); yourself)!

!UrdiTester class methodsFor: 'running tests'!

{void} allTestsOn: aStream {ostream reference} 
	"UrdiTester runTest: #allTestsOn:"
	"UrdiTester allTestsOn: cerr"

	aStream << '
Running all Urdi tests.
Test 1
'.
	self test1On: aStream.! !

!UrdiTester class methodsFor: 'testing'!

{void} tapeTest1On: aStream {ostream reference} 
	"self runTest: #tapeTest1On:"
	"Time millisecondsToRun: [self tapeTest1On: cerr] "

	| tIOAccessor tString "tCharStringPtr" tByteArray |
	
	tIOAccessor _ IOAccessor openFileNamed: 'smalltalk:sd0d' direction: 2 "r/w" creation: 1 "create if not exist".
	aStream << 'tIOAccessor = '; << tIOAccessor; << '
'.
	tString _ '12345'.
	"(tCharStringPtr _ CharPtr newZeroed: 512) putAll: tString."
	
	(tByteArray _ ByteArray new: 512) replaceBytesFrom: 1 to: (tString size) with: tString startingAt: 1.
	
	aStream << 'tIOAccessor fileSize = '; << tIOAccessor fileSize; << '
'.
	"tIOAccessor seekTo: (512 * 3)."
	aStream << 'wrote: '; << (tIOAccessor writeAll: tByteArray); << '
'.
	aStream << 'tIOAccessor fileSize = '; << tIOAccessor fileSize; << '
'.
	tIOAccessor commit.
	aStream << 'tIOAccessor fileSize = '; << tIOAccessor fileSize; << '
'.	
	tIOAccessor close.
	aStream << 'tIOAccessor = '; << tIOAccessor; << '
'.!

{void} tapeTest2On: aStream {ostream reference} 
	"self runTest: #tapeTest2On:"

	| tIOAccessor tUInt1Ptr |
	
	tIOAccessor _ IOAccessor openFileNamed: 'smalltalk:sd0d' direction: 2 "r/w" creation: 1 "create if not exist".
	tUInt1Ptr _ UInt1Ptr newZeroed: 512.
	
	tUInt1Ptr put: 1.
	tIOAccessor writeAll: (tUInt1Ptr underlyingArray).
	tUInt1Ptr put: 2.
	tIOAccessor writeAll: (tUInt1Ptr underlyingArray).
	tUInt1Ptr put: 3.
	tIOAccessor writeAll: (tUInt1Ptr underlyingArray).
	tIOAccessor seekTo: (512).
	tUInt1Ptr put: 4.
	tIOAccessor writeAll: (tUInt1Ptr underlyingArray).
	tIOAccessor commit.
	tIOAccessor close.! !Heaper subclass: #UrdiView
	instanceVariableNames: 'myUrdi {Urdi}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Urdi'!

(UrdiView getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!UrdiView methodsFor: 'operations'!

{void} abortWrite!

{void} becomeRead!

{void} commitWrite
	myUrdi commitWrite!

{Int4} getDataSizeOfSnarf: snarf {SnarfID}
	^myUrdi getDataSizeOfSnarf: snarf!

{BooleanVar} isWriteView
	^true
	"^myStream name isWritable"!

{SnarfHandle} makeErasingHandle: snarfID {SnarfID}
	^myUrdi eraseHandle: snarfID!

{SnarfHandle} makeReadHandle: snarfID {SnarfID}
	^myUrdi getHandle: snarfID!

{void} thawHandles
	myUrdi commitWrite! !

!UrdiView methodsFor: 'smalltalk: create'!

create: urdi {Urdi}
	super create.
	myUrdi _ urdi! !
(CxxSystemOrganization fileNamed: 'snefru')
	comment: ''!


(CxxSystemOrganization getOrMakeFileNamed: 'snefru')
	addClass: Snefru
getOrMakeCxxClassDescription in: #public!


(CxxSystemOrganization getOrMakeFileNamed: 'snefru')
	addClass: ErrAbort
getOrMakeCxxClassDescription in: #private;
	addClass: ReadFunc
getOrMakeCxxClassDescription in: #private!


(CxxSystemOrganization getOrMakeFileNamed: 'snefru')
	addClass: SnefruTester
getOrMakeCxxClassDescription in: #test!

(CxxSystemOrganization fileNamed: 'urdi')
	comment: ''!


(CxxSystemOrganization getOrMakeFileNamed: 'urdi')
	addClass: SnarfHandle
getOrMakeCxxClassDescription in: #public;
	addClass: Urdi
getOrMakeCxxClassDescription in: #public;
	addClass: UrdiView
getOrMakeCxxClassDescription in: #public!


(CxxSystemOrganization getOrMakeFileNamed: 'urdi')
	addClass: SnarfTester
getOrMakeCxxClassDescription in: #test;
	addClass: UrdiTester
getOrMakeCxxClassDescription in: #test!

CxxSystemOrganization tree: (CxxSystemOrganization tree addChild:
	((CxxTreeAssociation key: 'utility' value: nil)
 addChild: ((CxxTreeAssociation key: 'snefru' value: #file) yourself);
 addChild: ((CxxTreeAssociation key: 'urdi' value: #file) yourself); yourself))!