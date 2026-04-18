'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:53:07 pm'!

Heaper subclass: #FMComposer
	instanceVariableNames: 'myAttributes {AttributeGroup}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Compositors-Basic'!

(FMComposer getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #DEFERRED; yourself)!

!FMComposer methodsFor: 'composing'!

{IntegerVar} charIndexFor: pos {PointPos} with: model
{MuWordArray} with: composer {FMComposition}
	self subclassResponsibility!

{FMComposition} compose: model {MuWordArray} with: layout {AbstractLayout}

	self subclassResponsibility!

{FMComposition} uncompose: model {MuWordArray} with: composition {FMComposition} 

	self subclassResponsibility! !

!FMComposer methodsFor: 'creation'!

create: attributes {AttributeGroup}

	super create.
	myAttributes _ attributes.! !

!FMComposer methodsFor: 'accessing'!

{AttributeGroup} attributes

	^ myAttributes! !

!FMComposer methodsFor: 'printing'!

{void}printOn: aStream{ostream reference}
	aStream << self getCategory name << '('
	
	<< ' not really implemented ' << ') '! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

FMComposer class
	instanceVariableNames: ''!

(FMComposer getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #DEFERRED; yourself)!

!FMComposer class methodsFor: 'smalltalk: smalltalk pseudo constructors'!

make: attributes {AttributeGroup}
	[^ SmalltalkRunComposer create: attributes] smalltalkOnly.! !

!FMComposer class methodsFor: 'smalltalk: global: pseudo constructors'!

{FMComposer} fMComposer: attributes {AttributeGroup}
	[^ SmalltalkRunComposer create: attributes] smalltalkOnly.! !