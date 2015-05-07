//
//  TrainingSet.m
//  Jelly
//
//  Created by Jake Hoskins based on Zongzhe Yuans Java Image Processing Library
//  Copyright (c) 2015 Jake Hoskins. All rights reserved.
//

#import "TrainingSet.h"
#import "ImageObject.h"

#define SET(i, j) (set[BIN_SIZE3 * i + j])
#define TRAIN_SET(i, j) (trainSet[BIN_SIZE3 * i + j])

const int BIN_SIZE3 = 32;
NSString* const FILE_NAME = @"trainingSet.csv";
NSString* const SEPERATOR = @",";


@implementation TrainingSet
-(id) init{
    self = [super init];
    if (self) {
        /*
         To read/write we have to do so in 'sandbox' this is required by the OS.
         We have to get the path to the sandbox before we can access the contents of our directory
         */
        NSArray  *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString  *documentsDirectory = [paths objectAtIndex:0];
        filePath = [NSString stringWithFormat:@"%@/%@", documentsDirectory,FILE_NAME];
        set = calloc(BIN_SIZE3 * BIN_SIZE3, sizeof(long));
        [self loading];
    }
    return self;
}
/**
   Call to enforce singleton pattern
 */
+(instancetype) getInstance{
    static TrainingSet *sharedInstance = nil;
    static dispatch_once_t onceT;
    dispatch_once(&onceT, ^{
        sharedInstance = [[self alloc] init];;
        
    });
    return sharedInstance;
}

/**
    Load the CSV training set
 */
-(void) loading{
    BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:filePath];
    NSString *content;
    NSArray* allLinedStrings;
    if (!fileExists) {
        [[NSFileManager defaultManager] createFileAtPath:filePath contents:NULL attributes:nil];
    }else{
        /*
            Loading the contents of the csv into our 2D trainingSet array.
            Get the content, seperate content by lines, then we will loop over and seperate each line by ',' as
            we are working with a csv.
         */
        content = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:NULL];
        allLinedStrings = [content componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
        total = [[allLinedStrings objectAtIndex:0] doubleValue];
        if ([allLinedStrings count] != 0) {
            NSString *dataRow;
            NSArray *dataArray;
            int temp = 0;
            for (int i = 0; i < BIN_SIZE3; i++) {
                dataRow = [allLinedStrings objectAtIndex:i + 1];
                dataArray = [dataRow componentsSeparatedByString:SEPERATOR];
                for (int j = 0; j < BIN_SIZE3; j++) {
                    temp = (long) total * [[dataArray objectAtIndex:j] doubleValue];
                    SET(i, j) = temp;
                }
            }
        }
    }
}
/**
    Save the training set file
 */
-(void) save{
    /*
        Writing the contents in our trainingSet array back to the trainingSet file.
     */
    if (![[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        [[NSFileManager defaultManager] createFileAtPath:filePath contents:nil attributes:nil];
    }
    NSFileHandle *myHandle = [NSFileHandle fileHandleForWritingAtPath:filePath];
    [myHandle seekToFileOffset:0];
    [myHandle writeData:[[NSString stringWithFormat:@"%ld\n", total] dataUsingEncoding:NSUTF8StringEncoding]];
    double value = 0;
    for (int i = 0; i < BIN_SIZE3; i++) {
        value = (double) SET(i, 0) / total;
        [myHandle writeData:[[NSString stringWithFormat:@"%f", value] dataUsingEncoding:NSUTF8StringEncoding]];
        for (int j = 1; j < BIN_SIZE3; j++) {
            value = (double) SET(i,j) / total;
            [myHandle writeData:[[NSString stringWithFormat:@",%f", value] dataUsingEncoding:NSUTF8StringEncoding]];
        }
        [myHandle writeData:[[NSString stringWithFormat:@"\n"] dataUsingEncoding:NSUTF8StringEncoding]];
    }
      [myHandle closeFile];
}

/**
    Adding a training set
    @param imageObject
 */
-(void) addSet:(ImageObject *)imageObject{
    /*
        For each pixel we must get the hue, saturation.
        The hue saturation is an index to our backprojection csv file
        The more hits at an index the more likely skin will be there.
     */
    NSArray *tmp; // for hsb
    total += [imageObject getHeight] * [imageObject getWidth];
    long hue,sat = 0;
    for (int i = 0; i < [imageObject getWidth]; i++) {
        for (int j = 0; j < [imageObject getHeight]; j++) {
            // just make one call / 8 to put in 1 of 32 bins (255 / 32)
            tmp = [NSArray arrayWithArray:[imageObject rgb2hsb:i withYValue:j]];
            hue = [[tmp objectAtIndex:0] doubleValue] / 8;
            sat = [[tmp objectAtIndex:1] doubleValue] / 8;
            SET(hue, sat)++;
        }
    }
    // We must save what we have processed to the training set file.
    [self save];
}

/**
    Function will get the training set, the value of the set is the possibility of finding skin at pixel
    @return set
 */
-(double *) getSet{
    double *trainSet = calloc(BIN_SIZE3 * BIN_SIZE3, sizeof(double));
    for (int i = 0; i < BIN_SIZE3; i++) {
        for (int j = 0; j < BIN_SIZE3; j++) {
            TRAIN_SET(i, j) = (double) SET(i, j) / total;
        }
    }
    return trainSet;
}

-(void) dealloc {
    free(set);
}

+(int) getBinSize{
    return BIN_SIZE3;
}

@end
