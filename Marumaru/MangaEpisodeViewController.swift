//
//  MangaContentViewController.swift
//  Marumaru
//
//  Created by 이승기 on 2021/04/08.
//

import UIKit

import Lottie
import Hero
import RxSwift
import RxCocoa

class MangaEpisodeViewController: UIViewController {

    // MARK: - Declarations
    @IBOutlet weak var appbarView: UIView!
    @IBOutlet weak var infoContentView: UIView!
    @IBOutlet weak var thumbnailImageView: UIImageView!
    @IBOutlet weak var mangaTitleLabel: UILabel!
    @IBOutlet weak var authorLabel: UILabel!
    @IBOutlet weak var updateCycleLabel: UILabel!
    @IBOutlet weak var episodeSizeLabel: UILabel!
    @IBOutlet weak var scrollToBottomButton: UIButton!
    @IBOutlet weak var mangaEpisodeTableView: UITableView!
    @IBOutlet weak var backButton: UIButton!
    
    private let viewModel = MangaEpisodeViewModel()
    public var mangaSN: String?
    public var currentManga: MangaInfo?
    private var disposeBag = DisposeBag()
    private var episodeLoadingAnimationView = LottieAnimationView()
    private var cancelRequestImage: (() -> Void)?

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
    
    // MARK: - SetupData
    private func setupData() {
        setupMangaInfoData()
        setupMangaEpisodeData()
    }
    
    private func setupMangaInfoData() {
        guard let currentManga = currentManga else {
            dismiss(animated: true, completion: nil)
            return
        }
        
        mangaTitleLabel.text = currentManga.title
        authorLabel.text = currentManga.author
        updateCycleLabel.text = currentManga.updateCycle
        
        thumbnailImageView.layer.cornerRadius = 8
        thumbnailImageView.layer.borderColor = R.color.lineGrayLighter()?.cgColor
        thumbnailImageView.layer.borderWidth = 1
        
        if currentManga.updateCycle.contains("미분류") {
            updateCycleLabel.setBackgroundHighlight(with: R.color.accentGray() ?? .clear,
                                                                     textColor: R.color.textWhite() ?? .black)
        } else {
            updateCycleLabel.setBackgroundHighlight(with: R.color.accentBlue() ?? .clear,
                                                                     textColor: R.color.textWhite() ?? .black)
        }
        
        if currentManga.thumbnailImage != nil {
            thumbnailImageView.image = currentManga.thumbnailImage
            thumbnailImageView.layer.borderColor = currentManga.thumbnailImage?.averageColor?.cgColor
        } else {
            if let thumbnailImageUrl = currentManga.thumbnailImageURL {
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
    
    private func setupMangaEpisodeData() {
        playMangaEpisodeLoadingAnimation()
        
        viewModel.getMangaEpisodes(currentManga!.mangaSN)
            .subscribe(onCompleted: { [weak self] in
                self?.episodeLoadingAnimationView.stop()
            })
            .disposed(by: disposeBag)
    }
    
    // MARK: - SetupView
    private func setupView() {
        setupHero()
        setupAppbarView()
        setupMangaInfoView()
        setupMangaTitleLabel()
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
    
    private func setupMangaTitleLabel() {
        mangaTitleLabel.hero.id = "mangaTitleLabel"
    }
    
    private func setupBackButton() {
        backButton.hero.id = "appbarButton"
        backButton.imageEdgeInsets(with: 10)
        backButton.layer.masksToBounds = true
        backButton.layer.cornerRadius = 13
    }
    
    private func setupEpisodeSizeLable() {
        episodeSizeLabel.hero.modifiers = [.translate(x: -150)]
    }
    
    private func setupMangaInfoView() {
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
        let nibName = UINib(nibName: "MangaEpisodeTableViewCell", bundle: nil)
        mangaEpisodeTableView.register(nibName, forCellReuseIdentifier: "mangaEpisodeTableCell")
        mangaEpisodeTableView.delegate = self
        mangaEpisodeTableView.dataSource = self
        
        viewModel.reloadMangaEpisodeTableView = { [weak self] in
            self?.mangaEpisodeTableView.reloadData()
            self?.episodeSizeLabel.text = self?.viewModel.totalEpisodeCountText
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
        bindMangaEpisodeCell()
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
    
    private func bindMangaEpisodeCell() {
        mangaEpisodeTableView.rx.itemSelected
            .asDriver()
            .drive(with: self, onNext: { vc, indexPath in
                let mangaInfo = vc.viewModel.cellItemForRow(at: indexPath)
                vc.presentPlayMangaVC(mangaInfo.title, mangaInfo.mangaURL)
            }).disposed(by: disposeBag)
    }

    // MARK: - Method
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
        if mangaEpisodeTableView.contentSize.height > 0 {
            let indexPath = IndexPath(row: viewModel.totalEpisodeCount - 1, section: 0)
            mangaEpisodeTableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
        }
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
    
    private func playMangaEpisodeLoadingAnimation() {
        episodeLoadingAnimationView.play(name: "loading_cat",
                                         size: CGSize(width: 148, height: 148),
                                         to: mangaEpisodeTableView)
    }
}

// MARK: - Extenstions
extension MangaEpisodeViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.numberOfRowsIn(section: 0)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let episodeCell = tableView.dequeueReusableCell(withIdentifier: MangaEpisodeTableCell.identifier) as? MangaEpisodeTableCell else {
            return UITableViewCell()
        }
        
        let mangaInfo = viewModel.cellItemForRow(at: indexPath)
        
        episodeCell.titleLabel.text = mangaInfo.title
        episodeCell.descriptionLabel.text = mangaInfo.description
        episodeCell.indexLabel.text = (viewModel.totalEpisodeCount - indexPath.row).description
        episodeCell.thumbnailImageView.image = nil
        
        if viewModel.ifAlreadyWatched(at: indexPath) {
            episodeCell.setWatched()
        } else {
            episodeCell.setUnWatched()
        }
        
        if let thumbnailImageUrl = mangaInfo.thumbnailImageURL {
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

extension MangaEpisodeViewController: UIScrollViewDelegate {
    func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView) {
        let actualPosition = scrollView.panGestureRecognizer.translation(in: scrollView.superview)
        
        if actualPosition.y > 0 {
            fadeScrollToBottomButton(bool: true)
        } else {
            fadeScrollToBottomButton(bool: false)
        }
    }
}

extension MangaEpisodeViewController: PlayMangaViewDelegate {
    func didWatchHistoryUpdated() {
        setupMangaEpisodeData()
    }
}
