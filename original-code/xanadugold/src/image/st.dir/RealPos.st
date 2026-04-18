'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:07:53 pm'!

Position subclass: #RealPos
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-tumbler'!
RealPos comment:
'Represents some real number exactly.  Not all real numbers can be exactly represented.  See class comment in RealSpace.'!

(RealPos getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #ON.CLIENT; add: #DEFERRED; add: #COPY; yourself)!

!RealPos methodsFor: 'accessing'!

{XnRegion} asRegion

	^RealRegion make: false
		with: (PrimSpec pointer
			arrayWithTwo: (BeforeReal make: self)
			with: (AfterReal make: self))!

{CoordinateSpace INLINE} coordinateSpace

	^RealSpace make!

{PrimFloatValue CLIENT} value
	"Essential. Return the number as a PrimFloat object from which you can get it in a variety of representations."
	
	self subclassResponsibility! !

!RealPos methodsFor: 'testing'!

{UInt32} actualHashForEqual
	
	[^self asIEEE64 basicCast: UInt32] translateOnly.
	
	[^self asIEEE64 truncated] smalltalkOnly!

{BooleanVar} isEqual: other {Heaper} 

	
	MarkM thingToDo. "128 bit values"
	other
		cast: RealPos into: [:r |
			^self asIEEE64 = r asIEEE64]
		others: [^false].
	^false "fodder"!

{BooleanVar} isGE: other {Position}

	^self asIEEE64 >= (other cast: RealPos) asIEEE64! !

!RealPos methodsFor: 'smalltalk: passe'!

{IntegerVar} exponent

	self passe!

{BooleanVar} isIEEE
	"Whether the real number that this object represents is exactly representable in an available IEEE precision.  Currently the answer is always TRUE, and the available precisions are 8 (stupid precision), 32 (single precision), and 64 (double precision).  If the answer is FALSE, the meaning of the messages 'precision' and 'asIEEE' remain to be defined."
	self passe.
	^true!

{IntegerVar} mantissa
	"This number represents exactly this->mantissa() * 2 ^ this->exponent().  Should we eventually support real numbers which cannot be expressed exactly with integral mantissa and exponent, then this message (and 'exponent') will BLAST for such numbers."

	self passe! !

!RealPos methodsFor: 'obsolete:'!

{IEEE64} asIEEE
	"Returns the value as IEEE basic data type is big enough to hold any value which can be put into an XuReal.  Currently this is an IEEE64 (double precision).  In future releases of this API, the return type of this method may be changed to IEEE128 (quad precision).  Once we support other ways of representing real numbers, there may not be an all-inclusive IEEE type, in which case this message will BLAST.
	
	The only IEEE values which this will return are those that represent real numbers.  I.e., no NANs, no inifinities, no negative zero."
	
	self subclassResponsibility!

{IEEE64} asIEEE64
	"Returns the value as IEEE64 (double precision).
	The only IEEE values which this will return are those that represent real numbers.  I.e., no NANs, no inifinities, no negative zero."
	
	self subclassResponsibility!

{Int32} precision
	"What precision is it, in terms of the number of bits used to represent it.  In the interests of efficiency, this may return a number larger than that *needed* to represent it.  However, the precision reported must be at least that needed to represent this number.  It is assumed that the format of the number satisfies the IEEE radix independent floating point spec.  Should we represent real numbers other that those representable in IEEE, the meaning of this message will be more fully specified.
	
	The fact that this message is allowed to overestimate precision doesn't interfere with equality: a->isEqual(b) exactly when they represent that same real number, even if one of them happens to overestimate precision more that the other."
	
	MarkM thingToDo. "retire this"
	self subclassResponsibility! !

!RealPos methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

RealPos class
	instanceVariableNames: ''!

(RealPos getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #ON.CLIENT; add: #DEFERRED; add: #COPY; yourself)!

!RealPos class methodsFor: 'creation'!

{RealPos INLINE} make: value {IEEE64}
	"make an XuReal given an IEEE floating point number of whatever precision on this platform is able to hold all the real numbers currently representable by an XuReal.  Currently this is IEEE64 (double precision), but may be redeclared as a larger IEEE precision in the future.  See comment in XuReal::makeIEEE64"

	^self makeIEEE64: value!

{RealPos} makeIEEE32: value {IEEE32}
	"See comment in XuReal::makeIEEE64"

	self knownBug. "must ensure that it is a number, and convert -0 to +0"
	self thingToDo. "perhaps we should check to see if a lower precision can hold it exactly, and delegate to XuIEEE8.  Nahh."
	
	^IEEE32Pos create: value!

{RealPos} makeIEEE64: value {IEEE64}
	"Returns an XuReal which exactly represents the same real number that is represented by 'value'.  BLASTs if value doesn't represent a real (i.e., no NANs or inifinities).  Negative 0 will be silently converted to positive zero"

	self knownBug. "must ensure that it is a number, and convert -0 to +0"
	self thingToDo. "perhaps we should check to see if a lower precision can hold it exactly, and delegate to XuIEEE32 or XuIEEE8.  Nahh."
	
	^IEEE64Pos create: value!

{RealPos} makeIEEE8: value {IEEE8}
	"See comment in XuReal::makeIEEE64"

	self knownBug. "must ensure that it is a number, and convert -0 to +0"
	
	^IEEE8Pos create: value! !

!RealPos class methodsFor: 'smalltalk: system'!

info.stProtocol
"{PrimFloat CLIENT} value
"! !

!RealPos class methodsFor: 'smalltalk: promise'!

exportName
	^'Real'! !