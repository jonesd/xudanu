'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:02:56 pm'!

XnDependent subclass: #XnSensor
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-waldo'!
XnSensor comment:
'A Sensor is a mechanism for responding to asynchronous events. The client creates a Sensor object and passes it in to the server to wait for some event, such as a recorder being triggered or a document being released. When the event takes place, the sensor will be sent the "ring" message. The argument to the ring contains additional information about the event. Each access point for placing a Sensor will specify what sort of information will be passed to the Sensor when it is activated. The ring message is "NOWAIT" which means that the server does not wait for the method to complete; it simply starts it up and continues processing. This prevents the server from waiting for time-consuming (or non-terminating) Sensor processing procedures.'!

(XnSensor getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #BY.PROXY; add: #EQ; add: #DEFERRED; yourself)!

!XnSensor methodsFor: 'ringing'!

{void PROXY} ring: a {Heaper}
	"This method will be called by the server when the event this sensor was waiting for takes place. It may be called more than once. The argument contains information about the event; the actual contents depends on the context in which the sensor was placed."
	
	self subclassResponsibility! !

!XnSensor methodsFor: 'generated:'!

actualHashForEqual ^self asOop!

isEqual: other ^self == other! !