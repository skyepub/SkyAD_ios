// SkyEpub for iOS Advanced Demo IV  - Swift language
//
//  SettingViewController.swift
//  SkyAD
//
//  Created by 하늘나무 on 2020/10/09.
//  Copyright © 2020 Dev. All rights reserved.
//

import UIKit

// SettingViewController is for management Setting of SkyEpub Advanced demo IV.
// setting information is saved in sqlite Setting table which is defined in SkyData.swift.
class SettingViewController: UIViewController {
    @IBOutlet weak var scroillView: UIScrollView!
    @IBOutlet weak var homeButton: UIButton!
    @IBOutlet var coreView: UIView!
    
    
    @IBOutlet weak var doublePagedSwitch: UISwitch!
    @IBOutlet weak var lockRotationSwitch: UISwitch!
    @IBOutlet weak var globalPaginationSwitch: UISwitch!
    
    @IBOutlet weak var theme0Button: UIButton!
    @IBOutlet weak var theme1Button: UIButton!
    @IBOutlet weak var theme2Button: UIButton!
    @IBOutlet weak var theme3Button: UIButton!
    
    @IBOutlet weak var mediaOverlaySwitch: UISwitch!
    @IBOutlet weak var ttsSwitch: UISwitch!
    
    @IBOutlet weak var autoPlaySwitch: UISwitch!
    @IBOutlet weak var autoLoadSwitch: UISwitch!
    @IBOutlet weak var highlightTextSwitch: UISwitch!
    

    @IBOutlet weak var noneEffectCheckmark: UIImageView!
    @IBOutlet weak var slideEffectCheckmark: UIImageView!
    @IBOutlet weak var curlEffectCheckmark: UIImageView!
    
    
    var ad:AppDelegate!
    var sd:SkyData!
    var setting:Setting!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        ad = UIApplication.shared.delegate as? AppDelegate
        sd = ad.data
        NotificationCenter.default.addObserver(self, selector: #selector(didRotate), name: UIDevice.orientationDidChangeNotification, object: nil)
        self.loadSetting()
        self.makeUI()
        // Do any additional setup after loading the view.
    }
    
    func recalcFrames() {
        let topOffset:CGFloat = 80
        coreView.bounds.size.width = self.view.bounds.size.width
        
        self.scroillView.frame = CGRect(x:0,y:view.safeAreaInsets.top+topOffset,width:self.view.bounds.size.width,height: self.view.bounds.size.height)
        self.coreView.bounds.size.width = self.view.bounds.size.width
        
        self.scroillView.contentSize = CGSize(width: coreView.frame.size.width, height: coreView.frame.size.height+topOffset)
        
        coreView.frame.origin = CGPoint(x:0,y:0)
    }
    
    func makeUI() {
        self.scroillView.addSubview(coreView)
        recalcFrames()
    }
    
    @objc func didRotated() {
        recalcFrames()
    }
    
    @IBAction func homePressed(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    override func dismiss(animated flag: Bool,
                             completion: (() -> Void)?) {
        super.dismiss(animated: flag, completion: completion)
        self.saveSetting()
        NSLog("Dismissed");
    }
    
    func focusSelectedTheme() {
        theme0Button.layer.borderColor = UIColor.gray.cgColor
        theme1Button.layer.borderColor = UIColor.gray.cgColor
        theme2Button.layer.borderColor = UIColor.gray.cgColor
        theme3Button.layer.borderColor = UIColor.gray.cgColor
        
        theme0Button.layer.borderWidth = 1
        theme1Button.layer.borderWidth = 1
        theme2Button.layer.borderWidth = 1
        theme3Button.layer.borderWidth = 1
        
        switch setting.theme {
        case 0: theme0Button.layer.borderWidth = 3
        case 1: theme1Button.layer.borderWidth = 3
        case 2: theme2Button.layer.borderWidth = 3
        case 3: theme3Button.layer.borderWidth = 3
        default:
            theme0Button.layer.borderWidth = 3
        }
    }
    @IBAction func theme0Pressed(_ sender: Any) {
        setting.theme = 0
        focusSelectedTheme()
    }

    @IBAction func theme1Pressed(_ sender: Any) {
        setting.theme = 1
        focusSelectedTheme()
    }
    
    @IBAction func theme2Pressed(_ sender: Any) {
        setting.theme = 2
        focusSelectedTheme()
    }
    
    @IBAction func theme3Pressed(_ sender: Any) {
        setting.theme = 3
        focusSelectedTheme()
    }
    
    func focusSelectedEffect() {
        noneEffectCheckmark.isHidden = true
        slideEffectCheckmark.isHidden = true
        curlEffectCheckmark.isHidden = true
        switch setting.transitionType {
        case 0:
            noneEffectCheckmark.isHidden = false
        case 1:
            slideEffectCheckmark.isHidden = false
        case 2:
            curlEffectCheckmark.isHidden = false
        default:
            noneEffectCheckmark.isHidden = false
        }
    }
    
    @IBAction func noneEffectPressed(_ sender: Any) {
        setting.transitionType = 0
        self.focusSelectedEffect()
    }
    
    @IBAction func slideEffectPressed(_ sender: Any) {
        setting.transitionType = 1
        self.focusSelectedEffect()
    }
    
    @IBAction func curlEffectPressed(_ sender: Any) {
        setting.transitionType = 2
        self.focusSelectedEffect()
    }
    
    func loadSetting() {
        self.setting = sd.fetchSetting()
        doublePagedSwitch.isOn = setting.doublePaged
        lockRotationSwitch.isOn = setting.lockRotation
        globalPaginationSwitch.isOn = setting.globalPagination
        
        self.focusSelectedTheme()
        self.focusSelectedEffect()

        mediaOverlaySwitch.isOn = setting.mediaOverlay
        ttsSwitch.isOn = setting.tts
        
        autoPlaySwitch.isOn = setting.autoStartPlaying
        autoLoadSwitch.isOn = setting.autoLoadNewChapter
        highlightTextSwitch.isOn = setting.highlightTextToVoice
    }
    
    func saveSetting() {
        setting.doublePaged = doublePagedSwitch.isOn
        setting.lockRotation = lockRotationSwitch.isOn
        setting.globalPagination = globalPaginationSwitch.isOn
        
        setting.mediaOverlay = mediaOverlaySwitch.isOn
        setting.tts = ttsSwitch.isOn
        
        setting.autoStartPlaying = autoPlaySwitch.isOn
        setting.autoLoadNewChapter = autoLoadSwitch.isOn
        setting.highlightTextToVoice = highlightTextSwitch.isOn
        
        sd.updateSetting(setting: setting)
    }

    @IBAction func companyPressed(_ sender: Any) {
        guard let url = URL(string: "https://www.skyepub.net") else {
          return //be safe
        }
        if #available(iOS 10.0, *) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        } else {
            UIApplication.shared.openURL(url)
        }
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
