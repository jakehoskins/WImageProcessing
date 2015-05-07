/**
    This object represents a higher level image which stores histograms.
    Ideal for image processing and compatible with UIImage
 
 */

//#import <UIKit/UIKit.h>
#import "ANImageBitmapRep.h"
@interface ImageObject : NSObject{
    // Private variables
    long *set;
    double *twoDHistogram;
    double *hHistogram;
    double *sHistogram;
    int *hsValue;
    int dim1, dim2, dim3;
    ANImageBitmapRep *imageBitmap;
    
    CGRect cropSize;
}


@property(nonatomic, retain) UIImage *image;

/* 
    Constructs
 */
-(id) initWithImage:(UIImage *) image;
-(id) initWithImageFromFile:(NSString *) path;
/* 
    Getters
 */
-(int) getHeight;
-(int) getWidth;
-(int *) getHsValue;
-(UIImage *) getImage;
-(double *) gethHistogram;
-(double *) getsHistogram;
-(double *) getHGaussian;
-(double *) getSGaussian;
-(double *) getTwoDHistogram;
-(double *) getCombinedHistogram; // 32
-(double *) getSmall2DHistogram; // 64
-(double *) get1DHistogram;  //1024
/*
    Setters
 */
-(void) setImage:(UIImage *)image;
-(void) setImageFromPath:(NSString *)path;
-(void) setRgb:(int) x withY:(int)y withColour:(int)rgb;
-(void) setHistogram;

/*
    Actions
 */
-(NSArray *) rgb2hsb:(int)x withYValue:(int)y;
-(long)getRGBALong:(int)xp atY:(int)yp; // packed int
-(UIColor *)getRGBA:(int)xp atY:(int)yp;
-(void) draw;

/*
    Class
 */
+(UIImage *) cropImage:(UIImage *)img withFrame:(CGRect)frame;
+(UIImage *) scaleImage:(UIImage *)img withSize:(CGSize)size;

@end
