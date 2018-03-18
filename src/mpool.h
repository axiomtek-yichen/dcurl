#ifndef DCURL_MPOOL_H
#define DCURL_MPOOL_H

typedef struct __mpool mpool;

mpool *mpool_new(const int element_size, const int block_size);
void mpool_release(mpool *p);

void *mpool_alloc(mpool *p);
void mpool_free(mpool *p, void *ptr);

#endif
