'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:00:31 pm'!

GrandEntry subclass: #GrandSetEntry
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Collection-Grand'!

(GrandSetEntry getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #COPY; add: #SHEPHERD.ANCESTOR; add: #LOCKED; add: #NOT.A.TYPE; add: #CONCRETE; yourself)!

!GrandSetEntry methodsFor: 'testing'!

{BooleanVar} compare: anObj {Heaper | Position}
	^ self value isEqual: anObj!

{BooleanVar} matches: anEntry {GrandEntry}
	^ self value isEqual: anEntry value! !

!GrandSetEntry methodsFor: 'protected: creation'!

create: value {Heaper} with: hash {UInt32}
	super create: value with: hash.
	self newShepherd.
	self remember! !

!GrandSetEntry methodsFor: 'printing'!

{void} printOn: aStream {ostream reference}
	aStream << 'GrandSetEntry(hash=' << self hashForEqual << ', value=' << self value << ')'! !

!GrandSetEntry methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

GrandSetEntry class
	instanceVariableNames: ''!

(GrandSetEntry getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #COPY; add: #SHEPHERD.ANCESTOR; add: #LOCKED; add: #NOT.A.TYPE; add: #CONCRETE; yourself)!

!GrandSetEntry class methodsFor: 'create'!

{GrandEntry} make: value {Heaper} with: hash {UInt32}
	^ self create: value with: hash! !