'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:52:35 pm'!

Array variableSubclass: #ScannerTable
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'System-Compiler-Support'!
ScannerTable comment:
'I hold the table that the Scanner uses to look up characters by character value.  If the character value is out of range, I answer a default value.'!


!ScannerTable methodsFor: 'error handling'!

subscriptBoundsError: index
	"This method is invoked when a subscript is
	an integer but is out of range.  Answer an
	appropriate default value."

	^((index between: self size + 1 and: 65536) or: [index = 0])
		ifFalse: [super subscriptBoundsError: index]
		ifTrue: [(Character value: index) isLetter
					ifTrue: [^#xLetter]
					ifFalse: [^#xBinary]]! !