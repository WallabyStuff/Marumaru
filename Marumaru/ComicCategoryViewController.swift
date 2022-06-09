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
    
    @IBOutlet weak var comicCollectionView: UICollectionView!
    @IBOutlet weak var comicCategoryCollectionView: UICollectionView!
    
    var viewModel: ComicCategoryViewModel
    private var dataSource: RxCollectionViewSectionedReloadDataSource<ComicInfoSection>?
    private let comicCategoryCollectionViewTopInset: CGFloat = 72
    
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
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 4, execute: {
            self.comicCategoryCollectionView.collectionViewLayout.invalidateLayout()
            self.comicCategoryCollectionView.reloadData()
        })
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
        setupComicCollectionCell()
        setupComicCategoryCollectionView()
    }
    
    private func setupComicCollectionCell() {
        registerComicCollectionCell()
        comicCollectionView.collectionViewLayout = comicsCollectionViewLayout()
        comicCollectionView.contentInset = UIEdgeInsets.inset(top: comicCategoryCollectionViewTopInset,
                                                              bottom: 24)
    }
    
    private func registerComicCollectionCell() {
        let nibName = UINib(nibName: R.nib.comicThumbnailCollectionCell.name, bundle: nil)
        comicCollectionView.register(nibName, forCellWithReuseIdentifier: ComicThumbnailCollectionCell.identifier)
    }
    
    private func setupComicCategoryCollectionView() {
        registerComicCategoryCollectionCell()
        comicCategoryCollectionView.collectionViewLayout = comicCategoryCollectionViewLayout()
        comicCategoryCollectionView.contentInset = .init(top: 8, left: 20, bottom: 8, right: -40)
        comicCategoryCollectionView.delegate = self
    }
    
    private func registerComicCategoryCollectionCell() {
        let nibName = UINib(nibName: R.nib.categoryChipCollectionCell.name, bundle: nil)
        comicCategoryCollectionView.register(nibName, forCellWithReuseIdentifier: CategoryChipCollectionCell.identifier)
    }
    
    
    // MARK: - Binds
    
    private func bind() {
        bindComicsCollectionView()
        bindComicsCollectionCell()
        
        bindComicCategoryCollectionView()
        bindComicCategoryCollectionCell()
        
        bindNoticeLabel()
        bindPresentComicDetailVC()
        bindComicCategoryLoadingState()
    }
    
    private func bindComicsCollectionView() {
        guard let dataSource = dataSource else {
            return
        }

        viewModel.comicSectionsObservable
            .bind(to: comicCollectionView.rx.items(dataSource: dataSource))
            .disposed(by: disposeBag)
    }
    
    private func bindComicsCollectionCell() {
        comicCollectionView.rx.itemSelected
            .asDriver()
            .drive(with: self, onNext: { vc, indexPath in
                vc.viewModel.didTapComicItem(indexPath)
            })
            .disposed(by: disposeBag)
    }
    
    private func bindComicCategoryCollectionView() {
        viewModel.comicCategoriesObservable
            .bind(to: comicCategoryCollectionView.rx.items(cellIdentifier: CategoryChipCollectionCell.identifier,
                                                           cellType: CategoryChipCollectionCell.self)) { [weak self] _, category, cell  in
                guard let self = self else { return }
                
                cell.titleLabel.text = category.title
                
                // Do not bind 'selectedCategory' for stability
                // bind 'selectedCategory' from 'bindComicCategoryCollectionCell()' and reload collectionView
                if self.viewModel.selectedCategory.value == category {
                    cell.setSelected()
                } else {
                    cell.setDeselected()
                }
            }.disposed(by: disposeBag)
    }
    
    private func bindComicCategoryCollectionCell() {
        comicCategoryCollectionView.rx.itemSelected
            .asDriver()
            .drive(with: self, onNext: { vc, indexPath in
                vc.viewModel.categoryItemSelected(indexPath)
            })
            .disposed(by: disposeBag)
        
        viewModel.selectedCategory
            .subscribe(with: self, onNext: { vc, _ in
                vc.comicCategoryCollectionView.reloadData()
            })
            .disposed(by: disposeBag)
    }
    
    private func bindNoticeLabel() {
        viewModel.noticeMessageObservable
            .subscribe(with: self, onNext: { vc, message in
                vc.view.makeNoticeLabel(message)
            })
            .disposed(by: disposeBag)
    }
    
    private func bindComicCategoryLoadingState() {
        viewModel.isLoadingComics
            .subscribe(with: self, onNext: { vc, isLoading in
                vc.comicCollectionView.scrollToTop(topInset: vc.comicCategoryCollectionViewTopInset,
                                                   animated: false)
                vc.comicCollectionView.reloadData()
                vc.comicCollectionView.layoutIfNeeded()
                
                if isLoading {
                    vc.comicCollectionView.isUserInteractionEnabled = false
                    vc.disableComicCategoryCollectionView()
                    
                    vc.comicCollectionView.visibleCells.forEach { cell in
                        cell.showCustomSkeleton()
                    }
                    
                } else {
                    vc.comicCollectionView.isUserInteractionEnabled = true
                    vc.enableComicCategoryCollectionView()
                    
                    vc.comicCollectionView.visibleCells.forEach { cell in
                        cell.hideSkeleton()
                    }
                    
                    // Re
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
    
    private func configureDataSource() -> RxCollectionViewSectionedReloadDataSource<ComicInfoSection> {
        let dataSource = RxCollectionViewSectionedReloadDataSource<ComicInfoSection>(configureCell: { [weak self] _, cv, indexPath, item in
            guard let self = self,
                  let cell = cv.dequeueReusableCell(withReuseIdentifier: ComicThumbnailCollectionCell.identifier, for: indexPath) as? ComicThumbnailCollectionCell else {
                return UICollectionViewCell()
            }
            
            cell.hideSkeleton()
            cell.titleLabel.text = item.title
            cell.thumbnailImagePlaceholderLabel.text = item.title
            cell.authorLabel.text = item.author
            cell.updateCycleLabel.text = item.updateCycle
            cell.updateCycleView.backgroundColor = UpdateCycle(rawValue: item.updateCycle)?.color
            
            let url = self.viewModel.getImageURL(item.thumbnailImagePath)
            cell.thumbnailImageView.kf.setImage(with: url, options: [.transition(.fade(0.3)), .forceTransition]) { result in
                do {
                    let result = try result.get()
                    let image = result.image
                    
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
    
    private func comicsCollectionViewLayout() -> UICollectionViewCompositionalLayout {
        let layout = UICollectionViewCompositionalLayout { _, _ in
            let itemSize = NSCollectionLayoutSize(
                widthDimension: .absolute(120),
                heightDimension: .absolute(224))
            let item = NSCollectionLayoutItem(layoutSize: itemSize)
            
            let groupSize = NSCollectionLayoutSize(
                widthDimension: .absolute(120),
                heightDimension: .absolute(248))
            
            let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])
            group.contentInsets = NSDirectionalEdgeInsets(top: 12, leading: 0, bottom: 12, trailing: 0)
            
            let section = NSCollectionLayoutSection(group: group)
            section.orthogonalScrollingBehavior = .continuous
            section.interGroupSpacing = 16
            section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20)
            
            return section
        }
        
        return layout
    }
    
    private func comicCategoryCollectionViewLayout() -> UICollectionViewFlowLayout {
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.scrollDirection = .horizontal
        flowLayout.estimatedItemSize = .init(width: 60, height: 36)
        flowLayout.minimumInteritemSpacing = 12
        
        return flowLayout
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
    
    private func enableComicCategoryCollectionView() {
        comicCategoryCollectionView.isUserInteractionEnabled = true
        comicCategoryCollectionView.alpha = 1
    }
    
    private func disableComicCategoryCollectionView() {
        comicCategoryCollectionView.isUserInteractionEnabled = false
        comicCategoryCollectionView.alpha = 0.5
    }
}

extension ComicCategoryViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let sideInset: CGFloat = 16
        let width = viewModel.categoryItem(indexPath).title.size(withAttributes: nil).width + sideInset * 2
        return .init(width: width, height: 36)
    }
}
