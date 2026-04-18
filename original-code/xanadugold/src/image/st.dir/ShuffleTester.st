'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:05:32 pm'!

Tester subclass: #ShuffleTester
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Xcvr'!
ShuffleTester comment:
'test the ByteShufflers '!

(ShuffleTester getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #(COPY boot ); yourself)!

!ShuffleTester methodsFor: 'testing'!

{void} test1On: aStream {ostream reference} 
	"self tryTest: #test1On:"
	| simpleString {UInt8Array} shuffler {ByteShuffler} copy {UInt8Array} |

	shuffler _ SimpleShuffler create.
	simpleString _ UInt8Array string: 'abcdefghijkl'.
	copy _ simpleString copy cast: UInt8Array.
	shuffler shuffle: 16 with: copy gutsOf with: 6. copy noMoreGuts.
	aStream << '
Shuffling 16: ' << simpleString << ' to: ' << copy << '
'.
	copy _ simpleString copy cast: UInt8Array.
	shuffler shuffle: 32 with: copy gutsOf with: 3. copy noMoreGuts.
	aStream << 'Shuffling 32: ' << simpleString << ' to: ' << copy << '
'.

	simpleString _ UInt8Array string: ''.
	copy _ simpleString copy cast: UInt8Array.
	shuffler shuffle: 16 with: copy gutsOf with: Int32Zero. copy noMoreGuts.
	aStream << 'Shuffling an empty string 16: ' << copy << '
'.
	copy _ simpleString copy cast: UInt8Array.
	shuffler shuffle: 32 with: copy gutsOf with: Int32Zero. copy noMoreGuts.
	aStream << 'Shuffling an empty string 32: ' << copy << '
'.

	copy _ UInt8Array string: 'ab'.
	shuffler shuffle: 16 with: copy gutsOf with: 1. copy noMoreGuts.
	aStream << 'Shuffling a tiny string 16: ' << copy << '
'.

	simpleString _ UInt8Array string: 'abcd'.
	copy _ simpleString copy cast: UInt8Array.
	shuffler shuffle: 32 with: copy gutsOf with: 1. copy noMoreGuts.
	aStream << 'Shuffling a tiny string 32: ' << copy << '
'.
	copy _ simpleString copy cast: UInt8Array.
	shuffler shuffle: 16 with: copy gutsOf with: 2. copy noMoreGuts.
	aStream << 'Shuffling a small string 16: ' << copy << '
'.

	copy _ UInt8Array string: 'abcdef'.
	shuffler shuffle: 16 with: copy gutsOf with: 3. copy noMoreGuts.
	aStream << 'Shuffling a small string 16: ' << copy << '
'.! !

!ShuffleTester methodsFor: 'running tests'!

{void} allTestsOn: aStream {ostream reference} 
	"ShuffleTester runTest"
	
	aStream << 'testing shuffler
'.
	self test1On: aStream.! !

!ShuffleTester methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.! !