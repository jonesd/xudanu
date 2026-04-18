'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:07:54 pm'!

CoordinateSpace subclass: #RealSpace
	instanceVariableNames: ''
	classVariableNames: 'TheRealSpace {RealSpace} '
	poolDictionaries: ''
	category: 'Xanadu-tumbler'!
RealSpace comment:
'Non-arithmetic space of real numbers in which only certain positions are explicitly representable.  In this release, the only exactly representable numbers are those real numbers which can be represented in IEEE64 (double precision) format.  Future releases may make more real numbers representable.'!

(RealSpace getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #PSEUDO.COPY; add: #CONCRETE; add: #ON.CLIENT; yourself)!

!RealSpace methodsFor: 'create'!

create
	
	super create: (RealRegion make: false with: PtrArray empty)
		with: (RealRegion make: true with: PtrArray empty)
		with: RealDsp make
		with: RealUpOrder make! !

!RealSpace methodsFor: 'making'!

{RealRegion CLIENT} above: val {RealPos} with: inclusive {BooleanVar}
	"The region consisting of all positions >= val if inclusive, or all > val if not inclusive."

	inclusive ifTrue:
		[^RealRegion make: false
			with: (PrimSpec pointer arrayWith: (BeforeReal make: val))]
	ifFalse:
		[^RealRegion make: false
			with: (PrimSpec pointer arrayWith: (AfterReal make: val))]!

{RealRegion CLIENT} below: val {RealPos} with: inclusive {BooleanVar}
	"The region consisting of all positions <= val if inclusive, or all < val if not inclusive."

	inclusive ifTrue:
		[^RealRegion make: true
			with: (PrimSpec pointer arrayWith: (AfterReal make: val))]
	ifFalse:
		[^RealRegion make: true
			with: (PrimSpec pointer arrayWith: (BeforeReal make: val))]!

{RealRegion CLIENT} interval: start {RealPos} with: stop {RealPos}
	"Return a region of all numbers >= lower and < upper."
	
	MarkM thingToDo. "use a single constructor"
	^((self above: start with: true) intersect: (self below: stop with: false)) cast: RealRegion!

{RealPos CLIENT INLINE} position: val {IEEE64}
	"The XuReal representing the same real number as that exactly represented by 'val'.  If 'val' doesn't represent a real number (i.e., it is an infinity or a NAN), then this message BLASTs.  If 'val' is a negative zero, it is silently converted to a positive zero"
	
	^RealPos make: val! !

!RealSpace methodsFor: 'obsolete:'!

{RealRegion} after: val {IEEE64}
	"The region consisting of all position >= val.
	Should this just be supplanted by CoordinateSpace::region ()?"

	self thingToDo. "update clients"
	^RealRegion make: false
		with: (PrimSpec pointer arrayWith: (BeforeReal make: (RealPos make: val)))!

{RealRegion} before: val {IEEE64}
	"The region consisting of all position <= val
	Should this just be supplanted by CoordinateSpace::region ()?"

	self thingToDo. "update clients"
	^RealRegion make: true
		with: (PrimSpec pointer arrayWith: (AfterReal make: (RealPos make: val)))!

{RealRegion} strictlyAfter: val {IEEE64}
	"The region consisting of all position > val
	Should this just be supplanted by CoordinateSpace::region ()?
	Add Boolean to after to say whether its inclusive?"

	self thingToDo. "update clients"
	^RealRegion make: false
		with: (PrimSpec pointer arrayWith: (AfterReal make: (RealPos make: val)))!

{RealRegion} strictlyBefore: val {IEEE64}
	"The region consisting of all position < val
	Should this just be supplanted by CoordinateSpace::region ()?
	Add Boolean to before to say whether its inclusive?"

	self thingToDo. "update clients"
	^RealRegion make: true
		with: (PrimSpec pointer arrayWith: (AfterReal make: (RealPos make: val)))! !

!RealSpace methodsFor: 'testing'!

{UInt32} actualHashForEqual
	"is equal to any basic space on the same category of positions"

	^self getCategory hashForEqual + 1!

{BooleanVar} isEqual: anObject {Heaper}
	"is equal to any basic space on the same category of positions"

	^anObject getCategory == self getCategory! !

!RealSpace methodsFor: 'generated:'!

{void} sendSelfTo: xmtr {Xmtr}! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

RealSpace class
	instanceVariableNames: ''!

(RealSpace getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #PSEUDO.COPY; add: #CONCRETE; add: #ON.CLIENT; yourself)!

!RealSpace class methodsFor: 'creation'!

{RealSpace CLIENT INLINE} make

	^TheRealSpace! !

!RealSpace class methodsFor: 'rcvr pseudo constructors'!

{Heaper} make.Rcvr: rcvr {Rcvr}
	(rcvr cast: SpecialistRcvr) registerIbid: TheRealSpace.
	^TheRealSpace! !

!RealSpace class methodsFor: 'smalltalk: init'!

initTimeNonInherited

	self REQUIRES: PrimSpec.
	TheRealSpace := self create!

linkTimeNonInherited

	TheRealSpace := NULL! !

!RealSpace class methodsFor: 'smalltalk: system'!

info.stProtocol
"{RealRegion CLIENT} above: val {IEEE64} with: inclusive {BooleanVar}
{RealRegion CLIENT} below: val {IEEE64} with: inclusive {BooleanVar}
{RealRegion CLIENT} interval: lower {XuRegion} with: upper {XuReal}
{XuReal CLIENT} position: val {IEEE64}
"! !