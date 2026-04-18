'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:01:53 pm'!

CoordinateSpace subclass: #BasicSpace
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Spaces-Basic'!
BasicSpace comment:
'BasicSpace versus CoordinateSpace is not a type distinction in that there is no difference in contract with the client.  BasicSpace exists as a convenience to the definer of new CoordinateSpaces.  A new subclass of CoordinateSpace should be a subclass of BasicSpace iff there is only one coordinateSpace that corresponds to the new class.  I.e., that the instances are not parameterized to yield different coordinate spaces.  BasicSpace provides some conveniences (especially in Smalltalk) for defining a single canonical instance at dynamic initialization time, and always using it.
	
	As this class is irrelevent to CoordinateSpace clients, but is useful to those defining other kinds of coordinate spaces, it is an exellent example of something that would be classified as a "protected" class--something to be persued if we try to make modules more like classes.'!

(BasicSpace getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #OBSOLETE; add: #SMALLTALK.ONLY; add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!BasicSpace methodsFor: 'testing'!

{UInt32} actualHashForEqual
	"is equal to any basic space on the same category of positions"

	^self getCategory hashForEqual + 1!

{BooleanVar} isEqual: anObject {Heaper}
	"is equal to any basic space on the same category of positions"

	^anObject getCategory == self getCategory! !

!BasicSpace methodsFor: 'creation'!

create: emptyRegion {XnRegion}
	with: fullRegion {XnRegion}
	with: identityDsp {Dsp}
	with: ascending {OrderSpec default: NULL}
	with: descending {OrderSpec default: NULL}
	
	super create: emptyRegion with: fullRegion with: identityDsp with: ascending with: descending.! !

!BasicSpace methodsFor: 'smalltalk: defaults'!

create: emptyRegion {XnRegion}
	with: fullRegion {XnRegion}
	with: identityDsp {Dsp}
	
	self create: emptyRegion with: fullRegion with: identityDsp with: NULL with: NULL!

create: emptyRegion {XnRegion}
	with: fullRegion {XnRegion}
	with: identityDsp {Dsp}
	with: ascending {OrderSpec default: NULL}
	
	self create: emptyRegion with: fullRegion with: identityDsp with: ascending with: NULL! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

BasicSpace class
	instanceVariableNames: 'theSpace {BasicSpace star} '!

(BasicSpace getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #OBSOLETE; add: #SMALLTALK.ONLY; add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!BasicSpace class methodsFor: 'smalltalk: initialization'!

initTimeInherited

	self REQUIRES: PrimSpec.
	theSpace _ (self new.AllocType: #PERSISTENT) create.!

linkTimeInherited

	theSpace _ NULL.!

suppressInitTimeInherited!

suppressLinkTimeInherited! !