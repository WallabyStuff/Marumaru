//
//  ScrollViewCell.swift
//  Marumaru
//
//  Created by 이승기 on 2021/08/27.
//

import UIKit

import RxSwift

protocol SceneScrollViewCellDelegate: AnyObject {
    func cellUpdated(bottomOffsetY: CGFloat)
}

class SceneScrollViewCell: UIView {
    
    // MARK: - Declaration
    /// scrollView for superView
    private var parentContentView: UIView?
    private var sceneImageView = UIImageView()
    
    private var disposeBag = DisposeBag()
    weak var delegate: SceneScrollViewCellDelegate?
    
    private let networkHandler = NetworkHandler()
    open var imageUrl: String?
    open var sceneImage = BehaviorSubject<UIImage?>(value: nil)
    /// vertical cell spacing
    open var spacing: CGFloat = 15
    
    /// cell constraints
    private var topConstraint = NSLayoutConstraint()
    private var widthConstraint = NSLayoutConstraint()
    private var heightCosntraint = NSLayoutConstraint()
    /// cell height proportion (default : 1.4)
    private var heightPorportion: CGFloat = 1.4
    private var widthProportion: CGFloat = 1
    
    private var imageRequestToken: UUID?
    
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
            networkHandler.cancelLoadImage(token)
        }
    }
    
    // MARK: - Methods
    /// prepareForCell for image loading (Placeholder Cell)
    public func prepareForCell(index: Int, previousCell: SceneScrollViewCell?) {
        guard let parentContentView = parentContentView else { return }
        
        /// draw ContentView
        self.backgroundColor = ColorSet.patternedTile
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
        
        if let delegate = delegate {
            delegate.cellUpdated(bottomOffsetY: self.frame.origin.y + self.frame.height)
        }
    }
    
    /// appendCell
    public func appendCell(index: Int, previousCell: SceneScrollViewCell?) {
        prepareForCell(index: index, previousCell: previousCell)
        
        if let imageUrl = imageUrl, let url = URL(string: imageUrl) {
            let token = networkHandler.getImage(url) { [weak self] result in
                guard let self = self else { return }
                
                DispatchQueue.global(qos: .background).async { [weak self] in
                    guard let self = self else { return }
                    do {
                        let result = try result.get()
                        DispatchQueue.main.async { [weak self] in
                            guard let self = self else { return }
                            if index == 0 {
                                self.setImage(result.imageCache)
                            } else {
                                do {
                                    if try previousCell?.sceneImage.value() != nil {
                                        self.setImage(result.imageCache)
                                    } else {
                                        /// hold on until previous cell image to load
                                        previousCell?.sceneImage
                                            .subscribe(onNext: { [weak self] value in
                                                if value != nil {
                                                    self?.setImage(result.imageCache)
                                                }
                                            }).disposed(by: self.disposeBag)
                                    }
                                } catch {
                                    print(error)
                                }
                            }
                        }
                    } catch {
                        print(error)
                    }
                }
            }
            
            imageRequestToken = token
        }
    }
    
    /// set loaded Image with resize cell height
    public func setImage(_ imageCache: ImageCache) {
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            self.heightPorportion = imageCache.image.size.height / imageCache.image.size.width
            self.updateCellHeight()
            
            self.backgroundColor = ColorSet.backgroundColor
            self.sceneImageView.image = imageCache.image
            
            /// notify to next cell that previous cell image did loaded
            self.sceneImage.onNext(imageCache.image)
            
            /// update ScrollView contentView height
            if let delegate = self.delegate {
                delegate.cellUpdated(bottomOffsetY: self.frame.origin.y + self.frame.height + self.spacing)
            }
        }
    }
    
    public func updateCellHeight() {
        let accurateCellHeight = self.frame.width * self.heightPorportion
        self.heightCosntraint.constant = accurateCellHeight
        self.topConstraint.constant = self.spacing
        
        /// update ScrollView contentView height
        if let delegate = self.delegate {
            delegate.cellUpdated(bottomOffsetY: self.frame.origin.y + self.frame.height + self.spacing)
        }
    }
}
