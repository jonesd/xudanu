#include "ccompatc.h"

#define VERSION_ID_STRING(file)	CAT(file,_rcsId)
#define VERSION_ID_FUNC(file)	CAT(file,_idString)

#define VERSION_ID(file,string)			\
static char VERSION_ID_STRING(file)[] = string;	\
static char *VERSION_ID_FUNC(file)() {		\
	return VERSION_ID_STRING(file);		\
    }

VERSION_ID(verwrap_cxx,"$Id: verwrap.cxx,v 3.1 1992/08/14 22:12:13 shap Exp $")

#include <stream.h>

main(int ac, char *av[]) {
    cerr << ac << " args: ";
    for (int i = 0; i < ac; i++) {
	cerr << "'" << av[i] << "' ";
    }
    cerr << "\n";
}
