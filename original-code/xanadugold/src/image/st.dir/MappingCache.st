'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:56:04 pm'!

Object subclass: #MappingCache
	instanceVariableNames: 'cacheDict tests hits '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'X++ Translator'!


!MappingCache methodsFor: 'accessing'!

checkCacheFor: aKey
	tests _ tests + 1. hits _ hits + 1.
	^ cacheDict at: aKey ifAbsent: [hits _ hits - 1. nil]!

clearCache
	cacheDict _ IdentityDictionary new: 217.
	tests _ hits _ 0.!

enterCache: aKey with: aValue


	| tv |
	tv _ cacheDict at: aKey ifAbsent: [nil].
	(tv ~= nil and: [tv ~= aValue]) ifTrue: [self error: 'attempted to enter different value for key ', aKey printString].
	cacheDict at: aKey put: aValue.
	^ aValue!

presetCache: aDict 
	cacheDict _ IdentityDictionary new: 217.
	aDict associationsDo: [:ass | cacheDict add: ass]! !

!MappingCache methodsFor: 'printing'!

printOn: aStream


	aStream nextPutAll: self class name; nextPutAll: '( entries: '.
	aStream print: cacheDict size; nextPutAll: ', tests: '.
	aStream print: tests; nextPutAll: ', hits: '; print: hits.
	aStream nextPutAll: '; % hit = '; << (hits / tests * 100) truncated.
	aStream nextPutAll: ')'.! !

!MappingCache methodsFor: 'private: private'!

cache
	^ cacheDict! !

!MappingCache methodsFor: 'instance creation'!

create
	self clearCache! !