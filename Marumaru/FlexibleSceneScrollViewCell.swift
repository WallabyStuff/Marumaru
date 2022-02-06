//
//  ScrollViewCell.swift
//  Marumaru
//
//  Created by 이승기 on 2021/08/27.
//

import UIKit

import RxSwift

@objc protocol FlexibleSceneScrollViewDelegate: AnyObject {
    @objc optional func cellUpdated(bottomOffsetY: CGFloat)
}

class FlexibleSceneScrollViewCell: UIView {
    
    // MARK: - Declaration
    private let viewModel = FlexibleSceneScrollViewCellModel()
    
    /// scrollView for superView
    private var parentContentView: UIView?
    private var sceneImageView = UIImageView()
    
    private var disposeBag = DisposeBag()
    weak var delegate: FlexibleSceneScrollViewDelegate?
    
    private let networkHandler = MarumaruApiService()
    open var imageUrl: String?
    open var sceneImage = BehaviorSubject<UIImage?>(value: nil)
    /// vertical cell spacing
    open var spacing: CGFloat = 16
    
    /// cell constraints
    private var topConstraint = NSLayoutConstraint()
    private var widthConstraint = NSLayoutConstraint()
    private var heightCosntraint = NSLayoutConstraint()
    /// cell height proportion (default : 1.4)
    private var heightPorportion: CGFloat = 1.4
    private var widthProportion: CGFloat = 1
    
    private var imageRequestToken: UUID?
    private var cancelIamgeRequest: (() -> Void)?
    
    // MARK: - Initialization
    convenience init(parentContentView: UIView, imageUrl: String) {
        self.init(frame: .zero)
        
        self.parentContentView = parentContentView
        self.imageUrl = imageUrl
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    convenience init() {
        self.init(frame: CGRect.zero)
    }
    
    deinit {
        if let token = imageRequestToken {
            networkHandler.cancelImageRequest(token)
        }
    }
    
    // MARK: - Methods
    /// prepareForCell for image loading (Placeholder Cell)
    public func prepareForCell(index: Int, previousCell: FlexibleSceneScrollViewCell?) {
        guard let parentContentView = parentContentView else { return }
        
        /// draw ContentView
        self.backgroundColor = UIColor.tilePatternColor
        parentContentView.addSubview(self)
        
        if index == 0 {
            self.translatesAutoresizingMaskIntoConstraints = false
            
            self.centerXAnchor.constraint(equalTo: parentContentView.centerXAnchor).isActive = true
            
            self.topConstraint = topAnchor.constraint(equalTo: parentContentView.topAnchor, constant: 0)
            self.topConstraint.isActive = true
            
            self.widthConstraint = widthAnchor.constraint(equalTo: parentContentView.widthAnchor, multiplier: widthProportion)
            self.widthConstraint.isActive = true
            
            self.heightCosntraint = heightAnchor.constraint(equalToConstant: parentContentView.frame.width * heightPorportion)
            self.heightCosntraint.isActive = true
        } else {
            guard let previousCell = previousCell else { return }
            
            self.translatesAutoresizingMaskIntoConstraints = false
            
            self.centerXAnchor.constraint(equalTo: previousCell.centerXAnchor).isActive = true
            
            self.topConstraint = topAnchor.constraint(equalTo: previousCell.bottomAnchor, constant: 0)
            self.topConstraint.isActive = true
            
            self.widthConstraint = widthAnchor.constraint(equalTo: parentContentView.widthAnchor, multiplier: widthProportion)
            self.widthConstraint.isActive = true
            
            self.heightCosntraint = heightAnchor.constraint(equalToConstant: parentContentView.frame.width * heightPorportion)
            self.heightCosntraint.isActive = true
        }
        
        // darw ImageView
        sceneImageView.contentMode = .scaleAspectFit
        self.addSubview(sceneImageView)
        sceneImageView.translatesAutoresizingMaskIntoConstraints = false
        sceneImageView.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        sceneImageView.leadingAnchor.constraint(equalTo: self.leadingAnchor).isActive = true
        sceneImageView.trailingAnchor.constraint(equalTo: self.trailingAnchor).isActive = true
        sceneImageView.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
        
        delegate?.cellUpdated?(bottomOffsetY: bottomY)
    }
    
    /// appendCell
    public func appendCell(index: Int, previousCell: FlexibleSceneScrollViewCell?) {
        prepareForCell(index: index, previousCell: previousCell)
        
        if let imageUrl = imageUrl {
            let token = viewModel.requestImage(imageUrl) { [weak self] result in
                guard let self = self else { return }
                
                do {
                    let resultImage = try result.get()
                    
                    if index == 0 {
                        self.setImage(resultImage.imageCache)
                    } else {
                        if try previousCell?.sceneImage.value() != nil {
                            self.setImage(resultImage.imageCache)
                        } else {
                            previousCell?.sceneImage
                                .subscribe(onNext: { [weak self] value in
                                    if value != nil {
                                        self?.setImage(resultImage.imageCache)
                                    }
                                }).disposed(by: self.disposeBag)
                        }
                    }
                } catch {
                    print(error.localizedDescription)
                }
            }
            
            cancelIamgeRequest = { [weak self] in
                if let token = token {
                    self?.viewModel.cancelImageRequest(token)
                }
            }
        }
    }
    
    /// set loaded Image with resize cell height
    public func setImage(_ imageCache: ImageCache) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            self.heightPorportion = imageCache.image.size.height / imageCache.image.size.width
            self.updateCellHeight()
            
            self.backgroundColor = R.color.backgroundWhite()
            self.sceneImageView.image = imageCache.image
            
            /// notify to next cell that previous cell image did loaded
            self.sceneImage.onNext(imageCache.image)
            
            /// update ScrollView contentView height
            self.delegate?.cellUpdated?(bottomOffsetY: self.frame.origin.y + self.frame.height + self.spacing)
        }
    }
    
    public func updateCellHeight() {
        let accurateCellHeight = self.frame.width * self.heightPorportion
        self.heightCosntraint.constant = accurateCellHeight
        self.topConstraint.constant = self.spacing
        
        /// update ScrollView contentView height
        delegate?.cellUpdated?(bottomOffsetY: bottomY + self.spacing)
    }
}

extension UIView {
    var bottomY: CGFloat {
        return self.frame.origin.y + self.frame.height
    }
}
