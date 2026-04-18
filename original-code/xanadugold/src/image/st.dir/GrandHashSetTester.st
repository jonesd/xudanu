'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:00:28 pm'!

MuSetTester subclass: #GrandHashSetTester
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Collection-Grand'!

(GrandHashSetTester getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #(COPY boot ); yourself)!

!GrandHashSetTester methodsFor: 'testing'!

{void} allTestsOn: oo {ostream reference} 
	
	oo << 'GrandHashSet testing
'.
	super allTestsOn: oo.
	oo << 'End of GrandHashSet testing
'! !

!GrandHashSetTester methodsFor: 'accessing'!

{ScruSet} generateSet

	^ GrandHashSet make: 2!

{ScruSet} generateSetContaining: stuff {Stepper}
	| t {MuSet} |
	t _ GrandHashSet make: 2.
	stuff forEach: [:e {Heaper} |
		t store: e].
	^ t! !

!GrandHashSetTester methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.! !