// EXProcessCell.h - Custom cell for the process list

#import <UIKit/UIKit.h>
#import "EXProcessInfo.h"

@interface EXProcessCell : UITableViewCell

- (void)configureWithProcess:(EXProcessInfo *)process;

@end
