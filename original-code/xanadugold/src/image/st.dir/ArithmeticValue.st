'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:48:07 pm'!

Magnitude subclass: #ArithmeticValue
	instanceVariableNames: ''
	classVariableNames: 'CoercionErrorSignal DivisionByZeroSignal DomainErrorSignal ImaginaryResultSignal NumberErrorSignal OverflowSignal RangeErrorSignal UnderflowSignal UnorderedSignal '
	poolDictionaries: ''
	category: 'Magnitude-Numbers'!
ArithmeticValue comment:
'ArithmeticValue is an abstract class for objects which can perform the familiar four arithmetic functions (and therefore have many other functions defined in terms of these).  To permit arithmetic between instances of different subclasses, ArithmeticValue''s subclasses have a notion of coercion generality.  This means that an instance of one subclass can always be coerced to an instance of another subclass of "higher generality".  For example, 1 can be coerced to 1.0 because Float is said to be of higher generality than SmallInteger.  Therefore, 1 + 1.0 can be evaluated by, in effect performing, 1 asFloat + 1.0.  Implementing mixed-type arithmetic via generalized coercion can be inefficient, so for subclasses where efficiency is important, we use a technique called "double dispatching".  See the additional comments in the class protocol under the message category documentation.

ArithmeticValue is a subclass of Magnitude for implementation convenience (natural for most subclasses), although subclasses with no well-defined ordering will need to re-define #< as "^self shouldNotImplement".  For efficient mixed-mode arithmetic, subclasses should re-define all the methods in ArithmeticValue instance message category double dispatching.  Other efficiency measures include re-defining =.

Subclasses must implement methods for 
	instance protocol
		arithmetic
			+
			*
			-
			/
			<
		coercing
			coerce:
			generality
		testing
			isZero
		converting
			reduceGeneralityIfPossible

	class protocol
 		constants access
			zero
			unity 

Class Variables:
	CoercionErrorSignal		<Signal> Numeric coercion error
	DivisionByZeroSignal	<Signal> Division by zero
	DomainErrorSignal		<Signal> Numeric domain error
	NumberErrorSignal		<Signal> Numeric error
	OverflowSignal			<Signal> Numeric overflow
	RangeErrorSignal		<Signal> Numeric range error
	UnderflowSignal		<Signal> Numeric underflow
	UnorderedSignal 		<Signal> Ordering of these numbers is ill-defined
'!


!ArithmeticValue methodsFor: 'arithmetic'!

* aNumber 
	"Answer the result of multiplying the receiver by the argument, aNumber."

	^self subclassResponsibility!

+ aNumber 
	"Answer the sum of the receiver and the argument, aNumber."

	^self subclassResponsibility!

- aNumber 
	"Answer the difference between the receiver and aNumber."

	^self subclassResponsibility!

/ aNumber 
	"Answer the result of dividing receiver by aNumber."

	^self subclassResponsibility!

abs
	"Answer a Number that is the absolute value (positive magnitude) of the receiver."

	self negative
		ifTrue: [^self negated]
		ifFalse: [^self]!

absSquared
	"Return the magnitude (or absolute value) of the complex number, squared."

	^self * self!

negated
	"Answer a Number that is the negation of the receiver."

	^self class zero - self!

reciprocal
	"Answer 1 divided by the receiver.  Provide an error 
	notification if the receiver is 0."

	^self class unity / self! !

!ArithmeticValue methodsFor: 'mathematical functions'!

raisedToInteger: anInteger 
	"Answer the receiver raised to the power anInteger where the 
	argument must be a kind of Integer. This is a special case of 
	raisedTo:."

	| count tmp |
	anInteger isInteger
		ifFalse: [^self class
			raise: #domainErrorSignal
			receiver: self
			selector: #raisedToInteger:
			arg: anInteger
			errorString: 'raisedToInteger: expects an Integer as argument'].
	anInteger < 0 ifTrue: [^(self raisedToInteger: anInteger negated) reciprocal].
	anInteger = 0 ifTrue: [^self class unity].
	anInteger = 1 ifTrue: [^self].
	count _ 1.
	[(count _ count + count) < anInteger] whileTrue.
	tmp _ self class unity.
	[count > 0]
		whileTrue: 
			[tmp _ tmp * tmp.
			(anInteger bitAnd: count)
				= 0 ifFalse: [tmp _ tmp * self].
			count _ count bitShift: -1].
	^tmp!

raisedToInteger: anInteger mod: modulus
	"Answer the receiver raised to the power anInteger where the 
	argument must be a kind of Integer. This is a special case of 
	raisedTo:."

	| count tmp |
	anInteger isInteger
		ifFalse: [^self class
			raise: #domainErrorSignal
			receiver: self
			selector: #raisedToInteger:
			arg: anInteger
			errorString: 'raisedToInteger: expects an Integer as argument'].
	anInteger < 0 ifTrue: [^(self raisedToInteger: anInteger negated) reciprocal].
	anInteger = 0 ifTrue: [^self class unity].
	anInteger = 1 ifTrue: [^self \\ modulus].
	count _ 1.
	[(count _ count + count) < anInteger] whileTrue.
	tmp _ self class unity.
	[count > 0]
		whileTrue: 
			[tmp _ (tmp * tmp) \\ modulus.
			(anInteger bitAnd: count)
				= 0 ifFalse: [tmp _ (tmp * self) \\ modulus].
			count _ count bitShift: -1].
	^tmp!

squared
	"Answer the receiver multiplied by itself."

	^self * self! !

!ArithmeticValue methodsFor: 'testing'!

isComplex
	"Answer whether the receiver has an imaginary part"

	^false!

isZero
	"Answer whether 'self = self class zero'.  We can't use #= because
	#= is defined in terms of #isZero"

	^self subclassResponsibility!

negative
	"Answer whether the receiver is less than 0."

	^self < self class zero!

positive
	"Answer whether the receiver is greater than or equal to 0."

	^self >= self class zero!

respondsToArithmetic
	"Answer whether the object responds to the numeric (#+, #-, #*, #/)
	protocol as defined in the class ArithmeticValue"

	^true!

sign
	"Answer 1 if the receiver is greater than 0, answer -1 if less than 0, 
	else answer 0."

	self > self class zero ifTrue: [^1].
	self < self class zero ifTrue: [^-1].
	^0!

strictlyPositive
	"Answer whether the receiver is greater than 0."

	^self > self class zero! !

!ArithmeticValue methodsFor: 'comparing'!

= aNumber
	"Answer whether the two objects are equal.  For numeric objects,
	the two will be equal if the difference between them is zero"

	^aNumber respondsToArithmetic
		ifTrue:	[(self - aNumber) isZero]
		ifFalse:	[false]! !

!ArithmeticValue methodsFor: 'coercing'!

coerce: aNumber 
	"Answer a number representing the argument, aNumber, that is
	the same kind of Number as the receiver.  Must be defined by all Number
	classes."

	^self subclassResponsibility!

generality
	"Answer the number representing the ordering of the receiver in the
	generality hierarchy.  A number in this hierarchy coerces to numbers
	higher in hierarchy (i.e., with larger generality numbers)."

	^self subclassResponsibility!

retry: aSymbol coercing: aNumber 
	"Arithmetic represented by the symbol, aSymbol, could not be 
	performed with the receiver and the argument, aNumber, because
	of the differences in representation.  Coerce either the receiver or the
	argument, depending on which has higher generality, and try again.  
	If the generalities are the same, then this message
	should not have been sent so an error notification is provided."

	self generality < aNumber generality
		ifTrue: [^(aNumber coerce: self) perform: aSymbol with: aNumber].
	self generality > aNumber generality
		ifTrue: [^self perform: aSymbol with: (self coerce: aNumber)].
	self error: 'coercion attempt failed'! !

!ArithmeticValue methodsFor: 'double dispatching'!

differenceFromDouble: aDouble

	^aDouble retry: #- coercing: self!

differenceFromFloat: aFloat 
	"The argument aFloat, known to be a kind of floating point number, 
	encountered a problem on subtraction. Retry by coercing either aFloat
	or self, whichever is the less general arithmetic value."

	^aFloat retry: #- coercing: self!

differenceFromFraction: aFraction
	"The argument aFraction, known to be a kind of fraction, 
	encountered a problem on subtraction. Retry by coercing either 
	aFraction or self, whichever is the less general arithmetic value."

	^aFraction retry: #- coercing: self!

differenceFromInfinitesimal: aNumber

	^aNumber retry: #- coercing: self!

differenceFromInfinity: aNumber

	^aNumber retry: #- coercing: self!

differenceFromInteger: anInteger
	"The argument anInteger, known to be a kind of integer, 
	encountered a problem on subtraction. Retry by coercing either 
	anInteger or self, whichever is the less general arithmetic value."

	^anInteger retry: #- coercing: self!

differenceFromSomeNumber: aNumber

	^aNumber retry: #- coercing: self!

lessFromDouble: aDouble

	^aDouble retry: #< coercing: self!

lessFromFloat: aFloat 
	"The argument aFloat, known to be a kind of floating point number, 
	encountered a problem on less than comparison. Retry by coercing 
	either aFloat or self, whichever is the less general arithmetic value."

	^aFloat retry: #< coercing: self!

lessFromFraction: aFraction
	"The argument aFraction, known to be a kind of fraction, 
	encountered a problem on less than comparison. Retry by coercing 
	either aFraction or self, whichever is the less general arithmetic value."

	^aFraction retry: #< coercing: self!

lessFromInfinitesimal: aNumber

	^aNumber retry: #< coercing: self!

lessFromInfinity: aNumber

	^aNumber retry: #< coercing: self!

lessFromInteger: anInteger 
	"The argument anInteger, known to be a kind of integer, 
	encountered a problem on less than comparison. Retry by 
	coercing either anInteger or self, whichever is the less general
	arithmetic value."

	^anInteger retry: #< coercing: self!

lessFromSomeNumber: aNumber

	^aNumber retry: #< coercing: self!

productFromDouble: aDouble

	^aDouble retry: #* coercing: self!

productFromFloat: aFloat 
	"The argument aFloat, known to be a kind of floating point number, 
	encountered a problem on multiplication. Retry by coercing either 
	aFloat or self, whichever is the less general arithmetic value."

	^aFloat retry: #* coercing: self!

productFromFraction: aFraction
	"The argument aFraction, known to be a kind of fraction, 
	encountered a problem on multiplication. Retry by coercing either 
	aFraction or self, whichever is the less general arithmetic value."

	^aFraction retry: #* coercing: self!

productFromInfinitesimal: aNumber

	^aNumber retry: #* coercing: self!

productFromInfinity: aNumber

	^aNumber retry: #* coercing: self!

productFromInteger: anInteger
	"The argument anInteger, known to be a kind of integer, 
	encountered a problem on multiplication. Retry by coercing 
	either anInteger or self, whichever is the less general
	arithmetic value."

	^anInteger retry: #* coercing: self!

productFromSomeNumber: aNumber

	^aNumber retry: #* coercing: self!

quotientFromDouble: aDouble

	^aDouble retry: #/ coercing: self!

quotientFromFloat: aFloat 
	"The argument aFloat, known to be a kind of floating point number, 
	encountered a problem on division. Retry by coercing either aFloat 
	or self, whichever is the less general arithmetic value."

	^aFloat retry: #/ coercing: self!

quotientFromFraction: aFraction
	"The argument aFraction, known to be a kind of fraction, 
	encountered a problem on division. Retry by coercing either 
	aFraction or self, whichever is the less general arithmetic value."

	^aFraction retry: #/ coercing: self!

quotientFromInfinitesimal: aNumber 

	^aNumber retry: #/ coercing: self!

quotientFromInfinity: aNumber

	^aNumber retry: #/ coercing: self!

quotientFromInteger: anInteger
	"The argument anInteger, known to be a kind of integer, 
	encountered a problem on division. Retry by coercing either 
	anInteger or self, whichever is the less general arithmetic value."

	^anInteger retry: #/ coercing: self!

quotientFromSomeNumber: aNumber 

	^aNumber retry: #/ coercing: self!

sumFromDouble: aDouble

	^aDouble retry: #+ coercing: self!

sumFromFloat: aFloat 
	"The argument aFloat, known to be a kind of floating point number, 
	encountered a problem on addition. Retry by coercing either aFloat 
	or self, whichever is the less general arithmetic value."

	^aFloat retry: #+ coercing: self!

sumFromFraction: aFraction
	"The argument aFraction, known to be a kind of fraction, 
	encountered a problem on addition. Retry by coercing either 
	aFraction or self, whichever is the less general arithmetic value."

	^aFraction retry: #+ coercing: self!

sumFromInfinitesimal: aNumber

	^aNumber retry: #+ coercing: self!

sumFromInfinity: aNumber

	^aNumber retry: #+ coercing: self!

sumFromInteger: anInteger
	"The argument anInteger, known to be a kind of integer, 
	encountered a problem on addition. Retry by coercing either 
	anInteger or self, whichever is the less general arithmetic value."

	^anInteger retry: #+ coercing: self!

sumFromSomeNumber: aNumber

	^aNumber retry: #+ coercing: self! !

!ArithmeticValue methodsFor: 'converting'!

asSmallInteger
	"Answer the receiver transformed to a lower generality, repeating the 
	application until the generality of SmallInteger is reached.  If this is
	not possible, signal an error."

	^self reduceGeneralityToAtLeast: SmallInteger generality!

reduceGeneralityIfPossible
	"Answer the receiver transformed to a lower generality, if such a 
	transformation is possible without losing information. If not, answer 
	the receiver.  Answers self for simplicity, but subclasses should override."

	^self!

reduceGeneralityToAtLeast: aGenerality 
	"Answer the receiver transformed to a lower generality, repeating the 
	application until the specified generality is reached.  If the generality
	can't be reached, signal an error"

	| testVal lastTest generality |
	testVal _ self.
	lastTest _ 1000.	"An arbitrarily high generality"
	[(generality _ testVal generality) < lastTest and: [aGenerality < generality]]
		whileTrue: 
			[lastTest _ generality.
			testVal _ testVal reduceGeneralityIfPossible].
	aGenerality < generality
		ifTrue: [^self class
				raise: #coercionErrorSignal
				receiver: self
				selector: #reduceGeneralityToAtLeast:
				arg: aGenerality
				errorString: self printString , ' could not be reduced to the desired generality']
		ifFalse: [^testVal]!

toMinimumGenerality
	"Answer the receiver transformed to a lower generality, repeating the 
	application until the generality doesn't change"

	| testVal lastTest generality |
	testVal _ self.
	lastTest _ 1000.	"An arbitrarily high generality"
	[(generality _ testVal generality) < lastTest]
		whileTrue: 
			[lastTest _ generality.
			testVal _ testVal reduceGeneralityIfPossible].
	^testVal! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

ArithmeticValue class
	instanceVariableNames: ''!


!ArithmeticValue class methodsFor: 'class initialization'!

initialize
	"Initialize signals."
	"ArithmeticValue initialize"

	| es rs ds |
	es _ Object errorSignal.
	NumberErrorSignal _ (es _ (es newSignalMayProceed: true)
				notifierString: 'Numeric error';
				nameClass: self message: #errorSignal).
	UnorderedSignal _ ((es newSignal)
				notifierString: 'Ordering of these numbers is ill-defined';
				nameClass: self message: #unorderedSignal).
	DomainErrorSignal _ (ds _ (es newSignal)
				notifierString: 'Numeric domain error';
				nameClass: self message: #domainErrorSignal).
	DivisionByZeroSignal _ ((ds newSignal)
				notifierString: 'Division by zero';
				nameClass: self message: #divisionByZeroSignal).
	ImaginaryResultSignal _ ((ds newSignal)
				notifierString: 'Operation result would be imaginary';
				nameClass: self message: #imaginaryResultSignal).
	CoercionErrorSignal _ ((ds newSignal)
				notifierString: 'Numeric coercion error';
				nameClass: self message: #coercionErrorSignal).
	RangeErrorSignal _ (rs _ (es newSignal)
				notifierString: 'Numeric range error';
				nameClass: self message: #rangeErrorSignal).
	OverflowSignal _ ((rs newSignal)
				notifierString: 'Numeric overflow';
				nameClass: self message: #overflowSignal).
	UnderflowSignal _ ((rs newSignal)
				notifierString: 'Numeric underflow';
				nameClass: self message: #underflowSignal)! !

!ArithmeticValue class methodsFor: 'signal access'!

coercionErrorSignal

	^CoercionErrorSignal!

divisionByZeroSignal

	^DivisionByZeroSignal!

domainErrorSignal

	^DomainErrorSignal!

errorSignal

	^NumberErrorSignal!

imaginaryResultSignal

	^ImaginaryResultSignal!

overflowSignal

	^OverflowSignal!

raise: signalName receiver: anObject selector: aSymbol arg: anArg errorString: aMessage

	^(self perform: signalName) raiseRequestWith: (MessageSend receiver: anObject selector: aSymbol argument: anArg) errorString: aMessage!

raise: signalName receiver: anObject selector: aSymbol args: anArray errorString: aMessage

	^(self perform: signalName) raiseRequestWith: (MessageSend receiver: anObject selector: aSymbol arguments: anArray) errorString: aMessage!

raise: signalName receiver: anObject selector: aSymbol errorString: aMessage

	^(self perform: signalName) raiseRequestWith: (MessageSend receiver: anObject selector: aSymbol) errorString: aMessage!

rangeErrorSignal

	^RangeErrorSignal!

underflowSignal

	^UnderflowSignal!

unorderedSignal

	^UnorderedSignal! !

!ArithmeticValue class methodsFor: 'constants access'!

generality
	"Answer the generality of the receiver's instances."

	^self zero generality!

unity
	"Answer the value which allows, for any given arithmetic value, the following to be true

		aNumber * aNumber class unity = aNumber

	This must be true regardless of how a given subclass chooses to define #*"

	^self subclassResponsibility!

zero
	"Answer the value which allows, for any given arithmetic value, the following to be true

		aNumber + aNumber class zero = aNumber

	This must be true regardless of how a given subclass chooses to define #+"

	^self subclassResponsibility! !

!ArithmeticValue class methodsFor: 'instance creation'!

new
	"Numbers should be created only through arithmetic operations."

	^self shouldNotImplement!

new: size
	"Numbers should be created only through arithmetic operations."

	^self shouldNotImplement! !

!ArithmeticValue class methodsFor: 'documentation'!

aboutDoubleDispatching
	"Double dispatching is a useful technique for efficiently choosing an algorithm
	based on the classes of one or more of the arguments of a message as well
	as the class of the receiver.  For example, we might wish to evaluate the
	following expression:

		3 + 4.0

	When the SmallInteger 3 receives the message #+, it may have to choose
	among algorithms designed for Integers, Fractions, and Floats.  The fastest
	way to do this is for it to simply send the argument of the message another
	message--as shown here

		+ aNumber 
			<primitive: 1>
			^aNumber sumFromInteger: self

	If we replace variable names with values, this translates to

		4.0 sumFromInteger: 3

	Since the float knows that the argument must be an Integer, it knows immediately
	what must be done to add itself to the integer.  Note that the order of the numbers
	has changed, so that in methods such as Fraction>>quotientFromInteger:, it is the
	argument that is divided by the receiver, and not the receiver divided by the argument

	In the system as delivered, there are five operations that are subject to
	double-dispatching:
		+ (addition)
		- (subtraction)
		* (multiplication)
		/ (division)
		< (comparison--the rest of the comparison operators can be derived)

	For addition, the dispatch operator takes the form #sumFrom[a class name]:
	For subtraction, the dispatch operator takes the form #differenceFrom[a class name]:
	For multiplication, the dispatch operator takes the form #productFrom[a class name]:
	For division, the dispatch operator takes the form #quotientFrom[a class name]:
	For comparison, the dispatch operator takes the form #lessFrom[a class name]:
	"

	^self error: 'comment only'!

coercion
	"The base numbers in the system evaluate arithmetic and comparison 
	operations by a technique called double-dispatching. This provides 
	significant speed at the expense of a large number of typed 
	methods--sumFromFloat, sumFromInteger, sumFromFraction . . . . 
	Obviously, when defining a new class of ArithmeticValue, you wouldn't 
	always want to add a whole new set of dispatching messages for 
	your new class. This causes an explosion that is uncontrollable. 
	Therefore, there is a second, slightly less efficient method of 
	integrating a ArithmeticValue class into the system. 
	
	To implement a new class in the easiest possible fashion, you must 
	first decide the class's generality. The generality of a number is an 
	integer that defines its relationship to other kinds of numbers. For 
	example: all Integers can be represented as Fractions, but not all 
	Fractions can be represented as Integers. Therefore, Fractions have 
	greater generality than Integers. Likewise, Floats have greater 
	generality than either Fractions or Integers. For example, look at the 
	class Double--part of the Extended Numbers fileIn. Because all 
	Floats can be represented as Doubles, we give it a generality higher 
	than Float. Not all Complex numbers can be represented as Doubles, 
	so it should have a generality less than Complex. When we have 
	given the same consideration to all of the existing ArithmetivValue
	classes, we may settle on a generality of 90. 
	
	It must be possible, if this technique is used, to convert anything 
	with a smaller generality to an instance of the new class. For 
	Double, this is acheived by defining a message called #asDouble, 
	which is recognized by Floats, Fractions, and Integers. Then, when 
	#coerce: is sent to a Double, with aNumber as the argument, the 
	Double returns 'aNumber asDouble'. In this way, the argument of 
	#coerce: is made compatible with the receiver. Likewise, Doubles 
	must also know how to coerce themselves into instances of any 
	class that has higher generality than they do. The protocol is 
	defined by the class with higher generality. 
	
	Finally, when a number is sent an arithmetic or comparison message, 
	it should first test whether the argument is compatible. The easiest 
	test is whether the receiver and argument have the same class. If 
	they are compatible, there should be some kind of algorithm for 
	performing the requested operation. If not, the receiver should be 
	sent the message #retry:coercing:. The first argument is the 
	selector of the message that was sent; the second is the argument 
	of the message. The implementation of #retry:coercing: finds out 
	which of the numbers has lower generality, coerces that number to 
	have a compatible format with the other number, and resends the 
	message. 
	
	The class Complex depends heavily on this protocol. A useful 
	example of how the code works can be had by filing in the code for 
	Complex, and stepping through the following code in the Debugger: 
	
	self halt. 
	(3%2) + (5%3). 
	(3%2) + 7. 
	7 + (3%2). 
	
	"

	^self error: 'comment only'!

thisClassIsFieldlike
	"A more formal way of considering the role of ArithmeticValue is that 
	all subclasses obey the field axioms: 
		Given a set (all the potential instances of all the subclasses of 
		ArithmeticValue) with two operations -- addition (+) and 
		multiplication (*). 

		1] a + b is in the set {closed under addition}. 
		2] a + b = b + a and (a + b) + c = a + (b + c)
			{addition is commutative and associative}. 
		3] there is a set element z such that a + z = a
			{additive identity or zero} 
		4] for any a & b, there is a set element x such that a + x = b 
			{additive inverse} 
		5] a * b is in the set {closed under multiplication}. 
		6] a * b = b * a and (a * b) * c = a * (b * c)
			{multiplication is commutative and associative}. 
		7] there is a set element u such that a * u = a
			{multiplicitive identity or unity} 
		8] for any a & b, there is a set element x such that a * x = b 
			{multiplicitive inverse} 
		9] a * (b + c) = (a * b) + (a * c)
			{multiplication distributes over addition} 
	
	Given this basis, we can define subtraction, division, remainder, 
	negation etc. The guarentee of comutivity is needed for the 
	double-dispatching stuff. 
	
	Of course, the notion of a set being closed under some operation on 
	real computers is tied-up with the halting problem (e.g. can the 
	computation ever be completed) and lack of verification; so we can 
	not really rely on this notion completely. 
	"

	^self error: 'comment only'! !

ArithmeticValue initialize!
