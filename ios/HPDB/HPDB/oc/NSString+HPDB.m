//
//  NSString+HPDB.m
//  HPDB
//
//  Created by rkhd on 2018/8/14.
//  Copyright © 2018 rkhd. All rights reserved.
//

#import "NSString+HPDB.h"

@implementation NSString (HPDB)

+ (void)db_findAllBy:(NSString *)attr
           withValue:(id)val
             columns:(NSArray<NSString *> *)clms
             orderBy:(NSString *)column
           ascending:(BOOL)ascending
               limit:(int)limit
              offset:(int) offset
            callback:(HPDBCallback)cb
{
    
}
@end
