

$(FOR CLASSES )
$//
$(IF CLASS ! | kind: CheckedPtrVar kind: StrongPtrVar)
$//
Class $(CLASS), subclass of $(CLASS base:):

$//
$(FOR FUNCS & pro: public ! | name: _dtor name: _ctor)
    $(FUNC type:) $(FUNC) ($///
	$(FOR ARGS in:)$///
	    $(ARG type:) $(ARG name:)$(IF MORE), $(FI)$///
	$(ROF)$///

	$(IF ARGS out:), $(FI)$///

	$(FOR ARGS out:)$///
	    /*OUT*/ $(ARG type:) $(ARG name:)$(IF MORE), $(FI)$///
        $(ROF)$///
    )
$(ROF ** member functions **)
$(FOR FUNCS & pro: public name: _ctor)
    $(CLASS) ($///
	$(FOR ARGS in:)$///
	    $(ARG type:) $(ARG name:)$(IF MORE), $(FI)$///
	$(ROF)$///

	$(IF ARGS out:), $(FI)$///

	$(FOR ARGS out:)$///
	    /*OUT??*/$(ARG type:) $(ARG name:)$(IF MORE), $(FI)$///
        $(ROF)$///
    )
$(ROF ** constructors ** )
$(FOR FUNCS & pro: public name: _dtor)$// ** destructors **
    ~ $(CLASS) ()
$(ROF **  destructors **)


$(FI ** not SP2 or CP2 ** )
$//
$(ROF ** classes ** )
