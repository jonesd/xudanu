'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:02:40 pm'!

Tester subclass: #SnefruTester
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
'! !