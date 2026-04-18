'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:00:32 pm'!

GrandEntry subclass: #GrandTableEntry
	instanceVariableNames: 'keyInternal {Position}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Collection-Grand'!

(GrandTableEntry getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #COPY; add: #SHEPHERD.ANCESTOR; add: #LOCKED; add: #NOT.A.TYPE; add: #CONCRETE; yourself)!

!GrandTableEntry methodsFor: 'printing'!

{void} printOn: aStream {ostream reference}
	aStream << 'GrandTableEntry(hash=' << self hashForEqual << ', key='<< keyInternal << ', value=' << self value << ')'! !

!GrandTableEntry methodsFor: 'accessing'!

{Position} key
	^ keyInternal!

{Position} position
	^ keyInternal! !

!GrandTableEntry methodsFor: 'testing'!

{BooleanVar} compare: anObj {Heaper | Position}
	^ keyInternal isEqual: anObj!

{UInt32} contentsHash

	^super contentsHash
		bitXor: keyInternal hashForEqual!

{BooleanVar} matches: anEntry {GrandEntry}
	^ keyInternal isEqual: (anEntry cast: GrandTableEntry) position! !

!GrandTableEntry methodsFor: 'protected: creation'!

create: value {Heaper} with: key {Position} with: hash {UInt32}
	super create: value with: hash.
	keyInternal _ key.
	self newShepherd.
	self remember! !

!GrandTableEntry methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	keyInternal _ receiver receiveHeaper.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	xmtr sendHeaper: keyInternal.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

GrandTableEntry class
	instanceVariableNames: ''!

(GrandTableEntry getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #COPY; add: #SHEPHERD.ANCESTOR; add: #LOCKED; add: #NOT.A.TYPE; add: #CONCRETE; yourself)!

!GrandTableEntry class methodsFor: 'create'!

{GrandEntry} make: value {Heaper} with: key {Position} with: hash {UInt32}
	^ self create: value with: key with: hash! !