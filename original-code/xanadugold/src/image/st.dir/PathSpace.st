'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:02:23 pm'!

CoordinateSpace subclass: #PathSpace
	instanceVariableNames: 'myKeySpace {CoordinateSpace}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Spaces-Paths'!
PathSpace comment:
'A PathSpace represents a space in which there is an outer space from which keys are chosen, and then at each key there is a an arbitrary sub-space.'!

(PathSpace getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #OBSOLETE; add: #COPY; yourself)!

!PathSpace methodsFor: 'testing'!

{UInt32} hashForEqual
	^myKeySpace hashForEqual bitXor: #cat.U.PathSpace hashForEqual!

{BooleanVar} isEqual: other {Heaper}

	other 
		cast: PathSpace into: [:ps |
			^ps keySpace isEqual: myKeySpace]
		others: [^false]! !

!PathSpace methodsFor: 'accessing'!

{CoordinateSpace} keySpace
	^myKeySpace! !

!PathSpace methodsFor: 'smalltalk: passe'!

create: keySpace {CoordinateSpace}
	self passe.
	super create.
	myKeySpace _ keySpace! !

!PathSpace methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	myKeySpace _ receiver receiveHeaper.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	xmtr sendHeaper: myKeySpace.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

PathSpace class
	instanceVariableNames: ''!

(PathSpace getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #OBSOLETE; add: #COPY; yourself)!

!PathSpace class methodsFor: 'pseudo constructors'!

make: cs {CoordinateSpace}
	^PathSpace create: cs! !