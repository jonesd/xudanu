'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:53:06 pm'!

MacFilename subclass: #MacOSFilename
	instanceVariableNames: 'volumeReference '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'OS-Mac-Support'!
MacOSFilename comment:
'MacOSFilename adds the notion of a VREF to the filename.  Allows the Advanced Macintosh/Smalltalk programmer to use the Macintosh Standard File Utilities to get and put files.  Allows application writers to get a list of the files clicked to run the VM/VI.  Adds the ''getInfo'' capability to determine the file type, creator, data size, res. size, creation date, mod date.'!


!MacOSFilename methodsFor: 'utilities'!

putFileWithPrompt: aString
	" put file via StdFile manager"

	^self putFileWithPrompt: aString errInto: self errorReporter new!

stringFromVRef
	" get the equiv string from vRef"

	^self stringFromVRefErrInto: self errorReporter new! !

!MacOSFilename methodsFor: 'accessing'!

volumeReference
	^volumeReference! !

!MacOSFilename methodsFor: 'private: private'!

getFileInfo
	"get file statistics"

	" (MacOSFilename getFileTypes: #('TEXT' 'HPSF') ) getFileInfo"

	| stat bytes dts |
	stat _ self getFileInfoErrInto: self errorReporter new.
	bytes _ stat at: 6.
	dts _ IdentityDictionary new: 2.
	1 to: 2 do: 
		[:i | 
		| secs start dateAndTime |
		start _ i - 1 * 4 + 1.
		secs _ UninterpretedBytes with: bytes from: start to: start + 3.
		(secs unsignedLongAt: 1) = 0
			ifTrue:	[dateAndTime _ nil]
			ifFalse:	[dateAndTime _ Time aTime: (secs unsignedLongAt: 1)].


		dts at: (#(created modified) at: i)
			put: dateAndTime].
	stat at: 6 put: dts.
	^stat!

getFileInfoErrInto: errorHandler
	" put file via StdFile manager"
	<primitive: 758>
	^errorHandler reportError!

named: aString volumeReference: aNumber
	super named: aString.
	volumeReference _ aNumber!

putFileWithPrompt: aString errInto: errorHandler
	" put file via StdFile manager"
	<primitive: 757>
	^errorHandler reportError!

stringFromVRefErrInto: errorHandler
	" get the equiv string from vRef"
	<primitive: 759>
	^errorHandler reportError! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

MacOSFilename class
	instanceVariableNames: ''!


!MacOSFilename class methodsFor: 'instance creation'!

getFileTypes: aArray
	" get file via StdFile manager"
	"MacOSFilename getFileTypes: nil"
	"MacOSFilename getFileTypes: #('TEXT' 'HPS3')"

	^self getFileTypes: aArray errInto: self errorReporter new!

getStarupFiles
	" get statup files via finder"
	"MacOSFilename getStarupFiles"

	^self getStarupFilesErrInto: self errorReporter new! !

!MacOSFilename class methodsFor: 'primitives'!

getFileTypes: aArray errInto: errorHandler
	" get file via StdFile manager"

	<primitive: 756>
	^errorHandler reportError!

getStarupFilesErrInto: errorHandler
	" get statup files via finder"

	<primitive: 761>
	^errorHandler reportError! !