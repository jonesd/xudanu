'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:49:06 pm'!

nil subclass: #Object
	instanceVariableNames: ''
	classVariableNames: 'DeepCopyErrorSignal DependentsFields ErrorRecursion ErrorSignal HaltSignal IndexNotFoundSignal InformationSignal MessageNotUnderstoodSignal NonIntegerIndexSignal NotFoundSignal NotifySignal SubclassResponsibilitySignal SubscriptOutOfBoundsSignal UserInterruptSignal '
	poolDictionaries: ''
	category: 'Kernel-Objects'!
Object comment:
'Object is the superclass of all classes.  It thus provides default behavior common to all objects, such as class access, copying and printing.

Class Variables:
	DependentsFields	<IdentityDictionary> of associations, where each association pair 
						is an object and an ordered collection of objects that depend on that object
	ErrorRecursion		<Boolean> flags whether error notification is recursively infinite
	ErrorSignal			<Signal> Error - 
	IndexNotFoundSignal	<Signal> Index not found
	InformationSignal	<Signal> Information - 
	MessageNotUnderstoodSignal		<Signal> Message not understood 
	NonIntegerIndexSignal		<Signal> Non integer index: 
	NotFoundSignal		<Signal> Element not Found
	NotifySignal		<Signal> Notifier 
	SubclassResponsibilitySignal	<Signal> Subclass responsibility 
	SubscriptOutOfBoundsSignal	<Signal> Subscript out of bounds: 
	UserInterruptSignal		<Signal> User Interrupt'!


!Object methodsFor: 'initialize-release'!

release
	"Remove references to objects that may refer to the receiver. Answers self. 
	This message should be overidden by subclasses with any cycles, in which
	case the subclass should also include the expression super release."

	self breakDependents! !

!Object methodsFor: 'accessing'!

at: index 
	"Answer the value of an indexable field in the receiver.  Fail if the  
	argument index is not an Integer or is out of bounds.  Essential.  See  
	documentation in Object metaclass."

	<primitive: 60>
	index isInteger ifTrue: [^self subscriptBoundsError: index].
	index respondsToArithmetic
		ifTrue: [^self at: index asSmallInteger]
		ifFalse: [^self nonIntegerIndexError: index]!

at: index put: value 
	"Store the argument value in the indexable field of the receiver indicated by 
	index. Fail if the index is not an Integer or is out of bounds. Fail if the 
	value is not of the right type for this kind of collection. Answer the 
	value that was stored. Essential. See documentation in Object metaclass."

	<primitive: 61>
	index isInteger
		ifTrue: [(index >= 1 and: [index <= self size])
					ifTrue: [^self improperStoreError]
					ifFalse: [^self subscriptBoundsError: index]].
	index respondsToArithmetic
		ifTrue: [^self at: index asSmallInteger put: value]
		ifFalse: [^self nonIntegerIndexError: index]!

basicAt: index 
	"Answer the value of an indexable field in the receiver. Fail if the 
	argument index is not an Integer or is out of bounds. Essential. See 
	documentation in Object metaclass.  Do not override this message in any 
	subclass."

	<primitive: 60>
	index isInteger ifTrue: [^self subscriptBoundsError: index].
	index respondsToArithmetic
		ifTrue: [^self basicAt: index asSmallInteger]
		ifFalse: [^self nonIntegerIndexError: index]!

basicAt: index put: value 
	"Store the second argument value in the indexable field of the receiver 
	indicated by index. Fail if the index is not an Integer or is out of bounds. Or 
	fail if the value is not of the right type for this kind of collection. Answer 
	the value that was stored. Essential. See documentation in Object 
	metaclass. Do not override in a subclass."

	<primitive: 61>
	index isInteger
		ifTrue: [(index >= 1 and: [index <= self basicSize])
					ifTrue: [^self improperStoreError]
					ifFalse: [^self subscriptBoundsError: index]].
	index respondsToArithmetic
		ifTrue: [^self basicAt: index asSmallInteger put: value]
		ifFalse: [^self nonIntegerIndexError: index]!

basicSize
	"Answer the number of indexable fields in the receiver. This value is the 
	same as the largest legal subscript. Essential. See documentation in Object 
	metaclass. Do not override in any subclass."

	<primitive: 62>
	"The number of indexable fields of fixed-length objects is 0"
	^0!

readFromString: aString
	"Create an object based on the contents of aString."

	^self readFrom: (ReadStream on: aString)!

size
	"Answer the number of indexable fields in the receiver.  This value is the 
	same as the largest legal subscript.  Essential.  See documentation in Object 
	metaclass. "

	<primitive: 62>
	"The number of indexable fields of fixed-length objects is 0"
	^0!

yourself
	"Answer self."! !

!Object methodsFor: 'testing'!

isBehavior
	"Answer whether the object can be the 'class' of another object"

	^false!

isCharacter
	"Answer whether receiver is a character."

	^false!

isInteger
	"Coerces Integers to true and everything else to false.  Integer
	overrides with ^true"

	^false!

isManifest
	"Answer whether receiver is manifestly storable."

	^false!

isNil
	"Coerce nil to true and everything else to false.  UndefinedObject 
	overrides with ^true"

	^false!

isSequenceable
	"Answer true for SequenceableCollections and everything else to false.
	SequenceableCollection overrides with ^true"

	^false!

isString
	"Coerce String to true and everything else to false.  String
	overrides with ^true."

	^false!

isSymbol
	"Coerce Symbols to true and everything else to false.  Symbol
	overrides with ^true."

	^false!

notNil
	"Coerce nil to false and everything else to true.  UndefinedObject 
	overrides with ^false"

	^true!

refersToLiteral: anObject
	"The receiver is a literal in compiled code.
	Answer whether the receiver is a reference to
	anObject.  For objects other than sub-methods,
	this is just a test of whether the receiver is
	the same object as anObject. "

	^self == anObject!

{BooleanVar} refersTowardsLiteral: anObject
	"The receiver is a literal in compiled code.
	Answer whether the receiver is a reference to
	anObject.  For objects other than sub-methods,
	this is just a test of whether the receiver is
	the same object as anObject. "

	^self == anObject!

respondsToArithmetic
	"Answer whether the object responds to the numeric (#+, #-, #*, #/)
	protocol as defined in the class ArithmeticValue"

	^false! !

!Object methodsFor: 'comparing'!

= anObject 
	"Answer whether the receiver and the argument represent the same object.
	If = is redefined in any subclass, consider also redefining the message hash."

	^self == anObject!

== anObject 
	"Answer true if the receiver and the argument are the same object (have the same 
	object pointer) and false otherwise.  Do not redefine the message == in any 
	other class!!  Essential.  No Lookup.  See documentation in Object metaclass."

	<primitive: 110>
	self primitiveFailed!

hash
	"Answer with a SmallInteger unique to the receiver. 
	Fail if the receiver is a SmallInteger.  Essential.  See documentation 
	in Object metaclass."

	<primitive: 75>
	self primitiveFailed!

identityHash
	"Answer a SmallInteger whose value reflects the identity, not the contents,
	of the receiver.  Essential.  See documentation in Object metaclass."

	<primitive: 75>
	self primitiveFailed!

~= anObject 
	"Answer whether the receiver and the argument do not represent the same 
	object."

	^self = anObject == false!

~~ anObject 
	"Answer true if the receiver and the argument are not the same object 
	(have the same object pointer) and false otherwise."

	^(self == anObject) not! !

!Object methodsFor: 'copying'!

copy
	"Answer another instance just like the receiver. Subclasses typically override
	this method;  they typically do not override shallowCopy"

	^self shallowCopy!

deepCopy
	"Answer a copy of the receiver with its own copy of each instance 
	variable."
	"This is basically an incoherent concept which will be retracted in
	a future release.  Consider, for example what happens when deepCopying
	an object which refers to a system root (that is, an object from which all
	others are reachable).  Or what happens when deepCopying an object which
	transitively refers to itself.  For now, we raise an error signal in classes
	known to be bad to deepCopy (e.g. will infinitely recurse) and handle the
	signal here.  That is, if for example you try to deepCopy a BlockClosure, you'll
	get an error, if you try to deepCopy an object which *contains* a BlockClosure,
	you'll get a copy of the BlockClosure instead."

	| newObject class index |
	class _ self class.
	self errorSignal handle: [:ex | ex proceedWith: ex parameter copy "squelch shouldNotImplement"]
		do: 
			[class isVariable
				ifTrue: 
					[newObject _ class basicNew: (index _ self basicSize).
					1 to: index do: [:i | newObject basicAt: i put: (self basicAt: i) deepCopy]]
				ifFalse: [newObject _ class basicNew].
			1 to: class instSize do: [:i | newObject instVarAt: i put: (self instVarAt: i) deepCopy]].
	^newObject!

shallowCopy
	"Answer a copy of the receiver which shares the receiver's instance 
	variables."

	<primitive: 532>
	| class newObject index |
	class _ self class.
	class isVariable
		ifTrue: 
			[newObject _ class basicNew: (index _ self basicSize).
			1 to: index do:
				[ :i |  newObject basicAt: i put: (self basicAt: i)  ]]
		ifFalse: [newObject _ class basicNew].
	1 to: class instSize do:
		[ :i |  newObject instVarAt: i put: (self instVarAt: i)  ].
	^newObject! !

!Object methodsFor: 'converting'!

-> anObject
	"Answer a new Association with the receiver as the key and the argument as the value."

	^Association key: self value: anObject! !

!Object methodsFor: 'dependents access'!

addDependent: anObject
	"Add anObject as one of the receiver's dependents."

	^DependentsFields at: self add: anObject!

dependents 
	"Answer an Collection of the objects that are dependent on the
	receiver, that is, the objects that should be notified if the receiver changes."

	^DependentsFields collectionAt: self!

removeDependent: anObject
	"Remove the argument, anObject, as one of the receiver's dependents."

	^DependentsFields at: self remove: anObject! !

!Object methodsFor: 'updating'!

performUpdate: aSymbol 
	"Send the argument, aSymbol, as a unary message to the receiver."

	^self perform: aSymbol!

performUpdate: aSymbol with: anObject 
	"Send the argument, aSymbol, as a keyword message with argument anObject the receiver"

	self perform: aSymbol with: anObject!

update: anAspectSymbol 
	"Receive a change notice from an object of whom the receiver is a dependent.  The argument anAspectSymbol is typically a Symbol that indicates what change has occurred.  The default behavior is to do nothing;  a subclass might want to change itself in some way."

	^self!

update: anAspectSymbol with: aParameter
		"Receive a change notice from an object of whom the receiver is a dependent.  The argument anAspectSymbol is typically a Symbol that indicates what change has occurred and aParameter is additional information. The default behavior is to do nothing;  a subclass might want to change itself in some way."

	^self update: anAspectSymbol

"Note that in this implementation, assumption is that the object does not respond to this protocol but an attempt should be made to try a simpler message."!

update: anAspectSymbol with: aParameter from: aSender
		"Receive a change notice from an object, denoted by aSender, of whom the receiver is a dependent.  The argument anAspectSymbol is typically a Symbol that indicates what change has occurred and aParameter is additional information. The default behavior is to do nothing;  a subclass might want to change itself in some way."

	^self update: anAspectSymbol with: aParameter

"Note that in this implementation, assumption is that the object does not respond to this protocol but an attempt should be made to try a simpler message."!

updateRequest
	"Default behavior is to grant update requests;  a subclass might want to override
	this behavior if it is in the middle of making another change."

	^ true!

updateRequest: anAspectSymbol
		"Default behavior is to grant update requests;  a subclass might want to override this behavior if it is in the middle of making another change."

	^self updateRequest! !

!Object methodsFor: 'printing'!

displayString
	"Answer a String whose characters are a description of the receiver."

	| aStream |
	aStream _ WriteStream on: (String new: 16).
	self printOn: aStream.
	^aStream contents!

isLiteral
	"Answer whether the receiver has a literal text form recognized by the compiler."

	^false!

printOn: aStream 
	"Append to the argument aStream a sequence of characters that identifies the receiver."

	| title |
	title _ self class name.
	aStream nextPutAll: ((title at: 1) isVowel
							ifTrue: ['an ']
							ifFalse: ['a '])
						, title!

printString
	"Answer a String whose characters are a description of the receiver."

	| aStream |
	aStream _ WriteStream on: (String new: 16).
	self printOn: aStream.
	^aStream contents!

showOn: oo
	"/summarize myself onto the stream."

	self printOn: oo!

storeOn: aStream 
	"Append to the argument aStream a sequence of characters that is an expression 
	whose evaluation creates an object similar to the receiver.  The general format
	for objects is
		(class-name basicNew 
			instVarAt: index put: variable;
			basicAt: index put: element;
			yourself)
	or
		((class-name basicNew: size )
			instVarAt: index put: variable;
			basicAt: index put: element;
			yourself) "

	aStream nextPut: $(.
	self class isVariable
		ifTrue: [aStream nextPutAll: '(', self class name, ' basicNew: ';
					store: self basicSize;
					nextPutAll: ') ']
		ifFalse: [aStream nextPutAll: self class name, ' basicNew'].
	1 to: self class instSize do:
		[:i |
		aStream nextPutAll: ' instVarAt: ';
			store: i;
			nextPutAll: ' put: ';
			store: (self instVarAt: i);
			nextPut: $;].
	1 to: self basicSize do:
		[:i |
		aStream nextPutAll: ' basicAt: ';
			store: i;
			nextPutAll: ' put: ';
			store: (self basicAt: i);
			nextPut: $;].
	aStream nextPutAll: ' yourself)'!

storeString
	"Answer a String representation of the receiver from which the receiver
	can be reconstructed."

	| aStream |
	aStream _ WriteStream on: (String new: 16).
	self storeOn: aStream.
	^aStream contents! !

!Object methodsFor: 'class membership'!

changeClassToThatOf: anObject 
	"Change the class of the receiver to the class of anObject. Fail if	the 
	receiver is immediate, if anObject is immediate, or if none of the 
	following cases holds: 
	1. The receiver and anObject are both byte-type. 
	2. The receiver is any pointer-type object, anObject is a 
	non-indexable pointer-type object, and the storage sizes (i.e. the 
	number of named instance variables plus the number of indexed 
	instance variables, if any) of the two objects are the same. 
	3. The receiver is any pointer-type object, anObject is an indexable 
	pointer-type object, and the storage size of the receiver is at least 
	as large as the number of named instance variables of anObject. 
	The reason for specifying the primitive this way, rather than in the 
	more obvious way (changeClassTo: aBehavior), is that the obvious 
	specification would require a lot of tests in the VM as to whether 
	the argument was, in fact, a legal Behavior."

	<primitive: 535>
	self primitiveFailed!

class
	"Answer the object which is the receiver's class. Essential.  See 
	documentation in Object metaclass."

	<primitive: 111>
	self primitiveFailed!

isKindOf: aClass 
	"Answer a Boolean as to whether the class, aClass, is a superclass or class of
	the receiver."

	self class == aClass
		ifTrue: [^true]
		ifFalse: [^self class inheritsFrom: aClass]!

isMemberOf: aClass 
	"Answer a Boolean as to whether the receiver is an instance of the class, aClass."

	^self class == aClass!

respondsTo: aSymbol 
	"Answer a Boolean as to whether the method dictionary of the receiver's class 
	contains aSymbol as a message selector."

	^self class canUnderstand: aSymbol! !

!Object methodsFor: 'message handling'!

perform: aSymbol 
	"Send the receiver the unary message indicated by the argument. The argument is 
	the selector of the message. Invoke messageNotUnderstood: if the number of 
	arguments expected by the selector is not zero. Optional. See documentation
	in Object metaclass."

	<primitive: 511>
	^self perform: aSymbol withArguments: (Array new: 0)!

perform: aSymbol with: anObject 
	"Send the receiver the keyword message indicated by the arguments. The first 
	argument is the selector of the message. The other argument is the 
	argument of the message to be sent. Invoke messageNotUnderstood: if the 
	number of arguments expected by the selector is not one. Optional. See 
	documentation in Object metaclass."

	<primitive: 512>
	^self perform: aSymbol withArguments: (Array with: anObject)!

perform: aSymbol with: firstObject with: secondObject 
	"Send the receiver the keyword message indicated by the arguments. The first 
	argument is the selector of the message. The other arguments are the 
	arguments of the message to be sent. Invoke messageNotUnderstood: if 
	the number of arguments expected by the selector is not two. Optional. 
	See documentation in Object metaclass."

	<primitive: 513>
	^self perform: aSymbol withArguments: (Array with: firstObject with: secondObject)!

perform: aSymbol with: firstObject with: secondObject with: thirdObject 
	"Send the receiver the keyword message indicated by the arguments. The first 
	argument is the selector of the message. The other arguments are the 
	arguments of the message to be sent. Invoke messageNotUnderstood: if 
	the number of arguments expected by the selector is not three. Optional. 
	See documentation in Object metaclass."

	<primitive: 514>
	^self perform: aSymbol withArguments: (Array
			with: firstObject
			with: secondObject
			with: thirdObject)!

perform: selector withArguments: anArray 
	"Send the receiver the keyword message indicated by the arguments. The argument  
	selector is the selector of the message. The arguments of the message are the 
	elements of anArray. Invoke messageNotUnderstood: if the number of 
	arguments expected by the selector is not the same as the length of 
	anArray. Essential. See documentation in Object metaclass."

	<primitive: 510>
	self primitiveFailed! !

!Object methodsFor: 'error handling'!

assert
	"This only succeeds for True.  Bring up an error window."

	self error: 'Assertion failed.'!

assert: string
	"This only succeeds for True.  Bring up an error window."

	self halt: 'Assertion failed: ' , string!

confirm: aString 
	"Create and start up a BinaryChoice menu with the argument as the message in order
	to determine true or false.  Answers true or false."
	^ActionMenu confirm: aString!

deepCopyError
	"Think of this message as a specialization of shouldNotImplement; that
	is, it is sent by implementors of #deepCopy so that Object>>deepCopy
	can catch it."

	^DeepCopyErrorSignal raiseRequestWith: self!

doesNotUnderstand: aMessage 
	"The default behavior is to create a Notifier containing the 
	appropriate message and to allow the user to open a Debugger. 
	Subclasses can override this message in order to modify this behavior."

	Object messageNotUnderstoodSignal
		raiseRequestWith: aMessage
		errorString: 'Message not understood: ' , aMessage selector.
	^self perform: aMessage selector withArguments: aMessage arguments

	"3 font."!

error: aString 
	"Raise a non-proceedable signal that indicates an error with the argument as the message.
	This additional message is the one a subclass should override in order to
	change the handling of errors.
	Remove any trailing spaces from aString, since we know we don't
	want other strings appended to this one."

	| lastNonSpace |
	lastNonSpace _ aString findLast: [:ch | ch ~= Character space].
	^self errorSignal raiseErrorString: (aString copyFrom: 1 to: lastNonSpace)

	"nil error: 'error message'."!

errorSignal
	"Answer the Signal used for miscellaneous errors
	(self error:)."
	^self class errorSignal!

halt
	"This is a simple message to use for inserting breakpoints during debugging.
	The debugger is opened by raising a signal. This gives a chance to restore
	invariants related to multiple processes."

	Object haltSignal 
				raiseRequestWith: thisContext
				errorString: 'Halt encountered.'

	"nil halt."!

halt: aString 
	"This message can be used for inserting breakpoints during debugging.
	It creates and schedules a Debugger with the argument, aString, as 
	the label. The debugger is opened by raising a signal. This gives a chance
	to restore invariants related to multiple processes."

	Object haltSignal 
				raiseRequestWith: thisContext
				errorString: aString

	"nil halt: 'Test of halt:.'."!

notify: aString
	"Raise a proceedable signal with the argument as the message in order
	to request confirmation before a process can proceed."

	^Object notifySignal
				raiseRequestWith: thisContext
				errorString: aString

	"nil notify: 'confirmation message'."!

primitiveFailed
	"Announce that a primitive has failed and there is no appropriate 
	Smalltalk code to run."

	self error: 'a primitive has failed'!

shouldNotImplement
	"Announce that although the receiver inherits this message, it
	should not implement it."

	self error: 'This message is not appropriate for this object'!

subclassResponsibility
	"This message sets up a framework for the behavior of the class' subclasses.
	Raise a signal indicates that the subclass should have implemented this message."

	^Object subclassResponsibilitySignal 
				raiseErrorString: 'My subclass should have overridden one of my messages.'! !

!Object methodsFor: 'changing'!

broadcast: aSymbol 
	"Send the argument, aSymbol, as a unary message to all of the receiver's dependents."

	self myDependents performUpdate: aSymbol!

broadcast: aSymbol with: anObject 
	"Send the argument, aSymbol, as a keyword message with argument anObject to
	all of the receiver's dependents."

	self myDependents performUpdate: aSymbol with: anObject!

changed
	"Receiver changed in a general way; inform all the dependents by sending 
	each dependent an update: message."

	self changed: nil!

changed: anAspectSymbol 
	"Receiver changed.  The change is denoted by the argument anAspectSymbol.  Usually the argument is a Symbol that is part of the dependent's change protocol, that is, some aspect of the object's behavior.  Inform all of the dependents."

	self changed: anAspectSymbol with: nil!

changed: anAspectSymbol with: aParameter
	"The receiver changed.  The change is denoted by the argument anAspectSymbol.  Usually the argument is a Symbol that is part of the dependent's change protocol, that is, some aspect of the object's behavior, and aParameter is additional information.  Inform all of the dependents."

	self myDependents update: anAspectSymbol with: aParameter from: self!

changeRequest
	"The receiver wants to change; check with all dependents that it is OK."

	^self myDependents updateRequest!

changeRequest: anAspectSymbol 
	"The receiver wants to change this aspect; check with all dependents that it is OK."

	^self myDependents updateRequest: anAspectSymbol!

changeRequestFrom: aRequestorObject 
	"Receiver wants to change; check with all dependents (other than 
	requestor) that it is OK."

	self dependents do:
		[:aDependent | 
			(aDependent == aRequestorObject or: [aDependent updateRequest])
				ifFalse: [^false]].
	^true! !

!Object methodsFor: 'user interface'!

{NO_RETURN} audition
	ScreenPlay openOn: self!

{NO_RETURN} audition: startString {String}
	ScreenPlay openOn: self with: startString!

basicInspect
	"Create and schedule an Inspector in which the user can examine the
	receiver's variables.  This method should not be overwritten."

	InspectorView open: (Inspector inspect: self)!

browse
	"Create and schedule a system class browser on the class of the object."

	Browser newOnClass: self class!

browseHierarchy
	"Create and schedule a hierarchy browser on the class of the object."

	(Browser new onClass: self class) spawnHierarchy!

inspect
	"Create and schedule an Inspector in which the user can examine the
	receiver's variables."

	self basicInspect! !

!Object methodsFor: 'system primitives'!

allOwners
	| owners next |
	owners _ OrderedCollection new.
	next _ self firstOwner.
	[next ~~ nil] whileTrue: 
		[(next ~~ owners
			and: [(next isKindOf: Context) not 
			and: [(next isKindOf: Array) not]])
			ifTrue: [owners add: next].
		next _ self ownerAfter: next].
	^owners!

asOop
	"Answer an Integer which is 'unique' to me.  From V2.4
	on, not guaranteed to be unique"

	^self identityHash!

become: otherObject 
	"Swap the instance pointers of the receiver and the argument, otherObject.  All
	variables in the entire system that used to point to the receiver now point to the
	argument, and vice-versa.  Fail if either object is a SmallInteger.  Answer with the
	argument which is now the same instance pointer that formerly denoted the receiver. 
	Essential.  See documentation in Object metaclass."

	<primitive: 72>
	self primitiveFailed!

byteCount
	"return the number of bytes that I occupy"
	"See the Checker class for the following size calculation:"
	
	| nBytes |
	nBytes _ (self class instSize * 4) + 6. "+ 6 for header"
	self class isVariable
		ifTrue: [nBytes _ nBytes + (self class isPointers
			ifTrue: [self basicSize * 4]
			ifFalse: [self class isBits
				ifTrue: [((self basicSize + 1) // 2) * 2]
				ifFalse: [self basicSize * 2]])].
	^ nBytes!

{Array of: IntegerVar and: IntegerVar} deepByteCount
	
	| scanned |
	scanned _ IdentitySet new: 1000.
	^ Array with: (self deepByteCount: scanned) with: scanned size!

{IntegerVar} deepByteCount: scannedSet {IdentitySet} 
	| nBytes |
	(scannedSet includes: self) ifTrue: [^0].
	scannedSet add: self.
	nBytes _ self byteCount.
	self isBehavior ifTrue: [^ nBytes].
	1 to: self class instSize do: [:i | nBytes _ nBytes + ((self instVarAt: i) deepByteCount: scannedSet)].
	self class isVariable
		ifTrue: [self class isPointers not ifTrue: [^nBytes].
			1 to: self basicSize do: [:i | nBytes _ nBytes + ((self basicAt: i) deepByteCount: scannedSet)]].
	^nBytes!

firstOwner
	"Answer some object which points at self.  This primitive can be used with 'ownerAfter: '
	 to enumerate all the objects which point at self.
	 For example see SystemDictionary>quickPointersTo:do:.
	 Optional.  See also documentation in Object metaclass."

	<primitive: 197>
	^nil!

instVarAt: index 
	"Answer with a fixed variable in an object.  The numbering of the variables 
	corresponds to the named instance variables.  Fail if the index is not an 
	Integer or is not the index of a fixed variable.  Essential.  See documentation in 
	Object metaclass."

	<primitive: 73>
	"Access beyond fixed variables."
	^self basicAt: index - self class instSize!

instVarAt: anInteger put: anObject 
	"Store a value into a fixed variable in the receiver.  The numbering of  
	the variables corresponds to the named instance variables.  Fail if   
	the index is not an Integer or is not the index of a fixed variable.    
	Answer with the value stored as the result.  (Using this message 
	violates the principle that each object has sovereign control over the 
	storing of values into its instance variables.)  Essential.  See documentation 
	in Object metaclass. "

	<primitive: 74>
	"Access beyond fixed fields"
	^self basicAt: anInteger - self class instSize put: anObject!

nextInstance
	"Answer with the next instance after the receiver in the enumeration 
	 of all instances of this class.  Fail if all instances have been 
	enumerated.  Essential.  See documentation in Object metaclass."

	<primitive: 78>
	^nil!

nextObject
	"Answer with the next object following the receiver in 
	the enumeration of all non-immediate objects. Fail if there is no such 
	object or if the receiver is an immediate object. See Object class 
	someObject. Essential. See documentation in Object metaclass."

	<primitive: 531>
	^0!

ownerAfter: anObject
	"Answer the next object after anObject which points at self (in some hidden ordering).
	 This primitive can be used with 'firstOwner' to enumerate all the objects which point at self.
	 For example see SystemDictionary>quickPointersTo:do:.
	 Optional.  See also documentation in Object metaclass. "

	<primitive: 198>
	^nil!

refCt
	"Answer my reference count."

	<primitive: 134>
	^nil! !

!Object methodsFor: 'system simulation'!

tryPrimitive0
	"Warning!!!! This is not a real primitive.  This method is a template that the 
	Smalltalk simulator uses to execute primitives with no arguments.  See 
	Context doPrimitive:receiver:numArgs:."

	<primitive: 007>
	^Context primitiveFailedSignal raise!

tryPrimitive1: arg1 
	"Warning!!!! This is not a real primitive.  This method is a template that the 
	Smalltalk simulator uses execute primitives with one argument.  See 
	Context doPrimitive:receiver:numArgs:."

	<primitive: 007>
	^Context primitiveFailedSignal raise!

tryPrimitive2: arg1 with: arg2 
	"Warning!!!! This is not a real primitive.  This method is a template that the 
	Smalltalk simulator uses execute primitives with two arguments.  See 
	Context doPrimitive:receiver:numArgs:."

	<primitive: 007>
	^Context primitiveFailedSignal raise!

tryPrimitive3: arg1 with: arg2 with: arg3 
	"Warning!!!! This is not a real primitive.  This method is a template that the 
	Smalltalk simulator uses execute primitives with three arguments.  See 
	Context doPrimitive:receiver:numArgs:."

	<primitive: 007>
	^Context primitiveFailedSignal raise!

tryPrimitive4: arg1 with: arg2 with: arg3 with: arg4 
	"Warning!!!! This is not a real primitive.  This method is a template that the 
	Smalltalk simulator uses execute primitives with four arguments.  See 
	Context doPrimitive:receiver:numArgs:."

	<primitive: 007>
	^Context primitiveFailedSignal raise! !

!Object methodsFor: 'dependents collection'!

asDependentsAsCollection
	"Answer the receiver, considered as a
	collection of dependents, as a real
	Collection.  Since the receiver represents
	a singleton dependents collection,
	answer a Collection containing only
	the receiver. "

	^Array with: self!

asDependentsWith: anObject
	"Answer the receiver, considered as a
	collection of dependents, with anObject
	added.  Since the receiver represents
	a singleton dependents collection,
	answer a Collection containing the
	receiver and anObject. "

	^DependentsCollection with: self with: anObject!

asDependentsWithout: anObject
	"Answer the receiver, considered as a
	collection of dependents, with the first
	occurrence of anObject (if any) removed.
	If anObject does not occur in the receiver,
	answer the receiver. "
	" Since the receiver represents a
	singleton dependents collection, answer
	either the receiver or nil. "

	^anObject == self
		ifTrue: [nil]
		ifFalse: [self]! !

!Object methodsFor: 'fileIn/Out'!

storeBinaryOn: stream
	" Put a binary representation of the receiver into stream.
	WARNING: if you reimplement this message in some class,
	you will probably have to reimplement it again in every
	subclass that adds any instance variables: otherwise,
	the instance information in the subclass will not get written!! "

	stream storeOther: self! !

!Object methodsFor: 'private: private'!

breakDependents
	"Deallocate the soft field for the receiver's dependents."

	DependentsFields removeKey: self ifAbsent: []!

forkEmergencyEvaluatorAt: priority
	"Fork a process running a simple Smalltalk evaluator using as little of the system as possible.  Used for desperate debugging.  may be invoked by control-shift-C."

	| stream char |
		[Display white: (0@0 extent: 1024@36).
		'EMERGENCY EVALUATOR (priority ', priority printString, ') -- type an expression terminated by ESC' displayAt: 50@0.
		Display reverse: (0@0 extent: 1024@36).
		stream _ WriteStream on: String new.
		[[Sensor keyboardPressed] whileFalse.
		(char _ Sensor keyboard) = Character esc] whileFalse:
			[char = Character backspace
				ifTrue: [stream position > 0
							ifTrue: [stream skip: -1.  Display black: (0@18 extent: 1024@18)]]
				ifFalse: [stream nextPut: char].
			stream contents displayAt: 50@18].
		Display black: (0@0 extent: 1024@18).
		(self class compilerClass evaluate: stream contents) printString displayAt: 50@0] forkAt: priority!

improperStoreError
	"Create an error notification that an improper store was attempted."

	self error: 'Improper store into indexable object'!

mustBeBoolean
	"Catches attempts to test truth of non-Booleans.  This message is sent from the
	interpreter."

	self error: 'NonBoolean receiver--proceed for truth.'.
	^true!

myDependents
	"Answer the receivers dependents or nil."

	^DependentsFields atOrNil: self!

nilFields
	"Store nil into all pointer fields of the receiver."

	self class isPointers ifFalse: [^self].
	1 to: self basicSize do:
		[:index | self basicAt: index put: nil].
	1 to: self class instSize do:
		[:index | self instVarAt: index put: nil].!

nonIntegerIndexError: index
	"Raise a signal indicating that an improper object was used as an index."

	^Object nonIntegerIndexSignal raiseWith: index!

notFoundError
	"Raise a signal indicating that an element was not found."

	^Object notFoundSignal raise!

primitiveError: aString 
	"This method is called when the error handling results in a recursion in calling
	on error: or halt or halt:."

	| context key |
	Transcript cr.
	Transcript show: '**System Error Handling Failed** '.
	Transcript show: aString.
	Transcript cr.
	context _ thisContext sender sender.
	3 timesRepeat: 
		[context == nil ifFalse: [Transcript print: (context _ context sender); cr]].

	[Transcript show: '**type <s> for more stack; anything else restarts scheduler**'.
	Transcript cr.
	key _ Sensor keyboard.
	key = $s | (key = $S)] 
		whileTrue: 
			[5 timesRepeat: 
				[context == nil 
					ifFalse: [Transcript print: (context _ context sender); cr]]].
	ScheduledControllers searchForActiveController!

setDependents
	"Allocate the soft field for the receiver's dependents."
	| dependents |
	dependents _ OrderedCollection new.
	DependentsFields add: (Association key: self value: dependents).
	^ dependents!

species
	"Answer the preferred class for reconstructing the receiver.  For example, 
	collections create new collections whenever enumeration messages such as 
	collect: or select: are invoked.  The new kind of collection is determined by 
	the species of the original collection.  Species and class are not always the 
	same.  For example, the species of Interval is Array."

	^self class!

subscriptBoundsError: index 
	"Raise a signal indicating that an improper integer was used as an index."

	^Object subscriptOutOfBoundsSignal raiseWith: index! !

!Object methodsFor: 'cxx extensions'!

basicCast: type 
	"This only works for simple types (else the Smalltalk syntax breaks 
	down).  This one doesn't do any checks in smalltalk."

	^ self!

cast: type 
	"This only works for simple types (else the Smalltalk syntax breaks 
	down)."

	self getCategory == type ifFalse: 
		[(self getCategory inheritsFrom: type)
			ifFalse: [self error: 'Cast violation: ' , type printString]]!

cast: type1 {Category} into: b1 {Block} 
	"Conditional dispatch based on type.  Execute the first block from whose associated type the receiver inherits."
	"This only works for simple types (else the Smalltalk syntax breaks down)."

	| cat |
	((cat _ self getCategory) == type1 or: [type1 isSuperTo: cat])
		ifTrue: [b1 value: self]
		ifFalse: [self unkindError]!

cast: type1 {Category} into: b1 {Block}
cast: type2 {Category} into: b2 {Block} 
	"Conditional dispatch based on type.  Execute the first block from whose associated type the receiver inherits."
	"This only works for simple types (else the Smalltalk syntax breaks down)."

	| cat |
	cat _ self getCategory.
	(cat == type1 or: [type1 isSuperTo: cat]) ifTrue: [b1 value: self]
	ifFalse: [(cat == type2 or: [type2 isSuperTo: cat]) ifTrue: [b2 value: self]
	ifFalse: [self unkindError]]!

cast: type1 {Category} into: b1 {Block}
cast: type2 {Category} into: b2 {Block} 
cast: type3 {Category} into: b3 {Block}
	"Conditional dispatch based on type.  Execute the first block from whose associated type the receiver inherits."
	"This only works for simple types (else the Smalltalk syntax breaks down)."

	| cat |
	cat _ self getCategory.
	(cat == type1 or: [type1 isSuperTo: cat]) ifTrue: [b1 value: self]
	ifFalse: [(cat == type2 or: [type2 isSuperTo: cat]) ifTrue: [b2 value: self]
	ifFalse: [(cat == type3 or: [type3 isSuperTo: cat]) ifTrue: [b3 value: self]
	ifFalse: [self unkindError]]]!

cast: type1 {Category} into: b1 {Block}
cast: type2 {Category} into: b2 {Block} 
cast: type3 {Category} into: b3 {Block}
cast: type4 {Category} into: b4 {Block} 
	"Conditional dispatch based on type.  Execute the first block from whose associated type the receiver inherits."
	"This only works for simple types (else the Smalltalk syntax breaks down)."

	| cat |
	cat _ self getCategory.
	(cat == type1 or: [type1 isSuperTo: cat]) ifTrue: [b1 value: self]
	ifFalse: [(cat == type2 or: [type2 isSuperTo: cat]) ifTrue: [b2 value: self]
	ifFalse: [(cat == type3 or: [type3 isSuperTo: cat]) ifTrue: [b3 value: self]
	ifFalse: [(cat == type4 or: [type4 isSuperTo: cat]) ifTrue: [b4 value: self]
	ifFalse: [self unkindError]]]]!

cast: type1 {Category} into: b1 {Block}
cast: type2 {Category} into: b2 {Block} 
cast: type3 {Category} into: b3 {Block}
cast: type4 {Category} into: b4 {Block} 
cast: type5 {Category} into: b5 {Block}
	"Conditional dispatch based on type.  Execute the first block from whose associated type the receiver inherits."
	"This only works for simple types (else the Smalltalk syntax breaks down)."

	| cat |
	cat _ self getCategory.
	(cat == type1 or: [type1 isSuperTo: cat]) ifTrue: [b1 value: self]
	ifFalse: [(cat == type2 or: [type2 isSuperTo: cat]) ifTrue: [b2 value: self]
	ifFalse: [(cat == type3 or: [type3 isSuperTo: cat]) ifTrue: [b3 value: self]
	ifFalse: [(cat == type4 or: [type4 isSuperTo: cat]) ifTrue: [b4 value: self]
	ifFalse: [(cat == type5 or: [type5 isSuperTo: cat]) ifTrue: [b5 value: self]
	ifFalse: [self unkindError]]]]]!

cast: type1 {Category} into: b1 {Block}
cast: type2 {Category} into: b2 {Block} 
cast: type3 {Category} into: b3 {Block}
cast: type4 {Category} into: b4 {Block} 
cast: type5 {Category} into: b5 {Block}
cast: type6 {Category} into: b6 {Block} 
	"Conditional dispatch based on type.  Execute the first block from whose associated type the receiver inherits."
	"This only works for simple types (else the Smalltalk syntax breaks down)."

	| cat |
	cat _ self getCategory.
	(cat == type1 or: [type1 isSuperTo: cat]) ifTrue: [b1 value: self]
	ifFalse: [(cat == type2 or: [type2 isSuperTo: cat]) ifTrue: [b2 value: self]
	ifFalse: [(cat == type3 or: [type3 isSuperTo: cat]) ifTrue: [b3 value: self]
	ifFalse: [(cat == type4 or: [type4 isSuperTo: cat]) ifTrue: [b4 value: self]
	ifFalse: [(cat == type5 or: [type5 isSuperTo: cat]) ifTrue: [b5 value: self]
	ifFalse: [(cat == type6 or: [type6 isSuperTo: cat]) ifTrue: [b6 value: self]
	ifFalse: [self unkindError]]]]]]!

cast: type1 {Category} into: b1 {Block}
cast: type2 {Category} into: b2 {Block} 
cast: type3 {Category} into: b3 {Block}
cast: type4 {Category} into: b4 {Block} 
cast: type5 {Category} into: b5 {Block}
cast: type6 {Category} into: b6 {Block}
others: elseB {Block}
	"Conditional dispatch based on type.  Execute the first block from whose associated type the receiver inherits."
	"This only works for simple types (else the Smalltalk syntax breaks down)."

	| cat |
	cat _ self getCategory.
	(cat == type1 or: [type1 isSuperTo: cat]) ifTrue: [b1 value: self]
	ifFalse: [(cat == type2 or: [type2 isSuperTo: cat]) ifTrue: [b2 value: self]
	ifFalse: [(cat == type3 or: [type3 isSuperTo: cat]) ifTrue: [b3 value: self]
	ifFalse: [(cat == type4 or: [type4 isSuperTo: cat]) ifTrue: [b4 value: self]
	ifFalse: [(cat == type5 or: [type5 isSuperTo: cat]) ifTrue: [b5 value: self]
	ifFalse: [(cat == type6 or: [type6 isSuperTo: cat]) ifTrue: [b6 value: self]
	ifFalse: [elseB value]]]]]]!

cast: type1 {Category} into: b1 {Block}
cast: type2 {Category} into: b2 {Block} 
cast: type3 {Category} into: b3 {Block}
cast: type4 {Category} into: b4 {Block} 
cast: type5 {Category} into: b5 {Block}
others: elseB {Block}
	"Conditional dispatch based on type.  Execute the first block from whose associated type the receiver inherits."
	"This only works for simple types (else the Smalltalk syntax breaks down)."

	| cat |
	cat _ self getCategory.
	(cat == type1 or: [type1 isSuperTo: cat]) ifTrue: [b1 value: self]
	ifFalse: [(cat == type2 or: [type2 isSuperTo: cat]) ifTrue: [b2 value: self]
	ifFalse: [(cat == type3 or: [type3 isSuperTo: cat]) ifTrue: [b3 value: self]
	ifFalse: [(cat == type4 or: [type4 isSuperTo: cat]) ifTrue: [b4 value: self]
	ifFalse: [(cat == type5 or: [type5 isSuperTo: cat]) ifTrue: [b5 value: self]
	ifFalse: [elseB value]]]]]!

cast: type1 {Category} into: b1 {Block}
cast: type2 {Category} into: b2 {Block} 
cast: type3 {Category} into: b3 {Block}
cast: type4 {Category} into: b4 {Block} 
others: elseB {Block}
	"Conditional dispatch based on type.  Execute the first block from whose associated type the receiver inherits."
	"This only works for simple types (else the Smalltalk syntax breaks down)."

	| cat |
	cat _ self getCategory.
	(cat == type1 or: [type1 isSuperTo: cat]) ifTrue: [b1 value: self]
	ifFalse: [(cat == type2 or: [type2 isSuperTo: cat]) ifTrue: [b2 value: self]
	ifFalse: [(cat == type3 or: [type3 isSuperTo: cat]) ifTrue: [b3 value: self]
	ifFalse: [(cat == type4 or: [type4 isSuperTo: cat]) ifTrue: [b4 value: self]
	ifFalse: [elseB value]]]]!

cast: type1 {Category} into: b1 {Block}
cast: type2 {Category} into: b2 {Block} 
cast: type3 {Category} into: b3 {Block}
others: elseB {Block}
	"Conditional dispatch based on type.  Execute the first block from whose associated type the receiver inherits."
	"This only works for simple types (else the Smalltalk syntax breaks down)."

	| cat |
	cat _ self getCategory.
	(cat == type1 or: [type1 isSuperTo: cat]) ifTrue: [b1 value: self]
	ifFalse: [(cat == type2 or: [type2 isSuperTo: cat]) ifTrue: [b2 value: self]
	ifFalse: [(cat == type3 or: [type3 isSuperTo: cat]) ifTrue: [b3 value: self]
	ifFalse: [elseB value]]]!

cast: type1 {Category} into: b1 {Block}
cast: type2 {Category} into: b2 {Block} 
others: elseB {Block}
	"Conditional dispatch based on type.  Execute the first block from whose associated type the receiver inherits."
	"This only works for simple types (else the Smalltalk syntax breaks down)."

	| cat |
	cat _ self getCategory.
	(cat == type1 or: [type1 isSuperTo: cat]) ifTrue: [b1 value: self]
	ifFalse: [(cat == type2 or: [type2 isSuperTo: cat]) ifTrue: [b2 value: self]
	ifFalse: [elseB value]]!

cast: type1 {Category} into: b1 {Block} others: elseB {Block}
	"Conditional dispatch based on type.  Execute the first block from whose associated type the receiver inherits."
	"This only works for simple types (else the Smalltalk syntax breaks down)."

	| cat |
	((cat _ self getCategory) == type1 or: [type1 isSuperTo: cat]) ifTrue: [b1 value: self]
	ifFalse: [elseB value]!

create
	"this is in place of Tofu's constructor"!

delete
	"This is the destructor."!

destroy!

{Category} getCategory
	
	^self class!

hack!

hashForEqual
	self hack.
	^self hash!

{BooleanVar} isByProxy
	^false!

isEqual: other
	self hack.
	^self = other!

knownBug
	"mark places where there is a known bug.  Like thingToDo but more immediate."
	
	self thingToDo.		"Look for senders of 'knownBug' as well."!

{void} markInstances: count {IntegerVar}
	"Object marking stops at objects which are not subclasses of heaper."!

notNil: nonNilBlock {Block}
	"Execute nonNilBlock with the receiver as an argument if the receiver is non-nil."
	"The nil case is handled in the class that defines nil."

	^nonNilBlock value: self!

notNil: nonNilBlock {Block} else: elseB {Block}
	"Execute nonNilBlock with the receiver as an argument if the receiver is
	 non-nil.  If the receiver is NULL, then execute the else block."
	"The nil case is handled in the class that defines nil."

	^nonNilBlock value: self!

notNULL: nonNULLBlock {Block}
	"Execute nonNULLBlock with the receiver as an argument if the receiver is non-null."
	"The null case is handled in the class that defines null."

	nonNULLBlock value: self!

notNULL: nonNULLBlock {Block} else: elseB {Block}
	"Execute nonNULLBlock with the receiver as an argument if the receiver is
	 non-null.  If the receiver is NULL, then execute the else block."
	"The null case is handled in the class that defines null."

	nonNULLBlock value: self!

passe
	self error: 'tried to use an obsolete protocol'!

{Behavior} publicClass
	"A lot like species.  Only a temporary kludge until ScreenPlay knows about type declarations"
	
	| result {Behavior} |
	result _ self class.
	[result getOrMakeCxxClassDescription visibility = #private]
		whileTrue: [result _ result superclass].
	^result!

quickCast: type 
	"This only works for simple types (else the Smalltalk syntax breaks 
	down).  This one doesn't do any checks in smalltalk."!

shouldImplement
	"Announce that although the receiver inherits this message, it
	will not implement it."

	self halt: 'Somebody ought to do something about this...'!

thingToDo
	"mark places where there is still stuff to be done.  See also 'knownBug'"!

{void} unkindError
	"Error message to send when a cast:into: (ST for 'CHOOSE()') fails because the cast wasn't into any matching type, and the fallthrough case didn't exist.
	This is in a single place so that we can change it when we straighten out signals."
	
	Heaper BLAST: #'VALUE_IS_UNKIND'!

update: updateRecord from: sender!

warn: aString
	Transcript show: aString; cr!

willNotImplement
	"Announce that although the receiver inherits this message, it
	will not implement it."

	self error: 'This message is appropriate for this object but is unreasonable to implement'! !

!Object methodsFor: 'literals'!

{Set of: Symbol} literalSymbols
	^Set new! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

Object class
	instanceVariableNames: ''!


!Object class methodsFor: 'class initialization'!

initialize 
	"Reset all the dependents of all objects."

	"Object initialize"

	(self confirm: 'Do you really want to initialize
class Object?  It will reset all dependents.')
		ifTrue:
			[self initializeDependentsFields.
			self initializeErrorRecursion.
			self initSignals]!

initSignals
	"Initialize global signals."

	| es |
	es _ self errorSignal.
	InformationSignal _ Signal genericSignal newSignal 
		notifierString: 'Information - ';
		nameClass: self message: #informationSignal.
	UserInterruptSignal _ InformationSignal newSignal 
		notifierString: 'User Interrupt';
		nameClass: self message: #userInterruptSignal.
	HaltSignal _ UserInterruptSignal newSignal 
		notifierString: 'Halt ';
		nameClass: self message: #haltSignal.
	NotifySignal _ UserInterruptSignal newSignal 
		notifierString: 'Notifier ';
		nameClass: self message: #notifySignal.
	NotFoundSignal  _ es newSignal 
		notifierString: 'Element not Found';
		nameClass: self message: #notFoundSignal.
	IndexNotFoundSignal  _ NotFoundSignal newSignal 
		notifierString: 'Index not found';
		nameClass: self message: #indexNotFoundSignal.
	SubscriptOutOfBoundsSignal _ IndexNotFoundSignal newSignal 
		notifierString: 'Subscript out of bounds: ';
		nameClass: self message: #subscriptOutOfBoundsSignal.
	NonIntegerIndexSignal _ IndexNotFoundSignal newSignal 
		notifierString: 'Non integer index: ';
		nameClass: self message: #nonIntegerIndexSignal.
	SubclassResponsibilitySignal _ es newSignal 
		notifierString: 'Subclass responsibility ';
		nameClass: self message: #subclassResponsibilitySignal.
	DeepCopyErrorSignal _ es newSignal	"this is private to #deepCopy & #deepCopyError"
		notifierString: 'object can''t be deepCopy-ed'.
	MessageNotUnderstoodSignal _ es newSignal 
		notifierString: 'Message not understood ';
		nameClass: self message: #messageNotUnderstoodSignal.! !

!Object class methodsFor: 'instance creation'!

readFrom: aStream
	"Create an object based on the contents of aStream."

	| object |
	object _ self evaluatorClass evaluate: aStream.
	(object isKindOf: self) ifFalse: [self error: self name, ' expected'].
	^object! !

!Object class methodsFor: 'documentation'!

howToModifyPrimitives
	"You are allowed to write methods which specify primitives, but please use 
	caution.  If you make a subclass of a class which contains a primitive method, 
	the subclass inherits the primitive.  The message which is implemented 
	primitively may be overridden in the subclass (E.g., see at:put: in String's 
	subclass Symbol).  The primitive behavior can be invoked using super (see 
	Symbol string:). 
	 
	A class which attempts to mimic the behavior of another class without being 
	its subclass may or may not be able to use the primitives of the original class.  
	In general, if the instance variables read or written by a primitive have the 
	same meanings and are in the same fields in both classes, the primitive will 
	work.  

	For certain frequently used 'special selectors', the compiler emits a 
	send-special-selector bytecode instead of a send-message bytecode.  
	Special selectors were created because they offer two advantages.  Code 
	which sends special selectors compiles into fewer bytes than normal.  For 
	some pairs of receiver classes and special selectors, the interpreter jumps 
	directly to a primitive routine without looking up the method in the class.  
	This is much faster than a normal message lookup. 
	 
	A selector which is a special selector solely in order to save space has a 
	normal behavior.  Methods whose selectors are special in order to 
	gain speed contain the comment, 'No Lookup'.  When the interpreter 
	encounters a send-special-selector bytecode, it checks the class of the 
	receiver and the selector.  If the class-selector pair is a no-lookup pair, 
	then the interpreter swiftly jumps to the routine which implements the 
	corresponding primitive.  (A special selector whose receiver is not of the 
	right class to make a no-lookup pair, is looked up normally).  The pairs are 
	listed below.  No-lookup methods contain a primitive number specification, 
	<primitive: xx>, which is redundant.  Since the method is not normally looked 
	up, deleting the primitive number specification cannot prevent this 
	primitive from running.  If a no-lookup primitive fails, the method is looked 
	up normally, and the expressions in it are executed. 
	 
	No Lookup pairs of (class, selector) 
	 
	SmallInteger with any of		+ - * /  \\  bitOr: bitShift: bitAnd:  // 
	SmallInteger with any of		=  ~=  >  <  >=  <= 
	Any class with					== 
	Any class with 					@ 
	Point with either of				x y 
	ContextPart with					blockCopy: 
	BlockContext with either of 		value value:
	"

	self error: 'comment only'!

whatIsAPrimitive
	"Some messages in the system are responded to primitively. A primitive   
	response is performed directly by the interpreter rather than by evaluating   
	expressions in a method. The methods for these messages indicate the   
	presence of a primitive response by including <primitive: xx> before the   
	first expression in the method.   
	  
	Primitives exist for several reasons. Certain basic or 'primitive' 
	operations cannot be performed in any other way. Smalltalk without 
	primitives can move values from one variable to another, but cannot add two 
	SmallIntegers together. Many methods for arithmetic and comparison 
	between numbers are primitives. Some primitives allow Smalltalk to 
	communicate with I/O devices such as the disk, the display, and the keyboard. 
	Some primitives exist only to make the system run faster; each does the same 
	thing as a certain Smalltalk method, and its implementation as a primitive is 
	optional.  
	  
	When the Smalltalk interpreter begins to execute a method which specifies a 
	primitive response, it tries to perform the primitive action and to return a 
	result. If the routine in the interpreter for this primitive is successful, 
	it will return a value and the expressions in the method will not be evaluated. 
	If the primitive routine is not successful, the primitive 'fails', and the 
	Smalltalk expressions in the method are executed instead. These 
	expressions are evaluated as though the primitive routine had not been 
	called.  
	  
	The Smalltalk code that is evaluated when a primitive fails usually 
	anticipates why that primitive might fail. If the primitive is optional, the 
	expressions in the method do exactly what the primitive would have done (See 
	Number @). If the primitive only works on certain classes of arguments, the 
	Smalltalk code tries to coerce the argument or appeals to a superclass to find 
	a more general way of doing the operation (see SmallInteger +). If the 
	primitive is never supposed to fail, the expressions signal an error (see 
	SmallInteger asFloat).  
	  
	Each method that specifies a primitive has a comment in it. If the primitive is 
	optional, the comment will say 'Optional'. An optional primitive that is not 
	implemented always fails, and the Smalltalk expressions do the work 
	instead.  
	 
	If a primitive is not optional, the comment will say, 'Essential'. Some 
	methods will have the comment, 'No Lookup'. See Object 
	howToModifyPrimitives for an explanation of special selectors which are 
	not looked up.  
	  
	For the primitives for +, -, *, and bitShift: in SmallInteger, and truncated 
	in Float, the primitive constructs and returns a 16-bit 
	LargePositiveInteger when the result warrants it. Returning 16-bit 
	LargePositiveIntegers from these primitives instead of failing is 
	optional in the same sense that the LargePositiveInteger arithmetic 
	primitives are optional. The comments in the SmallInteger primitives say, 
	'Fails if result is not a SmallInteger', even though the implementor has the 
	option to construct a LargePositiveInteger. For further information on 
	primitives, see the 'Primitive Methods' part of the chapter on the formal 
	specification of the interpreter in the Smalltalk book."

	self error: 'comment only'! !

!Object class methodsFor: 'systemPrimitives'!

allObjects
	"Answer a WeakArray containing all objects that existed in the system prior to 
the invocation of this primitive. Fails if we cannot allocate a WeakArray large 
enough to contain all the objects in the system or if the WeakArray class does 
not exist."

	<primitive: 538>
	self primitiveFailed!

someObject
	"Answer with the first object in the enumeration of all non-immediate 
	objects. See Object nextObject. Essential. See Object documentation 
	whatIsAPrimitive."

	<primitive: 530>
	self primitiveFailed! !

!Object class methodsFor: 'Signal constants'!

errorSignal
	"Answer the Signal used for miscellaneous errors
	(self error:)."
	^ErrorSignal!

haltSignal

	^HaltSignal!

indexNotFoundSignal

	^IndexNotFoundSignal!

informationSignal

	^InformationSignal!

messageNotUnderstoodSignal

	^MessageNotUnderstoodSignal!

nonIntegerIndexSignal

	^NonIntegerIndexSignal!

notFoundSignal

	^NotFoundSignal!

notifySignal

	^NotifySignal!

subclassResponsibilitySignal

	^SubclassResponsibilitySignal!

subscriptOutOfBoundsSignal

	^SubscriptOutOfBoundsSignal!

userInterruptSignal

	^UserInterruptSignal! !

!Object class methodsFor: 'fileIn/Out'!

binaryStorageFormat
	" Answer an object (typically an integer)
	that identifies the format version that the
	receiver uses to store itself in binary form
	(storeBinaryOn:). "

	^1!

readBinaryFrom: stream tag: tag
	"Answer object appearing next in stream."

	| size newObject |
	self isVariable
		ifTrue:
			[size _ stream next.  "integer"
			newObject _ self basicNew: size]
		ifFalse:
			[newObject _ self basicNew].
	stream register: newObject id: tag.
	1 to: self instSize do:
		[:i | newObject instVarAt: i put: stream next].
	size == nil ifFalse:
		[1 to: size do:
			[:i | newObject basicAt: i put: stream next]].
	^newObject! !

!Object class methodsFor: 'private'!

initializeDependentsFields
	DependentsFields _ IdentityDictionary new: 4

	"Object initializeDependentsFields"!

initializeErrorRecursion
	ErrorRecursion _ false

	"Object initializeErrorRecursion"! !

!Object class methodsFor: 'cxx translation'!

create
	"Create the frame and call the constructor defined for instances."

	^self new create!

create.IntegerVar: arg1
	"Create the frame and call the constructor defined for instances."

	^self new create.IntegerVar: arg1!

{void} create.Rcvr: rcvr {Rcvr}
	^self new create.Rcvr: rcvr!

create: arg1
	"Create the frame and call the constructor defined for instances."

	^self new create: arg1!

create: arg1 with: arg2
	"Create the frame and call the constructor defined for instances."

	^self new create: arg1 with: arg2!

create: arg1 with: arg2 with: arg3
	"Create the frame and call the constructor defined for instances."

	^self new create: arg1 with: arg2 with: arg3!

create: arg1 with: arg2 with: arg3 with: arg4
	"Create the frame and call the constructor defined for instances."

	^self new create: arg1 with: arg2 with: arg3 with: arg4!

create: arg1 with: arg2 with: arg3 with: arg4 with: arg5
	"Create the frame and call the constructor defined for instances."

	^self new create: arg1 with: arg2 with: arg3 with: arg4 with: arg5!

create: arg1 with: arg2 with: arg3 with: arg4 with: arg5 with: arg6
	"Create the frame and call the constructor defined for instances."

	^self new create: arg1 with: arg2 with: arg3 with: arg4 with: arg5 with: arg6!

create: arg1 with: arg2 with: arg3 with: arg4 with: arg5 with: arg6 with: arg7
	"Create the frame and call the constructor defined for instances."

	^self new create: arg1 with: arg2 with: arg3 with: arg4 with: arg5 with: arg6 with: arg7!

create: arg1 with: arg2 with: arg3 with: arg4 with: arg5 with: arg6 with: arg7 with: arg8
	"Create the frame and call the constructor defined for instances."

	^self new create: arg1 with: arg2 with: arg3 with: arg4 with: arg5 with: arg6 with: arg7 with: arg8!

{Boolean} definesProxyMethods
	^ false!

{Boolean} isEqualOrSubclassOf: cat {Category}

	^ self == cat or: [self inheritsFrom: cat]!

mangle: foo!

vector
	"Return the Class for vectors of subclasses of object. The constructor is then 
	sent to the returned class."

	^PrimArray! !

!Object class methodsFor: 'smalltalk initialization'!

REQUIRES: class {Category}
	"make sure that initializers for class have already been run"
	(Heaper initializingClasses includes: class) ifTrue: [self error: 'Circular init requirement for ', class name].
	Heaper initializingClasses add: class.
	(Heaper initializedClasses includes: class) ifFalse:
		[(class class includesSelector: #initTimeNonInherited) ifTrue:
			[class initTimeNonInherited].
		((class respondsTo: #initTimeInherited)
				and: [(class class includesSelector: #suppressInitTimeInherited) not])
			ifTrue: [class initTimeInherited].
		Heaper initializedClasses add: class].
	Heaper initializingClasses remove: class.! !

Object initialize!
