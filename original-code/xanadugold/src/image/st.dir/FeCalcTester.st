'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:05:50 pm'!

Tester subclass: #FeCalcTester
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-calc'!

(FeCalcTester getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #(COPY boot ); yourself)!

!FeCalcTester methodsFor: 'testing'!

{void} allTestsOn: oo {ostream reference}
	"FeCalcTester runTest"
	
	"self test1On: oo."
	self test2On: oo!

{void} boobyPop: calc {FeCalc} with: oo {ostream reference}
	FeCalc problems.StackUnderflow 
		handle: [:ex |
			oo << 'Underflow caught
'.
			^VOID] 
		do: [calc pop.
			Heaper BLAST: #GRIPE].!

{void} boobyPush: calc {FeCalc} with: oo {ostream reference} with: rat {FeRational}
	FeCalc problems.StackOverflow 
		handle: [:ex |
			oo << 'Overflow caught
'.
			^VOID] 
		do: [calc push: rat.
			Heaper BLAST: #GRIPE].!

{void} printTop: calc {FeCalc} with: oo {ostream reference}

	| rat {FeRational} |
	rat := calc pop.
	calc push: rat.
	oo << 'calc''s top == (' << rat  << '
'.!

{void} test1On: oo {ostream reference}

	| cc {FeCalcCreator}
	  calc {FeCalc}
	  sensor {FePopSensor}
	  rat34 {FeRational}
	  rat45 {FeRational} |

	cc _ FeCalcCreator make.
	calc _ cc newCalc.
	cc _ NULL.
	[sensor _ FePopSensor make: oo] smalltalkOnly.
	'sensor = FePopSensor::make (&oo);' translateOnly.

	rat34 _  FeRational make: 3 with: 4.
	rat45 _  FeRational make: 4 with: 5.


	
"	calc push: rat34.
	calc plantPopSensor: (XuPopSensor make: sensor).

	self boobyPop: calc with: oo.
		
	calc plantPopSensor: sensor.
	calc push: rat34."
	calc push: rat34.
	calc push: rat45.
	calc times.
	
	oo << 'calc->pop () == (' << calc pop  << '
'.
	calc push: rat34.
	calc timesArg: rat45.
	
	
	self boobyPop: calc with: oo.
	self boobyPop: calc with: oo.

	20 timesRepeat: [calc push: rat45].
	
	self boobyPush: calc with: oo with: rat45.
	
	oo << 'calc->pop () == (' << calc pop  << '
'.
	20 timesRepeat: [calc pop].
	self boobyPop: calc with: oo.

	
	
"	calc destroy."!

{void} test2On: oo {ostream reference}

	| cc {FeCalcCreator}
	  calc {FeCalc}
	  rat23 {FeRational}
	  rat34 {FeRational}
	  rat45 {FeRational}
	  generic {Heaper} |

	cc _ FeCalcCreator make.
	calc _ cc newCalc.
	cc _ NULL.

	rat23 _  FeRational make: 2 with: 3.
	rat34 _  FeRational make: 3 with: 4.
	rat45 _  FeRational make: 4 with: 5.

	calc push: rat45.
	CurrentRat fluidBind: rat23 during:
		[calc timesCurrent.
		self printTop: calc with: oo.
		calc push: CurrentRat fluidGet.
		calc times.
		self printTop: calc with: oo.
		CurrentRat fluidBind: rat34 during:
			[calc timesCurrent.
			self printTop: calc with: oo.
			calc push: CurrentRat fluidGet.
			calc times.
			self printTop: calc with: oo.].
		calc timesCurrent.
		self printTop: calc with: oo.
		calc push: CurrentRat fluidGet.
		calc times.
		self printTop: calc with: oo.
		generic _ CurrentRat fluidGet asHeaper.
		calc push: (generic cast: FeRational).
		self printTop: calc with: oo.].! !

!FeCalcTester methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.! !