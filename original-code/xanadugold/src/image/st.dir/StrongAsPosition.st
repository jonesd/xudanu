'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:02:32 pm'!

HeaperAsPosition subclass: #StrongAsPosition
	instanceVariableNames: 'itsHeaper {Heaper}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Spaces-Unordered'!

(StrongAsPosition getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; add: #COPY; yourself)!

!StrongAsPosition methodsFor: 'testing'!

{UInt32} actualHashForEqual
	^itsHeaper hashForEqual!

{BooleanVar} isEqual: other {Heaper}

	other cast: HeaperAsPosition into: [:hap | 
			^itsHeaper == hap heaper 
				or: [itsHeaper isEqual: hap heaper]]
		others: [^false].
	^false "fodder"! !

!StrongAsPosition methodsFor: 'accessing'!

{CoordinateSpace} coordinateSpace
	^ HeaperSpace make!

{Heaper} heaper
	^ itsHeaper! !

!StrongAsPosition methodsFor: 'printing'!

{void} printOn: oo {ostream reference} 
	oo << 'position of (' << itsHeaper << ')'! !

!StrongAsPosition methodsFor: 'instance creation'!

create: aHeaper {Heaper}
	super create.
	aHeaper ~~ NULL assert: 'Heapers in StrongAsPosition must be real'.
	itsHeaper _ aHeaper! !

!StrongAsPosition methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	itsHeaper _ receiver receiveHeaper.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	xmtr sendHeaper: itsHeaper.! !