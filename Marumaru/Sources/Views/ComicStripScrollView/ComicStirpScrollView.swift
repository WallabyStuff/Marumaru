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
    private var previousBaseViewFrame: CGRect = .zero
    private var previousContentOffset: CGPoint = .zero
    private var previousContentViewFrame: CGRect = .zero
    
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
        contentView.backgroundColor = .white
        
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
    }
    
    private func bindScenes() {
        viewModel.scenes
            .subscribe(with: self, onNext: { strongSelf, scenes in
                strongSelf.loadScenes(scenes)
            })
            .disposed(by: disposeBag)
    }
    

    // MARK: - Constraints
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // Actual size did change
        if frame != previousBaseViewFrame {
            previousBaseViewFrame = frame
            previousContentOffset = contentOffset
            previousContentViewFrame = contentView.frame
            
            configureSceneConstraints()
            updateContentOffset()
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
    
    private func updateContentOffset() {
        // Update scroll position
        let newOffsetY = previousContentOffset.y * contentView.frame.height / previousContentViewFrame.height
        let newOffset = CGPoint(x: 0, y: newOffsetY)
        setContentOffset(newOffset, animated: false)
    }

    
    // MARK: - Methods
    
    private func loadScenes(_ scenes: [ComicStripScene]) {
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
        
        let url = MarumaruApiService.shared.getImageURL(scene.imagePath)
        imageView.kf.setImage(with: url) { [weak self] result in
            guard let self = self else { return }
            
            do {
                let result = try result.get()
                let resultImage = result.image
                
                // Resize image view by iamge resolution
                heightConstraint.constant = self.fitHeight(resultImage)
                self.updateContentViewHeight()
                
                // Update spacing
                topConstraint.constant = self.spacing
            } catch {
                print(error.localizedDescription)
            }
        }
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
        
        let url = MarumaruApiService.shared.getImageURL(scene.imagePath)
        imageView.kf.setImage(with: url) { [weak self] result in
            guard let self = self else { return }

            do {
                let result = try result.get()
                let resultImage = result.image
                
                // Resize image view by iamge resolution
                heightConstraint.constant = self.fitHeight(resultImage)
                self.updateContentViewHeight()
            } catch {
                print(error.localizedDescription)
            }
        }
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
    public func setScenes(_ scenes: [ComicStripScene]) {
        clearScenes()
        viewModel.updateScenes(scenes)
    }
    
    public func clearScenes() {
        sceneImageViews.forEach { scene in
            scene.imageView.removeFromSuperview()
        }
        
        sceneImageViews.removeAll()
        let safeAreaTop = UIApplication.shared.windows.first?.safeAreaInsets.top ?? 0
        scrollToTop(topInset: AppbarHeight.compactAppbarHeight.rawValue + safeAreaTop,
                    animated: false)
    }
}

extension ComicStripScrollView {
    public func stopLoadingScenes() {
        sceneImageViews.forEach { sceneImageView in
            sceneImageView.imageView.kf.cancelDownloadTask()
        }
    }
    
    public func resumeLoadingScenes() {
        loadScenes(viewModel.scenes.value)
    }
}

extension ComicStripScrollView {
    private func fitHeight(_ image: UIImage) -> CGFloat {
        let heightProportion = image.size.height / image.size.width
        return frame.width * heightProportion
    }
}

extension ComicStripScrollView {
    func disableScrollView() {
        isUserInteractionEnabled = false
        isScrollEnabled = false
        maximumZoomScale = 1
        minimumZoomScale = 1
        showsVerticalScrollIndicator = false
        showsHorizontalScrollIndicator = false
    }
    
    func enableScrollView() {
        isUserInteractionEnabled = true
        isScrollEnabled = true
        maximumZoomScale = 3
        minimumZoomScale = 1
        showsVerticalScrollIndicator = true
        showsHorizontalScrollIndicator = true
    }
}

private extension UIView {
    var bottomY: CGFloat {
        return self.frame.origin.y + self.frame.height
    }
}
