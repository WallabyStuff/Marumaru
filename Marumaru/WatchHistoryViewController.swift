//
//  WatchHistoryViewController.swift
//  Marumaru
//
//  Created by 이승기 on 2021/04/19.
//

import UIKit

import Hero
import RxSwift
import RxCocoa

@objc protocol WatchHistoryViewDelegate: AnyObject {
    @objc optional func didWatchHistoryUpdated()
}

class WatchHistoryViewController: BaseViewController, ViewModelInjectable {
        
    
    // MARK: - Properties
    
    typealias ViewModel = WatchHistoryViewModel
    
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var watchHistoryCollectionView: UICollectionView!
    @IBOutlet weak var clearHistoryButton: UIButton!
    @IBOutlet weak var appbarViewHeightConstraint: NSLayoutConstraint!
    
    static let identifier = R.storyboard.watchHistory.watchHistoryStoryboard.identifier
    weak var delegate: WatchHistoryViewDelegate?
    var viewModel: ViewModel
    private var watchHistoryPlaceholderLabel = StickyPlaceholderLabel()
    
    
    // MARK: - Initializers
    
    required init(_ viewModel: WatchHistoryViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        dismiss(animated: true)
    }
    
    required init?(_ coder: NSCoder, _ viewModel: WatchHistoryViewModel) {
        self.viewModel = viewModel
        super.init(coder: coder)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    // MARK: - LifeCycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
        bind()
        setupData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.isHidden = true
    }
    
    
    // MARK: - Overrides
    
    override func viewDidDisappear(_ animated: Bool) {
        delegate?.didWatchHistoryUpdated?()
    }
    
    override func updateViewConstraints() {
        super.updateViewConstraints()
        configureAppbarViewConstraints()
    }
    
    
    // MARK: - Setups
    
    private func setup() {
        setupView()
    }
    
    private func setupView() {
        setupWatchHistoryCollectionView()
        setupClearHistoryButton()
    }
    
    private func setupWatchHistoryCollectionView() {
        let nibName = UINib(nibName: ComicThumbnailCollectionCell.identifier, bundle: nil)
        watchHistoryCollectionView.register(nibName, forCellWithReuseIdentifier: ComicThumbnailCollectionCell.identifier)
        
        watchHistoryCollectionView.register(WatchHistoryCollectionReusableView.self,
                                            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
                                            withReuseIdentifier: WatchHistoryCollectionReusableView.identifier)
        
        watchHistoryCollectionView.collectionViewLayout = watchHistoryCollectionViewLayout()
        watchHistoryCollectionView.contentInset = UIEdgeInsets(top: compactAppbarHeight + view.safeAreaInsets.top + 24,
                                                               left: 0, bottom: 0, right: 0)
        watchHistoryCollectionView.delegate = self
        watchHistoryCollectionView.dataSource = self
        
        viewModel.reloadWatchHistoryCollectionView = { [weak self] in
            self?.watchHistoryCollectionView.reloadData()
        }
    }
    
    private func setupClearHistoryButton() {
        clearHistoryButton.layer.masksToBounds = true
        clearHistoryButton.layer.cornerRadius = 8
        clearHistoryButton.hero.modifiers = [.scale(0)]
    }
    
    
    // MARK: - Configurations
    
    private func configureAppbarViewConstraints() {
        appbarViewHeightConstraint.constant = view.safeAreaInsets.top + compactAppbarHeight
    }
    
    
    // MARK: - Bind
    
    private func bind() {
        bindBackButton()
        bindClearHistoryButton()
        bindWatchHistoryCell()
    }
    
    private func bindBackButton() {
        backButton.rx.tap
            .asDriver()
            .drive(onNext: { [weak self] in
                self?.navigationController?.popViewController(animated: true)
            }).disposed(by: disposeBag)
    }
    
    private func bindClearHistoryButton() {
        clearHistoryButton.rx.tap
            .asDriver()
            .drive(onNext: { [weak self] in
                self?.presentClearHistoryActionSheet()
            })
            .disposed(by: disposeBag)
    }
    
    private func bindWatchHistoryCell() {
        watchHistoryCollectionView.rx.itemSelected
            .asDriver()
            .drive(with: self, onNext: { vc, indexPath in
                let watchHistory = vc.viewModel.watchHistoryCellItemForRow(at: indexPath)
                vc.presentComicStripVC(watchHistory.comicTitle, watchHistory.comicURL)
            }).disposed(by: disposeBag)
    }
    
    private func setupData() {
        reloadWatchHistories()
    }
    
    
    // MARK: - Methods
    
    private func reloadWatchHistories() {
        watchHistoryPlaceholderLabel.detatchLabel()
        
        self.viewModel.getWatchHistories()
            .subscribe(with: self, onError: { vc, error in
                if let error = error as? WatchHistoryViewError {
                    vc.watchHistoryPlaceholderLabel.attatchLabel(text: error.message, to: vc.watchHistoryCollectionView)
                }
            }).disposed(by: self.disposeBag)
    }
    
    private func clearHistory() {
        viewModel.clearHistories()
            .subscribe().disposed(by: disposeBag)
    }
    
    private func presentClearHistoryActionSheet() {
        let deleteMenu = UIAlertController(title: "기록 삭제", message: "삭제 버튼을 눌러 시청 기록을 삭제할 수 있습니다.\n삭제 후 데이터 복원은 어렵습니다.", preferredStyle: .actionSheet)
        
        let clearAction = UIAlertAction(title: "삭제", style: .destructive) { [weak self] _ in
            self?.clearHistory()
        }
        let cancelAction = UIAlertAction(title: "취소", style: .cancel)
        
        deleteMenu.addAction(clearAction)
        deleteMenu.addAction(cancelAction)
        deleteMenu.popoverPresentationController?.sourceView = clearHistoryButton!
        deleteMenu.popoverPresentationController?.sourceRect = (clearHistoryButton as AnyObject).bounds
        
        self.present(deleteMenu, animated: true)
    }
    
    private func presentComicStripVC(_ comicTitle: String, _ comicURL: String) {
        let storyboard = UIStoryboard(name: R.storyboard.comicStrip.name, bundle: nil)
        let comicStripVC = storyboard.instantiateViewController(identifier: ComicStripViewController.identifier,
                                                                creator: { coder -> ComicStripViewController in
            let viewModel = ComicStripViewModel(comicTitle: comicTitle, comicURL: comicURL)
            return .init(coder, viewModel) ?? ComicStripViewController(.init(comicTitle: "", comicURL: ""))
        })
        
        comicStripVC.delegate = self
        comicStripVC.modalPresentationStyle = .fullScreen
        navigationController?.pushViewController(comicStripVC, animated: true)
    }
}


// MARK: - Extensions

extension WatchHistoryViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return viewModel.numberOfSection
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.numberOfItemsIn(section: section)
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ComicThumbnailCollectionCell.identifier,
                                                            for: indexPath)
                as? ComicThumbnailCollectionCell else {
            return UICollectionViewCell()
        }
        
        let comicInfo = viewModel.watchHistoryCellItemForRow(at: indexPath)
        cell.titleLabel.text = comicInfo.comicTitle
        cell.thumbnailImagePlaceholderLabel.text = comicInfo.comicTitle

        let token = viewModel.requestImage(comicInfo.thumbnailImageURL) { result in
            do {
                let imageResult = try result.get()

                DispatchQueue.main.async {
                    cell.thumbnailImagePlaceholderLabel.isHidden = true
                    cell.thumbnailImageView.image = imageResult.imageCache.image
                    cell.thumbnailImageView.startFadeInAnimation(duration: 0.3)
                }
            } catch {
                DispatchQueue.main.async {
                    cell.thumbnailImagePlaceholderLabel.isHidden = false
                }
            }
        }
        
        cell.onReuse = { [weak self] in
            if let token = token {
                self?.viewModel.cancelImageRequest(token)
            }
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        guard let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: WatchHistoryCollectionReusableView.identifier, for: indexPath) as? WatchHistoryCollectionReusableView else {
            return UICollectionReusableView()
        }
        
        headerView.dateLabel.text = viewModel.watchHistoryCellItemForRow(at: indexPath).watchDateFormattedString
        
        return headerView
    }
}

extension WatchHistoryViewController {
    private func watchHistoryCollectionViewLayout() -> UICollectionViewCompositionalLayout {
        let layout = UICollectionViewCompositionalLayout { _, environment in
            let itemSize = NSCollectionLayoutSize(
                widthDimension: .absolute(136),
                heightDimension: .absolute(236))
            let item = NSCollectionLayoutItem(layoutSize: itemSize)
            
            let groupSize = NSCollectionLayoutSize(
                widthDimension: .absolute(136),
                heightDimension: .absolute(236))
            
            let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])
            group.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 12, bottom: 0, trailing: 12)
            group.interItemSpacing = .fixed(12)
            
            let supplymentaryItemSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(environment.container.contentSize.width),
                heightDimension: .absolute(44))
            let supplymentaryItem = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: supplymentaryItemSize, elementKind: UICollectionView.elementKindSectionHeader, alignment: .topLeading)
            
            let section = NSCollectionLayoutSection(group: group)
            section.orthogonalScrollingBehavior = .continuous
            section.boundarySupplementaryItems = [supplymentaryItem]
            section.interGroupSpacing = 4
            return section
        }
        
        return layout
    }
}

extension WatchHistoryViewController: ComicStripViewDelegate {
    func didWatchHistoryUpdated() {
        reloadWatchHistories()
    }
}
