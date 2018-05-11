//
//  opencvWrapper.m
//  vHIT96da
//
//  Created by kuroda tatsuaki on 2018/02/17.
//  Copyright © 2018年 tatsuaki.kuroda. All rights reserved.
//
#import <opencv2/opencv.hpp>
#import <opencv2/imgcodecs/ios.h>
#import "opencvWrapper.h"

@implementation opencvWrapper
/*
-(UIImage *)toGray:(UIImage *)input_img {
    // 変換用Matの宣言
    cv::Mat gray_img;
    // input_imageをcv::Mat型へ変換
    UIImageToMat(input_img, gray_img); //---②
    
    cv::cvtColor(gray_img, gray_img, CV_BGR2GRAY); //---③
    
    input_img = MatToUIImage(gray_img); //---④
    
    return input_img; //---⑤
}

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
    
    // テンプレートマッチング
    cv::matchTemplate(new_mat, nar_mat, r_mat, CV_TM_CCOEFF_NORMED);
    // 最大のスコアの場所を探す
    cv::Point max_pt;
    double maxVal;
    cv::minMaxLoc(r_mat, NULL, &maxVal, NULL, &max_pt);
    *x_ret = max_pt.x;
    *y_ret = max_pt.y;
}
-(void) matching:(UIImage *)wide_img narrow:(UIImage *)narrow_img x:(int *)x_ret y:(int *)y_ret
{
    cv::Mat wide_mat;
    cv::Mat narrow_mat;
    cv::Mat return_mat;
    UIImageToMat(wide_img, wide_mat);
    UIImageToMat(narrow_img, narrow_mat);
    // テンプレートマッチング
    cv::matchTemplate(wide_mat, narrow_mat, return_mat, CV_TM_CCOEFF_NORMED);
    // 最大のスコアの場所を探す
    cv::Point max_pt;
    double maxVal;
    cv::minMaxLoc(return_mat, NULL, &maxVal, NULL, &max_pt);
    *x_ret = max_pt.x;
    *y_ret = max_pt.y;
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
    *eX = max_pt.x*100.0;
    *eY = max_pt.y*100.0;
    
    UIImageToMat(UIFaceB, wide_mat);
    UIImageToMat(UIFace, narrow_mat);
    // テンプレートマッチング
    cv::matchTemplate(wide_mat, narrow_mat, return_mat, CV_TM_CCOEFF_NORMED);
    // 最大のスコアの場所を探す
    //    cv::Point max_pt;
    //    double maxVal;
    cv::minMaxLoc(return_mat, NULL, &maxVal, NULL, &max_pt);
    *fX = max_pt.x*100.0;
    *fY = max_pt.y*100.0;
    
    UIImageToMat(UIOuterB, wide_mat);
    UIImageToMat(UIOuter, narrow_mat);
    // テンプレートマッチング
    cv::matchTemplate(wide_mat, narrow_mat, return_mat, CV_TM_CCOEFF_NORMED);
    // 最大のスコアの場所を探す
    //    cv::Point max_pt;
    //    double maxVal;
    cv::minMaxLoc(return_mat, NULL, &maxVal, NULL, &max_pt);
    *oX = max_pt.x*100.0;
    *oY = max_pt.y*100.0;
}
/*
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
