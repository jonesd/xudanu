'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:56:38 pm'!

FMBuilder subclass: #FMListBuilder
	instanceVariableNames: 'myComp {AbstractListComp}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'FM-Builders'!

(FMListBuilder getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!FMListBuilder methodsFor: 'build'!

{FMBuilding} build: aList {Heaper}

	"use the current scaffold to build a multiviewer with each element of the list
	in a separate view.  This will attach  ListDirector to the list to update the 
	view when the model changes"

	| mvs {TableAccumulator} mcs {TableAccumulator} mv {ListMultiViewer} mc {MultiController} tb {FMBuilding} |
	
	mvs _ TableAccumulator make.
	mcs _ TableAccumulator make.
	
	(aList quickCast: ListModel) asTable stepper forEach: [:elem {Heaper} | 
		tb _ Scaffold fluidGet build: elem.
		mvs step: (tb view).
		mcs step: tb controller].
	mv _ ListMultiViewer make: (ListModel make: (mvs value cast: IntegerTable)) with: myComp.
	mc _ MultiController make: (mcs value cast: ScruTable).
	^FMBuilding make: mv with: mc! !

!FMListBuilder methodsFor: 'create'!

create: compositor {AbstractListComp}
	super create.
	myComp _ compositor! !

!FMListBuilder methodsFor: 'printing'!

{void} printOn: aStream {ostream reference} 
	aStream << self getCategory name << '(' << ' not really implemented ' << ') '! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

FMListBuilder class
	instanceVariableNames: ''!

(FMListBuilder getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!FMListBuilder class methodsFor: 'pseudo constructors'!

make: compositor {AbstractListComp}
	^self create: compositor! !