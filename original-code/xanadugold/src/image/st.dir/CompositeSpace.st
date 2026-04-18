'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:02:05 pm'!

CoordinateSpace subclass: #CompositeSpace
	instanceVariableNames: 'mySubSpaces {ImmuTable of: CoordinateSpace}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Spaces-Composite'!

(CompositeSpace getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #OBSOLETE; add: #COPY; add: #SMALLTALK.ONLY; add: #CONCRETE; yourself)!

!CompositeSpace methodsFor: 'creation'!

create: subs {ImmuTable of: CoordinateSpace}

	Ravi shouldImplement.
	"super create: emptyRegion with: fullRegion with: identityDsp with: ascending with: descending."
	mySubSpaces _ subs.! !

!CompositeSpace methodsFor: 'accessing'!

{CoordinateSpace} subSpace: key {Position}
	"the sub space at a given key"
	^(mySubSpaces get: key) cast: CoordinateSpace!

{ImmuTable of: CoordinateSpace} subSpaces
	^mySubSpaces! !

!CompositeSpace methodsFor: 'testing'!

{UInt32} hashForEqual
	^mySubSpaces hashForEqual bitXor: #cat.U.CompositeSpace hashForEqual!

{BooleanVar} isEqual: other {Heaper}
	^(other isKindOf: CompositeSpace)
		and: [(other basicCast: CompositeSpace) subSpaces isEqual: mySubSpaces]! !

!CompositeSpace methodsFor: 'printing'!

{void} printOn: oo {ostream reference}
	oo << self getCategory name.
	mySubSpaces printOnWithSyntax: oo with: '(' with: ': ' with: ', ' with: ')'.! !

!CompositeSpace methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	mySubSpaces _ receiver receiveHeaper.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	xmtr sendHeaper: mySubSpaces.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

CompositeSpace class
	instanceVariableNames: ''!

(CompositeSpace getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #OBSOLETE; add: #COPY; add: #SMALLTALK.ONLY; add: #CONCRETE; yourself)!

!CompositeSpace class methodsFor: 'pseudo constructors'!

make: subSpaces {ScruTable of: CoordinateSpace}
	subSpaces count < 2 ifTrue: [Heaper blast.InvalidRequest raise].
	^CompositeSpace create: subSpaces asImmuTable! !