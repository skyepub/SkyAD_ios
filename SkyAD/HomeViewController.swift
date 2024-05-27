// SkyEpub for iOS Advanced Demo IV  - Swift language
//
//  HomeViewController.swift
//  SkyAD
//
//  Created by 하늘나무 on 2020/10/09.
//  Copyright © 2020 Dev. All rights reserved.
//

import UIKit

class HomeViewController: UIViewController,UISearchBarDelegate,UIDocumentPickerDelegate,UICollectionViewDataSource,UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    var bis:NSMutableArray!
    var sortType:Int = 0
    var searchKey:String = ""
    var ad:AppDelegate!
    var sd:SkyData!
    var isGridMode:Bool = false
    
    var currentBookInformation:BookInformation!
    
    @IBOutlet weak var bookCollectionView: UICollectionView!
    
    @IBOutlet weak var topBar: UIView!
    @IBOutlet weak var importButton: UIButton!
    @IBOutlet weak var searchButton: UIButton!
    @IBOutlet weak var sortButton: UIButton!
    @IBOutlet weak var settingButton: UIButton!
    @IBOutlet weak var gridButton: UIButton!
    @IBOutlet weak var searchBar: UISearchBar!
    
    func loadBis() {
        self.bis = sd.fetchBookInformations(sortType: self.sortType, key: searchKey)
    }
    
    func reload() {
        self.loadBis()
        self.bookCollectionView.reloadData()
    }
    
    func UIColorFromRGB(rgbValue: UInt) -> UIColor {
        return UIColor(
            red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
            alpha: CGFloat(1.0)
        )
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        ad = UIApplication.shared.delegate as? AppDelegate
        sd = ad.data
        searchBar.delegate = self
        bookCollectionView.dataSource = self
        bookCollectionView.delegate = self
        
        self.addSkyErrorNotificationObserver()

        installSampleBooks() // if books are already installed, it will do nothing.
        
        let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(self.longPressed(_:)))
        self.bookCollectionView.addGestureRecognizer(longPressRecognizer)
        
        self.topBar.backgroundColor = UIColorFromRGB(rgbValue: 0x0069db)
        self.view.backgroundColor = UIColorFromRGB(rgbValue: 0x0069db)
        

        self.reload()
    }
    
    func addSkyErrorNotificationObserver() {
        NotificationCenter.default.addObserver(self,
        selector: #selector(didReceiveSkyErrorNotification(_:)),
        name: NSNotification.Name("SkyError"),
        object: nil)
    }
    
    func removeSkyErrorNotification() {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name("SkyError"), object: nil)
    }
    
    // if any error is reported by sdk.
    @objc func didReceiveSkyErrorNotification(_ notification: Notification) {
        guard let code: String = notification.userInfo?["code"] as? String else { return }
        guard let level: String = notification.userInfo?["level"] as? String else { return }
        guard let message: String = notification.userInfo?["message"] as? String else { return }
        
        NSLog("SkyError code %d level %d message:%@",code,level,message)
    }
    
    // install sample epubs from bundle.
    func installSampleBooks() {
        sd.installEpub(fileName: "Alice.epub")
        sd.installEpub(fileName: "Doctor.epub")
    }
    
    // when top,left import button pressed, new epub file can be imported and installed from device's file system.
    @IBAction func importPressed(_ sender: Any) {
        let picker = UIDocumentPickerViewController(documentTypes: ["org.idpf.epub-container"], in: .import)
        picker.delegate = self
        picker.modalPresentationStyle = .fullScreen
        self.present(picker, animated: true, completion: nil)
    }
    
    // when importing a epub file from local file system is over,  install the epub.
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        if controller.documentPickerMode == .import {
            print(urls[0].path)
            sd.installEpub(url:urls[0])
            self.reload()
        }
    }
    
    @IBAction func searchPressed(_ sender: Any) {
        searchBar.isHidden = false
        searchBar.becomeFirstResponder()
    }
    
    func showSortTypeActionSheet() {
        var noSortActionStyle = UIAlertAction.Style.cancel
        let sortActionSheet = UIAlertController(title: "", message:  NSLocalizedString("sort_by",comment: ""), preferredStyle: UIAlertController.Style.actionSheet)
        let sortByTitleAction = UIAlertAction(title: NSLocalizedString("title",comment: ""), style: UIAlertAction.Style.default) { (action) in
            self.sortType = 0
            self.reload()
            print("Sort By Last Title")
        }
        let sortByAuthorAction = UIAlertAction(title: NSLocalizedString("author",comment: ""), style: UIAlertAction.Style.default) { (action) in
            self.sortType = 1
            self.reload()
            print("Sort By Last Author")
        }
        let sortByLastReadAction = UIAlertAction(title: NSLocalizedString("last_read",comment: ""), style: UIAlertAction.Style.default) { (action) in
            self.sortType = 2
            self.reload()
            print("Sort By Last Read")
        }
        
        if isPad() {
            noSortActionStyle = UIAlertAction.Style.default
        }
        
        let noSortAction = UIAlertAction(title: NSLocalizedString("no_sort",comment: ""), style: noSortActionStyle ) { (action) in
            self.sortType = 3
            self.reload()
            print("No Sort Selected")
        }
        sortActionSheet.addAction(sortByTitleAction)
        sortActionSheet.addAction(sortByAuthorAction)
        sortActionSheet.addAction(sortByLastReadAction)
        sortActionSheet.addAction(noSortAction)
        
        if (self.isPad()) {
            sortActionSheet.popoverPresentationController?.permittedArrowDirections = UIPopoverArrowDirection(rawValue: 0)
            var rect = self.view.bounds
            rect.origin.x = 0
            rect.origin.y = 0
            sortActionSheet.popoverPresentationController?.sourceView = self.view
            sortActionSheet.popoverPresentationController?.sourceRect = rect
            
        }
        self.present(sortActionSheet, animated: true, completion: nil)
    }
    
    @IBAction func sortPressed(_ sender: Any) {
        self.showSortTypeActionSheet()
    }
    
    @IBAction func gridPressed(_ sender: Any) {
        isGridMode = !isGridMode
        var iconName:String!
        if isGridMode   {
            iconName = "grid-shelf"
        }else {
            iconName = "list-shelf"
        }
        gridButton.setImage(UIImage(named: iconName), for: .normal)
        self.reload()
    }
    
    @IBAction func settingPressed(_ sender: Any) {
        let svc = storyboard?.instantiateViewController(withIdentifier: "SettingViewController") as! SettingViewController
        svc.modalPresentationStyle = .fullScreen
        present(svc, animated: true, completion: nil)
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        self.searchKey = searchBar.text!
        self.reload()
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchBar.setShowsCancelButton(true, animated: true)
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        //
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.text = ""
        searchBar.setShowsCancelButton(false, animated: true)
        searchBar.resignFirstResponder()
        searchBar.isHidden = true
        self.searchKey = ""
        self.reload()
    }
    
    @objc func longPressed(_ gestureRecognizer: UILongPressGestureRecognizer) {
        let point = gestureRecognizer.location(in: bookCollectionView)
        let indexPath = bookCollectionView.indexPathForItem(at: point)
        let cell = bookCollectionView.cellForItem(at: indexPath!) as! BookCollectionViewCell
        let index = cell.tag
        let bi:BookInformation = self.bis.object(at: index) as! BookInformation
        self.showLongPressedActionSheet(bi)
    }
    
    func showLongPressedActionSheet(_ bi:BookInformation) {
        let longPressedActionSheet = UIAlertController(title: bi.title, message: "", preferredStyle: UIAlertController.Style.actionSheet)
        let openAction = UIAlertAction(title:NSLocalizedString("open",comment: ""), style: UIAlertAction.Style.default) { (action) in
            self.openBook(bi)
        }
        let openFirstPageAction = UIAlertAction(title: NSLocalizedString("open_the_first_page",comment: ""), style: UIAlertAction.Style.default) { (action) in
            bi.position = -1.0
            self.openBook(bi)
        }
        let deleteBookAction = UIAlertAction(title: NSLocalizedString("delete_book",comment: ""), style: UIAlertAction.Style.default) { (action) in
            self.sd.deleteBookByBookCode(bookCode: Int(bi.bookCode))
            self.reload()
        }
        let cancelAction = UIAlertAction(title: NSLocalizedString("cancel",comment: ""), style: UIAlertAction.Style.cancel) { (action) in
        }
        longPressedActionSheet.addAction(openAction)
        longPressedActionSheet.addAction(openFirstPageAction)
        longPressedActionSheet.addAction(deleteBookAction)
        if (!self.isPad()) {
            longPressedActionSheet.addAction(cancelAction)
        }else {
            if (self.isPad()) {
                longPressedActionSheet.popoverPresentationController?.permittedArrowDirections = UIPopoverArrowDirection(rawValue: 0)
                var rect = self.view.bounds
                rect.origin.x = 0
                rect.origin.y = 0
                longPressedActionSheet.popoverPresentationController?.sourceView = self.view
                longPressedActionSheet.popoverPresentationController?.sourceRect = rect
            }
        }
        
        self.present(longPressedActionSheet, animated: true, completion: nil)
    }
    
    func isPad() ->Bool {
        if (UIDevice.current.userInterfaceIdiom == UIUserInterfaceIdiom.pad)  {
            return true
        }else {
            return false
        }
    }
    
    func isPortrait()->Bool {
        guard let interfaceOrientation = UIApplication.shared.windows.first(where: { $0.isKeyWindow })?.windowScene?.interfaceOrientation else { return false }
        var ret:Bool = false
        switch interfaceOrientation {
        case .portrait:
            ret = true
        case .portraitUpsideDown:
            ret = true
        case .landscapeLeft:
            ret = false
        case .landscapeRight:
            ret = false
        case .unknown:
            ret = false
        default:
            ret = false
        }
        return ret
    }
    
    func numberOfItemsInRow()->Int {
        if self.isPad() {
            if self.isPortrait() {    // for Pad
                if isGridMode {
                    return 3
                }else {
                    return 2
                }
            }else {
                if isGridMode {
                    return 5
                }else {
                    return 3
                }
            }
        }else {
            if self.isPortrait() {    // for Phone
                if isGridMode {
                    return 2
                }else {
                    return 1
                }
            }else {
                if isGridMode {
                    return 4
                }else {
                    return 2
                }
            }
        }
    }

    func cellWidth() ->CGFloat {
        let ni = self.numberOfItemsInRow()
        let vw = self.view.bounds.size.width
        let iw = CGFloat(vw*0.96)/CGFloat(ni)
        return iw
    }

    func cellHeight()->CGFloat {
        return 200
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return bis.count
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width:self.cellWidth(), height:self.cellHeight())
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "bookCollectionViewCell", for: indexPath) as! BookCollectionViewCell
        let index = indexPath.row
        let bi:BookInformation = self.bis.object(at: index) as! BookInformation
        // return BookCell made already
        if cell.isInit && cell.bookCode == bi.bookCode {
            return cell;
        }
        // Create BookCell
        let coverPath = sd.getCoverPath(fileName: bi.fileName)
        let fileManager = FileManager.default
        if !fileManager.fileExists(atPath: coverPath) {
            cell.titleLabelOnCover.text = bi.title
        }else {
            cell.titleLabelOnCover.text = ""
            cell.bookCoverImageView.image = UIImage(contentsOfFile : coverPath)
        }
        self.addShadow(view: cell.bookCoverImageView, rect: CGRect(x:0,y:0,width:125,height: 175), size: CGSize(width:5,height:20))
        cell.titleLabel.text = bi.title
        cell.authorLabel.text = bi.creator
        cell.publisherLabel.text = bi.publisher
        cell.bookCode = bi.bookCode
        cell.tag = index
        if isGridMode {
            cell.titleLabel.isHidden = true
            cell.authorLabel.isHidden = true
            cell.publisherLabel.isHidden = true
        }else {
            cell.titleLabel.isHidden = false
            cell.authorLabel.isHidden = false
            cell.publisherLabel.isHidden = false
        }
        return cell
    }
        
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath) as! BookCollectionViewCell
        let index = cell.tag
        let bi:BookInformation = self.bis.object(at: index) as! BookInformation
        openBook(bi)
    }
    
    func addShadow(view:UIView, rect:CGRect, size:CGSize) {
        let shadowPath:UIBezierPath = UIBezierPath(rect: rect)
        view.layer.masksToBounds = false
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOffset = size
        view.layer.shadowOpacity = 0.1
        view.layer.shadowPath = shadowPath.cgPath
    }
    
    func openBook(_ bi:BookInformation) {
        if !bi.isFixedLayout {
            let bvc = storyboard?.instantiateViewController(withIdentifier: "BookViewController") as! BookViewController
            bvc.bookInformation = bi
            bvc.modalPresentationStyle = .fullScreen
            present(bvc, animated: true, completion: nil)
        }else {
            let fvc = storyboard?.instantiateViewController(withIdentifier: "MagazineViewController") as! MagazineViewController
            fvc.bookInformation = bi
            fvc.modalPresentationStyle = .fullScreen
            present(fvc, animated: true, completion: nil)
        }
    }
    
    func setStatusBarBackgroundColor(_ color: UIColor) {
        guard let statusBar = UIApplication.shared.value(forKeyPath: "statusBarWindow.statusBar") as? UIView else { return }
        statusBar.backgroundColor = color
    }
}
