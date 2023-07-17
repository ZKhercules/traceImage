//
//  ViewController.m
//
//  Created by zhangkeqin on 2023/5/12.
//  Copyright © 2023 ZK. All rights reserved.
//

#import "ViewController.h"
// 屏幕宽高
#define Screen_Width [UIScreen mainScreen].bounds.size.width
#define Screen_Height [UIScreen mainScreen].bounds.size.height
@interface ViewController ()

@property (nonatomic, strong) UIImageView *tempImageView;


@property (nonatomic, strong) UISlider *slider;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tempImageView = [[UIImageView alloc]initWithFrame:CGRectMake(0, 0, Screen_Width, Screen_Height)];
    [self.view addSubview:self.tempImageView];
    
    //可手动调节阈值
    [self drawImage:95];
}

//ptr[0]:透明度,ptr[1]:B,ptr[2]:G,ptr[3]:R
//第一步 使用阈值将图片二值化 并将显色的部分改成RGB为（0,0,255）的正蓝色
- (void)drawImage:(double)filterValue{
    UIImage *image = [UIImage imageNamed:@"yong.png"];
    // 分配内存

    const int imageWidth = image.size.width;
    const int imageHeight = image.size.height;
    size_t      bytesPerRow = imageWidth * 4;
    uint32_t* rgbImageBuf = (uint32_t*)malloc(bytesPerRow * imageHeight);
    
    // 创建context
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(rgbImageBuf, imageWidth, imageHeight, 8, bytesPerRow, colorSpace,kCGBitmapByteOrder32Little | kCGImageAlphaNoneSkipLast);
    CGContextDrawImage(context, CGRectMake(0, 0, imageWidth, imageHeight), image.CGImage);
    // 遍历像素
    int pixelNum = imageWidth * imageHeight;
    uint32_t* pCurPtr = rgbImageBuf;
    
    for (int i = 0; i < pixelNum; i++, pCurPtr++)
    {
        //      ABGR
        uint8_t* ptr = (uint8_t*)pCurPtr;
        int B = ptr[1];
        int G = ptr[2];
        int R = ptr[3];
        double Gray = R*0.3+G*0.59+B*0.11;
        if (Gray > filterValue || (Gray == filterValue && filterValue == 0)) {
            ptr[0] = 0;
        }else{
            ptr[1] = 255;
            ptr[2] = 0;
            ptr[3] = 0;
        }
    }
    // 将内存转成image
    CGDataProviderRef dataProvider = CGDataProviderCreateWithData(NULL, rgbImageBuf, bytesPerRow * imageHeight,NULL);
    CGImageRef imageRef = CGImageCreate(imageWidth, imageHeight, 8, 32, bytesPerRow, colorSpace,kCGImageAlphaLast | kCGBitmapByteOrder32Little, dataProvider,NULL, true, kCGRenderingIntentDefault);
    
    CGDataProviderRelease(dataProvider);
    [UIColor colorWithRed:0 / 255.0 green:0 / 255.0 blue:0 / 255.0 alpha:1];
    UIImage* resultUIImage = [UIImage imageWithCGImage:imageRef scale:image.scale orientation:image.imageOrientation];
    // 释放
    CGImageRelease(imageRef);
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
//    self.tempImageView.image = resultUIImage;
    [self drawRedImage:resultUIImage];
}

    
//第二步：遍历所有像素点如果遍历到了一个正蓝色像素，判断这个像素的上下左右是否有透明色，如果有透明色，说明这个像素点是边缘点，将这个点存入数组。然后循环记录的点，将记录的点的色值改为（255,0,0）的正红色。
- (void)drawRedImage:(UIImage *)image{
    // 分配内存
    const int imageWidth = image.size.width;
    const int imageHeight = image.size.height;
    size_t      bytesPerRow = imageWidth * 4;
    uint32_t* rgbImageBuf = (uint32_t*)malloc(bytesPerRow * imageHeight);

    // 创建context
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(rgbImageBuf, imageWidth, imageHeight, 8, bytesPerRow, colorSpace,kCGBitmapByteOrder32Little | kCGImageAlphaNoneSkipLast);
    CGContextDrawImage(context, CGRectMake(0, 0, imageWidth, imageHeight), image.CGImage);
    // 遍历像素
    int pixelNum = imageWidth * imageHeight;
    uint32_t* pCurPtr = rgbImageBuf + imageWidth * 8;
    NSMutableArray *tempArray = [[NSMutableArray alloc]init];
    for (int i = imageWidth * 8; i < pixelNum - imageWidth * 8; i++, pCurPtr++)
    {
        
        //      ABGR
        uint8_t* leftPtr = (uint8_t*)pCurPtr - 8;
        uint8_t* rightPtr = (uint8_t*)pCurPtr + 8;
        uint8_t* topPtr = (uint8_t*)pCurPtr - imageWidth * 8;
        uint8_t* bottomPtr = (uint8_t*)pCurPtr + imageWidth * 8;
        
        
        int leftB = leftPtr[1];
        int leftG = leftPtr[2];
        int leftR = leftPtr[3];
        double leftColor = leftR*1+leftG*1+leftB*1;

        int rightB = rightPtr[1];
        int rightG = rightPtr[2];
        int rightR = rightPtr[3];
        double rightColor = rightR*1+rightG*1+rightB*1;

        int topB = topPtr[1];
        int topG = topPtr[2];
        int topR = topPtr[3];
        double topColor = topR*1+topG*1+topB*1;

        int bottomB = bottomPtr[1];
        int bottomG = bottomPtr[2];
        int bottomR = bottomPtr[3];
        double bottomColor = bottomR*1+bottomG*1+bottomB*1;

  
        
        uint8_t* ptr = (uint8_t*)pCurPtr;
        int B = ptr[1];
        int G = ptr[2];
        int R = ptr[3];
        double Gray = R*1+G*1+B*1;
        if(Gray == 255){
            if(leftColor == 0 || rightColor == 0 || topColor == 0 || bottomColor == 0){
                [tempArray addObject:[NSNumber numberWithInt:i]];
            }

        }else{
            ptr[0] = 0;
        }

    }
    
    
    for (int j = 0; j <tempArray.count; j++) {
        int index = [tempArray[j] intValue];
        uint32_t* pCurPtrs = &rgbImageBuf[index];
        uint8_t* ptrs = (uint8_t*)pCurPtrs;
        ptrs[1] = 0;
        ptrs[2] = 0;
        ptrs[3] = 255;
    }
    

    
    // 将内存转成image
    CGDataProviderRef dataProvider = CGDataProviderCreateWithData(NULL, rgbImageBuf, bytesPerRow * imageHeight,NULL);
    CGImageRef imageRef = CGImageCreate(imageWidth, imageHeight, 8, 32, bytesPerRow, colorSpace,kCGImageAlphaLast | kCGBitmapByteOrder32Little, dataProvider,NULL, true, kCGRenderingIntentDefault);

    CGDataProviderRelease(dataProvider);

    UIImage* resultUIImage = [UIImage imageWithCGImage:imageRef scale:image.scale orientation:image.imageOrientation];
    // 释放
    CGImageRelease(imageRef);
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
//    self.tempImageView.image = resultUIImage;
    [self drawFinalImage:resultUIImage];
}


//第三步：循环图片所有的像素点，将非正红色的点的像素透明，即可得到结果。
- (void)drawFinalImage:(UIImage *)image{
    // 分配内存
    const int imageWidth = image.size.width;
    const int imageHeight = image.size.height;
    size_t      bytesPerRow = imageWidth * 4;
    uint32_t* rgbImageBuf = (uint32_t*)malloc(bytesPerRow * imageHeight);
    
    // 创建context
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(rgbImageBuf, imageWidth, imageHeight, 8, bytesPerRow, colorSpace,kCGBitmapByteOrder32Little | kCGImageAlphaNoneSkipLast);
    CGContextDrawImage(context, CGRectMake(0, 0, imageWidth, imageHeight), image.CGImage);
    // 遍历像素
    int pixelNum = imageWidth * imageHeight;
    uint32_t* pCurPtr = rgbImageBuf;
    
    for (int i = 0; i < pixelNum; i++, pCurPtr++)
    {
        //      ABGR
        uint8_t* ptr = (uint8_t*)pCurPtr;
        int B = ptr[1];
        int G = ptr[2];
        int R = ptr[3];
        
        if ((B == 255 && G == 0 && R == 0) || (B == 0 && G == 0 && R == 0)) {
            ptr[0] = 0;
        }
    }
    // 将内存转成image
    CGDataProviderRef dataProvider = CGDataProviderCreateWithData(NULL, rgbImageBuf, bytesPerRow * imageHeight,NULL);
    CGImageRef imageRef = CGImageCreate(imageWidth, imageHeight, 8, 32, bytesPerRow, colorSpace,kCGImageAlphaLast | kCGBitmapByteOrder32Little, dataProvider,NULL, true, kCGRenderingIntentDefault);
    
    CGDataProviderRelease(dataProvider);
    [UIColor colorWithRed:0 / 255.0 green:0 / 255.0 blue:0 / 255.0 alpha:1];
    UIImage* resultUIImage = [UIImage imageWithCGImage:imageRef scale:image.scale orientation:image.imageOrientation];
    // 释放
    CGImageRelease(imageRef);
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
    self.tempImageView.image = resultUIImage;
}


@end
