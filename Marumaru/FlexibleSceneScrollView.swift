//
//  SceneScrollView.swift
//  Marumaru
//
//  Created by 이승기 on 2021/08/25.
//

import UIKit
import RxSwift
import RxCocoa

class FlexibleSceneScrollView: UIScrollView {

    // MARK: - Declaration
    public var contentView = UIView()
    private var contentViewHeightConstraint = NSLayoutConstraint()
    
    private var disposeBag = DisposeBag()
    var sceneArr = [MangaScene]()
    var cellList = [FlexibleSceneScrollViewCell]()
    
    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
      
        setup()
        initEventListener()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        setup()
        initEventListener()
    }
    
    deinit {
        cellList.forEach { scene in
            scene.removeFromSuperview()
        }
    }
    
    // MARK: - Setup
    private func setup() {
        setupContentView()
    }
    
    private func setupContentView() {
        translatesAutoresizingMaskIntoConstraints = false
        
        contentView.backgroundColor = R.color.backgroundWhite()
        addSubview(contentView)
        contentView.translatesAutoresizingMaskIntoConstraints = false
        contentView.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        contentView.leadingAnchor.constraint(equalTo: self.leadingAnchor).isActive = true
        contentView.trailingAnchor.constraint(equalTo: self.trailingAnchor).isActive = true
        contentView.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
        contentView.widthAnchor.constraint(equalTo: self.widthAnchor).isActive = true
        contentViewHeightConstraint = contentView.heightAnchor.constraint(equalToConstant: self.frame.height)
        contentViewHeightConstraint.isActive = true
    }
    
    private func initEventListener() {
        /// detect oriantation changed and resize the cells
        NotificationCenter.default.rx.notification(UIDevice.orientationDidChangeNotification)
            .subscribe(onNext: { [weak self] _ in
                guard let self = self else { return }
                for cell in self.cellList {
                    cell.updateCellHeight()
                }
            }).disposed(by: disposeBag)
    }
    
    private func loadCells() {
        /// Load scene image cells
        for (index, scene) in sceneArr.enumerated() {
            let cell = FlexibleSceneScrollViewCell(parentContentView: contentView, imageUrl: scene.sceneImageUrl)
            cell.delegate = self
            
            if index == 0 {
                cell.appendCell(index: index, previousCell: nil)
            } else {
                cell.appendCell(index: index, previousCell: cellList[index - 1])
            }
            
            cellList.append(cell)
        }
    }
}

extension FlexibleSceneScrollView {
    public func reloadData() {
        disableZoom()
        isScrollEnabled = false
        
        loadCells()
        
        isScrollEnabled = true
        enableZoom()
    }
    
    public func clearAndReloadData() {
        cellList.forEach { cell in
            cell.removeFromSuperview()
        }
        
        sceneArr.removeAll()
        cellList.removeAll()
        
        reloadData()
    }
}

extension FlexibleSceneScrollView {
    public func enableZoom() {
        minimumZoomScale = 1
        maximumZoomScale = 3
    }
    
    public func disableZoom() {
        minimumZoomScale = 1
        maximumZoomScale = 1
    }
}

/// to update ContentView height
extension FlexibleSceneScrollView: FlexibleSceneScrollViewDelegate {
    /// dettect cell did appended & cell image did loaded
    func cellUpdated(bottomOffsetY: CGFloat) {
        contentViewHeightConstraint.constant = bottomOffsetY
    }
}
