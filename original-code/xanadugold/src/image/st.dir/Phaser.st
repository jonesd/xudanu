'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:05:44 pm'!

Heaper subclass: #Phaser
	instanceVariableNames: '
		myProblemName {UInt8Array}
		myVal {Int32}
		myFileName {UInt8Array}
		myLineNumber {UInt32}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Xcvr-response'!

(Phaser getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #EQ; add: #COPY; yourself)!

!Phaser methodsFor: 'blasting'!

{void} explode
	
[	"cxx:
	char * problemName = new char[myProblemName->count() + 1];
	strncpy(problemName, ((char *) myProblemName->gutsOf()), (int)myProblemName->count());
	problemName[myProblemName->count()] = 0;
	char * fileName = new char[myFileName->count() + 1];
	strncpy(fileName, ((char *) myFileName->gutsOf()), (int)myFileName->count());
	fileName[myFileName->count()] = 0;
	blast(new Problem(problemName, myVal, fileName, myLineNumber, &Phaser::phaserStringFree));"] translateOnly.

	[Heaper BLAST: (Symbol fromString: myProblemName)] smalltalkOnly.! !

!Phaser methodsFor: 'hooks: smalltalk: hooks'!

{void RECEIVE.HOOK} receivePhaser: rcvr {Rcvr}
	myProblemName _ rcvr receiveString.
	myFileName _ rcvr receiveString!

{void SEND.HOOK} sendPhaser: xmtr {Xmtr}
	xmtr sendString: myProblemName.
	xmtr sendString: myFileName! !

!Phaser methodsFor: 'creation'!

create: problemName {UInt8Array} 
	with: val {Int32} 
	with: fileName {UInt8Array} 
	with: lineNumber {UInt32}

	super create.
	myProblemName _ problemName.
	myVal _ val.
	myFileName _ fileName.
	myLineNumber _ lineNumber! !

!Phaser methodsFor: 'printing'!

{void} printOn: oo {ostream reference}
	oo << self getCategory name << '(' << myProblemName << ', ' << myVal << ', ' << myFileName << ', ' << myLineNumber << ')'! !

!Phaser methodsFor: 'generated:'!

actualHashForEqual ^self asOop!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	myProblemName _ receiver receiveHeaper.
	myVal _ receiver receiveInt32.
	myFileName _ receiver receiveHeaper.
	myLineNumber _ receiver receiveUInt32.
	self receivePhaser: receiver.!

isEqual: other ^self == other!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	xmtr sendHeaper: myProblemName.
	xmtr sendInt32: myVal.
	xmtr sendHeaper: myFileName.
	xmtr sendUInt32: myLineNumber.
	self sendPhaser: xmtr.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

Phaser class
	instanceVariableNames: ''!

(Phaser getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #EQ; add: #COPY; yourself)!

!Phaser class methodsFor: 'creation'!

make: problem {Problem star} 
	[^self
		create: (UInt8Array string: problem PROBLEM)
		with: (problem parameter == nil ifTrue: [Int32Zero] ifFalse: [problem parameter])
		with: (UInt8Array string: problem handlerContext sender printString)
		with: Int32Zero] smalltalkOnly.
	^self
		create: (UInt8Array string: problem getProblemName)
		with: problem getVal
		with: (UInt8Array string: problem getFileName)
		with: problem getLineNumber! !

!Phaser class methodsFor: 'freeing strings'!

{void} phaserStringFree: s1 {char star const} with: s2 {char star const}

	'void *		tmp;

	if (s1 !!= NULL ) {
		tmp = (void *)s1;
		delete tmp;
	}
	if (s2 !!= NULL) {
		tmp = (void *)s2;
		delete tmp;
	}' translateOnly! !