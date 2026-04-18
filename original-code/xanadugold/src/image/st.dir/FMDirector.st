'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:56:38 pm'!

XnModel subclass: #FMDirector
	instanceVariableNames: 'scaffoldInternal {FMScaffold}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'FM-Builders'!
FMDirector comment:
'This is the superclass of Directors.  It''s not really necessary, but it''s here anyway.

Directors are persistent Builders.  They are for handling dynamic state of models.
One would use a Builder to create a Viewer/Controller pair for something that is static.
By contrast, if the model being displayed can change in such a way as to require
re-layout of a set of subviews displaying the model, then a director is used.  The
Director will selectively destroy and rebuild the appropriate views and controllers to
match the changes to the model.  For example, a ListDirector will add a new view/control
pair if a new entry were added to the list model it is displaying.'!

(FMDirector getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!FMDirector methodsFor: 'accessing'!

{FMScaffold} scaffold

    ^ scaffoldInternal! !

!FMDirector methodsFor: 'creation'!

create
 
    super create.
    scaffoldInternal _ Scaffold fluidGet.! !

!FMDirector methodsFor: 'printing'!

{void}printOn: aStream{ostream reference}
	aStream << self getCategory name << '('
	
	<< ' not really implemented ' << ') '! !