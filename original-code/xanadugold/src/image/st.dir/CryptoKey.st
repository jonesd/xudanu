'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:00:17 pm'!

Heaper subclass: #CryptoKey
	instanceVariableNames: 'bits '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Be-Locks'!


!CryptoKey methodsFor: 'instance creation'!

create! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

CryptoKey class
	instanceVariableNames: ''!


!CryptoKey class methodsFor: 'instance creation'!

{CryptoKey} impossibleKey
	^ CryptoKey create!

{CryptoKey} openKey
	^ CryptoKey create! !