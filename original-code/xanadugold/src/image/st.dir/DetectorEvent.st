'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:08:11 pm'!

Heaper subclass: #DetectorEvent
	instanceVariableNames: '
		myNext {DetectorEvent}
		myDetector {IntegerVar}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-proman'!
DetectorEvent comment:
'The detectors for comm create these and queue them up because they can only go out between requests.'!

(DetectorEvent getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #DEFERRED; yourself)!

!DetectorEvent methodsFor: 'accessing'!

{IntegerVar} detector
	^myDetector!

{DetectorEvent} next
	^myNext!

{void} setNext: event {DetectorEvent}
	myNext _ event! !

!DetectorEvent methodsFor: 'triggering'!

{void} trigger: pm {PromiseManager}
	"Send the message across the wire."
	
	self subclassResponsibility! !

!DetectorEvent methodsFor: 'creation'!

create: detector {IntegerVar}
	super create.
	myDetector _ detector.
	myNext _ NULL! !