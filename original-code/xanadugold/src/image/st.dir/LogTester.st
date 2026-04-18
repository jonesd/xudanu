'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:08:29 pm'!

Tester subclass: #LogTester
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-hlogger'!

(LogTester getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #(COPY boot ); yourself)!

!LogTester methodsFor: 'testing'!

{void} allTestsOn: oo {ostream reference} 
 
	FooLog << 'foo ' << self << '
'.
	VanillaLog << 'bar ' << self << '
'.
	ErrorLog << 'err ' << self << '
'.

	FooLog LOG: [:ooo |
		ooo << 'zip ' << self << '
'].
	VanillaLog LOG: [:ooo |
		ooo << 'zap ' << self << '
'].
	ErrorLog LOG: [:ooo |
		ooo << 'human ' << self << '
'].! !

!LogTester methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

LogTester class
	instanceVariableNames: ''!

(LogTester getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #(COPY boot ); yourself)!

!LogTester class methodsFor: 'smalltalk: init'!

linkTimeNonInherited
	Logger defineLogger: #FooLog! !