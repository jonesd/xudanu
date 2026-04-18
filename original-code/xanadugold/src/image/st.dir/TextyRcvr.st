'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:05:36 pm'!

SpecialistRcvr subclass: #TextyRcvr
	instanceVariableNames: '
		myStream {XnReadStream}
		myDepth {IntegerVar}'
	classVariableNames: '
		ReceiveStringBuffer {char vector} 
		ReceiveStringBufferSize {Int4 const} '
	poolDictionaries: ''
	category: 'Xanadu-Xcvr'!

(TextyRcvr getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!TextyRcvr methodsFor: 'receiving'!

{BooleanVar} receiveBooleanVar
	| result {BooleanVar} |
	self startThing.
	result _ self skipWhiteSpace.
	self endThing.
	result == $1 ifTrue: [^true] ifFalse: [result == $0 ifTrue: [^false] ifFalse: [Heaper BLAST: #InvalidRequest]].
	^false "fodder"!

{Category} receiveCategory
	self getIdentifier: ReceiveStringBuffer with: ReceiveStringBufferSize-1.
	(String strcmp: ReceiveStringBuffer with: 'NULL') == UInt32Zero
		ifTrue: [self endThing.
				^NULL].
	[^Category find: (ReceiveStringBuffer copyUpTo: Character null)] smalltalkOnly.
	^Category find: ReceiveStringBuffer.!

{void} receiveData: array {UInt8Array}
	"Fill the array with data from the stream."
	
	self startThing.
	self getCharToken: $".
	Int32Zero almostTo: array count do: [ :i {Int32} | 
		array at: i storeUInt: myStream getByte].
	self getCharToken: $".
	self endThing!

{IEEEDoubleVar} receiveIEEEDoubleVar
	self startThing.
	self unimplemented.
	self endThing.
	^0.0!

{Int32} receiveInt32 
	| result {Int32} |
	self startThing.
	result _ self receiveNumber DOTasLong.
	self endThing.
	^result!

{Int8} receiveInt8
	| result {Int8} | 
	self startThing.
	result _ self receiveNumber DOTasInt.
	self endThing.
	^result!

{IntegerVar} receiveIntegerVar
	| result {IntegerVar} |
	self startThing. 
	result _ self receiveNumber.
	self endThing.
	^result
	
	"[^IntegerVar localIntVar: self with: #tcsj] translateOnly."!

{char star} receiveString
	| result {char star} |
	self startThing.
	[result _ String streamContents: [ :stream | | c {char} |
		self getCharToken: $".
		[$" ~~ (c _ Character char: myStream getByte)] whileTrue:
			[c ~~ $\ ifTrue:
				[stream nextPut: c]
			ifFalse:
				[c _ myStream getByte.
				c == $' ifTrue:
					[stream nextPut: $']
				ifFalse: [c == $" ifTrue:
					[stream nextPut: $"]
				ifFalse: [c == $n ifTrue:
					[stream nextPut: Character cr]
				ifFalse: [c == $t ifTrue:
					[stream nextPut: Character tab]
				ifFalse: [c == $b ifTrue:
					[stream nextPut: Character backspace]
				ifFalse:
					[Heaper BLAST: #InvalidCharacter]]]]]]]]] smalltalkOnly.
	'char *buf = TextyRcvr::ReceiveStringBuffer;
	UInt32 max = TextyRcvr::ReceiveStringBufferSize;
	this->getCharToken(''"'');
	for (char c = myStream->getByte();
	  c !!= ''\"'';
	  c = myStream->getByte()) {
		if (max <= 1) {
			BLAST(STRING_TOO_LONG);
		}
		max -= 1;
		if (c !!= ''\\'') {
			*buf++ = c;
		} else {
			c = myStream->getByte();
			switch (c) {
			case ''a'':
				*buf++ = ALERT_CHAR;
				break;
			case ''?'':
/* ANSI permits, but does not require, ''?'' to be escaped.  Therefore, even */
/*  though we do not send it escaped, for consistency with the standard, we */
/*  can receive it either way.  */
				*buf++ = ''?'';
				break;
			case ''\n'':
				max += 1;
				break;
			case ''n'':
				*buf++ = ''\n'';
				break;
			case ''t'':
				*buf++ = ''\t'';
				break;
			case ''b'':
				*buf++ = ''\b'';
				break;
			case ''r'':
				*buf++ = ''\r'';
				break;
			case ''f'':
				*buf++ = ''\f'';
				break;
			case ''v'':
				*buf++ = ''\v'';
				break;
			case ''\\'':
				*buf++ = ''\\'';
				break;
			case ''\'''':
				*buf++ = ''\'''';
				break;
			case ''\"'':
				*buf++ = ''\"'';
				break;
			default:
				BLAST(UNRECOGNIZED_ESCAPE);
			}
		}
	}
	*buf++ = ''\0'';
	Int32 size = buf - ReceiveStringBuffer;
  	result = strcpy(new char[size],ReceiveStringBuffer);' translateOnly.
	self endThing.
	^result!

{UInt32} receiveUInt32
	| result {UInt32} | 
	self startThing.
	result _ self receiveNumber DOTasLong.
	self endThing.
	^result!

{UInt8} receiveUInt8
	| result {UInt8} | 
	self startThing.
	result _ self receiveNumber DOTasInt.
	self endThing.
	^result! !

!TextyRcvr methodsFor: 'protected: lexer'!

{void} decrementDepth
	myDepth _ myDepth - 1!

{void} endOfInstance
	self getCharToken: $).
	myDepth _ myDepth - 1.
	self endThing!

{void} endPacket
	self getCharToken: $;.
	super endPacket!

{Category} fetchStartOfInstance

	| cat {Category} |
	self startThing.
	cat _ self receiveCategory.
	cat == NULL ifTrue: [^NULL].
	myDepth _ myDepth + 1.
	self getCharToken: $(.
	^cat!

{UInt32} getByte
	^myStream getByte!

{void} getCharToken: referent {Character}
	"match a character from the input stream"
	
	| c {char} |
	c _ self skipWhiteSpace.
	c ~~ referent ifTrue:
		[Heaper BLAST: #WrongCharacter]!

{void} getIdentifier: buf {char star} with: limit {Int32}
	"get an identifier from the stream into a pre-allocated buffer"

	| c {char} nextPos {Int32} |
	nextPos _ Int32Zero.
	c _ self skipWhiteSpace.
	[(Character isalnum: c) or: [c == $_]] whileTrue:
		[nextPos >= limit ifTrue: [TextyRcvr BLAST: #IdentifierTooLong].
		[buf at: nextPos+1 put: c] smalltalkOnly.
		[buf at: nextPos put: c] translateOnly.
		nextPos _ nextPos + 1.
		c _ Character char: myStream getByte].
	myStream putBack: c uint8.
	[buf at: nextPos+1 put: (Character char: UInt32Zero)] smalltalkOnly.
	[buf at: nextPos put: (Character char: UInt32Zero)] translateOnly!

{void} incrementDepth
	myDepth _ myDepth + 1!

{char} skipWhiteSpace
	"return the first character following white space"
	| c {char} |
	c _ Character char: myStream getByte.
	[(Character isspace: c) or: [c == $,]] whileTrue: [c _ Character char: myStream getByte].
	^c! !

!TextyRcvr methodsFor: 'private: receiving'!

{IntegerVar} receiveNumber
	"Receive an arbitrary number.  Convert to the lesser types by range checking and casting."
 
	| value {IntegerVar} neg {BooleanVar} c {UInt8} |
	c _ self skipWhiteSpace.
	neg _ c == $-.
	neg ifTrue: [c _ Character char: myStream getByte].
	value _ IntegerVar0.
	[Character isdigit: c] whileTrue: 
		[| digit {UInt8} |
		digit _ c uint8 - $0 uint8.
		value _ value * 10 + digit.
		c _ Character char: myStream getByte].
	myStream putBack: c uint8.
	neg ifTrue: [^value negated].
	^value! !

!TextyRcvr methodsFor: 'creation'!

create: specialist {TransferSpecialist} with: stream {XnReadStream}

	super create: specialist.
	myStream _ stream.
	myDepth _ IntegerVar0! !

!TextyRcvr methodsFor: 'smalltalk: receiving'!

{String} receiveEverything
	^String streamContents: [ :stream |
		[myStream atEnd] whileFalse:
			[stream nextPut: (Character char: myStream getByte)]]! !

!TextyRcvr methodsFor: 'smalltalk: deja vu'!

{void} receiveString: array {UInt8Array}
	self startThing.
	[^String streamContents: [ :stream | | c {char} |
		self getCharToken: $".
		[$" ~~ (c _ myStream getByte)] whileTrue:
			[c ~~ $\ ifTrue:
				[stream nextPut: c]
			ifFalse:
				[c _ myStream getByte.
				c == $' ifTrue:
					[stream nextPut: $']
				ifFalse: [c == $" ifTrue:
					[stream nextPut: $"]
				ifFalse: [c == $n ifTrue:
					[stream nextPut: Character cr]
				ifFalse: [c == $t ifTrue:
					[stream nextPut: Character tab]
				ifFalse: [c == $b ifTrue:
					[stream nextPut: Character backspace]
				ifFalse:
					[Heaper BLAST: #InvalidCharacter]]]]]]]]] smalltalkOnly.
	[self unimplemented] translateOnly.
	self endThing! !

!TextyRcvr methodsFor: 'protected: receiving'!

{void} endThing
	myDepth == IntegerVar0 ifTrue: [self endPacket]!

{void} startThing
	myDepth == IntegerVar0 ifTrue: [myStream refill]! !

!TextyRcvr methodsFor: 'printing'!

{void} printOn: oo {ostream reference}
	oo << self getCategory name << '( ' << myStream << ')'! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

TextyRcvr class
	instanceVariableNames: ''!

(TextyRcvr getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!TextyRcvr class methodsFor: 'creation'!

{SpecialistRcvr} make: specialist {TransferSpecialist} with: stream {XnReadStream}
	^self create: specialist with: stream! !

!TextyRcvr class methodsFor: 'smalltalk: init'!

linkTimeNonInherited
	"!!!!!!!! This constant size buffer is a bad idea.  It's going to get us in trouble."
	
	ReceiveStringBufferSize _ 4096. "4088 is longest allowable C++ class name."
	'static char permReceiveStringBuffer[4096];
char * TextyRcvr::ReceiveStringBuffer = permReceiveStringBuffer;' translateOnly.
	[ReceiveStringBuffer := String new: ReceiveStringBufferSize] smalltalkOnly.! !