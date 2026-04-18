'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:02:37 pm'!

ScruSetTester subclass: #ImmuSetTester
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Testing'!

(ImmuSetTester getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #(COPY boot ); yourself)!

!ImmuSetTester methodsFor: 'testing'!

{void} allTestsOn: oo {ostream reference} 
	oo << 'ImmuSet testing
'.
	super allTestsOn: oo.
	oo << 'End of ImmuSet testing
'! !

!ImmuSetTester methodsFor: 'accessing'!

{ScruSet} generateSet

	^ ImmuSet make!

{ScruSet} generateSetContaining: stuff {Stepper}

	| t {MuSet} |
	t _ MuSet make.
	stuff forEach: [:e {Heaper} |
		t store: e].
	^ t asImmuSet! !

!ImmuSetTester methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.! !