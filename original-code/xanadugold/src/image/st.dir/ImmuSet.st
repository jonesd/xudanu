'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:00:34 pm'!

ScruSet subclass: #ImmuSet
	instanceVariableNames: ''
	classVariableNames: 'EmptySet {ImmuSet wimpy} '
	poolDictionaries: ''
	category: 'Xanadu-Collection-Sets'!
ImmuSet comment:
'ImmuSets are ScruSets which are guaranteed never to change.  ImmuSets correspond to the mathematical notion of a finite set of elements, except of course that here the elements can be any valid X++ object.  Just like mathematical sets, two are equal (according to isEqual) iff they have the same elements.  Just because the set cannot change, that doesn''t prevent any of the members from undergoing state change.
	
	ImmuSets implement some additional protocol to make new sets out of old ones according to the familiar set theoretic operators (like intersect).  XuRegions are much like ImmuSets of Positions except that they aren''t necessarily finite or even enumerable.  XuRegions implement a similar protocol, but aren''t polymorphic with ImmuSets. '!

(ImmuSet getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #DEFERRED; yourself)!

!ImmuSet methodsFor: 'accessing'!

{BooleanVar} hasMember: someone {Heaper}
	self subclassResponsibility!

{BooleanVar} isEmpty
	self subclassResponsibility! !

!ImmuSet methodsFor: 'operations'!

{ImmuSet} intersect: another {ScruSet} 
	"Regular set intersection.  Return an ImmuSet containing only those objects which are members of 
	both sets"
	self subclassResponsibility!

{ImmuSet} minus: another {ScruSet}
	"Return an ImmuSet containing those of my members which aren't members of 'another'"
	self subclassResponsibility!

{ImmuSet} unionWith: another {ScruSet}
	"Return an ImmuSet containing those objects with are members of either of us"
	self subclassResponsibility! !

!ImmuSet methodsFor: 'adding-removing'!

{ImmuSet} with: anElement {Heaper}
	"'set->with (anElement)' means the same as 'set->unionWith (immuSet (anElement))'.
	It returns an ImmuSet with all my members and having anElement as a member.
	If anElement is a member of me, then the result is identical to me."
	self subclassResponsibility!

{ImmuSet} without: anElement {Heaper}
	"'set->without (anElement)' means the same as 'set->minus (immuSet (anElement))'.
	It returns an ImmuSet with all my members except anElement.  If anElement isn't already a member,
	then the result is identical to me."
	self subclassResponsibility! !

!ImmuSet methodsFor: 'creation'!

{ScruSet} copy
	"don't need to actually make a copy, as this is immutable"
	^self! !

!ImmuSet methodsFor: 'conversion'!

{ImmuSet} asImmuSet
	^self!

{MuSet} asMuSet
	self subclassResponsibility! !

!ImmuSet methodsFor: 'enumerating'!

{IntegerVar} count
	self subclassResponsibility!

{Stepper} stepper
	self subclassResponsibility! !

!ImmuSet methodsFor: 'testing'!

{UInt32} actualHashForEqual
	^self contentsHash!

{BooleanVar} isEqual: other {Heaper} 

	other cast: ImmuSet into: [:o |
			^self contentsEqual: o]
		others: [^false].
	^ false "compiler fodder"! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

ImmuSet class
	instanceVariableNames: ''!

(ImmuSet getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #DEFERRED; yourself)!

!ImmuSet class methodsFor: 'smalltalk: constructors'!

create.MuSet: ms
	^ self new create.MuSet: ms!

{ImmuSet} make: thing
	(thing isKindOf: XnRegion)
		ifTrue: [false assert: 'Use region convert: ImmuSet'.
				^ImmuSet make.XuRegion: thing].
	^ImmuSet make.MuSet: (thing cast: MuSet)! !

!ImmuSet class methodsFor: 'protected: pseudo constructors'!

{ImmuSet} from: set {MuSet}
	"This is for ImmuSet subclasses to produce results from temporary MuSets.
	The difference between this and ImmuSet make.MuSet: is that this doesn't make a copy
	of the MuSet when making an ImmuSetOnMu."
	set isEmpty ifTrue: [^ EmptySet].
	set count == 1 ifTrue: [^ TinyImmuSet make: set theOne].
	^ ImmuSetOnMu make: set! !

!ImmuSet class methodsFor: 'pseudo constructors'!

{ImmuSet INLINE} make
	^EmptySet!

{ImmuSet} make.MuSet: set {MuSet}

	set isEmpty ifTrue: [^ EmptySet].
	set count == 1 ifTrue: [^ TinyImmuSet make: set theOne].
	^ ImmuSetOnMu make: (set copy cast: MuSet).!

{ImmuSet} newWith: value {Heaper}
	"A single element ImmuSet"
	
	^TinyImmuSet make: value! !

!ImmuSet class methodsFor: 'smalltalk: initialization'!

initTimeNonInherited
	self REQUIRES: Stepper.
	EmptySet _ (EmptyImmuSet new.AllocType: #PERSISTENT) create.!

linkTimeNonInherited

	EmptySet _ NULL! !

!ImmuSet class methodsFor: 'smalltalk: passe'!

make.Heaper: aSingleton {Heaper}

	self passe. "use ImmuSet make with: aSingleton"!

{ImmuSet} with: value {Heaper}
	"A single element ImmuSet"
	
	self passe. "use newWith:"! !