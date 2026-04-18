'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:56:05 pm'!

Object subclass: #NullClass
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'X++ Translator'!


!NullClass methodsFor: 'control structures'!

notNULL: nonNullBlock {Block}
	"Execute nonNullBlock with the receiver as an argument if the receiver is
	 non-null.  If the receiver is NULL, then BLAST."
	"The null case is handled in the class that defines null."
	
	self unkindError!

notNULL: nonNullBlock {Block} else: elseB {Block}
	"Execute nonNullBlock with the receiver as an argument if the receiver is
	 non-null.  If the receiver is NULL, then execute the else block."
	"The null case is handled in the class that defines null."

	elseB value! !

!NullClass methodsFor: 'primitive methods'!

= anObject 
	"Answer whether the receiver and the argument represent the same object. 
	If = is redefined in any subclass, consider also redefining the message hash."

	^ anObject class == NullClass!

== anObject 
	"Answer true if the receiver and the argument are the same object (have the same 
	object pointer) and false otherwise. Do not redefine the message == in any 
	other class!! Essential. No Lookup. See documentation in Object metaclass."

	<primitive: 110>
	self primitiveFailed!

addDepedent: ignored
	Heaper BLAST: #NoNULLDependents!

addDependent: ignored
	Heaper BLAST: #NoDependentsOnNULL!

basicCast: type 

	"This only works for simple types (else the Smalltalk syntax breaks 
	down).  This one doesn't do any checks in smalltalk."!

cast: type 

	"This only works for simple types (else the Smalltalk syntax breaks down). "

	^self!

class
	"Answer the object which is the receiver's class. Essential. See 
	documentation in Object metaclass."

	<primitive: 111>
	self primitiveFailed!

delete
	"This is the destructor. turn around and send the release message."

	^VOID!

hash
	"Answer with a SmallInteger unique to the receiver. 
	Fail if the receiver is a SmallInteger. Essential. See documentation 
	in Object metaclass."

	<primitive: 75>
	self primitiveFailed!

identityHash
	"Answer a SmallInteger whose value reflects the identity, not the contents, 
	of the receiver. Essential. See documentation in Object metaclass."

	<primitive: 75>
	self primitiveFailed!

{BooleanVar} isEqual: other
	self error: 'NULL can''t do this!!'!

{BooleanVar} isKindOf: cat
	self error: 'NULL can''t do this!!'!

name
	^ 'NULL'!

printOn: aStream 
	"Append to the argument aStream a sequence of characters that identifies the 
	receiver."

	aStream << 'NULL'!

printString
	"Answer a String whose characters are a description of the receiver."

	| aStream |
	aStream _ WriteStream on: (String new: 16).
	self printOn: aStream.
	^aStream contents!

quickCast: type 
	"This only works for simple types (else the Smalltalk syntax breaks 
	down). This one doesn't do any checks in smalltalk."!

~= anObject 
	"Answer whether the receiver and the argument do not represent the same 
	object."

	^ anObject class ~~ NullClass!

~~ anObject 
	"Answer true if the receiver and the argument are not the same object 
	(have the same object pointer) and false otherwise."

	^(self == anObject) not! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

NullClass class
	instanceVariableNames: ''!


!NullClass class methodsFor: 'initialization'!

initialize
	"NullClass initialize"

	Smalltalk at: #NULL put: self new! !

NullClass initialize!
