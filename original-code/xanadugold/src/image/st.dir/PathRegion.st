'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:02:22 pm'!

XnRegion subclass: #PathRegion
	instanceVariableNames: 'myPath {ImmuTable of: XnRegion}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Spaces-Paths'!
PathRegion comment:
'A PathRegion represents regions that may lie in various nested sub-documents of a containing document. The keySpace is the coordinate space of the outer document. At any key in that space, there can be a region in the sub-document. Different sub-documents can have different kinds of regions, and some of them may be PathRegions referring to regions in sub-sub-documents.

PathRegions are used to indicate what part of a document has been informed when a Sensor is triggered.'!

(PathRegion getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #COPY; yourself)!

!PathRegion methodsFor: 'create'!

create: path {ImmuTable of: XnRegion}
	super create.
	myPath _ path! !

!PathRegion methodsFor: 'enumerating'!

{IntegerVar} count
	| result {IntegerVar} |
	result _ IntegerVar0.
	myPath stepper forEach: [ :sub {XnRegion} |
		result _ result + sub count].
	^result!

{ScruSet of: XnRegion} distinctions

	self isFull
		ifTrue: [^ImmuSet make]
		ifFalse: [^ImmuSet make with: self]!

{Stepper} simpleRegions: order {OrderSpec unused default: NULL}

	self isEmpty
		ifTrue: [^ImmuSet make stepper]
		ifFalse: [^(ImmuSet make with: self) stepper]!

{Stepper} stepper: order {OrderSpec unused default: NULL}
	self unimplemented.
	^NULL! !

!PathRegion methodsFor: 'testing'!

{UInt32} hashForEqual
	^myPath hashForEqual!

{BooleanVar} hasMember: pos {Position}
	| path {PathPosition} sub {XnRegion} |
	path _ pos cast: PathPosition.
	sub _ (myPath fetch: path key) cast: XnRegion.
	sub == NULL ifTrue: [^false].
	^sub hasMember: path subKey!

{BooleanVar} intersects: region {XnRegion}
	| other {PathRegion} |
	other _ region cast: PathRegion.
	(self keys intersect: other keys) stepper forEach: [ :key {Position} |
		((self getSubRegion: key) intersects: (other getSubRegion: key))
			ifTrue: [^true]].
	^false!

{BooleanVar} isEmpty
	^myPath isEmpty!

{BooleanVar} isEqual: other {Heaper}

	other
		cast: PathRegion into: [:pr |
			^pr path isEqual: myPath]
		others: [^false]!

{BooleanVar} isFinite
	^false!

{BooleanVar} isSimple
	^true!

{BooleanVar} isSubsetOf: region {XnRegion}
	| other {PathRegion} |
	other _ region cast: PathRegion.
	(self keys isSubsetOf: other keys) ifFalse: [^false].
	self keys stepper forEach: [ :key {Position} |
		((self getSubRegion: key) isSubsetOf: (other getSubRegion: key))
			ifFalse: [^false]].
	^true! !

!PathRegion methodsFor: 'operations'!

{XnRegion} complement

	self unimplemented.
	^NULL!

{XnRegion} intersect: region {XnRegion}
	| result {MuTable of: XnRegion} other {PathRegion} |
	result _ MuTable make: myPath coordinateSpace.
	other _ region cast: PathRegion.
	(self keys intersect: other keys) stepper forEach: [ :key {Position} |
		result at: key store: ((self getSubRegion: key) intersect: (other getSubRegion: key))].
	^PathRegion make: result asImmuTable!

{XnRegion} minus: region {XnRegion}
	| other {PathRegion} result {MuTable of: XnRegion} loop {TableStepper} |
	other _ region cast: PathRegion.
	result _ MuTable make: myPath coordinateSpace.
	(loop _ myPath stepper) forEach: [ :mySub {XnRegion} | | sub {XnRegion} |
		sub _ other fetchSubRegion: loop position.
		sub == NULL
			ifTrue: [sub _ mySub]
			ifFalse: [sub _ mySub minus: sub].
		sub isEmpty ifFalse:
			[result at: loop position store: sub]].
	^PathRegion make: result asImmuTable!

{XnRegion} simpleUnion: other {XnRegion}
	^self unionWith: other!

{XnRegion} unionWith: region {XnRegion}
	| result {MuTable of: XnRegion} other {PathRegion} |
	result _ MuTable make: myPath coordinateSpace.
	other _ region cast: PathRegion.
	(self keys unionWith: other keys) stepper forEach:
		[ :key {Position} | | sub {XnRegion} sub2 {XnRegion} |
		sub _ self fetchSubRegion: key.
		sub2 _ other fetchSubRegion: key.
		sub == NULL
			ifTrue: [sub _ sub2]
			ifFalse:  [sub2 ~~ NULL
				ifTrue: [sub _ sub unionWith: sub2]].
		result at: key store: sub].
	^PathRegion make: result asImmuTable! !

!PathRegion methodsFor: 'accessing'!

{CoordinateSpace} coordinateSpace
	^PathSpace make: myPath coordinateSpace!

{XnRegion} fetchSubRegion: key {Position}
	^(myPath fetch: key) cast: XnRegion!

{XnRegion} getSubRegion: key {Position}
	^(myPath get: key) cast: XnRegion!

{XnRegion} keys
	^myPath domain!

{XnRegion} keysTransformedBy: dsp {Dsp}
	"transform the keys by the dsp"
	| result {MuTable of: XnRegion} loop {TableStepper} |
	result _ MuTable make: myPath coordinateSpace.
	(loop _ myPath stepper) forEach: [ :sub {XnRegion} |
		result at: (dsp of: loop position) introduce: sub].
	^PathRegion make: result asImmuTable!

{ImmuTable of: XnRegion} path
	^myPath! !

!PathRegion methodsFor: 'printing'!

{void} printOn: oo {ostream reference}
	oo << self getCategory name.
	myPath printOnWithSyntax: oo with: '[' with: '->' with: ', ' with: ']'! !

!PathRegion methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	myPath _ receiver receiveHeaper.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	xmtr sendHeaper: myPath.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

PathRegion class
	instanceVariableNames: ''!

(PathRegion getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #COPY; yourself)!

!PathRegion class methodsFor: 'smalltalk: defaults'!

{XnRegion} singlePathRegion: table {ScruTable of: Position}
	with: inner {XnRegion}
	^self singlePathRegion: table with: inner with: NULL! !

!PathRegion class methodsFor: 'pseudo constructors'!

make: path {ImmuTable of: XnRegion}
	^PathRegion create: path!

make: keys {XnRegion} with: sub {XnRegion}
	| result {MuTable of: XnRegion} |
	result _ MuTable make: keys coordinateSpace.
	keys stepper forEach: [ :key {Position} |
		result at: key store: sub].
	^PathRegion create: result asImmuTable!

{PathRegion} singlePathRegion: table {ScruTable of: Position}
	with: inner {PathRegion}
	with: order {OrderSpec default: NULL}
	"Makes a path region each level of which is a single position from the table, taken in the specified order. The innermost region is the given inner region."
	
	^self internalSinglePathRegion: (table stepper: order) with: inner! !

!PathRegion class methodsFor: 'private:'!

{PathRegion} internalSinglePathRegion: keys {Stepper of: Position}
	with: inner {PathRegion}
	"Makes a path region each level of which is a single position from the stepper. The innermost region is the given inner region."
	
	| key {Position} result {MuTable} |
	key := keys fetch cast: Position.
	key == NULL ifTrue: [^inner].
	keys step.
	result := MuTable make: key coordinateSpace.
	result at: key store: (self internalSinglePathRegion: keys with: inner).
	^self create: result asImmuTable! !