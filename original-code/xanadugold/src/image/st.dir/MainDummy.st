'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:06:33 pm'!

Heaper subclass: #MainDummy
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-rcmain'!
MainDummy comment:
'A dummy class on which to hang the main that reads in an rc file.'!

(MainDummy getOrMakeCxxClassDescription)
	friends:
'/* friends for class MainDummy */

friend int  main (int argc, char* * argv);';
	attributes: ((Set new) add: #DEFERRED; yourself)!
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

MainDummy class
	instanceVariableNames: ''!

(MainDummy getOrMakeCxxClassDescription)
	friends:
'/* friends for class MainDummy */

friend int  main (int argc, char* * argv);';
	attributes: ((Set new) add: #DEFERRED; yourself)!

!MainDummy class methodsFor: 'smalltalk: booting'!

{void} run: filename
	self XU.U.MAIN: 2 with: (Array with: filename)!

{void} runString: string 
	Initializer doMain:
	[| rc {Rcvr} next {Heaper | NULL} |
	rc _ TextyXcvrMaker make 
				makeRcvr: (TransferSpecialist make: (Cookbook make.String: 'boot'))
				with: (XnReadFile create: string readStream).
	next _ rc receiveHeaper.
	[next ~~ NULL] whileTrue: 
		[next cast: Thunk into: [:thunk | thunk execute] others: [].
		next _ rc receiveHeaper].
	rc destroy].
	^Int32Zero!

{void} toFile: fileName {Filename} runString: string {String}
	| aStream saveCerr |

	aStream _ fileName writeStream.
	saveCerr _ cerr.
	[| rc {Rcvr} next {Heaper | NULL} |
	cerr _ aStream.
	self knownBug. "only accepts UInt8Arrays"
	rc _ TextyXcvrMaker make 
				makeRcvr: (TransferSpecialist make: (Cookbook make.String: 'boot'))
				with: (XnReadFile create: string readStream).
	next _ rc receiveHeaper.
	[next ~~ NULL] whileTrue: 
		[next cast: Thunk into: [:thunk | thunk execute] others: [].
		next _ rc receiveHeaper].
	rc destroy] valueNowOrOnUnwindDo: 
		[cerr _ saveCerr.
		aStream close]! !

!MainDummy class methodsFor: 'smalltalk: init'!

staticTimeNonInherited
	Rcvr defineFluid: #CurrentMainReceiver with: Emulsion globalEmulsion with: [NULL].
	Heaper defineFluid: #MainActiveThunk with: Emulsion globalEmulsion with: [NULL].! !

!MainDummy class methodsFor: 'global: booting'!

{int} XU.U.MAIN: argc {int} with: argv {char star vector}
	| stackObject {Int32} |
	[StackExaminer] USES.
	'StackExaminer::stackEnd(&stackObject);' translateOnly.
	Initializer with: argc with: argv doMain:
	[| rc {Rcvr} next {Heaper | NULL} |
	argc < 2 ifTrue: [cerr << 'usage: ' << (argv at: Int32Zero) << ' rcFileName
'.	^1].
	rc _ TextyXcvrMaker make 
			makeRcvr: (TransferSpecialist make: (Cookbook make.String: 'boot')) 
			with: (XnReadFile make: (argv at: 1)).
	CurrentMainReceiver fluidBind: rc during:
		[next _ CurrentMainReceiver fluidGet receiveHeaper.
		[next ~~ NULL] whileTrue:
			[MainActiveThunk fluidBind: next during:
				[next cast: Thunk into: [:thunk | thunk execute] others: []].
			next _ CurrentMainReceiver fluidGet  receiveHeaper].
			CurrentMainReceiver fluidGet destroy].
	^Int32Zero]! !

!MainDummy class methodsFor: 'smalltalk: passe'!

{int} main: argc {int} with: argv {char star vector}
	
	self passe! !