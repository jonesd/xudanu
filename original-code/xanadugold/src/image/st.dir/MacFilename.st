'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:53:00 pm'!

Filename subclass: #MacFilename
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'OS-Mac'!
MacFilename comment:
'Class MacFilename defines class Filename to add Macintosh-specific behavior such as access date interpretation, Folder access, and Volume information.

'!


!MacFilename methodsFor: 'instance creation'!

constructString: extraFn
	"Make a new file name string, treating the receiver as a directory, and
	the string argument as a file within the pathname."

	| ws prefix suffix sep |
	sep _ self separator.
	prefix _ nameString.
	suffix _ (extraFn size > 1 and: [ (extraFn at: 1) = sep ])
			ifTrue: [extraFn copyFrom: 2 to: extraFn size]
			ifFalse: [extraFn].
	ws _ WriteStream on: (String new: prefix size + suffix size + 1).
	ws nextPutAll: prefix.
	prefix last = sep
		ifFalse:	[ws nextPut: sep].
	ws nextPutAll: suffix.
	^ws contents! !

!MacFilename methodsFor: 'testing'!

isAbsolute
	"Answer true if this name is absolute (e.g. not relative to the
	'current directory')."

	^(nameString at: 1) ~= self separator and: [nameString includes: self separator]! !

!MacFilename methodsFor: 'parsing'!

extension
	"Answer a String with the file extension (chars after a period) if any."
	^super extension!

head
	"Answer the directory prefix as a String."

	| index sep |
	sep _ self separator.
	index _ nameString prevIndexOf: sep from: nameString size to: 1.
	index ~~ nil
		ifTrue:	[^nameString copyFrom: 1 to: index-1]
		ifFalse:	[^self class defaultDirectoryName]!

tail
	"Answer the filename suffix as a String."

	| index sep |
	sep _ self separator.
	index _ nameString prevIndexOf: sep from: nameString size to: 1.
	index ~~ nil
		ifTrue:	[^nameString copyFrom: index+1 to: nameString size]
		ifFalse:	[^nameString copy]! !

!MacFilename methodsFor: 'private: private'!

filesMatchingAccessList: list into: allNames 
	"Handle the special case of double colon, to refer to parent directories"

	list isEmpty
		ifTrue: [^allNames].
	list first = ':'
		ifTrue: 
			[list removeFirst.
			^(self construct: ':')
				filesMatchingAccessList: list into: allNames].
	^super filesMatchingAccessList: list into: allNames!

named: n
	"Set the OS-specific pathname."
	"Only appropriate at instance creation."

	nameString _ n.!

primSetCreator: aCreatorString type: aTypeString errInto: errorHandler
	" set the CREATOR and TYPE of an existing file.
	aCreatorString and aTypeString a 4 characters long. "
	<primitive: 752>

	^errorHandler reportError!

printFileErrInto: errorHandler
	" print a postScript file via print manager"
	<primitive: 770>
	^errorHandler reportError! !

!MacFilename methodsFor: 'utilities'!

printFile
	" print a postScript file via print manager"

	^self printFileErrInto: self errorReporter new!

setFileCreator: aCreator andType: aType
	" set the CREATOR and TYPE of an existing file.
	aCreator and aType are a String of 4 characters."

	^self primSetCreator: aCreator type: aType errInto: self errorReporter new! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

MacFilename class
	instanceVariableNames: ''!


!MacFilename class methodsFor: 'class initialization'!

hookupTo: pn
	"You have become the default class for some OSHandle subclass.  Prepare yourself."
	"Do nothing."!

install

	self setSeparator: $:.
	DefaultDirectory _ self findDefaultDirectory! !

!MacFilename class methodsFor: 'defaulting'!

currentDirectoryString
	"Return the platform-specific token that represents the current directory"

	^':'!

defaultClass
	"Answer the appropriate concrete subclass."

	"Return self."!

isCaseSensitive
	"Answer whether file naming is case sensitive.  True, for example, means
	that 'foo.st' and 'Foo.st' name different files."

	^false! !

!MacFilename class methodsFor: 'constants'!

changeExtension
	"Answer the platform's changes filename extension."

	^'.cha'!

imageExtension
	"Answer the platform's image filename extension"

	^''!

maximumComponentLength
	"Answer the maximum size of a single component of a path"

	^31!

maxLength
	"Answer the maximum length for a platform pathname."

	^255!

separator
	"Answer the platform's filename component separator."

	^$:!

sourceExtension
	"Answer the platform's sources filename extension."

	^'.sources'! !

!MacFilename class methodsFor: 'parsing'!

components: nameString
	"Break a filename into path compoents, answer an OrderedCollection of components."

	| components separator  stream |
	components _ OrderedCollection new.
	separator _ self separator.
	stream _ nameString readStream.
	[stream atEnd]
		whileFalse:
			[components add: (stream through: separator)].
	^components!

isBadCharacter: aChar
	"Answer if this aCharacter is illegal for a platform
filename string."

	"^aChar == $:"
	^false!

isUglyCharacter: aChar
	"Answer if this character is in bad taste for a platform
pathname string."

	^super isUglyCharacter: aChar!

localNameStringFrom: aString
	"Return a string that is aString, modified to fit the platform's
	definition of a relative path name.  No syntax checking is done"

	aString first = self separator
		ifTrue:	[^aString]
		ifFalse:	[^aString copyFrom: 2 to: aString size]!

readBaseLocationFromStream: stream
	"Return the root of a (semi)absolute path name"

	^stream through: self separator!

suggest: str 
	"Answer a string which is in good taste as a filename on this platform"

	| fullName path pair ws llimit |
	llimit _ self maximumComponentLength.
	pair _ self splitPath: str.
	path _ pair at: 1.
	fullName _ pair at: 2.
	ws _ WriteStream on: (String new: str size).
	ws nextPutAll: path.
	ws nextPutAll: (self
			shrink: fullName
			to: llimit
			dropDelim: false).
	^self canonicalize: ws contents! !

!MacFilename class methodsFor: 'utilities'!

volumes
	"Answer an Array of Strings naming all reachable disk volumes."

	^self getVolumes! !

!MacFilename class methodsFor: 'private: private'!

baseDirectoryForList: list

	(list size = 1 and: [(list first includes: self separator) not])
		ifTrue:	[^self currentDirectory].
	^self named: list removeFirst!

canonicalize: str 
	"Convert this string to a canonical platform pathname string. 
	This may make for arbitrary, unpleasent transformations, like 
	truncating to 8 characters, folding to upper case, etc."

	| components ws maxComponent  |
	maxComponent _ self maximumComponentLength.
	ws _ WriteStream on: (String new: self maxLength).
	components _ self components: str.
	components do: 
		[:pn | 
		| location currentChar c |
		ws size + (pn size min: maxComponent) < self maxLength
			ifTrue: 
				[
				location _ 1.
				c _ pn size min: maxComponent.
				[location <= c]
					whileTrue: 
						[currentChar _ pn at: location.
						(self isBadCharacter: currentChar)
							ifFalse: [ws nextPut: currentChar].
						location _ location + 1].
				(pn size > c and: [pn last = self separator])
					ifTrue:	[ws nextPut: self separator]]
			ifFalse: [nil]].
	^ws contents!

getVolumes
	"Return a Array of Strings of all legal volume specifiers."
	<primitive: 750>

	^self errorReporter errorSignal raise!

stringIsAbsolute: ns 
	"Answer true if this name is absolute (e.g. not relative to the 
	'current directory')."

	| sep |
	sep _ self separator.
	ns size ~= 0
		ifTrue: 
			[(ns includes: sep)
				ifTrue: [^(ns at: 1)
						~= sep].
			^false]
		ifFalse: [^false]! !

!MacFilename class methodsFor: 'defaults'!

errorReporter
	"Return the appropriate error code interpreter."

	^MacErrorHolder! !