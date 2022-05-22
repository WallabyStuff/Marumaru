//
//  ComicDetailViewController.swift
//  Marumaru
//
//  Created by 이승기 on 2021/04/08.
//

import UIKit

import Lottie
import Hero
import RxSwift
import RxCocoa

class ComicDetailViewController: UIViewController, ViewModelInjectable {
    
    
    // MARK: - Properties
    
    typealias ViewModel = ComicDetailViewModel
    
    @IBOutlet weak var appbarView: UIView!
    @IBOutlet weak var infoContentView: UIView!
    @IBOutlet weak var thumbnailImageView: UIImageView!
    @IBOutlet weak var comicTitleLabel: UILabel!
    @IBOutlet weak var authorLabel: UILabel!
    @IBOutlet weak var updateCycleLabel: UILabel!
    @IBOutlet weak var episodeAmountLabel: UILabel!
    @IBOutlet weak var scrollToBottomButton: UIButton!
    @IBOutlet weak var comicEpisodeTableView: UITableView!
    @IBOutlet weak var backButton: UIButton!
    
    static let identifier = R.storyboard.comicDetail.comicDetailStoryboard.identifier
    var viewModel: ViewModel
    var disposeBag = DisposeBag()
    public var comicSN: String?
    public var currentComic: ComicInfo?
    private var episodeLoadingAnimationView = LottieAnimationView()
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
        fatalError("init(coder:) has not been implemented")
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
        setupView()
        setupData()
    }
    
    private func setupData() {
        setupComicInfoData()
        setupComicEpisodeData()
    }
    
    private func setupComicInfoData() {
        guard let currentComic = currentComic else {
            dismiss(animated: true, completion: nil)
            return
        }
        
        comicTitleLabel.text = currentComic.title
        authorLabel.text = currentComic.author
        updateCycleLabel.text = currentComic.updateCycle
        
        thumbnailImageView.layer.cornerRadius = 8
        thumbnailImageView.layer.borderColor = R.color.lineGrayLighter()?.cgColor
        thumbnailImageView.layer.borderWidth = 1
        
        if currentComic.updateCycle.contains("미분류") {
            updateCycleLabel.setBackgroundHighlight(with: R.color.accentGray() ?? .clear,
                                                    textColor: R.color.textWhite() ?? .black)
        } else {
            updateCycleLabel.setBackgroundHighlight(with: R.color.accentBlue() ?? .clear,
                                                    textColor: R.color.textWhite() ?? .black)
        }
        
        if currentComic.thumbnailImage != nil {
            thumbnailImageView.image = currentComic.thumbnailImage
            thumbnailImageView.layer.borderColor = currentComic.thumbnailImage?.averageColor?.cgColor
        } else {
            if let thumbnailImageUrl = currentComic.thumbnailImageURL {
                let token = viewModel.requestImage(thumbnailImageUrl) { result in
                    do {
                        let resultImage = try result.get()
                        
                        DispatchQueue.main.async {
                            self.thumbnailImageView.image = resultImage.imageCache.image
                            self.thumbnailImageView.startFadeInAnimation(duration: 0.3, nil)
                            self.thumbnailImageView.layer.borderColor = UIColor(hexString: resultImage.imageCache.imageAvgColorHex).cgColor
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
    
    private func setupComicEpisodeData() {
        playComicEpisodeLoadingAnimation()
        
        viewModel.getComicEpisodes(currentComic!.comicSN)
            .subscribe(onCompleted: { [weak self] in
                self?.episodeLoadingAnimationView.stop()
            })
            .disposed(by: disposeBag)
    }
    
    private func setupView() {
        setupHero()
        setupAppbarView()
        setupComicInfoView()
        setupComicTitleLabel()
        setupBackButton()
        setupEpisodeSizeLable()
        setupEpisodeTableView()
        setupScrollToBottomButton()
    }
    
    private func setupHero() {
        self.hero.isEnabled = true
    }
    
    private func setupAppbarView() {
        appbarView.hero.id = "appbar"
        appbarView.layer.cornerRadius = 24
        appbarView.layer.maskedCorners = [.layerMinXMaxYCorner]
    }
    
    private func setupComicTitleLabel() {
        comicTitleLabel.hero.id = "mangaTitleLabel"
    }
    
    private func setupBackButton() {
        backButton.hero.id = "appbarButton"
        backButton.imageEdgeInsets(with: 10)
        backButton.layer.masksToBounds = true
        backButton.layer.cornerRadius = 13
    }
    
    private func setupEpisodeSizeLable() {
        episodeAmountLabel.hero.modifiers = [.translate(x: -150)]
    }
    
    private func setupComicInfoView() {
        infoContentView.hero.id = "infoContentView"
        infoContentView.layer.cornerRadius = 16
        infoContentView.layer.shadowColor = R.color.shadowGray()?.cgColor
        infoContentView.layer.shadowOffset = CGSize(width: 4, height: 0)
        infoContentView.layer.shadowRadius = 20
        infoContentView.layer.shadowOpacity = 0.2
    }
    
    private func setupThumbnailImageView() {
        thumbnailImageView.hero.id = "previewImage"
        thumbnailImageView.layer.masksToBounds = true
        thumbnailImageView.layer.cornerRadius = 12
        thumbnailImageView.layer.borderWidth = 1
        thumbnailImageView.layer.borderColor = R.color.backgroundGrayLightest()?.cgColor
        thumbnailImageView.backgroundColor = R.color.backgroundGrayLightest()
    }
    
    private func setupEpisodeTableView() {
        let nibName = UINib(nibName: ComicEpisodeThumbnailTableCell.identifier, bundle: nil)
        comicEpisodeTableView.register(nibName, forCellReuseIdentifier: ComicEpisodeThumbnailTableCell.identifier)
        comicEpisodeTableView.delegate = self
        comicEpisodeTableView.dataSource = self
        
        viewModel.reloadComicEpisodeTableView = { [weak self] in
            self?.comicEpisodeTableView.reloadData()
            self?.episodeAmountLabel.text = self?.viewModel.totalEpisodeCountText
        }
    }
    
    private func setupScrollToBottomButton() {
        scrollToBottomButton.layer.cornerRadius = 12
        scrollToBottomButton.imageEdgeInsets(with: 10)
        scrollToBottomButton.hero.modifiers = [.translate(y: 100)]
    }
    
    
    // MARK: - Bind
    
    private func bind() {
        bindBackButton()
        bindScrollToBottomButton()
        bindComicEpisodeCell()
    }
    
    private func bindBackButton() {
        backButton.rx.tap
            .asDriver()
            .drive(onNext: { [weak self] in
                self?.dismiss(animated: true, completion: nil)
            })
            .disposed(by: disposeBag)
    }
    
    private func bindScrollToBottomButton() {
        scrollToBottomButton.rx.tap
            .asDriver()
            .drive(onNext: { [weak self] in
                self?.scrollToBottom()
            })
            .disposed(by: disposeBag)
    }
    
    private func bindComicEpisodeCell() {
        comicEpisodeTableView.rx.itemSelected
            .asDriver()
            .drive(with: self, onNext: { vc, indexPath in
                let comicInfo = vc.viewModel.cellItemForRow(at: indexPath)
                vc.presentComicStripVC(comicInfo.title, comicInfo.comicURL)
            }).disposed(by: disposeBag)
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
            let indexPath = IndexPath(row: viewModel.totalEpisodeCount - 1, section: 0)
            comicEpisodeTableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
        }
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
        present(comicStripVC, animated: true, completion: nil)
    }
    
    private func playComicEpisodeLoadingAnimation() {
        episodeLoadingAnimationView.play(name: "loading_cat",
                                         size: CGSize(width: 148, height: 148),
                                         to: comicEpisodeTableView)
    }
}


// MARK: - Extenstions

extension ComicDetailViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.numberOfRowsIn(section: 0)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let episodeCell = tableView.dequeueReusableCell(withIdentifier: ComicEpisodeThumbnailTableCell.identifier)
                as? ComicEpisodeThumbnailTableCell else {
            return UITableViewCell()
        }
        
        let comicInfo = viewModel.cellItemForRow(at: indexPath)
        
        episodeCell.titleLabel.text = comicInfo.title
        episodeCell.descriptionLabel.text = comicInfo.description
        episodeCell.indexLabel.text = (viewModel.totalEpisodeCount - indexPath.row).description
        episodeCell.thumbnailImageView.image = nil
        
        if viewModel.ifAlreadyWatched(at: indexPath) {
            episodeCell.setWatched()
        } else {
            episodeCell.setUnWatched()
        }
        
        if let thumbnailImageUrl = comicInfo.thumbnailImageURL {
            let token = viewModel.requestImage(thumbnailImageUrl) { result in
                do {
                    let resultImage = try result.get()
                    
                    DispatchQueue.main.async {
                        episodeCell.thumbnailImageView.image = resultImage.imageCache.image
                        if resultImage.animate {
                            episodeCell.thumbnailImageView.startFadeInAnimation(duration: 0.3)
                        }
                    }
                } catch {
                    print(error.localizedDescription)
                }
            }
            
            episodeCell.onReuse = { [weak self] in
                if let token = token {
                    self?.viewModel.cancelImageRequest(token)
                }
            }
        }
        
        return episodeCell
    }
}

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

extension ComicDetailViewController: ComicStripViewDelegate {
    func didWatchHistoryUpdated() {
        setupComicEpisodeData()
    }
}
