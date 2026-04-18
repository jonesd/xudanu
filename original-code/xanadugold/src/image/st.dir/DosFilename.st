'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:52:58 pm'!

Filename subclass: #DosFilename
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'OS-Dos'!
DosFilename comment:
'Refines class Filename to add MS-DOS-specific behavior such as access date interpretation.
'!


!DosFilename methodsFor: 'instance creation'!

constructString: extraFn 
	"Make a new file name string, treating the receiver as a directory, and 
	the string argument as a file within the pathname."

	| ws prefix suffix sep |
	sep _ self separator.
	prefix _ nameString.
	suffix _ (extraFn size > 1 and: [(extraFn at: 2) == $:])
		ifTrue: [extraFn copyFrom: 2 to: extraFn size]
		ifFalse: [extraFn].
	suffix _ (suffix size > 0 and: [ (suffix at: 1) = sep ])
		ifTrue: [suffix copyFrom: 2 to: suffix size]
		ifFalse: [suffix].
	ws _ WriteStream on: (String new: prefix size + suffix size + 1).
	ws nextPutAll: prefix.
	(prefix last = sep or: [ prefix last = $: ])
		ifFalse:	[ws nextPut: sep].
	ws nextPutAll: suffix.
	^ws contents! !

!DosFilename methodsFor: 'testing'!

isAbsolute
	"Answer true if this name is absolute (e.g. not relative to the
	'current directory')."

	| offset |
	offset _ self isVolumeAbsolute
		ifTrue:	[3]
		ifFalse:	[1].
	self size < offset
		ifTrue:	[^false].
	^(nameString at: offset) == self separator!

isVolumeAbsolute
	^nameString size > 1 and: [(nameString at: 2) == $:]!

isVolumeRelative
	^self isVolumeAbsolute not! !

!DosFilename methodsFor: 'parsing'!

extension
	"Answer a String with the file extension (chars after a period) if any."
	| di |
	di _ self lastIndexOf: $..
	di = 0 ifTrue: [^''].
	^nameString copyFrom: di + 1 to: nameString size!

head
	"Return the filename of the directory for this Filename"

	| index |
	(index _ self lastIndexOf: self separator) ~= 0
		ifTrue: 
			[index _ index max: 2 + (self lastIndexOf: $:).
			^nameString copyFrom: 1 to: index - 1]
		ifFalse:
			[(nameString includes: $:)
				ifTrue: [^nameString copyFrom: 1 to: 2]
				ifFalse: [^self class defaultDirectoryName]]!

tail
	"Answer the filename suffix as a String."

	| index |
	(index _ self lastIndexOf: self separator) ~= 0
		ifTrue: 
			[^nameString copyFrom: index+1 to: nameString size]
		ifFalse:
			[(nameString includes: $:)
				ifTrue: [^nameString copyFrom: 3 to: nameString size]
				ifFalse: [^nameString copy]]!

volume
	"Answer the volume as a string.  Default volume is empty string."

	(nameString size > 1 and: [(nameString at: 2) == $:])
		ifTrue: [^String with: (nameString at: 1)].
	^''! !

!DosFilename methodsFor: 'private: private'!

filesMatchingAccessList: list into: allNames 

	list isEmpty
		ifTrue:	[^allNames].
	list first = '.'
		ifTrue:	[list removeFirst.
				^self filesMatchingAccessList: list into: allNames].
	list first = '..'
		ifTrue:	[list removeFirst.
				^(self construct: '..') filesMatchingAccessList: list into: allNames].
	^super filesMatchingAccessList: list into: allNames!

named: n
	"Set the OS-specific pathname."
	"Only appropriate at instance creation."

	nameString _ n.
	nameString size = 0
		ifTrue:	[^self].
	(nameString last == self separator and:
		[nameString size > 1 and:
		[(nameString at: nameString size - 1) ~= $:]])
		ifTrue: [nameString _ nameString copyFrom: 1 to: nameString size -1]! !

!DosFilename methodsFor: 'utilities'!

printFile
	"print a PostScript file"
	"| printer output |
	printer _ (Filename named: 'lpt1') writeStream.
	output _ self readStream.
	[output atEnd] whileFalse:
		[printer nextPut: output next]"
	"self errorReporter unsupportedOperationSignal raise"! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

DosFilename class
	instanceVariableNames: ''!


!DosFilename class methodsFor: 'class initialization'!

hookupTo: pn
	"You have become the default class for some OSHandle subclass.  Prepare yourself."
	"Do nothing."!

install

	self setSeparator: self separator.
	DefaultDirectory _ self findDefaultDirectory! !

!DosFilename class methodsFor: 'defaulting'!

currentDirectoryString
	"Return the platform-specific token that represents the current directory"

	^'.'!

defaultClass
	"Answer the appropriate concrete subclass."

	"Return self."!

errorReporter
	"Answer the class which can do error interpretation for me."

	^DosErrorHolder!

isCaseSensitive
	"Answer whether file naming is case sensitive.  True, for example, means
	that 'foo.st' and 'Foo.st' name different files."
	^false! !

!DosFilename class methodsFor: 'constants'!

changeExtension
	"Answer the platform's changes filename extension."

	^'.cha'!

imageExtension
	"Answer the platform's image filename extension"

	^'.IM'!

maximumComponentLength
	"Answer the maximum size of a single component of a path"

	^12!

maxLength
	"Answer the maximum length for a platform pathname."

	^63!

separator
	"Answer the platform's filename component separator."

	^$\!

sourceExtension
	"Answer the platform's sources filename extension."

	^'.SOU'! !

!DosFilename class methodsFor: 'parsing'!

canonicalize: str 
	"Convert this string to a canonical platform pathname string. 
	This may make for arbitrary, unpleasent transformations, like 
	truncating to 8 characters, folding to upper case, etc."

	| ws components sep pair st skipBack head |
	str = '.' ifTrue: [^str].
	ws _ String new writeStream.
	sep _ self separator.
	skipBack _ false.
	components _ self components: str.
	head _ components first.
	(head last = self separator or:
			[head size = 2 and:
			[head first isLetter and:
			[head last = $:]]])
		ifTrue: [ws nextPutAll: components removeFirst asLowercase].
	components do:
		[:pn |
		(ws size + (pn size min: 8) < self maxLength and: [pn ~= '.'])
			ifTrue: 
				[pn = '..'
					ifTrue: [ws nextPutAll: pn]
					ifFalse: 
						[pair _ self splitExtension: pn.
						st _ pair first reject: [:c | self isBadCharacter: c].
						1 to: (st size min: 8)
							do: [:i | ws nextPut: (st at: i) asLowercase].
						pair last == nil
							ifFalse: 
								[ws nextPut: $..
								st _ pair last reject: [:c | self isBadCharacter: c].
								1 to: (st size min: 3)
									do: [:i | ws nextPut: (st at: i) asLowercase]]].
				skipBack _ true.
				ws nextPut: sep]].
	skipBack
		ifTrue: [ws skip: -1].
	^ws contents!

isBadCharacter: aChar
	"Answer if this character is illegal for a platform
pathname string."

	| cv |
	cv _ aChar asciiValue.
	cv <= 32 "space" ifTrue: [^true].
	cv >= 8r177 "del" ifTrue: [^true].
	'\:."/[]|<>+=;,*?' do: [:bc | bc == aChar ifTrue:
[^true]].
	^false!

isUglyCharacter: aChar
	"Answer if this character is in bad taste for a platform
pathname string."

	^self isBadCharacter: aChar!

readBaseLocationFromStream: stream
	"Return the root of a (semi)absolute path name"

	| drive |
	((drive _ stream next) isLetter and: [stream peekFor: $:])
		ifTrue:	[drive _ String with: drive with: $:]
		ifFalse:	[drive _ String new.
				stream skip: -1].
	^(stream peekFor: self separator)
		ifTrue:	[drive, (String with: self separator)]
		ifFalse:	[drive]!

splitVolume: str
	"Answer an Array with: with: "

	| volume remainder |
	((str size >= 2 and: [(str at: 2) == $:]) and: [| c | c _ (str at: 1) asUppercase. c >= $A and: [c <= $V]])
		ifTrue: 
			[volume _ str at: 1.
			remainder _ str size > 2
						ifTrue: [str copyFrom: 3 to: str size]
						ifFalse: ['']]
		ifFalse: [remainder _ str].
	^Array with: volume with: remainder!

suggest: str 
	"Answer a string which is in good taste as a filename on this 
	platform"

	| volume fullName path moniker extension pair ws |
	pair _ self splitVolume: str.
	volume _ pair at: 1.
	pair _ self splitPath: (pair at: 2).
	path _ pair at: 1.
	fullName _ pair at: 2.
	pair _ self splitExtension: fullName.
	moniker _ pair at: 1.
	extension _ pair at: 2.
	ws _ WriteStream on: (String new: str size).
	volume notNil ifTrue: [ws nextPut: volume; nextPut: $:].
	ws nextPutAll: path.
	ws nextPutAll: (self
			shrink: moniker
			to: 8
			dropDelim: false).
	(extension notNil and: [extension size > 0])
		ifTrue: [ws nextPut: $.; nextPutAll: (self
					shrink: extension
					to: 3
					dropDelim: true)].
	^self canonicalize: ws contents! !

!DosFilename class methodsFor: 'utilities'!

volumes
	"Answer an Array of Strings naming all reachable disk volumes."

	^self getVolumes asArray collect: [:v | String with: v with: $:]! !

!DosFilename class methodsFor: 'private: private'!

baseDirectoryForList: list

	^((list first includes: self separator) or: [ list first includes: $: ])
		ifTrue:	[self named: list removeFirst]
		ifFalse:	[self currentDirectory]!

getVolumes
	"Return a string of all legal volume specifiers."
	<primitive: 614>
	^self errorReporter errorSignal raise! !