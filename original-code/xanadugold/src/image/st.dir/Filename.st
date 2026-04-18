'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:52:40 pm'!

Object subclass: #Filename
	instanceVariableNames: 'nameString '
	classVariableNames: 'DefaultClass DefaultDirectory '
	poolDictionaries: 'IOConstants '
	category: 'OS-Support'!
Filename comment:
'Class Filename is an abstract class.  Instances of its subclasses encapsulate the platform-specific syntax of OS file pathnames.  Actually, this class
can almost be used as a concrete class, except name syntax is not interpreted.  There is standard protocol provided to do most of the things that OS''s can do with references to files -- deleting, renaming, etc.

Instance Variables:
	nameString	<String> Platform-specific syntax naming a file.  Primitives "know" that the nameString is the first instance variable.

Class Variables:
	DefaultDirectory	<Filename> Starting point for relative references.
	DefaultClass		<Metaclass> The appropriate concrete subclass for this platform.

Pool Dictionaries:
	IOConstants	<Dictionary> of characters keyed by symbols
'!


!Filename methodsFor: 'instance creation'!

construct: extraFn
	"Make a new instance, treating the receiver as a directory, and
	the string argument as a file within the pathname."

	^self class named: (self constructString: extraFn)!

constructString: extraFn
	"Make a new file name string, treating the receiver as a directory, and
	the string argument as a file within the pathname."

	| ws prefix suffix sep |
	sep _ self separator.
	prefix _ nameString.
	suffix _ (extraFn size > 0 and: [ (extraFn at: 1) = sep ])
			ifTrue: [extraFn copyFrom: 2 to: extraFn size]
			ifFalse: [extraFn].
	ws _ WriteStream on: (String new: prefix size + suffix size + 1).
	ws nextPutAll: prefix.
	prefix last = sep
		ifFalse:	[ws nextPut: sep].
	ws nextPutAll: suffix.
	^ws contents! !

!Filename methodsFor: 'parsing'!

directory
	"Answer the filename of the directory for this Filename."

	^self class named: self head!

head
	"Answer the directory prefix as a String."

	| index |
	(index _ self lastIndexOf: self separator) ~= 0
		ifTrue:	[index _ index max: 2.
				^nameString copyFrom: 1 to: index-1]
		ifFalse:	[^self class defaultDirectoryName]!

tail
	"Answer the filename suffix as a String."

	| index |
	(index _ self lastIndexOf: self separator) ~= 0
		ifTrue:	[^nameString copyFrom: index+1 to: nameString size]
		ifFalse:	[^nameString copy]! !

!Filename methodsFor: 'testing'!

canBeWritten
	"Answer true if the file can be written."

	self exists
		ifTrue: [^self isWritable and: [self isDirectory not]]
		ifFalse: [^Filename errorReporter inaccessableSignal
					handle: [:ex | ex returnWith: false]
					do: [self directory isWritable]]!

isAbsolute
	"Answer true if this name is absolute (e.g. not relative to the
	'current directory')."

	nameString size = 0
		ifTrue:	[^false].
	^(nameString at: 1) == self separator!

isDirectory
	"Answer true if this name refers to a directory."

	^self isDirectoryErrInto: (self errorReporter new)!

isReadable
	"Answer whether the file can be read."

	^self exists!

isRelative
	"Answer true if this name must be interpreted relative to some
	directory."
	^self isAbsolute not!

isWritable
	"Answer true if the named file is writable by the current user."

	^self isWriteableErrInto: (self errorReporter new)! !

!Filename methodsFor: 'comparing'!

= aFilename 
	"Answer whether the receiver is equal to the argument"

	^self species = aFilename species and: [self class isCaseSensitive
			ifTrue: [nameString = aFilename asString]
			ifFalse: [nameString sameAs: aFilename asString]]!

hash 
	"Answer with a SmallInteger unique to the receiver."

	^nameString hash! !

!Filename methodsFor: 'converting'!

asFilename
	"Answer self"

	^self!

asString
	"Answer the OS-specific name string."

	^nameString! !

!Filename methodsFor: 'defaulting'!

concreteClass
	"Answer self class for concrete classes, defaultClass for abstract classes."

	^self class concreteClass!

defaultClass
	"Answer the appropriate default concrete subclass."

	^self class defaultClass!

species
	"Answer the appropriate class for new instances."

	^self concreteClass! !

!Filename methodsFor: 'constants'!

separator
	"Answer the platform's filename component separator."

	"Delegate to metaclass."
	^self class separator! !

!Filename methodsFor: 'file utilities'!

copyTo: destName
	"Copy the file whose name is the receiver to a file named destName."

	| buffer bufferSize sourceFile destFile amountRead |
	sourceFile _ IOAccessor openFileReadOnly: self.
	destFile _ IOAccessor openFileWriteOnly: destName asFilename.
	[bufferSize _ sourceFile bufferSize.
	buffer _ ByteArray new: bufferSize.
		"Copy until we have a read that is less than buffer size"
	[(amountRead _ sourceFile readInto: buffer) = bufferSize] whileTrue:
		[destFile writeAll: buffer].
	"Copy any thing left over"
	amountRead > 0
		ifTrue: [destFile writeFrom: buffer startingAt: 1 forSure: amountRead]
	] valueNowOrOnUnwindDo: 
		[sourceFile close.
		destFile close]!

delete
	"Delete the reference to the named file (which is slightly different
	than saying 'deleting the file', but means the same thing in most cases)."

	self deleteErrInto: (self errorReporter new)!

directoryContents
	"Returns Array of strings -- the contents of the directory.
	Not Array of Filenames because we'd have to prepend directory names."

	^self listDirectoryErrInto: self errorReporter new.!

exists
	"Answer true if the named file exists."

	^OSErrorHolder nonexistentSignal
		handle:	[ :ex |	ex returnWith: false	]
		do: [self existsErrInto: (self errorReporter new)]!

fileSize
	"Answer the size (in bytes) of the corresponding file."

	^self fileSizeErrInto: (self errorReporter new)!

filesMatching: string
	"Answer an OrderedCollection of files matching string."

	| list allFiles |
	list _ self class components: string.
	allFiles _ OrderedCollection new.
	self filesMatchingAccessList: list into: allFiles.
	^allFiles!

makeDirectory
	"Create a directory with this name."

	self makeDirectoryErrInto: (self errorReporter new)!

makeUnwritable
	"Make this named file unwritable in the broadest sense
	(e.g. to at least the current user, but to everyone if possible)."

	self setWriteable: false errInto: (self errorReporter new)!

makeWritable
	"Make the corresponding file writable in the narrowest
	sense (e.g. at least to the current user)."

	self setWriteable: true errInto: (self errorReporter new)!

moveTo: destName
	"Copy the file whose name is the receiver to a file named destName."

	self copyTo: destName.
	self delete!

renameTo: aFileName
	"Substitute the new name for the old one (a.k.a. 'rename the file')."

	self renameTo: aFileName asFilename errInto: (self errorReporter new)! !

!Filename methodsFor: 'utilities'!

contentsOfEntireFile
	"Answer the contents of the file represented by
	the receiver."

	| stream contents |
	stream _ self readStream.
	[stream lineEndConvention = LineEndCRLF
		ifTrue:	[contents _ stream contents]
		ifFalse:	[contents _ stream next: self fileSize]
	] valueNowOrOnUnwindDo: [stream close].
	^contents!

dates
	"Answer a Dictionary with the file's access dates."

	| dts bytes |
	dts _ IdentityDictionary new: 3.
	bytes _ self getDatesErrInto: self errorReporter new.
	1 to: 3 do: 
		[:i | 
		| secs start dateAndTime |
		start _ i - 1 * 4 + 1.
		secs _ UninterpretedBytes with: bytes from: start to: start + 3.
		(secs unsignedLongAt: 1) = 0
			ifTrue:	[dateAndTime _ nil]
			ifFalse:	[dateAndTime _ Time aTime: (secs unsignedLongAt: 1)].
		dts at: (#(accessed modified statusChanged ) at: i)
			put: dateAndTime].
	^dts!

{String} differences: fromFile {Filename}

	self contentsOfEntireFile = fromFile contentsOfEntireFile
		ifTrue: [^ '']
		ifFalse: [^ self lineCompare: fromFile]!

edit
	"Edit the contents of the file represented by
	the receiver."

	FileModel 
		open: (FileModel fileName: self)
		named: nameString!

fileIn
	"FileIn the contents of the file represented by
	the receiver."

	Transcript cr; cr; show: 'Filing in from:'; crtab; show: self asString; cr.
	^self readStream fileIn!

fileOutChanges
	"FileOut changes on the file represented by
	the receiver."


	Transcript cr; cr; show: ('Filing out changes on:'); crtab; show: self asString.
	self writeStream fileOutChanges!

fileOutChangesFor: class
	"FileOut changes for class on the file represented by
	the receiver."

	self writeStream fileOutChangesFor: class!

{String} lineCompare: otherFile {Filename} 
	| first other results lineCnt l1 l2 |
	first _ self readStream.
	other _ otherFile readStream.
	
	[results _ WriteStream on: ''.
	lineCnt _ 0.
	[first atEnd | other atEnd]
		whileFalse: [lineCnt _ lineCnt + 1.
			(l1 _ self nextLine: first) = (l2 _ self nextLine: other) 
					ifFalse: [results << '<' << l1 << '>' << l2]].
	[first atEnd]
		whileFalse: [results << '<' << (self nextLine: first)].
	[other atEnd]
		whileFalse: [results << '>' << (self nextLine: other)]]
		valueNowOrOnUnwindDo: [first close.
			other close].
	^results contents!

{String} nextLine: fromStream {ReadStream}

	^ fromStream through: Character cr.!

requestFileName: message default: default version: versionType ifFail: failBlock
	"Prompt for a file name.  Insist on an existing file if versionType = #old.  Evaluate failBlock if none obtained." 

	"Filename defaultDirectory requestFileName: 'file:' default: '*.st' version: #any ifFail: [] "

	| fileName list menu index err list2 eraseString |
	fileName _ default.
	[true] whileTrue: 
		[fileName _ FillInTheBlank request: message initialAnswer: fileName.
		fileName isEmpty
			ifTrue: [^failBlock value].
		((fileName includes: $*) or: [fileName includes: $#])
			ifTrue:
				[list _ self filesMatching: fileName.
				eraseString _ self constructString: ''.
				list2 _ list collect:
					[:name |
					(name findString: eraseString startingAt: 1) = 1
						ifTrue: [name copyFrom: eraseString size + 1 to: name size]
						ifFalse: [name]]	.
				menu _ PopUpMenu
							labelList: (Array
											with: list2
											with: #('new pattern' 'abort')).
				index _ menu startUpWithHeading:
					(list isEmpty
						ifTrue: [' No Matches ']
						ifFalse: ['Choose a file from ', (self constructString: fileName)]) asText.
				(index == 0 or: [index = (list size + 2)])
					ifTrue: [^failBlock value].
				index <= list size ifTrue: [^list at: index]]
			ifFalse:
				[(self directoryContents includes: fileName) ifTrue: [^fileName].
				versionType ~= #old ifTrue: [^fileName].
				fileName = (self class named: fileName) asString
					ifTrue: [err _ ' File not found: \  ']
					ifFalse: [err _ ' Illegal file name: \  '].
				menu _ PopUpMenu labels: 'try again\abort' withCRs.
				(menu startUpWithHeading: err withCRs , fileName , ' ') = 2
					ifTrue: [^failBlock value]]]! !

!Filename methodsFor: 'stream creation'!

appendStream
	"Answer a write stream connected to the file represented by
	the receiver."

	^ExternalWriteStream on: (FileConnection
			openFileNamed: self
			mode: #appendOnly
			creationRule: #mayCreate)!

newReadAppendStream
	"Answer a new readAppend stream connected to the file represented by
	the receiver."

	^ExternalReadAppendStream on: (FileConnection
			openFileNamed: self
			mode: #readAppend
			creationRule: #truncateOrCreate)!

newReadWriteStream
	"Answer a new readWrite stream connected to the file represented by
	the receiver."

	^ExternalReadWriteStream on: (FileConnection
			openFileNamed: self
			mode: #readWrite
			creationRule: #truncateOrCreate)!

readAppendStream
	"Answer a readAppend stream connected to the file represented by
	the receiver."

	^ExternalReadAppendStream on: (FileConnection
			openFileNamed: self
			mode: #readAppend
			creationRule: #mayCreate)!

readStream
	"Answer a read stream connected to the file represented by
	the receiver."

	^ExternalReadStream on: (FileConnection
			openFileNamed: self
			mode: #readOnly
			creationRule: #noCreate)!

readWriteStream
	"Answer a readWrite stream connected to the file represented by
	the receiver."

	^ExternalReadWriteStream on: (FileConnection
			openFileNamed: self
			mode: #readWrite
			creationRule: #mayCreate)!

writeStream
	"Answer a write stream connected to the file represented by
	the receiver."

	^ExternalWriteStream on: (FileConnection
			openFileNamed: self
			mode: #writeOnly
			creationRule: #truncateOrCreate)! !

!Filename methodsFor: 'error reporting'!

errorReporter
	"Answer the appropriate error forwarder (e.g. the one who
	can interpret errorHolders) for me."

	^self class errorReporter!

reportError
	"Some error occured.  Have the error reporter signal it."

	self errorReporter reportOn: self!

reportErrorProceeding
	"Some error occured.  Have the error reporter signal it, permitting
	the signal handler to proceed."

	^self errorReporter reportProceedingOn: self! !

!Filename methodsFor: 'printing'!

printOn: aStream
	"Append to the argument aStream a sequence of characters that identifies the receiver."
	"Amplifies method in superclass to add name string."

	super printOn: aStream.
	aStream nextPut: $(.
	aStream print: self asString.
	aStream nextPut: $)! !

!Filename methodsFor: 'primitives'!

deleteErrInto: anErrorHolder
	"Delete the named file (or directory, if it's empty). Essential."
	<primitive: 621>
	anErrorHolder reportFor: self!

existsErrInto: anErrorHolder
	"Answer true if the named file exists. Essential."
	<primitive: 629>
	^anErrorHolder reportFor: self!

fileSizeErrInto: anErrorHolder
	"Answer size of file in bytes. Essential."
	"However, not all files have sizes..."

	<primitive: 626>
	anErrorHolder reportFor: self!

getDatesErrInto: anErrorHolder
	"Answer ByteArray of times
	(4 bytes unsigned ints each in platform order,
	measured in secs since 00:00:00 GMT, Jan. 1, 1970)
	 - first element is 'last accessed' time
	 - second element is 'last modified' time
	 - third element is 'last status changed' time
	A platform is free to return 0 for any field, which is
	interpreted as 'unknown'."
	<primitive: 610>
	anErrorHolder reportFor: self!

isDirectoryErrInto: anErrorHolder
	"Answer true if the named corresponds to a directory. Essential."
	<primitive: 622>
	anErrorHolder reportFor: self!

isWriteableErrInto: anErrorHolder
	"Answer true if file is writable by this user.  Essential.
	Writable for a directory means that new files can be
	created or old ones renamed."
	<primitive: 627>
	anErrorHolder reportFor: self!

listDirectoryErrInto: anErrorHolder
	"Receiver is a directory name.  Return an array of strings
	naming files contained in this directory. Essential."
	<primitive: 620>
	anErrorHolder reportFor: self!

makeDirectoryErrInto: anErrorHolder
	"Create the named directory. Essential."
	<primitive: 624>
	anErrorHolder reportFor: self!

renameTo: aFileName errInto: anErrorHolder
	"Give the file referred to by the receiver the
	new name of the first arg (this may move the file to
	a different directory). Essential."
	<primitive: 623>
	anErrorHolder reportFor: self!

setWriteable: boolean errInto: anErrorHolder
	"Set the named file (or directory) to be writeable/unwritable.
	Writable for a directory means that new files can be
	created or old ones renamed.  Essential."
	"The current user may not be able to change the permissions
	for this file."

	<primitive: 628>
	anErrorHolder reportFor: self! !

!Filename methodsFor: 'private: private'!

filesMatchingAccessList: list into: allNames 

	| contents pref sublist fullName isPattern isCaseSensitive |
	list isEmpty
		ifTrue:	[^allNames].
	pref _ list first.
	sublist _ list copyFrom: 2 to: list size.
	isPattern _ ((pref includes: $*) or: [ pref includes: $# ]).
	isCaseSensitive _ self class isCaseSensitive.
	contents _ self directoryContents.
	contents do:
		[:name |
		(isPattern
			ifTrue:	[(pref match: name ignoreCase: isCaseSensitive not)]
			ifFalse:	[isCaseSensitive not
						ifTrue:	[name asUppercase = pref asUppercase]
						ifFalse:	[name = pref]])
			ifTrue: 
				[fullName _ self construct: name.
				sublist isEmpty
					ifTrue: [allNames add: fullName asString]
					ifFalse: [fullName isDirectory
						ifTrue: [fullName
										filesMatchingAccessList: sublist
										into: allNames]].
				isPattern
					ifFalse:	[^self]]]!

lastIndexOf: aChar 
	"Answer the index of the last character in my nameString which 
	matches aChar, if none, answer 0."
	"Used to split nameStrings into head and tail components."

	nameString size
		to: 1
		by: -1
		do: [:i | (nameString at: i)
				= aChar ifTrue: [^i]].
	^0!

named: n
	"Set the OS-specific pathname."
	"Only appropriate at instance creation."

	nameString _ n.
	nameString size = 0
		ifTrue:	[^self].
	(nameString last == self separator and: [nameString size > 1])
		ifTrue: [nameString _ nameString copyFrom: 1 to: nameString size -1]! !

!Filename methodsFor: 'copying'!

copy

	^self class named: self asString copy! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

Filename class
	instanceVariableNames: ''!


!Filename class methodsFor: 'class initialization'!

findDefaultDirectory
	"Determine the default directory name and cache it as a Filename.
	Typically done at snapshot-return time."

	| str fn e |
	str _ DefaultClass defaultDirectoryErrInto: (e _ self errorReporter new).
	fn _ DefaultClass new named: str.
	^fn!

hookupTo: pn
	"The receiver has become the default class for some OSHandle subclass.  Get prepared."

	"Can't do ^self subclassResponsibility because we might break return-from-snapshot."
	Transcript cr; show: 'Warning -- No concrete class for ', self class name!

install
	"The receiver is the default class for Filenames, and installs itself."
	"Do nothing for abstract classes."! !

!Filename class methodsFor: 'class accessing'!

defaultClass: cls
	"Assign the appropriate concrete subclass for this platform.
	Only done at start-up."

	DefaultClass _ cls! !

!Filename class methodsFor: 'instance creation'!

named: str
	"Answer a new Filename with the supplied name string."
	"Avoid infinite recursion if there is no concrete subclass."

	| cstr conClass |
	str isEmpty
		ifTrue:	[OSErrorHolder invalidArgumentsSignal raiseWith: str].
	conClass _ self concreteClass.
	cstr _ conClass canonicalize: str.
	cstr isEmpty
		ifTrue:	[OSErrorHolder invalidArgumentsSignal raiseWith: str].
	conClass == self ifTrue: [^self new named: cstr].
	^conClass named: cstr! !

!Filename class methodsFor: 'defaults'!

concreteClass
	"Answer self for concrete classes, defaultClass for abstract classes."

	self == Filename ifTrue: [^self defaultClass].
	^self!

currentDirectory
	"Answer a filename representing the relative path name from the
	current directory to itself.  On DOS and Unix platforms, this is '.'.
	On Macs, it is ':'"

	(self == Filename and: [self ~~ self defaultClass])
		ifTrue:	[^self defaultClass currentDirectory].
	^self named: self currentDirectoryString!

currentDirectoryString
	"Return the platform-specific token that represents the current directory.
	In the default case, use the absolute path name"

	^self defaultDirectoryName!

defaultClass
	"Answer the appropriate concrete subclass."

	^DefaultClass!

defaultDirectory
	"Answer the default directory (e.g. interpretation starting point for
	relative names)."

	^DefaultDirectory copy!

defaultDirectoryName
	"Answer the default directory (e.g. interpretation starting point for
	relative names)."

	^DefaultDirectory asString copy!

errorReporter
	"Return the appropriate error code interpreter."

	| dc |
	dc _ self defaultClass.
	^dc == Filename ifTrue: [OSErrorHolder] ifFalse: [dc errorReporter]! !

!Filename class methodsFor: 'primitives'!

defaultDirectoryErrInto: anErrorHolder
	"Answer the default directory name (platform-specific) as a String.
	Essential."
	<primitive: 625>
	anErrorHolder reportFor: self! !

!Filename class methodsFor: 'constants'!

changeExtension
	"Answer the platform's changes filename extension."

	^'.cha'!

imageExtension
	"Answer the platform's image filename extension"

	^'.im'!

logExtension
	^ '.log'!

maxLength
	"Answer the maximum length that for a platform pathname."

	self concreteClass == Filename ifTrue: [^self subclassResponsibility].
	^self concreteClass maxLength!

separator
	"Answer the platform's filename component separator."

	self concreteClass == Filename ifTrue: [^self subclassResponsibility].
	^self concreteClass separator!

sourceExtension
	"Answer the platform's sources filename extension."

	self concreteClass == Filename ifTrue: [^self subclassResponsibility].
	^self concreteClass sourceExtension!

uglyReplacement
	"Answer a character which can be used to substitute for ugly characters in filenames."

	^$_		"underscore, silly!!"! !

!Filename class methodsFor: 'parsing'!

breakup: str 
	"Answer an ordered collection of (Array with: substr with: delim) 
	which is the original string broken into chunks 
	(treating non-alphanumeric characters as delimitors.)"

	| oc subws delimws inDelim |
	oc _ OrderedCollection new.
	subws _ WriteStream on: (String new: 24).
	delimws _ WriteStream on: (String new: 8).
	inDelim _ false.
	str do: [:c | inDelim
			ifTrue: [c isAlphaNumeric
					ifTrue: 
						[oc add: (Array with: subws contents with: delimws contents).
						subws reset.
						delimws reset.
						inDelim _ false.
						subws nextPut: c]
					ifFalse: [delimws nextPut: c]]
			ifFalse: [c isAlphaNumeric
					ifTrue: [subws nextPut: c]
					ifFalse: 
						[inDelim _ true.
						delimws nextPut: c]]].
	(subws size > 0 or: [delimws size > 0])
		ifTrue: [oc add: (Array with: subws contents with: delimws contents)].
	^oc!

components: nameString
	"Break a filename into path compoents, answer an OrderedCollection of components."

	| components separator component stream |
	components _ OrderedCollection new.
	separator _ self separator.
	stream _ nameString readStream.
	(component _ self readBaseLocationFromStream: stream) isEmpty
		ifFalse:	[components add: component].
	[stream atEnd]
		whileFalse:
			[components add: (stream upTo: separator)].
	^components!

isBadCharacter: aChar
	"Answer if this character is in illegal for a platform
filename string."

	"Assume nobody likes unprintable characters."
	| cv |
	cv _ aChar asciiValue.
	cv < 32 "space" ifTrue: [^true].
	cv >= 8r177 "del" ifTrue: [^true].
	^false!

isUglyCharacter: aChar
	"Answer if this character is in bad taste for a platform
filename string."

	^self isBadCharacter: aChar!

lastIndexOf: aChar in: str
	"Answer the index of the last character in my nameString which 
	matches aChar, if none, answer 0."
	"Used to split nameStrings into head and tail components."

	str size
		to: 1
		by: -1
		do: [:i | (str at: i)
				= aChar ifTrue: [^i]].
	^0!

localNameStringFrom: aString
	"Answer a string that is aString, modified to fit the platform's
	definition of a relative path name.  No syntax checking is done."

	aString first = self separator
		ifTrue:	[^aString copyFrom: 2 to: aString size]
		ifFalse:	[^aString]!

mapUglies: str
	"Answer string with repeated runs of uglies mapped to a single replacement character."

	| ws uglies |
	ws _ WriteStream on: (String new: str size).
	uglies _ false.
	1 to: str size do: 
		[:i | 
		| c |
		c _ str at: i.
		(self isUglyCharacter: c)
			ifFalse: [uglies _ false. ws nextPut: c]
			ifTrue: [uglies ifFalse: [uglies _ true. ws nextPut: self uglyReplacement]]].
	^ws contents.!

readBaseLocationFromStream: stream
	"Answer the root of a (semi)absolute path name."

	^(stream peekFor: self separator)
		ifTrue:	[String with: self separator]
		ifFalse:	[String new]!

shrink: str to: len dropDelim: dropDelim
	"Answer a string which is shortened to size len without making it 
	unrecognizable, with runs of ugly characters replaced.
	Non alphanumerics are dropped if dropDelim is true."

	| nstr need cnt chunks chunklen ws windfall |
	"First contract runs of ugly characters to a single character."
	nstr _ self mapUglies: str.
	nstr size <= len ifTrue: [^nstr].
	"Not good enough, try harder."
	need _ nstr size - len.
	"Try dropping vowels."
	cnt _ nstr dropFinalVowels size.
	cnt <= len ifTrue: [^nstr dropVowels: need].
	"Not good enough, break into substrings and shorten those."
	chunks _ self breakup: nstr.
	chunklen _ len // chunks size.
	windfall _ len - (chunklen * chunks size).
	ws _ WriteStream on: (String new: len).
	chunks do: [:arry |
		| sub delim target extra |
		sub _ arry at: 1.
		delim _ arry at: 2.
		target _ chunklen + windfall.
		extra _ (dropDelim or: [target <= 2]) ifTrue: [0] ifFalse: [1 min: delim size].
		(sub size + extra) <= target
			ifTrue: ["It fits as it!!"
					ws nextPutAll: sub.
					target _ target - sub size]
			ifFalse: ["Try dropping vowels."
					(sub dropFinalVowels size + extra) <= target
						ifTrue: [ws nextPutAll: (sub dropVowels: sub size - (target - extra))]
						ifFalse: [ws nextPutAll: (sub chopTo: target - extra)].
					target _ extra].
		extra == 0 ifFalse: [ws nextPut: (delim at: 1)].
		windfall _ target - extra].
	^ws contents!

splitExtension: fullName
	"Answer an Array with: theName with: extension."

	| extIndex theName extension |
	extIndex _ self lastIndexOf: $. in: fullName.
	theName _ (extIndex == 1)
			ifTrue: ['']
			ifFalse: [fullName
						copyFrom: 1
						to: (extIndex == 0
							ifTrue: [fullName size]
							ifFalse: [extIndex - 1])].
	extension _ (extIndex > 0 and: [fullName size > extIndex])
		ifTrue: [fullName copyFrom: extIndex + 1 to: fullName size]
		ifFalse: [extIndex == 0 ifTrue: [nil] ifFalse: ['']].
	^Array with: theName with: extension!

splitPath: fullName
	"Answer an Array with: head with: tail."

	| sepIndex head tail |
	sepIndex _ self lastIndexOf: self separator in: fullName.
	sepIndex < 1
		ifTrue: [^Array with: '' with: fullName copy].
	head _ fullName copyFrom: 1 to: sepIndex.
	tail _ fullName size > sepIndex
		ifTrue: [fullName copyFrom: sepIndex + 1 to: fullName size]
		ifFalse: [''].
	^Array with: head with: tail!

suggest: str 
	"Answer a string which is in good taste as a filename on this 
	platform."

	^self canonicalize: str! !

!Filename class methodsFor: 'utilities'!

filesMatching: string

	| list allFiles |
	(self == Filename and: [self ~~ self defaultClass])
		ifTrue:	[^self defaultClass filesMatching: string].
	list _ self components: string.
	allFiles _ OrderedCollection new.
	list isEmpty
		ifTrue:	[^allFiles].
	(self baseDirectoryForList: list) filesMatchingAccessList: list into: allFiles.
	^allFiles!

request: prompt initially: fstring shouldExist: shouldExist 
	"Prompt for a filename, using the prompt message and an initial 
	answer.  Persist a little if the file should exist but doesn't, or vice-versa.
	nil shouldExist means no opinion.  Assumes that initial value does not intentionally
	have any volume or directory specifications (e.g. /'s are stripped).
	Answer a string."

	| ws scp response suggested retry fn |
	suggested _ self concreteClass suggest: (self filterSeps: fstring).
	scp _ Sensor cursorPoint.
	[retry _ false.
	ws _ WriteStream on: (String new: prompt size + (fstring size * 2) + 10).
	ws nextPutAll: prompt.
	suggested ~= fstring
		ifTrue: 
			[ws nextPut: Character cr.
			ws nextPut: ${.
			ws nextPutAll: 'Item''s name is: "'.
			ws nextPutAll: fstring.
			ws nextPutAll: '"}'].
	FillInTheBlank
		request: ws contents
		displayAt: scp
		centered: true
		action: [:resp | response _ resp]
		initialAnswer: suggested.
	(response size > 0 and: [shouldExist notNil]) ifTrue: [
		fn _ Filename named: response.
		shouldExist
			ifTrue: [(self errorReporter errorSignal handle: [:ex | ex returnWith: false]
					do: [fn exists])
					ifFalse: [retry _ (BinaryChoice message:
										'File does not exist. Use this name anyway?') not]]
			ifFalse: [(self errorReporter errorSignal handle: [:ex | ex returnWith: false]
					do: [fn exists])
					ifTrue: [retry _ (BinaryChoice message:
										'File already exists. Use this name anyway?') not]]].
	retry] whileTrue.
	^response!

requestFileName: message default: default version: versionType ifFail: failBlock
	"Prompt for a file name.  Insist on an existing file if versionType = #old.
	Evaluate failBlock if none obtained." 
	"Filename requestFileName: 'file:' default: '*.st' version: #any ifFail: []"

	| fileName list menu index err list2 currentDir|
	fileName _ default.
	currentDir _ self defaultDirectoryName copyWith: self separator.
	[true] whileTrue: 
		[fileName _ FillInTheBlank request: message initialAnswer: fileName.
		fileName isEmpty
			ifTrue: [^failBlock value].
		((fileName includes: $*) or: [fileName includes: $#])
			ifTrue:
				[list _ self filesMatching: fileName.
				list2 _ list collect:
					[:fname |
					(fname findString: currentDir startingAt: 1) = 1
						ifTrue: [fname copyFrom: currentDir size + 1 to: fname size]
						ifFalse: [fname]]	.
				menu _ PopUpMenu
							labelList: (Array
											with: list2
											with: #('new pattern' 'abort')).
				index _ menu startUpWithHeading:
					(list isEmpty
						ifTrue: [' No Matches ']
						ifFalse: ['Choose a file']) asText.
				(index == 0 or: [index = (list size + 2)])
					ifTrue: [^failBlock value].
				index <= list size ifTrue: [^list2 at: index]]
			  ifFalse:
				[fileName asFilename exists
					ifTrue: [^fileName].
				versionType ~= #old
					ifTrue: [^fileName].
				fileName = fileName asFilename asString
					ifTrue: [err _ ' File not found: \  ']
					ifFalse: [err _ ' Illegal file name: \  '].
				menu _ PopUpMenu labels: 'try again\abort' withCRs.
				(menu startUpWithHeading: err withCRs , fileName , ' ') = 2
					ifTrue: [^failBlock value]]]!

unfilteredRequest: prompt initially: fstring shouldExist: shouldExist 
	"Prompt for a filename, using the prompt message and an initial 
	answer.  Persist a little if the file should exist but doesn't, or vice-versa.
	nil shouldExist means no opinion.  Assumes that initial value does not intentionally
	have any volume or directory specifications (e.g. /'s are stripped).
	Answer a string."

	| ws scp response suggested retry fn |
	suggested _ fstring.
	scp _ Sensor cursorPoint.
	[retry _ false.
	ws _ WriteStream on: (String new: prompt size + (fstring size * 2) + 10).
	ws nextPutAll: prompt.
	suggested ~= fstring
		ifTrue: 
			[ws nextPut: Character cr.
			ws nextPut: ${.
			ws nextPutAll: 'Item''s name is: "'.
			ws nextPutAll: fstring.
			ws nextPutAll: '"}'].
	FillInTheBlank
		request: ws contents
		displayAt: scp
		centered: true
		action: [:resp | response _ resp]
		initialAnswer: suggested.
	(response size > 0 and: [shouldExist notNil]) ifTrue: [
		fn _ Filename named: response.
		shouldExist
			ifTrue: [(self errorReporter errorSignal handle: [:ex | ex returnWith: false]
					do: [fn exists])
					ifFalse: [retry _ (BinaryChoice message:
										'File does not exist. Use this name anyway?') not]]
			ifFalse: [(self errorReporter errorSignal handle: [:ex | ex returnWith: false]
					do: [fn exists])
					ifTrue: [retry _ (BinaryChoice message:
										'File already exists. Use this name anyway?') not]]].
	retry] whileTrue.
	^response!

volumes
	"Answer an Array of Strings naming all reachable disk volumes."
	self == Filename ifTrue: [^self defaultClass volumes].
	^Array with: self defaultDirectory asString! !

!Filename class methodsFor: 'private: private'!

baseDirectoryForList: list

	^list first = (String with: self separator)
		ifTrue:	[self named: list removeFirst]
		ifFalse:	[self currentDirectory]!

canonicalize: str
	"Convert this string to a canonical platform pathname string.
	This may make for arbitrary, unpleasent transformations, like
	truncating to 8 characters, folding to upper case, etc."

	^str reject: [:c | self isBadCharacter: c]!

filterSeps: str
	"Answer string with separators mapped out."

	| sep |
	sep _ self separator.
	^str collect: [:c | c == sep ifTrue: [self uglyReplacement] ifFalse: [c]]!

setSeparator: aChar
	"Set the filename separator to be aChar."

	FileDirectory separator: aChar! !

!Filename class methodsFor: 'defaulting'!

isCaseSensitive
	"Answer whether file naming is case sensitive.  True, for example, means
	that 'foo.st' and 'Foo.st' name different files.
	Subclasses reflecting case insensitive names should overwrite this message."

	self == Filename
		ifTrue:	[^self defaultClass isCaseSensitive].
	^true! !