//
//  opencvWrapper.h
//  vHIT96da
//
//  Created by kuroda tatsuaki on 2018/02/17.
//  Copyright © 2018年 tatsuaki.kuroda. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
@interface opencvWrapper : NSObject
//(返り値の型 *)関数名:(引数の型 *)引数名;CMSampleBuffer
//- (IplImage *)createIplImageFromSampleBuffer:(CMSampleBufferRef)sampleBuffer;
//- (UIImage *)imageFromSampleBuffer:(CMSampleBufferRef)sampleBuffer;
//-(void) matching0:(UIImage *)newimg;
//-(void) matching1:(UIImage *)newimg x:(int *)x_ret y:(int *)y_ret;
-(void)getframes: (NSString *)fn f:(int)fr x:(int *)x_ret;
-(void)getframes: (NSString *)fn x:(int *)x_ret;
-(void) matching2:(UIImage *)wide_img n1:(UIImage *)narrow1_img n2:(UIImage *)narrow2_img x:(int *)eX y:(int *)eY;
-(void) matching_eye:(UIImage *)new_img old:(UIImage *)old_img x:(int *)x_ret y:(int *)y_ret;
-(void) matching_fac:(UIImage *)new_img old:(UIImage *)old_img x:(int *)x_ret y:(int *)y_ret;
-(void) matching_out:(UIImage *)new_img old:(UIImage *)old_img x:(int *)x_ret y:(int *)y_ret;
-(double) matching:(UIImage *)wide_img narrow:(UIImage *)narrow_img x:(int *)x_ret y:(int *)y_ret;
-(void) matching3:(UIImage *)UIEyeB n1:(UIImage *)UIEye x1:(int *)eX y1:(int *)eY w2:(UIImage *)UIFaceB n2:(UIImage *)UIFace x2:(int *)fX y2:(int *)fY w3:(UIImage *)UIOuterB n3:(UIImage *)UIOuter x3:(int *)oX y3:(int *)oY;
@end
