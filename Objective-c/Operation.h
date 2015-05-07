/**
    This class encapsulates an ImageProcessing library which can be used to process images.
 
   @author Jake Hoskins based on Zongzhe Yuans Java Image Processing Libraryn.
 */

#import <Foundation/Foundation.h>
#import "ImageObject.h"
@interface Operation : NSObject{
    // Private
    Operation *operate;
    double *trainingSet;
}

/*
    Public
 */
+(instancetype) getInstance:(double *) set; 

-(void) setSet:(double *)set;

-(void) findTrainingSet:(ImageObject *) imageObject;
-(void) erosion:(ImageObject *) imageObject;
-(NSArray *) process:(ImageObject *) imageObject;
-(NSArray *) connectedComponents:(ImageObject *) imageObject;

@end
