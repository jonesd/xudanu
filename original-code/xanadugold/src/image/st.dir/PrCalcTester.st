'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:05:51 pm'!

Tester subclass: #PrCalcTester
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-calc'!

(PrCalcTester getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #(COPY boot ); yourself)!

!PrCalcTester methodsFor: 'testing'!

{void} allTestsOn: oo {ostream reference}
	"FeCalcTester runTest"
	
	self test1On: oo.
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

{void} printTop: calc {PrCalc} with: oo {ostream reference}

	| rat {PrRational} |
	rat := calc pop.
	calc push: rat.
	oo << 'calc''s top == (' << rat numerator value << '/' << rat denominator value  << '
'.!

{void} test1On: oo {ostream reference}

	| cc {XuCalcCreator}
	  calc {XuCalc}
	  sensor {FePopSensor}
	  rat34 {XuRational}
	  rat45 {XuRational} 
	  result {XuRational} |

	cc _ XuCalcCreator make: (FeCalcCreator make).
	calc _ cc newCalc.
	cc _ NULL.
	[sensor _ FePopSensor make: oo] smalltalkOnly.
	'sensor = FePopSensor::make (&oo);' translateOnly.

	rat34 _ XuRational make: (FeRational make: 3 with: 4).
	rat45 _ XuRational make: (FeRational make: 4 with: 5).


	
	calc push: rat34.
	calc plantPopSensor: sensor.

	self boobyPop: calc with: oo.
		
	calc plantPopSensor: sensor.
	calc push: rat34.
	calc push: rat34.
	calc push: rat45.
	calc times.
	result := calc pop.
	oo << 'calc->pop () == (' << result numerator value << '/' << result denominator value << ')
'.
	calc push: rat34.
	calc timesArg: rat45.
	result := calc pop.
	oo << 'calc->pop () == (' << result numerator value << '/' << result denominator value << ')
'.	
	self boobyPop: calc with: oo.
	self boobyPop: calc with: oo.

	PrCalcTester problems.StackOverflow delayTry: [
		oo << 'In outer delay block.
'.
		PrCalcTester problems.StackUnderflow delayTry: [
			calc pop.
			calc push: rat34.
			calc push: rat45.
			calc times.
			result := calc pop.
			oo << 'result calculated inside inner delay block.
'.
			21 timesRepeat: [calc push: rat45].]
		catch: [:prom |
			oo << 'delayTry: #StackUnderflow with:catch: caught ' <<  prom problemName << '
'].
		oo << 'In outer block again.
'.]
	catch: [:prom |
		oo << 'delayTry: #StackOverflow with:catch: caught ' <<  prom problemName << '
'].
	oo << 'calc->pop () == (' << result numerator value << '/' << result denominator value << ')
'.
	20 timesRepeat: [calc pop].
	self boobyPop: calc with: oo.
	self boobyPop: calc with: oo.

	20 timesRepeat: [calc push: rat45].
	
	self boobyPush: calc with: oo with: rat45.
"	result := calc pop.	
	oo << 'calc->pop () == (' << result numerator value << '/' << result denominator value << ')
'."
	20 timesRepeat: [calc pop].
	self boobyPop: calc with: oo.

	
	
"	calc destroy."!

{void} test2On: oo {ostream reference}

	| cc {XuCalcCreator}
	  calc {XuCalc}
	  rat23 {XuRational}
	  rat34 {XuRational}
	  rat45 {XuRational} 
	  generic {XuPromise} |

	cc _ XuCalcCreator make: (FeCalcCreator make).
	calc _ cc newCalc.
	cc _ NULL.

	rat23 _ XuRational make: (FeRational make: 2 with: 3).
	rat34 _ XuRational make: (FeRational make: 3 with: 4).
	rat45 _ XuRational make: (FeRational make: 4 with: 5).

	calc push: rat45.
	XuCurrentRat fluidBind: rat23 during:
		[calc timesCurrent.
		self printTop: calc with: oo.
		calc push: XuCurrentRat fluidGet.
		calc times.
		self printTop: calc with: oo.
		XuCurrentRat fluidBind: rat34 during:
			[calc timesCurrent.
			self printTop: calc with: oo.
			calc push: XuCurrentRat fluidGet.
			calc times.
			self printTop: calc with: oo.].
		calc timesCurrent.
		self printTop: calc with: oo.
		calc push: XuCurrentRat fluidGet.
		calc times.
		self printTop: calc with: oo.
		generic _ XuCurrentRat fluidGet asHeaper.
		calc push: (generic delayCast: XuRational).
		self printTop: calc with: oo.].! !

!PrCalcTester methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

PrCalcTester class
	instanceVariableNames: ''!

(PrCalcTester getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #(COPY boot ); yourself)!

!PrCalcTester class methodsFor: 'exceptions: exceptions'!

problems.StackOverflow

	^self signals: #(StackOverflow)!

problems.StackUnderflow

	^self signals: #(StackUnderflow)! !