'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:59:17 pm'!

Heaper subclass: #UpdateRecord
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Update Mechanism'!
UpdateRecord comment:
'See XuDependent and XuModel.  When a model changes, it informs its dependents how it changed by sending it a kind of UpdateRecord which describes what aspect changed and how.  The dependent then has some partial ability to discriminate the type of the UpdateRecord so that it can avoid all the work of assuming that everything changed.  UpdateRecord itself is a concrete class which represents the generic notice: "I''ve changed somehow, you should be prepared for the worst.".  Whenever a dependent can''t discriminate an UpdateRecord to a type more specific that UpdateRecord he should treat it as equivalent to a direct instance of UpdateRecord.  However, see the bug notice in XuDependent.'!

(UpdateRecord getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!UpdateRecord methodsFor: 'testing'!

{BooleanVar} isEqual: another {Heaper}
	"BUG BUG: My god is this broken!!  Does anyone know what's going on here?"
	
	^another isKindOf: UpdateRecord! !

!UpdateRecord methodsFor: 'creation/deletion'!

create
	super create.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

UpdateRecord class
	instanceVariableNames: ''!

(UpdateRecord getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!UpdateRecord class methodsFor: 'pseudoconstructor'!

make
	"Return a generic UpdateRecord which represents some change without being 
	specific about what."

	^self create! !