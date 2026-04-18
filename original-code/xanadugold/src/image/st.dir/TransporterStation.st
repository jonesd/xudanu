'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:05:39 pm'!

Station subclass: #TransporterStation
	instanceVariableNames: '
		myXcvrMaker {XcvrMaker}
		myTransporter {Transporter}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Xcvr'!

(TransporterStation getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!TransporterStation methodsFor: 'xcvr creation'!

{SpecialistRcvr} makeRcvr: specialist {TransferSpecialist}

	^myXcvrMaker makeRcvr: specialist with: myTransporter readStream!

{SpecialistXmtr} makeXmtr: specialist {TransferSpecialist}

	^myXcvrMaker makeXmtr: specialist with: myTransporter writeStream! !

!TransporterStation methodsFor: 'creation'!

create: tport {Transporter} with: maker {XcvrMaker}
	super create.
	myTransporter _ tport.
	myXcvrMaker _ maker! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

TransporterStation class
	instanceVariableNames: ''!

(TransporterStation getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!TransporterStation class methodsFor: 'creation'!

{Station} make: tport {Transporter} with: maker {XcvrMaker}
	^self create: tport with: maker! !