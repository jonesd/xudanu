'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:05:11 pm'!

Tester subclass: #ProtocolTester
	instanceVariableNames: '
		myXmtr {Xmtr NOCOPY}
		myRcvr {Rcvr NOCOPY}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Xcvr'!

(ProtocolTester getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #(COPY boot ); add: #SMALLTALK.ONLY; add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!ProtocolTester methodsFor: 'initialization'!

setUpXcvrs
	| tporter maker station spec |
	tporter _ DirectTransporter make.
	maker _ ProtocolBroker commProtocol.
	station _ Station make: tporter with: maker.
	spec _ RPCSpecialist make: station with: (Cookbook make.Category: CalcCreator).
	myXmtr _ maker makeXmtr: spec with: tporter writeStream.
	myRcvr _ maker makeRcvr: spec with: tporter readStream.! !

!ProtocolTester methodsFor: 'testing'!

{void} allTestsOn: oo {ostream reference} 
	"ProtocolTester runTest"
	self setUpXcvrs.
	"self runHeaperTestOn: oo."  " must be first test."
	self runIntTestOn: oo.
	self runIntegerVarTestOn: oo.
	self runBooleanTestOn: oo.
	self runDataTestOn: oo.
	self runStringTestOn: oo.!

{void} runBooleanTestOn: oo {ostream reference} 

	myXmtr sendBooleanVar: true.
	myXmtr sendBooleanVar: false.
	myXmtr sendBooleanVar: true.
	oo << 'T F T ==> ' << myRcvr receiveBooleanVar << ' ' << myRcvr receiveBooleanVar << ' ' << myRcvr receiveBooleanVar.
	oo << '
'.!

{void} runDataTestOn: oo {ostream reference} 

	myXmtr sendHeaper: (UInt8Array string:
		'Apple Banana Cherry Durian Elderberry Grape ').
	oo << 'fruity list ==> ' << myRcvr receiveHeaper << '
'.!

{void} runHeaperTestOn: oo {ostream reference} 

	| conn {Connection}
	  cc {CalcCreator}
	  calc {Calc} calcProxy {Calc} secondCalc {Calc}
	  rat34 {Rational} rat45 {Rational} |

	conn _ Connection make: CalcCreator.
	cc _ conn bootHeaper cast: CalcCreator.
	calc _ cc newCalc.
	cc _ NULL.
	rat34 _ Rational make: 3 with: 4.
	rat45 _ Rational make: 4 with: 5.

	myXmtr sendHeaper: NULL.
	oo << 'NULL ==> ' << myRcvr receiveHeaper << '
'.
	myXmtr sendHeaper: calc.
	calcProxy _ myRcvr receiveHeaper.
	myXmtr sendHeaper: calcProxy.
	secondCalc _ myRcvr receiveHeaper.
	oo << 'calc calcProxy calc2 ==> ' << calc << ' ' << calcProxy << ' ' << secondCalc << '
'.
	myXmtr sendHeaper: rat34.
	myXmtr sendHeaper: rat45.
	oo << 'rat34 rat45 ==> ' << myRcvr receiveHeaper << ' ' << myRcvr receiveHeaper << '
'.
	conn destroy.!

{void} runIntegerVarTestOn: oo {ostream reference} 

	myXmtr sendIntegerVar: IntegerVar0.
	oo << '0 => ' << myRcvr receiveIntegerVar << '
'.
	myXmtr sendIntegerVar: 1.
	myXmtr sendIntegerVar: 2.
	oo << '1 2 ==> ' << myRcvr receiveIntegerVar << ' ' << myRcvr receiveIntegerVar << '
'.
	myXmtr sendIntegerVar: 42.
	myXmtr sendIntegerVar: 32.
	oo << '42 32 ==> ' << myRcvr receiveIntegerVar << ' ' << myRcvr receiveIntegerVar << '
'.
	myXmtr sendIntegerVar: 63.
	myXmtr sendIntegerVar: 64.
	oo << '63 64 ==> ' << myRcvr receiveIntegerVar << ' ' << myRcvr receiveIntegerVar << '
'.
	myXmtr sendIntegerVar: 127.
	myXmtr sendIntegerVar: 128.
	oo << '127 128 ==> ' << myRcvr receiveIntegerVar << ' ' << myRcvr receiveIntegerVar << '
'.
	myXmtr sendIntegerVar: 400.
	myXmtr sendIntegerVar: 20000.
	oo << '400 20000 ==> ' << myRcvr receiveIntegerVar << ' ' << myRcvr receiveIntegerVar << '
'.
	myXmtr sendIntegerVar: -1.
	myXmtr sendIntegerVar: -2.
	oo << '-1 -2 ==> ' << myRcvr receiveIntegerVar << ' ' << myRcvr receiveIntegerVar << '
'.
	myXmtr sendIntegerVar: -62.
	myXmtr sendIntegerVar: -63.
	oo << '-62 -63 ==> ' << myRcvr receiveIntegerVar << ' ' << myRcvr receiveIntegerVar << '
'.
	myXmtr sendIntegerVar: -64.
	myXmtr sendIntegerVar: -65.
	oo << '-64 -65 ==> ' << myRcvr receiveIntegerVar << ' ' << myRcvr receiveIntegerVar << '
'.
	myXmtr sendIntegerVar: -260.
	myXmtr sendIntegerVar: -120.
	oo << '-260 -120 ==> ' << myRcvr receiveIntegerVar << ' ' << myRcvr receiveIntegerVar << '
'.!

{void} runIntTestOn: oo {ostream reference} 

	myXmtr sendInt8: Int0.
	myXmtr sendUInt8: Int0.
	myXmtr sendInt32: Int32Zero.
	myXmtr sendUInt32: UInt32Zero.
	oo << '0 0 0 0 => ' << myRcvr receiveInt8 << ' ' << myRcvr receiveUInt8 << ' ' << myRcvr receiveInt32 << ' ' << myRcvr receiveUInt32 << '
'.
	myXmtr sendInt8: Int0 + 1.
	myXmtr sendUInt8: Int0 + 1.
	myXmtr sendInt32: Int32Zero + 1.
	myXmtr sendUInt32: UInt32Zero + 1.
	oo << '1 1 1 1 => ' << myRcvr receiveInt8 << ' ' << myRcvr receiveUInt8 << ' ' << myRcvr receiveInt32 << ' ' << myRcvr receiveUInt32 << '
'.
	myXmtr sendInt8: Int0 - 1.
	myXmtr sendInt32: Int32Zero - 1.
	oo << '-1 -1 => ' << myRcvr receiveInt8<< ' ' << myRcvr receiveInt32 << '
'.
	myXmtr sendInt8: Int0 - 35.
	myXmtr sendUInt8: Int0 + 34.
	myXmtr sendInt32: Int32Zero - 300.
	myXmtr sendUInt32: UInt32Zero + 808.
	oo << '-35 34 -300 808 => ' << myRcvr receiveInt8 << ' ' << myRcvr receiveUInt8 << ' ' << myRcvr receiveInt32 << ' ' << myRcvr receiveUInt32 << '
'.!

{void} runStringTestOn: oo {ostream reference} 

	myXmtr sendString: ''.
	myXmtr sendString: 'hello world'.
	myXmtr sendString: 'from here
 	to here'.
	myXmtr sendString: 'abcdefghijklmnopqrstuvwxyz0123456789!!@#$%^&*()_+|\=-[]`'';{}~":/.,<>?'.
	oo << 'empty ==> ' << myRcvr receiveString << '
'.
	oo << 'short ==> ' << myRcvr receiveString<< '
'.
	oo << 'with special characters ==> ' << myRcvr receiveString<< '
'.
	oo << 'many printing characters ==> ' << myRcvr receiveString<< '
'.! !

!ProtocolTester methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.! !