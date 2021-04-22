//
//  ViewMangaViewController.swift
//  Marumaru
//
//  Created by 이승기 on 2021/04/08.
//

import UIKit
import Alamofire
import SwiftSoup
import Lottie
import CoreData


class ViewMangaViewController: UIViewController {

    struct Scene {
        var sceneUrl: String
        var sceneImage: UIImage?
    }
    
    
    let networkHandler = NetworkHandler()
    var sceneArr = Array<Scene>()
    
    let baseUrl = "https://marumaru.cloud/"
    var mangaUrl: String = ""

    
    @IBOutlet weak var sceneLoadingView: UIView!
    @IBOutlet weak var topBarView: UIView!
    @IBOutlet weak var mangaTitleLabel: UILabel!
    @IBOutlet weak var mangaSceneTableView: UITableView!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var scrollContentView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        initDesign()
        initInstance()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        setLottieAnims()
        getMangaScenes()
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle{
        return .darkContent
    }
    
    
    func initDesign(){
        
    }
    
    func initInstance(){
        mangaSceneTableView.delegate = self
        mangaSceneTableView.dataSource = self
        
        scrollView.delegate = self
        scrollView.maximumZoomScale = 3.0
        scrollView.minimumZoomScale = 1.0
        
        scrollView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleTap(sender:))))
    }
    
    func setLottieAnims(){
        // Set scene loading animation
        let sceneLoadingAnim = AnimationView(name: "loading_square")
        sceneLoadingAnim.frame = CGRect(x: 0, y: 0, width: 300, height: 300)
        sceneLoadingAnim.center = sceneLoadingView.center
        sceneLoadingAnim.loopMode = .loop
        sceneLoadingAnim.play()
        
        sceneLoadingView.addSubview(sceneLoadingAnim)
    }
    
    func getMangaScenes(){
        self.sceneLoadingView.isHidden = false
        
        DispatchQueue.global(qos: .background).async {
            if !self.mangaUrl.isEmpty{
                do{
                    guard let url = URL(string: self.mangaUrl) else {return}
                    let htmlContent = try String(contentsOf: url, encoding: .utf8)
                    let doc = try SwiftSoup.parse(htmlContent)
                    let elements = try doc.getElementsByClass("img-tag")
                    
                    // Set manga title
                    let titleDoc = try doc.getElementsByClass("view-wrap")
                    let mangaTitle = try titleDoc.select("h1").text()
                    
                    DispatchQueue.main.async {
                        self.mangaTitleLabel.text = mangaTitle
                    }
                    
                    // Apends manga scenes
                    for (_, element) in elements.enumerated(){
                        var imgUrl = try element.select("img").attr("src")
                        if !imgUrl.contains(self.baseUrl){
                            imgUrl = "\(self.baseUrl)\(imgUrl)"
                        }
                        
                        self.sceneArr.append(Scene(sceneUrl: imgUrl, sceneImage: nil))
                    }
                    
                    // if successfuly appending scenes
                    DispatchQueue.main.sync {
                        self.sceneLoadingView.isHidden = true
                        self.mangaSceneTableView.reloadData()
                    }
                            
                }catch{
                    print(error.localizedDescription)
                }
            }
        }
    }
    
    func fadeTopbar(bool: Bool){
        if bool {
            UIView.animate(withDuration: 0.5) {
                self.topBarView.alpha = 0
            } completion: { _ in
                self.topBarView.isHidden = true
            }
        }else{
            self.topBarView.isHidden = false
            
            UIView.animate(withDuration: 0.5) {
                self.topBarView.alpha = 1
            }
        }
    }
    
   
    
    @objc func handleTap(sender: UITapGestureRecognizer){
        if sender.state == .ended{
            if topBarView.isHidden {
                fadeTopbar(bool: false)
            }else{
                fadeTopbar(bool: true)
            }
        }
    }

    @IBAction func backButtonAction(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
}




extension ViewMangaViewController: UITableViewDelegate ,UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sceneArr.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let sceneCell = tableView.dequeueReusableCell(withIdentifier: "MangaSceneCell") as! MangaSceneCell
        
        sceneCell.selectionStyle = .none
        
        // set background tile
        let tileImage = UIImage(named: "Tile")!
        let patternBackground = UIColor(patternImage: tileImage)
        sceneCell.backgroundColor = patternBackground
        sceneCell.sceneImageView.image = UIImage()

        // set scene
        if let url = URL(string: sceneArr[indexPath.row].sceneUrl){
            let token = networkHandler.getImage(url){result in
                DispatchQueue.global(qos: .background).async {
                    do{
                        let image = try result.get()
                        DispatchQueue.main.async {
                            sceneCell.sceneImageView.image = image
                            sceneCell.backgroundColor = UIColor(named: "BackgroundColor")!
                        }
                    }catch{
                        DispatchQueue.main.async {
                            sceneCell.backgroundColor = patternBackground
                        }
                        print(error.localizedDescription)
                    }
                }
            }
            
            sceneCell.onReuse = {
                if let token = token{
                    self.networkHandler.cancelLoadImage(token)
                }
            }
        }
        
        
//        // set background tile
//        let tileImage = UIImage(named: "Tile")!
//        let patternBackground = UIColor(patternImage: tileImage)
//        sceneCell.backgroundColor = patternBackground
//        sceneCell.sceneImageView.image = UIImage()
//
//        // 안전하게 인덱스 접근
//        if  indexPath.row < sceneArr.count{
//            if sceneArr[indexPath.row].sceneImage != nil {
//                // scene image already loaded
//                sceneCell.sceneImageView.image = sceneArr[indexPath.row].sceneImage
//                sceneCell.backgroundColor = UIColor(named: "BackgroundColor")!
//            }else{
//                // scene has not been loaded
//                DispatchQueue.global(qos: .background).async {
//                    do{
//                        let sceneImgUrl = URL(string: self.sceneArr[indexPath.row].sceneUrl)
//                        let sceneImgData = try Data(contentsOf: sceneImgUrl!)
//                        let sceneImg = UIImage(data: sceneImgData)
//                        self.sceneArr[indexPath.row].sceneImage = sceneImg
//
//                        DispatchQueue.main.async {
//                            sceneCell.sceneImageView.image = sceneImg
//                            sceneCell.backgroundColor = UIColor(named: "BackgroundColor")!
//                        }
//                    }catch{
//                        sceneCell.backgroundColor = patternBackground
//                        print(error.localizedDescription)
//                    }
//                }
//            }
//        }
        
        return sceneCell
    }
}


extension ViewMangaViewController: UIScrollViewDelegate{
    func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView) {
        
        let actualPosition = scrollView.panGestureRecognizer.translation(in: scrollView.superview)
        
        if (actualPosition.y > 0){
            // scrolling up
            fadeTopbar(bool: false)
        }else{
            // scrolling down
            fadeTopbar(bool: true)
        }
        
        let height = scrollView.frame.height
        let contentYoffset = scrollView.contentOffset.y
        let distanceFromBottom = scrollView.contentSize.height - contentYoffset
        
        if distanceFromBottom <= height{
            UIView.animate(withDuration: 0.5){
                self.topBarView.alpha = 1
            }
        }
    }
    
    // Set scrollview zoomable
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return self.scrollContentView
    }
}
