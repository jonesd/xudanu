'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:02:21 pm'!

Dsp subclass: #PathDsp
	instanceVariableNames: 'myKeyDsp {Dsp}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Spaces-Paths'!
PathDsp comment:
'A PathDsp transforms a PathRegion by transforming the keys, using the contained Dsp.'!

(PathDsp getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #COPY; yourself)!

!PathDsp methodsFor: 'create'!

create: keyDsp {Dsp}

	super create.
	myKeyDsp := keyDsp.! !

!PathDsp methodsFor: 'accessing'!

{CoordinateSpace} coordinateSpace

	^PathSpace make: myKeyDsp coordinateSpace!

{BooleanVar} isIdentity

	^myKeyDsp isIdentity!

{Dsp} keyDsp
	"The Dsp used to transform the keys."
	
	^myKeyDsp! !

!PathDsp methodsFor: 'testing'!

{UInt32} hashForEqual

	^myKeyDsp hashForEqual bitXor: #cat.U.PathDsp hashForEqual!

{BooleanVar} isEqual: other {Heaper}
	"See class comment in IdentityDsp"
	
	other cast: PathDsp into: [:o {PathDsp} |
			^o isIdentity and: [o coordinateSpace isEqual: self coordinateSpace]]
		others: [^false]! !

!PathDsp methodsFor: 'transforming'!

{Position} inverseOf: pos {Position}

	| path {PathPosition} |
	path := pos cast: PathPosition.
	^PathPosition make: (myKeyDsp inverseOf: path key)
		with: path subKey!

{XnRegion} inverseOfAll: reg {XnRegion}

	^(reg cast: PathRegion) keysTransformedBy: (myKeyDsp inverse cast: Dsp)!

{Position} of: pos {Position}

	| path {PathPosition} |
	path := pos cast: PathPosition.
	^PathPosition make: (myKeyDsp of: path key)
		with: path subKey!

{XnRegion} ofAll: reg {XnRegion}

	^(reg cast: PathRegion) keysTransformedBy: myKeyDsp! !

!PathDsp methodsFor: 'combining'!

{Dsp} compose: other {Dsp}

	^PathDsp make: (myKeyDsp compose: (other cast: PathDsp) keyDsp)!

{Mapping} inverse

	^PathDsp make: (myKeyDsp inverse cast: Dsp)!

{Dsp} inverseCompose: other {Dsp}

	^PathDsp make: (myKeyDsp inverseCompose: (other cast: PathDsp) keyDsp)!

{Dsp} minus: other {Dsp}

	^PathDsp make: (myKeyDsp minus: (other cast: PathDsp) keyDsp)! !

!PathDsp methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	myKeyDsp _ receiver receiveHeaper.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	xmtr sendHeaper: myKeyDsp.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

PathDsp class
	instanceVariableNames: ''!

(PathDsp getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #COPY; yourself)!

!PathDsp class methodsFor: 'pseudo constructors'!

make: keyDsp {Dsp}

	^self create: keyDsp! !