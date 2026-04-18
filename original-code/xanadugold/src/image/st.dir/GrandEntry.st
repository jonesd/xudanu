'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:00:27 pm'!

Abraham subclass: #GrandEntry
	instanceVariableNames: 'objectInternal {Heaper}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Collection-Grand'!
GrandEntry comment:
'GrandEntries probably want to not be remembered right when they are created,
and remembered when they are finally put into their place in the GrandDataPages
or GrandOverflows'!

(GrandEntry getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #DEFERRED; add: #COPY; add: #SHEPHERD.PATRIARCH; add: #DEFERRED.LOCKED; yourself)!

!GrandEntry methodsFor: 'accessing'!

{Heaper} value
	objectInternal == NULL ifTrue: [Heaper BLAST: #NotInTable].
	^ objectInternal! !

!GrandEntry methodsFor: 'protected: creation'!

create: value {Heaper} with: hash {UInt32}
	super create: hash.
	value == NULL ifTrue: [Heaper BLAST: #NullInsertion].
	[value == nil ifTrue: [Heaper BLAST: #NullInsertion]] smalltalkOnly.
	objectInternal _ value.! !

!GrandEntry methodsFor: 'deferred: testing'!

{BooleanVar} compare: anObj {Heaper | Position}
	self subclassResponsibility!

{BooleanVar} matches: anEntry {GrandEntry}
	self subclassResponsibility! !

!GrandEntry methodsFor: 'testing'!

{UInt32} contentsHash

	^(super contentsHash
		bitXor: (IntegerPos integerHash: self hashForEqual))
		bitXor: objectInternal hashForEqual! !

!GrandEntry methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	objectInternal _ receiver receiveHeaper.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	xmtr sendHeaper: objectInternal.! !