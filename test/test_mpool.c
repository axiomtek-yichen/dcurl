#include "common.h"

int test_mpool(int element_size, int block_size)
{
    mpool *mpool_ptr;
    int *test_ptr1 = NULL;
    int *test_ptr2 = NULL;

    /* init memory mpool with given parameters */
    mpool_ptr = mpool_new(element_size, block_size);

    /* allocate memory from memory mpool */
    test_ptr1 = mpool_alloc(mpool_ptr);
    test_ptr2 = mpool_alloc(mpool_ptr);

    /* test allocated memory validity */
    if (!(test_ptr1 && test_ptr2))
        return -1;

    /* free memory allocated from memory mpool */
    mpool_free(mpool_ptr, test_ptr1);

    /* free all memory used by this mpool */
    mpool_release(mpool_ptr);

    return 0;
}

int main()
{
    assert(test_mpool(4, 8) == 0);
    assert(test_mpool(8, 8) == 0);
    assert(test_mpool(16, 8) == 0);
    assert(test_mpool(32, 8) == 0);

    return 0;
}
