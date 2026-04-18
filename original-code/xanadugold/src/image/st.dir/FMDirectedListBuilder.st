'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:56:37 pm'!

FMBuilder subclass: #FMDirectedListBuilder
	instanceVariableNames: 'myComp {AbstractListComp}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'FM-Builders'!

(FMDirectedListBuilder getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!FMDirectedListBuilder methodsFor: 'create'!

create: compositor {AbstractListComp}
	super create.
	myComp _ compositor! !

!FMDirectedListBuilder methodsFor: 'build'!

{FMBuilding} build: aList {Heaper}
	"use the current scaffold to build a multiviewer with 
	each element of the list 
	in a separate view. This will attach ListDirector to 
	the list to update the 
	view when the model changes"

	| mvs {TableAccumulator} mcs {TableAccumulator} mv {ListMultiViewer} mc {MultiController} tb {FMBuilding} vl {ListModel of: Viewer} ld {FMListDirector} |
	mvs _ TableAccumulator make.
	mcs _ TableAccumulator make.
	(aList basicCast: ListModel) asTable stepper
		forEach:  
			[:elem {Heaper} | 
			tb _ Scaffold fluidGet build: elem.
			mvs step: tb view.
			tb controller ~~ NULL ifTrue: [mcs step: tb controller]].
	mv _ ListMultiViewer make: (vl _ ListModel make: (mvs value cast: IntegerTable)) with: myComp.
	mc _ MultiController make: (mcs value cast: ScruTable).
	ld _ FMListDirector
				make: (aList basicCast: ListModel)
				with: vl
				with: mc.
	(mcs value cast: ScruTable) isEmpty
		ifTrue: [^FMDirectorBuilding
				make: mv
				with: NULL
				with: ld]
		ifFalse: [^FMDirectorBuilding
				make: mv
				with: mc
				with: ld]! !

!FMDirectedListBuilder methodsFor: 'printing'!

{void} printOn: aStream {ostream reference} 
	aStream << self getCategory name << '(' << ' not really implemented ' << ') '! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

FMDirectedListBuilder class
	instanceVariableNames: ''!

(FMDirectedListBuilder getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!FMDirectedListBuilder class methodsFor: 'pseudo
constructors'!

make: compositor {AbstractListComp}
	^self create: compositor! !