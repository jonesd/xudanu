'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:05:08 pm'!

XcvrMaker subclass: #Binary2XcvrMaker
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Xcvr'!

(Binary2XcvrMaker getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #COPY; add: #NOT.A.TYPE; yourself)!

!Binary2XcvrMaker methodsFor: 'xcvr creation'!

{SpecialistRcvr} makeRcvr: specialist {TransferSpecialist} with: readStream {XnReadStream}
	^Binary2Rcvr make: specialist with: readStream!

{SpecialistXmtr} makeXmtr: specialist {TransferSpecialist} with: writeStream {XnWriteStream}
	^Binary2Xmtr make: specialist with: writeStream! !

!Binary2XcvrMaker methodsFor: 'testing'!

{char star} id
	^'binary2'! !

!Binary2XcvrMaker methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

Binary2XcvrMaker class
	instanceVariableNames: ''!

(Binary2XcvrMaker getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #COPY; add: #NOT.A.TYPE; yourself)!

!Binary2XcvrMaker class methodsFor: 'creation'!

{XcvrMaker} make
	^self create! !