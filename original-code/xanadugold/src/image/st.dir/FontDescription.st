'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:53:03 pm'!

Object subclass: #FontDescription
	instanceVariableNames: 'fullName widths italicAngle weight fixedPitch familyName underlinePosition underlineThickness '
	classVariableNames: 'PSFonts '
	poolDictionaries: ''
	category: 'System-Printing'!
', myPattern, ''''.!


!FontDescription methodsFor: 'accessing'!

familyName: string 
	"Set the type family to the name in the string."

	familyName _ string!

fixedPitch: bool 
	"Set whether or not a fixed pitch font."

	fixedPitch _ bool!

fullName
	"return the full name of the current font."

	^fullName!

fullName: string 
	"Set the current full name of the current font."

	fullName _ string!

italicAngle: number 
	"Set the angle at which the font is italicized."

	italicAngle _ number!

underlinePosition
	"Return where the underline goes in the current font."

	^underlinePosition!

underlinePosition: number 
	"Set where the underline goes in the current font."

	underlinePosition _ number!

underlineThickness
	"Return how thick an underline is done in the current font."

	^underlineThickness!

underlineThickness: number 
	"Set how thick the underline should be in the current font.."

	underlineThickness _ number!

weight: string 
	"Set the weight of the current font."

	weight _ string!

widths
	"Return an array of the widths of all the characters in the current  
	font."

	^widths!

widths: array 
	"Set the widths of all the characters in the current font from the 
	contents of the given array."

	widths _ array! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

FontDescription class
	instanceVariableNames: ''!
Record} with: from {XuModel}
 
	from == waldoInternal
		ifTrue: [self changed: ur]!


!FontDescription class methodsFor: 'initialization'!

fixNameInternal: string 
	"Massage the font name,  getting rid of spaces.  Also,  map 'Oblique' 
	to 'Italic',  'medium' to '',  'Light' to '',  'Demi' to 'Bold',  'Roman'   
	to '',  for internal use... this is necessary to deal with some of the   
	Adobe special naming choices."

	| new foundIndex1 foundIndex2 c |
	foundIndex1 _ string findString: 'Book' startingAt: 1.
	foundIndex2 _ string findString: 'Bookman' startingAt: 1.
	foundIndex2 == 0 ifTrue: [foundIndex1 == 0 ifFalse: [string
				replaceFrom: foundIndex1
				to: foundIndex1 + 3
				with: '    ']].
	foundIndex1 _ string findString: 'Demi' startingAt: 1.
	foundIndex1 == 0 ifFalse: [string
			replaceFrom: foundIndex1
			to: foundIndex1 + 3
			with: 'Bold'].
	foundIndex1 _ string findString: 'Oblique' startingAt: 1.
	foundIndex1 == 0 ifFalse: [string
			replaceFrom: foundIndex1
			to: foundIndex1 + 6
			with: 'Italic '].
	foundIndex1 _ string findString: 'Light' startingAt: 1.
	foundIndex1 == 0 ifFalse: [string
			replaceFrom: foundIndex1
			to: foundIndex1 + 4
			with: '     '].
	foundIndex1 _ string findString: 'Medium' startingAt: 1.
	foundIndex1 == 0 ifFalse: [string
			replaceFrom: foundIndex1
			to: foundIndex1 + 5
			with: '      '].
	foundIndex1 _ string findString: 'Roman' startingAt: 1.
	foundIndex1 == 0 ifFalse: [string
			replaceFrom: foundIndex1
			to: foundIndex1 + 4
			with: '     '].
	new _ WriteStream on: (String new: 1).
	1 to: string size do: 
		[:i | 
		c _ string at: i.
		c == 32 asCharacter ifFalse: [new nextPut: c]].
	^new contents!

getDirName
	"Prompt for and return the base directory name of the font metric files."

	^FillInTheBlank request: 'Where are the Font Metric files?'  initialAnswer: 
'printing',( String with: FileDirectory separator),'AFM'!

initialize
	"Process the default fonts for the LaserWrite-Plus."
	"FontDescription initialize."

	| dirList flag directoryName |
	PSFonts _ Dictionary new.
	flag _ false.
	[directoryName _ FontDescription getDirName.
	directoryName isEmpty or: 
		[(FileDirectory isDirectory: directoryName) not
		or: [(dirList _ (FileDirectory named: directoryName) 
						filesMatching: '*AFM') isEmpty]]]
		whileTrue: 
			[BinaryChoice
				message: 'try again?'
				displayAt: Sensor mousePoint
				centered: true
				ifTrue: nil
				ifFalse: [flag _ true].
			flag ifTrue: [^self]].
	self processAdobeFiles: dirList!

processAdobeFiles
	"Load in the Adobe Font Metric (AFM) files,  and massage them into a 
	set of  internal font descriptions..."

	^self processAdobeFiles: ((FileDirectory named: self getDirName)
		filesMatching: '*AFM')!

processAdobeFiles: aCollection
	"Load in the Adobe Font Metric (AFM) files,  and massage them into a 
	set of  internal font descriptions..."

	| key f s i c width widths index angle weight pitch family named desc 
underlineThickness underlinePosition spaceWidth psName |
	aCollection
		do: 
			[:aName | 
			Transcript cr; show: 'Processing ' , aName.
			key _ aName.
			widths _ Array new: 256.
			f _ aName asFilename.
			s _ f contentsOfEntireFile.
			named _ self extractFieldNamed: 'FullName' from: s.
			psName _ self extractFieldNamed: 'FontName' from: s.
			key _ (self fixNameInternal: named) asSymbol.
			angle _ Number readFrom: (ReadStream on: (self extractFieldNamed: 
'ItalicAngle' from: s)).
			underlineThickness _ Number readFrom: (ReadStream on: (self 
extractFieldNamed: 'UnderlineThickness' from: s)).
			underlinePosition _ Number readFrom: (ReadStream on: (self 
extractFieldNamed: 'UnderlinePosition' from: s)).
			weight _ self extractFieldNamed: 'Weight' from: s.
			pitch _ (self extractFieldNamed: 'IsFixedPitch' from: s)
						= 'true'.
			family _ self extractFieldNamed: 'FamilyName' from: s.
			i _ s indexOfSubCollection: 'StartCharMetrics' startingAt: 1.
			i _ s indexOfSubCollection: 'C ' startingAt: i.
			f _ s readStream.
			f position: i.
			[c _ f next.
			c = Character space ifFalse: [self afmReadError].
			index _ Integer readFrom: f.
			index < 0
				ifFalse: 
					[[c _ f next = $W] whileFalse.
					c _ f next.
					c = $X ifFalse: [self afmReadError].
					c _ f next.
					c = Character space ifFalse: [self afmReadError].
					width _ Integer readFrom: f.
					widths at: index + 1 put: width].
			f skipThrough: 13 asCharacter.
			c _ f next.
			c = $C] whileTrue.
			spaceWidth _ widths at: 32 + 1.
			"for non-glyphed characters, the printer will output a space   
			   glyph.  make measurement work correctly"
			1 to: 256 do: [:j | (widths at: j)
					== nil ifTrue: [widths at: j put: spaceWidth]].
			f close.
			"			desc _ (FontDescription new) familyName: family; fullName: 
			named; widths: widths; italicAngle: angle; weight: weight; 
			fixedPitch: pitch; underlineThickness: underlineThickness; 
			underlinePosition: underlinePosition.
			"
			desc _ (FontDescription new) familyName: family; fullName: psName; 
widths: widths; italicAngle: angle; weight: weight; fixedPitch: pitch; 
underlineThickness: underlineThickness; underlinePosition: underlinePosition.
			PSFonts at: key put: desc].
	^PSFonts! !

!FontDescription class methodsFor: 'accessing'!

named: aSymbol 
	"Return the font description corresponding to the given name."

	^PSFonts at: aSymbol! !

!FontDescription class methodsFor: 'private: private'!

afmReadError
	self error: 'Can''t parse font metrics file'!

extractFieldNamed: field from: string 
	"Find a named field in a string,  and return it."

	| i result |
	i _ string indexOfSubCollection: field startingAt: 1.
	i _ string indexOfSubCollection: ' ' startingAt: i.
	result _ string copyFrom: i + 1 to: (string indexOfSubCollection: '
' startingAt: i)
					- 1.
	^result! !

FontDescription initialize!
