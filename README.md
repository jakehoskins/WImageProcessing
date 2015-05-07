# WImageProcessing
An image processing library that is versatile across platforms. WImageProcessing has working implementations in Java, Java-Android Studio and Objective-c.

WImageProcessing is a powerful image processing library that allows you to remove a training set from the background e.g. for skin detection. It has other image processing algorithms such as erosion, connected components and the ability to detect local training sets as well as non-local training sets. 

Objective-c

Init the Operation class with a training set:

	TrainingSet *trainingSet = [TrainingSet getInstance];
	Operation *operator = [Operation getInstance:[trainingSet getSet]];

Create ImageObject with UIImage:

	UIImage *img = [UIImage imageNamed:@“image-name”];
	ImageObject *imgObj = [[ImageObject alloc] initWithImage:img];

Using Operator:

	[operator findTrainingSet: imgObj];
	[operator erosion: imgObj];
	UIImage *img = = [imgObj getImage];