'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:53:06 pm'!

Object subclass: #Printer
	instanceVariableNames: '
		labelIndex {UNKNOWN}
		document {UNKNOWN}
		twoColumn {UNKNOWN}
		PrinterResolution {UNKNOWN}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'System-Printing'!



!Printer methodsFor: 'indexing'! !

!Printer methodsFor: 'initialize-release'!

setPrinterResolution: PixelsPerPoint 
	"Set an instance variable which speciffies the resolution of the output 
	printer for imaging tasks which need to know this."

	PrinterResolution _ PixelsPerPoint! !

!Printer methodsFor: 'rendering'!

newLine
	self string: '
'! !