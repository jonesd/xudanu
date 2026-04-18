'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:05:37 pm'!

SpecialistXmtr subclass: #TextyXmtr
	instanceVariableNames: '
		myStream {XnWriteStream}
		myDepth {IntegerVar}
		myNeedsSep {BooleanVar}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Xcvr'!

(TextyXmtr getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!TextyXmtr methodsFor: 'sending'!

{void} sendBooleanVar: b {BooleanVar}
	self startThing.
	b ifTrue: [myStream putByte: $1 uint8] ifFalse: [myStream putByte: $0 uint8].
	self endThing!

{void} sendCategory: cat {Category}
	self startThing. 
	[self sendIdentifier: cat name] translateOnly.
	[self sendIdentifier: (cat name copyUpTo: $.)] smalltalkOnly.
	self endThing!

{void} sendIEEEDoubleVar: x {IEEEDoubleVar} 
	"Sending the normal decimal approximation doesn't work because it introduces 
	roundoff error. What we need to do instead is send a hex encoding of the IEEE 
	double precision (64-bit) representation of the number. For clarity in the 
	textual protocol, we also include the decimal approximation in a comment."

	self startThing.
	[myStream putStr: x printString] smalltalkOnly.
	'
	char 	str[CONVERTSTRLEN];
	sprintf(str, "%g", x);
	myStream->putStr(str);' translateOnly.
	self endThing!

{void} sendInt32: n {Int32}
	self startThing.
	[myStream putStr: n printString] smalltalkOnly.
	'
	char 	str[CONVERTSTRLEN];
	sprintf(str, "%d", n);
	myStream->putStr(str);' translateOnly.
	self endThing!

{void} sendInt8: n {Int8}
	self startThing.
	[myStream putStr: n printString] smalltalkOnly.
	'
	char 	str[CONVERTSTRLEN];
	sprintf(str, "%d", n);
	myStream->putStr(str);' translateOnly.
	self endThing!

{void} sendIntegerVar: n {IntegerVar}
	self startThing.
	[myStream putStr: n printString] smalltalkOnly.
	'(&n)->sendSelfTo(this);' translateOnly.
	self endThing!

{void} sendString: s {char star}

	self startThing.
	myStream putByte: $" uint8.
	[self hack. "not complete C string form"
	s do: [:c {char} |
		c == $' ifTrue:
			[myStream putStr: '\''']
		ifFalse: [c == $" ifTrue:
			[myStream putStr: '\"']
		ifFalse: [c == (Character cr) ifTrue:
			[myStream putStr: '\n']
		ifFalse: [c == (Character tab) ifTrue:
			[myStream putStr: '\t']
		ifFalse: [c == (Character backspace) ifTrue:
			[myStream putStr: '\b']
		ifFalse: [(c isSeparator not or: [c == $ ]) ifTrue:
			[myStream putByte: c uint8]
		ifFalse:
			[self class blast.InvalidCharacter raise]]]]]]]] smalltalkOnly.
	'for(; *s !!= ''\0''; s++) {
		switch (*s) {
		/*case ALERT_CHAR:
			myStream->putStr("\\a");
			break;*/
		case ''\n'':
			myStream->putStr("\\n\\\n");
			break;
		case ''\t'':
			myStream->putStr("\\t");
			break;
		case ''\b'':
			myStream->putStr("\\b");
			break;
		case ''\r'':
			myStream->putStr("\\r");
			break;
		case ''\f'':
			myStream->putStr("\\f");
			break;
		case ''\v'':
			myStream->putStr("\\v");
			break;
		case ''\\'':
			myStream->putStr("\\\\");
			break;
		case ''\'''':
			myStream->putStr("\\\''");
			break;
		case ''\"'':
			myStream->putStr("\\\"");
			break;
		default:
			if (isprint(*s)) {
				myStream->putByte(*s);
			} else {
				BLAST(NON_PRINTING_CHARACTER);
			}
		}
	}' translateOnly.
	myStream putByte: $" uint8.
	self endThing!

{void} sendUInt32: n {UInt32}
	self startThing.
	[myStream putStr: n printString] smalltalkOnly.
	' 
	char 	str[CONVERTSTRLEN];
	sprintf(str, "%u", n);
	myStream->putStr(str);' translateOnly.
	self endThing!

{void} sendUInt8: n {UInt8}
	self startThing.
	[myStream putStr: n printString] smalltalkOnly.
	'
	char 	str[CONVERTSTRLEN];
	sprintf(str, "%u", n);
	myStream->putStr(str);' translateOnly.
	self endThing!

{void} sendUInt8Data: array {UInt8Array}
	self startThing.
	myStream putByte: $" uint8.
	Int32Zero almostTo: array count do: [ :i {Int32} |
		myStream putByte: ((array uIntAt: i) basicCast: UInt8)].
	myStream putByte: $" uint8.
	self endThing! !

!TextyXmtr methodsFor: 'specialist sending'!

{void} endInstance
	"end sending an instance"
	myStream putByte: $) uint8.
	myDepth _ myDepth - 1.
	self endThing! !

!TextyXmtr methodsFor: 'protected: sending'!

{void} decrementDepth
	myDepth _ myDepth - 1!

{void} endPacket
	myStream putByte: $; uint8.
	myStream flush.
	myNeedsSep _ false.
	super endPacket!

{void} endThing
	myDepth == IntegerVar0
		ifTrue: [self endPacket]
		ifFalse: [myNeedsSep _ true]!

{void} incrementDepth
	myDepth _ myDepth + 1!

{void} putByte: b {UInt8}
	myStream putByte: b!

{void} sendNULL

	self startThing.
	self sendIdentifier: 'NULL'.
	self endThing!

{void} startNewInstance: cat {Category} 
	"start sending an instance of a particular class"
	
	myDepth _ myDepth + 1.
	self sendCategory: cat.
	myStream putByte: $( uint8.
	myNeedsSep _ false!

{void} startThing
	myNeedsSep ifTrue: [myStream putByte: $, uint8].
	myNeedsSep _ false! !

!TextyXmtr methodsFor: 'private: sending'!

{void} sendIdentifier: identifier {char star}
	"send an identifier"

	myStream putStr: identifier! !

!TextyXmtr methodsFor: 'creation'!

create: specialist {TransferSpecialist} with: stream {XnWriteStream}
	super create: specialist.
	myStream _ stream.
	myDepth _ IntegerVar0.
	myNeedsSep _ false! !

!TextyXmtr methodsFor: 'printing'!

{void} printOn: oo {ostream reference}
	oo << self getCategory name << '( ' << myStream << ')'! !

!TextyXmtr methodsFor: 'overloading junk'!

{void} sendHeaper: object {Heaper}
	super sendHeaper: object! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

TextyXmtr class
	instanceVariableNames: ''!

(TextyXmtr getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!TextyXmtr class methodsFor: 'creation'!

{SpecialistXmtr} make: specialist {TransferSpecialist} with: stream {XnWriteStream}
	^self create: specialist with: stream! !