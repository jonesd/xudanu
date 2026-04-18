'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:00:35 pm'!

ScruSet subclass: #MuSet
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Collection-Sets'!
MuSet comment:
'MuSets are a changable collection of elements.  Added to the ScruSet protocol are messages for performing these changes.  The "introduce/store/wipe/remove" suite is defined by analogy with similar methods in MuTable.  See both ScruSet and MuTable.'!

(MuSet getOrMakeCxxClassDescription)
	friends:
'/* friends for class MuSet */
friend class ImmuSetOnMu;
friend class COWMuSet;';
	attributes: ((Set new) add: #DEFERRED; add: #EQ; yourself)!

!MuSet methodsFor: 'accessing'!

{BooleanVar} hasMember: someone {Heaper}
	self subclassResponsibility!

{BooleanVar} isEmpty
	self subclassResponsibility! !

!MuSet methodsFor: 'operations'!

{void} restrictTo: other {ScruSet} 
	"Sort of intersect.  Wipe from myself all elements that I don't have in common with other.
	Turn myself into the intersection of my current self and other."

	| tmp {MuSet} |
	tmp _ self copy cast: MuSet.
	tmp wipeAll: other.
	self wipeAll: tmp.
	tmp destroy.!

{void} storeAll: other {ScruSet} 
	"Sort of union.  Store into myself all elements from other.
	Turn myself into the union of my current self and other."

	other stepper forEach: [:elem {Heaper wimpy} | self store: elem]!

{void} wipeAll: other {ScruSet} 
	"Sort of minus.  Wipe from myself all elements from other.
	Turn myself into my current self minus other."

	other stepper forEach: [:elem {Heaper wimpy} | self wipe: elem]! !

!MuSet methodsFor: 'adding-removing'!

{void} introduce: anElement {Heaper}
	"Add anElement to my members, but only if it isn't already a member.
	If it is already a member, BLAST"
	
	self subclassResponsibility!

{void} remove: anElement {Heaper}
	"Remove anElement from my members.  If it isn't currently a member, then BLAST"
	
	self subclassResponsibility!

{void} store: anElement {Heaper}
	"Add anElement to my set of members.  No semantic effect if anElement is already a member."
	
	self subclassResponsibility!

{void} wipe: anElement {Heaper}
	"make anElement no longer be one of my members.  No semantic effect if it already isn't a member."
	
	self subclassResponsibility! !

!MuSet methodsFor: 'creation'!

{ScruSet} copy
	self subclassResponsibility! !

!MuSet methodsFor: 'conversion'!

{ImmuSet} asImmuSet
	self isEmpty ifTrue: [^ ImmuSet make].
	self count == 1 ifTrue: [^ ImmuSet make with: (self theOne)].
	^ ImmuSet make: self!

{MuSet} asMuSet
	^ self copy quickCast: MuSet! !

!MuSet methodsFor: 'enumerating'!

{IntegerVar} count
	self subclassResponsibility!

{Stepper} stepper
	self subclassResponsibility! !

!MuSet methodsFor: 'private: enumerating'!

{Stepper} immuStepper
	self subclassResponsibility! !

!MuSet methodsFor: 'generated:'!

actualHashForEqual ^self asOop!

isEqual: other ^self == other! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

MuSet class
	instanceVariableNames: ''!

(MuSet getOrMakeCxxClassDescription)
	friends:
'/* friends for class MuSet */
friend class ImmuSetOnMu;
friend class COWMuSet;';
	attributes: ((Set new) add: #DEFERRED; add: #EQ; yourself)!

!MuSet class methodsFor: 'smalltalk: passe'!

make.Region: region {XnRegion} 
	"someSize is a non-semantic hint about how big the set might get."

	| result {MuSet} |
	self passe.
	result _ ActualHashSet make.IntegerVar: region count.
	region stepper forEach: [:position {Position} | result store: position].
	^result! !

!MuSet class methodsFor: 'pseudo constructors'!

{MuSet} fromStepper: stepper {Stepper}
	| result {MuSet} |
	result _ MuSet make.
	stepper forEach: [ :element {Heaper} |
		result store: element].
	^result!

{MuSet} make 
	^ActualHashSet make!

{MuSet} make.Heaper: item {Heaper}

	^ActualHashSet make.Heaper: item!

{MuSet} make.IntegerVar: someSize {IntegerVar}
	"someSize is a non-semantic hint about how big the set might get."
	^ActualHashSet make.IntegerVar: someSize! !

!MuSet class methodsFor: 'smalltalk: defaults'!

make: something
	(something isKindOf: Integer) ifTrue:
		[^self make.IntegerVar: something].
	^self make.Region: (something cast: XnRegion)! !

!MuSet class methodsFor: 'smalltalk: initialization'!

initTimeNonInherited

	self REQUIRES: ActualHashSet! !

!MuSet class methodsFor: 'exceptions: exceptions'!

problems.AlreadyInSet
	^self signals: #(AlreadyInSet)! !