'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:59:47 pm'!

Tester subclass: #OrglTester
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Be-Basic'!


!OrglTester methodsFor: 'testing'!

{void} allTestsOn: aStream {ostream reference}
	"OrglTester runTest: #allTestsOn:"
	
	aStream << 'Running all Orgl tests.
	Test1
	'.
	self test1On: aStream!

{void} test1On: aStream {ostream reference}
	"OrglTester runTest: #test1On:"
	
	| gm {GrandMap} |
	gm _ GrandMap make.
	aStream << gm! !