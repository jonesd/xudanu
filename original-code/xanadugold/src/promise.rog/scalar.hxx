#ifndef XU_SCALAR_HXX
#define XU_SCALAR_HXX

#include "opaque.hxx"

#include "scalar.oxx"

XU_INLINE1 XuIntVar xuMin (XuIntVar, XuIntVar);
XU_INLINE1 XuIntVar xuMax (XuIntVar, XuIntVar);


class XuIEEE128Var XU_ROOTCLASS {
  public:
    XuIEEE128Var ();
    XuIEEE128Var (XuIEEE128Var& other);
    XuIEEE128Var (XuIEEE64Var& other);
    XuIEEE128Var (XuIEEE32Var& other);
    XuIEEE128Var (XuIEEE8Var& other);
    XuIEEE128Var (float other);
    XuIEEE128Var (double other);
    operator float ();
    operator double ();
  private:
    union {
	struct {
	    unsigned int mySign 	:  1 ;
	    unsigned int myExponent 	: 11 ; /*?? */
	    unsigned int myMantissaH 	: 22 ; /*?? */
	    unsigned int myMantissaL	[5];   /*?? */
	} myFields;
	char myData [8];
    };
};

class XuIEEE64Var XU_ROOTCLASS {
  public:
    XuIEEE64Var ();
    XuIEEE64Var (XuIEEE128Var& other);
    XuIEEE64Var (XuIEEE64Var& other);
    XuIEEE64Var (XuIEEE32Var& other);
    XuIEEE64Var (XuIEEE8Var& other);
    XuIEEE64Var (float other);
    XuIEEE64Var (double other);
    operator float ();
    operator double ();
  private:
    union {
	struct {
	    unsigned int mySign 	:  1 ;
	    unsigned int myExponent 	: 11 ;
	    unsigned int myMantissaH 	: 20 ;
	    unsigned int myMantissaL 	: 32 ;
	} myFields;
	double myData;
    };
};

class XuIEEE32Var XU_ROOTCLASS {
  public:
    XuIEEE32Var ();
    XuIEEE32Var (XuIEEE128Var& other);
    XuIEEE32Var (XuIEEE64Var& other);
    XuIEEE32Var (XuIEEE32Var& other);
    XuIEEE32Var (XuIEEE8Var& other);
    XuIEEE32Var (float other);
    XuIEEE32Var (double other);
    operator float ();
    operator double ();
  private:
    union {
	struct {
	    unsigned int mySign 	:  1 ;
	    unsigned int myExponent 	:  8 ;
	    unsigned int myMantissa 	: 23 ;
	} myFields;
	float myData;
    };
};

class XuIEEE8Var XU_ROOTCLASS {
  public:
    XuIEEE8Var ();
    XuIEEE8Var (XuIEEE128Var& other);
    XuIEEE8Var (XuIEEE64Var& other);
    XuIEEE8Var (XuIEEE32Var& other);
    XuIEEE8Var (XuIEEE8Var& other);
    XuIEEE8Var (float other);
    XuIEEE8Var (double other);
    operator float ();
    operator double ();
  private:
    union {
	struct {
	    unsigned int mySign 	:  1 ;
	    unsigned int myExponent 	:  3 ;
	    unsigned int myMantissa 	:  4 ;
	} myFields;
	char myData;
    };
};


#endif /* XU_SCALAR_HXX */
