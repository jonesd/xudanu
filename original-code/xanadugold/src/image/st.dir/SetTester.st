'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:02:40 pm'!

Tester subclass: #SetTester
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Testing'!

(SetTester getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #(COPY boot ); yourself)!

!SetTester methodsFor: 'testing'!

{void} allTestsOn: oo {ostream reference} 
	| aTester {Tester} |

	aTester _ HashSetTester create.
	aTester allTestsOn: oo.
	aTester _ ImmuSetTester create.
	aTester allTestsOn: oo! !

!SetTester methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.! !