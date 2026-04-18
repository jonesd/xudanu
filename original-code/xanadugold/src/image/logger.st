'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 24 July 1995 at 3:41:19 pm'!

((CxxSystemOrganization tree childNamed: #logger) ~= nil) ifTrue: [
	(CxxSystemOrganization tree childNamed: #logger) destroyFiles]!

Object subclass: #Logger
	instanceVariableNames: '
		myLogFn {Symbol}
		myName {Symbol}
		myStream {ostream star}'
	classVariableNames: '
		MyFlags {Dictionary of: Symbol with: #(none cerr cout file )} 
		MyLoggers {Dictionary of: Symbol with: Logger} '
	poolDictionaries: ''
	category: 'Xanadu-logger'!

(Logger getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!Logger methodsFor: 'creation'!

create: name {Symbol}

	super create.
	myLogFn := #initFn:with:.
	myName := name.
	myStream := cerr.
	self registerYourself!

registerYourself
	
	MyFlags == nil ifTrue:
		[MyFlags _ Dictionary new].
	MyLoggers == nil ifTrue:
		[MyLoggers _ Dictionary new].
		
	(MyFlags includesKey: myName) ifFalse:
		[MyFlags at: myName put: #none].
	MyLoggers at: myName put: self! !

!Logger methodsFor: 'ops'!

{Logger ref} << arb

	(self of: '') ifTrue:
		[self stream << arb].
	^self! !

!Logger methodsFor: 'accessing'!

{void} init: str {Character star | NULL}

	| directive {Symbol} |
	myStream flush.
	(str == NULL or: [(directive _ str asSymbol) == #none]) ifTrue:
		[myLogFn _ #nopFn:with:.
		^VOID].
	myLogFn _ #logFn:with:.
	(directive == #cerr or: [directive == #cout]) ifTrue:
		[myStream _ cerr]
	ifFalse: [directive == #file ifTrue:
		[ | fname {String} |
		
		"If the Logger's name ends in 'Log', chop it off"
		(myName testSuffix: 'Log' ignoreCase: false) ifTrue:
			[fname _ myName copyFrom: 1 to: myName size - 'Log' size]
		ifFalse:
			[fname _ myName].
		
		"convert to lower case and append '.log'"
		fname _ fname asLowercase, '.log'.
		
		"open a file of that name for output and set this Logger to it"
		myStream _ (Filename named: fname) writeStream]
	ifFalse:
		[cerr << 'Logging directive "' << directive << '" unrecognized for logger "' << myName << '"
'.
		Heaper BLAST: #UnrecognizedLoggingDirective]]!

{Character star} name

	^myName!

{BooleanVar} of: str {Character star}

	^Logger perform: myLogFn with: self with: str!

{ostream} stream
	
	^myStream! !

!Logger methodsFor: 'smalltalk: macros'!

{void} LOG: aBlock {BlockClosure of: ostream reference}

	(self of: '') ifFalse: [^VOID].
	[aBlock value: myStream]
		valueNowOrOnUnwindDo: [myStream flush]! !

!Logger methodsFor: 'smalltalk: passe'!

register
	
	self passe! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

Logger class
	instanceVariableNames: ''!

(Logger getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!Logger class methodsFor: 'smalltalk: support'!

defineLogger: nm {Symbol} with: str {Character star default: NULL}

	MyFlags == nil ifTrue:
		[MyFlags _ Dictionary new].
	((MyFlags includesKey: nm) not and: [str ~~ NULL]) ifTrue:
		[MyFlags at: nm put: str asSymbol].
	Smalltalk safeAt: nm put: (Logger make: nm).!

{void} menu
	"Logger menu"

	[| menuDesc {OrderedCollection of: (Array | Symbol)} logName {Symbol | 0} directive {Symbol | 0} |
	menuDesc _ OrderedCollection new.
	MyFlags keys asSortedCollection do: [:k {Symbol} |
		menuDesc add: (Array
			with: (k, ' -> ', (MyFlags at: k))
			with: k
			with: 'Xu: Change the state of the logger')].
	logName _ (PopUpMenu fromArray: menuDesc) startUp.
	logName = 0 ifTrue: [^VOID].
	directive _ (PopUpMenu fromArray: #(
		('none'	none	'Xu: don''t log')
		('cerr'	cerr		'Xu: log to the Transcript')
		('cout'	cout		'Xu: log to the Transcript')
		('file'	file		'Xu: log to a file whose name is calculated from the name of the Logger'))) startUp.
	directive = 0 ifTrue: [^VOID].
	MyFlags at: logName put: directive]
		repeat! !

!Logger class methodsFor: 'fns'!

{Logger | NULL} fetch: nm {char star}

	^MyLoggers at: nm asSymbol ifAbsent: [^NULL]!

{Logger} get: nm {char star}

	| result {Logger | NULL} |
	result _ Logger fetch: nm.
	result == NULL ifTrue:
		[Heaper BLAST: #NotFound]
	ifFalse:
		[^result]!

{BooleanVar} initFn: logger {Logger} with: str {Character star}

	logger init: (MyFlags at: logger name).
	^logger of: str!

{BooleanVar} logFn: logger {Logger} with: str {Character star}

	logger stream << str.
	^true!

{BooleanVar} nopFn: logger {Logger} with: str {Character star}

	^false! !

!Logger class methodsFor: 'smalltalk: init'!

cleanupGarbage
	"Logger cleanupGarbage"

	"MyFlags _ nil."
	MyLoggers _ nil!

linkTimeNonInherited
	Logger defineLogger: #VanillaLog.
	Logger defineLogger: #ErrorLog with: 'cerr'.! !

!Logger class methodsFor: 'creation'!

make: aName {Character star}

	^self create: aName asSymbol! !

!Logger class methodsFor: 'smalltalk: defaults'!

defineLogger: nm {Symbol}

	self defineLogger: nm with: NULL! !
(CxxSystemOrganization fileNamed: 'logger')
	comment: ''!


(CxxSystemOrganization getOrMakeFileNamed: 'logger')
	addClass: Logger
getOrMakeCxxClassDescription in: #public!

CxxSystemOrganization tree: (CxxSystemOrganization tree addChild:
	((CxxTreeAssociation key: #logger value: #file) yourself))!