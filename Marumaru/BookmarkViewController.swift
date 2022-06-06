//
//  BookmarkViewController.swift
//  Marumaru
//
//  Created by 이승기 on 2022/06/06.
//

import UIKit

class BookmarkViewController: BaseViewController, ViewModelInjectable {

    
    // MARK: - Properties
    
    static let identifier = R.storyboard.bookmark.bookmarkStoryboard.identifier
    typealias ViewModel = BookmarkViewModel
    
    @IBOutlet weak var bookmarkCollectionView: UICollectionView!
    
    var viewModel: BookmarkViewModel
    let collectionViewSideInset: CGFloat = 12
    let collecitonViewTopInset: CGFloat = 24
    let collectionViewBottomInset: CGFloat = 24
    let cellSpacing: CGFloat = 0
    let cellLineSpacing: CGFloat = 12
    
    
    // MARK: - Initializers
    
    required init?(_ coder: NSCoder, _ viewModel: BookmarkViewModel) {
        self.viewModel = viewModel
        super.init(coder: coder)
    }
    
    
    required init(_ viewModel: BookmarkViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        navigationController?.popViewController(animated: true)
        dismiss(animated: true)
    }
    
    required init?(coder: NSCoder) {
        fatalError("ViewModel has not been implemented")
    }

    
    // MARK: - LifeCycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
        bind()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        viewModel.updateBookmarks()
    }
    
    
    // MARK: - Setups
    
    private func setup() {
        setupView()
    }
    
    private func setupView() {
        setupBookmarkCollectionView()
    }
    
    private func setupBookmarkCollectionView() {
        registerBookmarkCollectionCell()
        bookmarkCollectionView.contentInset = .init(top: collecitonViewTopInset,
                                                    left: collectionViewSideInset,
                                                    bottom: collectionViewBottomInset,
                                                    right: collectionViewSideInset)
        bookmarkCollectionView.collectionViewLayout = flowLayout()
    }
    
    private func registerBookmarkCollectionCell() {
        let nibName = UINib(nibName: R.nib.comicThumbnailCollectionCell.name, bundle: nil)
        bookmarkCollectionView.register(nibName, forCellWithReuseIdentifier: ComicThumbnailCollectionCell.identifier)
    }
    
    
    // MARK: - Binds
    
    private func bind() {
        bindBookmarks()
        bindBookmarkCell()
        bindNoticeLabel()
        bindUpdateConstraints()
    }
    
    private func bindBookmarks() {
        viewModel.bookmarksObservable
            .bind(to: bookmarkCollectionView.rx.items(cellIdentifier: ComicThumbnailCollectionCell.identifier, cellType: ComicThumbnailCollectionCell.self)) { [weak self] _, bookmark, cell in
                guard let self = self else { return }
                
                cell.thumbnailImageView.layer.cornerRadius = 6
                cell.thumbnailImagePlaceholderLabel.text = bookmark.title
                cell.titleLabel.text = bookmark.title
                
                let url = self.viewModel.getImageURL(bookmark.thumbnailImagePath)
                cell.thumbnailImageView.kf.setImage(with: url, options: [.transition(.fade(0.3))]) { result in
                    do {
                        let result = try result.get()
                        let image = result.image
                        cell.thumbnailImagePlaceholderView.setThumbnailShadow(with: image.averageColor)
                        cell.thumbnailImagePlaceholderLabel.isHidden = true
                    } catch {
                        cell.thumbnailImagePlaceholderLabel.isHidden = false
                    }
                }
                
                cell.onReuse = {
                    cell.thumbnailImageView.kf.cancelDownloadTask()
                }
            }
            .disposed(by: disposeBag)
    }
    
    private func bindBookmarkCell() {
        bookmarkCollectionView.rx
            .itemSelected
            .subscribe(with: self, onNext: { vc, indexPath in
                vc.viewModel.bookmarkItemSelected(indexPath)
            })
            .disposed(by: disposeBag)
        
        viewModel.presentComicDetailVCObservable
            .subscribe(with: self, onNext: { vc, comicInfo in
                vc.presentComicDetailVC(comicInfo)
            })
            .disposed(by: disposeBag)
    }
    
    private func bindNoticeLabel() {
        viewModel.bookmarksObservable
            .subscribe(with: self, onNext: { vc, bookmarks in
                if bookmarks.isEmpty {
                    vc.view.makeNoticeLabel("message.emptyBookmark".localized())
                } else {
                    vc.view.removeNoticeLabels()
                }
            })
            .disposed(by: disposeBag)
    }
    
    private func bindUpdateConstraints() {
        baseFrameSizeViewSizeDidChange
            .subscribe(with: self, onNext: { vc, _ in
                vc.bookmarkCollectionView.collectionViewLayout = vc.flowLayout()
            })
            .disposed(by: disposeBag)
    }
    
    
    // MARK: - Methods
    
    private func flowLayout() -> UICollectionViewFlowLayout {
        let estimatedCellWidth: CGFloat = 112
        let estimatedNumberOfCellInLine = floor((view.frame.width - collectionViewSideInset * 2) / estimatedCellWidth)
        let cellWidth = (view.frame.width - collectionViewSideInset * 2) / estimatedNumberOfCellInLine
        let cellHeight = (cellWidth  * 236) / 136
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.minimumLineSpacing = 0
        flowLayout.minimumInteritemSpacing = 0
        flowLayout.itemSize = CGSize(width: cellWidth, height: cellHeight)
        
        return flowLayout
    }
    
    private func presentComicDetailVC(_ comicInfo: ComicInfo) {
        let storyboard = UIStoryboard(name: R.storyboard.comicDetail.name, bundle: nil)
        let viewController = storyboard.instantiateViewController(identifier: ComicDetailViewController.identifier,
                                                                  creator: { coder -> ComicDetailViewController in
            let viewModel = ComicDetailViewModel(comicInfo: comicInfo)
            return .init(coder, viewModel) ?? ComicDetailViewController(viewModel)
        })
        
        viewController.delegate = self
        present(viewController, animated: true)
    }
}

extension BookmarkViewController: ComicDetailViewDelegate {
    func didBookmarkStateUpdate() {
        viewModel.updateBookmarks()
    }
}
