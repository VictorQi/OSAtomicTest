//
//  main.m
//  OSAtomicTest
//
//  Created by Victor on 2017/4/18.
//  Copyright © 2017年 VictorQi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <libkern/OSAtomic.h>

typedef struct Node {
    int value;
    struct Node *next;
} ListNode;

/**
 Adds A Node to The Head of A Linked List

 @param node Node that will be added
 @param head A pointer points to the original linked list
 */
void AddNode(ListNode *node, ListNode * volatile *head)
{
    bool success;
    do {
        ListNode *orig = *head;
        node->next = orig;
        success = OSAtomicCompareAndSwapPtrBarrier(orig, node, (void *)head);
    } while (!success);
}


/**
 Replace the given linked list to an empty list

 @param head A pointer points to the original linked list
 @return An empty list
 */
ListNode *StealList(ListNode * volatile *head) {
    bool success;
    ListNode *orig;
    do {
        orig = *head;
        success = OSAtomicCompareAndSwapPtrBarrier(orig, NULL, (void *)head);
    } while (!success);
    
    return orig;
}

// 基于CompareAndSwap仿制的AtomicAdd64
int64_t VQAtomicAdd64(int64_t howmuch, volatile int64_t *value)
{
    bool success;
    int64_t new;
    
    do {
        int64_t orig = *value;
        new = orig + howmuch;
        success = OSAtomicCompareAndSwap64(orig, new, value);
    } while (!success);
    
    return new;
}


int main(int argc, const char * argv[]) {
    @autoreleasepool {
        ListNode a = { 1, NULL };
        ListNode b = { 2, NULL };
        OSQueueHead queue = OS_ATOMIC_QUEUE_INIT;  // LIFO(stack)
        OSAtomicEnqueue(&queue, &a, offsetof(ListNode, next));
        OSAtomicEnqueue(&queue, &b, offsetof(ListNode, next));
        // b -> a (b的next指向a, a的next为NULL)
        
        ListNode *p;
        p = OSAtomicDequeue(&queue, offsetof(ListNode, next));  // p == &b
        p = OSAtomicDequeue(&queue, offsetof(ListNode, next));  // p == &a
        
//        ListNode * head = NULL;
//        head = malloc(sizeof(ListNode));
//        head->value = 1;
//        head->next = malloc(sizeof(ListNode));
//        head->next->value = 2;
//        head->next->next = malloc(sizeof(ListNode));
//        head->next->next->value = 3;
//        head->next->next->next = NULL;
//        
//        ListNode *node = NULL;
//        node = malloc(sizeof(ListNode));
//        node->value = 5;
//        node->next = NULL;
//        
//        AddNode(node, &head);
//        ListNode *p = head;
//        while (p) {
//            printf("value is %d\n", p->value);
//            p = p->next;
//        }
        
        int64_t sharedIndex = 0;
        int64_t index = OSAtomicAdd64(1, &sharedIndex) - 1;
        int64_t newIndex = OSAtomicIncrement64(&index);
        bool success = OSAtomicCompareAndSwap64(1, 0, &newIndex);
        /*
         * Compare And Swap Maybe Like This:
         * bool compareAndSwap64(int oldValue, int newValue, int *value)
         * {
         *   if (*value == oldValue) {
         *      *value = newValue;
         *      return true;
         *   }
         *   return false;
         * }
         */
        if (!success) {
            printf("compared swap failed");
        } else {
            printf("newIndex: %lld\n", newIndex);
        }
        
        int64_t original_0 = 3;
        int64_t original_1 = 3;
        if (original_0 == original_1) {
            int64_t new_original_0 = VQAtomicAdd64(3, &original_0);
            int64_t new_original_1 = OSAtomicAdd64(3, &original_1);
            
            if (new_original_0 == new_original_1) {
                printf("Nice A\n");
            }
        }
        
        // 使用OSSpinLock配合OSAtomicTestAndSet实现单例
//        static id _sharedInstance = nil;
//        static int32_t onceToken = 0;
//        if (!OSAtomicTestAndSet(1, &onceToken)) {
//            static OSSpinLock spinlock = OS_SPINLOCK_INIT;
//            OSSpinLockLock(&spinlock);
//            _sharedInstance = [[[self class] alloc] init];
//            OSSpinLockUnlock(&spinlock);
//        }
        
    }
    return 0;
}
