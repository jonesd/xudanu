'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:52:58 pm'!

IOAccessor subclass: #DosIOAccessor
	instanceVariableNames: ''
	classVariableNames: 'WouldBlockECode '
	poolDictionaries: ''
	category: 'OS-Dos'!
DosIOAccessor comment:
'DosIOAccessor is a reference to a MS-DOS "file descriptor".

Instances of it (and its subclasses) are used to perform IO to the various kinds of stream-like services that the PC provides (disk files, serial lines, etc).

Class Variables:
	WouldBlockECode	<SmallInteger>
						Return error code known as EWOULDBLOCK in C-land.
'!


!DosIOAccessor methodsFor: 'constants'!

lineEndConvention

	^LineEndLF! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

DosIOAccessor class
	instanceVariableNames: ''!


!DosIOAccessor class methodsFor: 'class initialization'!

hookupTo: platname
	"You have become the default class for some OSHandle subclass.  Prepare yourself."

	"This shouldn't really be here, but *someone* needs to
	tell these guys to hook-up, it might as well be me."
	DosTtyAccessor hookupTo: platname.
	DosErrorHolder hookupTo: platname!

install

	"Do nothing."!

wouldBlockErrorCode: n
	"Assign the value for the wouldBlock error code."

	WouldBlockECode _ n! !

!DosIOAccessor class methodsFor: 'defaulting'!

defaultClass
	"Answer the appropriate concrete subclass."

	^self!

defaultForFiles
	"Return the appropriate class for real (disk) files."

	^DosDiskFileAccessor!

defaultForIPC
	"Return the appropriate class for inter-process communications."

	"Not supported yet."
	^self unsupportedOperationSignal raise!

defaultForSerial
	"Return the appropriate class for serial (rs-232) communications."

	^DosTtyAccessor!

errorReporter
	"Answer the appropriate error code interpreter for me."

	^DosErrorHolder! !