'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:48:31 pm'!

Magnitude subclass: #Character
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Collections-Text'!
Character comment:
'An instance of class Character is an element of a String.  Characters are identified by a non-negative SmallInteger code: in particular, codes 0-127 define characters according to the ASCII standard.  Instances of class Character are unique, in that all instances with the same code are identical (==).  Characters can be expressed literally by preceding the character by a dollar sign ($): for example, $A represents the capital letter "A".

Characters, like SmallIntegers, use an "immediate" representation -- the character code is stored directly in the object pointer.
'!


!Character methodsFor: 'accessing'!

asciiValue
	"Answer the code value of the receiver."

	<primitive: 410>
	^self primitiveFailed!

digitValue
	"Answer 0-9 if the receiver is $0-$9, 10-35 if it is $A-$Z or $a-$z, and < 0 otherwise.
	This is used to parse literal numbers of radix 2-36."

	| ascii value |
	ascii _ self asciiValue.
	value _ ascii - $0 asciiValue.
	value <= 9
		ifTrue: [^value].
	value _ ascii - $A asciiValue.
	(value >= 0 and: [value < 26])
		ifTrue: [^value + 10].
	value _ ascii - $a asciiValue.
	(value >= 0 and: [value < 26])
		ifTrue: [^value + 10].
	^-1! !

!Character methodsFor: 'comparing'!

< aCharacter 
	"Answer whether the receiver's value is less than aCharacter's value."

	^self asciiValue < aCharacter asciiValue!

= aCharacter 
	"Answer whether the receiver and the argument are the same object 
	(have the same object pointer).  Optional.  See Object documentation 
	whatIsAPrimitive. "

	<primitive: 110>
	^self == aCharacter!

> aCharacter 
	"Answer whether the receiver's value > aCharacter's value."

	^self asciiValue > aCharacter asciiValue!

hash
	"Answer a SmallInteger unique to the receiver."

	^self asciiValue!

identityHash
	"Answer a SmallInteger unique to the receiver."
	"Must override method in Object, because characters are immediate."

	^self asciiValue! !

!Character methodsFor: 'testing'!

isAlphabetic
	"Answer whether the receiver is in the English alphabet."

	^($a <= self and: [self <= $z])
		or: [$A <= self and: [self <= $Z]]!

isAlphaNumeric
	"Answer whether the receiver is in the English alphabet or a digit."

	^self isAlphabetic or: [self isDigit]!

isCharacter
	"Answer whether receiver is a character."

	^true!

isDigit
	"Answer whether the receiver is a digit."

	^self >= $0 and: [self <= $9]!

isLetter
	"Answer whether the receiver is in the English alphabet or
	an extended (multi-byte) character."

	^self isAlphabetic or: [self asciiValue > 255]!

isLinebreak
	"Answer whether the receiver is one of the linebreak characters-- cr, line feed, null , or form feed."

	| ascii |
	ascii _ self asciiValue.
	ascii > 32 ifTrue: [^false]. "normal character"
	ascii = 13 ifTrue: [^true].	"cr"
	ascii = 10 ifTrue: [^true].	"line feed"
	ascii = 12 ifTrue: [^true].	"form feed"
	^false!

isLowercase
	"Answer whether the receiver is a lowercase alphabetic character."

	^self >= $a and: [self <= $z]!

isManifest
	"Answer whether receiver is manifestly storable."

	^true!

isSeparator
	"Answer whether the receiver is one of the separator characters--space,
	cr, tab, line feed, null , or form feed."

	| ascii |
	ascii _ self asciiValue.
	ascii > 32 ifTrue: [^false]. "normal character"
	ascii = 32 ifTrue: [^true].	"space"
	ascii = 13 ifTrue: [^true].	"cr"
	ascii = 9 ifTrue: [^true].	"tab"
	ascii = 10 ifTrue: [^true].	"line feed"
	ascii = 12 ifTrue: [^true].	"form feed"
	ascii = 0 ifTrue: [^true].	"null"
	^false!

isUppercase
	"Answer whether the receiver is an uppercase alphabetic character."

	^self >= $A and: [self <= $Z]!

isVowel
	"Answer whether the receiver is one of the vowels, AEIOU, in upper or lower case."

	^'AEIOU' includes: self asUppercase!

tokenish
	"Answer whether the receiver is a valid token-character--letter, digit, or colon."

	^self isLetter or: [self isDigit or: [self = $:]]! !

!Character methodsFor: 'copying'!

copy
	"Answer the receiver because Characters are unique."

	^self!

deepCopy
	"Answer the receiver becuase Characters are unique."

	^self!

shallowCopy
	"Answer the receiver because Characters are unique"

	^self! !

!Character methodsFor: 'printing'!

isLiteral
	"Answer true that the receiver is a literal."

	^true!

printOn: aStream  
	"Append to the argument aStream a sequence of characters preceded by the
	literal $ that identifies the receiver."

	aStream nextPut: $$.
	aStream nextPut: self!

storeOn: aStream
	"Append to the argument aStream a sequence of characters that is an
	expression whose evaluation creates an object similar to the receiver.
	Character literals are preceded by '$'."

	aStream nextPut: $$; nextPut: self! !

!Character methodsFor: 'converting'!

asCharacter
	"Answer the receiver itself."

	^self!

asInteger
	"Answer the value of the receiver."

	<primitive: 410>
	^self primitiveFailed!

asLowercase
	"Answer a Character that is the lower case letter corresponding to the receiver.  If
	the receiver is not an upper case letter, answer the receiver itself."

	| ascii |
	ascii _ self asciiValue.
	8r101 <= ascii 
		ifTrue: [ascii <= 8r132 
					ifTrue: [^Character value: ascii+8r40]]!

asString
	| s |
	s _ String new: 1.
	s at: 1 put: self.
	^s!

asSymbol
	"Answer the receiver converted into a Symbol."

	^Symbol internCharacter: self!

asUppercase
	"Answer a Character that is the upper case letter corresponding to  
	the receiver.  If the receiver is not a lower case letter, answer the 
	receiver itself."

	| ascii |
	ascii _ self asciiValue.
	8r141 <= ascii
		ifTrue: [ascii <= 8r172 
					ifTrue: [^Character value: ascii-8r40]]! !

!Character methodsFor: 'fileIn/Out'!

storeBinaryOn: stream 
	"Put a binary representation of the receiver into stream."

	stream storeCharacter: self! !

!Character methodsFor: 'cxx fixups'!

asUInt8
	"Answer the code value of the receiver."

	<primitive: 410>
	^self primitiveFailed!

bitShift: someNum 
	^self asInteger bitShift: someNum!

makeProxy: commHandler {CommHandler}
	^self!

sendSelfTo: transceiver {Transceiver}
	transceiver sendInt8: self!

uint8
	"Answer the code value of the receiver."

	<primitive: 410>
	^self primitiveFailed! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

Character class
	instanceVariableNames: ''!


!Character class methodsFor: 'instance creation'!

basicNew
	"Provide an error notification that creating new characters
	this way is not allowed."

	self error: 'Use Character value: to create new characters'!

digitValue: aNumber
	"Answer the Character whose digit value is aNumber.
	For example, answer $9 for aNumber=9, $0 for aNumber=0,
	$A for aNumber=10, $Z for aNumber=35."

	| index |
	index _ aNumber asSmallInteger.
	^self value:
		(index < 10
			ifTrue: [48 + index]
			ifFalse: [55 + index])!

new
	"Provide an error notification that creating new characters
	this way is not allowed."

	self error: 'Use Character value: to create new characters'!

value: anInteger 
	"Answer the Character whose value is anInteger."

	<primitive: 411>
	^self valueFromInteger: anInteger asSmallInteger!

valueFromInteger: anInteger 
	"Answer the Character whose value is anInteger."

	<primitive: 411>
	^self error: 'Character values must be non-negative SmallIntegers'! !

!Character class methodsFor: 'global: accessing untypeable characters'!

backspace
	"Answer the Character representing a backspace."

	^self value: 8!

cr
	"Answer the Character representing a carriage return."

	^self value: 13!

esc
	"Answer the Character representing an escape."

	^self value: 27!

lf
	"Answer the Character representing a carriage return."

	^self value: 10!

newPage
	"Answer the Character representing a form feed."

	^self value: 12!

space
	"Answer the Character representing a space."

	^self value: 32!

tab
	"Answer the Character representing a tab."

	^self value: 9! !

!Character class methodsFor: 'global: macros: c++ ctype.h'!

{BooleanVar} isalnum: c {char}
	
	^c isAlphaNumeric!

{BooleanVar} isalpha: c {char}
	
	^c isAlphabetic!

{BooleanVar} isdigit: c {char}
	
	^c isDigit!

{BooleanVar} islower: c {char}
	
	^c isLowercase!

{BooleanVar} isspace: c {char}
	
	^c isSeparator!

{BooleanVar} isupper: c {char}
	
	^c isUppercase! !

!Character class methodsFor: 'global: c++ instance creation'!

char: anInteger 
	"Answer the Character whose value is anInteger."

	<primitive: 411>
	^self valueFromInteger: anInteger asSmallInteger!

make: anInteger 
	"Answer the Character whose value is anInteger."

	<primitive: 411>
	^self valueFromInteger: anInteger asSmallInteger!

null
	^self value: 0!

star
	"Return the Class for vectors of subclasses of object. The constructor is then 
	sent to the returned class."

	^String!

vector
	"Return the Class for vectors of subclasses of object. The constructor is then 
	sent to the returned class."

	^String! !