'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:06:40 pm'!

Tester subclass: #MichaelsHacksTester
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-michael'!

(MichaelsHacksTester getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #(COPY boot ); yourself)!

!MichaelsHacksTester methodsFor: 'creation'!

create
	super create ": 'michael'"! !

!MichaelsHacksTester methodsFor: 'testing'!

{void} allTestsOn: oo {ostream reference} 
	"MichaelsHacskTester runTest"

	self test1On: oo.
	self test2On: oo.!

{void} test1On: oo {ostream reference} 
	"MichaelsHacksTester runTest: #test1On:"
	|  |
	
	oo << 'Hello, world!!
'!

{void} test2On: oo {ostream reference} 
	"MichaelsHacksTester runTest: #test2On:"
	|  |
	
	oo << '((3 - 5) + 7) = ' << ((3 - 5) + 7) << '
'.
	oo << '(3 - (5 + 7)) = ' << (3 - (5 + 7)) << '
'.! !

!MichaelsHacksTester methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.! !