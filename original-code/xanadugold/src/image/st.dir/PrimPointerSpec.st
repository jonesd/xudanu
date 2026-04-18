'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:03:11 pm'!

PrimSpec subclass: #PrimPointerSpec
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'X++ PrimArrays'!
PrimPointerSpec comment:
'Describes a kind of primitive pointer array'!

(PrimPointerSpec getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #(COPY xpp ); yourself)!

!PrimPointerSpec methodsFor: 'testing'!

{UInt32} actualHashForEqual

	^self getCategory hashForEqual bitXor: self arrayClass hashForEqual!

{BooleanVar} isEqual: other {Heaper}

	^(other isKindOf: PrimPointerSpec) and: [self arrayClass == (other cast: PrimPointerSpec) arrayClass]! !

!PrimPointerSpec methodsFor: 'private: making'!

{PrimArray} privateCopy: array {PrimArray}
	with: size {Int32 default: -1}
	with: start {Int32 default: Int32Zero}
	with: count {Int32 default: -1}
	with: offset {Int32 default: Int32Zero}
	"Make a copy of an array with a different representation size. The arguments are the same as in PrimArray::copy."
	

	[self == (PrimSpec pointer basicCast: Heaper star) ifTrue: [^PtrArray make: size with: array with: start with: count with: offset].
	self == (PrimSpec sharedPointer basicCast: Heaper star) ifTrue: [^SharedPtrArray make: size with: array with: start with: count with: offset].
	Heaper BLAST: #BadPrimSpec] translateOnly.
	[^myClass create: size with: start with: count with: offset] smalltalkOnly.
	^ NULL "compiler fodder"! !

!PrimPointerSpec methodsFor: 'create'!

create: primClass {Category}
	super create: primClass.! !

!PrimPointerSpec methodsFor: 'making'!

{PrimArray} array: count {Int32 default: Int32Zero}
	"Make an array initialized to null values"

	[self == (PrimSpec pointer basicCast: Heaper star) ifTrue: [^PtrArray nulls: count].
	self == (PrimSpec sharedPointer basicCast: Heaper star) ifTrue: [^SharedPtrArray make: count].
	Heaper BLAST: #BadPrimSpec] translateOnly.
	[^myClass create: count] smalltalkOnly.
	^ NULL "compiler fodder"!

{PrimArray} arrayFromBuffer: count {Int32} with: buffer {void star}
	"Make an array with the values at the given address"

	[self == (PrimSpec pointer basicCast: Heaper star) ifTrue: [^PtrArray make: count with: buffer].
	self == (PrimSpec sharedPointer basicCast: Heaper star) ifTrue: [^SharedPtrArray make: count with: buffer].
	Heaper BLAST: #BadPrimSpec] translateOnly.
	[^myClass create: count with: buffer] smalltalkOnly.
	^ NULL "compiler fodder"! !

!PrimPointerSpec methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.! !