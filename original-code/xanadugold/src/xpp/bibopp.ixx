#ifndef BIBOPP_IXX
#define BIBOPP_IXX

/* ************************************************************************ *
 * 
 *                    Class     UnallocatedHeaper
 *
 * ************************************************************************ */

extern Category * cat_UnallocatedHeaper;

INLINE UnallocatedHeaper * OR(NULL) UnallocatedHeaper::fetchNextFree()
{
    return myNextFree;
}

INLINE UnallocatedHeaper::UnallocatedHeaper(UnallocatedHeaper *next, TCSJ)
{
    myNextFree = next;
    *(Int32*)this = 0;  // only this type ever has GC sweep (first field) == 0
}

/* ************************************************************************ *
 * 
 *                    Class	BibopPage
 *
 * ************************************************************************ */

INLINE BooleanVar BibopPage::isValid(void * pointer)
{
    return (pointer == this->fetchContainer(pointer));
}

INLINE Int32 BibopPage::chunkSize()
{
    return myChunkSize;
}

INLINE Int32 BibopPage::offset()
{
    return myOffset;
}

INLINE BibopPage* OR(NULL) BibopPage::fetchNextPage()
{
    return myNextPage;
}

INLINE void BibopPage::setNextPage(BibopPage * OR(NULL) newNext)
{
    myNextPage = newNext;
}

INLINE void BibopPage::clearPageMapBit (BibopPage *aPage)
{
    Int32 pageIndex = ((char *)aPage - TheLowestAllocatedMemory) >> BibopPage::BibopLogPageSize;
    ThePageMap [pageIndex >> 3] &= (UInt8) (~(01 << (pageIndex & 07)));
}

INLINE void BibopPage::setPageMapBit(BibopPage *aPage)
{
    Int32 pageIndex = ((char *)aPage - TheLowestAllocatedMemory) >> BibopPage::BibopLogPageSize;
    ThePageMap [pageIndex >> 3] |= ((UInt8) (01 << (pageIndex & 07)));
}

INLINE BooleanVar BibopPage::testPageMapBit(void *aPage)
{
    Int32 pageIndex = ((char *)aPage - TheLowestAllocatedMemory) >> BibopPage::BibopLogPageSize;
    return ThePageMap[pageIndex >> 3] & (01 << (pageIndex & 07));
}

INLINE BibopHeap * OR(NULL) BibopPage::fetchHeap()
{
    return myHeap;
}

#endif /* BIBOPP_IXX */
