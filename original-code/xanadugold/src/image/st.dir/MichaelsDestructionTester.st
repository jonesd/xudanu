'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:06:40 pm'!

Tester subclass: #MichaelsDestructionTester
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-michael'!

(MichaelsDestructionTester getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #(COPY boot ); yourself)!

!MichaelsDestructionTester methodsFor: 'running tests'!

{void} allTestsOn: oo {ostream reference} 
	"MainDummy runString:	 '
		MichaelsCIVTester();
		NULL;'"

	self test1On: oo.
	"self test2On: oo."! !

!MichaelsDestructionTester methodsFor: 'testing'!

{void} test1On: oo {ostream reference} 
	|  |
	
	oo << 'Hello, world!!
'!

{void} test2On: oo {ostream reference} 
	| michaelsDestructionSubP {MichaelsDestructionSuper} |
	
	michaelsDestructionSubP := MichaelsDestructionSub make.
	oo << 'MichaelsDestructionSuper make = ' << michaelsDestructionSubP << '
'.
	michaelsDestructionSubP destroy.! !

!MichaelsDestructionTester methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.! !