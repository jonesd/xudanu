'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:02:37 pm'!

Tester subclass: #HelloTester
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Testing'!

(HelloTester getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #(COPY boot ); yourself)!

!HelloTester methodsFor: 'testing'!

{IntegerVar ifdefFOO ifndefBAR} ifdefTest
 
	^IntegerVar0!

{void} test1On: aStream {ostream reference} 
	"self tryTest: #test1On:"
	
	aStream << 'Hello, translated world!!
'! !

!HelloTester methodsFor: 'running tests'!

{void} allTestsOn: aStream {ostream reference} 
	"HelloTester runTest"
	
	aStream << ' 
Running Hello, world!! test.
'.
	self test1On: aStream.! !

!HelloTester methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.! !