'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:08:18 pm'!

Heaper subclass: #PromiseManager
	instanceVariableNames: '
		myPortal {Portal}
		myReadStream {XnReadStream}
		myWriteStream {XnWriteStream}
		myActuals {PrimPtrTable}
		myRefCounts {PrimIndexTable}
		myDetectorEvents {DetectorEvent}
		myNextClientPromise {IntegerVar}
		myNextServerPromise {IntegerVar}
		myHandlers {PtrArray}
		myAcks {IntegerVar}
		myError {ExceptionRecord}
		amInsideRequest {BooleanVar}
		myShuffler {ByteShuffler}'
	classVariableNames: '
		AllRequests {PtrArray of: RequestHandler} 
		LoginRequests {PtrArray of: RequestHandler} 
		OverrideArray {Array smalltalk} 
		OverrideMap {Dictionary smalltalk} 
		PromiseClasses {PtrArray of: Category} '
	poolDictionaries: ''
	category: 'Xanadu-proman'!

(PromiseManager getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!PromiseManager methodsFor: 'operations'!

{void} force
	self flushAcks.
	myDetectorEvents ~~ NULL ifTrue:
		[[myDetectorEvents ~~ NULL] whileTrue:
			[myDetectorEvents trigger: self.
			myDetectorEvents _ myDetectorEvents next]].
	myWriteStream flush!

{void} handleRequest
	amInsideRequest _ true.
	self thingToDo.  "This should not forward all errors."
	PromiseManager problems.EVERY.U.COMM
		handle: 
			[:ex | 
			| prob {Problem} |
			'prob = &PROBLEM(ex);' translateOnly.
			[prob _ Problem create: ex PROBLEM with: ex parameter with: ex initialContext sender printString with: 0] smalltalkOnly.
			self respondProblem: prob.
			ex return]
		do: [| reqnum {Int32} |
			reqnum _ self receiveRequestNumber.
			"[cerr cr << myNextClientPromise << (myHandlers get: reqnum).  cerr endEntry] smalltalkOnly."
			((myHandlers get: reqnum) cast: RequestHandler) handleRequest: self].
	myError ~~ NULL ifTrue: [self respondError].
	amInsideRequest _ false.
	myDetectorEvents ~~ NULL   "Forcing flushes detector events too."
		ifTrue: [self force]
		ifFalse: [myWriteStream flush]!

{BooleanVar} noErrors
	"Return true if no errors have occurred in the current transaction."

	^myError == NULL!

{void} queueDetectorEvent: event {DetectorEvent}
	"Queue up the detector event.  It will be executed after the next transaction."
	
	event setNext: myDetectorEvents.
	myDetectorEvents _ event.
	amInsideRequest ifFalse: [self force]!

{void} waive
	"Release the promise argument.  This could return a value because the PromiseManager doesn't keep any state for void promises."

	self actualWaive: self receiveIntegerVar!

{void} waiveMany
	"Release a range of promise argument, given a start and a count.  This could return a value because the PromiseManager doesn't keep any state for void promises."

	| prnum {IntegerVar} prcount {IntegerVar} |
	prnum _ self receiveIntegerVar.
	prcount _ self receiveIntegerVar.
	prnum almostTo: prnum + prcount do: [ :i {IntegerVar} |
		self actualWaive: i]! !

!PromiseManager methodsFor: 'comm'!

{BooleanVar} fetchBooleanVar
	"Optimize promise arguments that are expected to point at IntValues."
	| num {IntegerVar} result {Heaper | NULL} |
	num _ self receiveIntegerVar.
	result _ myActuals fetch: num.
	result == NULL ifTrue: 
		[myError _ (ExceptionRecord excuse: num) best: myError.
		^false].
	result cast: PrimIntValue into: [:number | ^number asIntegerVar ~~ IntegerVarZero]
		others: [myError _ (ExceptionRecord mismatch: num) best: myError].
	^false!

{Category | NULL} fetchCategory
	| num {Int32} result {Category | NULL} |
	
	self thingToDo.  "Renumber the categories from 0." 
	num _ self receiveRequestNumber.
	result _ (PromiseClasses fetch: num) cast: Category.
	result == NULL ifTrue: 
		[myError _ (ExceptionRecord badCategory: num) best: myError.
		^NULL].
	^result!

{Heaper} fetchHeaper: cat {Category}
	| num {IntegerVar} result {Heaper | NULL} |
	num _ self receiveIntegerVar.
	num == IntegerVarZero ifTrue: [^NULL].
	result _ myActuals fetch: num.
	result == NULL ifTrue: 
		[myError _ (ExceptionRecord excuse: num) best: myError.
		^NULL].
	(result isKindOf: cat) ifFalse: 
		[myError _ (ExceptionRecord mismatch: num) best: myError.
		^NULL].
	^result!

{Int32} fetchInt32

	^self fetchIntegerVar DOTasLong!

{IntegerVar} fetchIntegerVar
	"Optimize promise arguments that are expected to point at IntValues."
	| num {IntegerVar} result {Heaper | NULL} |
	num _ self receiveIntegerVar.
	result _ myActuals fetch: num.
	result == NULL ifTrue: 
		[myError _ (ExceptionRecord excuse: num) best: myError.
		^IntegerVarZero].
	result cast: PrimIntValue into: [:number | ^number asIntegerVar]
		others: [myError _ (ExceptionRecord mismatch: num) best: myError].
	^IntegerVarZero!

{Heaper} fetchNonNullHeaper: cat {Category}
	| num {IntegerVar} result {Heaper | NULL} |
	num _ self receiveIntegerVar.
	num == IntegerVarZero ifTrue:
		[myError _ (ExceptionRecord wasNull: num) best: myError.
		^NULL].
	result _ myActuals fetch: num.
	result == NULL ifTrue: 
		[myError _ (ExceptionRecord excuse: num) best: myError.
		^NULL].
	(result isKindOf: cat) ifFalse: 
		[myError _ (ExceptionRecord mismatch: num) best: myError.
		^NULL].
	^result!

{IntegerVar} receiveIntegerVar
	"A new representation that requires less shifting (eventually)."
"
7/1 		0<7>
14/2	10<6>		<8>
21/3	110<5>		<16>
28/4	1110<4>		<24>
35/5	11110<3>	<32>
42/6	111110<2>	<40>
49/7	1111110<1>	<48>
56/8	11111110 	<56>
+/+	11111111  <humber count>
"
"This is smalltalk only because smalltalk doesn't do sign-extend."
	| byte {UInt8} mask {UInt8} count {Int32} num {Int32} |
	"count is bytes following first word or -1 if bignum meaning next byte is humber for actual count"
	byte _  myReadStream getByte.
	byte <= 2r00111111 ifTrue: [^byte]. 
	byte <= 2r01111111 ifTrue: [^byte-128].
	byte <= 2r10111111
		ifTrue: [mask _ 2r00111111.  count _ 1]
		ifFalse: [byte <= 2r11011111
					ifTrue: [mask _ 2r00011111.  count _ 2]
					ifFalse: [byte <= 2r11101111
								ifTrue: [mask _ 2r00001111.  count _ 3]
								ifFalse: [byte <= 2r11110111
											ifTrue: [mask _ 2r00000111.  count _ 4]
											ifFalse: [self unimplemented]]]].
	byte _ byte bitAnd: mask.
	(byte bitAnd: ((mask bitInvert bitShiftRight: 1) bitAnd: mask)) ~= Int32Zero
		ifTrue:
			[byte _ byte bitOr: mask bitInvert.
			num _ -1]
		ifFalse: [num _ Int32Zero.
				((count > 3) and: [(byte ~= (byte bitAnd: mask))]) ifTrue: [self unimplemented]].
	num _ (num bitShift: 8) + byte.
	1 to: count do: [:i {Int32} | num _ (num bitShift: 8) + myReadStream getByte].
	^ num!

{void} respondBooleanVar: val {BooleanVar}
	myError == NULL ifTrue:
		[self flushAcks.
		self sendResponse: PromiseManager humberResponse.
		[self sendIntegerVar: val.
		myActuals at: myNextClientPromise introduce: (PrimIntValue make: val)] translateOnly.
		[self sendIntegerVar: (val ifTrue: [1] ifFalse: [0]).
		myActuals at: myNextClientPromise introduce: (PrimIntValue make: (val ifTrue: [1] ifFalse: [0]))] smalltalkOnly.
		myNextClientPromise _ myNextClientPromise + 1]!

{void} respondHeaper: result {Heaper}
	result == NULL ifTrue:
		[Heaper BLAST: #NullResponseResult].
	myError == NULL ifTrue:
		[result cast: PrimIntValue into: [ :i |
			self flushAcks.
			self sendResponse: PromiseManager humberResponse.
			self sendIntegerVar: i asIntegerVar]
		cast: PrimFloatValue into: [ :f |
			self flushAcks.
			self sendResponse: PromiseManager IEEEResponse.
			f bitCount = 64 ifTrue:
				[self sendIEEE64: f asIEEE64]
			ifFalse: [f bitCount = 32 ifTrue:
				[self sendIEEE32: f asIEEE32]
			ifFalse:
				[self unimplemented]]]
		others: [myAcks _ myAcks + 1].
		myActuals at: myNextClientPromise introduce: result.
		(result isKindOf: FeDetector) ifTrue: 
			[| refCt {IntegerVar} |
			refCt _ myRefCounts fetch: result.
			refCt == -1
				ifTrue: [myRefCounts at: result introduce: 1]
				ifFalse: 
					[myRefCounts remove: result.
					myRefCounts at: result introduce: refCt + 1]].
		myNextClientPromise _ myNextClientPromise + 1]!

{void} respondIntegerVar: val {IntegerVar}
	myError == NULL ifTrue:
		[self flushAcks.
		self sendResponse: PromiseManager humberResponse.
		self sendIntegerVar: val.
		myActuals at: myNextClientPromise introduce: (PrimIntValue make: val).
		myNextClientPromise _ myNextClientPromise + 1]!

{void} respondVoid
	myError == NULL ifTrue:
		[myAcks _ myAcks + 1.
		myNextClientPromise _ myNextClientPromise + 1]!

{void} sendIEEE32: f {IEEE32}

	'this->sendIntegerVar (4);
	for (UInt32 i = 0; i < 4; i++) {
		myWriteStream->putByte (((UInt8 *) &f) [i]);
	}' translateOnly.
	[self unimplemented] smalltalkOnly.!

{void} sendIEEE64: f {IEEE64}

	'this->sendIntegerVar (8);
	for (UInt32 i = 0; i < 8; i++) {
		myWriteStream->putByte (((UInt8 *) &f) [i]);
	}' translateOnly.
	[self unimplemented] smalltalkOnly.!

{void} sendIntegerVar: num {IntegerVar}
	"Send a Dean style humber.  Like Drexler style, except all the tag bits go into the first byte."
	 
"
7/1 		0<7>
14/2	10<6>		<8>
21/3	110<5>		<16>
28/4	1110<4>		<24>
35/5	11110<3>	<32>
42/6	111110<2>	<40>
49/7	1111110<1>	<48>
56/8	11111110 	<56>
+/+	11111111  <humber count>
"
	| abs {IntegerVar} low32 {Int32} |
	num < IntegerVarZero ifTrue: [abs _ num negated] ifFalse: [abs _ num].
	low32 _ (num bitAnd: ("(1 bitShift: 32) -1"  4294967295)) DOTasLong.
	num < "1 bitShift: 6" 64 ifTrue: [myWriteStream putByte: (low32 bitAnd: 127).  ^VOID].
	abs < "1 bitShift: 13"  8192 ifTrue: 
		[myWriteStream putByte: (((low32 bitShiftRight: 8) bitAnd: 2r0111111) bitOr: 2r10000000).
		myWriteStream putByte: (low32 bitAnd: 255).
		^VOID].
	abs < "1 bitShift: 20"  1048576 ifTrue: 
		[myWriteStream putByte: (((low32 bitShiftRight: 16) bitAnd: 2r011111) bitOr: 2r11000000).
		myWriteStream putByte: ((low32 bitShiftRight: 8) bitAnd: 255).
		myWriteStream putByte: (low32 bitAnd: 255).
		^VOID].
	abs < "1 bitShift: 27"  134217728 ifTrue: 
		[myWriteStream putByte: (((low32 bitShiftRight: 24) bitAnd: 2r00001111) bitOr: 2r11100000).
		myWriteStream putByte: ((low32 bitShiftRight: 16) bitAnd: 255).
		myWriteStream putByte: ((low32 bitShiftRight: 8) bitAnd: 255).
		myWriteStream putByte: (low32 bitAnd: 255).
		^VOID].
	"abs < (1 bitShift: 34)" true ifTrue: 
		["do shift in two steps to get around Sparc shift bug /ravi/7/23/92/"
		myWriteStream putByte: ((((num bitShiftRight: 16) bitShiftRight: 16) bitAnd: 2r0111) bitOr: 2r11110000) DOTasLong.
		myWriteStream putByte: ((num bitShiftRight: 24) bitAnd: 255) DOTasLong.
		myWriteStream putByte: ((num bitShiftRight: 16) bitAnd: 255) DOTasLong.
		myWriteStream putByte: ((num bitShiftRight: 8) bitAnd: 255) DOTasLong.
		myWriteStream putByte: (num bitAnd: 255) DOTasLong.
		^VOID].
	"self sendIntegerVar: (abs log: 256) truncated + 1."  "The humber count."
	Eric shouldImplement  "Write out each of the bytes."!

{void} sendPromise: heaper {Heaper}
	"Register heaper with the next Server promise number and increment it.  The client must stay in sync."
	
	myActuals at: myNextServerPromise introduce: heaper.
	myNextServerPromise _ myNextServerPromise - 1!

{void} sendResponse: num {Int32}
	"Use a representation optimized for small positive numbers."
	"If the number is less than 255 then just send it.  Otherwise send 255, subtract 255 and recur."

	| val {Int32} |
	val _ num.
	[num < 255] whileFalse:
		[myWriteStream putByte: 255.
		val _ val - 255].
	myWriteStream putByte: (val basicCast: UInt8)! !

!PromiseManager methodsFor: 'arrays'!

{void} sendHumbers: array {IntegerVarArray} with: count {Int32} with: start {Int32}
	"Send a bunch of IntegerVars to the client."
	
	| maxx {Int32} |
	maxx _ start + count.
	maxx > array count ifTrue: [Heaper BLAST: #OutOfBounds].
	self flushAcks.
	self sendResponse: PromiseManager humbersResponse.
	self sendIntegerVar: count.
	myActuals at: myNextClientPromise introduce: (PrimIntValue make: count).
	start almostTo: maxx do: 
		[:i {Int32} | self sendIntegerVar: (array integerVarAt: i)].
	myNextClientPromise _ myNextClientPromise + 1!

{void} sendIEEEs: array {PrimFloatArray} with: count {Int32} with: start {Int32}
	"Send a bunch of fixed precision integers to the client."
	
	| size {Int32} buffer {UInt8Array} |
	start + count > array count ifTrue: [Heaper BLAST: #OutOfBounds].
	self flushAcks.
	self sendResponse: PromiseManager IEEEsResponse.
	self sendIntegerVar: array bitCount // 8.
	self sendIntegerVar: count.
	myActuals at: myNextClientPromise introduce: (PrimIntValue make: count).
	size _ array bitCount // 8 * count.
	buffer _ (PrimIntArray zeros: 8 with: size) cast: UInt8Array.
	[array copyToBuffer: buffer gutsOf with: size with: count with: start]
		valueNowOrOnUnwindDo:
			(UInt8Array bomb.ReleaseGuts: buffer).
	[myShuffler shuffle: array bitCount with: buffer gutsOf with: count]
		valueNowOrOnUnwindDo:
			(UInt8Array bomb.ReleaseGuts: buffer).
	myWriteStream putData: buffer.
	myNextClientPromise _ myNextClientPromise + 1!

{void} sendInts: array {PrimIntArray} with: count {Int32} with: start {Int32}
	"Send a bunch of fixed precision integers to the client."
	
	| size {Int32} buffer {UInt8Array} |
	start + count > array count ifTrue: [Heaper BLAST: #OutOfBounds].
	self flushAcks.
	self sendResponse: PromiseManager intsResponse.
	self sendIntegerVar: array bitCount.
	self sendIntegerVar: count.
	myActuals at: myNextClientPromise introduce: (PrimIntValue make: count).
	size _ array bitCount abs // 8 * count.
	buffer _ (PrimIntArray zeros: 8 with: size) cast: UInt8Array.
	[array copyToBuffer: buffer gutsOf with: size with: count with: start]
		valueNowOrOnUnwindDo:
			(UInt8Array bomb.ReleaseGuts: buffer).
	[myShuffler shuffle: array bitCount abs with: buffer gutsOf with: count]
		valueNowOrOnUnwindDo:
			(UInt8Array bomb.ReleaseGuts: buffer).
	myWriteStream putData: buffer.
	myNextClientPromise _ myNextClientPromise + 1!

{void} sendPromises: array {PtrArray} with: count {Int32} with: start {Int32}
	"Register heaper with the next Server promise number and increment it.  The client must stay in sync."
	
	| maxx {Int32} nulls {Int32} ptrs {Int32} |
	maxx _ start + count.
	maxx > array count ifTrue: [Heaper BLAST: #OutOfBounds].
	nulls _ Int32Zero.
	ptrs _ Int32Zero.
	self flushAcks.
	self sendResponse: PromiseManager promisesResponse.
	self sendIntegerVar: count.
	myActuals at: myNextClientPromise introduce: (PrimIntValue make: count).
	start almostTo: maxx do: 
		[:i {Int32} |
		| elem {Heaper | NULL} |
		elem _ array fetch: i.
		elem == NULL
			ifTrue:
				[nulls <= Int32Zero ifTrue: 
					[self sendIntegerVar: ptrs.
					ptrs _ Int32Zero].
				nulls _ nulls + 1]
			ifFalse:
				[nulls > Int32Zero ifTrue: 
					[self sendIntegerVar: nulls.
					nulls _ Int32Zero].
				self sendPromise: elem.
				ptrs _ ptrs + 1]].
	ptrs >= 1 ifTrue: [self sendIntegerVar: ptrs].
	nulls >= 1 ifTrue: [self sendIntegerVar: nulls].
	myNextClientPromise _ myNextClientPromise + 1! !

!PromiseManager methodsFor: 'private: comm'!

{void} actualWaive: prnum {IntegerVar}
	"Release the promise argument.  This could return a value because the PromiseManager doesn't keep any state for void promises."

	| actual {Heaper} count {IntegerVar} |
	actual _ myActuals fetch: prnum.
	(myActuals fetch: prnum) ~~ NULL ifTrue: [myActuals remove: prnum].
	count _ myRefCounts fetch: actual.
	count == Int32Zero ifTrue: [Heaper BLAST: #RefCountBug].
	count > Int32Zero ifTrue:
		[count == 1 
			ifTrue:
				[myRefCounts remove: actual.
				actual destroy]
			ifFalse: [myRefCounts at: actual introduce: count - 1]]!

{IntegerVar} clientPromiseNumber

	^myNextClientPromise!

{void} flushAcks
	"If any acks have accumulated, flush them."
	
	myAcks > IntegerVarZero ifTrue:
		[self sendResponse: PromiseManager ackResponse.
		self sendIntegerVar: myAcks.
		myAcks _ IntegerVarZero]!

{XnReadStream} readStream
	^myReadStream!

{Int32} receiveRequestNumber
	"Receive a request number.  The first byte is either between 0 and 254 or it
	 is 255 and the second byte + 255 is the number."
	
	| byte {Int32} |
	byte _ myReadStream getByte.
	byte < 255 ifTrue: [^byte].
	^myReadStream getByte + 255!

{void} respondError
	self flushAcks.
	myError isExcused 
		ifTrue: 
			[self sendResponse: PromiseManager excusedResponse.
			self sendIntegerVar: myError promise]
		ifFalse:
			[self sendResponse: PromiseManager errorResponse.
			self sendIntegerVar: myError error.
			self sendIntegerVar: Int32Zero].
	myNextClientPromise _ myNextClientPromise + 1.
	myError _ NULL!

{void} respondProblem: problem {Problem}

	BlastLog << 'Blast sent: ' << problem getProblemName << ' at: '.
	BlastLog << problem getFileName << ':' << problem getLineNumber << '
'.
	[Logger] USES.
	self flushAcks.
	self sendResponse: PromiseManager errorResponse.
	self sendIntegerVar: (PromiseManager problemNumber: problem getProblemName).
	self sendIntegerVar: (PromiseManager problemSource: problem getFileName
		with: problem getLineNumber).
	myNextClientPromise _ myNextClientPromise + 1.
	myError _ NULL!

{IntegerVar} serverPromiseNumber

	^myNextServerPromise! !

!PromiseManager methodsFor: 'protected: creation'!

create: portal {Portal} with: clientID {char star} with: shuffler {ByteShuffler}
	super create.
	myPortal _ portal.
	myReadStream _ portal readStream.
	myWriteStream _ portal writeStream.
	myActuals _ PrimPtrTable make: 5000.
	myRefCounts _ PrimIndexTable make: 63.
	myDetectorEvents _ NULL.
	myNextClientPromise _ 1.
	myNextServerPromise _ -1.
	self thingToDo.  "This should get a table based on the clientID."
	myHandlers _ PromiseManager makeRequestTable.
	clientID delete.
	myAcks _ Int32Zero.
	myError _ NULL.
	amInsideRequest _ false.
	myShuffler _ shuffler.!

{void} destruct
	| step {PrimIndexTableStepper} |
	myPortal destroy.
	"clean up all the ref counted Detectors"
	step _ myRefCounts stepper.
	[step hasValue] whileTrue: [
		| detect {Heaper} |
		detect _ step key.
		detect destroy.
		step step].
	super destruct! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

PromiseManager class
	instanceVariableNames: ''!

(PromiseManager getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!PromiseManager class methodsFor: 'exceptions: exceptions'!

problems.EVERY.U.COMM

	^self signals: #(ALL.U.BUT 
		SUBCLASS.U.RESPONSIBILITY 
		URDI.U.JACKPOT 
		MEM.U.ALLOC.U.ERROR
		NULL.U.CHKPTR
		PURE.U.VIRTUAL
		NullResponseResult
		SOCKET.U.RECV.U.ERROR
		SOCKET.U.SEND.U.ERROR
		SanityViolation)! !

!PromiseManager class methodsFor: 'constants'!

{Int32} ackResponse
	^Int32Zero!

{Int32} doneResponse
	^14!

{Int32} errorResponse
	^1!

{Int32} excusedResponse
	^2!

{Int32} filledResponse
	^13!

{Int32} grabbedResponse
	^9!

{Int32} humberResponse
	^3!

{Int32} humbersResponse
	^5!

{Int32} IEEEResponse
	^4!

{Int32} IEEEsResponse
	^7!

{Int32} intsResponse
	^6!

{Int32} problemNumber: prob {char star}
	"The number that gets sent over the wire for the given problem name"
	"PromiseManager problemNumber: 'VALUE_IS_UNKIND' "
	
	^(FHash fastHash.String: prob) bitAnd: 16777215!

{Int32} problemSource: file {char star} with: line {int}
	"The number that gets sent over the wire for the given problem file/line number"
	
	^((((FHash fastHash.String: file) bitAnd: 65535) bitShift: 15) bitXor: (line bitAnd: 32767))!

{Int32} promisesResponse
	^8!

{Int32} rangeFilledResponse
	^12!

{Int32} releasedResponse
	^10!

{Int32} revisedResponse
	^11!

{Int32} terminatedResponse
	^15! !

!PromiseManager class methodsFor: 'smalltalk: init'!

initTimeNonInherited

	PromiseClasses _ PtrArray nulls: 100.
	self fillClassTable: PromiseClasses.
	AllRequests _ PtrArray nulls: 500.
	AllRequests storeAll: 
		(SpecialHandler make: (PromiseManager pointerToStaticMember: #noRequest: with: 'VHFn')).
	self fillRequestTable: AllRequests.
	"LoginRequests _ PtrArray nulls: 500.
	LoginRequests storeAll: 
		(SpecialHandler make: (PromiseManager pointerToStaticMember: #notLoginRequest: with: 'VHFn'))."!

linkTimeNonInherited

	PromiseClasses _ NULL.
	AllRequests _ NULL.
	"LoginRequests _ NULL"
	Logger defineLogger: #BlastLog.! !

!PromiseManager class methodsFor: 'creation'!

make: portal {Portal} 
	| reader {Rcvr} writer {Xmtr} target {char star} shuffler {ByteShuffler} |
	reader _ TextyXcvrMaker makeReader: portal readStream.
	writer _ TextyXcvrMaker makeWriter: portal writeStream.
	self thingToDo.  "Make the following loop a helper routine."
"Meta-protocol"
	target _ reader receiveString.
	[(String strcmp: target with: 'simple') = Int32Zero] whileFalse:
		[target delete.
		target _ NULL.
		writer sendString: 'no!!'.
		target _ reader receiveString].
	writer sendString: 'yes'.
	target delete.
	target _ NULL.
"Architecture."
	target _ reader receiveString.
	[(String strcmp: target with: 'sun') = Int32Zero or: [(String strcmp: target with: 'intel') = Int32Zero]] whileFalse:
		[target delete.
		target _ NULL.
		writer sendString: 'no!!'.
		target _ reader receiveString].
	[[(OSHandle informVM quickSearch: target) = Int32Zero]
		ifTrue: [shuffler _ SimpleShuffler create]
		ifFalse: [shuffler _ NoShuffler create]] smalltalkOnly.
	[((String strcmp: target with: 'intel') = Int32Zero)
		ifTrue: [shuffler _ SimpleShuffler create]
		ifFalse: [shuffler _ NoShuffler create]] translateOnly.
	target delete.
	target _ NULL.
	writer sendString: 'yes'.
"Syntax"
	target _ reader receiveString.
	[(String strcmp: target with: 'binary2') = Int32Zero] whileFalse:
		[target delete.
		target _ NULL.
		writer sendString: 'no!!'.
		target _ reader receiveString].
	target delete.
	target _ NULL.
	writer sendString: 'yes'.
"Semantics"
	target _ reader receiveString.
	[(String strcmp: target with: 'febe92.2') = Int32Zero] whileFalse:
		[target delete.
		target _ NULL.
		writer sendString: 'no!!'.
		target _ reader receiveString].
	writer sendString: 'yes'.
	writer destroy.
	reader destroy.
	^PromiseManager create: portal with: target with: shuffler.! !

!PromiseManager class methodsFor: 'detector requests'!

{void} fillDetector: pm {PromiseManager} 
	"Create the comm detector and add it."
	| rangeElement {FeRangeElement | NULL} |
	rangeElement _ (pm fetchNonNullHeaper: FeRangeElement) cast: FeRangeElement.
	pm noErrors ifTrue:
		[| detector {FeFillDetector} |
		detector _ CommFillDetector make: pm with: pm clientPromiseNumber with: rangeElement.
		rangeElement addFillDetector: detector.
		pm respondHeaper: detector]!

{void} fillRangeDetector: pm {PromiseManager} 
	"Create the comm detector and add it."
	| receiver {FeEdition | NULL} |
	receiver _ (pm fetchNonNullHeaper: FeEdition) cast: FeEdition.
	pm noErrors ifTrue:
		[| detector {FeFillRangeDetector} |
		detector _ CommFillRangeDetector make: pm with: pm clientPromiseNumber with: receiver.
		receiver addFillRangeDetector: detector.
		pm respondHeaper: detector]!

{void} revisionDetector: pm {PromiseManager} 
	"Create the comm detector and add it."
	| receiver {FeWork | NULL} |
	receiver _ (pm fetchNonNullHeaper: FeWork) cast: FeWork.
	pm noErrors ifTrue:
		[| detector {FeRevisionDetector} |
		detector _ CommRevisionDetector make: pm with: pm clientPromiseNumber with: receiver.
		receiver addRevisionDetector: detector.
		pm respondHeaper: detector]!

{void} statusDetector: pm {PromiseManager} 
	"Create the comm detector and add it."
	| receiver {FeWork | NULL} |
	receiver _ (pm fetchNonNullHeaper: FeWork) cast: FeWork.
	pm noErrors ifTrue:
		[| detector {FeStatusDetector} |
		detector _ CommStatusDetector make: pm with: pm clientPromiseNumber with: receiver.
		receiver addStatusDetector: detector.
		pm respondHeaper: detector]!

{void} waitForConsequences: pm {PromiseManager} 
	"Create the comm detector and add it."
	| detector {FeWaitDetector} |
	detector _ CommWaitDetector make: pm with: pm clientPromiseNumber.
	FeServer waitForConsequences: detector.
	pm respondHeaper: detector!

{void} waitForWrite: pm {PromiseManager} 
	"Create the comm detector and add it."
	| detector {FeWaitDetector} |
	detector _ CommWaitDetector make: pm with: pm clientPromiseNumber.
	FeServer waitForWrite: detector.
	pm respondHeaper: detector! !

!PromiseManager class methodsFor: 'misc requests'!

{void} delayCast: pm {PromiseManager} 
	
	| result {Heaper} cat {Category} |
	result _ pm fetchHeaper: Heaper.
	cat _ pm fetchCategory.
	pm noErrors ifTrue:
		[(result == NULL or: [result isKindOf: cat]) 
			ifFalse: [Heaper BLAST: #CastFailed].
		pm respondHeaper: result]!

{void} equals: pm {PromiseManager} 
	
	| me {Heaper} him {Heaper} |
	me _ pm fetchNonNullHeaper: Heaper.
	him _ pm fetchNonNullHeaper: Heaper.
	pm noErrors ifTrue:
		[pm respondBooleanVar: (me isEqual: him)]!

{void} export0: pm {PromiseManager} 
	"The zero argument version of PrimArray export."
	
	| array {PrimArray} |
	array _ (pm fetchNonNullHeaper: PrimArray) cast: PrimArray.
	pm noErrors ifTrue:
		[array cast: PrimIntArray into: [:a | pm sendInts: a with: a count with: Int32Zero]
			 cast: IntegerVarArray into: [:a | pm sendHumbers: a with: a count with: Int32Zero]
			 cast: PtrArray into: [:a | pm sendPromises: a with: a count with: Int32Zero]
			 cast: PrimFloatArray into: [:a | pm sendIEEEs: a with: a count with: Int32Zero]]!

{void} export1: pm {PromiseManager} 
	"The one argument version of PrimArray export."
	
	| array {PrimArray} count {Int32} |
	array _ (pm fetchNonNullHeaper: PrimArray) cast: PrimArray.
	count _ pm fetchInt32.
	pm noErrors ifTrue:
		[array cast: PrimIntArray into: [:a | pm sendInts: a with: count with: Int32Zero]
			 cast: IntegerVarArray into: [:a | pm sendHumbers: a with: count with: Int32Zero]
			 cast: PtrArray into: [:a | pm sendPromises: a with: count with: Int32Zero]
			 cast: PrimFloatArray into: [:a | pm sendIEEEs: a with: count with: Int32Zero]]!

{void} export2: pm {PromiseManager} 
	"The two argument version of PrimArray export."
	
	| array {PrimArray} count {Int32} start {Int32} |
	array _ (pm fetchNonNullHeaper: PrimArray) cast: PrimArray.
	count _ pm fetchInt32.
	start _ pm fetchInt32.
	pm noErrors ifTrue:
		[array cast: PrimIntArray into: [:a | pm sendInts: a with: count with: start]
			 cast: IntegerVarArray into: [:a | pm sendHumbers: a with: count with: start]
			 cast: PtrArray into: [:a | pm sendPromises: a with: count with: start]
			 cast: PrimFloatArray into: [:a | pm sendIEEEs: a with: count with: start]]!

{void} forceIt: pm {PromiseManager} 
	pm force!

{PtrArray of: RequestHandler} makeRequestTable
	"PromiseManager makeRequestTable."
	| table {PtrArray} |
	table _ PtrArray nulls: 500.
	table storeAll: (SpecialHandler make: (PromiseManager pointerToStaticMember: #noRequest: with: 'VHFn')).
	self fillRequestTable: table.
	^table!

{void} noRequest: pm {PromiseManager unused} 
	"For illegal requests."
	
	Heaper BLAST: #BadRequest!

{void} notLoggedInRequest: pm {PromiseManager unused} 
	"For illegal requests."
	
	Heaper BLAST: #NotLoggedIn!

{void} promiseHash: pm {PromiseManager} 
	
	| me {Heaper}  |
	me _ pm fetchNonNullHeaper: Heaper.
	pm noErrors ifTrue:
		[pm respondIntegerVar: me hashForEqual]!

{void} setCurrentAuthor: pm {PromiseManager}
	"The one argument version of PrimArray export."
	
	| iD {ID}  |
	iD _ (pm fetchHeaper: ID) cast: ID.
	pm noErrors ifTrue:
		[FeServer setCurrentAuthor: iD]!

{void} setCurrentKeyMaster: pm {PromiseManager}
	"Set the fluid."
	
	| keymaster {FeKeyMaster}  |
	keymaster _ (pm fetchHeaper: FeKeyMaster) cast: FeKeyMaster.
	pm noErrors ifTrue:
		[FeServer setCurrentKeyMaster: keymaster]!

{void} setInitialEditClub: pm {PromiseManager}
	"Set the fluid."
	
	| iD {ID}  |
	iD _ (pm fetchHeaper: ID) cast: ID.
	pm noErrors ifTrue:
		[FeServer setInitialEditClub: iD]!

{void} setInitialOwner: pm {PromiseManager}
	"Set the fluid."
	
	| iD {ID}  |
	iD _ (pm fetchHeaper: ID) cast: ID.
	pm noErrors ifTrue:
		[FeServer setInitialOwner: iD]!

{void} setInitialReadClub: pm {PromiseManager}
	"Set the fluid."
	
	| iD {ID}  |
	iD _ (pm fetchHeaper: ID) cast: ID.
	pm noErrors ifTrue:
		[FeServer setInitialReadClub: iD]!

{void} setInitialSponsor: pm {PromiseManager}
	"Set the fluid."
	
	| iD {ID}  |
	iD _ (pm fetchHeaper: ID) cast: ID.
	pm noErrors ifTrue:
		[FeServer setInitialSponsor: iD]!

{void} shutdown: pm {PromiseManager}

	| adm {FeAdminer} |
	adm := (pm fetchNonNullHeaper: FeAdminer) cast: FeAdminer.
	pm noErrors ifTrue:
		[pm force.
		adm shutdown]!

{void} testKindOf: pm {PromiseManager} 
	| result {Heaper} cat {Category} |
	result _ pm fetchNonNullHeaper: Heaper.
	cat _ pm fetchCategory.
	pm noErrors ifTrue:
		[pm respondBooleanVar: (result isKindOf: cat)]!

{void} waiveEm: pm {PromiseManager} 
	pm waiveMany!

{void} waiveIt: pm {PromiseManager} 
	pm waive! !

!PromiseManager class methodsFor: 'making requests'!

{void} makeFloat: pm {PromiseManager} 
	"<sizeof> <byte>* "
	| size {Int32} |
	size _ pm receiveIntegerVar DOTasLong.
	size = 4 ifTrue:
		['IEEE32 f;
		pm->readStream ()->getBytes ((void *) &f, 4);
		pm->respondHeaper (PrimIEEE32::make (f));
		return;' translateOnly]
	ifFalse: [size = 8 ifTrue:
		['IEEE64 f;
		pm->readStream ()->getBytes ((void *) &f, 8);
		pm->respondHeaper (PrimIEEE64::make (f));
		return;' translateOnly]].
	size timesRepeat: [pm readStream getByte].
	pm noErrors ifTrue: [self unimplemented]!

{void} makeFloatArray: pm {PromiseManager} 
	| sizeofFloat {IntegerVar} count {IntegerVar} |
	sizeofFloat _ pm receiveIntegerVar.
	count _ pm receiveIntegerVar.
	pm noErrors ifTrue: 
		[| size {Int32} buffer {UInt8 vector} result {PrimFloatArray} |
		size _ (sizeofFloat * count) DOTasLong.
		[buffer _ UInt8Array make: size] smalltalkOnly.
		'if (size > 0) {
			buffer = new UInt8[size];
		} else {
			buffer = NULL;
		}' translateOnly.
		pm readStream getBytes: buffer with: size.
		result _ ((PrimSpec iEEE: (sizeofFloat * 8) DOTasLong) arrayFromBuffer: count DOTasLong with: buffer) cast: PrimFloatArray.
		buffer ~~ NULL ifTrue: [buffer delete].
		pm respondHeaper: result]!

{void} makeHumber: pm {PromiseManager} 
	| num {IntegerVar} |
	num _ pm receiveIntegerVar.
	pm noErrors ifTrue: [pm respondHeaper: (PrimIntValue make: num)]!

{void} makeHumberArray: pm {PromiseManager} 
	| count {Int32} result {PrimIntegerArray} |
	count _ pm receiveIntegerVar DOTasLong.
	result _ IntegerVarArray zeros: count.
	Int32Zero almostTo: count do: [:i {Int32} | result at: i storeInteger: pm receiveIntegerVar].
	pm noErrors ifTrue: [pm respondHeaper: result]!

{void} makeIntArray: pm {PromiseManager} 

	| precision {IntegerVar} count {IntegerVar} size {Int32} buffer {UInt8 vector} bits {Int32} spec {PrimSpec} result {PrimIntegerArray} |
	precision _ pm receiveIntegerVar.
	count _ pm receiveIntegerVar.
	bits _ precision abs DOTasLong.
	size _ (precision abs // 8 * count) DOTasLong.
	[buffer _ UInt8Array make: size] smalltalkOnly.
	'if (size > 0) {
		buffer = new UInt8[size];
	} else {
		buffer = NULL;
	}' translateOnly.
	pm readStream getBytes: buffer with: size.
	precision < Int32Zero 
		ifTrue: [spec _ PrimSpec signedInteger: bits] 
		ifFalse: [spec _ PrimSpec unsignedInteger: bits].
	result _ (spec arrayFromBuffer: count DOTasLong with: buffer) cast: PrimIntegerArray.
	buffer ~~ NULL ifTrue: [buffer delete].
	pm respondHeaper: result!

{void} makePtrArray: pm {PromiseManager} 
	"If any of the promises is an error, then pm won't return the PtrArray."
	| count {Int32} result {PtrArray} |
	count _ pm receiveIntegerVar DOTasLong.
	result _ PtrArray nulls: count.
	Int32Zero almostTo: count do: 
		[:i {Int32} | result at: i store: (pm fetchHeaper: Heaper)].
	pm noErrors ifTrue: [pm respondHeaper: result]! !

!PromiseManager class methodsFor: 'smalltalk: generation'!

mapOverride: sel with: class with: argCount
	"The table of classes and their selectors overridden by special handlers."
	"PromiseManager mapOverride: 'waive' with: 'Promise' with: 0"
	
	| array |
	array _ #(
		('Promise cast 1' delayCast:)
		('Promise isKindOf 1' testKindOf:)
		('Promise waive 0' waiveIt:)
		('Promise waiveMany 1' waiveEm:)
		('Promise equals 1' equals:)
		('Promise hash 0' promiseHash:)
		('Server force 0' forceIt:)
		('Adminer shutdown 0' shutdown:)
		('Array export 0' export0:)
		('Array export 1' export1:)
		('Array export 2' export2:)
		('FloatValue import 1' makeFloat:)
		('FloatArray import 1' makeFloatArray:)
		('IntValue import 1' makeHumber:)
		('HumberArray import 1' makeHumberArray:)
		('IntArray import 1' makeIntArray:)
		('PtrArray import 1' makePtrArray:)
		('RangeElement fillDetector 0' fillDetector:)
		('Edition fillRangeDetector 0' fillRangeDetector:)
		('Work revisionDetector 0' revisionDetector:)
		('Work statusDetector 0' statusDetector:)
		('Server setCurrentAuthor 1' setCurrentAuthor:)
		('Server setCurrentKeyMaster 1' setCurrentKeyMaster:)
		('Server setInitialEditClub 1' setInitialEditClub:)
		('Server setInitialOwner 1' setInitialOwner:)
		('Server setInitialReadClub 1' setInitialReadClub:)
		('Server setInitialSponsor 1' setInitialSponsor:)
		('Server waitForConsequences 0' waitForConsequences:)
		('Server waitForWrite 0' waitForWrite:)
	).
	array ~~ OverrideArray ifTrue:
		[OverrideArray _ array.
		OverrideMap _ Dictionary fromPairs: array].
	^OverrideMap at: (String streamContents: [:pp | pp << class << ' ' << sel << ' ' << argCount])
		ifAbsent: []! !

!PromiseManager class methodsFor: 'smalltalk: passe'!

{void} force: pm {PromiseManager} 
	self passe. "use forceIt"!

{void} waive: pm {PromiseManager} 
	self passe! !

!PromiseManager class methodsFor: 'translate: generated'!

{void} fillClassTable: table {PtrArray}
	
	table at: 1 storeValue: Heaper.
	table at: 2 storeValue: FeAdminer.
	table at: 3 storeValue: FeArchiver.
	table at: 4 storeValue: PrimArray.
	table at: 5 storeValue: PrimFloatArray.
	table at: 6 storeValue: IntegerVarArray.
	table at: 7 storeValue: PrimIntArray.
	table at: 8 storeValue: PtrArray.
	table at: 9 storeValue: FeBundle.
	table at: 10 storeValue: FeArrayBundle.
	table at: 11 storeValue: FeElementBundle.
	table at: 12 storeValue: FePlaceHolderBundle.
	table at: 13 storeValue: CoordinateSpace.
	table at: 14 storeValue: CrossSpace.
	table at: 15 storeValue: FilterSpace.
	table at: 16 storeValue: IDSpace.
	table at: 17 storeValue: IntegerSpace.
	table at: 18 storeValue: RealSpace.
	table at: 19 storeValue: SequenceSpace.
	table at: 20 storeValue: FeFillRangeDetector.
	table at: 21 storeValue: FeFillDetector.
	table at: 22 storeValue: FeKeyMaster.
	table at: 23 storeValue: Lock.
	table at: 24 storeValue: BooLock.
	table at: 25 storeValue: ChallengeLock.
	table at: 26 storeValue: MatchLock.
	table at: 27 storeValue: MultiLock.
	table at: 28 storeValue: WallLock.
	table at: 29 storeValue: Mapping.
	table at: 30 storeValue: CrossMapping.
	table at: 31 storeValue: IntegerMapping.
	table at: 32 storeValue: SequenceMapping.
	table at: 33 storeValue: OrderSpec.
	table at: 34 storeValue: CrossOrderSpec.
	table at: 35 storeValue: Position.
	table at: 36 storeValue: FilterPosition.
	table at: 37 storeValue: ID.
	table at: 38 storeValue: Sequence.
	table at: 39 storeValue: Tuple.
	table at: 40 storeValue: IntegerPos.
	table at: 41 storeValue: RealPos.
	table at: 42 storeValue: FeRangeElement.
	table at: 43 storeValue: FeDataHolder.
	table at: 44 storeValue: FeEdition.
	table at: 45 storeValue: FeIDHolder.
	table at: 46 storeValue: FeLabel.
	table at: 47 storeValue: FeWork.
	table at: 48 storeValue: FeClub.
	table at: 49 storeValue: FeRevisionDetector.
	table at: 50 storeValue: FeServer.
	table at: 51 storeValue: FeSession.
	table at: 52 storeValue: FeStatusDetector.
	table at: 53 storeValue: Stepper.
	table at: 54 storeValue: TableStepper.
	table at: 55 storeValue: FeWaitDetector.
	table at: 56 storeValue: FeWrapper.
	table at: 57 storeValue: FeClubDescription.
	table at: 58 storeValue: FeHyperLink.
	table at: 59 storeValue: FeHyperRef.
	table at: 60 storeValue: FeMultiRef.
	table at: 61 storeValue: FeSingleRef.
	table at: 62 storeValue: FeLockSmith.
	table at: 63 storeValue: FeBooLockSmith.
	table at: 64 storeValue: FeChallengeLockSmith.
	table at: 65 storeValue: FeMatchLockSmith.
	table at: 66 storeValue: FeMultiLockSmith.
	table at: 67 storeValue: FeWallLockSmith.
	table at: 68 storeValue: FePath.
	table at: 69 storeValue: FeSet.
	table at: 70 storeValue: FeText.
	table at: 71 storeValue: FeWrapperSpec.
	table at: 72 storeValue: XnRegion.
	table at: 73 storeValue: CrossRegion.
	table at: 74 storeValue: Filter.
	table at: 75 storeValue: IDRegion.
	table at: 76 storeValue: IntegerRegion.
	table at: 77 storeValue: RealRegion.
	table at: 78 storeValue: SequenceRegion.
	table at: 79 storeValue: PrimValue.
	table at: 80 storeValue: PrimFloatValue.
	table at: 81 storeValue: PrimIntValue.!

{void} fillRequestTable1: table {PtrArray}
	
	table at: 27 storeValue: 
		(HHandler make: (RequestHandler pointerToStaticMember: #IDSpace.U.unique.U.N0 with: 'HFn')).
	table at: 283 storeValue: 
		(HHHandler make: (RequestHandler pointerToStaticMember: #IDSpace.U.export.U.N1: with: 'HHFn')
			with: IDSpace).
	table at: 430 storeValue: 
		(HHHHandler make: (RequestHandler pointerToStaticMember: #IDSpace.U.iDsFromServer.U.N2:with: with: 'HHHFn')
			with: IDSpace
			with: Sequence).
	table at: 28 storeValue: 
		(HHHandler make: (RequestHandler pointerToStaticMember: #IDSpace.U.newID.U.N1: with: 'HHFn')
			with: IDSpace).
	table at: 29 storeValue: 
		(HHHHandler make: (RequestHandler pointerToStaticMember: #IDSpace.U.newIDs.U.N2:with: with: 'HHHFn')
			with: IDSpace
			with: PrimIntValue).

"Requests for class IntegerSpace"

	table at: 30 storeValue: 
		(HHandler make: (RequestHandler pointerToStaticMember: #IntegerSpace.U.make.U.N0 with: 'HFn')).
	table at: 31 storeValue: 
		(HHBHandler make: (RequestHandler pointerToStaticMember: #IntegerSpace.U.above.U.N2:with: with: 'HHBFn')
			with: IntegerPos).
	table at: 32 storeValue: 
		(HHBHandler make: (RequestHandler pointerToStaticMember: #IntegerSpace.U.below.U.N2:with: with: 'HHBFn')
			with: IntegerPos).
	table at: 33 storeValue: 
		(HHHHandler make: (RequestHandler pointerToStaticMember: #IntegerSpace.U.interval.U.N2:with: with: 'HHHFn')
			with: IntegerPos
			with: IntegerPos).
	table at: 34 storeValue: 
		(HHHandler make: (RequestHandler pointerToStaticMember: #IntegerSpace.U.position.U.N1: with: 'HHFn')
			with: PrimIntValue).
	table at: 35 storeValue: 
		(HHHandler make: (RequestHandler pointerToStaticMember: #IntegerSpace.U.translation.U.N1: with: 'HHFn')
			with: PrimIntValue).

"Requests for class RealSpace"

	table at: 284 storeValue: 
		(HHandler make: (RequestHandler pointerToStaticMember: #RealSpace.U.make.U.N0 with: 'HFn')).
	table at: 36 storeValue: 
		(HHHBHandler make: (RequestHandler pointerToStaticMember: #RealSpace.U.above.U.N3:with:with: with: 'HHHBFn')
			with: RealSpace
			with: RealPos).
	table at: 37 storeValue: 
		(HHHBHandler make: (RequestHandler pointerToStaticMember: #RealSpace.U.below.U.N3:with:with: with: 'HHHBFn')
			with: RealSpace
			with: RealPos).
	table at: 38 storeValue: 
		(HHHHHandler make: (RequestHandler pointerToStaticMember: #RealSpace.U.interval.U.N3:with:with: with: 'HHHHFn')
			with: RealSpace
			with: RealPos
			with: RealPos).
	table at: 39 storeValue: 
		(HHHHandler make: (RequestHandler pointerToStaticMember: #RealSpace.U.position.U.N2:with: with: 'HHHFn')
			with: RealSpace
			with: PrimFloatValue).

"Requests for class SequenceSpace"

	table at: 40 storeValue: 
		(HHandler make: (RequestHandler pointerToStaticMember: #SequenceSpace.U.make.U.N0 with: 'HFn')).
	table at: 41 storeValue: 
		(HHBHandler make: (RequestHandler pointerToStaticMember: #SequenceSpace.U.above.U.N2:with: with: 'HHBFn')
			with: Sequence).
	table at: 42 storeValue: 
		(HHBHandler make: (RequestHandler pointerToStaticMember: #SequenceSpace.U.below.U.N2:with: with: 'HHBFn')
			with: Sequence).
	table at: 43 storeValue: 
		(HHHHandler make: (RequestHandler pointerToStaticMember: #SequenceSpace.U.interval.U.N2:with: with: 'HHHFn')
			with: Sequence
			with: Sequence).
	table at: 285 storeValue: 
		(HHHandler make: (RequestHandler pointerToStaticMember: #SequenceSpace.U.mapping.U.N1: with: 'HHFn')
			with: PrimIntValue).
	table at: 286 storeValue: 
		(HHHHandler make: (RequestHandler pointerToStaticMember: #SequenceSpace.U.mapping.U.N2:with: with: 'HHHFn')
			with: PrimIntValue
			with: Sequence).
	table at: 44 storeValue: 
		(HHHandler make: (RequestHandler pointerToStaticMember: #SequenceSpace.U.position.U.N1: with: 'HHFn')
			with: PrimArray).
	table at: 45 storeValue: 
		(HHHHandler make: (RequestHandler pointerToStaticMember: #SequenceSpace.U.position.U.N2:with: with: 'HHHFn')
			with: PrimArray
			with: PrimIntValue).
	table at: 287 storeValue: 
		(HHHHandler make: (RequestHandler pointerToStaticMember: #SequenceSpace.U.prefixedBy.U.N2:with: with: 'HHHFn')
			with: Sequence
			with: PrimIntValue).

"Requests for class FillRangeDetector"


"Requests for class FillDetector"


"Requests for class KeyMaster"

	table at: 288 storeValue: 
		(HHHandler make: (RequestHandler pointerToStaticMember: #KeyMaster.U.actualAuthority.U.N1: with: 'HHFn')
			with: FeKeyMaster).
	table at: 289 storeValue: 
		(HHHandler make: (RequestHandler pointerToStaticMember: #KeyMaster.U.copy.U.N1: with: 'HHFn')
			with: FeKeyMaster).
	table at: 290 storeValue: 
		(BHHHandler make: (RequestHandler pointerToStaticMember: #KeyMaster.U.hasAuthority.U.N2:with: with: 'BHHFn')
			with: FeKeyMaster
			with: ID).
	table at: 291 storeValue: 
		(VHHHandler make: (RequestHandler pointerToStaticMember: #KeyMaster.U.incorporate.U.N2:with: with: 'VHHFn')
			with: FeKeyMaster
			with: FeKeyMaster).
	table at: 292 storeValue: 
		(HHHandler make: (RequestHandler pointerToStaticMember: #KeyMaster.U.loginAuthority.U.N1: with: 'HHFn')
			with: FeKeyMaster).
	table at: 293 storeValue: 
		(VHHHandler make: (RequestHandler pointerToStaticMember: #KeyMaster.U.removeLogins.U.N2:with: with: 'VHHFn')
			with: FeKeyMaster
			with: IDRegion).

"Requests for class Lock"


"Requests for class BooLock"

	table at: 431 storeValue: 
		(HHHandler make: (RequestHandler pointerToStaticMember: #BooLock.U.boo.U.N1: with: 'HHFn')
			with: BooLock).

"Requests for class ChallengeLock"

	table at: 432 storeValue: 
		(HHHandler make: (RequestHandler pointerToStaticMember: #ChallengeLock.U.challenge.U.N1: with: 'HHFn')
			with: ChallengeLock).
	table at: 433 storeValue: 
		(HHHHandler make: (RequestHandler pointerToStaticMember: #ChallengeLock.U.response.U.N2:with: with: 'HHHFn')
			with: ChallengeLock
			with: PrimIntArray).

"Requests for class MatchLock"

	table at: 434 storeValue: 
		(HHHHandler make: (RequestHandler pointerToStaticMember: #MatchLock.U.encryptedPassword.U.N2:with: with: 'HHHFn')
			with: MatchLock
			with: PrimIntArray).

"Requests for class MultiLock"

	table at: 435 storeValue: 
		(HHHHandler make: (RequestHandler pointerToStaticMember: #MultiLock.U.lock.U.N2:with: with: 'HHHFn')
			with: MultiLock
			with: Sequence).
	table at: 436 storeValue: 
		(HHHandler make: (RequestHandler pointerToStaticMember: #MultiLock.U.lockNames.U.N1: with: 'HHFn')
			with: MultiLock).

"Requests for class WallLock"


"Requests for class Mapping"

	table at: 46 storeValue: 
		(HHHHandler make: (RequestHandler pointerToStaticMember: #Mapping.U.combine.U.N2:with: with: 'HHHFn')
			with: Mapping
			with: Mapping).
	table at: 47 storeValue: 
		(HHHandler make: (RequestHandler pointerToStaticMember: #Mapping.U.domain.U.N1: with: 'HHFn')
			with: Mapping).
	table at: 294 storeValue: 
		(HHHandler make: (RequestHandler pointerToStaticMember: #Mapping.U.domainSpace.U.N1: with: 'HHFn')
			with: Mapping).
	table at: 48 storeValue: 
		(HHHandler make: (RequestHandler pointerToStaticMember: #Mapping.U.inverse.U.N1: with: 'HHFn')
			with: Mapping).
	table at: 49 storeValue: 
		(BHHandler make: (RequestHandler pointerToStaticMember: #Mapping.U.isComplete.U.N1: with: 'BHFn')
			with: Mapping).
	table at: 50 storeValue: 
		(BHHandler make: (RequestHandler pointerToStaticMember: #Mapping.U.isIdentity.U.N1: with: 'BHFn')
			with: Mapping).
	table at: 51 storeValue: 
		(HHHHandler make: (RequestHandler pointerToStaticMember: #Mapping.U.of.U.N2:with: with: 'HHHFn')
			with: Mapping
			with: Position).
	table at: 52 storeValue: 
		(HHHHandler make: (RequestHandler pointerToStaticMember: #Mapping.U.ofAll.U.N2:with: with: 'HHHFn')
			with: Mapping
			with: XnRegion).
	table at: 295 storeValue: 
		(HHHandler make: (RequestHandler pointerToStaticMember: #Mapping.U.range.U.N1: with: 'HHFn')
			with: Mapping).
	table at: 296 storeValue: 
		(HHHandler make: (RequestHandler pointerToStaticMember: #Mapping.U.rangeSpace.U.N1: with: 'HHFn')
			with: Mapping).
	table at: 53 storeValue: 
		(HHHHandler make: (RequestHandler pointerToStaticMember: #Mapping.U.restrict.U.N2:with: with: 'HHHFn')
			with: Mapping
			with: XnRegion).
	table at: 54 storeValue: 
		(HHHandler make: (RequestHandler pointerToStaticMember: #Mapping.U.simplerMappings.U.N1: with: 'HHFn')
			with: Mapping).
	table at: 55 storeValue: 
		(HHHandler make: (RequestHandler pointerToStaticMember: #Mapping.U.unrestricted.U.N1: with: 'HHFn')
			with: Mapping).

"Requests for class CrossMapping"

	table at: 297 storeValue: 
		(HHHHandler make: (RequestHandler pointerToStaticMember: #CrossMapping.U.subMapping.U.N2:with: with: 'HHHFn')
			with: CrossMapping
			with: PrimIntValue).
	table at: 298 storeValue: 
		(HHHandler make: (RequestHandler pointerToStaticMember: #CrossMapping.U.subMappings.U.N1: with: 'HHFn')
			with: CrossMapping).

"Requests for class IntegerMapping"

	table at: 56 storeValue: 
		(HHHandler make: (RequestHandler pointerToStaticMember: #IntegerMapping.U.translation.U.N1: with: 'HHFn')
			with: IntegerMapping).

"Requests for class SequenceMapping"

	table at: 57 storeValue: 
		(HHHandler make: (RequestHandler pointerToStaticMember: #SequenceMapping.U.shift.U.N1: with: 'HHFn')
			with: SequenceMapping).
	table at: 58 storeValue: 
		(HHHandler make: (RequestHandler pointerToStaticMember: #SequenceMapping.U.translation.U.N1: with: 'HHFn')
			with: SequenceMapping).

"Requests for class OrderSpec"

	table at: 299 storeValue: 
		(HHHandler make: (RequestHandler pointerToStaticMember: #OrderSpec.U.coordinateSpace.U.N1: with: 'HHFn')
			with: OrderSpec).
	table at: 59 storeValue: 
		(BHHHHandler make: (RequestHandler pointerToStaticMember: #OrderSpec.U.follows.U.N3:with:with: with: 'BHHHFn')
			with: OrderSpec
			with: Position
			with: Position).
	table at: 300 storeValue: 
		(HHHandler make: (RequestHandler pointerToStaticMember: #OrderSpec.U.reversed.U.N1: with: 'HHFn')
			with: OrderSpec).

"Requests for class CrossOrderSpec"

	table at: 301 storeValue: 
		(HHHandler make: (RequestHandler pointerToStaticMember: #CrossOrderSpec.U.lexOrder.U.N1: with: 'HHFn')
			with: CrossOrderSpec).
	table at: 302 storeValue: 
		(HHHHandler make: (RequestHandler pointerToStaticMember: #CrossOrderSpec.U.subOrder.U.N2:with: with: 'HHHFn')
			with: CrossOrderSpec
			with: PrimIntValue).
	table at: 303 storeValue: 
		(HHHandler make: (RequestHandler pointerToStaticMember: #CrossOrderSpec.U.subOrders.U.N1: with: 'HHFn')
			with: CrossOrderSpec).

"Requests for class Position"

	table at: 60 storeValue: 
		(HHHandler make: (RequestHandler pointerToStaticMember: #Position.U.asRegion.U.N1: with: 'HHFn')
			with: Position).
	table at: 304 storeValue: 
		(HHHandler make: (RequestHandler pointerToStaticMember: #Position.U.coordinateSpace.U.N1: with: 'HHFn')
			with: Position).

"Requests for class FilterPosition"

	table at: 437 storeValue: 
		(HHHandler make: (RequestHandler pointerToStaticMember: #FilterPosition.U.baseRegion.U.N1: with: 'HHFn')
			with: FilterPosition).

"Requests for class ID"

	table at: 305 storeValue: 
		(HHHandler make: (RequestHandler pointerToStaticMember: #ID.U.import.U.N1: with: 'HHFn')
			with: PrimIntArray).
	table at: 306 storeValue: 
		(HHHandler make: (RequestHandler pointerToStaticMember: #ID.U.export.U.N1: with: 'HHFn')
			with: ID).

"Requests for class Sequence"

	table at: 61 storeValue: 
		(HHHandler make: (RequestHandler pointerToStaticMember: #Sequence.U.firstIndex.U.N1: with: 'HHFn')
			with: Sequence).
	table at: 307 storeValue: 
		(HHHHandler make: (RequestHandler pointerToStaticMember: #Sequence.U.integerAt.U.N2:with: with: 'HHHFn')
			with: Sequence
			with: PrimIntValue).
	table at: 62 storeValue: 
		(HHHandler make: (RequestHandler pointerToStaticMember: #Sequence.U.integers.U.N1: with: 'HHFn')
			with: Sequence).
	table at: 63 storeValue: 
		(BHHandler make: (RequestHandler pointerToStaticMember: #Sequence.U.isZero.U.N1: with: 'BHFn')
			with: Sequence).
	table at: 308 storeValue: 
		(HHHandler make: (RequestHandler pointerToStaticMember: #Sequence.U.lastIndex.U.N1: with: 'HHFn')
			with: Sequence).
	table at: 309 storeValue: 
		(HHHHHandler make: (RequestHandler pointerToStaticMember: #Sequence.U.with.U.N3:with:with: with: 'HHHHFn')
			with: Sequence
			with: PrimIntValue
			with: PrimIntValue).

"Requests for class Tuple"

	table at: 64 storeValue: 
		(HHHHandler make: (RequestHandler pointerToStaticMember: #Tuple.U.coordinate.U.N2:with: with: 'HHHFn')
			with: Tuple
			with: PrimIntValue).
	table at: 65 storeValue: 
		(HHHandler make: (RequestHandler pointerToStaticMember: #Tuple.U.coordinates.U.N1: with: 'HHFn')
			with: Tuple).

"Requests for class Integer"

	table at: 66 storeValue: 
		(HHHandler make: (RequestHandler pointerToStaticMember: #Integer.U.value.U.N1: with: 'HHFn')
			with: IntegerPos).

"Requests for class Real"

	table at: 67 storeValue: 
		(HHHandler make: (RequestHandler pointerToStaticMember: #Real.U.value.U.N1: with: 'HHFn')
			with: RealPos).

"Requests for class RangeElement"

	table at: 68 storeValue: 
		(HHandler make: (RequestHandler pointerToStaticMember: #RangeElement.U.placeHolder.U.N0 with: 'HFn')).
	table at: 310 storeValue: 
		(HHHandler make: (RequestHandler pointerToStaticMember: #RangeElement.U.again.U.N1: with: 'HHFn')
			with: FeRangeElement).
	table at: 311 storeValue: 
		(BHHHandler make: (RequestHandler pointerToStaticMember: #RangeElement.U.canMakeIdentical.U.N2:with: with: 'BHHFn')
			with: FeRangeElement
			with: FeRangeElement).
	table at: 312 storeValue: 
		(SpecialHandler make: (PromiseManager pointerToStaticMember: #fillDetector: with: 'VHFn')).
	self fillRequestTable2: table.!

{void} fillRequestTable2: table {PtrArray}
	
	table at: 69 storeValue: 
		(BHHHandler make: (RequestHandler pointerToStaticMember: #RangeElement.U.isIdentical.U.N2:with: with: 'BHHFn')
			with: FeRangeElement
			with: FeRangeElement).
	table at: 70 storeValue: 
		(HHHandler make: (RequestHandler pointerToStaticMember: #RangeElement.U.label.U.N1: with: 'HHFn')
			with: FeRangeElement).
	table at: 313 storeValue: 
		(VHHHandler make: (RequestHandler pointerToStaticMember: #RangeElement.U.makeIdentical.U.N2:with: with: 'VHHFn')
			with: FeRangeElement
			with: FeRangeElement).
	table at: 314 storeValue: 
		(HHHandler make: (RequestHandler pointerToStaticMember: #RangeElement.U.owner.U.N1: with: 'HHFn')
			with: FeRangeElement).
	table at: 71 storeValue: 
		(HHHHandler make: (RequestHandler pointerToStaticMember: #RangeElement.U.relabelled.U.N2:with: with: 'HHHFn')
			with: FeRangeElement
			with: FeLabel).
	table at: 315 storeValue: 
		(VHHHandler make: (RequestHandler pointerToStaticMember: #RangeElement.U.setOwner.U.N2:with: with: 'VHHFn')
			with: FeRangeElement
			with: ID).
	table at: 72 storeValue: 
		(HHHandler make: (RequestHandler pointerToStaticMember: #RangeElement.U.transcluders.U.N1: with: 'HHFn')
			with: FeRangeElement).
	table at: 73 storeValue: 
		(HHHHandler make: (RequestHandler pointerToStaticMember: #RangeElement.U.transcluders.U.N2:with: with: 'HHHFn')
			with: FeRangeElement
			with: Filter).
	table at: 74 storeValue: 
		(HHHHHandler make: (RequestHandler pointerToStaticMember: #RangeElement.U.transcluders.U.N3:with:with: with: 'HHHHFn')
			with: FeRangeElement
			with: Filter
			with: Filter).
	table at: 75 storeValue: 
		(HHHHHHandler make: (RequestHandler pointerToStaticMember: #RangeElement.U.transcluders.U.N4:with:with:with: with: 'HHHHHFn')
			with: FeRangeElement
			with: Filter
			with: Filter
			with: PrimIntValue).
	table at: 316 storeValue: 
		(HHHHHHHandler make: (RequestHandler pointerToStaticMember: #RangeElement.U.transcluders.U.N5:with:with:with:with: with: 'HHHHHHFn')
			with: FeRangeElement
			with: Filter
			with: Filter
			with: PrimIntValue
			with: FeEdition).
	table at: 76 storeValue: 
		(HHHandler make: (RequestHandler pointerToStaticMember: #RangeElement.U.works.U.N1: with: 'HHFn')
			with: FeRangeElement).
	table at: 77 storeValue: 
		(HHHHandler make: (RequestHandler pointerToStaticMember: #RangeElement.U.works.U.N2:with: with: 'HHHFn')
			with: FeRangeElement
			with: Filter).
	table at: 78 storeValue: 
		(HHHHHandler make: (RequestHandler pointerToStaticMember: #RangeElement.U.works.U.N3:with:with: with: 'HHHHFn')
			with: FeRangeElement
			with: Filter
			with: PrimIntValue).
	table at: 317 storeValue: 
		(HHHHHHandler make: (RequestHandler pointerToStaticMember: #RangeElement.U.works.U.N4:with:with:with: with: 'HHHHHFn')
			with: FeRangeElement
			with: Filter
			with: PrimIntValue
			with: FeEdition).

"Requests for class DataHolder"

	table at: 79 storeValue: 
		(HHHandler make: (RequestHandler pointerToStaticMember: #DataHolder.U.make.U.N1: with: 'HHFn')
			with: PrimValue).
	table at: 80 storeValue: 
		(HHHandler make: (RequestHandler pointerToStaticMember: #DataHolder.U.value.U.N1: with: 'HHFn')
			with: FeDataHolder).

"Requests for class Edition"

	table at: 81 storeValue: 
		(HHHandler make: (RequestHandler pointerToStaticMember: #Edition.U.empty.U.N1: with: 'HHFn')
			with: CoordinateSpace).
	table at: 82 storeValue: 
		(HHHHandler make: (RequestHandler pointerToStaticMember: #Edition.U.fromAll.U.N2:with: with: 'HHHFn')
			with: XnRegion
			with: FeRangeElement).
	table at: 83 storeValue: 
		(HHHandler make: (RequestHandler pointerToStaticMember: #Edition.U.fromArray.U.N1: with: 'HHFn')
			with: PrimArray).
	table at: 84 storeValue: 
		(HHHHandler make: (RequestHandler pointerToStaticMember: #Edition.U.fromArray.U.N2:with: with: 'HHHFn')
			with: PrimArray
			with: XnRegion).
	table at: 318 storeValue: 
		(HHHHHandler make: (RequestHandler pointerToStaticMember: #Edition.U.fromArray.U.N3:with:with: with: 'HHHHFn')
			with: PrimArray
			with: XnRegion
			with: OrderSpec).
	table at: 85 storeValue: 
		(HHHHandler make: (RequestHandler pointerToStaticMember: #Edition.U.fromOne.U.N2:with: with: 'HHHFn')
			with: Position
			with: FeRangeElement).
	table at: 86 storeValue: 
		(HHHandler make: (RequestHandler pointerToStaticMember: #Edition.U.placeHolders.U.N1: with: 'HHFn')
			with: XnRegion).
	table at: 319 storeValue: 
		(HHHHandler make: (RequestHandler pointerToStaticMember: #Edition.U.canMakeRangeIdentical.U.N2:with: with: 'HHHFn')
			with: FeEdition
			with: FeEdition).
	table at: 320 storeValue: 
		(HHHHHandler make: (RequestHandler pointerToStaticMember: #Edition.U.canMakeRangeIdentical.U.N3:with:with: with: 'HHHHFn')
			with: FeEdition
			with: FeEdition
			with: XnRegion).
	table at: 87 storeValue: 
		(HHHHandler make: (RequestHandler pointerToStaticMember: #Edition.U.combine.U.N2:with: with: 'HHHFn')
			with: FeEdition
			with: FeEdition).
	table at: 88 storeValue: 
		(HHHandler make: (RequestHandler pointerToStaticMember: #Edition.U.coordinateSpace.U.N1: with: 'HHFn')
			with: FeEdition).
	table at: 89 storeValue: 
		(HHHHandler make: (RequestHandler pointerToStaticMember: #Edition.U.copy.U.N2:with: with: 'HHHFn')
			with: FeEdition
			with: XnRegion).
	table at: 321 storeValue: 
		(HHHHandler make: (RequestHandler pointerToStaticMember: #Edition.U.cost.U.N2:with: with: 'HHHFn')
			with: FeEdition
			with: PrimIntValue).
	table at: 90 storeValue: 
		(HHHandler make: (RequestHandler pointerToStaticMember: #Edition.U.count.U.N1: with: 'HHFn')
			with: FeEdition).
	table at: 91 storeValue: 
		(HHHandler make: (RequestHandler pointerToStaticMember: #Edition.U.domain.U.N1: with: 'HHFn')
			with: FeEdition).
	table at: 92 storeValue: 
		(VHHHandler make: (RequestHandler pointerToStaticMember: #Edition.U.endorse.U.N2:with: with: 'VHHFn')
			with: FeEdition
			with: CrossRegion).
	table at: 93 storeValue: 
		(HHHandler make: (RequestHandler pointerToStaticMember: #Edition.U.endorsements.U.N1: with: 'HHFn')
			with: FeEdition).
	table at: 322 storeValue: 
		(SpecialHandler make: (PromiseManager pointerToStaticMember: #fillRangeDetector: with: 'VHFn')).
	table at: 94 storeValue: 
		(HHHHandler make: (RequestHandler pointerToStaticMember: #Edition.U.get.U.N2:with: with: 'HHHFn')
			with: FeEdition
			with: Position).
	table at: 95 storeValue: 
		(BHHHandler make: (RequestHandler pointerToStaticMember: #Edition.U.hasPosition.U.N2:with: with: 'BHHFn')
			with: FeEdition
			with: Position).
	table at: 96 storeValue: 
		(BHHandler make: (RequestHandler pointerToStaticMember: #Edition.U.isEmpty.U.N1: with: 'BHFn')
			with: FeEdition).
	table at: 97 storeValue: 
		(BHHandler make: (RequestHandler pointerToStaticMember: #Edition.U.isFinite.U.N1: with: 'BHFn')
			with: FeEdition).
	table at: 323 storeValue: 
		(BHHHandler make: (RequestHandler pointerToStaticMember: #Edition.U.isRangeIdentical.U.N2:with: with: 'BHHFn')
			with: FeEdition
			with: FeEdition).
	table at: 324 storeValue: 
		(HHHHandler make: (RequestHandler pointerToStaticMember: #Edition.U.makeRangeIdentical.U.N2:with: with: 'HHHFn')
			with: FeEdition
			with: FeEdition).
	table at: 325 storeValue: 
		(HHHHHandler make: (RequestHandler pointerToStaticMember: #Edition.U.makeRangeIdentical.U.N3:with:with: with: 'HHHHFn')
			with: FeEdition
			with: FeEdition
			with: XnRegion).
	table at: 98 storeValue: 
		(HHHHandler make: (RequestHandler pointerToStaticMember: #Edition.U.mapSharedOnto.U.N2:with: with: 'HHHFn')
			with: FeEdition
			with: FeEdition).
	table at: 326 storeValue: 
		(HHHHandler make: (RequestHandler pointerToStaticMember: #Edition.U.mapSharedTo.U.N2:with: with: 'HHHFn')
			with: FeEdition
			with: FeEdition).
	table at: 99 storeValue: 
		(HHHHandler make: (RequestHandler pointerToStaticMember: #Edition.U.notSharedWith.U.N2:with: with: 'HHHFn')
			with: FeEdition
			with: FeEdition).
	table at: 100 storeValue: 
		(HHHHHandler make: (RequestHandler pointerToStaticMember: #Edition.U.notSharedWith.U.N3:with:with: with: 'HHHHFn')
			with: FeEdition
			with: FeEdition
			with: PrimIntValue).
	table at: 101 storeValue: 
		(HHHHandler make: (RequestHandler pointerToStaticMember: #Edition.U.positionsLabelled.U.N2:with: with: 'HHHFn')
			with: FeEdition
			with: FeLabel).
	table at: 102 storeValue: 
		(HHHHandler make: (RequestHandler pointerToStaticMember: #Edition.U.positionsOf.U.N2:with: with: 'HHHFn')
			with: FeEdition
			with: FeRangeElement).
	table at: 327 storeValue: 
		(HHHHandler make: (RequestHandler pointerToStaticMember: #Edition.U.rangeOwners.U.N2:with: with: 'HHHFn')
			with: FeEdition
			with: XnRegion).
	table at: 103 storeValue: 
		(HHHandler make: (RequestHandler pointerToStaticMember: #Edition.U.rangeTranscluders.U.N1: with: 'HHFn')
			with: FeEdition).
	table at: 104 storeValue: 
		(HHHHandler make: (RequestHandler pointerToStaticMember: #Edition.U.rangeTranscluders.U.N2:with: with: 'HHHFn')
			with: FeEdition
			with: XnRegion).
	table at: 105 storeValue: 
		(HHHHHandler make: (RequestHandler pointerToStaticMember: #Edition.U.rangeTranscluders.U.N3:with:with: with: 'HHHHFn')
			with: FeEdition
			with: XnRegion
			with: Filter).
	table at: 106 storeValue: 
		(HHHHHHandler make: (RequestHandler pointerToStaticMember: #Edition.U.rangeTranscluders.U.N4:with:with:with: with: 'HHHHHFn')
			with: FeEdition
			with: XnRegion
			with: Filter
			with: Filter).
	table at: 107 storeValue: 
		(HHHHHHHandler make: (RequestHandler pointerToStaticMember: #Edition.U.rangeTranscluders.U.N5:with:with:with:with: with: 'HHHHHHFn')
			with: FeEdition
			with: XnRegion
			with: Filter
			with: Filter
			with: PrimIntValue).
	table at: 328 storeValue: 
		(HHHHHHHHandler make: (RequestHandler pointerToStaticMember: #Edition.U.rangeTranscluders.U.N6:with:with:with:with:with: with: 'HHHHHHHFn')
			with: FeEdition
			with: XnRegion
			with: Filter
			with: Filter
			with: PrimIntValue
			with: FeEdition).
	table at: 329 storeValue: 
		(HHHandler make: (RequestHandler pointerToStaticMember: #Edition.U.rangeWorks.U.N1: with: 'HHFn')
			with: FeEdition).
	table at: 330 storeValue: 
		(HHHHandler make: (RequestHandler pointerToStaticMember: #Edition.U.rangeWorks.U.N2:with: with: 'HHHFn')
			with: FeEdition
			with: XnRegion).
	table at: 331 storeValue: 
		(HHHHHandler make: (RequestHandler pointerToStaticMember: #Edition.U.rangeWorks.U.N3:with:with: with: 'HHHHFn')
			with: FeEdition
			with: XnRegion
			with: Filter).
	table at: 332 storeValue: 
		(HHHHHHandler make: (RequestHandler pointerToStaticMember: #Edition.U.rangeWorks.U.N4:with:with:with: with: 'HHHHHFn')
			with: FeEdition
			with: XnRegion
			with: Filter
			with: PrimIntValue).
	table at: 333 storeValue: 
		(HHHHHHHandler make: (RequestHandler pointerToStaticMember: #Edition.U.rangeWorks.U.N5:with:with:with:with: with: 'HHHHHHFn')
			with: FeEdition
			with: XnRegion
			with: Filter
			with: PrimIntValue
			with: FeEdition).
	table at: 108 storeValue: 
		(HHHHHandler make: (RequestHandler pointerToStaticMember: #Edition.U.rebind.U.N3:with:with: with: 'HHHHFn')
			with: FeEdition
			with: Position
			with: FeEdition).
	table at: 109 storeValue: 
		(HHHHandler make: (RequestHandler pointerToStaticMember: #Edition.U.replace.U.N2:with: with: 'HHHFn')
			with: FeEdition
			with: FeEdition).
	table at: 334 storeValue: 
		(VHHHandler make: (RequestHandler pointerToStaticMember: #Edition.U.retract.U.N2:with: with: 'VHHFn')
			with: FeEdition
			with: CrossRegion).
	table at: 110 storeValue: 
		(HHHandler make: (RequestHandler pointerToStaticMember: #Edition.U.retrieve.U.N1: with: 'HHFn')
			with: FeEdition).
	table at: 111 storeValue: 
		(HHHHandler make: (RequestHandler pointerToStaticMember: #Edition.U.retrieve.U.N2:with: with: 'HHHFn')
			with: FeEdition
			with: XnRegion).
	table at: 112 storeValue: 
		(HHHHHandler make: (RequestHandler pointerToStaticMember: #Edition.U.retrieve.U.N3:with:with: with: 'HHHHFn')
			with: FeEdition
			with: XnRegion
			with: OrderSpec).
	table at: 113 storeValue: 
		(HHHHHHandler make: (RequestHandler pointerToStaticMember: #Edition.U.retrieve.U.N4:with:with:with: with: 'HHHHHFn')
			with: FeEdition
			with: XnRegion
			with: OrderSpec
			with: PrimIntValue).
	table at: 335 storeValue: 
		(HHHHandler make: (RequestHandler pointerToStaticMember: #Edition.U.setRangeOwners.U.N2:with: with: 'HHHFn')
			with: FeEdition
			with: ID).
	table at: 336 storeValue: 
		(HHHHHandler make: (RequestHandler pointerToStaticMember: #Edition.U.setRangeOwners.U.N3:with:with: with: 'HHHHFn')
			with: FeEdition
			with: ID
			with: XnRegion).
	table at: 114 storeValue: 
		(HHHHandler make: (RequestHandler pointerToStaticMember: #Edition.U.sharedRegion.U.N2:with: with: 'HHHFn')
			with: FeEdition
			with: FeEdition).
	table at: 115 storeValue: 
		(HHHHHandler make: (RequestHandler pointerToStaticMember: #Edition.U.sharedRegion.U.N3:with:with: with: 'HHHHFn')
			with: FeEdition
			with: FeEdition
			with: PrimIntValue).
	table at: 116 storeValue: 
		(HHHHandler make: (RequestHandler pointerToStaticMember: #Edition.U.sharedWith.U.N2:with: with: 'HHHFn')
			with: FeEdition
			with: FeEdition).
	table at: 117 storeValue: 
		(HHHHHandler make: (RequestHandler pointerToStaticMember: #Edition.U.sharedWith.U.N3:with:with: with: 'HHHHFn')
			with: FeEdition
			with: FeEdition
			with: PrimIntValue).
	table at: 118 storeValue: 
		(HHHandler make: (RequestHandler pointerToStaticMember: #Edition.U.stepper.U.N1: with: 'HHFn')
			with: FeEdition).
	table at: 119 storeValue: 
		(HHHHandler make: (RequestHandler pointerToStaticMember: #Edition.U.stepper.U.N2:with: with: 'HHHFn')
			with: FeEdition
			with: XnRegion).
	table at: 337 storeValue: 
		(HHHHHandler make: (RequestHandler pointerToStaticMember: #Edition.U.stepper.U.N3:with:with: with: 'HHHHFn')
			with: FeEdition
			with: XnRegion
			with: OrderSpec).
	table at: 120 storeValue: 
		(HHHandler make: (RequestHandler pointerToStaticMember: #Edition.U.theOne.U.N1: with: 'HHFn')
			with: FeEdition).
	table at: 121 storeValue: 
		(HHHHandler make: (RequestHandler pointerToStaticMember: #Edition.U.transformedBy.U.N2:with: with: 'HHHFn')
			with: FeEdition
			with: Mapping).
	table at: 122 storeValue: 
		(HHHandler make: (RequestHandler pointerToStaticMember: #Edition.U.visibleEndorsements.U.N1: with: 'HHFn')
			with: FeEdition).
	table at: 123 storeValue: 
		(HHHHHandler make: (RequestHandler pointerToStaticMember: #Edition.U.with.U.N3:with:with: with: 'HHHHFn')
			with: FeEdition
			with: Position
			with: FeRangeElement).
	self fillRequestTable3: table.!

{void} fillRequestTable3: table {PtrArray}
	
	table at: 124 storeValue: 
		(HHHHHandler make: (RequestHandler pointerToStaticMember: #Edition.U.withAll.U.N3:with:with: with: 'HHHHFn')
			with: FeEdition
			with: XnRegion
			with: FeRangeElement).
	table at: 125 storeValue: 
		(HHHHandler make: (RequestHandler pointerToStaticMember: #Edition.U.without.U.N2:with: with: 'HHHFn')
			with: FeEdition
			with: Position).
	table at: 126 storeValue: 
		(HHHHandler make: (RequestHandler pointerToStaticMember: #Edition.U.withoutAll.U.N2:with: with: 'HHHFn')
			with: FeEdition
			with: XnRegion).

"Requests for class IDHolder"

	table at: 338 storeValue: 
		(HHHandler make: (RequestHandler pointerToStaticMember: #IDHolder.U.make.U.N1: with: 'HHFn')
			with: ID).
	table at: 339 storeValue: 
		(HHHandler make: (RequestHandler pointerToStaticMember: #IDHolder.U.iD.U.N1: with: 'HHFn')
			with: FeIDHolder).

"Requests for class Label"

	table at: 340 storeValue: 
		(HHandler make: (RequestHandler pointerToStaticMember: #Label.U.make.U.N0 with: 'HFn')).

"Requests for class Work"

	table at: 127 storeValue: 
		(HHHandler make: (RequestHandler pointerToStaticMember: #Work.U.make.U.N1: with: 'HHFn')
			with: FeEdition).
	table at: 128 storeValue: 
		(BHHandler make: (RequestHandler pointerToStaticMember: #Work.U.canRead.U.N1: with: 'BHFn')
			with: FeWork).
	table at: 129 storeValue: 
		(BHHandler make: (RequestHandler pointerToStaticMember: #Work.U.canRevise.U.N1: with: 'BHFn')
			with: FeWork).
	table at: 130 storeValue: 
		(HHHandler make: (RequestHandler pointerToStaticMember: #Work.U.editClub.U.N1: with: 'HHFn')
			with: FeWork).
	table at: 131 storeValue: 
		(HHHandler make: (RequestHandler pointerToStaticMember: #Work.U.edition.U.N1: with: 'HHFn')
			with: FeWork).
	table at: 341 storeValue: 
		(VHHHandler make: (RequestHandler pointerToStaticMember: #Work.U.endorse.U.N2:with: with: 'VHHFn')
			with: FeWork
			with: CrossRegion).
	table at: 132 storeValue: 
		(HHHandler make: (RequestHandler pointerToStaticMember: #Work.U.endorsements.U.N1: with: 'HHFn')
			with: FeWork).
	table at: 133 storeValue: 
		(VHHandler make: (RequestHandler pointerToStaticMember: #Work.U.grab.U.N1: with: 'VHFn')
			with: FeWork).
	table at: 342 storeValue: 
		(HHHandler make: (RequestHandler pointerToStaticMember: #Work.U.grabber.U.N1: with: 'HHFn')
			with: FeWork).
	table at: 343 storeValue: 
		(HHHandler make: (RequestHandler pointerToStaticMember: #Work.U.historyClub.U.N1: with: 'HHFn')
			with: FeWork).
	table at: 134 storeValue: 
		(HHHandler make: (RequestHandler pointerToStaticMember: #Work.U.lastRevisionAuthor.U.N1: with: 'HHFn')
			with: FeWork).
	table at: 344 storeValue: 
		(HHHandler make: (RequestHandler pointerToStaticMember: #Work.U.lastRevisionNumber.U.N1: with: 'HHFn')
			with: FeWork).
	table at: 135 storeValue: 
		(HHHandler make: (RequestHandler pointerToStaticMember: #Work.U.lastRevisionTime.U.N1: with: 'HHFn')
			with: FeWork).
	table at: 136 storeValue: 
		(HHHandler make: (RequestHandler pointerToStaticMember: #Work.U.readClub.U.N1: with: 'HHFn')
			with: FeWork).
	table at: 137 storeValue: 
		(VHHandler make: (RequestHandler pointerToStaticMember: #Work.U.release.U.N1: with: 'VHFn')
			with: FeWork).
	table at: 345 storeValue: 
		(VHHandler make: (RequestHandler pointerToStaticMember: #Work.U.removeEditClub.U.N1: with: 'VHFn')
			with: FeWork).
	table at: 346 storeValue: 
		(VHHandler make: (RequestHandler pointerToStaticMember: #Work.U.removeReadClub.U.N1: with: 'VHFn')
			with: FeWork).
	table at: 138 storeValue: 
		(VHHandler make: (RequestHandler pointerToStaticMember: #Work.U.requestGrab.U.N1: with: 'VHFn')
			with: FeWork).
	table at: 347 storeValue: 
		(VHHHandler make: (RequestHandler pointerToStaticMember: #Work.U.retract.U.N2:with: with: 'VHHFn')
			with: FeWork
			with: CrossRegion).
	table at: 139 storeValue: 
		(VHHHandler make: (RequestHandler pointerToStaticMember: #Work.U.revise.U.N2:with: with: 'VHHFn')
			with: FeWork
			with: FeEdition).
	table at: 348 storeValue: 
		(SpecialHandler make: (PromiseManager pointerToStaticMember: #revisionDetector: with: 'VHFn')).
	table at: 349 storeValue: 
		(HHHandler make: (RequestHandler pointerToStaticMember: #Work.U.revisions.U.N1: with: 'HHFn')
			with: FeWork).
	table at: 350 storeValue: 
		(VHHHandler make: (RequestHandler pointerToStaticMember: #Work.U.setEditClub.U.N2:with: with: 'VHHFn')
			with: FeWork
			with: ID).
	table at: 351 storeValue: 
		(VHHHandler make: (RequestHandler pointerToStaticMember: #Work.U.setHistoryClub.U.N2:with: with: 'VHHFn')
			with: FeWork
			with: ID).
	table at: 352 storeValue: 
		(VHHHandler make: (RequestHandler pointerToStaticMember: #Work.U.setReadClub.U.N2:with: with: 'VHHFn')
			with: FeWork
			with: ID).
	table at: 353 storeValue: 
		(VHHHandler make: (RequestHandler pointerToStaticMember: #Work.U.sponsor.U.N2:with: with: 'VHHFn')
			with: FeWork
			with: IDRegion).
	table at: 354 storeValue: 
		(HHHandler make: (RequestHandler pointerToStaticMember: #Work.U.sponsors.U.N1: with: 'HHFn')
			with: FeWork).
	table at: 355 storeValue: 
		(SpecialHandler make: (PromiseManager pointerToStaticMember: #statusDetector: with: 'VHFn')).
	table at: 356 storeValue: 
		(VHHHandler make: (RequestHandler pointerToStaticMember: #Work.U.unsponsor.U.N2:with: with: 'VHHFn')
			with: FeWork
			with: IDRegion).

"Requests for class Club"

	table at: 357 storeValue: 
		(HHHandler make: (RequestHandler pointerToStaticMember: #Club.U.make.U.N1: with: 'HHFn')
			with: FeEdition).
	table at: 358 storeValue: 
		(VHHandler make: (RequestHandler pointerToStaticMember: #Club.U.removeSignatureClub.U.N1: with: 'VHFn')
			with: FeClub).
	table at: 359 storeValue: 
		(VHHHandler make: (RequestHandler pointerToStaticMember: #Club.U.setSignatureClub.U.N2:with: with: 'VHHFn')
			with: FeClub
			with: ID).
	table at: 360 storeValue: 
		(HHHandler make: (RequestHandler pointerToStaticMember: #Club.U.signatureClub.U.N1: with: 'HHFn')
			with: FeClub).
	table at: 361 storeValue: 
		(HHHandler make: (RequestHandler pointerToStaticMember: #Club.U.sponsoredWorks.U.N1: with: 'HHFn')
			with: FeClub).
	table at: 362 storeValue: 
		(HHHHandler make: (RequestHandler pointerToStaticMember: #Club.U.sponsoredWorks.U.N2:with: with: 'HHHFn')
			with: FeClub
			with: Filter).

"Requests for class RevisionDetector"


"Requests for class Server"

	table at: 438 storeValue: 
		(HHandler make: (RequestHandler pointerToStaticMember: #Server.U.accessClubID.U.N0 with: 'HFn')).
	table at: 439 storeValue: 
		(HHandler make: (RequestHandler pointerToStaticMember: #Server.U.adminClubID.U.N0 with: 'HFn')).
	table at: 440 storeValue: 
		(HHandler make: (RequestHandler pointerToStaticMember: #Server.U.archiveClubID.U.N0 with: 'HFn')).
	table at: 363 storeValue: 
		(HHHandler make: (RequestHandler pointerToStaticMember: #Server.U.assignID.U.N1: with: 'HHFn')
			with: FeRangeElement).
	table at: 364 storeValue: 
		(HHHHandler make: (RequestHandler pointerToStaticMember: #Server.U.assignID.U.N2:with: with: 'HHHFn')
			with: FeRangeElement
			with: ID).
	table at: 441 storeValue: 
		(HHandler make: (RequestHandler pointerToStaticMember: #Server.U.clubDirectoryID.U.N0 with: 'HFn')).
	table at: 365 storeValue: 
		(HHandler make: (RequestHandler pointerToStaticMember: #Server.U.currentTime.U.N0 with: 'HFn')).
	table at: 442 storeValue: 
		(HHandler make: (RequestHandler pointerToStaticMember: #Server.U.encrypterName.U.N0 with: 'HFn')).
	table at: 140 storeValue: 
		(SpecialHandler make: (PromiseManager pointerToStaticMember: #forceIt: with: 'VHFn')).
	table at: 141 storeValue: 
		(HHHandler make: (RequestHandler pointerToStaticMember: #Server.U.get.U.N1: with: 'HHFn')
			with: ID).
	table at: 443 storeValue: 
		(HHandler make: (RequestHandler pointerToStaticMember: #Server.U.identifier.U.N0 with: 'HFn')).
	table at: 142 storeValue: 
		(HHHandler make: (RequestHandler pointerToStaticMember: #Server.U.iDOf.U.N1: with: 'HHFn')
			with: FeRangeElement).
	table at: 143 storeValue: 
		(HHHandler make: (RequestHandler pointerToStaticMember: #Server.U.iDsOf.U.N1: with: 'HHFn')
			with: FeRangeElement).
	table at: 144 storeValue: 
		(HHHandler make: (RequestHandler pointerToStaticMember: #Server.U.iDsOfRange.U.N1: with: 'HHFn')
			with: FeEdition).
	table at: 444 storeValue: 
		(HHHandler make: (RequestHandler pointerToStaticMember: #Server.U.login.U.N1: with: 'HHFn')
			with: ID).
	table at: 445 storeValue: 
		(HHHandler make: (RequestHandler pointerToStaticMember: #Server.U.loginByName.U.N1: with: 'HHFn')
			with: Sequence).
	table at: 446 storeValue: 
		(HHandler make: (RequestHandler pointerToStaticMember: #Server.U.emptyClubID.U.N0 with: 'HFn')).
	table at: 447 storeValue: 
		(HHandler make: (RequestHandler pointerToStaticMember: #Server.U.publicClubID.U.N0 with: 'HFn')).
	table at: 448 storeValue: 
		(HHandler make: (RequestHandler pointerToStaticMember: #Server.U.publicKey.U.N0 with: 'HFn')).
	table at: 145 storeValue: 
		(SpecialHandler make: (PromiseManager pointerToStaticMember: #setCurrentAuthor: with: 'VHFn')).
	table at: 146 storeValue: 
		(SpecialHandler make: (PromiseManager pointerToStaticMember: #setCurrentKeyMaster: with: 'VHFn')).
	table at: 147 storeValue: 
		(SpecialHandler make: (PromiseManager pointerToStaticMember: #setInitialEditClub: with: 'VHFn')).
	table at: 148 storeValue: 
		(SpecialHandler make: (PromiseManager pointerToStaticMember: #setInitialOwner: with: 'VHFn')).
	table at: 149 storeValue: 
		(SpecialHandler make: (PromiseManager pointerToStaticMember: #setInitialReadClub: with: 'VHFn')).
	table at: 150 storeValue: 
		(SpecialHandler make: (PromiseManager pointerToStaticMember: #setInitialSponsor: with: 'VHFn')).
	table at: 366 storeValue: 
		(SpecialHandler make: (PromiseManager pointerToStaticMember: #waitForConsequences: with: 'VHFn')).
	table at: 367 storeValue: 
		(SpecialHandler make: (PromiseManager pointerToStaticMember: #waitForWrite: with: 'VHFn')).

"Requests for class Session"

	table at: 449 storeValue: 
		(HHandler make: (RequestHandler pointerToStaticMember: #Session.U.current.U.N0 with: 'HFn')).
	table at: 450 storeValue: 
		(HHHandler make: (RequestHandler pointerToStaticMember: #Session.U.connectTime.U.N1: with: 'HHFn')
			with: FeSession).
	table at: 451 storeValue: 
		(VHHandler make: (RequestHandler pointerToStaticMember: #Session.U.endSession.U.N1: with: 'VHFn')
			with: FeSession).
	table at: 452 storeValue: 
		(VHBHandler make: (RequestHandler pointerToStaticMember: #Session.U.endSession.U.N2:with: with: 'VHBFn')
			with: FeSession).
	table at: 453 storeValue: 
		(HHHandler make: (RequestHandler pointerToStaticMember: #Session.U.initialLogin.U.N1: with: 'HHFn')
			with: FeSession).
	table at: 454 storeValue: 
		(HHHandler make: (RequestHandler pointerToStaticMember: #Session.U.port.U.N1: with: 'HHFn')
			with: FeSession).
	table at: 470 storeValue: 
		(BHHandler make: (RequestHandler pointerToStaticMember: #Session.U.isConnected.U.N1: with: 'BHFn')
			with: FeSession).

"Requests for class StatusDetector"


"Requests for class Stepper"

	table at: 151 storeValue: 
		(BHHandler make: (RequestHandler pointerToStaticMember: #Stepper.U.atEnd.U.N1: with: 'BHFn')
			with: Stepper).
	table at: 254 storeValue: 
		(HHHandler make: (RequestHandler pointerToStaticMember: #Stepper.U.copy.U.N1: with: 'HHFn')
			with: Stepper).
	table at: 152 storeValue: 
		(HHHandler make: (RequestHandler pointerToStaticMember: #Stepper.U.get.U.N1: with: 'HHFn')
			with: Stepper).
	table at: 153 storeValue: 
		(VHHandler make: (RequestHandler pointerToStaticMember: #Stepper.U.step.U.N1: with: 'VHFn')
			with: Stepper).
	table at: 154 storeValue: 
		(HHHandler make: (RequestHandler pointerToStaticMember: #Stepper.U.stepMany.U.N1: with: 'HHFn')
			with: Stepper).
	self fillRequestTable4: table.!

{void} fillRequestTable4: table {PtrArray}
	
	table at: 155 storeValue: 
		(HHHHandler make: (RequestHandler pointerToStaticMember: #Stepper.U.stepMany.U.N2:with: with: 'HHHFn')
			with: Stepper
			with: PrimIntValue).
	table at: 156 storeValue: 
		(HHHandler make: (RequestHandler pointerToStaticMember: #Stepper.U.theOne.U.N1: with: 'HHFn')
			with: Stepper).

"Requests for class TableStepper"

	table at: 157 storeValue: 
		(HHHandler make: (RequestHandler pointerToStaticMember: #TableStepper.U.position.U.N1: with: 'HHFn')
			with: TableStepper).
	table at: 158 storeValue: 
		(HHHandler make: (RequestHandler pointerToStaticMember: #TableStepper.U.stepManyPairs.U.N1: with: 'HHFn')
			with: TableStepper).
	table at: 159 storeValue: 
		(HHHHandler make: (RequestHandler pointerToStaticMember: #TableStepper.U.stepManyPairs.U.N2:with: with: 'HHHFn')
			with: TableStepper
			with: PrimIntValue).

"Requests for class Void"


"Requests for class WaitDetector"


"Requests for class Wrapper"

	table at: 160 storeValue: 
		(HHHandler make: (RequestHandler pointerToStaticMember: #Wrapper.U.edition.U.N1: with: 'HHFn')
			with: FeWrapper).
	table at: 368 storeValue: 
		(HHHandler make: (RequestHandler pointerToStaticMember: #Wrapper.U.inner.U.N1: with: 'HHFn')
			with: FeWrapper).

"Requests for class ClubDescription"

	table at: 369 storeValue: 
		(HHHHandler make: (RequestHandler pointerToStaticMember: #ClubDescription.U.make.U.N2:with: with: 'HHHFn')
			with: FeSet
			with: FeLockSmith).
	table at: 370 storeValue: 
		(HHHandler make: (RequestHandler pointerToStaticMember: #ClubDescription.U.lockSmith.U.N1: with: 'HHFn')
			with: FeClubDescription).
	table at: 371 storeValue: 
		(HHHandler make: (RequestHandler pointerToStaticMember: #ClubDescription.U.membership.U.N1: with: 'HHFn')
			with: FeClubDescription).
	table at: 372 storeValue: 
		(HHHHandler make: (RequestHandler pointerToStaticMember: #ClubDescription.U.withLockSmith.U.N2:with: with: 'HHHFn')
			with: FeClubDescription
			with: FeLockSmith).
	table at: 373 storeValue: 
		(HHHHandler make: (RequestHandler pointerToStaticMember: #ClubDescription.U.withMembership.U.N2:with: with: 'HHHFn')
			with: FeClubDescription
			with: FeSet).

"Requests for class HyperLink"

	table at: 161 storeValue: 
		(HHHHHandler make: (RequestHandler pointerToStaticMember: #HyperLink.U.make.U.N3:with:with: with: 'HHHHFn')
			with: FeSet
			with: FeHyperRef
			with: FeHyperRef).
	table at: 162 storeValue: 
		(HHHHandler make: (RequestHandler pointerToStaticMember: #HyperLink.U.endAt.U.N2:with: with: 'HHHFn')
			with: FeHyperLink
			with: Sequence).
	table at: 163 storeValue: 
		(HHHandler make: (RequestHandler pointerToStaticMember: #HyperLink.U.endNames.U.N1: with: 'HHFn')
			with: FeHyperLink).
	table at: 164 storeValue: 
		(HHHandler make: (RequestHandler pointerToStaticMember: #HyperLink.U.linkTypes.U.N1: with: 'HHFn')
			with: FeHyperLink).
	table at: 165 storeValue: 
		(HHHHHandler make: (RequestHandler pointerToStaticMember: #HyperLink.U.withEnd.U.N3:with:with: with: 'HHHHFn')
			with: FeHyperLink
			with: Sequence
			with: FeHyperRef).
	table at: 374 storeValue: 
		(HHHHandler make: (RequestHandler pointerToStaticMember: #HyperLink.U.withLinkTypes.U.N2:with: with: 'HHHFn')
			with: FeHyperLink
			with: FeSet).
	table at: 375 storeValue: 
		(HHHHandler make: (RequestHandler pointerToStaticMember: #HyperLink.U.withoutEnd.U.N2:with: with: 'HHHFn')
			with: FeHyperLink
			with: Sequence).

"Requests for class HyperRef"

	table at: 166 storeValue: 
		(HHHandler make: (RequestHandler pointerToStaticMember: #HyperRef.U.originalContext.U.N1: with: 'HHFn')
			with: FeHyperRef).
	table at: 167 storeValue: 
		(HHHandler make: (RequestHandler pointerToStaticMember: #HyperRef.U.pathContext.U.N1: with: 'HHFn')
			with: FeHyperRef).
	table at: 376 storeValue: 
		(HHHHandler make: (RequestHandler pointerToStaticMember: #HyperRef.U.withOriginalContext.U.N2:with: with: 'HHHFn')
			with: FeHyperRef
			with: FeWork).
	table at: 377 storeValue: 
		(HHHHandler make: (RequestHandler pointerToStaticMember: #HyperRef.U.withPathContext.U.N2:with: with: 'HHHFn')
			with: FeHyperRef
			with: FePath).
	table at: 378 storeValue: 
		(HHHHandler make: (RequestHandler pointerToStaticMember: #HyperRef.U.withWorkContext.U.N2:with: with: 'HHHFn')
			with: FeHyperRef
			with: FeWork).
	table at: 168 storeValue: 
		(HHHandler make: (RequestHandler pointerToStaticMember: #HyperRef.U.workContext.U.N1: with: 'HHFn')
			with: FeHyperRef).

"Requests for class MultiRef"

	table at: 169 storeValue: 
		(HHHandler make: (RequestHandler pointerToStaticMember: #MultiRef.U.make.U.N1: with: 'HHFn')
			with: PtrArray).
	table at: 170 storeValue: 
		(HHHHandler make: (RequestHandler pointerToStaticMember: #MultiRef.U.make.U.N2:with: with: 'HHHFn')
			with: PtrArray
			with: FeWork).
	table at: 171 storeValue: 
		(HHHHHandler make: (RequestHandler pointerToStaticMember: #MultiRef.U.make.U.N3:with:with: with: 'HHHHFn')
			with: PtrArray
			with: FeWork
			with: FeWork).
	table at: 172 storeValue: 
		(HHHHHHandler make: (RequestHandler pointerToStaticMember: #MultiRef.U.make.U.N4:with:with:with: with: 'HHHHHFn')
			with: PtrArray
			with: FeWork
			with: FeWork
			with: FePath).
	table at: 379 storeValue: 
		(HHHHandler make: (RequestHandler pointerToStaticMember: #MultiRef.U.intersect.U.N2:with: with: 'HHHFn')
			with: FeMultiRef
			with: FeMultiRef).
	table at: 380 storeValue: 
		(HHHHandler make: (RequestHandler pointerToStaticMember: #MultiRef.U.minus.U.N2:with: with: 'HHHFn')
			with: FeMultiRef
			with: FeMultiRef).
	table at: 173 storeValue: 
		(HHHandler make: (RequestHandler pointerToStaticMember: #MultiRef.U.refs.U.N1: with: 'HHFn')
			with: FeMultiRef).
	table at: 381 storeValue: 
		(HHHHandler make: (RequestHandler pointerToStaticMember: #MultiRef.U.unionWith.U.N2:with: with: 'HHHFn')
			with: FeMultiRef
			with: FeMultiRef).
	table at: 382 storeValue: 
		(HHHHandler make: (RequestHandler pointerToStaticMember: #MultiRef.U.with.U.N2:with: with: 'HHHFn')
			with: FeMultiRef
			with: FeHyperRef).
	table at: 383 storeValue: 
		(HHHHandler make: (RequestHandler pointerToStaticMember: #MultiRef.U.without.U.N2:with: with: 'HHHFn')
			with: FeMultiRef
			with: FeHyperRef).

"Requests for class SingleRef"

	table at: 174 storeValue: 
		(HHHandler make: (RequestHandler pointerToStaticMember: #SingleRef.U.make.U.N1: with: 'HHFn')
			with: FeEdition).
	table at: 175 storeValue: 
		(HHHHandler make: (RequestHandler pointerToStaticMember: #SingleRef.U.make.U.N2:with: with: 'HHHFn')
			with: FeEdition
			with: FeWork).
	table at: 176 storeValue: 
		(HHHHHandler make: (RequestHandler pointerToStaticMember: #SingleRef.U.make.U.N3:with:with: with: 'HHHHFn')
			with: FeEdition
			with: FeWork
			with: FeWork).
	table at: 177 storeValue: 
		(HHHHHHandler make: (RequestHandler pointerToStaticMember: #SingleRef.U.make.U.N4:with:with:with: with: 'HHHHHFn')
			with: FeEdition
			with: FeWork
			with: FeWork
			with: FePath).
	table at: 178 storeValue: 
		(HHHandler make: (RequestHandler pointerToStaticMember: #SingleRef.U.excerpt.U.N1: with: 'HHFn')
			with: FeSingleRef).
	table at: 384 storeValue: 
		(HHHHandler make: (RequestHandler pointerToStaticMember: #SingleRef.U.withExcerpt.U.N2:with: with: 'HHHFn')
			with: FeSingleRef
			with: FeEdition).

"Requests for class LockSmith"


"Requests for class BooLockSmith"

	table at: 455 storeValue: 
		(HHandler make: (RequestHandler pointerToStaticMember: #BooLockSmith.U.make.U.N0 with: 'HFn')).

"Requests for class ChallengeLockSmith"

	table at: 456 storeValue: 
		(HHHHandler make: (RequestHandler pointerToStaticMember: #ChallengeLockSmith.U.make.U.N2:with: with: 'HHHFn')
			with: PrimIntArray
			with: Sequence).
	table at: 457 storeValue: 
		(HHHandler make: (RequestHandler pointerToStaticMember: #ChallengeLockSmith.U.encrypterName.U.N1: with: 'HHFn')
			with: FeChallengeLockSmith).
	table at: 458 storeValue: 
		(HHHandler make: (RequestHandler pointerToStaticMember: #ChallengeLockSmith.U.publicKey.U.N1: with: 'HHFn')
			with: FeChallengeLockSmith).

"Requests for class MatchLockSmith"

	table at: 459 storeValue: 
		(HHHHandler make: (RequestHandler pointerToStaticMember: #MatchLockSmith.U.make.U.N2:with: with: 'HHHFn')
			with: PrimIntArray
			with: Sequence).
	table at: 460 storeValue: 
		(HHHandler make: (RequestHandler pointerToStaticMember: #MatchLockSmith.U.scrambledPassword.U.N1: with: 'HHFn')
			with: FeMatchLockSmith).
	table at: 461 storeValue: 
		(HHHandler make: (RequestHandler pointerToStaticMember: #MatchLockSmith.U.scramblerName.U.N1: with: 'HHFn')
			with: FeMatchLockSmith).

"Requests for class MultiLockSmith"

	table at: 462 storeValue: 
		(HHandler make: (RequestHandler pointerToStaticMember: #MultiLockSmith.U.make.U.N0 with: 'HFn')).
	table at: 463 storeValue: 
		(HHHHandler make: (RequestHandler pointerToStaticMember: #MultiLockSmith.U.lockSmith.U.N2:with: with: 'HHHFn')
			with: FeMultiLockSmith
			with: Sequence).
	table at: 464 storeValue: 
		(HHHandler make: (RequestHandler pointerToStaticMember: #MultiLockSmith.U.lockSmithNames.U.N1: with: 'HHFn')
			with: FeMultiLockSmith).
	table at: 465 storeValue: 
		(HHHHHandler make: (RequestHandler pointerToStaticMember: #MultiLockSmith.U.with.U.N3:with:with: with: 'HHHHFn')
			with: FeMultiLockSmith
			with: Sequence
			with: FeLockSmith).
	table at: 466 storeValue: 
		(HHHHandler make: (RequestHandler pointerToStaticMember: #MultiLockSmith.U.without.U.N2:with: with: 'HHHFn')
			with: FeMultiLockSmith
			with: Sequence).

"Requests for class WallLockSmith"

	table at: 467 storeValue: 
		(HHandler make: (RequestHandler pointerToStaticMember: #WallLockSmith.U.make.U.N0 with: 'HFn')).

"Requests for class Path"

	table at: 179 storeValue: 
		(HHHandler make: (RequestHandler pointerToStaticMember: #Path.U.make.U.N1: with: 'HHFn')
			with: PtrArray).
	table at: 180 storeValue: 
		(HHHHandler make: (RequestHandler pointerToStaticMember: #Path.U.follow.U.N2:with: with: 'HHHFn')
			with: FePath
			with: FeEdition).

"Requests for class Set"

	table at: 181 storeValue: 
		(HHandler make: (RequestHandler pointerToStaticMember: #Set.U.make.U.N0 with: 'HFn')).
	table at: 182 storeValue: 
		(HHHandler make: (RequestHandler pointerToStaticMember: #Set.U.make.U.N1: with: 'HHFn')
			with: PtrArray).
	table at: 183 storeValue: 
		(HHHandler make: (RequestHandler pointerToStaticMember: #Set.U.count.U.N1: with: 'HHFn')
			with: FeSet).
	table at: 184 storeValue: 
		(BHHHandler make: (RequestHandler pointerToStaticMember: #Set.U.includes.U.N2:with: with: 'BHHFn')
			with: FeSet
			with: FeRangeElement).
	table at: 385 storeValue: 
		(HHHHandler make: (RequestHandler pointerToStaticMember: #Set.U.intersect.U.N2:with: with: 'HHHFn')
			with: FeSet
			with: FeSet).
	table at: 386 storeValue: 
		(HHHHandler make: (RequestHandler pointerToStaticMember: #Set.U.minus.U.N2:with: with: 'HHHFn')
			with: FeSet
			with: FeSet).
	table at: 185 storeValue: 
		(HHHandler make: (RequestHandler pointerToStaticMember: #Set.U.theOne.U.N1: with: 'HHFn')
			with: FeSet).
	table at: 387 storeValue: 
		(HHHHandler make: (RequestHandler pointerToStaticMember: #Set.U.unionWith.U.N2:with: with: 'HHHFn')
			with: FeSet
			with: FeSet).
	table at: 388 storeValue: 
		(HHHHandler make: (RequestHandler pointerToStaticMember: #Set.U.with.U.N2:with: with: 'HHHFn')
			with: FeSet
			with: FeRangeElement).
	table at: 389 storeValue: 
		(HHHHandler make: (RequestHandler pointerToStaticMember: #Set.U.without.U.N2:with: with: 'HHHFn')
			with: FeSet
			with: FeRangeElement).

"Requests for class Text"

	table at: 186 storeValue: 
		(HHHandler make: (RequestHandler pointerToStaticMember: #Text.U.make.U.N1: with: 'HHFn')
			with: PrimArray).
	table at: 187 storeValue: 
		(HHHandler make: (RequestHandler pointerToStaticMember: #Text.U.contents.U.N1: with: 'HHFn')
			with: FeText).
	table at: 188 storeValue: 
		(HHHandler make: (RequestHandler pointerToStaticMember: #Text.U.count.U.N1: with: 'HHFn')
			with: FeText).
	table at: 189 storeValue: 
		(HHHHandler make: (RequestHandler pointerToStaticMember: #Text.U.extract.U.N2:with: with: 'HHHFn')
			with: FeText
			with: IntegerRegion).
	table at: 190 storeValue: 
		(HHHHHandler make: (RequestHandler pointerToStaticMember: #Text.U.insert.U.N3:with:with: with: 'HHHHFn')
			with: FeText
			with: PrimIntValue
			with: FeText).
	table at: 191 storeValue: 
		(HHHHHandler make: (RequestHandler pointerToStaticMember: #Text.U.move.U.N3:with:with: with: 'HHHHFn')
			with: FeText
			with: PrimIntValue
			with: IntegerRegion).
	table at: 192 storeValue: 
		(HHHHHandler make: (RequestHandler pointerToStaticMember: #Text.U.replace.U.N3:with:with: with: 'HHHHFn')
			with: FeText
			with: IntegerRegion
			with: FeText).

"Requests for class WrapperSpec"

	table at: 193 storeValue: 
		(HHHandler make: (RequestHandler pointerToStaticMember: #WrapperSpec.U.get.U.N1: with: 'HHFn')
			with: Sequence).
	table at: 194 storeValue: 
		(HHHandler make: (RequestHandler pointerToStaticMember: #WrapperSpec.U.filter.U.N1: with: 'HHFn')
			with: FeWrapperSpec).
	table at: 390 storeValue: 
		(HHHandler make: (RequestHandler pointerToStaticMember: #WrapperSpec.U.name.U.N1: with: 'HHFn')
			with: FeWrapperSpec).
	table at: 195 storeValue: 
		(HHHHandler make: (RequestHandler pointerToStaticMember: #WrapperSpec.U.wrap.U.N2:with: with: 'HHHFn')
			with: FeWrapperSpec
			with: FeEdition).

"Requests for class Region"

	table at: 196 storeValue: 
		(HHHHandler make: (RequestHandler pointerToStaticMember: #Region.U.chooseMany.U.N2:with: with: 'HHHFn')
			with: XnRegion
			with: PrimIntValue).
	table at: 197 storeValue: 
		(HHHHHandler make: (RequestHandler pointerToStaticMember: #Region.U.chooseMany.U.N3:with:with: with: 'HHHHFn')
			with: XnRegion
			with: PrimIntValue
			with: OrderSpec).
	table at: 198 storeValue: 
		(HHHandler make: (RequestHandler pointerToStaticMember: #Region.U.chooseOne.U.N1: with: 'HHFn')
			with: XnRegion).
	self fillRequestTable5: table.!

{void} fillRequestTable5: table {PtrArray}
	
	table at: 199 storeValue: 
		(HHHHandler make: (RequestHandler pointerToStaticMember: #Region.U.chooseOne.U.N2:with: with: 'HHHFn')
			with: XnRegion
			with: OrderSpec).
	table at: 200 storeValue: 
		(HHHandler make: (RequestHandler pointerToStaticMember: #Region.U.complement.U.N1: with: 'HHFn')
			with: XnRegion).
	table at: 201 storeValue: 
		(HHHandler make: (RequestHandler pointerToStaticMember: #Region.U.coordinateSpace.U.N1: with: 'HHFn')
			with: XnRegion).
	table at: 202 storeValue: 
		(HHHandler make: (RequestHandler pointerToStaticMember: #Region.U.count.U.N1: with: 'HHFn')
			with: XnRegion).
	table at: 203 storeValue: 
		(BHHHandler make: (RequestHandler pointerToStaticMember: #Region.U.hasMember.U.N2:with: with: 'BHHFn')
			with: XnRegion
			with: Position).
	table at: 204 storeValue: 
		(HHHHandler make: (RequestHandler pointerToStaticMember: #Region.U.intersect.U.N2:with: with: 'HHHFn')
			with: XnRegion
			with: XnRegion).
	table at: 205 storeValue: 
		(BHHHandler make: (RequestHandler pointerToStaticMember: #Region.U.intersects.U.N2:with: with: 'BHHFn')
			with: XnRegion
			with: XnRegion).
	table at: 206 storeValue: 
		(BHHandler make: (RequestHandler pointerToStaticMember: #Region.U.isEmpty.U.N1: with: 'BHFn')
			with: XnRegion).
	table at: 207 storeValue: 
		(BHHandler make: (RequestHandler pointerToStaticMember: #Region.U.isFinite.U.N1: with: 'BHFn')
			with: XnRegion).
	table at: 208 storeValue: 
		(BHHandler make: (RequestHandler pointerToStaticMember: #Region.U.isFull.U.N1: with: 'BHFn')
			with: XnRegion).
	table at: 209 storeValue: 
		(BHHHandler make: (RequestHandler pointerToStaticMember: #Region.U.isSubsetOf.U.N2:with: with: 'BHHFn')
			with: XnRegion
			with: XnRegion).
	table at: 210 storeValue: 
		(HHHHandler make: (RequestHandler pointerToStaticMember: #Region.U.minus.U.N2:with: with: 'HHHFn')
			with: XnRegion
			with: XnRegion).
	table at: 211 storeValue: 
		(HHHandler make: (RequestHandler pointerToStaticMember: #Region.U.stepper.U.N1: with: 'HHFn')
			with: XnRegion).
	table at: 212 storeValue: 
		(HHHHandler make: (RequestHandler pointerToStaticMember: #Region.U.stepper.U.N2:with: with: 'HHHFn')
			with: XnRegion
			with: OrderSpec).
	table at: 213 storeValue: 
		(HHHandler make: (RequestHandler pointerToStaticMember: #Region.U.theOne.U.N1: with: 'HHFn')
			with: XnRegion).
	table at: 214 storeValue: 
		(HHHHandler make: (RequestHandler pointerToStaticMember: #Region.U.unionWith.U.N2:with: with: 'HHHFn')
			with: XnRegion
			with: XnRegion).
	table at: 215 storeValue: 
		(HHHHandler make: (RequestHandler pointerToStaticMember: #Region.U.with.U.N2:with: with: 'HHHFn')
			with: XnRegion
			with: Position).
	table at: 216 storeValue: 
		(HHHHandler make: (RequestHandler pointerToStaticMember: #Region.U.without.U.N2:with: with: 'HHHFn')
			with: XnRegion
			with: Position).

"Requests for class CrossRegion"

	table at: 217 storeValue: 
		(HHHandler make: (RequestHandler pointerToStaticMember: #CrossRegion.U.boxes.U.N1: with: 'HHFn')
			with: CrossRegion).
	table at: 218 storeValue: 
		(BHHandler make: (RequestHandler pointerToStaticMember: #CrossRegion.U.isBox.U.N1: with: 'BHFn')
			with: CrossRegion).
	table at: 219 storeValue: 
		(HHHHandler make: (RequestHandler pointerToStaticMember: #CrossRegion.U.projection.U.N2:with: with: 'HHHFn')
			with: CrossRegion
			with: PrimIntValue).
	table at: 220 storeValue: 
		(HHHandler make: (RequestHandler pointerToStaticMember: #CrossRegion.U.projections.U.N1: with: 'HHFn')
			with: CrossRegion).

"Requests for class Filter"

	table at: 391 storeValue: 
		(HHHandler make: (RequestHandler pointerToStaticMember: #Filter.U.baseRegion.U.N1: with: 'HHFn')
			with: Filter).
	table at: 392 storeValue: 
		(HHHandler make: (RequestHandler pointerToStaticMember: #Filter.U.intersectedFilters.U.N1: with: 'HHFn')
			with: Filter).
	table at: 393 storeValue: 
		(BHHandler make: (RequestHandler pointerToStaticMember: #Filter.U.isAllFilter.U.N1: with: 'BHFn')
			with: Filter).
	table at: 394 storeValue: 
		(BHHandler make: (RequestHandler pointerToStaticMember: #Filter.U.isAnyFilter.U.N1: with: 'BHFn')
			with: Filter).
	table at: 221 storeValue: 
		(BHHHandler make: (RequestHandler pointerToStaticMember: #Filter.U.match.U.N2:with: with: 'BHHFn')
			with: Filter
			with: XnRegion).
	table at: 395 storeValue: 
		(HHHandler make: (RequestHandler pointerToStaticMember: #Filter.U.unionedFilters.U.N1: with: 'HHFn')
			with: Filter).

"Requests for class IDRegion"

	table at: 396 storeValue: 
		(HHHandler make: (RequestHandler pointerToStaticMember: #IDRegion.U.import.U.N1: with: 'HHFn')
			with: PrimIntArray).
	table at: 397 storeValue: 
		(HHHandler make: (RequestHandler pointerToStaticMember: #IDRegion.U.export.U.N1: with: 'HHFn')
			with: IDRegion).

"Requests for class IntegerRegion"

	table at: 222 storeValue: 
		(HHHandler make: (RequestHandler pointerToStaticMember: #IntegerRegion.U.intervals.U.N1: with: 'HHFn')
			with: IntegerRegion).
	table at: 398 storeValue: 
		(HHHHandler make: (RequestHandler pointerToStaticMember: #IntegerRegion.U.intervals.U.N2:with: with: 'HHHFn')
			with: IntegerRegion
			with: OrderSpec).
	table at: 223 storeValue: 
		(BHHandler make: (RequestHandler pointerToStaticMember: #IntegerRegion.U.isBoundedAbove.U.N1: with: 'BHFn')
			with: IntegerRegion).
	table at: 224 storeValue: 
		(BHHandler make: (RequestHandler pointerToStaticMember: #IntegerRegion.U.isBoundedBelow.U.N1: with: 'BHFn')
			with: IntegerRegion).
	table at: 225 storeValue: 
		(BHHandler make: (RequestHandler pointerToStaticMember: #IntegerRegion.U.isInterval.U.N1: with: 'BHFn')
			with: IntegerRegion).
	table at: 226 storeValue: 
		(HHHandler make: (RequestHandler pointerToStaticMember: #IntegerRegion.U.start.U.N1: with: 'HHFn')
			with: IntegerRegion).
	table at: 227 storeValue: 
		(HHHandler make: (RequestHandler pointerToStaticMember: #IntegerRegion.U.stop.U.N1: with: 'HHFn')
			with: IntegerRegion).

"Requests for class RealRegion"

	table at: 228 storeValue: 
		(HHHandler make: (RequestHandler pointerToStaticMember: #RealRegion.U.intervals.U.N1: with: 'HHFn')
			with: RealRegion).
	table at: 399 storeValue: 
		(HHHHandler make: (RequestHandler pointerToStaticMember: #RealRegion.U.intervals.U.N2:with: with: 'HHHFn')
			with: RealRegion
			with: OrderSpec).
	table at: 229 storeValue: 
		(BHHandler make: (RequestHandler pointerToStaticMember: #RealRegion.U.isBoundedAbove.U.N1: with: 'BHFn')
			with: RealRegion).
	table at: 230 storeValue: 
		(BHHandler make: (RequestHandler pointerToStaticMember: #RealRegion.U.isBoundedBelow.U.N1: with: 'BHFn')
			with: RealRegion).
	table at: 231 storeValue: 
		(BHHandler make: (RequestHandler pointerToStaticMember: #RealRegion.U.isInterval.U.N1: with: 'BHFn')
			with: RealRegion).
	table at: 232 storeValue: 
		(HHHandler make: (RequestHandler pointerToStaticMember: #RealRegion.U.lowerBound.U.N1: with: 'HHFn')
			with: RealRegion).
	table at: 233 storeValue: 
		(HHHandler make: (RequestHandler pointerToStaticMember: #RealRegion.U.upperBound.U.N1: with: 'HHFn')
			with: RealRegion).

"Requests for class SequenceRegion"

	table at: 234 storeValue: 
		(HHHandler make: (RequestHandler pointerToStaticMember: #SequenceRegion.U.intervals.U.N1: with: 'HHFn')
			with: SequenceRegion).
	table at: 400 storeValue: 
		(HHHHandler make: (RequestHandler pointerToStaticMember: #SequenceRegion.U.intervals.U.N2:with: with: 'HHHFn')
			with: SequenceRegion
			with: OrderSpec).
	table at: 235 storeValue: 
		(BHHandler make: (RequestHandler pointerToStaticMember: #SequenceRegion.U.isBoundedAbove.U.N1: with: 'BHFn')
			with: SequenceRegion).
	table at: 236 storeValue: 
		(BHHandler make: (RequestHandler pointerToStaticMember: #SequenceRegion.U.isBoundedBelow.U.N1: with: 'BHFn')
			with: SequenceRegion).
	table at: 237 storeValue: 
		(BHHandler make: (RequestHandler pointerToStaticMember: #SequenceRegion.U.isInterval.U.N1: with: 'BHFn')
			with: SequenceRegion).
	table at: 238 storeValue: 
		(HHHandler make: (RequestHandler pointerToStaticMember: #SequenceRegion.U.lowerEdge.U.N1: with: 'HHFn')
			with: SequenceRegion).
	table at: 239 storeValue: 
		(HHHandler make: (RequestHandler pointerToStaticMember: #SequenceRegion.U.lowerEdgePrefixLimit.U.N1: with: 'HHFn')
			with: SequenceRegion).
	table at: 240 storeValue: 
		(HHHandler make: (RequestHandler pointerToStaticMember: #SequenceRegion.U.lowerEdgeType.U.N1: with: 'HHFn')
			with: SequenceRegion).
	table at: 241 storeValue: 
		(HHHandler make: (RequestHandler pointerToStaticMember: #SequenceRegion.U.upperEdge.U.N1: with: 'HHFn')
			with: SequenceRegion).
	table at: 242 storeValue: 
		(HHHandler make: (RequestHandler pointerToStaticMember: #SequenceRegion.U.upperEdgePrefixLimit.U.N1: with: 'HHFn')
			with: SequenceRegion).
	table at: 243 storeValue: 
		(HHHandler make: (RequestHandler pointerToStaticMember: #SequenceRegion.U.upperEdgeType.U.N1: with: 'HHFn')
			with: SequenceRegion).

"Requests for class Value"


"Requests for class FloatValue"

	table at: 244 storeValue: 
		(SpecialHandler make: (PromiseManager pointerToStaticMember: #makeFloat: with: 'VHFn')).
	table at: 401 storeValue: 
		(HHHandler make: (RequestHandler pointerToStaticMember: #FloatValue.U.bitCount.U.N1: with: 'HHFn')
			with: PrimFloatValue).

"Requests for class IntValue"

	table at: 245 storeValue: 
		(SpecialHandler make: (PromiseManager pointerToStaticMember: #makeHumber: with: 'VHFn')).
	table at: 402 storeValue: 
		(HHHHandler make: (RequestHandler pointerToStaticMember: #IntValue.U.bitwiseAnd.U.N2:with: with: 'HHHFn')
			with: PrimIntValue
			with: PrimIntValue).
	table at: 403 storeValue: 
		(HHHHandler make: (RequestHandler pointerToStaticMember: #IntValue.U.bitwiseOr.U.N2:with: with: 'HHHFn')
			with: PrimIntValue
			with: PrimIntValue).
	table at: 404 storeValue: 
		(HHHHandler make: (RequestHandler pointerToStaticMember: #IntValue.U.bitwiseXor.U.N2:with: with: 'HHHFn')
			with: PrimIntValue
			with: PrimIntValue).
	table at: 246 storeValue: 
		(HHHHandler make: (RequestHandler pointerToStaticMember: #IntValue.U.dividedBy.U.N2:with: with: 'HHHFn')
			with: PrimIntValue
			with: PrimIntValue).
	table at: 247 storeValue: 
		(BHHHandler make: (RequestHandler pointerToStaticMember: #IntValue.U.isGE.U.N2:with: with: 'BHHFn')
			with: PrimIntValue
			with: PrimIntValue).
	table at: 405 storeValue: 
		(HHHHandler make: (RequestHandler pointerToStaticMember: #IntValue.U.leftShift.U.N2:with: with: 'HHHFn')
			with: PrimIntValue
			with: PrimIntValue).
	table at: 248 storeValue: 
		(HHHHandler make: (RequestHandler pointerToStaticMember: #IntValue.U.maximum.U.N2:with: with: 'HHHFn')
			with: PrimIntValue
			with: PrimIntValue).
	table at: 249 storeValue: 
		(HHHHandler make: (RequestHandler pointerToStaticMember: #IntValue.U.minimum.U.N2:with: with: 'HHHFn')
			with: PrimIntValue
			with: PrimIntValue).
	table at: 250 storeValue: 
		(HHHHandler make: (RequestHandler pointerToStaticMember: #IntValue.U.minus.U.N2:with: with: 'HHHFn')
			with: PrimIntValue
			with: PrimIntValue).
	table at: 406 storeValue: 
		(HHHHandler make: (RequestHandler pointerToStaticMember: #IntValue.U.mod.U.N2:with: with: 'HHHFn')
			with: PrimIntValue
			with: PrimIntValue).
	table at: 251 storeValue: 
		(HHHHandler make: (RequestHandler pointerToStaticMember: #IntValue.U.plus.U.N2:with: with: 'HHHFn')
			with: PrimIntValue
			with: PrimIntValue).
	table at: 407 storeValue: 
		(HHHandler make: (RequestHandler pointerToStaticMember: #IntValue.U.bitCount.U.N1: with: 'HHFn')
			with: PrimIntValue).
	table at: 252 storeValue: 
		(HHHHandler make: (RequestHandler pointerToStaticMember: #IntValue.U.times.U.N2:with: with: 'HHHFn')
			with: PrimIntValue
			with: PrimIntValue).!

{void} fillRequestTable: table {PtrArray}
	

"Requests for class Promise"

	table at: 253 storeValue: 
		(SpecialHandler make: (PromiseManager pointerToStaticMember: #waiveEm: with: 'VHFn')).
	table at: 1 storeValue: 
		(SpecialHandler make: (PromiseManager pointerToStaticMember: #delayCast: with: 'VHFn')).
	table at: 2 storeValue: 
		(SpecialHandler make: (PromiseManager pointerToStaticMember: #equals: with: 'VHFn')).
	table at: 3 storeValue: 
		(SpecialHandler make: (PromiseManager pointerToStaticMember: #promiseHash: with: 'VHFn')).
	table at: 4 storeValue: 
		(SpecialHandler make: (PromiseManager pointerToStaticMember: #testKindOf: with: 'VHFn')).
	table at: 5 storeValue: 
		(SpecialHandler make: (PromiseManager pointerToStaticMember: #waiveIt: with: 'VHFn')).

"Requests for class Adminer"

	table at: 408 storeValue: 
		(HHandler make: (RequestHandler pointerToStaticMember: #Adminer.U.make.U.N0 with: 'HFn')).
	table at: 409 storeValue: 
		(VHBHandler make: (RequestHandler pointerToStaticMember: #Adminer.U.acceptConnections.U.N2:with: with: 'VHBFn')
			with: FeAdminer).
	table at: 410 storeValue: 
		(HHHandler make: (RequestHandler pointerToStaticMember: #Adminer.U.activeSessions.U.N1: with: 'HHFn')
			with: FeAdminer).
	table at: 411 storeValue: 
		(VHHHandler make: (RequestHandler pointerToStaticMember: #Adminer.U.execute.U.N2:with: with: 'VHHFn')
			with: FeAdminer
			with: PrimIntArray).
	table at: 412 storeValue: 
		(HHHandler make: (RequestHandler pointerToStaticMember: #Adminer.U.gateLockSmith.U.N1: with: 'HHFn')
			with: FeAdminer).
	table at: 413 storeValue: 
		(VHHHHandler make: (RequestHandler pointerToStaticMember: #Adminer.U.grant.U.N3:with:with: with: 'VHHHFn')
			with: FeAdminer
			with: ID
			with: IDRegion).
	table at: 414 storeValue: 
		(HHHandler make: (RequestHandler pointerToStaticMember: #Adminer.U.grants.U.N1: with: 'HHFn')
			with: FeAdminer).
	table at: 415 storeValue: 
		(HHHHandler make: (RequestHandler pointerToStaticMember: #Adminer.U.grants.U.N2:with: with: 'HHHFn')
			with: FeAdminer
			with: IDRegion).
	table at: 416 storeValue: 
		(HHHHHandler make: (RequestHandler pointerToStaticMember: #Adminer.U.grants.U.N3:with:with: with: 'HHHHFn')
			with: FeAdminer
			with: IDRegion
			with: IDRegion).
	table at: 417 storeValue: 
		(BHHandler make: (RequestHandler pointerToStaticMember: #Adminer.U.isAcceptingConnections.U.N1: with: 'BHFn')
			with: FeAdminer).
	table at: 418 storeValue: 
		(VHHHandler make: (RequestHandler pointerToStaticMember: #Adminer.U.setGateLockSmith.U.N2:with: with: 'VHHFn')
			with: FeAdminer
			with: FeLockSmith).
	table at: 419 storeValue: 
		(SpecialHandler make: (PromiseManager pointerToStaticMember: #shutdown: with: 'VHFn')).

"Requests for class Archiver"

	table at: 420 storeValue: 
		(HHandler make: (RequestHandler pointerToStaticMember: #Archiver.U.make.U.N0 with: 'HFn')).
	table at: 421 storeValue: 
		(HHHHHandler make: (RequestHandler pointerToStaticMember: #Archiver.U.archive.U.N3:with:with: with: 'HHHHFn')
			with: FeArchiver
			with: FeEdition
			with: FeEdition).
	table at: 422 storeValue: 
		(VHHHandler make: (RequestHandler pointerToStaticMember: #Archiver.U.markArchived.U.N2:with: with: 'VHHFn')
			with: FeArchiver
			with: FeEdition).
	table at: 423 storeValue: 
		(HHHHHandler make: (RequestHandler pointerToStaticMember: #Archiver.U.restore.U.N3:with:with: with: 'HHHHFn')
			with: FeArchiver
			with: FeEdition
			with: FeEdition).

"Requests for class Array"

	table at: 468 storeValue: 
		(HHHandler make: (RequestHandler pointerToStaticMember: #Array.U.copy.U.N1: with: 'HHFn')
			with: PrimArray).
	table at: 469 storeValue: 
		(HHHHandler make: (RequestHandler pointerToStaticMember: #Array.U.copy.U.N2:with: with: 'HHHFn')
			with: PrimArray
			with: PrimIntValue).
	table at: 255 storeValue: 
		(HHHHHandler make: (RequestHandler pointerToStaticMember: #Array.U.copy.U.N3:with:with: with: 'HHHHFn')
			with: PrimArray
			with: PrimIntValue
			with: PrimIntValue).
	table at: 424 storeValue: 
		(HHHHHHandler make: (RequestHandler pointerToStaticMember: #Array.U.copy.U.N4:with:with:with: with: 'HHHHHFn')
			with: PrimArray
			with: PrimIntValue
			with: PrimIntValue
			with: PrimIntValue).
	table at: 425 storeValue: 
		(HHHHHHHandler make: (RequestHandler pointerToStaticMember: #Array.U.copy.U.N5:with:with:with:with: with: 'HHHHHHFn')
			with: PrimArray
			with: PrimIntValue
			with: PrimIntValue
			with: PrimIntValue
			with: PrimIntValue).
	table at: 6 storeValue: 
		(HHHandler make: (RequestHandler pointerToStaticMember: #Array.U.count.U.N1: with: 'HHFn')
			with: PrimArray).
	table at: 7 storeValue: 
		(SpecialHandler make: (PromiseManager pointerToStaticMember: #export0: with: 'VHFn')).
	table at: 256 storeValue: 
		(SpecialHandler make: (PromiseManager pointerToStaticMember: #export1: with: 'VHFn')).
	table at: 257 storeValue: 
		(SpecialHandler make: (PromiseManager pointerToStaticMember: #export2: with: 'VHFn')).
	table at: 8 storeValue: 
		(HHHHandler make: (RequestHandler pointerToStaticMember: #Array.U.get.U.N2:with: with: 'HHHFn')
			with: PrimArray
			with: PrimIntValue).
	table at: 9 storeValue: 
		(VHHHHandler make: (RequestHandler pointerToStaticMember: #Array.U.store.U.N3:with:with: with: 'VHHHFn')
			with: PrimArray
			with: PrimIntValue
			with: Heaper).
	table at: 258 storeValue: 
		(VHHandler make: (RequestHandler pointerToStaticMember: #Array.U.storeAll.U.N1: with: 'VHFn')
			with: PrimArray).
	table at: 259 storeValue: 
		(VHHHandler make: (RequestHandler pointerToStaticMember: #Array.U.storeAll.U.N2:with: with: 'VHHFn')
			with: PrimArray
			with: Heaper).
	table at: 260 storeValue: 
		(VHHHHandler make: (RequestHandler pointerToStaticMember: #Array.U.storeAll.U.N3:with:with: with: 'VHHHFn')
			with: PrimArray
			with: Heaper
			with: PrimIntValue).
	table at: 261 storeValue: 
		(VHHHHHandler make: (RequestHandler pointerToStaticMember: #Array.U.storeAll.U.N4:with:with:with: with: 'VHHHHFn')
			with: PrimArray
			with: Heaper
			with: PrimIntValue
			with: PrimIntValue).
	table at: 262 storeValue: 
		(VHHHHandler make: (RequestHandler pointerToStaticMember: #Array.U.storeMany.U.N3:with:with: with: 'VHHHFn')
			with: PrimArray
			with: PrimIntValue
			with: PrimArray).
	table at: 263 storeValue: 
		(VHHHHHandler make: (RequestHandler pointerToStaticMember: #Array.U.storeMany.U.N4:with:with:with: with: 'VHHHHFn')
			with: PrimArray
			with: PrimIntValue
			with: PrimArray
			with: PrimIntValue).
	table at: 264 storeValue: 
		(VHHHHHHandler make: (RequestHandler pointerToStaticMember: #Array.U.storeMany.U.N5:with:with:with:with: with: 'VHHHHHFn')
			with: PrimArray
			with: PrimIntValue
			with: PrimArray
			with: PrimIntValue
			with: PrimIntValue).

"Requests for class FloatArray"

	table at: 265 storeValue: 
		(SpecialHandler make: (PromiseManager pointerToStaticMember: #makeFloatArray: with: 'VHFn')).
	table at: 266 storeValue: 
		(HHHHandler make: (RequestHandler pointerToStaticMember: #FloatArray.U.zeros.U.N2:with: with: 'HHHFn')
			with: PrimIntValue
			with: PrimIntValue).
	table at: 267 storeValue: 
		(HHHandler make: (RequestHandler pointerToStaticMember: #FloatArray.U.bitCount.U.N1: with: 'HHFn')
			with: PrimFloatArray).

"Requests for class HumberArray"

	table at: 268 storeValue: 
		(SpecialHandler make: (PromiseManager pointerToStaticMember: #makeHumberArray: with: 'VHFn')).
	table at: 269 storeValue: 
		(HHHandler make: (RequestHandler pointerToStaticMember: #HumberArray.U.zeros.U.N1: with: 'HHFn')
			with: PrimIntValue).

"Requests for class IntArray"

	table at: 10 storeValue: 
		(SpecialHandler make: (PromiseManager pointerToStaticMember: #makeIntArray: with: 'VHFn')).
	table at: 11 storeValue: 
		(HHHHandler make: (RequestHandler pointerToStaticMember: #IntArray.U.zeros.U.N2:with: with: 'HHHFn')
			with: PrimIntValue
			with: PrimIntValue).
	table at: 12 storeValue: 
		(HHHandler make: (RequestHandler pointerToStaticMember: #IntArray.U.bitCount.U.N1: with: 'HHFn')
			with: PrimIntArray).

"Requests for class PtrArray"

	table at: 270 storeValue: 
		(SpecialHandler make: (PromiseManager pointerToStaticMember: #makePtrArray: with: 'VHFn')).
	table at: 271 storeValue: 
		(HHHandler make: (RequestHandler pointerToStaticMember: #PtrArray.U.nulls.U.N1: with: 'HHFn')
			with: PrimIntValue).

"Requests for class Bundle"

	table at: 13 storeValue: 
		(HHHandler make: (RequestHandler pointerToStaticMember: #Bundle.U.region.U.N1: with: 'HHFn')
			with: FeBundle).

"Requests for class ArrayBundle"

	table at: 14 storeValue: 
		(HHHandler make: (RequestHandler pointerToStaticMember: #ArrayBundle.U.array.U.N1: with: 'HHFn')
			with: FeArrayBundle).
	table at: 15 storeValue: 
		(HHHandler make: (RequestHandler pointerToStaticMember: #ArrayBundle.U.ordering.U.N1: with: 'HHFn')
			with: FeArrayBundle).

"Requests for class ElementBundle"

	table at: 16 storeValue: 
		(HHHandler make: (RequestHandler pointerToStaticMember: #ElementBundle.U.element.U.N1: with: 'HHFn')
			with: FeElementBundle).

"Requests for class PlaceHolderBundle"


"Requests for class CoordinateSpace"

	table at: 272 storeValue: 
		(HHHandler make: (RequestHandler pointerToStaticMember: #CoordinateSpace.U.ascending.U.N1: with: 'HHFn')
			with: CoordinateSpace).
	table at: 273 storeValue: 
		(HHHHandler make: (RequestHandler pointerToStaticMember: #CoordinateSpace.U.completeMapping.U.N2:with: with: 'HHHFn')
			with: CoordinateSpace
			with: XnRegion).
	table at: 274 storeValue: 
		(HHHandler make: (RequestHandler pointerToStaticMember: #CoordinateSpace.U.descending.U.N1: with: 'HHFn')
			with: CoordinateSpace).
	table at: 17 storeValue: 
		(HHHandler make: (RequestHandler pointerToStaticMember: #CoordinateSpace.U.emptyRegion.U.N1: with: 'HHFn')
			with: CoordinateSpace).
	table at: 18 storeValue: 
		(HHHandler make: (RequestHandler pointerToStaticMember: #CoordinateSpace.U.fullRegion.U.N1: with: 'HHFn')
			with: CoordinateSpace).
	table at: 19 storeValue: 
		(HHHandler make: (RequestHandler pointerToStaticMember: #CoordinateSpace.U.identityMapping.U.N1: with: 'HHFn')
			with: CoordinateSpace).

"Requests for class CrossSpace"

	table at: 20 storeValue: 
		(HHHandler make: (RequestHandler pointerToStaticMember: #CrossSpace.U.make.U.N1: with: 'HHFn')
			with: PtrArray).
	table at: 275 storeValue: 
		(HHHandler make: (RequestHandler pointerToStaticMember: #CrossSpace.U.axes.U.N1: with: 'HHFn')
			with: CrossSpace).
	table at: 276 storeValue: 
		(HHHHandler make: (RequestHandler pointerToStaticMember: #CrossSpace.U.axis.U.N2:with: with: 'HHHFn')
			with: CrossSpace
			with: PrimIntValue).
	table at: 277 storeValue: 
		(HHHandler make: (RequestHandler pointerToStaticMember: #CrossSpace.U.axisCount.U.N1: with: 'HHFn')
			with: CrossSpace).
	table at: 278 storeValue: 
		(HHHandler make: (RequestHandler pointerToStaticMember: #CrossSpace.U.crossOfMappings.U.N1: with: 'HHFn')
			with: CrossSpace).
	table at: 279 storeValue: 
		(HHHHandler make: (RequestHandler pointerToStaticMember: #CrossSpace.U.crossOfMappings.U.N2:with: with: 'HHHFn')
			with: CrossSpace
			with: PtrArray).
	table at: 426 storeValue: 
		(HHHandler make: (RequestHandler pointerToStaticMember: #CrossSpace.U.crossOfOrderSpecs.U.N1: with: 'HHFn')
			with: CrossSpace).
	table at: 427 storeValue: 
		(HHHHandler make: (RequestHandler pointerToStaticMember: #CrossSpace.U.crossOfOrderSpecs.U.N2:with: with: 'HHHFn')
			with: CrossSpace
			with: PtrArray).
	table at: 428 storeValue: 
		(HHHHHandler make: (RequestHandler pointerToStaticMember: #CrossSpace.U.crossOfOrderSpecs.U.N3:with:with: with: 'HHHHFn')
			with: CrossSpace
			with: PtrArray
			with: PrimIntArray).
	table at: 21 storeValue: 
		(HHHHandler make: (RequestHandler pointerToStaticMember: #CrossSpace.U.crossOfPositions.U.N2:with: with: 'HHHFn')
			with: CrossSpace
			with: PtrArray).
	table at: 22 storeValue: 
		(HHHHandler make: (RequestHandler pointerToStaticMember: #CrossSpace.U.crossOfRegions.U.N2:with: with: 'HHHFn')
			with: CrossSpace
			with: PtrArray).
	table at: 23 storeValue: 
		(HHHHHandler make: (RequestHandler pointerToStaticMember: #CrossSpace.U.extrusion.U.N3:with:with: with: 'HHHHFn')
			with: CrossSpace
			with: PrimIntValue
			with: XnRegion).

"Requests for class FilterSpace"

	table at: 280 storeValue: 
		(HHHandler make: (RequestHandler pointerToStaticMember: #FilterSpace.U.make.U.N1: with: 'HHFn')
			with: CoordinateSpace).
	table at: 24 storeValue: 
		(HHHHandler make: (RequestHandler pointerToStaticMember: #FilterSpace.U.allFilter.U.N2:with: with: 'HHHFn')
			with: FilterSpace
			with: XnRegion).
	table at: 25 storeValue: 
		(HHHHandler make: (RequestHandler pointerToStaticMember: #FilterSpace.U.anyFilter.U.N2:with: with: 'HHHFn')
			with: FilterSpace
			with: XnRegion).
	table at: 281 storeValue: 
		(HHHandler make: (RequestHandler pointerToStaticMember: #FilterSpace.U.baseSpace.U.N1: with: 'HHFn')
			with: FilterSpace).
	table at: 429 storeValue: 
		(HHHHandler make: (RequestHandler pointerToStaticMember: #FilterSpace.U.position.U.N2:with: with: 'HHHFn')
			with: FilterSpace
			with: XnRegion).

"Requests for class IDSpace"

	table at: 26 storeValue: 
		(HHandler make: (RequestHandler pointerToStaticMember: #IDSpace.U.global.U.N0 with: 'HFn')).
	table at: 282 storeValue: 
		(HHHandler make: (RequestHandler pointerToStaticMember: #IDSpace.U.import.U.N1: with: 'HHFn')
			with: PrimIntArray).
	self fillRequestTable1: table.! !