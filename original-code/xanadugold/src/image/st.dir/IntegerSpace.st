'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:02:18 pm'!

CoordinateSpace subclass: #IntegerSpace
	instanceVariableNames: ''
	classVariableNames: 'TheIntegerSpace {IntegerSpace} '
	poolDictionaries: ''
	category: 'Xanadu-Spaces-Integers'!
IntegerSpace comment:
'The space of all integers.  See the class comments in IntegerRegion, XuInteger, and IntegerDsp for interesting properties of this space.  Especially IntegerRegion.
	
	IntegerSpaces are the most frequently used of the coordinate spaces.  XuArrays are an efficient data structure which we provide as a table whose domain space is an integer space.  In so doing, the notion of an array is made to be simply a particular case of a table indexed by the positions of a coordinate space.  However, IntegerSpaces and XuArrays are both expected to be more efficient than other spaces and tables built on other spaces.  See XuArray'!

(IntegerSpace getOrMakeCxxClassDescription)
	friends:
'/* friends for class IntegerSpace */

friend class IntegerRegion;
friend class IntegerDsp;
';
	attributes: ((Set new) add: #PSEUDO.COPY; add: #CONCRETE; add: #ON.CLIENT; yourself)!

!IntegerSpace methodsFor: 'creation'!

create

	super create: (IntegerRegion using: false with: Int32Zero
			with: (IntegerVarArray zeros: Int32Zero))
		with: (IntegerRegion using: true with: Int32Zero
			with: (IntegerVarArray zeros: Int32Zero))
		with: IntegerMapping identity
		with: IntegerUpOrder make! !

!IntegerSpace methodsFor: 'making'!

{IntegerRegion CLIENT} above: start {IntegerPos} with: inclusive {BooleanVar}
	"Essential. Make a region that contains all integers greater than (or equal if inclusive is true) to start."
	| after {IntegerVar} |
	after _ start asIntegerVar.
	inclusive ifFalse: [after _ after + 1].
	^IntegerRegion after: after!

{IntegerRegion CLIENT} below: stop {IntegerPos} with: inclusive {BooleanVar}
	"Make a region that contains all integers less than (or equal if inclusive is true) to stop."
	| after {IntegerVar} |
	after _ stop asIntegerVar.
	inclusive ifTrue: [after _ after + 1].
	^IntegerRegion before: after!

{IntegerRegion CLIENT} interval: start {IntegerPos} with: stop {IntegerPos}
	"Make a region that contains all integers greater than or equal to start and less than stop."
	
	^IntegerRegion make: start asIntegerVar with: stop asIntegerVar!

{IntegerPos CLIENT INLINE} position: value {IntegerVar}
	"Essential. Make an integer Position object"
	
	^value integer!

{IntegerMapping CLIENT} translation: value {IntegerVar}
	"Essential. Make a Mapping which adds a fixed amount to any value.
	Should this just be supplanted by CoordinateSpace::mapping ()?"
	
	value = IntegerVarZero ifTrue:
		[^self identityDsp cast: IntegerMapping].
	^IntegerMapping make: value! !

!IntegerSpace methodsFor: 'testing'!

{UInt32} actualHashForEqual
	"is equal to any basic space on the same category of positions"

	^self getCategory hashForEqual + 1!

{BooleanVar} isEqual: anObject {Heaper}
	"is equal to any basic space on the same category of positions"

	^anObject getCategory == self getCategory! !

!IntegerSpace methodsFor: 'smalltalk: passe'!

{IntegerPos} integer: value {IntegerVar}

	self passe "position"! !

!IntegerSpace methodsFor: 'generated:'!

{void} sendSelfTo: xmtr {Xmtr}! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

IntegerSpace class
	instanceVariableNames: ''!

(IntegerSpace getOrMakeCxxClassDescription)
	friends:
'/* friends for class IntegerSpace */

friend class IntegerRegion;
friend class IntegerDsp;
';
	attributes: ((Set new) add: #PSEUDO.COPY; add: #CONCRETE; add: #ON.CLIENT; yourself)!

!IntegerSpace class methodsFor: 'creation'!

{IntegerSpace INLINE} implicitReceiver
	"Get the receievr for wire requests."
	
	^TheIntegerSpace!

{IntegerSpace CLIENT INLINE} make
	"return the one integer space"
	
	^TheIntegerSpace! !

!IntegerSpace class methodsFor: 'rcvr pseudo constructor'!

{Heaper} make.Rcvr: rcvr {Rcvr}
	(rcvr cast: SpecialistRcvr) registerIbid: TheIntegerSpace.
	^TheIntegerSpace! !

!IntegerSpace class methodsFor: 'smalltalk: init'!

initTimeNonInherited

	TheIntegerSpace := self create!

linkTimeNonInherited

	TheIntegerSpace := NULL! !

!IntegerSpace class methodsFor: 'smalltalk: system'!

info.stProtocol
"{IntegerRegion CLIENT} above: start {IntegerVar} with: inclusive {BooleanVar}
{IntegerRegion CLIENT} below: start {IntegerVar} with: inclusive {BooleanVar}
{IntegerRegion CLIENT} interval: start {IntegerVar} with: stop {IntegerVar}
{XuInteger CLIENT} position: value {IntegerVar}
{IntegerMapping CLIENT} translation: value {IntegerVar}
"! !