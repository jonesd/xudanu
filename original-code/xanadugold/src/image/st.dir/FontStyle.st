'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:53:03 pm'!

Object subclass: #FontStyle
	instanceVariableNames: 'currentStyle defaultInfo '
	classVariableNames: 'DefaultDefaultInfo '
	poolDictionaries: ''
	category: 'System-Printing'!
anString newName oldName |
	self changeRequest ifFalse: [^self].
	aString _ self prompt: 'Enter new ClassName' initially: self nonMetaClass name.
	aString isEmpty ifTrue: [^self].
	cleanString _ aString select: [:aChar | aChar isLetter or: [aChar isDigit]].
	cleanString = aString ifFalse: [(self confirm: 'Invalid characters in class name.  Should I use ' , cleanString , '?')
			ifTrue: [aString _ cleanString]
			ifFalse: [Transcript show: 'using odd name for class >'; print: aString; cr]].
	aString first isLowercase ifTrue: [aString at: 1 put: (aString at: 1) asUppercase.
		(self confirm: 'Class names must be capitalized.  Should I use ' , aString , '?')
			ifFalse: [^self]].
	newName _ aString asSymbol.
	oldName _ self nonMetaClass name.
	aString = oldName
		ifFalse: 
			[self nonMetaClass rename: newName.
			self newClassList: class.
			Transcript cr; show: 'Searching for references to this class...'.
			(ClassRefsFilter make: self nonMetaClass with: oldName) browse]!


!FontStyle methodsFor: 'initialization'!

initialize
	"Set up an initial default font style."

	currentStyle _ #Default.
	defaultInfo _ DefaultDefaultInfo deepCopy.! !

!FontStyle methodsFor: 'fonts'!

currentAttributes
	"Return the appropriate info for the current style setting."

	currentStyle == #Default ifTrue: [^defaultInfo].
	self error: 'funny style'!

currentFace
	"Return the current typeface."

	^self currentAttributes at: #face!

currentFamily
	"Return the current type family."

	^self currentAttributes at: #family!

currentSize
	"Return the current type point size."

	^self currentAttributes at: #size!

currentStyle
	"Return the current font style."

	^currentStyle!

setFace: aSymbol 
	"Set the current type face to the named one."

	self currentAttributes add: (Association key: #face value: aSymbol)!

setFamily: aSymbol 
	"Set the current type family."

	self currentAttributes add: (Association key: #family value: aSymbol).
	self setFace: #Default!

setSize: anInteger 
	"Set the point size of the type."

	self currentAttributes add: (Association key: #size value: anInteger)!

setStyle: abstractFontName 
	"Set the current type style."

	currentStyle _ abstractFontName! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

FontStyle class
	instanceVariableNames: ''!
!


!FontStyle class methodsFor: 'instance creation'!

default
	"Return a new defaulted font style."

	^self new!

new
	"Initialize."

	^super new initialize! !

!FontStyle class methodsFor: 'class initialization'!

initialize
	"Set up the details of the default style."

	DefaultDefaultInfo _ Dictionary new.
	DefaultDefaultInfo	at: 		#face put: #Default;
						at:		#size put: 10;
						at:		#family put: #SanSerif.! !

FontStyle initialize!
