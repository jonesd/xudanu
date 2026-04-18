'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:56:54 pm'!

UserEvent subclass: #KeyEvent
	instanceVariableNames: '
		keycodeInternal {IntegerVar}
		keyNameInternal {PackOBits}
		repeatCountInternal {IntegerVar}'
	classVariableNames: 'KeyNameMap {ScruTable of: IntegerPos and: PackOBits} '
	poolDictionaries: ''
	category: 'FM-Events'!
KeyEvent comment:
'Right now I''m keeping the keynames in this class.  When we bother with menu accelerator tables, this might be moved to the event dispatcher.  Alternatively, key events could respond positively to the appropriate menuQueries.

This should internally (transparently) manage repeating keys.'!

(KeyEvent getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!KeyEvent methodsFor: 'transition testing'!

{BooleanVar}keystroke
	"This event resulted from a keystroke.  Note that I don't currently provide keyUp events."

	^true! !

!KeyEvent methodsFor: 'accessing'!

{IntegerVar}keycode
	^keycodeInternal!

{PackOBits}keyName
	"This is some kind of symbolic name for the key.  
	 I'm not sure this is necessary for C++.  It's used
	 in Smalltalk to make for readable controllers."

	^keyNameInternal!

{IntegerVar}repeatCount
	"Return the number of times this character has been repeated on the same keypress."

	^repeatCountInternal! !

!KeyEvent methodsFor: 'create'!

create: time {TimeVar} with: point{PointPos} with: metaBits{UInt32} with: keycode{IntegerVar}
	super create: time with: point with: metaBits.
	' 
	keycodeInternal = keycode;
	/*keyNameInternal = keycode;*/
	repeatCountInternal = 1;' translateOnly.
	[keycodeInternal _ keycode.
	keyNameInternal _ KeyNameMap intFetch: keycodeInternal asciiValue.
	repeatCountInternal _ 1] smalltalkOnly!

create: time{TimeVar} with: point{PointPos} with: metaBits{UInt32} with: keycode{IntegerVar} with: repeatCount{IntegerVar}
	super create: time with: point with: metaBits.
	'keycodeInternal = keycode;
	/*keyNameInternal =   keycode;*/
	repeatCountInternal = repeatCount;' translateOnly.
	[keycodeInternal _ keycode.
	keyNameInternal _ KeyNameMap intFetch: keycodeInternal asciiValue + 1.
	repeatCountInternal _ repeatCount] smalltalkOnly! !

!KeyEvent methodsFor: 'printing'!

{void} printOn: aStream{ostream reference}
	super printOn: aStream.
	aStream << ' name: ' << keyNameInternal! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

KeyEvent class
	instanceVariableNames: ''!

(KeyEvent getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!KeyEvent class methodsFor: 'smalltalk: smalltalk initialization'!

initialize
	"KeyEvent initialize"

	KeyNameMap _ Array new: 256.
	TextConstants associationsDo:
		[:assoc | (assoc value isKindOf: Character)
			ifTrue: [KeyNameMap at: assoc value asciiValue + 1 put: assoc key]].!

initTimeNonInherited
	"KeyEvent initTimeNonInherited"

	self hack.  "This doesn't translate correctly..."
	KeyNameMap _ IntegerTable make: 256.
	[TextConstants associationsDo:
		[:assoc | (assoc value isKindOf: Character)
			ifTrue: [KeyNameMap atInt: assoc value asciiValue store: assoc key]]] smalltalkOnly.!

linkTimeNonInherited
	"KeyEvent initTimeNonInherited"

	
	KeyNameMap _NULL.! !

!KeyEvent class methodsFor: 'pseudo constructors'!

make: time{TimeVar} with: point{PointPos} with: metaBits{UInt32} with: keycode{IntegerVar}
	^ KeyEvent create: time with: point with: metaBits with: keycode!

make: time{TimeVar} with: point{PointPos} with: metaBits{UInt32} with: keycode{IntegerVar} with: repeatCount{IntegerVar}
	^ KeyEvent create: time with: point with: metaBits with: keycode with: repeatCount! !

KeyEvent initialize!
