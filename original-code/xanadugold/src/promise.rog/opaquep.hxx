#ifndef XU_OPAQUEP_HXX
#define XU_OPAQUEP_HXX

#include "opaque.hxx"
#include "opaquep.oxx"

class XuCategory : public XuCounted {
    XU_PROLOGUE(XuCategory)
  public:
    XuBooleanVar isEqualOrSubTypeOf (XuCategoryP other);
    static XuCategoryP make (XuCategoryP * XU_OR_NULL superPP, XuStringVar name);
    XuStringVar name ();

  private:
    XuCategoryP XU_OR_NULL fetchSuperCat ();
    XuCategory (XuCategoryP * XU_OR_NULL superPP, XuStringVar name);

    XuCategoryP * XU_OR_NULL mySuperCatPP;
    XuStringVar myName;
};



#endif /* XU_OPAQUEP_HXX */
