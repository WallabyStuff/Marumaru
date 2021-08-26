//
//  SceneScrollView.swift
//  Marumaru
//
//  Created by 이승기 on 2021/08/25.
//

import UIKit

import RxSwift
import RxCocoa

class SceneScrollView: UIScrollView {
    
    struct SceneView {
        var baseView: UIView
        var imageView: UIImageView
    }
    
    var disposeBag = DisposeBag()
    let networkHandler = NetworkHandler()
    
    var contentView = UIView()
    var contentViewHeightConstraint = NSLayoutConstraint()
    var spacing: CGFloat = 20
    
    var sceneViewArr = [SceneView]()
    var imageRequestArr = [UUID]()
    var sceneArr = [MangaScene]()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setUpScrollView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setUpScrollView()
    }
    
    deinit {
        disposeBag = DisposeBag()
    }
    
    private func setUpScrollView() {
        translatesAutoresizingMaskIntoConstraints = false
        
        contentView.backgroundColor = ColorSet.backgroundColor
        addSubview(contentView)
        contentView.translatesAutoresizingMaskIntoConstraints = false
        contentView.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        contentView.leadingAnchor.constraint(equalTo: self.leadingAnchor).isActive = true
        contentView.trailingAnchor.constraint(equalTo: self.trailingAnchor).isActive = true
        contentView.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
        contentView.widthAnchor.constraint(equalTo: self.widthAnchor).isActive = true
        contentViewHeightConstraint = contentView.heightAnchor.constraint(equalToConstant: self.frame.height)
        contentViewHeightConstraint.isActive = true
        
        // Detect orientation change and resize cells
        NotificationCenter.default.rx.notification(UIDevice.orientationDidChangeNotification)
                    .observe(on: MainScheduler.instance)
                    .subscribe(onNext: { _ in
                        self.resizeCell()
                    }).disposed(by: disposeBag)
    }
    
    private func prepareForImage() {
        for (index, _) in sceneArr.enumerated() {
            // baseView for sceneImageView
            let sceneBaseView = UIView(frame: CGRect(x: 0, y: 0,
                                                           width: self.frame.width,
                                                           height: self.frame.height))
            sceneBaseView.backgroundColor = ColorSet.patternedColor
            
            if index == 0 {
                // index image
                sceneBaseView.frame = CGRect(x: 0, y: 0,
                                             width: self.frame.width,
                                             height: self.frame.height)
                contentView.addSubview(sceneBaseView)
            } else {
                DispatchQueue.main.async {
                    let previousCell = self.sceneViewArr[index - 1].baseView
                    let offsetY = previousCell.frame.origin.y + previousCell.frame.height
                    
                    sceneBaseView.frame = CGRect(x: 0,
                                                 y: offsetY,
                                                 width: self.frame.width,
                                                 height: self.contentView.frame.width)
                    sceneBaseView.center.x = self.contentView.center.x
                    self.contentView.addSubview(sceneBaseView)
                }
            }
            
            contentViewHeightConstraint.constant += sceneBaseView.frame.height
            contentViewHeightConstraint.isActive = true
            
            // Scene ImageView
            let sceneImageView = UIImageView()
            sceneImageView.backgroundColor = .clear
            sceneImageView.image = UIImage()
            sceneImageView.contentMode = .scaleAspectFit
            
            sceneBaseView.addSubview(sceneImageView)
            sceneImageView.translatesAutoresizingMaskIntoConstraints = false
            sceneImageView.topAnchor.constraint(equalTo: sceneBaseView.topAnchor).isActive = true
            sceneImageView.leadingAnchor.constraint(equalTo: sceneBaseView.leadingAnchor).isActive = true
            sceneImageView.trailingAnchor.constraint(equalTo: sceneBaseView.trailingAnchor).isActive = true
            sceneImageView.bottomAnchor.constraint(equalTo: sceneBaseView.bottomAnchor).isActive = true
            
            let sceneView = SceneView(baseView: sceneBaseView,
                                      imageView: sceneImageView)
            sceneViewArr.append(sceneView)
        }
    }
    
    private func appendSceneImage(index: Int) {
        
        if sceneArr.count > 0 && index < sceneArr.count {
            if let url = URL(string: sceneArr[index].sceneImageUrl) {
                let token = networkHandler.getImage(url) { result in
                    DispatchQueue.global(qos: .background).async {
                        do {
                            let result = try result.get()
                            
                            DispatchQueue.main.async {
                                self.appendSceneImage(index: index + 1)
                                self.setImage(index, result.imageCache)
                            }
                        } catch {
                            print(error)
                            return
                        }
                    }
                }
                
                if let token = token {
                    imageRequestArr.append(token)
                }
            }
        }
    }
    
    private func setImage(_ index: Int, _ imageCache: ImageCache) {
        
        sceneViewArr[index].imageView.image = imageCache.image
        sceneViewArr[index].baseView.backgroundColor = ColorSet.backgroundColor
        
        let heightProportion = imageCache.image.size.height / imageCache.image.size.width
        let accurateCellHeight = contentView.frame.width * heightProportion
        sceneViewArr[index].baseView.frame.size.height = accurateCellHeight
        
        // reposition the Cell
        if index == 0 {
            sceneViewArr[index].baseView.center.x = self.contentView.center.x
            sceneViewArr[index].baseView.frame.origin.y = 0
            sceneViewArr[index].baseView.frame.size.width = self.frame.width
            enableZoom()
        } else {
            let previousCell = sceneViewArr[index - 1].baseView
            let offsetY = previousCell.frame.origin.y + previousCell.frame.height + self.spacing
            
            sceneViewArr[index].baseView.center.x = self.contentView.center.x
            sceneViewArr[index].baseView.frame.origin.y = offsetY
            sceneViewArr[index].baseView.frame.size.width = self.frame.width
            
            self.contentViewHeightConstraint.constant += accurateCellHeight
            self.contentViewHeightConstraint.isActive = true
            
            if index == sceneViewArr.count - 1 {
                contentViewHeightConstraint.constant = offsetY + accurateCellHeight
                contentViewHeightConstraint.isActive = true
                resizeCell()
            }
        }
    }
    
    func resizeCell() {
        disableZoom()
        
        contentViewHeightConstraint.constant = 0
        contentViewHeightConstraint.isActive = true
        
        for (index, sceneView) in sceneViewArr.enumerated() {
            if index == 0 {
                if !sceneView.imageView.image!.isEmpty() {
                    // if image is loaded
                    let heightProportion = sceneView.imageView.image!.size.height / sceneView.imageView.image!.size.width
                    let accurateCellHeight = contentView.frame.width * heightProportion
                    
                    sceneView.baseView.frame.size.width = self.frame.width
                    sceneView.baseView.frame.size.height = accurateCellHeight
                } else {
                    // if image is not loaded
                    sceneView.baseView.frame = CGRect(x: 0,
                                                      y: 0,
                                                      width: self.frame.width,
                                                      height: self.frame.height)
                }
            } else {
                if !sceneView.imageView.image!.isEmpty() {
                    // if image is loaded
                    DispatchQueue.main.async {
                        // accurate position Y
                        let previousCell = self.sceneViewArr[index - 1].baseView
                        let offsetY = previousCell.frame.origin.y + previousCell.frame.height + self.spacing

                        // accurate cell height
                        let heightProportion = sceneView.imageView.image!.size.height /  sceneView.imageView.image!.size.width
                        let accurateCellHeight = self.contentView.frame.width * heightProportion

                        sceneView.baseView.frame.origin.y = offsetY
                        sceneView.baseView.frame.size.width = self.frame.width
                        sceneView.baseView.frame.size.height = accurateCellHeight
                        sceneView.baseView.center.x = self.contentView.center.x
                        
                        // exent contentView height widht appended cell height
                        self.contentViewHeightConstraint.constant += accurateCellHeight
                        self.contentViewHeightConstraint.isActive = true
                        
                        if index == (self.sceneViewArr.count - 1) {
                            self.contentViewHeightConstraint.constant = offsetY + accurateCellHeight
                            self.contentViewHeightConstraint.isActive = true
                            self.enableZoom()
                        }
                    }
                }
            }
        }
    }
    
    func reloadData() {
        disableZoom()
        
        // ScrollView Size to original
        self.setContentOffset(CGPoint(x: 0, y: 0), animated: false)
        contentViewHeightConstraint.constant = self.frame.height
        contentViewHeightConstraint.isActive = true
        
        // remove all the ContentViews
        contentView.subviews.forEach { subView in
            subView.removeFromSuperview()
        }
        
        // cancel the image requests
        imageRequestArr.forEach { token in
            print("Log cancel requriest")
            networkHandler.cancelLoadImage(token)
        }
        
        // start set scene image with sceneArr
        sceneViewArr.removeAll()
        prepareForImage()
        appendSceneImage(index: 0)
    }
    
    func clearReloadData() {
        sceneArr.removeAll()
        sceneViewArr.removeAll()
        reloadData()
    }
    
    func enableZoom() {
        minimumZoomScale = 1
        maximumZoomScale = 3
    }
    
    func disableZoom() {
        minimumZoomScale = 1
        maximumZoomScale = 1
    }
}
