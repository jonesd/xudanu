'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:07:08 pm'!

Tester subclass: #VolumeTester
	instanceVariableNames: 'myConnection {Connection NOCOPY}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-nkernel'!

(VolumeTester getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #(COPY boot ); add: #SMALLTALK.ONLY; yourself)!

!VolumeTester methodsFor: 'testing'!

{void} allTestsOn: oo {ostream reference} 
	| server file protoArray count chunk result  stepper |
	Dean shouldImplement. "bring this up to date"
	
	myConnection := Connection make: FeServer.
	server _ myConnection bootHeaper.
	
	protoArray _ UInt8Array basicNew.
	file _ (Filename named: 'base.cha') readStream.
	result _ FeEdition empty: IntegerSpace make.
	
	[count _ 0.
	chunk _ 41000.
	50 timesRepeat:
		[| data {UInt8Array} |
		oo << count << '
'.
		data _ file next: chunk.
		data changeClassToThatOf: protoArray.
		result _ result combine: 
			((server newEdition: data) transformedBy: (IntegerMapping make: count)).
		count _ count + chunk].
	result domain.
	stepper _ RandomStepper make: 389.
	
	120 timesRepeat: 
		[| start {IntegerVar} stop {IntegerVar} region {XnRegion} |
		start _ stepper value \\ count.
		stepper step.
		stop _ stepper value \\ count.
		stepper step.
		region _ IntegerRegion make: start with: stop.
		oo << region << '
'.
		result copy: region].
	
	200 timesRepeat: 
		[| start {IntegerVar} stop {IntegerVar} region {XnRegion} |
		start _ stepper value \\ count.
		stepper step.
		stop _ stepper value \\ 30000.
		stop > count ifTrue: [stop _ count].
		stepper step.
		region _ IntegerRegion make: start with: stop.
		oo << region << '
'.
		result retrieve: region with: NULL]]
	valueNowOrOnUnwindDo: [file close]! !

!VolumeTester methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.! !