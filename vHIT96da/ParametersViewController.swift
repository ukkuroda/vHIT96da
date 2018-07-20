//
//  ParametersViewController.swift
//  vHIT96da
//
//  Created by kuroda tatsuaki on 2018/02/11.
//  Copyright © 2018年 tatsuaki.kuroda. All rights reserved.
//

import UIKit

class ParametersViewController: UIViewController, UITextFieldDelegate {
    
 //   var flatWidth:Int = 0
    var flatsumLimit:Int = 0
    var waveWidth:Int = 0
    var wavePeak:Int = 0
    var updownPgap:Int = 0
  //  var peakWidth:Int = 0
    var eyeBorder:Int = 0
    var faceBorder:Int = 0
    var outerBorder:Int = 0
    var rectEye = CGRect(x:0,y:0,width:0,height:0)
    var rectFace = CGRect(x:0,y:0,width:0,height:0)
    var rectOuter = CGRect(x:0,y:0,width:0,height:0)
    var eyeRatio:Int = 0
    var outerRatio:Int = 0
    
 //   @IBOutlet weak var ettButton: UIButton!
  //  @IBOutlet weak var vhitButton: UIButton!
    @IBOutlet weak var flat1: UILabel!
    @IBOutlet weak var wave2: UILabel!
    @IBOutlet weak var wave3: UILabel!
    @IBOutlet weak var slope4: UILabel!
    @IBOutlet weak var faceb: UILabel!
    @IBOutlet weak var outerb: UILabel!
    @IBOutlet weak var eyen: UILabel!
    @IBOutlet weak var outern: UILabel!
    @IBOutlet weak var vhitpng: UIImageView!
    @IBOutlet weak var keyDown: UIButton!
    @IBOutlet weak var labelEye: UILabel!
    @IBOutlet weak var labelFace: UILabel!
    @IBOutlet weak var labelOuter: UILabel!
 //   @IBOutlet weak var flatWidthinput: UITextField!
    @IBOutlet weak var flatSuminput: UITextField!
    @IBOutlet weak var waveWidthinput: UITextField!
    @IBOutlet weak var wavePeakinput: UITextField!
    @IBOutlet weak var updownPointinput: UITextField!
//    @IBOutlet weak var peakWidthinput: UITextField!
    
    @IBOutlet weak var eyeBinput: UITextField!
    @IBOutlet weak var faceBinput: UITextField!
    @IBOutlet weak var outerBinput: UITextField!
    
    @IBOutlet weak var eyeRatioinput: UITextField!
    @IBOutlet weak var outerRatioinput: UITextField!
    
    // became first responder
    func textFieldDidBeginEditing(_ textField: UITextField) {
        keyDown.isHidden = false
    }
//    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
//   //     print("\(String(describing: flatWidthinput.text))")
//     //   print("kkkkkkk********")
//        return true
//    }
    @IBAction func tapBack(_ sender: Any) {
        numpadOff(0)
    }
    func showParams(show:Bool){
        if show == true{
            vhitpng.isHidden=false
            flat1.isHidden=false
            wave2.isHidden=false
            wave3.isHidden=false
            slope4.isHidden=false
 //           eyen.isHidden=false
            outern.text="outer n/100"
 //           outern.isHidden=false
 //           faceb.isHidden=false
            outerb.isHidden=false
 //           labelFace.isHidden=false
            labelOuter.isHidden=false
            flatSuminput.isHidden=false
            waveWidthinput.isHidden=false
            wavePeakinput.isHidden=false
            updownPointinput.isHidden=false
 //           faceBinput.isHidden=false
            outerBinput.isHidden=false
//            eyeRatioinput.isHidden=false
//            outerRatioinput.isHidden=false
            
        }else{
            vhitpng.isHidden=true
            flat1.isHidden=true
            wave2.isHidden=true
            wave3.isHidden=true
            slope4.isHidden=true
 //           eyen.isHidden=true
            outern.text="speed n/100"//isHidden=true
 //           faceb.isHidden=true
            outerb.isHidden=true
 //           labelFace.isHidden=true
            labelOuter.isHidden=true
            flatSuminput.isHidden=true
            waveWidthinput.isHidden=true
            wavePeakinput.isHidden=true
            updownPointinput.isHidden=true
  //          faceBinput.isHidden=true
            outerBinput.isHidden=true
  //          eyeRatioinput.isHidden=true
  //          outerRatioinput.isHidden=true
     }
    }
    @IBAction func setVog(_ sender: Any) {
        faceBorder = 0
        outerBorder = 0
        dispParam()
        showParams(show: false)
    }
    @IBAction func setVOGb(_ sender: Any) {
        faceBorder = 8
        outerBorder = 0
        dispParam()
        showParams(show: false)
     }
    @IBAction func setVhit(_ sender: Any) {
        faceBorder = 8
        outerBorder = 30
        dispParam()
        showParams(show: true)
    }
    @IBAction func numpadOff(_ sender: Any) {
 //       flatWidthinput.endEditing(true)
        flatSuminput.endEditing(true)
        waveWidthinput.endEditing(true)
        wavePeakinput.endEditing(true)
        updownPointinput.endEditing(true)
 //       peakWidthinput.endEditing(true)
        eyeBinput.endEditing(true)
        faceBinput.endEditing(true)
        outerBinput.endEditing(true)
        eyeRatioinput.endEditing(true)
        outerRatioinput.endEditing(true)
        keyDown.isHidden = true
    }
//    @IBAction func flatwidthDown(_ sender: Any) {
    //   //    keyDown.isHidden = false
//  //      setKeydown()
//   }
//    @IBAction func flatsumDown(_ sender: Any) {
//     //  keyDown.isHidden = false
//    ///    setKeydown()
//  }
//    @IBAction func wavewidthDown(_ sender: Any) {
//     //  keyDown.isHidden = false
//    //    setKeydown()
//    }
//    @IBAction func wavepeakDown(_ sender: Any) {
//   //      keyDown.isHidden = false
//      //  setKeydown()
//    }
//
////    @IBAction func updownUp(_ sender: Any) {
//  //      keyDown.isHidden = false
//    //}
//    @IBAction func updownDown(_ sender: Any) {
//  //      print("***************:")
//   //     keyDown.isHidden = false
//
//   //     sleep(UInt32(0.1))
//    //    keyDown.isHidden = false
//    //    setKeydown()
//   }
//
//    @IBAction func peakwidthDown(_ sender: Any) {
//   //    keyDown.isHidden = false
//        //setKeydown()
//  }
//    @IBAction func eyeBorderDown(_ sender: Any) {
//    //    keyDown.isHidden = false
//        //setKeydown()
//    }
//
//    @IBAction func faceBorderDown(_ sender: Any) {
//   // keyDown.isHidden = false
//        //setKeydown()
//    }
//
//    @IBAction func outerBorderDown(_ sender: Any) {
//      //   keyDown.isHidden = false
//      //  setKeydown()
//    }
//
    
    @IBAction func setDefault(_ sender: Any) {
        //上手く働かない
        //       flatWidth = 28
        flatsumLimit = 80
        waveWidth = 40
        wavePeak = 15
        updownPgap = 6
        //       peakWidth = 23
        eyeBorder = 10
        faceBorder = 8
        outerBorder = 30
        eyeRatio = 100
        outerRatio = 100
        //        let ratioW = self.view.bounds.width/375.0//6s
        //        let ratioH = self.view.bounds.height/667.0//6s
        //        self.rectEye = CGRect(x:97*ratioW,y:143*ratioH,width:209*ratioW,height:10*ratioH)
        //        self.rectFace = CGRect(x:167*ratioW,y:328*ratioH,width:77*ratioW,height:27*ratioH)
        //        self.rectOuter = CGRect(x:140*ratioW,y:510*ratioH,width:110*ratioW,height:10*ratioH)
        dispParam()
        showParams(show: true)
        
    }
    func Field2value(field:UITextField) -> Int {
        if field.text?.count != 0 {
            return Int(field.text!)!
        }else{
            return 0
        }
    }
//    @IBAction func flatWidthButton(_ sender: Any) {
//   //     print("*******flatwidthbutton button")
//        flatWidth = Field2value(field: flatWidthinput)
//    }
    @IBAction func flatSumButton(_ sender: Any) {
        flatsumLimit = Field2value(field:flatSuminput)
    }
    @IBAction func waveWidthButton(_ sender: Any) {
        waveWidth = Field2value(field: waveWidthinput)
    }
    @IBAction func wavePeakButton(_ sender: Any) {
        wavePeak = Field2value(field: wavePeakinput)
    }
    @IBAction func updownPointButton(_ sender: Any) {
        updownPgap = Field2value(field: updownPointinput)
    }
//    @IBAction func peakWidthButton(_ sender: Any) {
//        peakWidth = Field2value(field: peakWidthinput)
//    }
    
    @IBAction func eyeBorderButton(_ sender: Any) {
        eyeBorder = Field2value(field: eyeBinput)
    }
    @IBAction func faceBorderButton(_ sender: Any) {
        faceBorder = Field2value(field: faceBinput)
    }
    @IBAction func outerBorderButton(_ sender: Any) {
        outerBorder = Field2value(field: outerBinput)
    }
    @IBAction func eyeRatioButton(_ sender: Any) {
        eyeRatio = Field2value(field: eyeRatioinput)
    }
    @IBAction func outerRationButton(_ sender: Any) {
        outerRatio = Field2value(field: outerRatioinput)
    }
    
    
    func dispParam(){
        var x = 0
        var y = 0
        var width = 0
        var height = 0
 //       self.flatWidthinput.text = "\(flatWidth)"
        self.flatSuminput.text = "\(flatsumLimit)"
        self.waveWidthinput.text = "\(waveWidth)"
        self.wavePeakinput.text = "\(wavePeak)"
        self.updownPointinput.text = "\(updownPgap)"
 //       self.peakWidthinput.text = "\(peakWidth)"
        self.eyeBinput.text = "\(eyeBorder)"
        self.faceBinput.text = "\(faceBorder)"
        self.outerBinput.text = "\(outerBorder)"
        self.eyeRatioinput.text = "\(eyeRatio)"
        self.outerRatioinput.text = "\(outerRatio)"
        x = Int(rectEye.origin.x)
        y = Int(rectEye.origin.y)
        width = Int(rectEye.size.width)
        height = Int(rectEye.size.height)
        self.labelEye.text = "\(String(format:"%04d,%04d,%04d,%04d eye",x,y,width,height))"
        x = Int(rectFace.origin.x)
        y = Int(rectFace.origin.y)
        width = Int(rectFace.size.width)
        height = Int(rectFace.size.height)
        self.labelFace.text = "\(String(format:"%04d,%04d,%04d,%04d face",x,y,width,height))"
        x = Int(rectOuter.origin.x)
        y = Int(rectOuter.origin.y)
        width = Int(rectOuter.size.width)
        height = Int(rectOuter.size.height)
        self.labelOuter.text = "\(String(format:"%04d,%04d,%04d,%04d outer",x,y,width,height))"
        
    }
    override func viewDidLoad() {
        super.viewDidLoad()
 //       flatWidthinput.delegate = self
        //flatWidthinput.delegate = self//これはなんだ？コメントアウトして大丈夫かな？
        flatSuminput.delegate = self
        waveWidthinput.delegate = self
        wavePeakinput.delegate = self
        updownPointinput.delegate = self
 //       peakWidthinput.delegate = self
        eyeBinput.delegate = self
        faceBinput.delegate = self
        outerBinput.delegate = self
        eyeRatioinput.delegate = self
        outerRatioinput.delegate = self
    //    setKeydown()
      //入力を数字入力キーボードとする
 //       self.flatWidthinput.keyboardType = UIKeyboardType.numberPad
        self.flatSuminput.keyboardType = UIKeyboardType.numberPad
        self.waveWidthinput.keyboardType = UIKeyboardType.numberPad
        self.wavePeakinput.keyboardType = UIKeyboardType.numberPad
        self.updownPointinput.keyboardType = UIKeyboardType.numberPad
  //      self.peakWidthinput.keyboardType = UIKeyboardType.numberPad
        self.eyeBinput.keyboardType = UIKeyboardType.numberPad
        self.faceBinput.keyboardType = UIKeyboardType.numberPad
        self.outerBinput.keyboardType = UIKeyboardType.numberPad
        self.eyeRatioinput.keyboardType = UIKeyboardType.numberPad
        self.outerRatioinput.keyboardType = UIKeyboardType.numberPad
        dispParam()
        setKeydown()
        
        keyDown.isHidden = true
    }
    func setKeydown(){
        //se:640(568) 6s:750(667) 7plus:1080(736) x:1125(812)
        self.keyDown.frame.origin.x = view.bounds.width*2/3
        //print(view.bounds.height)
        if view.bounds.height>810 {//X
            self.keyDown.frame.origin.y = view.bounds.height - 255 - 75
        }else if view.bounds.height>730 {
            self.keyDown.frame.origin.y = view.bounds.height - 255 - 10
        }else{
            self.keyDown.frame.origin.y = view.bounds.height - 255
        }
        self.keyDown.frame.size.width = view.bounds.width/3
        self.keyDown.frame.size.height = 40
    //    keyDown.isHidden = false//ここにおくと良いみたい
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

