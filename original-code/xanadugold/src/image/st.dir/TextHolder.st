'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:49:47 pm'!

StringHolder subclass: #TextHolder
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Interface-Text'!
TextHolder comment:
'A TextHolder is like a StringHolder, except it keeps its contents as a text, not as a string.'!


!TextHolder methodsFor: 'accessing'!

contents: aStringOrText
	"Set aStringOrText to be the contents of the receiver."
	contents _ aStringOrText! !