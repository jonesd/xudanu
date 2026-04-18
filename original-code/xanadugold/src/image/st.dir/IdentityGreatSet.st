'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:48:27 pm'!

GreatSet variableSubclass: #IdentityGreatSet
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Collections-Unordered'!



!IdentityGreatSet methodsFor: 'private: greatness'!

bucketFor: anObject

	^ (anObject identityHash \\ self basicSize) + 1!

initialize

	1 to: self basicSize do: [:i | 
		self basicAt: i put: (IdentitySet new: 128)]! !