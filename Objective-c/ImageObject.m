//
//  ImageObject.m
//  Jelly
//
//  Created by Jake Hoskins based on Zongzhe Yuans Java Image Processing Library
//  Copyright (c) 2015 Jake Hoskins. All rights reserved.
//


#import "ImageObject.h"
#import <math.h>

#define HS(i,j,k) (hsValue[dim2 * dim3 * i + dim3 * j + k])
#define SET(i,j) (set[BIN_SIZE * i + j])
#define TWODHIST(i, j) (twoDHistogram[BIN_SIZE * i + j])
#define TWODHIST2(i,j) (twoDHistogram2[TWO_D_BIN * i + j])


/*
 Constants.
 */
const int BIN_SIZE = 32;
const int CROP_FRAME = 400;
const int MAX_RGB = 255;
const int BLACK2 = -16777216;
const int SMALL_BIN_SIZE = 16;
const int TWO_D_BIN = 32;

@implementation ImageObject

#pragma Constructors

/**
    Construct ImageObject
    @param image
 */
-(id) initWithImage:(UIImage *) image{
    self = [super init];
    if (self) {
        [self setImage:image];
    }
    return self;
}

/**
   Construct ImageObject w/ path to image file
    @param path
 */
-(id) initWithImageFromFile:(NSString *) path{
    self = [super init];
    if (self) {
        [self setImageFromPath:path];
    }
    
    return self;
}

/**
    Default Constructor
 */
-(id) init{
    // constructor call super initalise then instantiate
    self = [super init];
    if (self) {
        _image = NULL;
    }
    return self;
}

#pragma Logic

/**
    Convert the rgb to hsb at a point in the member image
    @param x
    @param y
 */
-(NSArray *) rgb2hsb:(int)x withYValue:(int)y{
    NSArray *hsb;
    NSMutableArray *result = [[NSMutableArray alloc] init];;
    UIColor *colour = [self getRGBA:x atY:y];
    CGFloat hue;
    CGFloat saturation;
    CGFloat brightness;
    CGFloat alpha;
    BOOL success = [colour getHue:&hue saturation:&saturation brightness:&brightness alpha:&alpha];
    if(success){
        int dim = 3;
        float tmp = 0;
        hsb = [[NSArray alloc] initWithObjects:[NSNumber numberWithFloat:hue],[NSNumber numberWithFloat:saturation], [NSNumber numberWithFloat:brightness], nil];
        for (int i = 0; i < dim; i++) {
            // Compute the value
            tmp = [[hsb objectAtIndex:i] floatValue] * MAX_RGB;
            // insert the value as an integer to our array
            [result insertObject:[NSNumber numberWithInt:(int) tmp] atIndex:i];
        }
        return [NSArray arrayWithArray:result];
    }else{
        return NULL;
    }
    
}

#pragma Setters

/**
    Set the image
    @param image
 */
-(void) setImage:(UIImage *)image{
    cropSize = CGRectMake(image.size.width / 2 - (CROP_FRAME / 2), image.size.height / 2 - (CROP_FRAME / 2), CROP_FRAME, CROP_FRAME);
    imageBitmap = [[ANImageBitmapRep alloc] initWithImage:image];
    _image = [imageBitmap image];
    
}

/**
    Set the image w/ path
    @param path
 */
-(void) setImageFromPath:(NSString *)path{
    [self setImage:[UIImage imageNamed:[NSString stringWithFormat:@"%@",path]]];
}

/**
    Set rgb at point on member image
    @param x
    @param y
    @param rgb (Packed Integer)
 */
-(void) setRgb:(int) x withY:(int)y withColour:(int)rgb{
    UInt8 newColor[4];
    
    newColor[0] = (rgb >> 16) & 0xFF;
    newColor[1] = (rgb >> 8) & 0xFF;
    newColor[2] = rgb & 0xFF;
    newColor[3] = rgb >> 24;
    
    [imageBitmap setRawPixel:newColor atPoint:BMPointMake(x, y)];
}


/**
    Set the histogram
 */
-(void) setHistogram{
    NSLog(@"IO Building histogram...");
    NSArray *hsb;
    long total = 0;
    long sum = 0;
    
    // dynamically alloc memory
    hsValue = (int *) calloc(2 * [self getWidth]*[self getHeight], sizeof(int));
    set = (long *) calloc(BIN_SIZE * BIN_SIZE,sizeof(long));
    twoDHistogram = (double *)  calloc(BIN_SIZE * BIN_SIZE, sizeof(double));
    hHistogram = (double *)calloc(BIN_SIZE, sizeof(double));
    sHistogram = (double *)calloc(BIN_SIZE, sizeof(double));
    
    // loop over each pixel and get the hue saturation value and put it in our array.
    int hs[2] = {0};
    for (int i = 0; i < [self getWidth]; i++) {
        for (int j = 0; j < [self getHeight]; j++) {
            // store hue saturation
            hsb = [NSArray arrayWithArray:[self rgb2hsb:i withYValue:j]];
            hs[0] = [[hsb objectAtIndex:0] intValue];
            hs[1]= [[hsb objectAtIndex:1] intValue];

//            HS(0, i, j) = [[hsb objectAtIndex:0] intValue];
//            HS(1, i, j) = [[hsb objectAtIndex:1] intValue];
            if ([self getRGBALong:i atY:j] != BLACK2) {
                // store non black pixels

                SET((hs[0] / 8), (hs[1] / 8))++;

                total++;
            }
        }
      
    }
    
    double count = 0;
    double count2 = 0;
    // normalising the histograms
    for (int i = 0; i < BIN_SIZE; i++) {
        sum=0;
        for (int j = 0; j < BIN_SIZE; j++) {
            sum += SET(i, j);
            TWODHIST(i, j) = (double) SET(i, j) / total;
            count2 = count2 + TWODHIST(i, j);
        }
        hHistogram[i] = (double) sum / total;
        count = count + hHistogram[i];
    }
  //  NSLog(@"IO [two-dimmensional histogram: %.2f checksum]", count2);
  //  NSLog(@"IO [hue-histogram: %.2f checksum]", count);
    count = 0;
    for (int j = 0; j < BIN_SIZE; j++) {
        sum=0;
        for (int i = 0; i < BIN_SIZE; i++) {
            sum += SET(i, j);
        }
        sHistogram[j] = (double) sum / total;
        count = count + sHistogram[j];
    }
   // NSLog(@"IO [saturation-histogram: %.2f checksum]", count);
}

#pragma Getters

/**
    Get width of image
    @return width
 */
-(int) getWidth{
    return (int) _image.size.width;
}

/**
    Get height of image
    @return height
 */
-(int)getHeight{
    return (int) _image.size.height;
}

/**
    Get the hsValue
    @return hsValue
 */
-(int *) getHsValue{
    return hsValue;
}
/**
    Get the hue histogram
    @return hHistogram
 */
-(double *) gethHistogram{
    return hHistogram;
}

/**
    Get the saturation histogram
    @return sHistogram;
 */
-(double *) getsHistogram{
    return sHistogram;
}

/**
    Get the hue gaussian 
    @return hGaussian
 */
-(double *) getHGaussian{
    return [self getGaussian:hHistogram];
}
/**
    Get the saturation gaussian
 */
-(double *) getSGaussian{
    return [self getGaussian:sHistogram];
}
/**
    Get the two-dimmensional histogram
    @return twoDHistogram
 */
-(double *) getTwoDHistogram{
    return twoDHistogram;
}
/**
    Get the smaller hue histogram
 
 * @return hHistogram2
 */
-(double *) getHSmallHistogram{
    return [self getSmallHistogram:hHistogram];
}
/**
    Get the smaller saturation hustogram
 
 * @return sHistogram2
 */
-(double *) getSSmallHistogram{
    return [self getSmallHistogram:sHistogram];
}
/**
    Get the combined histogram
    @return histogram
*/
-(double *) getCombinedHistogram{
    double *histogram = calloc(SMALL_BIN_SIZE * 2, sizeof(double));
    double *temp1 = [self getHSmallHistogram];
    double *temp2 = [self getSSmallHistogram];
    double count = 0; // testing
    /* Filling hue saturations linearly in one dimmension*/
    for (int i = 0; i < SMALL_BIN_SIZE; i++) {
        histogram[i] = temp1[i];
        count = count + histogram[i];
    }
    for (int i = 0; i < SMALL_BIN_SIZE; i++) {
        histogram[i + SMALL_BIN_SIZE] = temp2[i];
        count = count + histogram[i + SMALL_BIN_SIZE];
    }
   // NSLog(@"IO [combined-histogram: %2.f checksum]", count);
    return histogram;
}
/**
    Get the smaller histogram in one dimmension
    @param histogram
    @return histogram2;
 */
-(double *) getSmallHistogram:(double *) histogram{
    /* Returning so have to use heap */
    double *histogram2 = calloc(SMALL_BIN_SIZE, sizeof(double));
    for (int i = 0; i < SMALL_BIN_SIZE; i++) {
        for (int j = 0; j < BIN_SIZE / SMALL_BIN_SIZE; j++) {
            histogram2[i] += histogram[(BIN_SIZE / SMALL_BIN_SIZE) * i + j];
        }
    }
    return histogram2;
}
/**
  Get the smaller histogram in two dimmensions
 
  @return twoDHistogram2 The 2 D histogram that has bigger bin size than
          original
 */
-(double *) getSmall2DHistogram{
    double *oneDHistogram = calloc(TWO_D_BIN * TWO_D_BIN, sizeof(double));
    double count = 0;
    for (int i = 0; i < TWO_D_BIN; i+=1) {
        for (int j = 0; j < TWO_D_BIN; j+=1) {
            for (int j2 = 0; j2 < BIN_SIZE / TWO_D_BIN; j2++) {
                for (int k = 0; k < BIN_SIZE / TWO_D_BIN; k++) {
                    oneDHistogram[i * TWO_D_BIN + j] += TWODHIST(((BIN_SIZE / TWO_D_BIN) * i + j2), ((BIN_SIZE / TWO_D_BIN) * j + k));
                }
            }
            count = count + oneDHistogram[i * TWO_D_BIN + j];
        }
    }
    //NSLog(@"IO [small-two-dimmensional: %2.f checksum]", count);
    return oneDHistogram;
}


-(double *) get1DHistogram{
    double count = 0;
    double *oneDHist = calloc(BIN_SIZE * BIN_SIZE, sizeof(double));
    for (int i = 0; i < BIN_SIZE; i++) {
        for (int j = 0; j < BIN_SIZE; j++) {
            oneDHist[i * BIN_SIZE + j] = TWODHIST(i, j);
            count = count + oneDHist[i * BIN_SIZE + j];
        }
    }
    // NSLog(@"IO [one-dimmensional checksum: %.2f]", count);
    return oneDHist;
}
/**
    Return the UIImage, will redraw on call
    @return drawnImage
 */

-(UIImage *) getImage {
    return [imageBitmap image];
}

/**
    Call draw if you wish to see if the effects of any rgb manipulation.
 */
-(void) draw{
    _image = [self getImage];
}

/**
    Get the RGBA at a x,y location in member image
    @return rgb
 */
-(long)getRGBALong:(int)xp atY:(int)yp {
    BMPixel pixel = [imageBitmap getPixelAtPoint:BMPointMake(xp, yp)];
    int r = pixel.red * MAX_RGB;
    int g = pixel.green * MAX_RGB;
    int b = pixel.blue * MAX_RGB;
    int a = pixel.alpha * MAX_RGB;
    return  (r << 16) | (g << 8) | (b) | (a << 24);
    
}

/**
   Get the RGBA at a x,y location in member image as a UIColor
    @param x
    @param y
    @return rgb
 */
-(UIColor *)getRGBA:(int)xp atY:(int)yp {
    BMPixel pixel = [imageBitmap getPixelAtPoint:BMPointMake(xp, yp)];
    return [UIColor colorWithRed:pixel.red green:pixel.green blue:pixel.blue alpha:pixel.alpha];
}

/**
    Gets the gaussian value of the histogram
    @param x
    @param y
    @return gaussianValue;
 */
-(double *) getGaussian:(double *) histogram{
    double deviation = 0;
    double mean = 0;
    double error = 0;
    for (int i = 0; i < BIN_SIZE; i++) {
        mean += (i+1) * histogram[i];
        
    }
    for (int i = 0; i < BIN_SIZE; i++) {
        deviation += histogram[i] * pow((i+1) - mean, 2);
    }
    
    // calculate the error between gaussian function and raw data
    for (int i = 0; i < BIN_SIZE; i++) {
        error += abs(histogram[i]
                     -pow(M_E, -pow((i+1) - mean, 2)
                          / (2 * pow(deviation, 2)))
                     / (deviation * sqrt(2 * M_PI )));
    }

    // return pointer to address of malloc on the heap
    double *pResult = malloc(sizeof(double) * 3);
    pResult[0] = mean;
    pResult[1] = deviation;
    pResult[2] = error;
    return pResult;
}

#pragma Class Methods
/**
    Class method can be used as a utility to crop images external to this class
    @param fram
    @return cropedImage
 */
+(UIImage *) cropImage:(UIImage *)img withFrame:(CGRect)frame {
    ANImageBitmapRep *tmp = [[ANImageBitmapRep alloc] initWithImage:img];
    [tmp cropFrame:frame];
    return [tmp image];
}
/**
    Class method can be used as a utility to scale images external to this class
    @param size
    @return scaledImmage
 */
+(UIImage *) scaleImage:(UIImage *)img withSize:(CGSize)size{
    ANImageBitmapRep *tmp = [[ANImageBitmapRep alloc] initWithImage:img];
    [tmp setSize:BMPointMake(size.width, size.height)];
    return [tmp image];
}

// find the right destructor for NSObjects think this could be wrong
-(void) dealloc{
    free(set);
    free(twoDHistogram);
    free(hHistogram);
    free(sHistogram);
    free(hsValue);
}

@end
