'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:59:08 pm'!

Model subclass: #STWindowModel
	instanceVariableNames: 'myWindow {WindowModel}'
	classVariableNames: '
		ActiveWindowCount {Integer} 
		WindowsGone {UNKNOWN} '
	poolDictionaries: ''
	category: 'Tapestry-Smalltalk version'!



!STWindowModel methodsFor: 'create'!

create: window {WindowModel}
	super create.
	myWindow _  window.
	myWindow addDependent: self.
	ActiveWindowCount := ActiveWindowCount + 1.!

{void} destruct
	myWindow removeDependent: self.
	myWindow _ NULL.
	super destruct.!

release

	ActiveWindowCount := ActiveWindowCount - 1.
	ActiveWindowCount = 0 ifTrue:
		[WindowsGone signal]! !

!STWindowModel methodsFor: 'accessing'!

{WindowModel} window
	^myWindow! !

!STWindowModel methodsFor: 'menus'!

redButtonMenu
	^ self yellowButtonMenu! !

!STWindowModel methodsFor: 'filters'!

{DisplayObject} filter
	"get the name of the user's current filter"
	^(self referenceFilter getValue cast: TapestryFilter) name asString asParagraph! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

STWindowModel class
	instanceVariableNames: ''!



!STWindowModel class methodsFor: 'smalltalk: init'!

linkTimeNonInherited

	ActiveWindowCount := 0.
	WindowsGone := Semaphore new.! !

!STWindowModel class methodsFor: 'semaphore'!

{Semaphore} windowsGone

	^WindowsGone! !