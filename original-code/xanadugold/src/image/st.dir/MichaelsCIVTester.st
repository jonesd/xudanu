'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:06:39 pm'!

Tester subclass: #MichaelsCIVTester
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-michael'!

(MichaelsCIVTester getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #(COPY boot ); yourself)!

!MichaelsCIVTester methodsFor: 'running tests'!

{void} allTestsOn: oo {ostream reference} 
	"MainDummy runString:	 '
		MichaelsCIVTester();
		NULL;'"

	self test1On: oo.
	self test2On: oo.
	self test3On: oo.! !

!MichaelsCIVTester methodsFor: 'testing'!

{void} test1On: oo {ostream reference} 
	|  |
	
	oo << 'Hello, world!!
'!

{void} test2On: oo {ostream reference} 
	|  |
	
	oo << 'MichaelsCIVSuper make classInstanceVar = ' << MichaelsCIVSuper make fetchClassInstanceVar << '
'.
	oo << 'MichaelsCIVSub make classInstanceVar = ' << MichaelsCIVSub make fetchClassInstanceVar << '
'!

{void} test3On: oo {ostream reference} 
	|  |
	
	oo << '
MichaelsCIVSuper make: oo emits:
'.
	MichaelsCIVSuper make: oo.
	
	oo << '
MichaelsCIVSub make: ooemits:
'.
	MichaelsCIVSub make: oo.! !

!MichaelsCIVTester methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.! !