//
//  WatchHistoryViewController.swift
//  Marumaru
//
//  Created by 이승기 on 2021/04/19.
//

import UIKit

import RxSwift
import RxCocoa
import RxDataSources

class WatchHistoryViewController: BaseViewController, ViewModelInjectable {
        
    
    // MARK: - Properties
    
    typealias ViewModel = WatchHistoryViewModel
    
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var watchHistoryCollectionView: UICollectionView!
    @IBOutlet weak var clearHistoryButton: UIButton!
    @IBOutlet weak var appbarViewHeightConstraint: NSLayoutConstraint!
    
    static let identifier = R.storyboard.watchHistory.watchHistoryStoryboard.identifier
    var viewModel: ViewModel
    private var dataSource: RxCollectionViewSectionedAnimatedDataSource<WatchHistorySection>?
    
    
    // MARK: - Initializers
    
    required init(_ viewModel: WatchHistoryViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        dismiss(animated: true)
    }
    
    required init?(_ coder: NSCoder, _ viewModel: WatchHistoryViewModel) {
        self.viewModel = viewModel
        super.init(coder: coder)
        dataSource = dataSourceFactory()
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
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.isHidden = true
        viewModel.updateWatchHistories()
    }
    
    
    // MARK: - Overrides
    
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
        
        watchHistoryCollectionView.register(WatchHistoryCollectionReusableView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: WatchHistoryCollectionReusableView.identifier)
    }
    
    private func setupClearHistoryButton() {
        clearHistoryButton.layer.masksToBounds = true
        clearHistoryButton.layer.cornerRadius = 8
    }
    
    
    // MARK: - Configurations
    
    private func configureAppbarViewConstraints() {
        appbarViewHeightConstraint.constant = view.safeAreaInsets.top + compactAppbarHeight
    }
    
    
    // MARK: - Bind
    
    private func bind() {
        bindBackButton()
        bindClearHistoryButton()
        bindWatchHistoryCollectionView()
    }
    
    private func bindBackButton() {
        backButton.rx.tap
            .asDriver()
            .debug()
            .drive(with: self, onNext: { vc, _  in
                vc.navigationController?.popViewController(animated: true)
            }).disposed(by: disposeBag)
    }
    
    private func bindClearHistoryButton() {
        clearHistoryButton.rx.tap
            .asDriver()
            .drive(with: self, onNext: { vc, _ in
                vc.presentClearHistoryActionSheet()
            })
            .disposed(by: disposeBag)
    }
    
    private func bindWatchHistoryCollectionView() {
        watchHistoryCollectionView.rx.itemSelected
            .asDriver()
            .drive(with: self, onNext: { vc, indexPath in
                vc.viewModel.comicItemSelected(indexPath)
            }).disposed(by: disposeBag)
        
        viewModel.presentComicStrip
            .subscribe(with: self, onNext: { vc, comic in
                vc.presentComicStripVC(comic)
            })
            .disposed(by: disposeBag)
        
        viewModel.watchHistoriesObservable
            .bind(to: watchHistoryCollectionView.rx.items(dataSource: dataSource!))
            .disposed(by: disposeBag)
        
        viewModel.watchHistoriesObservable
            .subscribe(with: self, onNext: { vc, comics in
                if comics.isEmpty {
                    vc.view.makeNoticeLabel("시청기록이 없습니다.")
                } else {
                    vc.view.removeNoticeLabels()
                }
            })
            .disposed(by: disposeBag)
    }
    
    
    // MARK: - Methods
    
    private func dataSourceFactory() -> RxCollectionViewSectionedAnimatedDataSource<WatchHistorySection> {
        let dataSource = RxCollectionViewSectionedAnimatedDataSource<WatchHistorySection>(configureCell: { [weak self] _, _, indexPath, comic in
            if comic.isInvalidated { return UICollectionViewCell() }
            
            guard let self = self,
                  let cell = self.watchHistoryCollectionView.dequeueReusableCell(withReuseIdentifier: ComicThumbnailCollectionCell.identifier, for: indexPath) as? ComicThumbnailCollectionCell else {
                return UICollectionViewCell()
            }
            
            cell.titleLabel.text = comic.episodeTitle
            cell.thumbnailImagePlaceholderLabel.text = comic.episodeTitle

            let token = self.viewModel.requestImage(comic.thumbnailImageURL) { result in
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
        }, configureSupplementaryView: { [weak self] _, collectionView, _, indexPath in
            guard let self = self else { return .init() }
            
            guard let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: WatchHistoryCollectionReusableView.identifier, for: indexPath) as? WatchHistoryCollectionReusableView else {
                return UICollectionReusableView()
            }

            headerView.dateLabel.text = self.viewModel.sectionHeader(indexPath)
            return headerView
        })
        
        return dataSource
    }
    
    private func presentClearHistoryActionSheet() {
        let deleteMenu = UIAlertController(title: "기록 삭제", message: "삭제 버튼을 눌러 시청 기록을 삭제할 수 있습니다.\n삭제 후 데이터 복원은 어렵습니다.", preferredStyle: .actionSheet)
        
        let clearAction = UIAlertAction(title: "삭제", style: .destructive) { [weak self] _ in
            self?.viewModel.clearHistories()
        }
        let cancelAction = UIAlertAction(title: "취소", style: .cancel)
        
        deleteMenu.addAction(clearAction)
        deleteMenu.addAction(cancelAction)
        deleteMenu.popoverPresentationController?.sourceView = clearHistoryButton!
        deleteMenu.popoverPresentationController?.sourceRect = (clearHistoryButton as AnyObject).bounds
        
        self.present(deleteMenu, animated: true)
    }
    
    private func presentComicStripVC(_ comic: WatchHistory) {
        let storyboard = UIStoryboard(name: R.storyboard.comicStrip.name, bundle: nil)
        let comicStripVC = storyboard.instantiateViewController(identifier: ComicStripViewController.identifier,
                                                                creator: { coder -> ComicStripViewController in
            let episode = Episode(title: comic.episodeTitle, serialNumber: "")
            let viewModel = ComicStripViewModel(episode: episode,
                                                episodeURL: comic.episodeURL)
            return .init(coder, viewModel) ?? ComicStripViewController(.init(episode: episode, episodeURL: ""))
        })
        
        comicStripVC.modalPresentationStyle = .fullScreen
        navigationController?.pushViewController(comicStripVC, animated: true)
    }
}


// MARK: - Extensions

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
