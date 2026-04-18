'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:02:30 pm'!

Dsp subclass: #IdentityDsp
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Spaces-Unordered'!
IdentityDsp comment:
'An implementation sharing convenience for Dsp classes which only provide the identity mapping functionality for their coordinate spaces.  This provides everything except the coordinate space itself (which must be provided by the subclass).  Will eventually be declared NOT_A_TYPE, so don''t use it in type declarations.  
	
	Assumes that if a given space uses it as its identity Dsp, then the one cached instance will be the only identity Dsp for that space.  I.e., I do equality comparison as an EQ object.  If this assumpsion isn''t true, please override isEqual and hashForEqual.  See PathDsp.
	
	IdentityDsp is in module "unorder" because typically unordered spaces will only have an identity Dsp and so want to subclass this class.  Non-unordered spaces should also feel free to use this as appropriate.'!

(IdentityDsp getOrMakeCxxClassDescription)
	friends:
'/* friends for class IdentityDsp */
friend SPTR(Dsp) dsp(CoordinateSpace*);
friend SPTR(Dsp) dsp(IntegerVar);';
	attributes: ((Set new) add: #NOT.A.TYPE; add: #DEFERRED; yourself)!

!IdentityDsp methodsFor: 'creation'!

create
	super create! !

!IdentityDsp methodsFor: 'transforming'!

{Position} inverseOf: pos {Position}

	^pos!

{XnRegion} inverseOfAll: reg {XnRegion}

	^reg!

{Position} of: pos {Position}

	^pos!

{XnRegion} ofAll: reg {XnRegion}

	^reg! !

!IdentityDsp methodsFor: 'combining'!

{Dsp} compose: other {Dsp}

	^ other!

{Mapping} inverse

	^ self!

{Dsp} inverseCompose: other {Dsp}

	^ other!

{Dsp} minus: other {Dsp}

	^other inverse cast: Dsp! !

!IdentityDsp methodsFor: 'printing'!

{void} printOn: oo {ostream reference}

	oo << self getCategory name << '(' << self coordinateSpace << ')'! !

!IdentityDsp methodsFor: 'accessing'!

{BooleanVar} isIdentity
	^ true! !

!IdentityDsp methodsFor: 'deferred accessing'!

{CoordinateSpace} coordinateSpace

	self subclassResponsibility! !

!IdentityDsp methodsFor: 'testing'!

{UInt32} actualHashForEqual
	^Heaper takeOop!

{BooleanVar} isEqual: other {Heaper}
	^self == other! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

IdentityDsp class
	instanceVariableNames: 'theDsp {IdentityDsp star} '!

(IdentityDsp getOrMakeCxxClassDescription)
	friends:
'/* friends for class IdentityDsp */
friend SPTR(Dsp) dsp(CoordinateSpace*);
friend SPTR(Dsp) dsp(IntegerVar);';
	attributes: ((Set new) add: #NOT.A.TYPE; add: #DEFERRED; yourself)!

!IdentityDsp class methodsFor: 'smalltalk: smalltalk initialization'!

initTimeInherited

	theDsp _ (self new.AllocType: #PERSISTENT) create.!

linkTimeInherited

	theDsp _ NULL.!

suppressInitTimeInherited!

suppressLinkTimeInherited! !