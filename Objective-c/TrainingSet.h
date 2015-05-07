/**
    This class represents a trainingSet that can be used to start the operation class.
 
    @author Jake Hoskins based on Zongzhe Yuans Java Image Processing Library
 */
#import <Foundation/Foundation.h>
#import "ImageObject.h"
@interface TrainingSet : NSObject{
    /*
        Private
     */
    long total;
    long *set;
    NSString *filePath;
}

/*
    Public
 */

+(instancetype) getInstance;

-(void) addSet:(ImageObject *)imageObject;

-(double *) getSet;

/*
    Class
 */
+(int) getBinSize;
@end
