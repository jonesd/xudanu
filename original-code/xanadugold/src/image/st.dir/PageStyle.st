'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:53:04 pm'!

Object subclass: #PageStyle
	instanceVariableNames: 'pageSize tabStops margins '
	classVariableNames: 'DefaultMargins DefaultPageSize DefaultTabStops '
	poolDictionaries: ''
	category: 'System-Printing'!
Methods make: coll with: rep printString) browse: rep!


!PageStyle methodsFor: 'initialization'!

initialize
	"Set up an initial default document style."

	pageSize _ DefaultPageSize deepCopy.
	tabStops _ DefaultTabStops deepCopy.
	margins _ DefaultMargins deepCopy! !

!PageStyle methodsFor: 'accessing'!

margins
	"Return the current page margins."

	^margins!

margins: m 
	"Set the current margins."

	margins _ m!

pageHeight
	"Return the current height of the page."

	^pageSize y!

pageSize
	"Return the current size of the page."

	^pageSize!

pageSize: p 
	"Set the current size of the page."

	pageSize _ p!

pageWidth
	"Return the current height of the page."

	^pageSize x!

tabStops
	"Return the current tabstops."

	^tabStops!

tabStops: array 
	"Set the current tab stops to the given array."

	tabStops _ array! !

!PageStyle methodsFor: 'margins'!

bottomMargin
	"Return the value of the bottom margin."

	^self margins at: 2!

bottomMargin: inches 
	"Set the value of the bottom margin."

	self margins at: 2 put: inches!

height
	^self pageHeight - (self topMargin + self bottomMargin)!

leftMargin
	"Return the value of the left margin."

	^self margins at: 3!

leftMargin: inches 
	"Set the value of the left margin."

	self margins at: 3 put: inches!

printingHeight
	"Return the height of the printing area of the page."

	^self pageHeight - (self topMargin + self bottomMargin)!

printingWidth
	"Return the width of the printing area of the page."

	^self pageWidth - (self leftMargin + self rightMargin)!

rightMargin
	"Set the value of the right margin."

	^self margins at: 4!

rightMargin: inches 
	"Set the value of the right margin."

	self margins at: 4 put: inches!

topMargin
	"Return the value of the top margin."

	^self margins at: 1!

topMargin: inches 
	"Set the value of the top margin."

	self margins at: 1 put: inches!

width
	^self pageWidth - (self leftMargin + self rightMargin)! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

PageStyle class
	instanceVariableNames: ''!
asciiValue		put: #again:key:.
	Keyboard at: 225 + 1 "ctrl-shift-a"			put: #again:key:.
	
	FontKeys do: [:i | Keyboard at: i + 1 put: #changeEmphasis:key:].
	"Keyboard at: Ctrlv asciiValue + 1 put: #fontMenu:key:."

	Keyboard at: CtrlMinus asciiValue + 1 put: #changeEmphasis:key:.
	Keyboard at: CtrlShiftMinus asciiValue + 1 put: #changeEmphasis:key:.
	Keyboard at: Ctrlb asciiValue + 1 put: #changeEmphasis:key:.
	Keyboard at: CtrlB asciiValue + 1 put: #changeEmphasis:key:.
	Keyboard at: CtrlI asciiValue + 1 put: #changeEmphasis:key:.	
	"Keyboard at: Ctrlx asciiValue + 1 put: #changeEmphasis:key:."
	
	EncloseKeys _ #(200 27 220 251 194 199 15 16 10 11 12). "add ctrl-o,p,j,k,l"
	EncloseKeys do: [:i | Keyboard at: i + 1 put: #enclose:key:].
	Keyboard at: $n asciiValue - $_ asciiValue		put: #leaveBrackets:key:.
	Keyboard at: ESC asciiValue + 1				put: #selectCurrentTypeIn:key:.
	Keyboard at: $p asciiValue - $_ asciiValue		put: #backwardCharacter:key:.
	Keyboard at: $n asciiValue - $_ asciiValue		put: #forwardCharacter:key:.!


!PageStyle class methodsFor: 'instance creation'!

default
	"Return a new defaulted document style."

	^self new!

new
	"Initialize."

	^super new initialize! !

!PageStyle class methodsFor: 'class initialization'!

initialize
	"Set up the details of the default margins,  page size,  and tabs."

	DefaultPageSize _ 8.5 @ 11.0.
	DefaultMargins _ #(1 1 1 1).
	DefaultTabStops _ Array new: 34.
	1 to: DefaultTabStops size do: [:i | DefaultTabStops at: i put: i * 0.25].! !

PageStyle initialize!
