//
//  ComicDetailViewController.swift
//  Marumaru
//
//  Created by 이승기 on 2021/04/08.
//

import UIKit

import Lottie
import RxSwift
import RxCocoa

class ComicDetailViewController: BaseViewController, ViewModelInjectable {
    
    
    // MARK: - Properties
    
    typealias ViewModel = ComicDetailViewModel
    
    @IBOutlet weak var thumbnailImagePlaceholderView: ThumbnailView!
    @IBOutlet weak var thumbnailImageView: UIImageView!
    @IBOutlet weak var comicTitleLabel: UILabel!
    @IBOutlet weak var authorLabel: UILabel!
    @IBOutlet weak var updateCycleLabel: UILabel!
    @IBOutlet weak var episodeAmountLabel: UILabel!
    @IBOutlet weak var scrollToBottomButton: UIButton!
    @IBOutlet weak var comicEpisodeTableView: UITableView!
    
    static let identifier = R.storyboard.comicDetail.comicDetailStoryboard.identifier
    var viewModel: ViewModel
    private var cancelRequestImage: (() -> Void)?
    
    
    // MARK: - Initializers
    
    required init(_ viewModel: ComicDetailViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        dismiss(animated: true)
    }
    
    required init?(_ coder: NSCoder, _ viewModel: ComicDetailViewModel) {
        self.viewModel = viewModel
        super.init(coder: coder)
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
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        cancelRequestImage?()
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .darkContent
    }
    
    
    // MARK: - Setup
    
    private func setup() {
        setupData()
        setupView()
    }
    
    private func setupData() {
        setupComicInfoData()
        viewModel.updateComicEpisodes()
    }
    
    private func setupComicInfoData() {
        comicTitleLabel.text = viewModel.comicInfo.title
        authorLabel.text = viewModel.comicInfo.author
        updateCycleLabel.text = viewModel.comicInfo.updateCycle
        thumbnailImageView.layer.cornerRadius = 8
        
        if viewModel.comicInfo.updateCycle.contains("미분류") {
            updateCycleLabel.setBackgroundHighlight(with: .systemTeal,
                                                    textColor: .white)
        } else {
            updateCycleLabel.setBackgroundHighlight(with: .systemTeal,
                                                    textColor: .white)
        }
        
        if viewModel.comicInfo.thumbnailImage != nil {
            thumbnailImageView.image = viewModel.comicInfo.thumbnailImage
            thumbnailImageView.layer.borderColor = viewModel.comicInfo.thumbnailImage?.averageColor?.cgColor
        } else {
            if let thumbnailImageUrl = viewModel.comicInfo.thumbnailImageURL {
                let token = viewModel.requestImage(thumbnailImageUrl) { result in
                    do {
                        let resultImage = try result.get()

                        DispatchQueue.main.async {
                            self.thumbnailImageView.image = resultImage.imageCache.image
                            self.thumbnailImageView.startFadeInAnimation(duration: 0.3, nil)
                            self.thumbnailImagePlaceholderView.setThumbnailShadow(with: resultImage.imageCache.averageColor.cgColor)
                        }
                    } catch {
                        print(error.localizedDescription)
                    }
                }

                cancelRequestImage = { [weak self] in
                    if let token = token {
                        self?.viewModel.cancelImageRequest(token)
                    }
                }
            }
        }
    }
    
    private func setupView() {
        setupThumbnailImagePlaceholderView()
        setupEpisodeTableView()
        setupScrollToBottomButton()
    }
    
    private func setupThumbnailImagePlaceholderView() {
        thumbnailImagePlaceholderView.layer.cornerRadius = 8
    }

    private func setupThumbnailImageView() {
        thumbnailImageView.layer.masksToBounds = true
        thumbnailImageView.layer.cornerRadius = 8
    }
    
    private func setupEpisodeTableView() {
        let nibName = UINib(nibName: ComicEpisodeThumbnailTableCell.identifier, bundle: nil)
        comicEpisodeTableView.register(nibName, forCellReuseIdentifier: ComicEpisodeThumbnailTableCell.identifier)
    }
    
    private func setupScrollToBottomButton() {
        scrollToBottomButton.layer.cornerRadius = 12
        scrollToBottomButton.imageEdgeInsets(with: 10)
    }
    
    
    // MARK: - Bind
    
    private func bind() {
        bindScrollToBottomButton()
        
        bindComicEpisodeTableView()
        bindComicEpisodeTableViewCell()
        bindComicEpisodeLoadingState()
        bindComicEpisodeFailState()
        bindEpisodeAmountLabel()
    }
    
    private func bindScrollToBottomButton() {
        scrollToBottomButton.rx.tap
            .asDriver()
            .drive(with: self, onNext: { vc, _ in
                vc.scrollToBottom()
            })
            .disposed(by: disposeBag)
    }
    
    private func bindComicEpisodeTableView() {
        viewModel.comicEpisodesObservable
            .bind(to: comicEpisodeTableView.rx.items(cellIdentifier: ComicEpisodeThumbnailTableCell.identifier,
                                                     cellType: ComicEpisodeThumbnailTableCell.self)) { [weak self] index, comic, cell in
                guard let self = self else { return }
                
                cell.hideSkeleton()
                cell.titleLabel.text = comic.title
                cell.authorLabel.text = comic.description
                cell.indexLabel.text = self.viewModel.comicEpisodeIndex(index).description
                cell.thumbnailImageView.image = nil
                
                if self.viewModel.ifAlreadyWatched(index) {
                    cell.setWatched()
                } else {
                    cell.setUnWatched()
                }
                
                if let thumbnailImageUrl = comic.thumbnailImageURL {
                    let token = self.viewModel.requestImage(thumbnailImageUrl) { result in
                        do {
                            let resultImage = try result.get()
                            
                            DispatchQueue.main.async {
                                cell.thumbnailImageView.image = resultImage.imageCache.image
                                if resultImage.animate {
                                    cell.thumbnailImageView.startFadeInAnimation(duration: 0.3)
                                }
                            }
                        } catch {
                            print(error.localizedDescription)
                        }
                    }
                    
                    cell.onReuse = { [weak self] in
                        if let token = token {
                            self?.viewModel.cancelImageRequest(token)
                        }
                    }
                }
            }.disposed(by: disposeBag)
    }
    
    private func bindComicEpisodeTableViewCell() {
        comicEpisodeTableView.rx.itemSelected
            .asDriver()
            .drive(with: self, onNext: { vc, indexPath in
                vc.viewModel.comicItemSelected(indexPath)
            }).disposed(by: disposeBag)
        
        viewModel.presentComicStripVCObservable
            .subscribe(with: self, onNext: { vc, comic in
                vc.presentComicStripVC(comic)
            })
            .disposed(by: disposeBag)
    }
    
    private func bindComicEpisodeLoadingState() {
        viewModel.isLoadingComicEpisodes
            .subscribe(with: self, onNext: { vc, isLoading in
                vc.comicEpisodeTableView.layoutSubviews()
                
                if isLoading {
                    vc.comicEpisodeTableView.isUserInteractionEnabled = false
                    vc.episodeAmountLabel.showCustomSkeleton()
                    vc.comicEpisodeTableView.visibleCells.forEach { cell in
                        cell.showCustomSkeleton()
                    }
                } else {
                    vc.comicEpisodeTableView.isUserInteractionEnabled = true
                    vc.episodeAmountLabel.hideSkeleton()
                    vc.comicEpisodeTableView.visibleCells.forEach { cell in
                        cell.hideSkeleton()
                    }
                }
            })
            .disposed(by: disposeBag)
    }
    
    private func bindComicEpisodeFailState() {
        viewModel.failedToLoadingComicEpisodes
            .subscribe(with: self, onNext: { vc, isFailed in
                if isFailed {
                    vc.comicEpisodeTableView.makeNoticeLabel("🛠서버 점검중입니다.\n나중에 다시 시도해주세요")
                } else {
                    vc.comicEpisodeTableView.removeNoticeLabels()
                }
            })
            .disposed(by: disposeBag)
    }
    
    private func bindEpisodeAmountLabel() {
        viewModel.comicEpisodesObservable
            .subscribe(with: self, onNext: { vc, comics in
                vc.episodeAmountLabel.text  = "총 \(comics.count)화"
            })
            .disposed(by: disposeBag)
    }
    
    
    // MARK: - Methods
    
    private func fadeScrollToBottomButton(bool: Bool) {
        if bool {
            // fade out
            UIView.animate(withDuration: 0.3) {
                self.scrollToBottomButton.alpha = 0
            }
        } else {
            // fade in
            UIView.animate(withDuration: 0.3) {
                self.scrollToBottomButton.alpha = 1
            }
        }
    }
    
    private func scrollToBottom() {
        if comicEpisodeTableView.contentSize.height > 0 {
            let indexPath = IndexPath(row: viewModel.comicEpisodeAmount - 1, section: 0)
            comicEpisodeTableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
        }
    }
    
    private func presentComicStripVC(_ comicEpisode: ComicEpisode) {
        let storyboard = UIStoryboard(name: R.storyboard.comicStrip.name, bundle: nil)
        let comicStripVC = storyboard.instantiateViewController(identifier: ComicStripViewController.identifier,
                                                                creator: { coder -> ComicStripViewController in
            let episode = Episode(title: comicEpisode.title, serialNumber: "")
            let viewModel = ComicStripViewModel(episode: episode, episodeURL: comicEpisode.episodeURL)
            return .init(coder, viewModel) ?? ComicStripViewController(.init(episode: episode, episodeURL: ""))
        })
        
        comicStripVC.modalPresentationStyle = .fullScreen
        present(comicStripVC, animated: true)
    }
}


// MARK: - Extenstions

extension ComicDetailViewController: UIScrollViewDelegate {
    func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView) {
        let actualPosition = scrollView.panGestureRecognizer.translation(in: scrollView.superview)
        
        if actualPosition.y > 0 {
            fadeScrollToBottomButton(bool: true)
        } else {
            fadeScrollToBottomButton(bool: false)
        }
    }
}
