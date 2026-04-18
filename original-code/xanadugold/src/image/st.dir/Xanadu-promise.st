Heaper subclass: #XuCollectionAgent
	instanceVariableNames: '
		myPromises {XuPromise}
		myPrevious {XuCollectionAgent}
		myProblemList {char star vector}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-promise'!

(XuCollectionAgent getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!XuCollectionAgent methodsFor: 'accessing'!

{void} addPromise: aPromise {XuPromise}

	| tPromise {XuPromise} |
	(myPromises == NULL) ifTrue: [ 
		myPromises _ aPromise]
	ifFalse: [
		tPromise _ myPromises.
		[(tPromise next) ~~ NULL] whileTrue: [ tPromise _ (tPromise next)].
		tPromise next: aPromise.].!

{XuPromise} firstPromise

	^myPromises.!

{BooleanVar} handlesProblem: problemName {char star}
	
	["cxx:
		char *i;
		for (i = *myProblemList; i !!= NULL; i++) {
			if (strcmp (i, problemName) == 0)
				return(TRUE);
		}
		return(FALSE);"] translateOnly.
		
	[^myProblemList accepts: (Heaper signal: problemName  asSymbol).] smalltalkOnly.!

{XuCollectionAgent} previous
 
	^myPrevious.! !

!XuCollectionAgent methodsFor: 'creation'!

create: problemList {char star vector} with: previous {XuCollectionAgent}

	super create.
	myPromises _ NULL.
	myPrevious _ previous.
	myProblemList _ problemList.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

XuCollectionAgent class
	instanceVariableNames: ''!

(XuCollectionAgent getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!XuCollectionAgent class methodsFor: 'pseudo-consructors'!

make: problemList {char star vector} with: previous {XuCollectionAgent}

	^self create: problemList with: previous.! !

Heaper subclass: #XuPromise
	instanceVariableNames: '
		myProblemName {char star}
		myVal {Int32}
		myFileName {char star}
		myLineNumber {UInt32}
		myExcuse {XuPromise}
		mySeqNo {IntegerVar}
		myNext {XuPromise}
		myBrokenFlag {BooleanVar}
		myActualThing {Heaper}'
	classVariableNames: '
		CurrentCollector {XuCollectionAgent} 
		LastSeqForced {IntegerVar} 
		LastSeqNo {IntegerVar} '
	poolDictionaries: ''
	category: 'Xanadu-promise'!

(XuPromise getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #EQ; yourself)!

!XuPromise methodsFor: 'heaper'!

{XuIntValue} areActualsEqual: other {XuPromise}
	| retVal {XuIntValue} tmp {BooleanVar}|
	(self isBroken) ifTrue: [^XuIntValue makeBrokenBy: self].
	(other isBroken) ifTrue: [^XuIntValue makeBrokenBy: other].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuIntValue makeBroken: ex asProblem. ex return]
		do: 	[tmp _ (XuPromise getActual: self) isEqual: (XuPromise getActual: other).
		retVal _ XuIntValue make: (PrimIntValue make: (tmp ifTrue: [1] ifFalse: [Int32Zero]))].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuIntValue} equals: other {XuPromise}
	| retVal {XuIntValue} tmp {BooleanVar} |
	(self isBroken) ifTrue: [^XuIntValue makeBrokenBy: self].
	(other isBroken) ifTrue: [^XuIntValue makeBrokenBy: other].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuIntValue makeBroken: ex asProblem. ex return]
		do: 	[tmp _ (XuPromise getActual: self) isEqual: (XuPromise getActual: other).
		retVal _ XuIntValue make: (PrimIntValue make: (tmp ifTrue: [1] ifFalse: [Int32Zero]))].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuIntValue} hash
	| retVal {XuIntValue} |
	(self isBroken) ifTrue: [^XuIntValue makeBrokenBy: self].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuIntValue makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuIntValue make: (PrimIntValue make: (XuPromise getActual: self) hashForEqual)].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuIntValue} hashActual
	| retVal {XuIntValue} |
	(self isBroken) ifTrue: [^XuIntValue makeBrokenBy: self].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuIntValue makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuIntValue make: (PrimIntValue make: (XuPromise getActual: self) hashForEqual)].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal! !

!XuPromise methodsFor: 'printing'!

{void} printOn: oo {ostream reference}
	self isBroken 
		ifTrue: [oo << 'Xu(BROKEN)']
		ifFalse: [oo << 'Xu(' << myActualThing << $)]! !

!XuPromise methodsFor: 'smalltalk: casting'!

{XuPromise} delayCast: pClass {Category}

	self isBroken ifTrue:
		[^pClass makeBrokenBy: self].
	(self actualThing isKindOf: (Smalltalk at: (Heaper togglePromiseName: pClass name)))
		ifTrue: [^pClass make: self actualThing]
		ifFalse: [^pClass makeBroken: 'bad delayCast']! !

!XuPromise methodsFor: 'blasting'!

{void} explode

	(self isBroken) ifFalse: [Heaper BLAST: #Unbroken.U.promise.U.exploded].
	(myExcuse ~~ NULL) ifTrue: [myExcuse explode]
	ifFalse: [
		["cxx:
		char *problemName, *fileName;
		problemName = new char[strlen (myProblemName) +1];
		strcpy(problemName, ((char *) myProblemName));
		fileName = new char[strlen (myFileName) + 1];
		strcpy(fileName, ((char *) myFileName));
		blast(new Problem(problemName, myVal, fileName, myLineNumber, &XuPromise::promiseStringFree));"] translateOnly.

		[Heaper BLAST: myProblemName ] smalltalkOnly. 
	].! !

!XuPromise methodsFor: 'accessing'!

{char star} fileName

	^myFileName.!

{BooleanVar} isBroken

	^myBrokenFlag.!

{void} isBroken: problem {Problem}

	myBrokenFlag _ true.
	
	["cxx: 
	myProblemName = (new char[strlen(problem->getProblemName())]);
	strcpy(myProblemName, (problem->getProblemName()) );
	myVal = problem->getVal();
	myFileName = (new char[strlen(problem->getFileName())]);
	strcpy(myFileName, (problem->getFileName()) );
	myLineNumber = problem->getLineNumber();"] translateOnly.
	
	[myProblemName _ (String fromString: problem PROBLEM).
	myVal _ (problem parameter == nil ifTrue: [Int40] ifFalse: [problem parameter]).
	myFileName _ (String fromString: problem handlerContext sender printString).
	myLineNumber _ Int40] smalltalkOnly.!

{BooleanVar} isForced

	^(mySeqNo <= LastSeqForced).!

{UInt32} lineNumber

	^myLineNumber.!

{XuPromise} next

	^myNext.!

{void} next: aPromise {XuPromise}

	myNext _ aPromise.!

{char star} problemName

	^myProblemName.!

{Int32} val

	^myVal.! !

!XuPromise methodsFor: 'creation'!

create

	super create.
	LastSeqNo _ LastSeqNo + 1.
	mySeqNo _ LastSeqNo.
	myBrokenFlag _ false.
	myNext _ NULL.!

create.Problem: problem {Problem}

	super create.
	mySeqNo _ LastSeqNo _ LastSeqNo + 1.
	myBrokenFlag _ true.
	myNext _ NULL.
	myExcuse _ NULL.

	["cxx: 
	myProblemName = (new char[strlen(problem->getProblemName())]);
	strcpy(myProblemName, (problem->getProblemName()) );
	myVal = problem->getVal();
	myFileName = (new char[strlen(problem->getFileName())]);
	strcpy(myFileName, (problem->getFileName()) );
	myLineNumber = problem->getLineNumber();"] translateOnly.
	
	[myProblemName _ (String fromString: problem PROBLEM).
	myVal _ (problem parameter == nil ifTrue: [Int40] ifFalse: [problem parameter]).
	myFileName _ (String fromString: problem handlerContext sender printString).
	myLineNumber _ Int40] smalltalkOnly.!

create.Promise: promise {XuPromise}

	super create.
	mySeqNo _ LastSeqNo _ LastSeqNo + 1.
	myBrokenFlag _ true.
	myNext _ NULL.
	myExcuse _ promise.!

create: aHeaper {Heaper}

	super create.
	LastSeqNo _ LastSeqNo + 1.
	mySeqNo _ LastSeqNo.
	myBrokenFlag _ false.
	myNext _ NULL.
	myActualThing _ aHeaper! !

!XuPromise methodsFor: 'secret'!

{Heaper} actualThing

	self knownBug. "what if I'm broken? not forced?"
	^myActualThing! !

!XuPromise methodsFor: 'promise access'!

{Heaper} getActualHeaper

	self isBroken
		ifFalse: [^myActualThing cast: Heaper]
		ifTrue: [Heaper BLAST: #BrokenPromise]! !

!XuPromise methodsFor: 'generated:'!

actualHashForEqual ^self asOop!

isEqual: other ^self == other! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

XuPromise class
	instanceVariableNames: ''!

(XuPromise getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #EQ; yourself)!

!XuPromise class methodsFor: 'smalltalk: init'!

initTimeNonInherited

	LastSeqNo _ IntegerVarZero.
	LastSeqForced _ IntegerVarZero.
	CurrentCollector _ NULL.!

linkTimeNonInherited

	LastSeqNo _ IntegerVarZero.
	LastSeqForced _ IntegerVarZero.
	CurrentCollector _ NULL.! !

!XuPromise class methodsFor: 'smalltalk: testing'!

{Boolean} isNotGenerated
	^ false "Well, not really, but this class lacks the makeBroken: method"! !

!XuPromise class methodsFor: 'pseudo constructors'!

make

	^self create.!

make: aHeaper {Heaper}
	^self create: aHeaper!

{XuPromise} makeBroken: problem {Problem}

	| broke {XuPromise} |
	broke _ self create.Problem: problem.
	XuPromise savePromise: broke.
	^broke!

{XuPromise} makeBrokenBy: broken {XuPromise}

	^self create.Promise: broken.! !

!XuPromise class methodsFor: 'internals'!

{Heaper} getActual: promise {XuPromise | NULL}
	promise == NULL ifTrue: [^NULL] ifFalse: [^promise getActualHeaper]!

{BooleanVar} isBroken: promise {XuPromise | NULL}
		promise == NULL ifTrue: [^false] ifFalse: [^promise isBroken]! !

!XuPromise class methodsFor: 'accessing'!

{XuCollectionAgent} collector

	^CurrentCollector!

{Emulsion} emulsion

	self hack. "for now"
	^ServerChunk emulsion!

{void} force

	LastSeqForced _ LastSeqNo.!

{BooleanVar} inDelayBlock

	^(CurrentCollector ~= NULL)!

{void} newCollector: problemList {char star vector}

	CurrentCollector _ XuCollectionAgent make: problemList with: CurrentCollector.!

{void} popCollector

	CurrentCollector _ CurrentCollector previous.!

{void} promiseStringFree: s1 {char star const} with: s2 {char star const}

	["cxx:
	void *		tmp;

	if (s1 !!= NULL ) {
		tmp = (void *)s1;
		delete tmp;
	}
	if (s2 !!= NULL) {
		tmp = (void *)s2;
		delete tmp;
	}"] translateOnly!

{void} savePromise: aPromise {XuPromise}

	| aCollector {XuCollectionAgent} |
	(CurrentCollector == NULL) ifTrue: [ Heaper BLAST: #NotInDelayBlock ].
	aCollector _ CurrentCollector.
	[true] whileTrue: [
		(aCollector handlesProblem: aPromise problemName) ifTrue: [
			aCollector addPromise: aPromise.
			^VOID.]
		ifFalse: [
			(aCollector previous == NULL) ifTrue: [ Heaper BLAST: #NoCollectorForPromise ].
			aCollector _ aCollector previous]].! !

!XuPromise class methodsFor: 'smalltalk: create'!

create.Problem: problem {Problem}

^self new create.Problem: problem!

create.Promise: promise {XuPromise}

^self new create.Promise: promise!

dynamicType: promise
	| actual |
	promise == NULL ifTrue: [^promise].
	actual _ self getActual: promise.
	^actual class promiseClass make: actual! !

!XuPromise class methodsFor: 'smalltalk: macros'!

{void} delayTry: aProblemList {char star vector} with: aBlock catch: aHandler

	| collector {XuCollectionAgent} aPromise {XuPromise} |
	self newCollector: aProblemList.
	collector := CurrentCollector.
	[aBlock value] valueNowOrOnUnwindDo: [self popCollector].
	self force.
	aPromise _ collector firstPromise.
	[aPromise ~~ NULL] whileTrue: [
		aHandler value: aPromise.
		aPromise _ aPromise next].! !

XuPromise subclass: #XuVoid
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-promise'!

(XuVoid getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!XuVoid methodsFor: 'creation'!

create

 	super create.!

create.Problem: problem {Problem}

	super create.Problem: problem.!

create.Promise: promise {XuPromise}

	super create.Promise: promise.! !

!XuVoid methodsFor: 'accessing'!

{void} value

	self isForced ifFalse: [ Heaper BLAST: #UnforcedValue].
	self isBroken ifTrue: [self explode].
	^VOID.! !

!XuVoid methodsFor: 'printing'!

{void} printOn: oo {ostream reference}
	oo << 'Xu(Void)'! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

XuVoid class
	instanceVariableNames: ''!

(XuVoid getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!XuVoid class methodsFor: 'pseudo-constructors'!

make

	^self create.!

{XuVoid} makeBroken: problem {Problem}

	^self create.Problem: problem.!

{XuVoid} makeBrokenBy: broken {XuPromise}

	^self create.Promise: broken.! !

!XuVoid class methodsFor: 'smalltalk: testing'!

{Boolean} isNotGenerated
	^ true! !