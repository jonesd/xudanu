'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:07:23 pm'!

FeWrapper subclass: #FeWorkSet
	instanceVariableNames: ''
	classVariableNames: 'TheWorkSetSpec {FeWrapperSpec} '
	poolDictionaries: ''
	category: 'Xanadu-wrapper'!
FeWorkSet comment:
'An undifferentiated set of Works.

Last minute bulletin: This will probably be changed to be a set of any kind of RangeElements, with protocol for testing types.'!

(FeWorkSet getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #OBSOLETE; add: #SMALLTALK.ONLY; yourself)!

!FeWorkSet methodsFor: 'private:'!

{IDSpace} iDSpace
	^self edition coordinateSpace cast: IDSpace! !

!FeWorkSet methodsFor: 'accessing'!

{IDRegio} iDs
	"The current global IDs of all of the Works contained"
	
	^FeServer iDsOfRange: self edition!

{BooleanVar} includes: work {FeWork}
	"Whether the set includes the given Work"
	
	^(self edition keysOf: work) isEmpty not!

{FeWorkSet} intersect: other {FeWorkSet}
	"Return those which are in both sets"
	
	^FeWorkSet construct: (self edition
		sharedWith: other edition)!

{FeWorkSet} minus: other {FeWorkSet}
	"Remove some Works from the set"
	
	^FeWorkSet construct: (self edition
		notSharedWith: other edition)!

{FeWorkSet} unionWith: other {FeWorkSet}
	"Return those which are in either set"
	
	| added {FeEdition} |
	"Need to assign new IDs to avoid collisions"
	added := other notSharedWIth: self.
	added isEmpty ifTrue: [^self].
	^FeWorkSet construct: (self edition combine:
		(FeEdition fromArray: added retrieve
			with: (self iDSpace newIDs: added count)))!

{FeWorkSet} with: work {FeWork}
	"Add a Work to the set"
	
	(self includes: work)
		ifTrue: [^self]
		ifFalse: [^FeWorkSet construct: (self edition
			with: self iDSpace newID
			with: work)]!

{FeWorkSet} without: work {FeWork}
	"Remove a Work from the set"
	
	^FeWorkSet construct: 
		(self edition notSharedWith: 
			(FeEdition fromOne: IntegerVar0 integer with: work))!

{PtrArray of: FeWork} works
	"The Works in the set"
	
	^self edition retrieve! !

!FeWorkSet methodsFor: 'printing'!

{void} printOn: oo {ostream reference}

	oo << self getCategory name << $(.
	self edition stepper forEach: [ :work {FeWork} |
		oo << $  << work].
	oo << $)! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

FeWorkSet class
	instanceVariableNames: ''!

(FeWorkSet getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #OBSOLETE; add: #SMALLTALK.ONLY; yourself)!

!FeWorkSet class methodsFor: 'pseudo constructors'!

{FeWorkSet} make

	^self construct: (FeEdition empty: IDSpace unique)!

{FeWorkSet} make: works {PtrArray of: FeWork}

	^self spec wrap: (FeEdition
		fromArray: works
		with: (IDSpace unique newIDs: works count))!

{FeWrapperSpec} spec

	^TheWorkSetSpec! !

!FeWorkSet class methodsFor: 'private: wrapping'!

{BooleanVar} check: edition {FeEdition}

	Ravi hack. "zones stuff"
	^(edition coordinateSpace isKindOf: IDSpace)
		and: [edition isFinite
		"and: [edition count = (edition zoneOf: FeWork spec) count]"]!

{FeWorkSet} construct: edition {FeEdition}

	self spec endorse: edition.
	^(self makeWrapper: edition) cast: FeWorkSet!

{FeWrapper} makeWrapper: edition {FeEdition}

	^self create: edition with: self spec!

{void} setSpec: wrap {FeWrapperSpec}

	TheWorkSetSpec := wrap.! !

!FeWorkSet class methodsFor: 'smalltalk: init'!

initTimeNonInherited

	FeWrapperSpec DIRECTWRAPPER: 'WorkSet' with: 'Wrapper' with: #FeWorkSet.!

linkTimeNonInherited

	TheWorkSetSpec := NULL.! !