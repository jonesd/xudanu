#ifndef FLUIDX_IXX
#define FLUIDX_IXX

INLINE Emulsion * FluidVarDescription::emulsion ()
{
    return myEmulsion;
}

INLINE void * FluidVarDescription::space ()
{
    return & myEmulsion->fluidsSpace() [myOffset];
}

#endif /* FLUIDX_IXX */
