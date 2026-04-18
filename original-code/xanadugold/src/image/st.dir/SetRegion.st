'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:02:31 pm'!

XnRegion subclass: #SetRegion
	instanceVariableNames: '
		myPositions {(ImmuSet of: Position) copy}
		myIsComplement {BooleanVar copy}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Spaces-Unordered'!
SetRegion comment:
'How do you make regions for spaces whose positions
		a) have no orderring (i.e., either no ordering can be imposed (as 
			in HeaperSpace) or it is undesirable to impose one (as curently 
			in IDSpace)); and
		b) there is an inifinte supply of new positions, and you can only 
			name the positions you''ve encountered?
			
	SetRegion is our answer to that.  To start with, a set region can simply be an enumeration of the positions which are its members.  However, because the complement of an XuRegion must be a valid XuRegion, and we have no other representation of the infinite set of positions left over, we must also be able to represent the region consisting of all positions except those explicitly enumerated.  Every SetRegion must either have a finite number of positions, or it must cover all the space except for a finite number of positions.
	
	With regard to degrees of simplicity (see class comment in XuRegion), we currently only have distinctions.  There are no non-distinctions, and therefore no non-simple SetRegions.  Interesting cases are:
	
		1) empty region
		2) full region
		3) singleton set (single member)
		4) singleton hole (single non-member)
		5) region with more than 1, but a finite number, of members
		6) region with more than 1, but a finite number, of non-members
	
	Cases 1, 3, and 5 can be considered the "positive" regions, and cases 2, 4, and 6 the "negative" ones.
	
	Because we only have distinctions (which we are currently doing for an internal reason which will probably go away), we forego the ability to use the generic XuRegion protocol to decompose complex regions into simpler ones.  Instead we provide SetRegion specific protocol ("positions" and "isComplement").  
	
	At a later time, we will probably have cases 1 thru 4 above be the only distinctions, case 6 be a simple region but not a distinction, and have case 5 be a non-simple region.  (These choices are all consistent with the letter and spirit of the simplicity framework documented in XuRegion.  Simple regions must be the *intersection* of distinctions, therefore case 5 cannot be a simple non-distinction.)  Please try to write your software so that it''ll be insensitive to this change.  Thanks.
	
	SetRegion is an abstract superclass useful for defining regions for spaces which have the constraints listed above.'!

(SetRegion getOrMakeCxxClassDescription)
	friends:
'/* friends for class SetRegion */
SPTR(SetRegion) setRegion (CoordinateSpace * cs, ImmuSet * aSet);
friend class SetRegionStepper;
';
	attributes: ((Set new) add: #DEFERRED; add: #COPY; yourself)!

!SetRegion methodsFor: 'accessing'!

{XnRegion} asSimpleRegion

	^ self!

{ScruSet of: XnRegion} distinctions

	^ImmuSet make with: self!

{BooleanVar INLINE} isComplement
	"FALSE means that I'm a 'positive' region (see class comment).  
	TRUE means I'm a negative region."
	
	^myIsComplement!

{ImmuSet wimpy INLINE of: Position} positions
	"If I'm a positive region (see class comment and isComplement), then 
	this is a list of those positions I contain. If I'm negative, then it's 
	those positions I don't contain."

	^myPositions!

{Stepper} simpleRegions: order {OrderSpec unused default: NULL}
	"Make up a singleton set containing the whole region"

	^Stepper itemStepper: self! !

!SetRegion methodsFor: 'enumerating'!

{IntegerVar} count
	myIsComplement
		ifTrue: [Heaper BLAST: #NotEnumerable].
	^myPositions count!

{BooleanVar} isEnumerable: order {OrderSpec default: NULL}
	
	^myIsComplement not!

{Position} theOne
	self count ~~ 1 ifTrue:
		[ Heaper BLAST: #NotOneElement ].
	^ myPositions theOne cast: Position! !

!SetRegion methodsFor: 'operations'!

{XnRegion} complement

	^self makeNew: myIsComplement not with: myPositions!

{XnRegion} intersect: region {XnRegion}
	region isEmpty
		ifTrue: [ ^ region ]
		ifFalse:
			[| other {SetRegion wimpy} |
			other _ region cast: SetRegion.
			myIsComplement
				ifTrue: [other isComplement
					ifTrue: [^self makeNew: true with: (myPositions unionWith: other positions)]
					ifFalse: [^self makeNew: false with: (other positions minus: myPositions)]]
				ifFalse: [other isComplement
					ifTrue: [^self makeNew: false with: (myPositions minus: other positions)]
					ifFalse: [^self makeNew: false with: (myPositions intersect: other positions)]]]!

{XnRegion} minus: other {XnRegion}
	other isEmpty
		ifTrue: [ ^ self ]
		ifFalse:
			[| set {SetRegion wimpy} |
			set _ other cast: SetRegion.
			myIsComplement
				ifTrue: [set isComplement
					ifTrue: [^self makeNew: false with: (set positions minus: myPositions)]
					ifFalse: [^self makeNew: true with: (set positions unionWith: myPositions)]]
				ifFalse: [set isComplement
					ifTrue: [^self makeNew: false with: (set positions intersect: myPositions)]
					ifFalse: [^self makeNew: false with: (myPositions minus: set positions)]]]!

{XnRegion} simpleUnion: other {XnRegion}
	^self unionWith: other!

{XnRegion} unionWith: region {XnRegion}
	region isEmpty
		ifTrue: [ ^ self ]
		ifFalse:
			[| other {SetRegion wimpy} |
			other _ region cast: SetRegion.
			myIsComplement
				ifTrue: [other isComplement
					ifTrue: [^self makeNew: true with: (myPositions intersect: other positions)]
					ifFalse: [^self makeNew: true with: (myPositions minus: other positions)]]
				ifFalse: [other isComplement
					ifTrue: [^self makeNew: true with: (other positions minus: myPositions)]
					ifFalse: [^self makeNew: false with: (myPositions unionWith: other positions)]]]!

{XnRegion} with: pos {Position}

	myIsComplement
		ifTrue: [^self makeNew: myIsComplement with: (myPositions without: pos)]
		ifFalse: [^self makeNew: myIsComplement with: (myPositions with: pos)]!

{XnRegion} without: pos {Position}

	myIsComplement
		ifTrue: [^self makeNew: myIsComplement with: (myPositions with: pos)]
		ifFalse: [^self makeNew: myIsComplement with: (myPositions without: pos)]! !

!SetRegion methodsFor: 'testing'!

{UInt32} actualHashForEqual
	^(self getCategory hashForEqual
		bitXor: myPositions hashForEqual)
		bitXor: (myIsComplement ifTrue: [15732] ifFalse: [Int32Zero])!

{BooleanVar} hasMember: atPos {Position}
	^(myPositions hasMember: atPos) ~~ myIsComplement!

{BooleanVar} intersects: region {XnRegion}
	region isEmpty
		ifTrue: [ ^ false ]
		ifFalse:
			[| other {SetRegion wimpy} |
			other _ region cast: SetRegion.
			myIsComplement
				ifTrue: [other isComplement
					ifTrue: [^true]
					ifFalse: [^(other positions isSubsetOf: myPositions) not]]
				ifFalse: [other isComplement
					ifTrue: [^(myPositions isSubsetOf: other positions) not]
					ifFalse: [^other positions intersects: myPositions]]]!

{BooleanVar} isEmpty
	^myIsComplement not and: [myPositions isEmpty]!

{BooleanVar} isEqual: other {Heaper}

	other
		cast: SetRegion into: [:sr |
			self hack.
			^(other isKindOf: self getCategory)
			 and: [sr isComplement == myIsComplement
			 and: [sr positions isEqual: myPositions]]]
		others: [^false].
	^false "fodder"!

{BooleanVar} isFinite
	^myIsComplement not!

{BooleanVar} isFull	

	^myIsComplement and: [myPositions isEmpty]!

{BooleanVar} isSimple
	^true!

{BooleanVar} isSubsetOf: other {XnRegion}
	other isEmpty
		ifTrue: [ ^ self isEmpty ]
		ifFalse:
			[| set {SetRegion wimpy} |
			set _ other cast: SetRegion.
			myIsComplement
				ifTrue: [^set isComplement and: [set positions isSubsetOf: myPositions]]
				ifFalse: [set isComplement
					ifTrue: [^(set positions intersects: myPositions) not]
					ifFalse: [^myPositions isSubsetOf: set positions]]]! !

!SetRegion methodsFor: 'protected: creation'!

create: cmp {BooleanVar} with: set {ImmuSet of: Position}
	"the set should be for my use alone"
	super create.
	myIsComplement _ cmp.
	myPositions _ set! !

!SetRegion methodsFor: 'printing'!

{void} printOn: oo {ostream reference} 
	oo << self getCategory name.
	myIsComplement ifTrue: [oo << '~'].
	myPositions printOnWithSimpleSyntax: oo with: '{' with: ', ' with: '}'! !

!SetRegion methodsFor: 'protected: protected deferred'!

{XnRegion} makeNew: isComplement {BooleanVar} with: positions {ImmuSet of: Position}
	self subclassResponsibility! !

!SetRegion methodsFor: 'deferred accessing'!

{CoordinateSpace} coordinateSpace
	self subclassResponsibility! !

!SetRegion methodsFor: 'protected: enumerating'!

{Stepper} actualStepper: order {OrderSpec unused}

	^myPositions stepper! !

!SetRegion methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	myPositions _ receiver receiveHeaper.
	myIsComplement _ receiver receiveBooleanVar.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	xmtr sendHeaper: myPositions.
	xmtr sendBooleanVar: myIsComplement.! !