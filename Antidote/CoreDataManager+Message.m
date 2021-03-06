//
//  CoreDataManager+Message.m
//  Antidote
//
//  Created by Dmitry Vorobyov on 26.07.14.
//  Copyright (c) 2014 dvor. All rights reserved.
//

#import "CoreDataManager+Message.h"
#import "CoreData+MagicalRecord.h"

NSString *const kCoreDataManagerNewMessageNotification = @"kCoreDataManagerNewMessageNotification";
NSString *const kCoreDataManagerMessageUpdateNotification = @"kCoreDataManagerMessageUpdateNotification";
NSString *const kCoreDataManagerCDMessageKey = @"kCoreDataManagerCDMessageKey";

@implementation CoreDataManager (Message)

+ (void)fetchedControllerForMessagesFromChat:(CDChat *)chat
                             completionQueue:(dispatch_queue_t)queue
                             completionBlock:(void (^)(NSFetchedResultsController *controller))completionBlock
{
    if (! completionBlock) {
        return;
    }

    dispatch_async([self private_queue], ^{
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"chat == %@", chat];

        NSFetchedResultsController *controller = [CDMessage MR_fetchAllSortedBy:@"date"
                                                                      ascending:YES
                                                                  withPredicate:predicate
                                                                        groupBy:nil
                                                                       delegate:nil
                                                                      inContext:[self private_context]];

        [self private_performBlockOnQueueOrMain:queue block:^{
            completionBlock(controller);
        }];
    });
}

+ (void)messagesWithPredicate:(NSPredicate *)predicate
              completionQueue:(dispatch_queue_t)queue
              completionBlock:(void (^)(NSArray *messages))completionBlock
{
    if (! completionBlock) {
        return;
    }

    dispatch_async([self private_queue], ^{
        NSArray *array = [CDMessage MR_findAllSortedBy:@"date"
                                             ascending:YES
                                         withPredicate:predicate
                                             inContext:[self private_context]];

        [self private_performBlockOnQueueOrMain:queue block:^{
            completionBlock(array);
        }];
    });
}

+ (void)insertMessageWithType:(CDMessageType)type
                  configBlock:(void (^)(CDMessage *message))configBlock
              completionQueue:(dispatch_queue_t)queue
              completionBlock:(void (^)(CDMessage *message))completionBlock;
{
    dispatch_async([self private_queue], ^{
        CDMessage *message = [NSEntityDescription insertNewObjectForEntityForName:@"CDMessage"
                                                           inManagedObjectContext:[self private_context]];

        if (type == CDMessageTypeText) {
            message.text = [NSEntityDescription insertNewObjectForEntityForName:@"CDMessageText"
                                                         inManagedObjectContext:[self private_context]];
        }
        else if (type == CDMessageTypeFile) {
            message.file = [NSEntityDescription insertNewObjectForEntityForName:@"CDMessageFile"
                                                         inManagedObjectContext:[self private_context]];
        }
        else if (type == CDMessageTypePendingFile) {
            message.pendingFile = [NSEntityDescription insertNewObjectForEntityForName:@"CDMessagePendingFile"
                                                                inManagedObjectContext:[self private_context]];
        }
        else if (type == CDMessageTypeCall) {
            message.call = [NSEntityDescription insertNewObjectForEntityForName:@"CDMessageCall"
                                                         inManagedObjectContext:[self private_context]];
        }

        if (configBlock) {
            configBlock(message);
        }

        [[self private_context] MR_saveToPersistentStoreAndWait];

        DDLogVerbose(@"CoreDataManager+Message: inserted message %@", message);

        if (completionBlock) {
            [self private_performBlockOnQueueOrMain:queue block:^{
                completionBlock(message);
            }];
        }

        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:kCoreDataManagerNewMessageNotification
                                                                object:nil
                                                              userInfo:@{kCoreDataManagerCDMessageKey: message}];
        });
    });
}

+ (void)editCDMessageAndSendNotificationsWithMessage:(CDMessage *)message
                                               block:(void (^)())block
                                     completionQueue:(dispatch_queue_t)queue
                                     completionBlock:(void (^)())completionBlock;
{
    dispatch_async([self private_queue], ^{
        if (block) {
            block();

            [[self private_context] MR_saveToPersistentStoreAndWait];

            DDLogVerbose(@"CoreDataManager+Message: edited message %@", message);
        }

        [self private_performBlockOnQueueOrMain:queue block:completionBlock];

        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:kCoreDataManagerMessageUpdateNotification
                                                                object:nil
                                                              userInfo:@{kCoreDataManagerCDMessageKey: message}];
        });
    });
}

+ (void)movePendingFileToFileForMessage:(CDMessage *)message
                        completionQueue:(dispatch_queue_t)queue
                        completionBlock:(void (^)())completionBlock
{
    dispatch_async([self private_queue], ^{
        message.file = [NSEntityDescription insertNewObjectForEntityForName:@"CDMessageFile"
                                                     inManagedObjectContext:[self private_context]];

        message.file.fileSize         = message.pendingFile.fileSize;
        message.file.originalFileName = message.pendingFile.originalFileName;
        message.file.fileNameOnDisk   = message.pendingFile.fileNameOnDisk;
        message.file.fileUTI          = message.pendingFile.fileUTI;

        message.pendingFile = nil;

        [[self private_context] MR_saveToPersistentStoreAndWait];

        [self private_performBlockOnQueueOrMain:queue block:completionBlock];

        DDLogVerbose(@"CoreDataManager+Message: pendingFile -> file for message message %@", message);

        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:kCoreDataManagerMessageUpdateNotification
                                                                object:nil
                                                              userInfo:@{kCoreDataManagerCDMessageKey: message}];
        });
    });
}

@end
