#import <Foundation/Foundation.h>

@class YapDatabase;
@class YapDatabaseView;

@class SJDatabaseViewDataSource;
@protocol SJDatabaseViewDataSourceDelegate <NSObject>

- (void)dataSourceDidChange:(SJDatabaseViewDataSource *)dataSource
           insertedSections:(NSIndexSet *)insertedSections
            deletedSections:(NSIndexSet *)deletedSections
              insertedItems:(NSArray *)insertedItems
               deletedItems:(NSArray *)deletedItems
               changedItems:(NSArray *)changedItems;

@end

@interface SJDatabaseViewDataSource : NSObject

@property (nonatomic, weak) id<SJDatabaseViewDataSourceDelegate> delegate;

- (id)initWithView:(YapDatabaseView *)view database:(YapDatabase *)database;

- (NSInteger)numberOfItemsInSection:(NSInteger)section;
- (id)itemAtIndexPath:(NSIndexPath *)indexPath;

- (NSArray *)allItemsInSection:(NSInteger)section;

@end
