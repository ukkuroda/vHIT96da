//
//  opencvWrapper.m
//  vHIT96da
//
//  Created by kuroda tatsuaki on 2018/02/17.
//  Copyright © 2018年 tatsuaki.kuroda. All rights reserved.
//
#import <opencv2/opencv.hpp>
#import <opencv2/videoio.hpp>
#import <opencv2/video.hpp>
#import <opencv2/imgcodecs/ios.h>
#import "opencvWrapper.h"

@implementation opencvWrapper
-(double) matching:(UIImage *)wide_img narrow:(UIImage *)narrow_img x:(int *)x_ret y:(int *)y_ret
{
        cv::Mat wide_mat;
        cv::Mat narrow_mat;
        cv::Mat return_mat;
        UIImageToMat(wide_img, wide_mat);
        UIImageToMat(narrow_img, narrow_mat);

        // テンプレートマッチング
        cv::cvtColor(wide_mat, wide_mat, CV_BGRA2GRAY);
        cv::cvtColor(narrow_mat,narrow_mat,CV_BGR2GRAY);
          try
        {
            cv::matchTemplate(wide_mat, narrow_mat, return_mat, CV_TM_CCOEFF_NORMED);
           // ...
        }
        catch( cv::Exception& e )
        {
          //  const char* err_msg = e.what();
            return -2.0;
        }
        
        // 最大のスコアの場所を探す
        cv::Point max_pt;
        double maxVal;
        cv::minMaxLoc(return_mat, NULL, &maxVal, NULL, &max_pt);
        *x_ret = max_pt.x;
        *y_ret = max_pt.y;
        return maxVal;//恐らく見つかった時は　0.7　より大の模様
}
//-(UIImage *)GrayScale:(UIImage *)image{
/*
 -(UIImage *)GrayScale:(UIImage *)input_img vn:(NSString *)vname x:(int *)x_ret{
    // 変換用Matの宣言
    cv::Mat gray_img;
    cv::VideoCapture cap;
    cap.open(vname.UTF8String);
    cv::Mat frame;
    cap>>frame;
    int v_w=cap.get(CV_CAP_PROP_FRAME_WIDTH); //縦の大きさ
    int v_h=cap.get(CV_CAP_PROP_FRAME_HEIGHT); //横の大きさ
    int max_frame=cap.get(CV_CAP_PROP_FRAME_COUNT); //フレーム数
    int fps=cap.get(CV_CAP_PROP_FPS);
    for (int i=0;i<800;i++){
        cap>>frame;
    }
    // input_imageをcv::Mat型へ変換
    UIImageToMat(input_img, gray_img); //---②
    cv::cvtColor(gray_img, gray_img, CV_BGR2GRAY); //---③
    input_img = MatToUIImage(gray_img); //---④
    _cvImage0=input_img;
    *x_ret=678;
    return MatToUIImage(frame);//input_img; //---⑤
}
-(double) matching_gray:(UIImage *)wide_img narrow:(UIImage *)narrow_img x:(int *)x_ret y:(int *)y_ret
{
    cv::Mat wide_mat;
    cv::Mat narrow_mat;
    cv::Mat return_mat;
    int rows,cols;
    UIImageToMat(wide_img, wide_mat);
    cv::cvtColor(wide_mat,wide_mat,CV_BGR2GRAY);
    UIImageToMat(narrow_img, narrow_mat);
    cv::cvtColor(narrow_mat,narrow_mat,CV_BGR2GRAY);
    cols=wide_mat.cols;//width 1280/se 1/6-3/6
    rows=wide_mat.rows;//height 720/se 1/3-2/3
//    if (rows>cols){
//        rows=rows/2;
//    }else{
//        cols=cols/2;
//    }
    //
    cv::Rect myROI(cols/6,rows/3,cols/3,rows/3);
    cv::Mat subImg=wide_mat(myROI);
    *x_ret = 0;
    *y_ret = 0;
    // テンプレートマッチング
    try
    {
        cv::matchTemplate(subImg, narrow_mat, return_mat, CV_TM_CCOEFF);//_NORMED);
       // ...
    }
    catch( cv::Exception& e )
    {
      //  const char* err_msg = e.what();
       // ...
        return -2.0;
    }
    
    // 最大のスコアの場所を探す
    cv::Point max_pt;
    double maxVal;
    cv::minMaxLoc(return_mat, NULL, &maxVal, NULL, &max_pt);
    if(maxVal>0.7){//恐らく見つかったらここ
        *x_ret = max_pt.x;
        *y_ret = max_pt.y;
//    }else{//瞬きではこちらだろう
//        *x_ret = 0;
//        *y_ret = 0;
    }
      return maxVal;
}*/
/*
cv::Mat oldmat;//うまくいかない。何か方法があるかもしれないが・・・下のコードではだめ
-(void) matching0:(UIImage *)newimg
{
    cv::Mat newmat;
    cv::Rect oldr;
    UIImageToMat(newimg, newmat);
  
    oldr.x = 20;
    oldr.y = 20;
    oldr.width = newmat.cols-40;
    oldr.height = newmat.rows-40;
    oldmat = cv::Mat(newmat,oldr).clone();
}
 
-(void) matching1:(UIImage *)newimg x:(int *)x_ret y:(int *)y_ret
{
    cv::Mat newmat;
    cv::Mat r_mat;
    cv::Rect oldr;
    UIImageToMat(newimg, newmat);
    
//    if ( oldmat.isContinuous()){
         // テンプレートマッチング
        cv::matchTemplate(newmat, oldmat, r_mat, CV_TM_CCOEFF_NORMED);
        // 最大のスコアの場所を探す
        cv::Point max_pt;
        double maxVal;
        cv::minMaxLoc(r_mat, NULL, &maxVal, NULL, &max_pt);
        *x_ret = max_pt.x;
        *y_ret = max_pt.y;
//    }
    oldr.x = 20;
    oldr.y = 20;
    oldr.width = newmat.cols-40;
    oldr.height = newmat.rows-40;
    oldmat = cv::Mat(newmat,oldr).clone();
    *x_ret=0;
    *y_ret=0;
}
*/
/*
- (IplImage *)createIplImageFromSampleBuffer:(CMSampleBufferRef)sampleBuffer {
    IplImage *iplimage = 0;
    if (sampleBuffer) {
        CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
        CVPixelBufferLockBaseAddress(imageBuffer, 0);

        // get information of the image in the buffer
        uint8_t *bufferBaseAddress = (uint8_t *)CVPixelBufferGetBaseAddressOfPlane(imageBuffer, 0);
        size_t bufferWidth = CVPixelBufferGetWidth(imageBuffer);
        size_t bufferHeight = CVPixelBufferGetHeight(imageBuffer);

        // create IplImage
        if (bufferBaseAddress) {
            iplimage = cvCreateImage(cvSize(bufferWidth, bufferHeight), IPL_DEPTH_8U, 4);
            iplimage->imageData = (char*)bufferBaseAddress;
        }

        // release memory
        CVPixelBufferUnlockBaseAddress(imageBuffer, 0);
    }
    else{
    }
       // DLog(@"No sampleBuffer!!");

    return iplimage;
}

// サンプルバッファのデータからCGImageRefを生成する
- (UIImage *)imageFromSampleBuffer:(CMSampleBuffer)sample
{
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sample);
    // ピクセルバッファのベースアドレスをロックする
    CVPixelBufferLockBaseAddress(imageBuffer, 0);
    // Get information of the image
    uint8_t *baseAddress = (uint8_t *)CVPixelBufferGetBaseAddressOfPlane(imageBuffer, 0);
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
    size_t width = CVPixelBufferGetWidth(imageBuffer);
    size_t height = CVPixelBufferGetHeight(imageBuffer);
    // RGBの色空間
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    CGContextRef newContext = CGBitmapContextCreate(baseAddress,
                                                    width,
                                                    height,
                                                    8,
                                                    bytesPerRow,
                                                    colorSpace,
                                                    kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
    CGImageRef cgImage = CGBitmapContextCreateImage(newContext);
    CGContextRelease(newContext);
    CGColorSpaceRelease(colorSpace);
    CVPixelBufferUnlockBaseAddress(imageBuffer, 0);
    UIImage *image = [UIImage imageWithCGImage:cgImage scale:1.0 orientation:UIImageOrientationRight];
    CGImageRelease(cgImage);
    return image;
}
 

-(int)getIn: (NSString *)fn{
    return _cnt+1;
}
-(int) getframes1: (NSString *)fn{
    _cnt=0;
    cv::VideoCapture cap;
    cap.open(fn.UTF8String);
    cv::Mat frame;
//    int v_w=cap.get(CV_CAP_PROP_FRAME_WIDTH); //縦の大きさ
//    int v_h=cap.get(CV_CAP_PROP_FRAME_HEIGHT); //横の大きさ
//    int max_frame=cap.get(CV_CAP_PROP_FRAME_COUNT); //フレーム数
//    int fps=cap.get(CV_CAP_PROP_FPS);
    while(1){
        cap>>frame;
        _cnt ++;
        if(frame.empty()==true)break;
    }
    return _cnt;//v_w;
}

-(int) getframes: (NSString *)fn f:(int *)framen{
    _cnt=0;
    cv::VideoCapture cap;
    cap.open(fn.UTF8String);
 //   double frameTime = 1000.0 * fr/120;//noFrame / frameRate;
    //bool success =

 //   cap.set(CV_CAP_PROP_POS_FRAMES,0);
 //   cap.set(CV_CAP_PROP_POS_MSEC, double(100.0));//frameTime);

//    int v_w=cap.get(CV_CAP_PROP_FRAME_WIDTH); //縦の大きさ
//    int v_h=cap.get(CV_CAP_PROP_FRAME_HEIGHT); //横の大きさ
    int max_frame=cap.get(CV_CAP_PROP_FRAME_COUNT); //フレーム数
    int fps=cap.get(CV_CAP_PROP_FPS);
   // cap.set(CV_CAP_PROP_POS_MSEC , 1.0/fps);
 //   char fname[300];
 //   strcpy(fname,fn.UTF8String);//(fname,fn);
//    //"/var/mobile/Media/DCIM/100APPLE/IMG_0357.MOV");
    cv::Mat frame;
    //frame.rows
    //VideoCaptureProperties(CV_CAP_PROP_POS_AVI_RATIO, 0);//Reset
//
  //      cap.set(CV_CAP_PROP_POS_AVI_RATIO,0);
//    cap.set(CV_CAP_PROP_POS_FRAMES,cap.get(CV_CAP_PROP_POS_FRAMES));
// cap.set(CV_CAP_PROP_POS_FRAMES,2);
// cap.set(CV_CAP_PROP_POS_FRAMES,3);
// cap.set(CV_CAP_PROP_POS_FRAMES,4);
// cap.set(CV_CAP_PROP_POS_FRAMES,1);
// //   cap.set(CV_CAP_PROP_POS_AVI_RATIO,0);
//    cap.set(CV_CAP_PROP_POS_FRAMES,(int)framen);//ちゃんとfrに値が入っている
//    cap.set(CV_CAP_PROP_POS_MSEC , double(500.0));//これでもスタート位置を変更できません？
    while(1){
        cap>>frame;
        _cnt ++;
        if(frame.empty()==true)break;
  //      adaptiveThreshold0=cnt;
//        UIImageToMat(_cvImage0,frame);
//        self.print("openCVcnt:",cnt)
    }
    *framen=_cnt;
    return *framen;//cnt;
}
//eye w:10 h:5    face w:20 h:10    outer w:40 h:20 横縦が入れ替わる
-(void) matching_eye:(UIImage *)new_img old:(UIImage *)old_img x:(int *)x_ret y:(int *)y_ret
{
    
    cv::Mat new_mat;
    cv::Mat old_mat;
    cv::Mat nar_mat;
    cv::Mat r_mat;
    UIImageToMat(new_img, new_mat);
    UIImageToMat(old_img, old_mat);
    cv::Rect oldr;
    oldr.x=5;
    oldr.y=10;
    oldr.width=new_mat.cols-10;
    oldr.height=new_mat.rows-20;
    
    nar_mat = cv::Mat(old_mat,oldr).clone();
    
    // テンプレートマッチング
    cv::matchTemplate(new_mat, nar_mat, r_mat, CV_TM_CCOEFF_NORMED);
    // 最大のスコアの場所を探す
    cv::Point max_pt;
    double maxVal;
    cv::minMaxLoc(r_mat, NULL, &maxVal, NULL, &max_pt);
    *x_ret = max_pt.x;
    *y_ret = max_pt.y;
}
int iii;
-(void) matching_fac:(UIImage *)new_img old:(UIImage *)old_img x:(int *)x_ret y:(int *)y_ret
{
    
    cv::Mat new_mat;
    cv::Mat old_mat;
    cv::Mat nar_mat;
    cv::Mat r_mat;
    UIImageToMat(new_img, new_mat);
    UIImageToMat(old_img, old_mat);
    cv::Rect oldr;
    oldr.x=10;
    oldr.y=20;
    oldr.width=new_mat.cols-20;
    oldr.height=new_mat.rows-40;
    
    nar_mat = cv::Mat(old_mat,oldr).clone();
    int io;
    io=565;
    iii=io;
    // テンプレートマッチング
    cv::matchTemplate(new_mat, nar_mat, r_mat, CV_TM_CCOEFF_NORMED);
    // 最大のスコアの場所を探す
    cv::Point max_pt;
    double maxVal;
    cv::minMaxLoc(r_mat, NULL, &maxVal, NULL, &max_pt);
    *x_ret = max_pt.x;
    *y_ret = max_pt.y;
}
-(void) matching_out:(UIImage *)new_img old:(UIImage *)old_img x:(int *)x_ret y:(int *)y_ret
{
    
    cv::Mat new_mat;
    cv::Mat old_mat;
    cv::Mat nar_mat;
    cv::Mat r_mat;
    UIImageToMat(new_img, new_mat);
    UIImageToMat(old_img, old_mat);
    cv::Rect oldr;
    oldr.x=20;
    oldr.y=40;
    oldr.width=new_mat.cols-40;
    oldr.height=new_mat.rows-80;
    
    nar_mat = cv::Mat(old_mat,oldr).clone();
    int j;
    j=iii;
    // テンプレートマッチング
    cv::matchTemplate(new_mat, nar_mat, r_mat, CV_TM_CCOEFF_NORMED);
    // 最大のスコアの場所を探す
    cv::Point max_pt;
    double maxVal;
    cv::minMaxLoc(r_mat, NULL, &maxVal, NULL, &max_pt);
    *x_ret = max_pt.x;
    *y_ret = max_pt.y;
}*/

/*
-(void) matching2:(UIImage *)wide_img n1:(UIImage *)narrow1_img n2:(UIImage *)narrow2_img x:(int *)eX y:(int *)eY
{
    //return;
    cv::Mat wide_mat;
//    cv::Mat wide_mat2;//念の為
    cv::Mat narrow1_mat;
    cv::Mat narrow2_mat;
    cv::Mat return_mat;
    UIImageToMat(wide_img, wide_mat);
    UIImageToMat(narrow1_img, narrow1_mat);
    UIImageToMat(narrow2_img, narrow2_mat);
    // テンプレートマッチング
    cv::matchTemplate(wide_mat, narrow1_mat, return_mat, CV_TM_CCOEFF_NORMED);
    // 最大のスコアの場所を探す
    cv::Point max_pt;
    double maxVal;
    cv::minMaxLoc(return_mat, NULL, &maxVal, NULL, &max_pt);
 //   *eX = max_pt.x;
    *eY = max_pt.y;
    
    cv::matchTemplate(wide_mat, narrow2_mat, return_mat, CV_TM_CCOEFF_NORMED);
    cv::minMaxLoc(return_mat, NULL, &maxVal, NULL, &max_pt);
    //  *eX = max_pt.x;
    *eX = max_pt.y;
}



-(void) matching3:(UIImage *)UIEyeB n1:(UIImage *)UIEye x1:(int *)eX y1:(int *)eY w2:(UIImage *)UIFaceB n2:(UIImage *)UIFace x2:(int *)fX y2:(int *)fY w3:(UIImage *)UIOuterB n3:(UIImage *)UIOuter x3:(int *)oX y3:(int *)oY
{
    //return;
    cv::Mat wide_mat;
    cv::Mat narrow_mat;
    cv::Mat return_mat;
    UIImageToMat(UIEyeB, wide_mat);
    UIImageToMat(UIEye, narrow_mat);
    // テンプレートマッチング
    cv::matchTemplate(wide_mat, narrow_mat, return_mat, CV_TM_CCOEFF_NORMED);
    // 最大のスコアの場所を探す
    cv::Point max_pt;
    double maxVal;
    cv::minMaxLoc(return_mat, NULL, &maxVal, NULL, &max_pt);
    *eX = max_pt.x;
    *eY = max_pt.y;
    
    UIImageToMat(UIFaceB, wide_mat);
    UIImageToMat(UIFace, narrow_mat);
    // テンプレートマッチング
    cv::matchTemplate(wide_mat, narrow_mat, return_mat, CV_TM_CCOEFF_NORMED);
    // 最大のスコアの場所を探す
    //    cv::Point max_pt;
    //    double maxVal;
    cv::minMaxLoc(return_mat, NULL, &maxVal, NULL, &max_pt);
    *fX = max_pt.x;
    *fY = max_pt.y;
    
    UIImageToMat(UIOuterB, wide_mat);
    UIImageToMat(UIOuter, narrow_mat);
    // テンプレートマッチング
    cv::matchTemplate(wide_mat, narrow_mat, return_mat, CV_TM_CCOEFF_NORMED);
    // 最大のスコアの場所を探す
    //    cv::Point max_pt;
    //    double maxVal;
    cv::minMaxLoc(return_mat, NULL, &maxVal, NULL, &max_pt);
    *oX = max_pt.x;
    *oY = max_pt.y;
}

cv::Mat eyeold_mat;
cv::Mat facold_mat;
cv::Mat outold_mat;
-(void) matching3:(UIImage *)e_img wideF:(UIImage *)f_img wideO:(UIImage *)o_img xe:(int *)xe_ret ye:(int *)ye_ret xf:(int *)xf_ret yf:(int *)yf_ret xo:(int *)xo_ret yo:(int *)yo_ret
{
    cv::Mat eye_mat;
    cv::Mat fac_mat;
    cv::Mat out_mat;
    cv::Mat r_mat;
    UIImageToMat(e_img, eye_mat);
    UIImageToMat(f_img, fac_mat);
    UIImageToMat(o_img, out_mat);

    // テンプレートマッチング
    if ( *xe_ret != 999 ){//第一フレーム時は飛ばす
        cv::matchTemplate(eye_mat, eyeold_mat, r_mat, CV_TM_CCOEFF_NORMED);
        // 最大のスコアの場所を探す
        cv::Point max_pt;
        double maxVal;
        cv::minMaxLoc(r_mat, NULL, &maxVal, NULL, &max_pt);
        *xe_ret = max_pt.x;
        *ye_ret = max_pt.y;
    }
    cv::Rect eyer,facr,outr;
    eyer.x=5;
    eyer.y=5;
    eyer.width=eyeold_mat.rows-10;
    eyer.height=eyeold_mat.cols-10;
    eyeold_mat = cv::Mat(eye_mat,eyer).clone();
    facr.x=5;
    facr.y=5;
    facr.width=facold_mat.rows-10;
    facr.height=facold_mat.cols-10;
    facold_mat = cv::Mat(fac_mat,facr).clone();
    outr.x=5;
    outr.y=5;
    outr.width=outold_mat.rows-10;
    outr.height=outold_mat.cols-10;
    outold_mat = cv::Mat(out_mat,outr).clone();
    //上三行でcropしておく (narrowにしておく)
}

-(void) test:(int *)x;
{
    *x = -16777216;
}
*/
@end
