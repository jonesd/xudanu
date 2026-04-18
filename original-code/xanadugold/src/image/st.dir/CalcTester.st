'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:05:48 pm'!

Tester subclass: #CalcTester
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-calc'!

(CalcTester getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #(COPY boot ); yourself)!

!CalcTester methodsFor: 'testing'!

{void} allTestsOn: oo {ostream reference}
	"CalcTester runTest"
	
	self test1On: oo.
	self testPseudoCopyOn: oo.!

{void} boobyPop: calc {Calc} with: oo {ostream reference}
	Calc problems.StackUnderflow 
		handle: [:ex |
			oo << 'Underflow caught
'.
			^VOID] 
		do: [calc pop.
			Heaper BLAST: #GRIPE].!

{void} boobyPush: calc {Calc} with: oo {ostream reference} with: rat {Rational}
	Calc problems.StackOverflow 
		handle: [:ex |
			oo << 'Overflow caught
'.
			^VOID] 
		do: [calc push: rat.
			Heaper BLAST: #GRIPE].!

{void} test1On: oo {ostream reference}

	| conn {Connection}
	  cc {CalcCreator}
	  calc {Calc}
	  sensor {PopSensor}
	  rat34 {Rational}
	  rat45 {Rational} |

	conn _ Connection make: CalcCreator.
	cc _ conn bootHeaper cast: CalcCreator.
	calc _ cc newCalc.
	cc _ NULL.
	[sensor _ PopSensor make: oo] smalltalkOnly.
	'sensor = PopSensor::make (&oo);' translateOnly.

	rat34 _ Rational make: 3 with: 4.
	rat45 _ Rational make: 4 with: 5.

	oo << 'calc->getMyI() == ' << calc getMyI << '
'.
	oo << 'calc->getFoo()->sayMe() == ' << calc getFoo sayMe << '
'.
	oo << 'calc->getFoo()->sayOther() == ' << calc getFoo sayOther << '
'.
	oo << 'calc->getFoo()->sayOtherOther() == ' << calc getFoo sayOtherOther << '
'.
	
	calc push: rat34.
	calc plantPopSensor: sensor.

	self boobyPop: calc with: oo.
		
	calc plantPopSensor: sensor.
	calc push: rat34.
	calc push: rat34.
	calc push: rat45.
	calc times.
	
	oo << 'calc->pop () == ' << calc pop << '
'.
	calc push: rat34.
	calc timesArg: rat45.
	
	"
	self boobyPop: calc with: oo.
	self boobyPop: calc with: oo.

	20 timesRepeat: [calc push: rat45].
	
	self boobyPush: calc with: oo with: rat45.
	
	oo << 'calc->pop () == ' << calc pop << '
'.
	20 timesRepeat: [calc pop].
	self boobyPop: calc with: oo.

	"
	
	calc destroy.
	conn destroy!

{void} testPseudoCopyOn: oo {ostream reference}

	| conn {Connection}
	  cc {CalcCreator}
	  calc {Calc}
	  rat34 {Rational}
	  rat45 {Rational}
	  und {UndefinedRational} |

	oo << 'testing PSEUDO_COPY objects
'.
	conn _ Connection make: CalcCreator.
	cc _ conn bootHeaper cast: CalcCreator.
	calc _ cc newCalc.
	cc _ NULL.

	rat34 _ Rational make: 3 with: 4.
	rat45 _ Rational make: 4 with: 5.
	und _ UndefinedRational make.

	calc push: rat34.
	calc push: und.
	calc push: rat45.
	
	oo << 'calc->pop () == ' << calc pop << '
'.
	oo << 'calc->pop () == ' << calc pop << '
'.
	oo << 'calc->pop () == ' << calc pop << '
'.

	calc destroy.
	conn destroy! !

!CalcTester methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.! !