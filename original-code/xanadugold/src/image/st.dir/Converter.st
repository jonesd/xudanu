'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:04:25 pm'!

Heaper subclass: #Converter
	instanceVariableNames: ''
	classVariableNames: '
		AllConverters {CategoryTable} 
		LastConverter {Converter star} 
		LastFrom {Category star} 
		LastTo {Category star} '
	poolDictionaries: ''
	category: 'Xanadu-Xpp-Converters'!
Converter comment:
'Converters exist to convert an object that is of one data type to some other data type.  In order to understand why we use Converters for this, we first have to understand why the two obvious C++ means for doing so are inadequate.
	
	First, we could send a conversion message to the object that we''re converting from.  This has the disadvantage that the module which provides the object must know all the types that we might want to convert it to.  This effectively prevents the easy addition of new types to an existing system (without coordinating overhead).
	
	Second, we could use pseudo-constructors for the new type which were overloaded based of the type of the argument (to be converted from). The problem is that overloading only happens based on compile time type, and we want to invoke the converter that is most specific based on the run-time type.  Let''s say that "p" is declared as pointer to Position, but at the moment it points to an Integer. If a converter has been provided by someone for converting Integers to the target type we would prefer that one.  The CHOOSE macro doesn''t help, because that only converts run time types to particular compile time types which the user of the CHOOSE macro thought to list.
	
	Instead, one declares a static instance of each Converter which (at initialization time) posts itself to a table of all converters, indexed by the from-class and the to-class.  At run-time, when we use the CONVERT macro to convert an object to a desired type, the most specific converter based on the from-type hierarchy is selected.  I believe that currently any compatable to-type is acceptable (with no preference).  The selected converter''s from type may be a superclass of the from-object, and the converter''s to-type may be any subclass of the requested to type.
	
	Example:
	
	"CONVERT(XuRegion,p)" when p is bound to a position will return a singleton region of the same coordinate space as that of the position.  In Smalltalk, one says "p convert: XuRegion".
	
	See Scaffold and WaldoMaker for services which are similar to that provided by Converter.  Eventually we hope to unify some of these.'!

(Converter getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #OBSOLETE; add: #EQ; add: #DEFERRED; yourself)!

!Converter methodsFor: 'protected: creation'!

create: from {Category} with: to {Category}
	"remember the kind of converter this is.  It is in the parameters passed to this by subclass
	 constructors that a concrete Converter class declares what types it knows how to convert to what.
	 See any subclass's constructor."
	| subtable {CategoryTable} |
	super create.
	subtable _ (AllConverters fetchSuperOf: from) cast: CategoryTable.
	subtable == NULL ifTrue:
		[subtable _ CategoryTable make.
		AllConverters at: from introduce:"was store:" subtable].
	subtable at: to introduce: self.! !

!Converter methodsFor: 'accessing'!

{Heaper} convert: value {Heaper}
	"perform the conversion.  This is defined by those who define a new converter, but not directly called
	 by clients.  Clients invoke conversion purely by using the CONVERT macro"
	self subclassResponsibility! !

!Converter methodsFor: 'generated:'!

actualHashForEqual ^self asOop!

isEqual: other ^self == other! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

Converter class
	instanceVariableNames: ''!

(Converter getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #OBSOLETE; add: #EQ; add: #DEFERRED; yourself)!

!Converter class methodsFor: 'accessing'!

{Converter} fetchConverter: from {Category} with: to {Category}
	"find the best available converter.  See class comment for definition of best."
	| candidates {CategoryTable} result {Converter} |
	(LastFrom == from and: [LastTo == to]) ifTrue: [ ^ LastConverter ].
	candidates _ (AllConverters fetchSuperOf: from) quickCast: CategoryTable.
	candidates == NULL ifTrue: [^NULL].
	result _ (candidates fetchSubOf: to) quickCast: Converter.
	LastConverter _ result.
	LastFrom _ from.
	LastTo _ to.
	^ result!

{Heaper} getConversion: to {Category} with: value {Heaper}
	"get the best converter and use it to actually do the conversion.  
	Clients should only use the CONVERT macro instead"
	
	'return getConverter (value->getCategory(), to)->convert(value);' translateOnly.
	[^(Converter getConverter: value getCategory with: to) convert: value] smalltalkOnly!

{Converter} getConverter: from {Category} with: to {Category}
	"find the best available converter.  See class comment for definition of best."
	| result {Converter} |
	result _ Converter fetchConverter: from with: to.
	result == NULL ifTrue: [Heaper BLAST: #CantConvert].
	^result! !

!Converter class methodsFor: 'smalltalk: initialization'!

initTimeInherited

	"create an instance of the converter.  The constructor places it into the AllConverters table"
	self REQUIRES: Converter.
	(self new.AllocType: #PERSISTENT) create. "create a new instance of each subclass"!

initTimeNonInherited
	"create an instance and assign it to the class instance variable"
	self REQUIRES: CategoryTable.
	AllConverters _ CategoryTable make.!

linkTimeNonInherited
	"create an instance and assign it to the class instance variable"
	AllConverters _ NULL.
	LastFrom _ NULL.
	LastTo _ NULL.
	LastConverter _ NULL.!

suppressInitTimeInherited!

suppressLinkTimeInherited! !

!Converter class methodsFor: 'smalltalk: macro'!

{Heaper} CONVERT: to {Category} with: thing {Heaper}
	"convert using the best available converter"
	^((self getConverter: thing getCategory with: to) convert: thing) cast: to! !