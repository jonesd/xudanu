'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:05:36 pm'!

XcvrMaker subclass: #TextyXcvrMaker
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Xcvr'!

(TextyXcvrMaker getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #COPY; add: #NOT.A.TYPE; yourself)!

!TextyXcvrMaker methodsFor: 'xcvr creation'!

{SpecialistRcvr} makeRcvr: specialist {TransferSpecialist} with: readStream {XnReadStream}

	^TextyRcvr create: specialist with: readStream!

{SpecialistXmtr} makeXmtr: specialist {TransferSpecialist} with: writeStream {XnWriteStream}

	^TextyXmtr create: specialist with: writeStream! !

!TextyXcvrMaker methodsFor: 'testing'!

{char star} id
	^'texty'! !

!TextyXcvrMaker methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

TextyXcvrMaker class
	instanceVariableNames: ''!

(TextyXcvrMaker getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #COPY; add: #NOT.A.TYPE; yourself)!

!TextyXcvrMaker class methodsFor: 'creation'!

{XcvrMaker} make
	^self create!

{Rcvr} makeReader: stream {XnReadStream}
	^TextyRcvr create: (TransferSpecialist make: (Cookbook make)) with: stream.!

{Xmtr} makeWriter: stream {XnWriteStream}
	^TextyXmtr create: (TransferSpecialist make: (Cookbook make)) with: stream.! !