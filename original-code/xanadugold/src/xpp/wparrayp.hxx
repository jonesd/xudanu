#ifndef WPARRAYP_HXX
#define WPARRAYP_HXX

#include "wparrayx.hxx"

class DepartedObject : public Heaper {
    CONCRETE(DepartedObject)
    NO_GC(DepartedObject)
    NOT_A_TYPE(DepartedObject)
 public:
    DepartedObject () {}
};

#endif /* WPARRAYP_HXX */
