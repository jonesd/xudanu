'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:02:41 pm'!

Tester subclass: #UrdiTester
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
	tIOAccessor close.! !