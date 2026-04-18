'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:04:24 pm'!

Tester subclass: #BecomeTester
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Xpp-Become'!

(BecomeTester getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #(COPY boot ); yourself)!

!BecomeTester methodsFor: 'testing'!

{void} allTestsOn: oo {ostream reference} 
	"BecomeTester runTest"

	self test1On: oo.!

{void} test1On: oo {ostream reference} 
	"BecomeTester runTest: #test1On:"
	| cham {Chameleon} |
	cham _ Moth make.
	cham explain: oo.
	(cham cast: Moth) molt.
	cham explain: oo.! !

!BecomeTester methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.! !