//
//  ComicStirpSceneScrollView.swift
//  Marumaru
//
//  Created by 이승기 on 2022/06/03.
//

import UIKit

import RxSwift
import RxCocoa

struct SceneImageView {
    var imageView: UIImageView
    var topConstraint: NSLayoutConstraint
    var leadingConstraint: NSLayoutConstraint
    var trailingConstraint: NSLayoutConstraint
    var heightConstraint: NSLayoutConstraint
}

class ComicStripScrollView: UIScrollView {
    
    
    // MARK: - Initializers
    
    private var viewModel = ComicStripScrollViewModel()
    private var disposeBag = DisposeBag()
    
    public var spacing: CGFloat = 20
    public var defaultSceneHeightProportion: CGFloat = 1.4
    
    public var contentView = UIView()
    private var contentViewHeightConstraint = NSLayoutConstraint()
    
    private var sceneImageViews = [SceneImageView]()
    private var lastestFrameWidth: CGFloat = 0
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    
    // MARK: - Setups
    
    private func setup() {
        setupView()
        bind()
    }
    
    private func setupView() {
        setupScrollView()
        setupContentView()
    }
    
    private func setupScrollView() {
        translatesAutoresizingMaskIntoConstraints = false
    }
    
    private func setupContentView() {
        contentView.backgroundColor = R.color.backgroundWhite()!
        
        addSubview(contentView)
        contentView.translatesAutoresizingMaskIntoConstraints = false
        contentViewHeightConstraint = contentView.heightAnchor.constraint(equalToConstant: self.frame.height)
        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(equalTo: self.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: self.widthAnchor),
            contentViewHeightConstraint
        ])
    }
    
    
    // MARK: - Binds
    
    private func bind() {
        bindScenes()
        bindSceneConstraints()
    }
    
    private func bindScenes() {
        viewModel.scenesObservable
            .subscribe(with: self, onNext: { strongSelf, scenes in
                strongSelf.loadScenes(scenes)
            })
            .disposed(by: disposeBag)
    }
    
    private func bindSceneConstraints() {
        viewModel.isFrameWidthChanged
            .subscribe(with: self, onNext: { strongSelf, isChanged in
                if isChanged {
                    strongSelf.configureSceneConstraints()
                }
            })
            .disposed(by: disposeBag)
    }
    
    
    // MARK: - Constraints
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if frame.width != lastestFrameWidth {
            lastestFrameWidth = frame.width
            viewModel.updateFrameWidth()
        }
    }
    
    private func configureSceneConstraints() {
        sceneImageViews.forEach { scene in
            if let image = scene.imageView.image {
                scene.heightConstraint.constant = fitHeight(image)
            } else {
                scene.heightConstraint.constant = frame.width * defaultSceneHeightProportion
            }
        }
        
        updateContentViewHeight()
    }

    
    // MARK: - Methods
    
    private func loadScenes(_ scenes: [ComicStripScene]) {
        // Append empty scene to load last scene image view
        var scenes = scenes
        scenes.append(emptyScene)
        
        if scenes.count == 0 {
            contentView.isHidden = true
            return
        }
        
        contentView.isHidden = false
        
        for (index, scene) in scenes.enumerated() {
            if index == 0 {
                appendFirstScene(scene)
            } else {
                appendScene(index, scene)
            }
        }

        removeLastScene()
        updateContentViewHeight()
    }
}

extension ComicStripScrollView {
    private func appendScene(_ index: Int, _ scene: ComicStripScene) {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.backgroundColor = UIColor.tilePatternColor
        
        contentView.addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        
        var topConstraint = NSLayoutConstraint()
        let previousSceneBottomAnchor = sceneImageViews[index - 1].imageView.bottomAnchor
        topConstraint = imageView.topAnchor.constraint(equalTo: previousSceneBottomAnchor)
        let leadingCsontraint = imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor)
        let trailingConstraint = imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor)
        let heightConstraint = imageView.heightAnchor.constraint(equalToConstant: self.frame.width * defaultSceneHeightProportion)
        
        NSLayoutConstraint.activate([
            topConstraint,
            leadingCsontraint,
            trailingConstraint,
            heightConstraint
        ])
        
        let sceneImageView = SceneImageView(imageView: imageView,
                                            topConstraint: topConstraint,
                                            leadingConstraint: leadingCsontraint,
                                            trailingConstraint: trailingConstraint,
                                            heightConstraint: heightConstraint)
        sceneImageViews.append(sceneImageView)
        
        viewModel.prepareForRequestImage()
        viewModel.imageRequestResults[index - 1]
            .subscribe(with: self, onNext: { strongSelf, resultImage in
                DispatchQueue.main.async {
                    // set previous scene image
                    let previouseScene = strongSelf.sceneImageViews[index - 1]
                    previouseScene.imageView.image = resultImage
                    previouseScene.imageView.backgroundColor = R.color.backgroundWhite()!
                    
                    // Resize image view by iamge resolution
                    previouseScene.heightConstraint.constant = strongSelf.fitHeight(resultImage)
                    strongSelf.updateContentViewHeight()
                    
                    // Update spacing
                    topConstraint.constant = strongSelf.spacing
                }
                
                strongSelf.viewModel.requestImage(index, scene.imagePath)
            })
            .disposed(by: disposeBag)
    }
    
    private func appendFirstScene(_ scene: ComicStripScene) {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.backgroundColor = UIColor.tilePatternColor
        
        contentView.addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        
        let topConstraint = imageView.topAnchor.constraint(equalTo: contentView.topAnchor)
        let leadingCsontraint = imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor)
        let trailingConstraint = imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor)
        let heightConstraint = imageView.heightAnchor.constraint(equalToConstant: self.frame.width * defaultSceneHeightProportion)
        
        NSLayoutConstraint.activate([
            topConstraint,
            leadingCsontraint,
            trailingConstraint,
            heightConstraint
        ])
        
        let sceneImageView = SceneImageView(imageView: imageView,
                                            topConstraint: topConstraint,
                                            leadingConstraint: leadingCsontraint,
                                            trailingConstraint: trailingConstraint,
                                            heightConstraint: heightConstraint)
        sceneImageViews.append(sceneImageView)
        viewModel.prepareForRequestImage()
        viewModel.requestImage(0, scene.imagePath)
    }
    
    private func updateContentViewHeight() {
        layoutIfNeeded()
        if let lastScene = sceneImageViews.last {
            let updatedHeight = lastScene.imageView.bottomY
            contentViewHeightConstraint.constant = updatedHeight
        }
        
        layoutIfNeeded()
    }
}

extension ComicStripScrollView {
    public func reload(scenes: [ComicStripScene]) {
        clearScenes()
        viewModel.updateScenes(scenes)
    }
    
    public func clearScenes() {
        sceneImageViews.forEach { scene in
            scene.imageView.removeFromSuperview()
        }
        
        sceneImageViews.removeAll()
        scrollToTop(topInset: contentInset.top, animated: false)
    }
}

extension ComicStripScrollView {
    private var emptyScene: ComicStripScene {
        return .init(imagePath: "")
    }
    
    private func removeLastScene() {
        if let emptyScene = sceneImageViews.last {
            emptyScene.imageView.removeFromSuperview()
            sceneImageViews.removeLast()
        }
    }
}

extension ComicStripScrollView {
    private func fitHeight(_ image: UIImage) -> CGFloat {
        let heightProportion = image.size.height / image.size.width
        return frame.width * heightProportion
    }
}

private extension UIView {
    var bottomY: CGFloat {
        return self.frame.origin.y + self.frame.height
    }
}
