'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:51:54 pm'!

ClassRelatedChange subclass: #MethodChange
	instanceVariableNames: 'selector category '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'System-Changes'!
MethodChange comment:
'Class MethodChange represents a change to a method (new definition or removal).

Instance Variables:
	selector	<Symbol> for method selector
	category	<Symbol> for name of a method category'!


!MethodChange methodsFor: 'accessing'!

category
	^category!

category: aSymbol
	category _ aSymbol asSymbol!

parameters
	^Array with: className with: selector!

selector
	^selector!

selector: aSymbol
	selector _ aSymbol asSymbol! !