'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:02:29 pm'!

IdentityDsp subclass: #HeaperDsp
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Spaces-Unordered'!

(HeaperDsp getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #PSEUDO.COPY; add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!HeaperDsp methodsFor: 'accessing'!

{CoordinateSpace} coordinateSpace

	^HeaperSpace make! !

!HeaperDsp methodsFor: 'creation'!

create
	super create! !

!HeaperDsp methodsFor: 'generated:'!

{void} sendSelfTo: xmtr {Xmtr}! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

HeaperDsp class
	instanceVariableNames: ''!

(HeaperDsp getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #PSEUDO.COPY; add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!HeaperDsp class methodsFor: 'pseudo constructors'!

{Dsp} make 
	^(theDsp basicCast: IdentityDsp) basicCast: HeaperDsp!

{Heaper} make.Rcvr: rcvr {Rcvr}
	(rcvr cast: SpecialistRcvr) registerIbid: theDsp.
	^theDsp! !