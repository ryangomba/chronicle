#import "CHCustomCloud.h"
#import <RGNetworking/RGNetworking.h>
#import "CHDatabase.h"
#import "CHDBModelOperation.h"
#import "CHDBListOperation.h"

@implementation CHCustomCloud

//static NSString * const kAPIRoot = @"http://localhost:5000/api/model";
static NSString * const kAPIRoot = @"https://chronicle.appthat.com/api/model";

+ (void)subscribe {
    // noop
}

+ (void)saveAllStories {
    // noop
}

+ (void)restoreAllStoriesWithCompletion:(void (^)(BOOL success))completion {
    // noop
}

+ (void)deleteAllStories {
    // noop
}

+ (void)applyDatabaseOperation:(CHDBOperation *)operation
                    completion:(void (^)(BOOL success))completion {
    
    if ([operation isKindOfClass:[CHDBModelOperation class]]) {
        [self applyDatabaseModelOperation:(CHDBModelOperation *)operation completion:completion];
        
    } else if ([operation isKindOfClass:[CHDBListOperation class]]) {
        [self applyDatabaseListOperation:(CHDBListOperation *)operation completion:completion];
    }
}

+ (void)applyDatabaseModelOperation:(CHDBModelOperation *)operation
                         completion:(void (^)(BOOL success))completion {
    
//    NSString *urlString = [NSString stringWithFormat:@"%@/%@/%@/%@",
//                           kAPIRoot,
//                           operation.entityName,
//                           operation.collectionName,
//                           operation.entityPK];
//    NSURL *url = [NSURL URLWithString:urlString];
//
//    RGRequest *request = nil;
//
//    if (operation.type == CHDBOperationTypeInsert) {
//        request = [RGPostRequest requestWithURL:url parameters:operation.info files:nil];
//    } else if (operation.type == CHDBOperationTypeUpdate) {
//        request = [RGPatchRequest requestWithURL:url parameters:operation.info files:nil];
//    } else if (operation.type == CHDBOperationTypeDelete) {
//        request = [RGDeleteRequest requestWithURL:url parameters:nil];
//    }
//
//    [[RGService sharedService] startJSONRequest:request responseHandler:
//     ^(RGRequest *completedRequest, id responseObject, RGRequestError *error) {
//         if (!error && responseObject) {
//             [CHDatabase deleteDatabaseOperation:operation];
//             [self handleUpdatedModel:responseObject];
//         }
//         completion(error == nil);
//     }];
}

+ (void)applyDatabaseListOperation:(CHDBListOperation *)operation
                        completion:(void (^)(BOOL success))completion {
    
    NSString *urlString = [NSString stringWithFormat:@"%@/%@/%@/%@/%@",
                           kAPIRoot,
                           operation.entityName,
                           operation.collectionName,
                           operation.entityPK,
                           operation.listKey];
    NSURL *url = [NSURL URLWithString:urlString];
    
    RGRequest *request = nil;
    
    NSDictionary *info = @{
        @"member_key": operation.memberPK,
        @"member_index": @(operation.memberIndex),
    };
    
    request = [RGPatchRequest requestWithURL:url parameters:info files:nil];
    
    [[RGService sharedService] startJSONRequest:request responseHandler:
     ^(RGRequest *completedRequest, id responseObject, RGRequestError *error) {
         if (!error && responseObject) {
             [CHDatabase deleteDatabaseOperation:operation];
             [self handleUpdatedModel:responseObject];
         }
         completion(error == nil);
     }];
}

+ (void)handleUpdatedModel:(NSDictionary *)modelDictionary {
    NSLog(@"%@", modelDictionary);
}

@end
