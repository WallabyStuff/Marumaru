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

protocol ComicDetailViewDelegate: AnyObject {
    func didBookmarkStateUpdate()
}

class ComicDetailViewController: BaseViewController, ViewModelInjectable {
    
    
    // MARK: - Properties
    
    static let identifier = R.storyboard.comicDetail.comicDetailStoryboard.identifier
    typealias ViewModel = ComicDetailViewModel
    
    var viewModel: ViewModel
    weak var delegate: ComicDetailViewDelegate?
    
    
    // MARK: - UI
    
    @IBOutlet weak var thumbnailImagePlaceholderView: ThumbnailPlaceholderView!
    @IBOutlet weak var thumbnailImagePlaceholderLabel: UILabel!
    @IBOutlet weak var thumbnailImageView: UIImageView!
    @IBOutlet weak var comicTitleLabel: UILabel!
    @IBOutlet weak var authorLabel: UILabel!
    @IBOutlet weak var updateCycleLabel: TagLabel!
    @IBOutlet weak var episodeAmountLabel: UILabel!
    @IBOutlet weak var comicEpisodeTableView: UITableView!
    @IBOutlet weak var bookmarkButton: UIButton!
    @IBOutlet weak var playFirstEpisodeButton: UIButton!
    
    
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
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.updateWatchHistories()
    }
    
    
    // MARK: - Setup
    
    private func setup() {
        setupData()
        setupView()
    }
    
    private func setupData() {
        viewModel.updateComicInfoAndEpisodes()
        viewModel.setBookmarkState()
        
        // Do not call setInitailComicInfo() in viewDidAppear() with modal style
        DispatchQueue.main.async { [weak self] in
            self?.viewModel.setInitailComicInfo()
        }
    }
    
    private func setupView() {
        setupThumbnailImagePlaceholderView()
        setupThumbnailImageView()
        setupEpisodeTableView()
        setupBookmarkButton()
        setupPlayFirstEpisodeButton()
    }
    
    private func setupThumbnailImagePlaceholderView() {
        thumbnailImagePlaceholderView.layer.cornerRadius = 8
    }

    private func setupThumbnailImageView() {
        thumbnailImageView.layer.masksToBounds = true
        thumbnailImageView.layer.cornerRadius = 8
    }
    
    private func setupEpisodeTableView() {
        registerEpisodeTableCell()
        comicEpisodeTableView.contentInset = UIEdgeInsets.bottom(60 + view.safeAreaInsets.bottom)
    }
    
    private func registerEpisodeTableCell() {
        let nibName = UINib(nibName: R.nib.comicEpisodeThumbnailTableCell.name, bundle: nil)
        comicEpisodeTableView.register(nibName, forCellReuseIdentifier: ComicEpisodeThumbnailTableCell.identifier)
    }
    
    private func setupBookmarkButton() {
        bookmarkButton.layer.cornerRadius = 16
        bookmarkButton.layer.maskedCorners = [.layerMinXMaxYCorner]
        bookmarkButton.layer.shadowColor = R.color.shadowBlack()!.cgColor
        bookmarkButton.layer.shadowOffset = .init(width: 0, height: 4)
        bookmarkButton.layer.shadowRadius = 20
        bookmarkButton.layer.shadowOpacity = 0.2
    }
    
    private func setupPlayFirstEpisodeButton() {
        playFirstEpisodeButton.layer.cornerRadius = playFirstEpisodeButton.frame.height / 2
        playFirstEpisodeButton.layer.borderWidth = 1
        playFirstEpisodeButton.layer.borderColor = R.color.lineGrayLighter()!.cgColor
        playFirstEpisodeButton.layer.shadowColor = R.color.shadowBlack()!.cgColor
        playFirstEpisodeButton.layer.shadowOffset = .init(width: 0, height: 4)
        playFirstEpisodeButton.layer.shadowOpacity = 0.2
        playFirstEpisodeButton.layer.shadowRadius  = 20
    }
    
    
    // MARK: - Bind
    
    private func bind() {
        bindComicInfo()
        
        bindComicEpisodeTableView()
        bindComicEpisodeTableViewCell()
        bindComicEpisodeLoadingState()
        bindComicEpisodeFailState()
        
        bindEpisodeAmountLabel()
        bindRecentWatchingEpisode()
        
        bindBookmarkState()
        bindPlayFirstEpisodeButton()
    }
    
    private func bindComicInfo() {
        viewModel.comicInfo
            .subscribe(with: self, onNext: { vc, comicInfo in
                if comicInfo.title != "" {
                    vc.view.hideSkeleton()
                    vc.episodeAmountLabel.showCustomSkeleton()
                }
                
                vc.comicTitleLabel.text = comicInfo.title
                vc.authorLabel.text = comicInfo.author
                vc.updateCycleLabel.text = comicInfo.updateCycle
                vc.thumbnailImagePlaceholderLabel.text = comicInfo.title
                
                vc.updateCycleLabel.makeRoundedBackground(cornerRadius: 6,
                                                       backgroundColor: UpdateCycle(rawValue: comicInfo.updateCycle)?.color,
                                                       foregroundColor: .white)
                
                if vc.thumbnailImageView.image != nil {
                    return
                }
                
                if comicInfo.thumbnailImage != nil {
                    vc.thumbnailImageView.image = comicInfo.thumbnailImage
                } else {
                    let url = vc.viewModel.getImageURL(comicInfo.thumbnailImagePath)
                    vc.thumbnailImageView.kf.setImage(with: url, options: [.transition(.fade(0.3)), .forceTransition]) { [weak self] result in
                        guard let self = self else { return }
                        
                        do {
                            let result = try result.get()
                            let image = result.image
                            self.thumbnailImagePlaceholderView.makeThumbnailShadow(with: image.averageColor)
                            self.thumbnailImagePlaceholderLabel.isHidden = true
                        } catch {
                            self.thumbnailImagePlaceholderLabel.isHidden = false
                        }
                    }
                }
            })
            .disposed(by: disposeBag)
    }
    
    private func bindComicEpisodeTableView() {
        viewModel.comicEpisodes
            .bind(to: comicEpisodeTableView.rx.items(cellIdentifier: ComicEpisodeThumbnailTableCell.identifier,
                                                     cellType: ComicEpisodeThumbnailTableCell.self)) { [weak self] index, episode, cell in
                guard let self = self else { return }
                
                let episodeIndex = self.viewModel.comicEpisodeIndex(index)
                cell.configure(with: episode, index: episodeIndex)

                if self.viewModel.ifAlreadyWatched(index) {
                    cell.setWatched()
                }
                
                if let recentWatchingEpisodSN = self.viewModel.recentWatchingEpisodeSN {
                    if episode.episodeSN == recentWatchingEpisodSN {
                        cell.recentWatchingIndicatorView.isHidden = false
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
        
        viewModel.presentComicStripVC
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
                    vc.view.showCustomSkeleton()
                    vc.comicEpisodeTableView.isUserInteractionEnabled = false
                    vc.comicEpisodeTableView.visibleCells.forEach { cell in
                        cell.showCustomSkeleton()
                    }
                    
                    vc.playFirstEpisodeButton.isHidden = true
                } else {
                    vc.view.hideSkeleton()
                    vc.comicEpisodeTableView.isUserInteractionEnabled = true
                    vc.comicEpisodeTableView.visibleCells.forEach { cell in
                        cell.hideSkeleton()
                    }
                    
                    if vc.viewModel.comicEpisodeAmount != 0 {
                        vc.playFirstEpisodeButton.isHidden = false
                    }
                }
            })
            .disposed(by: disposeBag)
    }
    
    private func bindComicEpisodeFailState() {
        viewModel.failedToLoadingComicEpisodes
            .subscribe(with: self, onNext: { vc, isFailed in
                if isFailed {
                    vc.comicEpisodeTableView.makeNoticeLabel("message.serverError".localized())
                } else {
                    vc.comicEpisodeTableView.removeNoticeLabels()
                }
            })
            .disposed(by: disposeBag)
    }
    
    private func bindEpisodeAmountLabel() {
        viewModel.comicEpisodes
            .subscribe(with: self, onNext: { vc, comics in
                vc.episodeAmountLabel.text  = "총 \(comics.count)화"
            })
            .disposed(by: disposeBag)
    }
    
    private func bindRecentWatchingEpisode() {
        viewModel.recentWatchingEpisodeUpdated
            .subscribe(with: self, onNext: { vc, indexPath in
                vc.comicEpisodeTableView.reloadData()
                vc.comicEpisodeTableView.scrollToRow(at: indexPath,
                                                     at: .middle,
                                                     animated: false)
            })
            .disposed(by: disposeBag)
    }
    
    private func bindBookmarkState() {
        bookmarkButton.rx.tap
            .asDriver()
            .drive(with: self, onNext: { vc, _ in
                vc.viewModel.tapBookmarkButton()
                vc.makeImpactFeedback(.light)
                vc.delegate?.didBookmarkStateUpdate()
            })
            .disposed(by: disposeBag)
        
        viewModel.bookmarkState
            .subscribe(with: self, onNext: { vc, isBookmarked in
                if isBookmarked {
                    vc.bookmarkButton.setImage(R.image.bookmarkFilled(),
                                               for: .normal)
                } else {
                    vc.bookmarkButton.setImage(R.image.bookmark(),
                                               for: .normal)
                }
            })
            .disposed(by: disposeBag)
    }
    
    private func bindPlayFirstEpisodeButton() {
        playFirstEpisodeButton.rx.tap
            .asDriver()
            .drive(with: self, onNext: { vc, _ in
                vc.viewModel.playFirstComic()
            })
            .disposed(by: disposeBag)
    }
    
    
    // MARK: - Methods
    
    private func scrollToBottom() {
        if comicEpisodeTableView.contentSize.height > 0 {
            let indexPath = IndexPath(row: viewModel.comicEpisodeAmount - 1, section: 0)
            comicEpisodeTableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
        }
    }
    
    private func presentComicStripVC(_ episode: ComicEpisode) {
        let storyboard = UIStoryboard(name: R.storyboard.comicStrip.name, bundle: nil)
        let comicStripVC = storyboard.instantiateViewController(identifier: ComicStripViewController.identifier,
                                                                creator: { coder -> ComicStripViewController in
            let comicEpisode = ComicEpisode(comicSN: episode.comicSN,
                                            episodeSN: episode.episodeSN,
                                            title: episode.title,
                                            description: episode.description,
                                            thumbnailImagePath: episode.thumbnailImagePath)
            let viewModel = ComicStripViewModel(currentEpisode: comicEpisode)
            
            return .init(coder, viewModel) ?? ComicStripViewController(viewModel)
        })
        
        comicStripVC.modalPresentationStyle = .fullScreen
        comicStripVC.delegate = self
        present(comicStripVC, animated: true)
    }
}


// MARK: - Extenstions

extension ComicDetailViewController: ComicStripViewDelegate {
    func didRecentWatchingEpisodeUpdated(_ episodeSN: String) {
        viewModel.updateRecentWatchingEpisode(episodeSN)
    }
}
