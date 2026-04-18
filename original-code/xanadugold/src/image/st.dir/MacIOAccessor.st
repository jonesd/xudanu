'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:53:00 pm'!

IOAccessor subclass: #MacIOAccessor
	instanceVariableNames: ''
	classVariableNames: 'LineEndConventionGlobal WouldBlockECode '
	poolDictionaries: ''
	category: 'OS-Mac'!
MacIOAccessor comment:
'Class MacIOAccessor is a reference to a Macintosh "file reference".  Instances of it (and its subclasses) are used to perform IO to the various kinds of stream-like services that Macintosh provides (disk files, serial lines, etc).

Class Variables:
	WouldBlockECode	<SmallInteger>
						Return error code known as EWOULDBLOCK in C-land.
'!


!MacIOAccessor methodsFor: 'constants'!

lineEndConvention
	^LineEndConventionGlobal! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

MacIOAccessor class
	instanceVariableNames: ''!


!MacIOAccessor class methodsFor: 'class initialization'!

hookupTo: platname
	"You have become the default class for some OSHandle subclass.  Prepare yourself."

	"This shouldn't really be here, but *someone* needs to
	tell these guys to hook-up, it might as well be me."

	"MacTtyAccessor hookupTo: platname."
	MacErrorHolder hookupTo: platname!

install

	"Do nothing."!

setLineEndConventionForMac: toConv 
	"MacIOAccessor setLineEndConventionForMac: false"
	toConv
		ifTrue: [LineEndConventionGlobal _ LineEndCR]
		ifFalse: [LineEndConventionGlobal _ LineEndLF]!

wouldBlockErrorCode: n
	"Assign the value for the wouldBlock error code."

	WouldBlockECode _ n! !

!MacIOAccessor class methodsFor: 'defaulting'!

defaultClass
	"Answer the appropriate concrete subclass."

	^self!

defaultForFiles
	"Return the appropriate class for real (disk) files."

	^MacDiskFileAccessor!

defaultForIPC
	"Return the appropriate class for inter-process communications."

	"Not supported yet."
	^self unsupportedOperationSignal raise!

defaultForSerial
	"Return the appropriate class for serial (rs-232) communications."

	^MacTtyAccessor!

errorReporter
	"Answer the appropriate error code interpreter for me."

	^MacErrorHolder! !

!MacIOAccessor class methodsFor: 'private: private'!

getAccessories
	"Return a Array of Strings of all available accessories."
	"MacIOAccessor getAccessories"
	<primitive: 754>

	^self primitiveFailed!

runAccessory: aNumber
	" invoke an accessory. "
	" MacIOAccessor runAccessory: 3 "
	<primitive: 755>

	^self primitiveFailed! !