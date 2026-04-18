'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:49:16 pm'!

ClassDescription subclass: #Metaclass
	instanceVariableNames: 'thisClass '
	classVariableNames: 'ObsoleteSignal '
	poolDictionaries: ''
	category: 'Kernel-Classes'!
Metaclass comment:
'Metaclasses add instance-specific behavior to various classes in the system.  This typically includes messages for initializing class variables and instance creation messages particular to that class.  There is only one instance of a metaclass, namely the class (thisClass) which is being described.  A metaclass shares the class variables of its instance.

[Subtle] In general, the superclass hierarchy for metaclasses parallels that for classes.  Thus,
	Integer superclass == Number, and
	Integer class superclass == Number class.
However there is a singularity at Object.  Here the class hierarchy terminates, but the metaclass hierarchy must wrap around to Class, since ALL metaclasses are subclasses of Class.  Thus,
	Object superclass == nil, and
	Object class superclass == Class.

Instance Variables:
	thisClass	<Class> the chief instance of the receiver, which the receiver describes

Class Variables:
	ObsoleteSignal 	<Signal> Obsolete metaclass
		
'!


!Metaclass methodsFor: 'initialize-release'!

instanceVariableNames: instVarString 
	"Declare additional variables for my instances."

	^self classBuilder
		currentClass: self;
		superclass: superclass;
		instVarString: instVarString;
		reviseSystem! !

!Metaclass methodsFor: 'accessing'!

name
	"Answer a String that is the name of the receiver, either Metaclass or the
	name of the receiver's class followed by the ' class'."

	thisClass == nil
		ifTrue: [^'a Metaclass']
		ifFalse: [^thisClass name , ' class']!

nonMeta
	"the non-meta class"
	^self soleInstance!

soleInstance
	"The receiver has only one instance.  Answer it.
	If the receiver is an obsolete metaclass, raise a signal."

	thisClass == nil ifTrue: [^Metaclass obsoleteSignal raise].
	^thisClass! !

!Metaclass methodsFor: 'testing'!

isMeta
	^ true!

isObsolete
	"Answer whether the receiver is an obsolete metaclass."

	^thisClass == nil or: [thisClass ~~ (Smalltalk at: thisClass name ifAbsent: [nil])]
	"should only be true for obsolete metaclass"! !

!Metaclass methodsFor: 'copying'!

copy
	"Make a copy of the receiver without a list of subclasses.  Share the 
	reference to the sole instance."

	| copy t |
	t _ thisClass.
	thisClass _ nil.
	copy _ super copy.
	thisClass _ t.
	^copy! !

!Metaclass methodsFor: 'instance creation'!

adopt: aClass
	"Define the current class for this metaclass."

	aClass class == self
		ifFalse:	[^self error: 'Invalid assignment'].
	thisClass _ aClass!

new
	"The receiver can only have one instance.  Create it or complain that
	one already exists."

	thisClass == nil
		ifTrue: [^thisClass _ super new]
		ifFalse: [self error: 'A Metaclass should only have one instance!!']! !

!Metaclass methodsFor: 'instance variables'!

addInstVarName: aString 
	"Add the argument, aString, as one of the receiver's instance variables."

	| fullString |
	fullString _ aString.
	self instVarNames do: [:aString2 | fullString _ aString2 , ' ' , fullString].
	self instanceVariableNames: fullString!

removeInstVarName: aString 
	"Remove the argument, aString, as one of the receiver's instance variables."


	| newArray newString |
	(self instVarNames includes: aString)
		ifFalse: [self error: aString , ' is not one of my instance variables'].
	newArray _ self instVarNames copyWithout: aString.
	newString _ ''.
	newArray do: [:aString2 | newString _ aString2 , ' ' , newString].
	self instanceVariableNames: newString! !

!Metaclass methodsFor: 'class variables'!

addClassVarName: aString
	"Add the new class variable named aString to the receiver."

	^thisClass addClassVarName: aString!

classPool
	"Answer the dictionary of class variables."

	^thisClass classPool! !

!Metaclass methodsFor: 'class hierarchy'!

{Collection of: Behavior} subclasses
	"Answer the receiver's subclasses."

	| result {Collection of: Behavior} subs {Collection of: Behavior} |
	subs _ thisClass subclasses.
	result _ Set new: subs size.
	subs do: [:cls {Behavior} |
		cls isMeta not
			ifTrue: [result add: cls class]].
	^result!

{void} withAllSubsAndMetasDo: aBlock {BlockClosure of: Behavior}

	^VOID! !

!Metaclass methodsFor: 'compiling'!

possibleVariablesFor: misspelled continuedFrom: oldResults
	^ thisClass possibleVariablesFor: misspelled continuedFrom: oldResults.!

scopeHas: name ifTrue: assocBlock 
	^thisClass scopeHas: name ifTrue: assocBlock! !

!Metaclass methodsFor: 'printing'!

definition
	"Answer with a string that defines me"
	^self name , '
	' , 'instanceVariableNames: ' , self instanceVariablesStringWithTypes storeString!

definitionWithComment
	^self definition!

definitionWithCommentAndAttributes
	^self definition! !

!Metaclass methodsFor: 'fileIn/Out'!

fileOutOn: aFileStream moveSource: moveSource toFile: fileIndex 
	"File me out on aFileStream."

	super
		fileOutOn: aFileStream
		moveSource: moveSource
		toFile: fileIndex.
	(methodDict includesKey: #initialize)
		ifTrue: 
			[aFileStream cr.
			aFileStream cr.
			aFileStream nextChunkPut: thisClass name , ' initialize'.
			aFileStream cr]!

nonTrivial
	"Answer whether the receiver has some state or methods or class comment."

	^self instVarNames size > 0 or: [methodDict size > 0 or: [self comment size > 0]]!

readBinaryContentsFrom: stream
	"Read instance from stream."

	methodDict _ stream inClass: self do: [stream next].
	organization _ stream next!

storeBinaryContentsOn: stream
	"Store binary representation of the contents of the receiver onto aStream."

	stream inClass: self do: [stream nextPut: methodDict].
	stream nextPut: organization! !

!Metaclass methodsFor: 'cxx fileOut'! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

Metaclass class
	instanceVariableNames: ''!


!Metaclass class methodsFor: 'class initialization'!

initialize
	"Initialize signals."

	| es |
	es _ Object errorSignal.
	ObsoleteSignal _ es newSignal 
		notifierString: 'Obsolete metaclass';
		nameClass: self message: #obsoleteSignal.! !

!Metaclass class methodsFor: 'Signal constants'!

obsoleteSignal

	^ObsoleteSignal! !

Metaclass initialize!
