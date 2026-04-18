'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:52:09 pm'!

Object subclass: #CRFilter
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'System-Change Log Filter'!
CRFilter comment:
'This class is the abstract description of a filter used to select change records'!



!CRFilter methodsFor: 'accessing'!

{CRFilter} intersect: other {CRFilter} 
	
	^CRAndFilter make: self with: other!

{String} label
	self subclassResponsibility!

{CRFilter} not
	^ CRNotFilter make: self!

{BooleanVar} passes: cr {ChangeRecord}
	self subclassResponsibility!

{CRFilter} unionWith: other {CRFilter}

	^ CROrFilter make: self with: other! !

!CRFilter methodsFor: 'printing'!

{void} printOn: oo {ostream reference}

	oo << self getCategory name << '(''' << self label << ''')'! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

CRFilter class
	instanceVariableNames: ''!



!CRFilter class methodsFor: 'make'!

make: a
	^ self create: a!

make: a with: b
	^ self create: a with: b! !