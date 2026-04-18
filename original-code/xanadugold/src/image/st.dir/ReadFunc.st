'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:01:50 pm'!

Object subclass: #ReadFunc
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Snefru'!


"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

ReadFunc class
	instanceVariableNames: ''!



!ReadFunc class methodsFor: 'accessing'!

{int var} stringReadFunc: param {void star} with: buffer {char star} with: bufSize {unsigned int}
	"Pseudo read() function for reading from strings."

	| src {char star vector} dst {char star} i {int unsigned var} |

	src _ param.
	dst _ buffer clone.
	i _ 0.
	[(i < bufSize) and: [src at ~= (0 asCharacter)]] whileTrue: [
		dst postInc put: ((src postInc at) asInteger).
		i _ i+1
	].
	
	^i! !