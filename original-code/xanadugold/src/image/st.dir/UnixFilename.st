'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:52:51 pm'!

Filename subclass: #UnixFilename
	instanceVariableNames: ''
	classVariableNames: 'LengthLimit '
	poolDictionaries: ''
	category: 'OS-Unix'!
UnixFilename comment:
'Refines class Filename to add unix-specific behavior such as access date interpretation.

Class Variables:
	LengthLimit	<SmallInteger> 	Maximum length of a filename component. (Different between Sys-V and 4.n derived systems)'!


!UnixFilename methodsFor: 'testing'!

isReadable
	"Answer true if the file is readable."
	"Implemented by opening the file for reading, then closing it.
	BUG: This doesn't work if the file is a directory!!"
	
	^UnixIOAccessor errorSignal handle: [:ex | ex returnWith: false]
		do: 
			[(UnixIOAccessor openFileReadOnly: self) close.
			true]! !

!UnixFilename methodsFor: 'parsing'!

extension
	"Answer a String with the file extension (chars after a period) if any."
	| di |
	di _ self lastIndexOf: $..
	di = 0 ifTrue: [^''].
	^nameString copyFrom: di + 1 to: nameString size! !

!UnixFilename methodsFor: 'utilities'!

getProtection
	"Return the file's protection mode"

	^self primGetProtectionErrInto: self errorReporter new!

printFile
	"print a PostScript file--may be installation specific."

	| cmd proc reply connection |
	connection _ UnixProcess pipeConnectionFor: 'lpr'
			arguments: (Array with: nameString)
			setProcessDescriptor: [:pd | proc _ pd].
	[cmd _ connection readStream.
	reply _ cmd contents.
	proc wait]
		valueNowOrOnUnwindDo:
			[connection close.
			"Process will remove itself, eventually"].
	Transcript show: reply!

setProtection: mode
	"Set the file's protection mode to 'mode'."

	^self primSetProtection: mode errInto: self errorReporter new! !

!UnixFilename methodsFor: 'private: private'!

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
	"UnixFilename must be ByteString."

	super named: n asByteString!

primGetProtectionErrInto: anErrorHolder
	"Return the file's protection mode."

	<primitive: 617>
	anErrorHolder reportFor: self!

primSetProtection: mode errInto: anErrorHolder
	"Set the file's protection mode to 'mode'."

	<primitive: 615>
	anErrorHolder reportFor: self! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

UnixFilename class
	instanceVariableNames: ''!


!UnixFilename class methodsFor: 'class initialization'!

hookupTo: pn
	"You have become the concrete class for Filename.  Prepare yourself."

	"Probably should use an ordered collection of patterns (from most to least specific)
	with corresponding selectors to perform.  This will have to do for now."
	"The difference between the two unixes we have to deal with here is
	filename length limit."
	('* sys# *' match: pn)
		ifTrue: [LengthLimit _ 14]
		ifFalse: [LengthLimit _ 255]!

install

	self setSeparator: $/.
	DefaultDirectory _ self findDefaultDirectory! !

!UnixFilename class methodsFor: 'defaulting'!

currentDirectoryString
	"Return the platform-specific token that represents the current directory"

	^'.'!

errorReporter
	"Answer the class which can do error interpretation for me."

	^UnixErrorHolder! !

!UnixFilename class methodsFor: 'constants'!

changeExtension
	"Answer the platform's changes filename extension."

	^'.cha'!

imageExtension
	"Answer the platform's image filename extension"

	^'.im'!

maximumComponentLength
	"Answer the maximum size of a single component of a path"

	^LengthLimit!

maxLength
	"Answer the maximum length for a platform pathname."

	^255!

separator
	"Answer the platform's filename component separator."

	^$/!

sourceExtension
	"Answer the platform's sources filename extension."

	^'.sources'! !

!UnixFilename class methodsFor: 'parsing'!

canonicalize: str 
	"Convert this string to a canonical platform pathname string. 
	This may make for arbitrary, unpleasent transformations, like 
	truncating to 8 characters, folding to upper case, etc."

	| components ws maxComponent skipBack |
	str = '.' ifTrue: [^str].
	maxComponent _ self maximumComponentLength.
	ws _ WriteStream on: (String new: self maxLength).
	skipBack _ false.
	components _ self components: str.
	components first last = self separator
		ifTrue:	[ws nextPutAll: components removeFirst].
	components do: [:pn |
		(ws size + (pn size min: maxComponent)) < self maxLength ifTrue: [
			(pn size > 0 and: [pn ~= '.'])
				ifTrue: [
					1 to: (pn size min: maxComponent) do: 
						[:i | 
						| c |
						c _ pn at: i.
						(self isBadCharacter: c) ifFalse: [ws nextPut: c]].
					skipBack _ true.
					ws nextPut: self separator]]].
	skipBack
		ifTrue:	[ws skip: -1].
	^ws contents!

isBadCharacter: aChar
	"Answer if this character is illegal for a platform
filename string."

	^aChar asciiValue == 0 or: [aChar == $/]!

isUglyCharacter: aChar
	"Answer if this character is in bad taste for a platform
pathname string."

	| cv |
	cv _ aChar asciiValue.
	cv <= 32 "space" ifTrue: [^true].
	cv >= 8r177 "del" ifTrue: [^true].
	'*?><|&!!"''`#$[](){}^;\~%' do: [:uc | aChar == uc
ifTrue: [^true]].
	^false!

suggest: str 
	"Answer a string which is in good taste as a filename on this 
	platform"

	| fullName path moniker newName extension pair ws llimit |
	llimit _ self maximumComponentLength.
	pair _ self splitPath: str.
	path _ pair at: 1.
	fullName _ pair at: 2.
	pair _ self splitExtension: fullName.
	moniker _ pair at: 1.
	extension _ pair at: 2.
	ws _ WriteStream on: (String new: str size).
	ws nextPutAll: path.
	ws nextPutAll: (newName _ self
					shrink: moniker
					to: llimit - (4 min: (extension notNil ifTrue: [extension size + 1] ifFalse: [0]))
					dropDelim: false).
	(extension notNil and: [newName size < llimit])
			ifTrue: 
				[ws nextPut: $..
				(newName size + 1 < llimit and: [extension size > 0])
					ifTrue: [ws nextPutAll: (self
							shrink: extension
							to: llimit - 1 - newName size
							dropDelim: true)]].
	^self canonicalize: ws contents! !

!UnixFilename class methodsFor: 'utilities'!

setCreationMask: mask
	"Change the default creation mask to 'mask' and return the old value"

	^self primSetCreationMask: mask errInto: self errorReporter new!

volumes
	"Answer an Array of Strings naming all reachable disk volumes."

	^Array with: '/'! !

!UnixFilename class methodsFor: 'primitives'!

primSetCreationMask: mask errInto: anErrorHolder
	"Change the default creation mask to 'mask' and return the old value"

	<primitive: 616>
	anErrorHolder reportFor: self.
	^0! !