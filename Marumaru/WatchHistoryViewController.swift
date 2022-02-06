//
//  HistoryMangaViewController.swift
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

class WatchHistoryViewController: UIViewController {
    
    // MARK: - Declarations
    @IBOutlet weak var appbarView: UIView!
    @IBOutlet weak var watchHistoryCollectionView: UICollectionView!
    @IBOutlet weak var clearHistoryButton: UIButton!
    @IBOutlet weak var backButton: UIButton!
    
    private let viewModel = WatchHistoryViewModel()
    weak var delegate: WatchHistoryViewDelegate?
    private var disposeBag = DisposeBag()
    private var watchHistoryPlaceholderLabel = StickyPlaceholderLabel()
    
    // MARK: - LifeCycle
    override func viewDidLoad() {
        super.viewDidLoad()
    
        setup()
        bind()
        setupData()
    }

    // MARK: - Overrides
    override func viewDidDisappear(_ animated: Bool) {
        delegate?.didWatchHistoryUpdated?()
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .darkContent
    }
    
    // MARK: - Setup
    private func setup() {
        setupView()
    }
    
    // MARK: - SetupView
    private func setupView() {
        setupHero()
        setupAppbarView()
        setupWatchHistoryCollectionView()
        setupClearHistoryButton()
        setupBackButton()
    }
    
    private func setupHero() {
        self.hero.isEnabled = true
    }
    
    private func setupAppbarView() {
        appbarView.hero.id = "appbar"
        appbarView.layer.cornerRadius = 24
        appbarView.layer.maskedCorners = CACornerMask([.layerMinXMaxYCorner])
    }
    
    private func setupWatchHistoryCollectionView() {
        let nibName = UINib(nibName: "MangaThumbnailCollectionViewCell", bundle: nil)
        watchHistoryCollectionView.register(nibName, forCellWithReuseIdentifier: MangaThumbnailCollectionCell.identifier)
        
        watchHistoryCollectionView.register(WatchHistoryCollectionReusableView.self,
                                            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: WatchHistoryCollectionReusableView.identifier)
        
        watchHistoryCollectionView.collectionViewLayout = watchHistoryCollectionViewLayout()
        watchHistoryCollectionView.contentInset = UIEdgeInsets(top: 28, left: 0, bottom: 0, right: 0)
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
    
    private func setupBackButton() {
        backButton.hero.id = "appbarButton"
        backButton.imageEdgeInsets(with: 10)
        backButton.layer.cornerRadius = 12
    }
    
    // MARK: - Bind
    private func bind() {
        bindClearHistoryButton()
        bindBackButton()
        bindWatchHistoryCell()
    }
    
    private func bindClearHistoryButton() {
        clearHistoryButton.rx.tap
            .asDriver()
            .drive(onNext: { [weak self] in
                self?.presentClearHistoryActionSheet()
            })
            .disposed(by: disposeBag)
    }
    
    private func bindBackButton() {
        backButton.rx.tap
            .asDriver()
            .drive(onNext: { [weak self] in
                self?.dismiss(animated: true, completion: nil)
            })
            .disposed(by: disposeBag)
    }
    
    private func bindWatchHistoryCell() {
        watchHistoryCollectionView.rx.itemSelected
            .asDriver()
            .drive(with: self, onNext: { vc, indexPath in
                let watchHistory = vc.viewModel.watchHistoryCellItemForRow(at: indexPath)
                vc.presentPlayMangaVC(watchHistory.mangaTitle, watchHistory.mangaUrl)
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
    
    private func presentPlayMangaVC(_ mangaTitle: String, _ mangaUrl: String) {
        let viewModel = PlayMangaViewModel(mangaTitle: mangaTitle, link: mangaUrl)
        
        guard let playMangaVC = storyboard?.instantiateViewController(identifier: "ViewMangaStoryboard", creator: { coder in
            PlayMangaViewController(
                coder: coder, viewModel: viewModel)
        }) else { return }
                
        playMangaVC.delegate = self
        playMangaVC.modalPresentationStyle = .fullScreen
        present(playMangaVC, animated: true, completion: nil)
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
        guard let mangaCollectionCell = collectionView.dequeueReusableCell(withReuseIdentifier: MangaThumbnailCollectionCell.identifier, for: indexPath) as? MangaThumbnailCollectionCell else { return UICollectionViewCell() }
        
        let mangaInfo = viewModel.watchHistoryCellItemForRow(at: indexPath)
        
        mangaCollectionCell.titleLabel.text = mangaInfo.mangaTitle
        mangaCollectionCell.thumbnailImagePlaceholderLabel.text = mangaInfo.mangaTitle

        let token = viewModel.requestImage(mangaInfo.thumbnailImageUrl) { result in
            do {
                let imageResult = try result.get()

                DispatchQueue.main.async {
                    mangaCollectionCell.thumbnailImagePlaceholderLabel.isHidden = true
                    mangaCollectionCell.thumbnailImageView.image = imageResult.imageCache.image
                    mangaCollectionCell.thumbnailImageView.startFadeInAnimation(duration: 0.3)
                }
            } catch {
                DispatchQueue.main.async {
                    mangaCollectionCell.thumbnailImagePlaceholderLabel.isHidden = false
                }
            }
        }
        
        mangaCollectionCell.onReuse = { [weak self] in
            if let token = token {
                self?.viewModel.cancelImageRequest(token)
            }
        }
        
        return mangaCollectionCell
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

extension WatchHistoryViewController: PlayMangaViewDelegate {
    func didWatchHistoryUpdated() {
        reloadWatchHistories()
    }
}
