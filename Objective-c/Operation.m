//
//  Operation.m
//  Jelly
//
//  Created by Jake Hoskins based on Zongzhe Yuans Java Image Processing Library
//  Copyright (c) 2015 Jake Hoskins. All rights reserved.
//

#import "Operation.h"
#import "ImageObject.h"
#import "TrainingSet.h"
#import<malloc/malloc.h>

#define TRAIN_SET(i, j) (trainingSet[BIN_SIZE2 * i + j])
#define MASK(i,j) (mask[[imageObject getHeight] * i + j])
#define LOC_TRAIN_SET(i,j) (localTrainingSet[LOCAL_BIN_SIZE * i + j])
#define HS(i,j,k) ([imageObject getHsValue][[imageObject getWidth] * [imageObject getHeight] * i + [imageObject getHeight] * j + k]) // hmm check


/*
    Constants
 */
const int EROSION_SIZE = 3;    //3
const int THRESH_SIZE = 20;     //20
const double SKIN_THRESH = 1e-5;
const int BLACK = -16777216;
const int BIN_SIZE2 = 32;
const int LOCAL_BIN_SIZE = 32;
const int LOCAL_SIZE = 20;


@implementation Operation

/**
    Default Constructor (private)
 */
-(id) init{
    self = [super init];
    if (self) {
        trainingSet = calloc(BIN_SIZE2, sizeof(double));
    }
    return self;
}
/**
    Constructor w/ a trainingset. 
    Normally skin pixel training set can be passed in however the training set should work on any training images.
 
    @param set
 */
-(id) initWithTrainingSet:(double *)set{
    self = [super init];
    if (self) {
        trainingSet = set;
    }
    return self;
}

/**
    Implements a singleton pattern call get instance to get initiate class
 
    @param set
    @return currentInstance
 */
+(instancetype) getInstance:(double *)set {
    static Operation *sharedInstance = nil;
    static dispatch_once_t onceT;
    dispatch_once(&onceT, ^{
        sharedInstance = [[self alloc] initWithTrainingSet:set];
    });
    return sharedInstance;
}
/**
    This method performs general image processing. This method is responisbile, for detececting skin,
    performing erosiion and then using connected components to return a result set of images.
 
    @param imageObject
    @return resultImages
 */
-(NSArray *) process:(ImageObject *) imageObject{
    NSMutableArray *result;
    
    /*
     First we look for background skin pixels and set them to black.
     */
    
    [self findTrainingSet:imageObject];
    
    /*
     Will remove speckle skin pixels not removed and adds black boarder
     so if objects are overlapping they become seperated by black pixels
     */
    
    [self erosion:imageObject];

    /*
        We will now keep a backup as a last resort. Gives us the option to atleast send something to the server as connected
        components may return no imagee objects in the worst case.
     */
    
    ImageObject *remain = [[ImageObject alloc] initWithImage:[imageObject getImage]];
    
    /*
        Seperates sweeets in hand, into computable ImageObject's
     */
    result = [[NSMutableArray alloc] initWithArray:[self connectedComponents:imageObject]];
    if ([result count] == 0) {
        // Somethings gone wrong use the backup
        result = [[NSMutableArray alloc] initWithObjects:remain, nil];
    }
    

    for (int i = 0; i < [result count]; i++) {
        [[result objectAtIndex:i] draw];
        [[result objectAtIndex:i] setHistogram];
//        [self gaussianScope:[result objectAtIndex:i]];
//        [[result objectAtIndex:i] draw];

    }
    
    
    
    return [NSArray arrayWithArray:result];
}

/**
    Get rid of all pixels that our out of the range (expectation +- 3* the deviation)
 
    @param imageObject
 */
-(void) gaussianScope:(ImageObject *) imageObject {
    double hExpectation  = [imageObject getHGaussian][0];
    double hDeviation = [imageObject getHGaussian][1];
    double sExpectation = [imageObject getSGaussian][0];
    double sDeviation = [imageObject getSGaussian][1];
    double h,s = 0;
    for (int i = 0; i < [imageObject getWidth]; i++) {
        for (int j = 0; j < [imageObject getHeight]; j++) {
            //NSLog(@"%i",HS(0, i, j));
            h = HS(0, i, j) / (256 / [TrainingSet getBinSize])+ 1;
            s = HS(1, i, j) / (256 / [TrainingSet getBinSize])+ 1;
//            if (s < floor(sExpectation) - 3 * sDeviation || s > ceil(sExpectation) + 3 * sDeviation) {
//                [imageObject setRgb:i withY:j withColour:BLACK];
//            }
            if (h < floor(hExpectation) - 3 * hDeviation
                || h > ceil(hExpectation) + 3 * hDeviation
                || s < floor(sExpectation) - 5 * sDeviation
                || s > ceil(sExpectation) + 5 * sDeviation){
                    [imageObject setRgb:i withY:j withColour:BLACK];
            }
            
            
        }
    }
    
}

/**
    Set the training set so the class has a trainingset
 
    @param trainingSet
*/
-(void) setSet:(double *)set{
    trainingSet = set;
}

/**
    Find the training set pixels and remove them.
    (previously named findSkin)
 
    @param imageObject
 */
-(void) findTrainingSet:(ImageObject *) imageObject{
    NSLog(@"OP Detecting skin...");
    NSArray *tmp;
    double *localTrainingSet = calloc(LOCAL_BIN_SIZE * LOCAL_BIN_SIZE, sizeof(double));
    // Generate a local training set for any reflection - see report
//    [self generateLocal:imageObject withTrainingSet: localTrainingSet]; // malloc bug here
    int hue, sat = 0;
    for (int i = 0; i < [imageObject getWidth]; i++) {
        for (int j = 0; j < [imageObject getHeight]; j++) {
            tmp = [NSArray arrayWithArray:[imageObject rgb2hsb:i withYValue:j]];
            hue = [[tmp objectAtIndex:0] doubleValue] / 8;
            sat = [[tmp objectAtIndex:1] doubleValue] / 8;
            if (TRAIN_SET(hue, sat) > SKIN_THRESH){ //|| LOC_TRAIN_SET(hue,sat) == 0){
                [imageObject setRgb:i withY:j withColour:BLACK];
            }
        }
    }
    free(localTrainingSet);
}

/**
    Will generate a local training set wrt the users skin
 
    @param imageObject
    @param localTerainingSet
 */
-(void) generateLocal:(ImageObject *) imageObject withTrainingSet:(double *)localTrainingSet{
    NSLog(@"OP Generating local training set...");
    int width = [imageObject getWidth] / LOCAL_SIZE;
    int height = [imageObject getHeight] / LOCAL_SIZE;
    int total =  height * [imageObject getWidth] * 2 + width * ([imageObject getHeight] - 2 * height) * 2;
    NSArray *hsv;
    for (int i = 0; i < [imageObject getWidth]; i++) {
        for (int j = 0; j < [imageObject getHeight]; j++) {
            hsv = [NSArray arrayWithArray:[imageObject rgb2hsb:i withYValue:j]];
            LOC_TRAIN_SET([[hsv objectAtIndex:0] intValue] / 8, [[hsv objectAtIndex:1] intValue] / 8)++;
        }
    }
    for (int i = 0; i < LOCAL_BIN_SIZE; i++) {
        for (int j = 0; j < LOCAL_BIN_SIZE; j++) {
            LOC_TRAIN_SET(i, j) /= total;
        }
    }
}
/**
    Performs an erosion function on a ImageObject
 
    @param imageObject
 */
-(void) erosion:(ImageObject *) imageObject{
    int *mask = calloc([imageObject getWidth] * [imageObject getHeight], sizeof(int));
    NSLog(@"OP Performing erosion...");
    for (int i = EROSION_SIZE; i < [imageObject getWidth] - EROSION_SIZE; i++) {
        for (int j = EROSION_SIZE; j < [imageObject getHeight] - EROSION_SIZE; j++) {
            if ([self checkMask:imageObject withI:i withJ:j]) {
                MASK(i, j) = 1;
            }
        }
    }
    
    for (int i = EROSION_SIZE; i < [imageObject getWidth] - EROSION_SIZE; i++) {
        for (int j = EROSION_SIZE; j < [imageObject getHeight] - EROSION_SIZE; j++) {
            if (MASK(i, j) == 1) {
                [imageObject setRgb:i withY:j withColour:BLACK];
            }
        }
    }
    
    /*
     Cut the edge
     */
    for (int i = 0; i < [imageObject getWidth]; i++) {
        for (int j = 0; j < EROSION_SIZE + 1; j++) {
            [imageObject setRgb:i withY:j withColour:BLACK];
        }
        for (int j = [imageObject getHeight] - EROSION_SIZE; j < [imageObject getHeight]; j++) {
            [imageObject setRgb:i withY:j withColour:BLACK];
        }
    }
    
    for (int j = 0; j < [imageObject getHeight]; j++) {
        for (int i = 0; i < EROSION_SIZE + 1; i++) {
            [imageObject setRgb:i withY:j withColour:BLACK];
        }
        for (int i = [imageObject getWidth] - EROSION_SIZE; i < [imageObject getWidth]; i++) {
            [imageObject setRgb:i withY:j withColour:BLACK];
        }
    }
    free(mask);
}

/**
    Check the mask wrt the imageObject
 
    @param x
    @param y
 */
-(BOOL) checkMask:(ImageObject *)imageObject withI:(int) i withJ:(int) j{
    for (int i2 = i - EROSION_SIZE; i2 < i + EROSION_SIZE + 1; i2++) {
        for (int j2 = j - EROSION_SIZE; j2 < j + EROSION_SIZE + 1; j2++) {
            if ([imageObject getRGBALong:i2 atY:j2] == BLACK) {
                return  true;
            }
        }
    }
    return false;
}

/**
    Find the 'dad' of the number in the mask
 
    @param list
    @param number
    @return sameNumbers
 */
-(int) findSame:(NSArray *)list withNum:(int) number{
    if ([list count] >= number) {
        if ([[list objectAtIndex:number] intValue] == number || [[list objectAtIndex:number] intValue] == 0) {
            return number;
        }else{
            return [[list objectAtIndex:number] intValue];
        }
    }else{
        return 0;
    }
}

/**
    Performs the connected components algorithm on an ImageObject.
    This function will seperate a processed ImageObject into multiple ImageObjects if needed
 
    @return resultImages
 */
-(NSArray *) connectedComponents:(ImageObject *) imageObject {
    NSLog(@"OP Detecting components...");
    NSMutableArray *resultImagesArr = [[NSMutableArray alloc] init];
    int *mask = calloc([imageObject getWidth] * [imageObject getHeight], sizeof(int));
    int thresholder = [imageObject getWidth] * [imageObject getHeight] / THRESH_SIZE;
    int count = 1;
    NSMutableArray *regionSize = [[NSMutableArray alloc] init];
    NSMutableArray *sameValues = [[NSMutableArray alloc] init];
    [regionSize addObject:@0];
    [sameValues addObject:@0];
    
    /*
     Loop over image and check the image over the mask to see
     if regions are continious and create an array of region size and
     the number of same values. Check the Java model for a clearer view of this algorithm.
     */
    for (int i = 1; i < [imageObject getWidth]; i++) {
        for (int j = 1; j < [imageObject getHeight]; j++) {
            if (([imageObject getRGBALong:i atY:j] == BLACK)) { // not black
                continue;
            }else{
                if (MASK((i-1),j) == 0 && MASK(i, (j-1)) == 0) {
                    MASK(i, j) = count;
                    count++;
                    [regionSize addObject:@1];
                    [sameValues addObject:@0];
                }else if(MASK((i-1), j) != 0 && MASK(i,(j-1)) == 0){
                    MASK(i, j) = MASK((i-1), j);
                    int index = [self findSame:sameValues withNum:MASK(i, j)];
                    int obj = [[regionSize objectAtIndex:index] intValue] + 1;
                    [regionSize replaceObjectAtIndex:index withObject:[NSNumber numberWithInt:obj]];
                }else if(MASK((i-1), j) == 0 && MASK(i, (j-1)) != 0){
                    MASK(i, j) = MASK(i, (j-1));
                    int index = [self findSame:sameValues withNum:MASK(i, j)];
                    int obj = [[regionSize objectAtIndex:index] intValue] + 1;
                    [regionSize replaceObjectAtIndex:index withObject:[NSNumber numberWithInt:obj]];
                }else if(MASK((i-1), j) != 0 && MASK(i, (j-1)) != 0 && [self findSame:sameValues withNum:MASK((i - 1), j)] == [self findSame:sameValues withNum:MASK(i, (j-1))]){
                    MASK(i, j) = MASK(i, (j-1));
                    int index = [self findSame:sameValues withNum:MASK(i, j)];
                    int obj = [[regionSize objectAtIndex:index] intValue] + 1;
                    [regionSize replaceObjectAtIndex:index withObject:[NSNumber numberWithInt:obj]];
                }else {
                    MASK(i, j) = MASK(i, (j-1));
                    int tmp1 = [self findSame:sameValues withNum:MASK(i, j)];
                    int tmp2 = [self findSame:sameValues withNum:MASK((i-1), j)];
                    
                    int obj = [[regionSize objectAtIndex:tmp1] intValue] + [[regionSize objectAtIndex:tmp2] intValue] +1;
                    [regionSize replaceObjectAtIndex:tmp2 withObject:[NSNumber numberWithInt:obj]];
                    [regionSize replaceObjectAtIndex:tmp1 withObject:@0];
                    [sameValues replaceObjectAtIndex:MASK(i, j) withObject:[NSNumber numberWithInt:tmp2]];
                    [sameValues replaceObjectAtIndex:tmp1 withObject:[NSNumber numberWithInt:tmp2]];
                    [sameValues replaceObjectAtIndex:tmp1 withObject:[NSNumber numberWithInteger:tmp2]];
                    
                    for (int k = 0; k < [sameValues count]; k++) {
                        if ([[sameValues objectAtIndex:k] intValue] == tmp1) {
                            [sameValues replaceObjectAtIndex:k withObject:[NSNumber numberWithInt:tmp2]];
                        }
                    }
                    [sameValues replaceObjectAtIndex:tmp1 withObject:[NSNumber numberWithInt:tmp2]];
                }
            }
        }
    }
    
    // Big region is what is most likely the jellybean
    NSMutableArray *bigRegion = [[NSMutableArray alloc] init];
    for (int i = 0; i < [regionSize count]; i++) {
        if ([[regionSize objectAtIndex:i] intValue] >= thresholder) {
            [bigRegion addObject:[NSNumber numberWithInt:i]];
        }
    }
    
    for (int i = 0 ; i < [bigRegion count]; i++) {
        // Create a blank null image for how many big regions we have and add them to our result array
        UIGraphicsBeginImageContextWithOptions([imageObject getImage].size, true, 0.0);
        UIImage *blank = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        [resultImagesArr addObject:[[ImageObject alloc] initWithImage:blank]];
    }

    // Draw the images
    for (int i  = 0 ; i < [imageObject getWidth]; i++) {
        for (int j = 0; j < [imageObject getHeight]; j++) {
            if (MASK(i, j) == 0) {
                continue;
            }else if ([[sameValues objectAtIndex:MASK(i, j)] intValue] == 0) {
                if ([[regionSize objectAtIndex:MASK(i, j)] intValue] < thresholder) {
                    continue;
                }else{
                    // Redrawing our sweet
                    [[resultImagesArr objectAtIndex:[bigRegion indexOfObject:[NSNumber numberWithInt:MASK(i, j)]]] setRgb:i withY:j withColour:(int)[imageObject getRGBALong:i atY:j]];
                }
            }else{
                if ([[regionSize objectAtIndex:[[sameValues objectAtIndex:MASK(i, j)] intValue]]intValue] < thresholder) {
                    continue;
                }else{
                    // Redrawing our sweet
                    [[resultImagesArr objectAtIndex:[bigRegion indexOfObject:[sameValues objectAtIndex:MASK(i, j)]]] setRgb:i withY:j withColour:(int)[imageObject getRGBALong:i atY:j]];
                }
            }
        }
    }
    NSLog(@"OP [Found %li components]",[bigRegion count]);
    free(mask);
    return [NSArray arrayWithArray:resultImagesArr];
}


-(void) dealloc {
    free(trainingSet);
}

@end
