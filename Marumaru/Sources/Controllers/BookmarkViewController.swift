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
  
  var viewModel: BookmarkViewModel
  private let collectionViewSideInset: CGFloat = 12
  private let collectionViewTopInset: CGFloat = 24
  private let collectionViewBottomInset: CGFloat = 24
  private let cellSpacing: CGFloat = 0
  private let cellLineSpacing: CGFloat = 12
  
  
  // MARK: - UI
  
  @IBOutlet weak var bookmarkCollectionView: UICollectionView!
  
  
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
    bookmarkCollectionView.contentInset = .init(top: collectionViewTopInset,
                                                left: collectionViewSideInset,
                                                bottom: collectionViewBottomInset,
                                                right: collectionViewSideInset)
    bookmarkCollectionView.collectionViewLayout = flowLayout()
  }
  
  private func registerBookmarkCollectionCell() {
    let nibName = UINib(nibName: R.nib.comicEpisodeThumbnailCollectionCell.name, bundle: nil)
    bookmarkCollectionView.register(nibName, forCellWithReuseIdentifier: ComicEpisodeThumbnailCollectionCell.identifier)
  }
  
  
  // MARK: - Binds
  
  private func bind() {
    bindBookmarks()
    bindBookmarkCell()
    bindNoticeLabel()
    bindUpdateConstraints()
  }
  
  private func bindBookmarks() {
    viewModel.bookmarks
      .bind(to: bookmarkCollectionView.rx.items(cellIdentifier: ComicEpisodeThumbnailCollectionCell.identifier, cellType: ComicEpisodeThumbnailCollectionCell.self)) { _, bookmark, cell in
        cell.configure(with: bookmark.convertToComicEpisode())
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
    
    viewModel.presentComicDetailVC
      .subscribe(with: self, onNext: { vc, comicInfo in
        vc.presentComicDetailVC(comicInfo)
      })
      .disposed(by: disposeBag)
  }
  
  private func bindNoticeLabel() {
    viewModel.bookmarks
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
