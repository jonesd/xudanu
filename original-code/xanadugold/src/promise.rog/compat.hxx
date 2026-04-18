#ifndef XU_COMPAT_HXX
#define XU_COMPAT_HXX


#ifdef sgi
#define PURE_VIRTUAL_BUG
#endif /* sgi */


extern "C" {
#	include "compat.h"
};

/* The following turns off multiple inheritance when possible */

#ifdef macintosh
#	define XU_ROOTCLASS	: public SingleObject
#else
#	define XU_ROOTCLASS
#endif


/* Inline switches */


#ifdef XU_USE_INLINE1
#	define XU_INLINE1 inline
#else
#	define XU_INLINE1
#endif /* XU_USE_INLINE1 */

#ifdef XU_USE_INLINE2
#	define XU_INLINE2 inline
#else
#	define XU_INLINE2
#endif /* XU_USE_INLINE2 */


/* to suppress automatic type conversion for single arg constructors */
class XuTCS XU_ROOTCLASS {};
extern XuTCS xuTCS;

#endif /* XU_COMPAT_HXX */
