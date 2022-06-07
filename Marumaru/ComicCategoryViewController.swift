//
//  CategoryViewController.swift
//  Marumaru
//
//  Created by 이승기 on 2022/06/07.
//

import UIKit

import RxSwift
import RxCocoa
import RxDataSources

class ComicCategoryViewController: BaseViewController, ViewModelInjectable {
    
    
    // MARK: - Properties
    
    static let identifier = R.storyboard.comicCategory.comicCategoryStoryboard.identifier
    typealias ViewModel = ComicCategoryViewModel
    
    @IBOutlet weak var categoryCollectionView: UICollectionView!
    
    var viewModel: ComicCategoryViewModel
    private var dataSource: RxCollectionViewSectionedAnimatedDataSource<ComicInfoSection>?
    
    required init(_ viewModel: ComicCategoryViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        dismiss(animated: true)
        navigationController?.popViewController(animated: true)
    }
    
    required init?(_ coder: NSCoder, _ viewModel: ComicCategoryViewModel) {
        self.viewModel = viewModel
        super.init(coder: coder)
        self.dataSource = configureDataSource()
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
    
    
    // MARK: - Setups
    
    private func setup() {
        setupView()
        setupData()
    }
    
    private func setupData() {
        setupComicCategoryItems()
    }
    
    private func setupComicCategoryItems() {
        viewModel.updateComicCategory()
    }
    
    private func setupView() {
        setupCategoryCollectionCell()
    }
    
    private func setupCategoryCollectionCell() {
        registerCategoryCollectionCell()
        categoryCollectionView.collectionViewLayout = flowLayout()
        categoryCollectionView.contentInset = .init(top: 24, left: 0, bottom: 24, right: 0)
    }
    
    private func registerCategoryCollectionCell() {
        let nibName = UINib(nibName: R.nib.categoryThumbnailCollectionCell.name, bundle: nil)
        categoryCollectionView.register(nibName, forCellWithReuseIdentifier: CategoryThumbnailCollectionCell.identifier)
    }
    
    
    // MARK: - Binds
    
    private func bind() {
        bindNoticeLabel()
        ComicCategoryCollectionView()
        bindComicCategoryCell()
        bindPresentComicDetailVC()
        setupComicCategoryLoadingState()
    }
    
    private func bindNoticeLabel() {
        viewModel.noticeMessageObservable
            .subscribe(with: self, onNext: { vc, message in
                vc.view.makeNoticeLabel(message)
            })
            .disposed(by: disposeBag)
    }
    
    private func ComicCategoryCollectionView() {
        guard let dataSource = dataSource else {
            return
        }

        viewModel.comicSectionsObservable
            .bind(to: categoryCollectionView.rx.items(dataSource: dataSource))
            .disposed(by: disposeBag)
    }
    
    private func bindComicCategoryCell() {
        categoryCollectionView.rx.itemSelected
            .asDriver()
            .drive(with: self, onNext: { vc, indexPath in
                vc.viewModel.tapComicItem(indexPath)
            })
            .disposed(by: disposeBag)
    }
    
    private func setupComicCategoryLoadingState() {
        viewModel.isLoadingComics
            .subscribe(with: self, onNext: { vc, isLoading in
                vc.categoryCollectionView.layoutIfNeeded()
                
                if isLoading {
                    vc.categoryCollectionView.isUserInteractionEnabled = false
                    vc.categoryCollectionView.visibleCells.forEach { cell in
                        cell.showCustomSkeleton()
                    }
                } else {
                    vc.categoryCollectionView.isUserInteractionEnabled = true
                    vc.categoryCollectionView.visibleCells.forEach { cell in
                        cell.hideSkeleton()
                    }
                }
            })
            .disposed(by: disposeBag)
    }
    
    private func bindPresentComicDetailVC() {
        viewModel.presentComicDetailVCObservable
            .subscribe(with: self, onNext: { vc, comicInfo in
                vc.presentComicDetailVC(comicInfo)
            })
            .disposed(by: disposeBag)
    }
    
    
    // MARK: - Methods
    
    private func configureDataSource() -> RxCollectionViewSectionedAnimatedDataSource<ComicInfoSection> {
        let dataSource = RxCollectionViewSectionedAnimatedDataSource<ComicInfoSection>(configureCell: { [weak self] _, cv, indexPath, item in
            guard let self = self,
                  let cell = cv.dequeueReusableCell(withReuseIdentifier: CategoryThumbnailCollectionCell.identifier, for: indexPath) as? CategoryThumbnailCollectionCell else {
                return UICollectionViewCell()
            }
            
            cell.hideSkeleton()
            cell.titleLabel.text = item.title
            cell.thumbnailImagePlaceholderLabel.text = item.title
            cell.authorLabel.text = item.author
            cell.updateCycleLabel.text = item.updateCycle
            
            let url = self.viewModel.getImageURL(item.thumbnailImagePath)
            cell.thumbnailImageView.kf.setImage(with: url, options: [.transition(.fade(0.3))]) { result in
                do {
                    let result = try result.get()
                    let image = result.image
                    
                    cell.thumbnailImageView.image = result.image
                    cell.thumbnailImagePlaceholderLabel.isHidden = true
                    cell.thumbnailImagePlaceholderView.makeThumbnailShadow(with: image.averageColor)
                } catch {
                    cell.thumbnailImagePlaceholderLabel.isHidden = false
                }
            }
            
            cell.onReuse = {
                cell.thumbnailImageView.kf.cancelDownloadTask()
            }
            
            return cell
        })
        
        return dataSource
    }
    
    private func flowLayout() -> UICollectionViewCompositionalLayout {
        let layout = UICollectionViewCompositionalLayout { _, _ in
            let itemSize = NSCollectionLayoutSize(
                widthDimension: .absolute(120),
                heightDimension: .absolute(224))
            let item = NSCollectionLayoutItem(layoutSize: itemSize)
            
            let groupSize = NSCollectionLayoutSize(
                widthDimension: .absolute(120),
                heightDimension: .absolute(224))
            
            let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])
            group.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20)
            group.interItemSpacing = .fixed(16)
            
            let section = NSCollectionLayoutSection(group: group)
            section.orthogonalScrollingBehavior = .continuous
            section.interGroupSpacing = 16
            section.contentInsets = .init(top: 12, leading: 0, bottom: 12, trailing: 40)
            
            return section
        }
        
        return layout
    }
    
    private func presentComicDetailVC(_ comicInfo: ComicInfo) {
        let storyboard = UIStoryboard(name: R.storyboard.comicDetail.name, bundle: nil)
        let comicDetailVC = storyboard.instantiateViewController(identifier: ComicDetailViewController.identifier,
                                                             creator: { coder -> ComicDetailViewController in
            let viewModel = ComicDetailViewModel(comicInfo: comicInfo)
            return .init(coder, viewModel) ?? ComicDetailViewController(.init())
        })
        
        present(comicDetailVC, animated: true, completion: nil)
    }
}
