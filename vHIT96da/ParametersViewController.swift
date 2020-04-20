//
//  ParametersViewController.swift
//  vHIT96da
//
//  Created by kuroda tatsuaki on 2018/02/11.
//  Copyright © 2018年 tatsuaki.kuroda. All rights reserved.
//

import UIKit

class ParametersViewController: UIViewController, UITextFieldDelegate {
 
    @IBOutlet weak var markText: UILabel!
    @IBOutlet weak var markSwitch: UISwitch!
    var faceF:Int?
    var widthRange:Int = 0
    var waveWidth:Int = 0
    var eyeBorder:Int = 0
    var gyroDelta:Int = 0
    var ratio1:Int = 0
    var ratio2:Int = 0
    var vhit_vog:Bool?
    @IBOutlet weak var gyroText: UILabel!
    @IBOutlet weak var paraText1: UILabel!
    @IBOutlet weak var paraText2: UILabel!
    @IBOutlet weak var paraText3: UILabel!
    @IBOutlet weak var paraText4: UILabel!
    @IBOutlet weak var paraText5: UILabel!
    @IBOutlet weak var paraText6: UILabel!
    @IBOutlet weak var vhitpng: UIImageView!
    @IBOutlet weak var keyDown: UIButton!
    @IBOutlet weak var widthRangeinput: UITextField!
    @IBOutlet weak var waveWidthinput: UITextField!
    @IBOutlet weak var eyeBinput: UITextField!
    @IBOutlet weak var gyroDinput: UITextField!
    @IBOutlet weak var ratio1input: UITextField!
    @IBOutlet weak var ratio2input: UITextField!
    
    @IBAction func markButton(_ sender: UISwitch) {
        if sender.isOn{
            faceF=1
        }else{
            faceF=0
        }
    }
    // became first responder
    func textFieldDidBeginEditing(_ textField: UITextField) {
        keyDown.isHidden = false
    }

    @IBAction func tapBack(_ sender: Any) {
        numpadOff(0)
    }

    @IBAction func numpadOff(_ sender: Any) {
 
        widthRangeinput.endEditing(true)
        waveWidthinput.endEditing(true)
        eyeBinput.endEditing(true)
        gyroDinput.endEditing(true)
        ratio1input.endEditing(true)
        ratio2input.endEditing(true)
        keyDown.isHidden = true
    }

    @IBAction func setDefault(_ sender: Any) {
        widthRange = 30
        waveWidth = 80
        eyeBorder=10
        faceF=0
        markSwitch.isOn=false
        gyroDelta = 50
        ratio1 = 100
        ratio2 = 100
        dispParam()
    }
    func Field2value(field:UITextField) -> Int {
        if field.text?.count != 0 {
            return Int(field.text!)!
        }else{
            return 0
        }
    }


    @IBAction func widthRangeButton(_ sender: Any) {
        widthRange = Field2value(field:widthRangeinput)
    }
    @IBAction func waveWidthButton(_ sender: Any) {
        waveWidth = Field2value(field: waveWidthinput)
    }
    
    @IBAction func eyeBorderButton(_ sender: Any) {
        eyeBorder = Field2value(field: eyeBinput)
    }
    
    @IBAction func gyroDeltaButton(_  sender: Any) {
        gyroDelta = Field2value(field: gyroDinput)
    }
//    @IBAction func outerBorderButton(_ sender: Any) {
////        outerBorder = Field2value(field: outerBinput)
//    }

    @IBAction func ratio1Button(_ sender: Any) {
        ratio1 = Field2value(field: ratio1input)
    }
    
    @IBAction func ratio2Button(_ sender: Any) {
        ratio2 = Field2value(field: ratio2input)
    }
    
    func dispParam(){
        self.widthRangeinput.text = "\(widthRange)"
        self.waveWidthinput.text = "\(waveWidth)"
        self.eyeBinput.text = "\(eyeBorder)"
        self.gyroDinput.text = "\(gyroDelta)"
        self.ratio1input.text = "\(ratio1)"
        self.ratio2input.text = "\(ratio2)"
        
    }
    func setTexts(){
        let ww:CGFloat=view.bounds.width
        let wh:CGFloat=view.bounds.height
        let bw:CGFloat=45
        let bh:CGFloat=25
        let bh1=bh+3
        let tw:CGFloat=ww-bw-10
        let vhit_h:CGFloat=ww/4
        let by:CGFloat=20//vhit_h+20
        let x1:CGFloat=3
        let x2=x1+bw+5
        if vhit_vog==false{
            vhitpng.isHidden=true
            paraText1.isHidden=true
            //paraText2.isHidden=true
            paraText5.isHidden=true
            paraText6.isHidden=true
            waveWidthinput.isHidden = true
            widthRangeinput.isHidden = true
            eyeBinput.isHidden = true
            gyroDinput.isHidden = true
            ratio1input.isHidden = false
            ratio2input.isHidden = false
            markText.isHidden = true
            markSwitch.isHidden = true
            gyroText.isHidden = true
            paraText2.text = "VOG 波形表示高さの調整"
            paraText3.text="眼球位置（上段）表示の高さ ％"
            paraText4.text="眼球速度（下段）表示の高さ ％"
            paraText2.frame   = CGRect(x:x2,   y: bh1*1.5 ,width: tw, height: bh)
            paraText3.frame   = CGRect(x:x2,   y: bh1*3 ,width: tw, height: bh)
            paraText4.frame   = CGRect(x:x2,   y: bh1*4 ,width: tw, height: bh)
            ratio1input.frame = CGRect(x:x1,y: bh1*3 ,width: bw, height: bh)
            ratio2input.frame = CGRect(x:x1,y: bh1*4 ,width: bw, height: bh)
        }else{
            paraText1.frame = CGRect(x:x2,   y: by ,width: tw, height: bh)
            paraText2.frame = CGRect(x:x2,   y: by+bh1 ,width: tw, height: bh)
            paraText3.frame = CGRect(x:x2,   y: by+bh1*2 ,width: tw, height: bh)
            paraText4.frame = CGRect(x:x2,   y: by+bh1*3 ,width: tw, height: bh)
            paraText5.frame = CGRect(x:x2,   y: by+bh1*4 ,width: tw, height: bh)
            paraText6.frame = CGRect(x:x2,   y: by+bh1*5 ,width: tw, height: bh)
            markText.frame  = CGRect(x:x2+2,y:by+bh1*6+2,width:tw,height:bh)
            vhitpng.frame   = CGRect(x:0, y: by+bh1*7+10 ,width: ww, height: ww*9/32)
            gyroText.frame = CGRect(x:5,y:by+bh1*7+10+ww/5,width:ww-10,height:bh*7)//wh-by-bh1*7-10-ww/5-70)
            waveWidthinput.frame = CGRect(x:x1,y: by,width: bw, height: bh)
            widthRangeinput.frame = CGRect(x:x1,y:by+bh1 ,width: bw, height: bh)
            ratio1input.frame = CGRect(x:x1,y: by+bh1*2 ,width: bw, height: bh)
            ratio2input.frame = CGRect(x:x1,y: by+bh1*3 ,width: bw, height: bh)
            gyroDinput.frame = CGRect(x:x1,y: by+bh1*4 ,width: bw, height: bh)
            eyeBinput.frame = CGRect(x:x1,y: by+bh1*5 ,width: bw, height: bh)
            markSwitch.frame = CGRect(x:x1,y:by+bh1*6,width:1,height:1)
            if faceF==1{
                markSwitch.isOn=true
            }else{
                markSwitch.isOn=false
            }
        }
        
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        widthRangeinput.delegate = self
        waveWidthinput.delegate = self
        eyeBinput.delegate = self
        gyroDinput.delegate = self
        ratio1input.delegate = self
        ratio2input.delegate = self

        self.widthRangeinput.keyboardType = UIKeyboardType.numberPad
        self.waveWidthinput.keyboardType = UIKeyboardType.numberPad
        self.eyeBinput.keyboardType = UIKeyboardType.numberPad
        self.gyroDinput.keyboardType = UIKeyboardType.numberPad
        self.ratio1input.keyboardType = UIKeyboardType.numberPad
        self.ratio2input.keyboardType = UIKeyboardType.numberPad
        setTexts()
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

