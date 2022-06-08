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
    
    typealias ViewModel = ComicDetailViewModel
    
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
    
    static let identifier = R.storyboard.comicDetail.comicDetailStoryboard.identifier
    weak var delegate: ComicDetailViewDelegate?
    var viewModel: ViewModel
    
    
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
        setupComicInfoData()
        viewModel.updateComicEpisodes()
        viewModel.setBookmarkState()
    }
    
    private func setupComicInfoData() {
        comicTitleLabel.text = viewModel.comicInfo.title
        authorLabel.text = viewModel.comicInfo.author
        updateCycleLabel.text = viewModel.comicInfo.updateCycle
        thumbnailImageView.layer.cornerRadius = 8
        thumbnailImagePlaceholderLabel.text = viewModel.comicInfo.title
        updateCycleLabel.makeRoundedBackground(cornerRadius: 6,
                                               backgroundColor: UpdateCycle(rawValue: viewModel.comicInfo.updateCycle)?.color,
                                               foregroundColor: .white)
        
        if viewModel.comicInfo.thumbnailImage != nil {
            thumbnailImageView.image = viewModel.comicInfo.thumbnailImage
            thumbnailImageView.layer.borderColor = viewModel.comicInfo.thumbnailImage?.averageColor?.cgColor
        } else {
            let url = viewModel.getThumbnailImageURL()
            thumbnailImageView.kf.setImage(with: url, options: [.transition(.fade(0.3))]) { [weak self] result in
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
    }
    
    private func setupView() {
        setupThumbnailImagePlaceholderView()
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
        bindComicEpisodeTableView()
        bindComicEpisodeTableViewCell()
        bindComicEpisodeLoadingState()
        bindComicEpisodeFailState()
        
        bindEpisodeAmountLabel()
        bindRecentWatchingEpisode()
        
        bindBookmarkState()
        bindPlayFirstEpisodeButton()
    }
    
    private func bindComicEpisodeTableView() {
        viewModel.comicEpisodesObservable
            .bind(to: comicEpisodeTableView.rx.items(cellIdentifier: ComicEpisodeThumbnailTableCell.identifier,
                                                     cellType: ComicEpisodeThumbnailTableCell.self)) { [weak self] index, episode, cell in
                guard let self = self else { return }
                
                cell.hideSkeleton()
                cell.titleLabel.text = episode.title
                cell.authorLabel.text = episode.description
                cell.indexLabel.text = self.viewModel.comicEpisodeIndex(index).description
                cell.thumbnailImageView.image = nil
                
                if self.viewModel.ifAlreadyWatched(index) {
                    cell.setWatched()
                }
                
                if let recentWatchingEpisodSN = self.viewModel.recentWatchingEpisodeSN {
                    if episode.episodeSN == recentWatchingEpisodSN {
                        cell.recentWatchingIndicatorView.isHidden = false
                    }
                }
                
                let url = self.viewModel.getImageURL(episode.thumbnailImagePath)
                cell.thumbnailImageView.kf.setImage(with: url, options: [.transition(.fade(0.3))])
                
                cell.onReuse = {
                    cell.thumbnailImageView.kf.cancelDownloadTask()
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
                    
                    vc.playFirstEpisodeButton.isHidden = true
                } else {
                    vc.comicEpisodeTableView.isUserInteractionEnabled = true
                    vc.episodeAmountLabel.hideSkeleton()
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
        viewModel.comicEpisodesObservable
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
