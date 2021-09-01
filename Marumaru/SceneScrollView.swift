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
    
    // MARK: - Declaration
    var disposeBag = DisposeBag()
    var sceneArr = [MangaScene]()
    var cellArr = [SceneScrollViewCell]()
    
    var contentView = UIView()
    var contentViewHeightConstraint = NSLayoutConstraint()
    
    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
      
        setUpScrollView()
        initEventListener()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        setUpScrollView()
        initEventListener()
    }
    
    deinit {
        cellArr.forEach { scene in
            scene.removeFromSuperview()
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        
    }
    
    private func initEventListener() {
        /// detect oriantation changed and resize the cells
        NotificationCenter.default.rx.notification(UIDevice.orientationDidChangeNotification)
            .subscribe(onNext: { [weak self] _ in
                guard let self = self else { return }
                for cell in self.cellArr {
                    cell.updateCellHeight()
                }
            }).disposed(by: disposeBag)
    }
    
    // MARK: - Method
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
    }
    
    private func loadCells() {
        /// Load scene image cells
        for (index, scene) in sceneArr.enumerated() {
            let cell = SceneScrollViewCell(parentContentView: contentView, imageUrl: scene.sceneImageUrl)
            cell.delegate = self
            
            if index == 0 {
                cell.appendCell(index: index, previousCell: nil)
            } else {
                cell.appendCell(index: index, previousCell: cellArr[index - 1])
            }
            
            cellArr.append(cell)
        }
    }
    
    func reloadData() {
        disableZoom()
        isScrollEnabled = false
        
        loadCells()
        
        isScrollEnabled = true
        enableZoom()
    }
    
    func clearReloadData() {
        /// detatch all the cells from contentView
        cellArr.forEach { cell in
            cell.removeFromSuperview()
        }
        
        sceneArr.removeAll()
        cellArr.removeAll()
        
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

// MARK: - Extension
/// to update ContentView height
extension SceneScrollView: SceneScrollViewCellDelegate {
    /// dettect cell did appended & cell image did loaded
    func cellUpdated(bottomOffsetY: CGFloat) {
        contentViewHeightConstraint.constant = bottomOffsetY
    }
}
