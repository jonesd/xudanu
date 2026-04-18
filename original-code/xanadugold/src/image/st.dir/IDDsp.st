'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:02:30 pm'!

IdentityDsp subclass: #IDDsp
	instanceVariableNames: 'mySpace {IDSpace}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Spaces-Unordered'!
IDDsp comment:
'There are no non-trivial Dsps on IDs.'!

(IDDsp getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #PSEUDO.COPY; yourself)!

!IDDsp methodsFor: 'accessing'!

{CoordinateSpace} coordinateSpace

	^mySpace! !

!IDDsp methodsFor: 'creation'!

create
	super create!

create: space {IDSpace}

	super create.
	mySpace := space.! !

!IDDsp methodsFor: 'generated:'!

{void} sendSelfTo: xmtr {Xmtr}! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

IDDsp class
	instanceVariableNames: ''!

(IDDsp getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #PSEUDO.COPY; yourself)!

!IDDsp class methodsFor: 'rcvr pseudo constructors'!

{Heaper} make.Rcvr: rcvr {Rcvr}
	(rcvr cast: SpecialistRcvr) registerIbid: theDsp.
	^theDsp! !

!IDDsp class methodsFor: 'pseudo constructors'!

make: space {IDSpace}

	^self create: space! !

!IDDsp class methodsFor: 'smalltalk: passe'!

make
	self passe.
	^theDsp cast: IDDsp! !