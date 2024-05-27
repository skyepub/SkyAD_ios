// SkyEpub for iOS Advanced Demo IV  - Swift language
//
//  MagazineViewController.swift
//  SkyAD
//
//  Created by 하늘나무 on 2020/10/06.
//  Copyright © 2020 Dev. All rights reserved.
//

import UIKit

class MagazineViewController: UIViewController,FixedViewControllerDataSource,FixedViewControllerDelegate,SkyProviderDataSource, UITextFieldDelegate, UITableViewDelegate, UITableViewDataSource  {
    @IBOutlet weak var skyepubView: UIView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var homeButton: UIButton!
    @IBOutlet weak var listButton: UIButton!
    @IBOutlet weak var searchButton: UIButton!
    @IBOutlet weak var bookmarkButton: UIButton!
    @IBOutlet weak var menuButton: UIButton!
    
    @IBOutlet var highlightBox: UIView!
    @IBOutlet var colorBox: UIView!
    @IBOutlet var noteBox: UIView!
    @IBOutlet weak var noteTextView: UITextView!
    
    @IBOutlet var listBox: UIView!
    @IBOutlet weak var listBoxTitleLabel: UILabel!
    @IBOutlet weak var listBoxResumeButton: UIButton!
    @IBOutlet weak var listBoxSegmentedControl: UISegmentedControl!
    @IBOutlet weak var listBoxContainer: UIView!
    @IBOutlet weak var contentsTableView: UITableView!
    @IBOutlet weak var notesTableView: UITableView!
    @IBOutlet weak var bookmarksTableView: UITableView!

    @IBOutlet var baseView: UIView!

    @IBOutlet var searchBox: UIView!
    @IBOutlet weak var searchCancelButton: UIButton!
    @IBOutlet weak var searchScrollView: UIScrollView!
    @IBOutlet weak var searchTextField: UITextField! {
        didSet {
            searchTextField.delegate = self
        }
    }

    @IBOutlet var mediaBox: UIView!
    @IBOutlet weak var prevButton: UIButton!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var stopButton: UIButton!
    @IBOutlet weak var nextButton: UIButton!
    
    var bookInformation:BookInformation!
    var ad:AppDelegate!
    var sd:SkyData!
    var setting:Setting!
    var bookCode:Int = -1

    var thumbnailBox: UIScrollView!
    
    var fv:FixedViewController!
    var currentPageInformation:FixedPageInformation!
    var initialized:Bool = false
    var isCaching:Bool = false
    
    var isUIShown:Bool = false
    var currentTheme:Theme!
    var currentThemeIndex:Int = 0
    var themes:NSMutableArray = NSMutableArray()
    
    var currentColor:UIColor!
    var currentHighlight:Highlight!
    var currentMenuRect:CGRect!
    
    var isRotationLocked:Bool = false

    var highlights:NSMutableArray   = NSMutableArray()
    var bookmarks:NSMutableArray    = NSMutableArray()
    
    var searchScrollHeight:CGFloat = 0
    var searchResults:NSMutableArray = NSMutableArray()
    var lastNumberOfSearched:Int = 0
    
    var isAutoPlaying:Bool = false
    var isLoop:Bool = false
    var autoStartPlayingWhenNewPagesLoaded:Bool = false
    var autoMovePageWhenParallesFinished:Bool = false
    var currentParallel:Parallel!
    var isChapterJustLoaded:Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        var ad:AppDelegate!
        ad = UIApplication.shared.delegate as? AppDelegate
        sd = ad.data
        sd.createCachesDirectory()
        
        setting = sd.fetchSetting()
        
        self.addSkyErrorNotification()
        NotificationCenter.default.addObserver(self, selector: #selector(self.didRotate(_:)), name: UIDevice.orientationDidChangeNotification, object: nil)

        autoStartPlayingWhenNewPagesLoaded = setting.autoStartPlaying
        autoMovePageWhenParallesFinished = setting.autoLoadNewChapter
        if autoStartPlayingWhenNewPagesLoaded {
            isAutoPlaying = true
        }
        self.makeBookViewer()
        self.makeUI()
        self.hideUI()

        // Do any additional setup after loading the view.
    }
    
    func addSkyErrorNotification() {
        NotificationCenter.default.addObserver(self,
        selector: #selector(didReceiveSkyErrorNotification(_:)),
        name: NSNotification.Name("SkyError"),
        object: nil)
    }
    
    func removeSkyErrorNotification() {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name("SkyError"), object: nil)
    }
    
    @objc func didReceiveSkyErrorNotification(_ notification: Notification) {
        guard let code: String = notification.userInfo?["code"] as? String else { return }
        guard let level: String = notification.userInfo?["level"] as? String else { return }
        guard let message: String = notification.userInfo?["message"] as? String else { return }
        
        NSLog("SkyError code %d level %d message:%@",code,level,message)
    }
    
    @objc func didRotate(_ sender:Any) {
        print("rotated")
        self.hideUI()
        self.recalcFrames()
    }
    
    func recalcFrames() {
        self.recalcThumbnailBox()
    }
    
    override var prefersStatusBarHidden: Bool {
        if self.isPad() {
            return true
        }
        return false
    }
    
    func getBookPath()->String {
        let bookPath:String = "\(fv.baseDirectory!)/\(fv.fileName!)"
        return bookPath
    }
    
    func makeBookViewer() {
        // make FixedViewController Object for fixed layout epub.
        self.fv = FixedViewController.init(startPosition: self.bookInformation.position, spread: bookInformation.spread)
        // booksDirectory is the place where epub files exist
        let booksDirectory = sd.getBooksDirectory()
        // set bookCode of the b ook.
        fv.bookCode = bookInformation.bookCode
        // set fileName to open
        fv.fileName = bookInformation.fileName
        // set the baseDirectory of fv to booksDirectory
        fv.baseDirectory = booksDirectory
        
        // if setBookPath is called, fileName and baseDirectory are extracted automatically from bookPath.
        fv.setBookPath(self.getBookPath())

        // tell sdk that this epub is fixed layout.
        fv.isFixedLayout = true
        self.bookCode = Int(fv.bookCode)
        
        // set the dataSource of fv to self
        fv.dataSource = self
        // set the delegate of fv to self
        fv.delegate = self
        // set the page of book to its height.
        fv.setFitToHeight(false)

        // add two item in standard menu system for text selection.
        fv.addMenuItem(forSelection: self, title: "Highlight", selector:  #selector(onHighlightItemPressed(_:)))
        fv.addMenuItem(forSelection: self, title: "Note", selector:  #selector(onNoteItemPressed(_:)))
        
        // customize windowColor and backgroundColor.
        let windowColor = UIColor.darkGray
        self.view.backgroundColor = windowColor
        fv.changeWindowColor(windowColor)
        fv.changeBackgroundColor(UIColor.white)
        
        // currentColor is current HighlightColor.
        currentColor = self.getMarkerColor(colorIndex: 0)
        
        // set transitionType of fv. 0:none, 1:slide, 2:curling effect.
        fv.transitionType = Int32(setting.transitionType)
        // set page scale.
        fv.setPageScaleFactor(1.0)
        // enable swipe gestures to turn pages.  if some interactive book requires drag and drop actions, you need to turn it off.
        fv.setSwipeGestureEnabled(true)
        
        // set License Key for Fixed Layout
        fv.setLicenseKey("0000-0000-0000-0000");
        
        // SkyEpub SDK reads epub file via ContentProvider.
        // you are able to make your own ContentProvider.
        // SkyProvider is standard ContentProvider to open normal epub and the epubs encrypted by SkyDRM software.
        let skyProvider:SkyProvider = SkyProvider()
        // set the dataSource of skyProvider .
        skyProvider.dataSource = self
        // set the book object to fv.b ook.
        skyProvider.book = fv.book
        // set the contentProvider of fv to skyProvider.
        fv.setContentProvider(skyProvider)
        
        // set fixedViewController's size and coordinates.
        fv.view.frame = self.skyepubView.bounds
        fv.view.autoresizingMask =  [.flexibleWidth, .flexibleHeight]
        // add fv as subview of self.view
        self.skyepubView.addSubview(fv.view)
        self.addChild(fv)
        self.view.autoresizesSubviews = true
    }
    
    func makeThemes() {
        // Theme 0  -  White
        self.themes.add(Theme(themeName:"White",textColor: .black, backgroundColor: UIColor.init(red:252/255,green:252/255,blue: 252/255,alpha:1), boxColor: .white, borderColor: UIColor.init(red:198/255,green:198/255,blue: 200/255,alpha:1), iconColor: UIColor.init(red:0/255,green:2/255,blue: 0/255,alpha:1), labelColor: .black,     selectedColor:.blue, sliderThumbColor: .black,sliderMinTrackColor: .darkGray, sliderMaxTrackColor: UIColor.init(red:220/255,green:220/255,blue: 220/255,alpha:1)))
        // Theme 1 -   Brown
        self.themes.add(Theme(themeName:"Brown",textColor: .black, backgroundColor: UIColor.init(red:240/255,green:232/255,blue: 206/255,alpha:1), boxColor: UIColor.init(red:253/255,green:249/255,blue: 237/255,alpha:1), borderColor: UIColor.init(red:219/255,green:212/255,blue: 199/255,alpha:1), iconColor:UIColor.init(red:166/255,green:131/255,blue: 55/255,alpha:1), labelColor: UIColor.init(red:70/255,green:52/255,blue: 35/255,alpha:1), selectedColor:.blue,sliderThumbColor: UIColor.init(red:191/255,green:154/255,blue: 70/255,alpha:1),sliderMinTrackColor: UIColor.init(red:191/255,green:154/255,blue: 70/255,alpha:1), sliderMaxTrackColor: UIColor.init(red:219/255,green:212/255,blue: 199/255,alpha:1)))
        // Theme 2 -  Dark
        self.themes.add(Theme(themeName:"Dark",textColor: UIColor.init(red:212/255,green:212/255,blue: 213/255,alpha:1), backgroundColor: UIColor.init(red:71/255,green:71/255,blue: 73/255,alpha:1), boxColor: UIColor.init(red:77/255,green:77/255,blue: 79/255,alpha:1), borderColor: UIColor.init(red:91/255,green:91/255,blue: 95/255,alpha:1), iconColor: UIColor.init(red:238/255,green:238/255,blue: 238/255,alpha:1), labelColor: UIColor.init(red:212/255,green:212/255,blue: 213/255,alpha:1),selectedColor:.yellow, sliderThumbColor: UIColor.init(red:254/255,green:254/255,blue: 254/255,alpha:1),sliderMinTrackColor: UIColor.init(red:254/255,green:254/255,blue: 254/255,alpha:1), sliderMaxTrackColor: UIColor.init(red:103/255,green:103/255,blue: 106/255,alpha:1)))
        // Theme 3 - Black
        self.themes.add(Theme(themeName:"Black",textColor: UIColor.init(red:175/255,green:175/255,blue: 175/255,alpha:1), backgroundColor: .black, boxColor: UIColor.init(red:44/255,green:44/255,blue: 46/255,alpha:1), borderColor: UIColor.init(red:90/255,green:90/255,blue: 92/255,alpha:1), iconColor: UIColor.init(red:241/255,green:241/255,blue: 241/255,alpha:1), labelColor: UIColor.init(red:169/255,green:169/255,blue: 169/255,alpha:1),selectedColor:.white, sliderThumbColor: UIColor.init(red:169/255,green:169/255,blue: 169/255,alpha:1),sliderMinTrackColor: UIColor.init(red:169/255,green:169/255,blue: 169/255,alpha:1), sliderMaxTrackColor: UIColor.init(red:42/255,green:42/255,blue: 44/255,alpha:1)))
        // Theme 4 -  FixedLayout
        self.themes.add(Theme(themeName:"Fixed",textColor: UIColor.init(red:238/255,green:238/255,blue: 238/255,alpha:1), backgroundColor: UIColor.init(red:71/255,green:71/255,blue: 73/255,alpha:1), boxColor: UIColor.init(red:65/255,green:65/255,blue: 65/255,alpha:1), borderColor: UIColor.init(red:91/255,green:91/255,blue: 95/255,alpha:1), iconColor: UIColor.init(red:238/255,green:238/255,blue: 238/255,alpha:1), labelColor: UIColor.init(red:238/255,green:238/255,blue: 238/255,alpha:1),selectedColor:.yellow, sliderThumbColor: UIColor.init(red:254/255,green:254/255,blue: 254/255,alpha:1),sliderMinTrackColor: UIColor.init(red:254/255,green:254/255,blue: 254/255,alpha:1), sliderMaxTrackColor: UIColor.init(red:103/255,green:103/255,blue: 106/255,alpha:1)))

    }
    
    func applyTheme(theme:Theme) {
        applyThemeToBody(theme: theme)
        applyThemeToListBox(theme: theme)
        applyThemeToSearchBox(theme: theme)
        applyThemeToMediaBox(theme: theme)
    }
    
    func applyThemeToBody(theme:Theme) {
//        currentTheme.iconColor = UIColor.white
//        currentTheme.labelColor = UIColor.white
        homeButton.tintColor = currentTheme.iconColor
        listButton.tintColor = currentTheme.iconColor
        searchButton.tintColor = currentTheme.iconColor
        bookmarkButton.tintColor = currentTheme.iconColor
        menuButton.tintColor = currentTheme.iconColor
        titleLabel.textColor = currentTheme.labelColor
    }
    
    func makeUI() {
        makeThemes()
//        currentThemeIndex = setting.theme
        currentThemeIndex = 4
        currentTheme = themes.object(at: currentThemeIndex) as! Theme
        applyTheme(theme: currentTheme)
        contentsTableView.delegate = self
        contentsTableView.dataSource = self
        bookmarksTableView.delegate = self
        bookmarksTableView.dataSource = self
        notesTableView.delegate = self
        notesTableView.dataSource = self
        self.thumbnailBox = UIScrollView()
        self.view.addSubview(thumbnailBox)
    }
    
    func showUI() {
        self.showControls()
        self.showThumbnailBox()
    }
    
    func hideUI() {
        self.hideControls()
        self.hideThumbnailBox()
    }
    
    func showControls() {
        homeButton.isHidden = false
        listButton.isHidden = false
        searchButton.isHidden = false
        bookmarkButton.isHidden = false
        if mediaBox.isHidden {
            titleLabel.isHidden = false
        }else {
            titleLabel.isHidden = true
        }
        menuButton.isHidden = true
        isUIShown = true
    }
    
    func hideControls() {
        homeButton.isHidden = true
        listButton.isHidden = true
        searchButton.isHidden = true
        bookmarkButton.isHidden = true
        titleLabel.isHidden = true
        menuButton.isHidden = false
        isUIShown = false

    }
    
    // SKYEPUB SDK CALLBACK
    // called when touch on book is detected.
    // positionInView is iphone view coodinates.
    // positionInPage is HTML coordinates of b ook.
    func fixedViewController(_ fvc: FixedViewController!, didDetectTapAt positionInView: CGPoint, positionInPage: CGPoint) {
        if isUIShown {
            hideUI()
        }
    }
    
    func imageFilePath(pageIndex:Int)->String {
        let documentPath = sd.getDocumentsPath()
        let imageFilePath = "\(documentPath)/caches/sb\(self.bookCode)-cache\(pageIndex).png"
        return imageFilePath
    }
    
    func makeThumbView(pageIndex:Int)->ThumbnailView {
        let tv:ThumbnailView = ThumbnailView()
        tv.tag = pageIndex

        tv.backgroundColor = UIColor.lightGray
        tv.pageIndex = pageIndex
        
        tv.thumbImageView = UIImageView()
        tv.thumbImageView.autoresizingMask = [.flexibleWidth,.flexibleHeight]
        tv.thumbImageView.image = UIImage(contentsOfFile: self.imageFilePath(pageIndex: pageIndex))
        tv.addSubview(tv.thumbImageView)
        
        tv.thumbButton = UIButton(type: .custom)
        tv.thumbButton.tag = pageIndex
        tv.thumbButton.showsTouchWhenHighlighted = true
        tv.thumbButton.setTitleColor(UIColor.darkGray, for: .normal)
        var pi = pageIndex + 1
        if fv.isRTL {
            pi = fv.spine.count-1-pageIndex
        }
        tv.thumbButton.setTitle("\(pi)", for: .normal)
        tv.thumbButton.autoresizingMask = [.flexibleWidth,.flexibleHeight]
        tv.thumbButton.addTarget(self, action: #selector(self.thumbmailPressed(_:)), for: .touchUpInside)
        tv.addSubview(tv.thumbButton)
        return tv
    }
    
    // SKYEPUB SDK CALLBACK
    // called whenever page is moved.
    // fixedPageInformation contains all information about current page.
    func fixedViewController(_ fvc: FixedViewController!, pageMoved fixedPageInformation: FixedPageInformation!) {
        currentPageInformation = fixedPageInformation
        self.bookInformation.position = fixedPageInformation.pagePosition
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.startMediaOverlay()
        }
        titleLabel.text = fv.title
        self.applyBookmark()
        if !initialized {
            self.makeThumbnailBox()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.fv.startCaching()
            }
            initialized = true
        }
        self.markThumbnail(pageIndex:fixedPageInformation.pageIndex)
        print("zoomScale \(fv.zoomScale())")
    }
    
    // SKYEPUB SDK CALLBACK
    // called when sdk needs to ask key to decrypt the encrypted epub. (encrypted by skydrm or any other drm which conforms to epub3 encrypt specification)
    // for more information about SkyDRM. please refer to the links below
    // https://www.dropbox.com/s/ctbe4yvhs60lq4n/SkyDRM%20Diagram.pdf?dl=1
    // https://www.dropbox.com/s/ch0kf0djrcxd241/SkyDRM%20Solution.pdf?dl=1
    // https://www.dropbox.com/s/xkxw4utpqq9frjw/SCS%20API%20Reference.pdf?dl=1
    func skyProvider(_ sp: SkyProvider!, keyForEncryptedData uuidForContent: String!, contentName: String!, uuidForEpub: String!) -> String! {
        let key = sd.keyManager.getKey(uuidForEpub,uuidForContent: uuidForContent);
        return key
    }
    
    // SKYEPUB SDK CALLBACK
    // need to return true to SDK if cachedImage for pageIndex exists.
    func fixedViewController(_ fvc: FixedViewController!, cacheExists pageIndex: Int32) -> Bool {
        let path = self.imageFilePath(pageIndex: Int(pageIndex))
        var isDir: ObjCBool = false
        if FileManager.default.fileExists(atPath: path, isDirectory: &isDir) {
            return true
        }else {
            return false
        }
    }
    
    // SKYEPUB SDK CALLBACK
    // called when caching process starts.
    func fixedViewController(_ fvc: FixedViewController!, cachingStarted index: Int32) {
        isCaching = true
    }
    

    // SKYEPUB SDK CALLBACK
    // called whenever one page image is cached, the image is needed to be saved in device persistant memory for future use.
    func fixedViewController(_ fvc: FixedViewController!, cached index: Int32, image: UIImage!) {
        self.writeImage(image: image, pageIndex:Int(index))
    }
    
    // SKYEPUB SDK CALLBACK
    // called when caching process ends.
    func fixedViewController(_ fvc: FixedViewController!, cachingFinished index: Int32) {
        isCaching = false
    }
    
    func resizeImage(sourceImage:UIImage,maxWidth i_width:Int) -> UIImage! {
        let oldWidth = sourceImage.size.width
        let scaleFactor = CGFloat(i_width) / oldWidth
        
        let newHeight = sourceImage.size.height * scaleFactor
        let newWidth = oldWidth * scaleFactor
        
        UIGraphicsBeginImageContext(CGSize(width:newWidth, height:newHeight))
        sourceImage.draw(in: CGRect(x:0, y:0, width:newWidth, height:newHeight))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext();
        return newImage;
    }
    
    func writeImage(image:UIImage,pageIndex:Int) {
        let path = self.imageFilePath(pageIndex: pageIndex)
        let resized = self.resizeImage(sourceImage: image, maxWidth: 100)
        guard let imageData = image.jpegData(compressionQuality: 1) else { return }
        do {
            try imageData.write(to:URL(fileURLWithPath: path))
        } catch let error {
            print("error saving file with error", error)
        }
        print("PageIndex \(pageIndex) is cached in \(path)")
        self.loadThumbnailImage(image:resized!,pageIndex:pageIndex)
    }
    
    func getThumbView(pageIndex:Int)->ThumbnailView! {
        let resultViews = thumbnailBox.subviews.filter{$0 is ThumbnailView}
        for i in 0..<resultViews.count {
            let tb:ThumbnailView = resultViews[i] as! ThumbnailView
            if tb.pageIndex == pageIndex {
                return tb
            }
        }
        return nil
    }
    
    func loadThumbnailImage(image:UIImage,pageIndex:Int) {
        let tv = self.getThumbView(pageIndex: pageIndex)
        tv?.thumbImageView.image = image
    }
    
    
    // make thumbnail box to display all cacked images for each page.
    func makeThumbnailBox() {
        for tv in thumbnailBox.subviews{
           if tv is ThumbnailView {
              tv.removeFromSuperview()
           }
        }
        // in fixedc layout, chaper is page, so the number of chapters is equal to the number of pages.
        // fv.b ook.spine.count always returns the number of chapters.
        for i in 0..<fv.spine.count {
            let tv:ThumbnailView = self.makeThumbView(pageIndex: i)
            thumbnailBox.addSubview(tv)
        }
        self.recalcThumbnailBox()
    }
    
    func recalcThumbnailBox() {
        let vw = self.view.frame.size.width
        let vh = self.view.frame.size.height
        let bm:CGFloat = view.safeAreaInsets.bottom + 5
        
        // in fixed layout, book has fixedWidth and fixedHeight of fixed layout b ook.
        // aspect is fixedWidth / fixedheight
        ThumbnailView.ASPECT = CGFloat(fv.fixedWidth) / CGFloat(fv.fixedHeight)
        ThumbnailView.HEIGHT = CGFloat(self.view.bounds.size.height/7)
        ThumbnailView.WIDTH = CGFloat(ThumbnailView.HEIGHT * ThumbnailView.ASPECT)

        for i in 0..<fv.spine.count {
            let tv:ThumbnailView! = self.getThumbView(pageIndex: i)
            tv.frame    = CGRect(x:ThumbnailView.MARGIN + (ThumbnailView.WIDTH + ThumbnailView.MARGIN) * CGFloat(i),y:0,width:ThumbnailView.WIDTH,height:ThumbnailView.HEIGHT)
        }
        
        let totalWidth:CGFloat = (ThumbnailView.WIDTH + ThumbnailView.MARGIN)*CGFloat(fv.spine.count)+ThumbnailView.MARGIN
        thumbnailBox.contentSize = CGSize(width: totalWidth, height:ThumbnailView.HEIGHT)
        thumbnailBox.frame = CGRect(x:0,y:(vh-(bm+vh/7)),width:vw,height:vh/7);
    }
    
    func markThumbnail(pageIndex:Int) {
        for uv in thumbnailBox.subviews{
            if uv is ThumbnailView {
                let nv:ThumbnailView = uv as! ThumbnailView
                nv.thumbButton.layer.borderColor = UIColor.gray.cgColor
                nv.thumbButton.layer.borderWidth = 1.0
                if nv.pageIndex == pageIndex {
                    nv.thumbButton.layer.borderWidth = 3.0
                }
            }
        }
        var offsetX:CGFloat = ThumbnailView.MARGIN+(ThumbnailView.WIDTH+ThumbnailView.MARGIN)*CGFloat(pageIndex)-(self.view.bounds.size.width-ThumbnailView.WIDTH)/2
        if offsetX <= 0 {
            offsetX = 0
        }
        thumbnailBox.setContentOffset(CGPoint(x:offsetX,y:0), animated: true)
    }
    
    // if one of cached image in thumbnailBox is pressed, goth the page.
    @objc func thumbmailPressed(_ sender: UIButton){
        let thumbnailButton:UIButton = sender
        let pageIndex = Int32(thumbnailButton.tag)
        fv.gotoPage(pageIndex)
    }
    
    func showThumbnailBox() {
        self.recalcFrames()
        thumbnailBox.isHidden = false
    }

    func hideThumbnailBox() {
        thumbnailBox.isHidden = true
    }
    
    // Bookmark
    func getPageInformation(_ fi:FixedPageInformation) -> PageInformation {
        var pi = PageInformation()
        pi.bookCode = fi.bookCode
        pi.chapterIndex = fi.pageIndex
        pi.pageIndex = fi.pageIndex
        pi.pagePositionInBook = fi.pagePosition
        return pi
        
    }
    
    func changeBookmarkButton(isBookmarked:Bool) {
        if isBookmarked {
            bookmarkButton.setImage(UIImage(named: "bookmarked"), for: .normal)
        }else {
            bookmarkButton.setImage(UIImage(named: "bookmark"), for: .normal)
        }
    }
    
    @IBAction func bookmarkPressed(_ sender: Any) {
        self.toggleBookmark()
    }
    
    func toggleBookmark() {
        let pi = self.getPageInformation(currentPageInformation)
        let isMarked:Bool = sd.isBookmarked(pageInformation: pi)
        self.changeBookmarkButton(isBookmarked: !isMarked)
        sd.toggleBookmark(pageInformation: pi)
    }

    func applyBookmark() {
        let pi = self.getPageInformation(currentPageInformation)
        let isMarked:Bool = sd.isBookmarked(pageInformation: pi)
        self.changeBookmarkButton(isBookmarked: isMarked)
    }
    
    // SKYEPUB SDK CALLBACK
    // called when user select text to highlight.
    func fixedViewController(_ rvc: FixedViewController!, didSelectRange highlight: Highlight!, menuRect: CGRect) {
        currentHighlight = highlight;
        currentMenuRect = menuRect;
    }
    
    // SKYEPUB SDK CALLBACK
    // called when a highlight is about to be deleted.
    func fixedViewController(_ rvc: FixedViewController!, didDelete highlight: Highlight!) {
        sd.deleteHighlight(highlight: highlight)
    }
    
    // SKYEPUB SDK CALLBACK
    // called when a highlight is about to be update.
    func fixedViewController(_ rvc: FixedViewController!, didUpdate highlight: Highlight!) {
        sd.updateHighlight(highlight: highlight)
    }
    
    // SKYEPUB SDK CALLBACK
    // called when a highlight is about to be inserted
    func fixedViewController(_ rvc: FixedViewController!, didInsert highlight: Highlight!) {
        sd.insertHighlight(highlight: highlight)
        currentHighlight = highlight
        UIPasteboard.general.string = highlight.text
    }
    
    // SKYEPUB SDK CALLBACK
    // called when user touches on a highlight.
    func fixedViewController(_ rvc: FixedViewController!, didHitHighlight highlight: Highlight!, at position: CGPoint) {
        currentHighlight = highlight
        currentMenuRect = CGRect(x:position.x-15, y:position.y-40, width:50, height: 50)
        currentColor = self.UIColorFromRGB(rgbValue: UInt(currentHighlight.highlightColor))
        self.showHighlightBox()
    }
    
    func fixedViewController(_ fvc: FixedViewController!, didHitLink href:String!) {
        print("didHitLink detected : "+href)
    }
    
    // SKYEPUB SDK CALLBACK
    // need to return all highlight objects to SDK.
    func fixedViewController(_ fvc: FixedViewController!, highlightsForChapter chapterIndex: Int) -> NSMutableArray! {
        let highlights = sd.fetchHighlights(bookCode: self.bookCode, chapterIndex: Int(chapterIndex))
        return highlights
    }
    
    
    // when highlight menu item (which is registered into standard menu system by fv.addMenuItem) is pressed.
    @objc func onHighlightItemPressed(_ sender: UIMenuController){
        self.showHighlightBox()
        // make the selected text highlight.
        fv.makeSelectionHighlight(currentColor)
    }
    
    // when note menu item (which is registered into standard menu system by fv.addMenuItem) is pressed.
    @objc func onNoteItemPressed(_ sender: UIMenuController){
        // make the selected text note (highlight with note text)
        fv.makeSelectionHighlight(currentColor)
        self.showNoteBox()
    }
    
    func showBaseView() {
        self.view.addSubview(baseView)
        baseView.frame = self.view.bounds
        baseView.isHidden = false
        baseView.backgroundColor = .clear
        let gesture = UITapGestureRecognizer(target: self, action:#selector(self.baseClick(_:)))
        baseView.addGestureRecognizer(gesture)
    }
    
    func hideBaseView() {
        if !baseView.isHidden {
            baseView.removeFromSuperview()
            baseView.isHidden = true
        }
    }
    
    @objc func baseClick(_ sender:UITapGestureRecognizer){
        self.hideBoxes()
    }
    
    func hideBoxes() {
        self.hideHighlightBox()
        self.hideColorBox()
        self.hideNoteBox()
    }
    
    func UIColorFromRGB(rgbValue: UInt) -> UIColor {
        return UIColor(
            red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
            alpha: CGFloat(1.0)
        )
    }
    
    func RGBFromUIColor(color:UIColor)->UInt32 {
        let colorComponents = color.cgColor.components!
        let value = UInt32(0xFF0000*colorComponents[0] + 0xFF00*colorComponents[1] + 0xFF*colorComponents[2])
        return value
    }
    
    func getMarkerColor(colorIndex:Int32)->UIColor {
        var markerColor:UIColor!
        switch colorIndex {
        case 0: // yellow
            markerColor = UIColor(red: 238/255, green: 230/255, blue: 142/255, alpha: 1)
        case 1: //
            markerColor = UIColor(red: 218/255, green: 244/255, blue: 160/255, alpha: 1)
        case 2:
            markerColor = UIColor(red: 172/255, green: 201/255, blue: 246/255, alpha: 1)
        case 3:
            markerColor = UIColor(red: 249/255, green: 182/255, blue: 214/255, alpha: 1)
        default:
            markerColor = UIColor(red: 249/255, green: 182/255, blue: 214/255, alpha: 1)
        }
        return markerColor
    }
    
    func showHighlightBox() {
        showBaseView()
        self.view.addSubview(highlightBox)
        var hx:CGFloat = (currentMenuRect.size.width - highlightBox.frame.size.width)/2+currentMenuRect.origin.x
        var highlightFrame:CGRect = CGRect(x:hx,y:currentMenuRect.origin.y,width:190,height:37);
        highlightBox.frame = highlightFrame
        highlightBox.isHidden = false
    }
    
    func hideHighlightBox() {
        self.highlightBox.removeFromSuperview()
        highlightBox.isHidden = true
        hideBaseView()
    }
    
    func showColorBox() {
        showBaseView()
        self.view.addSubview(colorBox)
        colorBox.frame.origin.x = currentMenuRect.origin.x
        colorBox.frame.origin.y = currentMenuRect.origin.y
        colorBox.backgroundColor = currentColor
        colorBox.isHidden = false
    }
    
    func hideColorBox() {
        self.colorBox.removeFromSuperview()
        colorBox.isHidden = true
        hideBaseView()
    }
    
    func changeHighlightColor(newColor:UIColor) {
        currentColor = newColor
        highlightBox.backgroundColor = currentColor
        colorBox.backgroundColor = currentColor
        // change the color of current highglight
        fv.changeHighlight(currentHighlight, color: currentColor!)
        self.hideColorBox()
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
    
    func isCurrentHighlightInLeftPage() ->Bool {
        var isLeftPage:Bool = true
        if (currentHighlight.pageIndex % 2) == 0 {
            isLeftPage = false
        }else {
            isLeftPage = true
        }
        return isLeftPage
    }
    
    func showNoteBox() {
        showBaseView()
        var noteX,noteY,noteWidth,noteHeight:CGFloat!
        noteWidth  = 280
        noteHeight = 230
        var noteFrame:CGRect!
        
        if (self.isPad()) { // iPad
            noteY = currentMenuRect.origin.y+100;
            if (noteY+noteHeight) > (self.view.bounds.size.height*0.7) {
                noteY = (self.view.bounds.size.height - noteBox.frame.size.height)/2
            }
            if (self.isPortrait()) {
                noteX = (self.view.bounds.size.width - noteWidth)/2;
            }else {
                // if fv is double paged (two pages displayed in landscape mode)
                if (fv.isDoublePaged()) {
                    noteHeight = 150
                    noteWidth = 250
                    if self.isCurrentHighlightInLeftPage() {
                        noteX = (self.view.bounds.size.width / 2 - noteWidth) / 2
                    }else {
                        let halfViewWidth = self.view.bounds.size.width / 2
                        noteX = (halfViewWidth + (halfViewWidth - noteWidth) / 2)
                    }
                }else {
                    noteX = (self.view.bounds.size.width - noteWidth)/2
                    noteHeight = 200
                    noteWidth = 300
                }
            }
        }else { // in case of iPhone, coordinates are fixed.
            if self.isPortrait() {
                noteY = (self.view.bounds.size.height - noteBox.frame.size.height)/2
            }else {
                noteY = (self.view.bounds.size.height - noteBox.frame.size.height)/2
                noteHeight = 150
                noteWidth = 500
            }
            noteX = (self.view.bounds.size.width - noteWidth)/2
        }
        noteBox.frame =  CGRect(x:noteX,y:noteY,width:noteWidth,height:noteHeight)
        noteBox.backgroundColor = currentColor
        self.view.addSubview(self.noteBox)
        self.noteBox.isHidden = false
    }
    
    func hideNoteBox() {
        if self.noteBox.isHidden {
            return
        }
        self.saveNote()
        self.noteBox.removeFromSuperview()
        noteBox.isHidden = true
        noteTextView.text.removeAll()
        noteTextView.resignFirstResponder()
        hideBaseView()
    }
    
    // save the text of note.
    func saveNote() {
        if self.noteBox.isHidden  {
            return
        }
        if currentHighlight == nil {
            return
        }
        if let text = noteTextView.text {
            let newColor:UIColor!
            if (currentHighlight.highlightColor==0) {
                newColor = self.getMarkerColor(colorIndex: 0)
            }else {
                newColor = self.UIColorFromRGB(rgbValue: UInt(currentHighlight.highlightColor))
            }
            
            if text.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).isEmpty {
                currentHighlight.note = ""
                currentHighlight.isNote = false
            }else {
                currentHighlight.note = text
                currentHighlight.isNote = true
            }
            // when text of note is modified and needed to be saved,
            fv.changeHighlight(currentHighlight, color: newColor, note: text)
        }
    }
    
    @IBAction func colorPressed(_ sender: Any) {
        hideHighlightBox()
        showColorBox()
    }
    

    @IBAction func trashPressed(_ sender: Any) {
        fv.deleteHightlight(currentHighlight)
        hideHighlightBox()
    }
    
    
    @IBAction func noteInHighlightBoxPressed(_ sender: Any) {
        hideHighlightBox()
        noteTextView.text = currentHighlight.note
        showNoteBox()
    }
    
    
    @IBAction func savePressed(_ sender: Any) {
        hideHighlightBox()
    }
    
    
    @IBAction func yellowPressed(_ sender: Any) {
        let color = self.getMarkerColor(colorIndex: 0)
        self.changeHighlightColor(newColor: color)

    }
    
    @IBAction func greenPressed(_ sender: Any) {
        let color = self.getMarkerColor(colorIndex: 1)
        self.changeHighlightColor(newColor: color)

    }
    
    @IBAction func bluePressed(_ sender: Any) {
        let color = self.getMarkerColor(colorIndex: 2)
        self.changeHighlightColor(newColor: color)

    }
    
    @IBAction func redPressed(_ sender: Any) {
        let color = self.getMarkerColor(colorIndex: 3)
        self.changeHighlightColor(newColor: color)

    }
    
    // listBox
    func applyThemeToListBox(theme:Theme) {
        listBox.backgroundColor = theme.backgroundColor
        
        listBoxTitleLabel.textColor = theme.textColor
        listBoxResumeButton.setTitleColor(theme.textColor, for: .normal)
        
        if #available(iOS 13.0, *) {
            listBoxSegmentedControl.setTitleTextAttributes([.foregroundColor: UIColor.black], for: .selected)
            listBoxSegmentedControl.setTitleTextAttributes([.foregroundColor: theme.labelColor], for: .normal)
        } else {
            listBoxSegmentedControl.tintColor = UIColor.darkGray
        }
    }
    
    @IBAction func listBoxSegmentedControlChanged(_ sender: Any) {
        print(listBoxSegmentedControl.selectedSegmentIndex)
        self.showTableView(index:listBoxSegmentedControl.selectedSegmentIndex)
    }
    
    @IBAction func listBoxResumePressed(_ sender: Any) {
        self.hideListBox()
    }
    
    func showListBox() {
        showBaseView()
        isRotationLocked = true
        var sx,sy,sw,sh:CGFloat
        listBox.layer.borderColor = UIColor.clear.cgColor
        sx = view.safeAreaInsets.left * 0.4
        sy = view.safeAreaInsets.top
        sw = self.view.bounds.size.width-(view.safeAreaInsets.left+view.safeAreaInsets.right) * 0.4
        sh = self.view.bounds.size.height-(view.safeAreaInsets.top+view.safeAreaInsets.bottom)
        
        listBox.frame = CGRect(x:sx,y:sy,width: sw,height: sh)
        
        listBoxTitleLabel.text = fv.title;
        
        reloadContents()
        reloadHighlights()
        reloadBookmarks()
        
        showTableView(index: listBoxSegmentedControl.selectedSegmentIndex)
        
        view.addSubview(listBox)
        applyThemeToListBox(theme: currentTheme)
        listBox.isHidden = false
    }
    
    func hideListBox() {
        if listBox.isHidden {
            return
        }
        listBox.isHidden = true
        listBox.removeFromSuperview()   // this line causes the constraint issues.
        isRotationLocked = setting.lockRotation
        hideBaseView()
    }
    
    func showTableView(index:Int) {
        contentsTableView.isHidden = true
        notesTableView.isHidden = true
        bookmarksTableView.isHidden = true
        if (index==0) {
            contentsTableView.isHidden = false
        }else if (index==1) {
            notesTableView.isHidden = false
        }else if (index==2) {
            bookmarksTableView.isHidden = false
        }
    }
    
    func reloadContents() {
        contentsTableView.reloadData()
    }
    
    func reloadHighlights() {
        self.highlights = self.sd.fetchHighlights(bookCode: self.bookCode)
        notesTableView.reloadData()
    }
    
    func reloadBookmarks() {
        self.bookmarks = self.sd.fetchBookmarks(bookCode: self.bookCode)
        bookmarksTableView.reloadData()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        var ret:Int = 0
        if (tableView.tag==200) {
            ret  = fv.navMap.count
        }else if (tableView.tag==201) {
            ret  = self.highlights.count
        }else if (tableView.tag==202) {
            ret  = self.bookmarks.count
        }
        return ret
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let index = indexPath.row
        if (tableView.tag==200) {
            // make a tabble for TOC (table of contents)
            if let cell:ContentsTableViewCell = contentsTableView.dequeueReusableCell(withIdentifier: "contentsTableViewCell", for: indexPath) as? ContentsTableViewCell {
                let np:NavPoint = fv.navMap.object(at: index) as! NavPoint
                var leadingSpaceForDepth:String = ""
                for _ in 0..<np.depth {
                    leadingSpaceForDepth += "   "
                }
                cell.chapterTitleLabel.text = leadingSpaceForDepth + np.text
                cell.positionLabel.text = ""
                cell.chapterTitleLabel.textColor = currentTheme.textColor
                cell.positionLabel.textColor = currentTheme.textColor
                
                if np.chapterIndex == currentPageInformation.pageIndex {
                    cell.chapterTitleLabel.textColor = UIColor.systemIndigo
                }
                
                return cell
            }
        }else if (tableView.tag==201) {
            // make a table for Notes and Highlights
            if let cell:NotesTableViewCell = notesTableView.dequeueReusableCell(withIdentifier: "notesTableViewCell", for: indexPath) as? NotesTableViewCell {
                let highlight:Highlight = highlights.object(at: index) as! Highlight
                var displayPageIndex = highlight.chapterIndex+1
                if  fv.isDoublePaged() {
                    displayPageIndex = displayPageIndex*2
                }
                cell.positionLabel.text = "Page \(displayPageIndex)"
                cell.highlightTextLabel.text = highlight.text
                cell.noteTextLabel.text = highlight.note
                cell.datetimeLabel.text = highlight.datetime
                
                cell.positionLabel.textColor = currentTheme.textColor
                cell.highlightTextLabel.textColor = .black
                cell.noteTextLabel.textColor = currentTheme.textColor
                cell.datetimeLabel.textColor = currentTheme.textColor

                cell.highlightTextLabel.backgroundColor =  UIColorFromRGB(rgbValue: UInt(highlight.highlightColor))
                return cell
            }
        }else if (tableView.tag==202) {
            // make a table for bookmarks.
            if let cell:BookmarksTableViewCell = bookmarksTableView.dequeueReusableCell(withIdentifier: "bookmarksTableViewCell", for: indexPath) as? BookmarksTableViewCell {
                let pg:PageInformation = bookmarks.object(at: index) as! PageInformation
                var displayPageIndex = pg.chapterIndex+1
                if  fv.isDoublePaged() {
                    displayPageIndex = displayPageIndex*2
                }
                cell.positionLabel.text = "Page \(displayPageIndex)"
                cell.datetimeLabel.text = pg.datetime
                cell.datetimeLabel.textColor = currentTheme.textColor
                cell.positionLabel.textColor = currentTheme.textColor
                return cell
            }
        }
        return UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let index = indexPath.row
        if (tableView.tag==200) {
            let np:NavPoint = fv.navMap.object(at: index) as! NavPoint
            // when one item of TOC table is pressed, goto the position using navPoint.
            fv.gotoPage(napPoint: np)
            self.hideListBox()
        }else if (tableView.tag==201) {
            // when one highlight is pressed, goto the position by using highlight chapter index (chaperIndex is pageIndex in fixed layout)
            let highlight:Highlight = highlights.object(at: index) as! Highlight
            fv.gotoPage(highlight.chapterIndex)
            self.hideListBox()
        }else if (tableView.tag==202) {
            // when one bookmark is pressed, goto the position by using the chapter index of PageInformation object which is alreedy stored as bookmark position.
            let pg:PageInformation = bookmarks.object(at: index) as! PageInformation
            fv.gotoPage(Int32(pg.chapterIndex))
            self.hideListBox()
        }
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        if (tableView.tag==201 || tableView.tag==202) {
            return true
        }
        return false
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if (editingStyle == .delete) {
            let index = indexPath.row
            if (tableView.tag==201) {
                let highlight:Highlight = highlights.object(at: index) as! Highlight
                self.sd.deleteHighlight(highlight: highlight)
                self.reloadHighlights()
            }else if (tableView.tag==202) {
                let pi:PageInformation = bookmarks.object(at: index) as! PageInformation
                self.sd.deleteBookmark(pageInformation: pi)
                self.reloadBookmarks()
            }
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let index = indexPath.row
        var height:CGFloat = 70
        if (tableView.tag == 200) {
            height = 40
        }else if (tableView.tag == 201) {
            let highlight:Highlight = highlights.object(at: index) as! Highlight
            if highlight.isNote {
                height = 125
            }else {
                height = 100
            }
        }else if (tableView.tag == 202) {
            height = 67
        }
        return height
    }

    // Saerch Routine ======================================================================================
    @IBAction func searchCancelPressed(_ sender: Any) {
        self.hideSearchBox()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {   //delegate method
        let searchKey = searchTextField.text
        hideSearchBox()
        showSearchBox(isCollapsed: false)
        self.startSearch(key: searchKey)
        searchTextField.resignFirstResponder()
        return true
    }
    
    func clearSearchResults() {
        searchScrollHeight = 0
        searchResults.removeAllObjects()
        for sv in searchScrollView.subviews {
            sv.removeFromSuperview()
        }
        searchScrollView.contentSize.height = 0
    }
    
    func startSearch(key:String!)  {
        lastNumberOfSearched = 0
        
        self.clearSearchResults()
        // start search by using key.
        fv.searchKey(key)
    }
    
    func searchMore() {
        // continue searching
        fv.searchMore()
    }

    func stopSearch() {
        // stop searching.
        fv.stopSearch()
    }
    
    var didApplyClearBox:Bool = false
    
    func showSearchBox(isCollapsed:Bool) {
        showBaseView()
        var searchText:String!
        searchText = searchTextField.text
        
        searchTextField.leftViewMode = .always
        
        let imageView = UIImageView();
        let image = UIImage(named: "magnifier");
        imageView.image = image;
        searchTextField.leftView = imageView;

        searchBox.layer.borderWidth = 1
        searchBox.layer.cornerRadius = 10
        isRotationLocked = true
        
        var sx,sy,sw,sh:CGFloat
        let rightMargin:CGFloat = 50.0
        let topMargin:CGFloat = 60.0 + view.safeAreaInsets.top
        let bottomMargin:CGFloat = 50.0 + view.safeAreaInsets.bottom
        
        
        if isCollapsed {
            if (searchText ?? "").isEmpty {
                self.clearSearchResults()
                searchTextField.becomeFirstResponder()
            }
        }
        
        if self.isPad() {
            searchBox.layer.borderColor = UIColor.lightGray.cgColor
            sx = self.view.bounds.size.width - searchBox.bounds.size.width - rightMargin
            sw = 400
            sy = topMargin
            if isCollapsed && (searchText ?? "").isEmpty  {
                searchScrollView.isHidden = true
                sh = 95
            }else {
                sh = self.view.bounds.size.height - (topMargin+bottomMargin)
                searchScrollView.isHidden = false
            }
        }else {
            searchBox.layer.borderColor = UIColor.clear.cgColor
            sx = 0
            sy = view.safeAreaInsets.top
            sw = self.view.bounds.size.width
            sh = self.view.bounds.size.height-(view.safeAreaInsets.top+view.safeAreaInsets.bottom)
        }
        
        searchBox.frame = CGRect(x:sx,y:sy,width:sw,height:sh)
        searchScrollView.frame = CGRect(x:30,y:100,width:searchBox.frame.size.width-55,height:searchBox.frame.height-(35+95))
        
        view.addSubview(searchBox)
        
        applyThemeToSearchBox(theme: currentTheme)
        searchBox.isHidden = false
    }
    
    func hideSearchBox() {
        if searchBox.isHidden {
            return
        }
        searchTextField.resignFirstResponder()
        searchBox.isHidden = true
        searchBox.removeFromSuperview()   // this line causes the constraint issues.
        isRotationLocked = setting.lockRotation
        hideBaseView()
    }
    
    @objc func searchTextFieldDidChange(_ textField: UITextField) {
        if !(searchTextField.text ?? "").isEmpty {
            applyThemeToSearchTextFieldClearButton(theme: currentTheme)
        }
    }
    
    func applyThemeToSearchTextFieldClearButton(theme:Theme) {
        if didApplyClearBox {
            return
        }
        for view in searchTextField.subviews {
            if view is UIButton {
                let button = view as! UIButton
                if let image = button.image(for: .highlighted) {
                    button.setImage(image.imageWithColor(color: .lightGray), for: .highlighted)
                    button.setImage(image.imageWithColor(color: .lightGray), for: .normal)
                    didApplyClearBox = true
                }
                if let image = button.image(for: .normal) {
                    button.setImage(image.imageWithColor(color: .lightGray), for: .highlighted)
                    button.setImage(image.imageWithColor(color: .lightGray), for: .normal)
                    didApplyClearBox = true
                }
            }
        }

    }
    
    func applyThemeToSearchBox(theme:Theme) {
        searchBox.backgroundColor = theme.boxColor
        searchBox.layer.borderWidth = 1
        searchBox.layer.borderColor = theme.borderColor.cgColor
        
        searchTextField.backgroundColor = UIColor.clear
        searchTextField.layer.masksToBounds = true
        searchTextField.layer.borderWidth = 1
        searchTextField.layer.cornerRadius = 5
        searchTextField.layer.borderColor = theme.borderColor.cgColor
        searchTextField.textColor = theme.textColor
        searchTextField.addTarget(self, action: #selector(self.searchTextFieldDidChange(_:)), for: .editingChanged)
        
        searchCancelButton.setTitleColor(theme.textColor, for: .normal)
        applyThemeToSearchTextFieldClearButton(theme: theme)
        
        let resultViews = searchScrollView.subviews.filter{$0 is SearchResultView}
        for i in 0..<resultViews.count {
            let resultView:SearchResultView = resultViews[i] as! SearchResultView
            resultView.headerLabel.textColor = theme.textColor
            resultView.contentLabel.textColor = theme.textColor
            resultView.bottomLine.backgroundColor = theme.borderColor
            resultView.bottomLine.alpha = 0.65
        }
    }
    
    func addSearchResult(searchResult:SearchResult, mode:SearchResultType) {
        var headerText:String = ""
        var contentText:String = ""
        
        let resultView = Bundle.main.loadNibNamed("SearchResultView", owner: self, options: nil)?.first as! SearchResultView
        let gotoButton = resultView.searchResultButton!
        
        if (mode == .normal) {
            let ci = searchResult.chapterIndex;
            let chapterTitle = fv.getChapterTitle(ci)
            var displayPageIndex = searchResult.pageIndex+1
            var displayNumberOfPages = searchResult.numberOfPagesInChapter
            if  fv.isDoublePaged() {
                displayPageIndex = displayPageIndex*2
                displayNumberOfPages = displayNumberOfPages*2
            }
            
//            headerText = String(format: "%@ %d/%d",NSLocalizedString("page",comment: ""),displayPageIndex,displayNumberOfPages)
            if !searchResult.chapterTitle.isEmpty {
                headerText = String(format: "%@",searchResult.chapterTitle)
            }else {
                headerText = String(format: "Page %d",searchResult.chapterIndex+1)
            }
            
            contentText = searchResult.text
            searchResults.add(searchResult)
            
            gotoButton.tag = searchResults.count - 1
        }else if (mode == .more){
            headerText = NSLocalizedString("search_more",comment: "")
            contentText = String(format:"%d %@",searchResult.numberOfSearched,NSLocalizedString("found",comment: ""))
            gotoButton.tag =  -2
        }else if (mode == .finished) {
            contentText = String(format:"%d %@",searchResult.numberOfSearched,NSLocalizedString("found",comment: ""))
            gotoButton.tag =  -1
        }
        
        resultView.headerLabel.text = headerText
        resultView.contentLabel.text = contentText
        
        resultView.headerLabel.textColor = currentTheme.textColor
        resultView.contentLabel.textColor = currentTheme.textColor
        resultView.bottomLine.backgroundColor = currentTheme.borderColor
        resultView.bottomLine.alpha = 0.65
        
        gotoButton.addTarget(self, action: #selector(self.gotoSearchPressed(_:)), for: .touchUpInside)
        
        var rx,ry,rw,rh:CGFloat
        rx = 0
        ry = searchScrollHeight
        rw = searchScrollView.bounds.size.width
        rh = 90
        
        resultView.frame = CGRect(x:rx,y:ry,width:rw,height:rh)
        
        searchScrollView.addSubview(resultView)
        searchScrollHeight+=rh
        searchScrollView.contentSize = CGSize(width:rw,height:searchScrollHeight)
        var co = searchScrollHeight-searchScrollView.bounds.size.height
        if (co<=0) {
            co = 0
        }
        searchScrollView.contentOffset  = CGPoint(x:0,y:co)
        
    }

    // when one item for a searchResult is pressed, goto the position.
    @objc func gotoSearchPressed(_ sender: UIButton){
        let gotoSearchButton:UIButton = sender
        if (gotoSearchButton.tag == -1) {
            self.hideSearchBox()
        }else if (gotoSearchButton.tag == -2) {
            searchScrollHeight -= gotoSearchButton.bounds.size.height;
            searchScrollView.contentSize = CGSize(width:gotoSearchButton.bounds.size.width,height:searchScrollHeight)
            gotoSearchButton.superview!.removeFromSuperview()
            fv.searchMore()
        }else {
            self.hideSearchBox()
            let sr = searchResults.object(at: gotoSearchButton.tag) as! SearchResult
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.fv.gotoPage(searchResult: sr) // goto the position by using searchResult object.
            }
        }
    }

    // SKYEPUB SDK CALLBACK
    // called when key is found while searching.
    // SearchResult object contains all information of the text found.
    func fixedViewController(_ fvc: FixedViewController!, didSearchKey searchResult: SearchResult!) {
        self.addSearchResult(searchResult: searchResult, mode:.normal)
    }
    
    // SKYEPUB SDK CALLBACK
    // called when all search process is over.
    func fixedViewController(_ fvc: FixedViewController!, didFinishSearchAll searchResult: SearchResult!) {
        self.addSearchResult(searchResult: searchResult, mode:.finished)
    }
    
    // SKYEPUB SDK CALLBACK
    // called when all search process for given chapter (in fixed layout chapter = page).
    func fixedViewController(_ fvc: FixedViewController!, didFinishSearchForChapter searchResult: SearchResult!) {
        fv.pauseSearch()
        let cn = Int(searchResult.numberOfSearched) - Int(lastNumberOfSearched)
        if cn > 150 {
            self.addSearchResult(searchResult: searchResult, mode:.more)
            lastNumberOfSearched = Int(searchResult.numberOfSearched)
        }else {
            fv.searchMore()
        }
    }

    // MediaOverlay Routines ============================================================================================================
    func applyThemeToMediaBox(theme:Theme) {
        prevButton.tintColor = theme.iconColor
        playButton.tintColor = theme.iconColor
        stopButton.tintColor = theme.iconColor
        nextButton.tintColor = theme.iconColor
    }
    
    func startMediaOverlay() {
        // if fv has mediaOverlay and setting is set for mediaOverlay.
        if fv.isMediaOverlayAvailable() && setting.mediaOverlay {
            self.showMediaBox()
            if isAutoPlaying {
                playButton.setImage(UIImage(named: "pause"), for: .normal)
                fv.playFirstParallel()  // play the first parallel of mediaOverlay in this page.
            }
        }else {
            self.hideMediaBox()
        }
    }
    
    func showMediaBox() {
        self.view.addSubview(mediaBox)
        applyThemeToMediaBox(theme: currentTheme)
        mediaBox.frame.origin.x = titleLabel.frame.origin.x
        mediaBox.frame.origin.y = listButton.frame.origin.y - 7
        mediaBox.isHidden = false
        titleLabel.isHidden = true
    }
    
    func hideMediaBox() {
        self.mediaBox.removeFromSuperview()
        mediaBox.isHidden = true
        if !homeButton.isHidden {
            titleLabel.isHidden = false
        }
    }
    
    func changePlayAndPauseButton() {
        if !fv.isPlayingStarted() {
            playButton.setImage(UIImage(named: "play"), for: .normal)
        }else if fv.isPlayingPaused() {
            playButton.setImage(UIImage(named: "play"), for: .normal)
        }else {
            playButton.setImage(UIImage(named: "pause"), for: .normal)
        }
    }
    
    @IBAction func prevPressed(_ sender: Any) {
        self.playPrev()
    }
    
    @IBAction func playPressed(_ sender: Any) {
        self.playAndPause()
    }
    
    @IBAction func stopPressed(_ sender: Any) {
        self.stopPlaying()
    }
        
    @IBAction func nextPressed(_ sender: Any) {
        self.playNext()
    }
    
    func playAndPause() {
        if fv.isPlayingPaused() {
            if !fv.isPlayingStarted() {
                if (autoStartPlayingWhenNewPagesLoaded) {
                    isAutoPlaying = true
                }
                fv.playFirstParallel()
            }else {
                if (autoStartPlayingWhenNewPagesLoaded) {
                    isAutoPlaying = true
                }
                fv.resumePlayingParallel()
            }
        }else {
            if (autoStartPlayingWhenNewPagesLoaded) {
                isAutoPlaying = true
            }
            fv.pausePlayingParallel()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.changePlayAndPauseButton()
        }
    }
    
    func stopPlaying() {
        playButton.setImage(UIImage(named: "play"), for: .normal)
        fv.stopPlayingParallel()
        if autoStartPlayingWhenNewPagesLoaded {
            isAutoPlaying = false
        }
        fv.restoreElementColor()
    }

    func playPrev() {
        fv.restoreElementColor()
        if currentParallel.parallelIndex == 0 {
            if autoMovePageWhenParallesFinished {
                fv.gotoPrevPage()
            }
        }else {
            fv.playPrevParallel()
        }
    }

    func playNext() {
        fv.restoreElementColor()
        fv.playNextParallel()
    }
    
    // SKYEPUB SDK CALLBACK
    // called when Playing a parallel starts in MediaOverlay.
    // setting.highlightTextToVoice is set, make the text for parallel which is being played as highlight.
    func fixedViewController(_ fvc: FixedViewController!, parallelDidStart parallel: Parallel!) {
        if setting.highlightTextToVoice {
            fv.changeElementColor("#FF0000", hash: parallel.hash, pageIndex: parallel.pageIndex)
        }
        currentParallel = parallel
    }
    
    // SKYEPUB SDK CALLBACK
    // called when Playing a parallel ends in MediaOverlay.
    func fixedViewController(_ fvc: FixedViewController!, parallelDidEnd parallel: Parallel!) {
        if setting.highlightTextToVoice {
            fv.restoreElementColor()
        }
        if isLoop {
            fv.playPrevParallel()
        }
    }
    
    // SKYEPUB SDK CALLBACK
    // called when playing all parallels is finished.
    func parallesDidEnd(_ fvcc: FixedViewController!) {
        if autoStartPlayingWhenNewPagesLoaded {
            isAutoPlaying = true
        }
        if autoMovePageWhenParallesFinished {
            fv.gotoNextPage()
        }
    }
    
    
    // should call destory explicitly whenever this viewController is dismissed.
    func destroy() {
        NotificationCenter.default.removeObserver(self)
        self.removeSkyErrorNotification()
        sd.updateBookPosition(bookInformation: self.bookInformation)
        fv.removeFromParent()
        fv.view.removeFromSuperview()
        fv.destroy()
    }
    
    override func dismiss(animated flag: Bool,
                             completion: (() -> Void)?) {
        super.dismiss(animated: flag, completion: completion)
        NSLog("Dismissed");
    }
    
    @IBAction func homePressed(_ sender: Any) {
        destroy()
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func menuPressed(_ sender: Any) {
        self.showUI()
    }
    
    @IBAction func listPressed(_ sender: Any) {
        self.showListBox()
    }
    
    @IBAction func searchPressed(_ sender: Any) {
        self.showSearchBox(isCollapsed: true)
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
