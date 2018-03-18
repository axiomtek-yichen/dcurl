/*
 * Copyright (C) 2018 dcurl Developers.
 * Use of this source code is governed by MIT license that can be
 * found in the LICENSE file.
 */

#include <stdlib.h>
#include <string.h>

#include "mpool.h"

#ifndef max
#define max(a, b) ((a) < (b) ? (b) : (a))
#endif

typedef struct __mpool_freed {
    struct __mpool_freed *nextFree;
} mpool_freed;

struct __mpool {
    uint32_t element_size;
    uint32_t block_size;
    uint32_t used;
    int32_t block;
    mpool_freed *freed;
    uint32_t blocks_used;
    uint8_t **blocks;
};

static void mpool_freeAll(mpool *p)
{
    p->used = p->block_size - 1;
    p->block = -1;
    p->freed = NULL;
}

#define MPOOL_BLOCKS_INIT 1

mpool *mpool_new(const int element_size, const int block_size)
{
    mpool *p = malloc(sizeof(mpool));
    if (!p)
        return NULL;

    p->element_size = max(element_size, sizeof(mpool_freed));
    p->block_size = block_size;

    mpool_freeAll(p);

    p->blocks_used = MPOOL_BLOCKS_INIT;
    p->blocks = malloc(sizeof(uint8_t *) * p->blocks_used);

    for (int i = 0; i < p->blocks_used; ++i)
        p->blocks[i] = NULL;

    return p;
}

void mpool_release(mpool *p)
{
    if (!p)
        return;

    for (int i = 0; i < p->blocks_used; ++i) {
        if (p->blocks[i] == NULL)
            break;
        free(p->blocks[i]);
    }

    free(p->blocks);
    free(p);
}

void *mpool_alloc(mpool *p)
{
    if (p->freed != NULL) {
        void *recycle = p->freed;
        p->freed = p->freed->nextFree;
        return recycle;
    }

    if (++p->used == p->block_size) {
        p->used = 0;
        if (++p->block == (int32_t) p->blocks_used) {
            uint32_t i;

            p->blocks_used <<= 1;
            p->blocks = realloc(p->blocks, sizeof(uint8_t *) * p->blocks_used);

            for (i = p->blocks_used >> 1; i < p->blocks_used; ++i)
                p->blocks[i] = NULL;
        }

        if (p->blocks[p->block] == NULL)
            p->blocks[p->block] = malloc(p->element_size * p->block_size);
    }

    return p->blocks[p->block] + p->used * p->element_size;
}

void mpool_free(mpool *p, void *ptr)
{
    mpool_freed *pFreed = p->freed;

    p->freed = ptr;
    p->freed->nextFree = pFreed;
}
