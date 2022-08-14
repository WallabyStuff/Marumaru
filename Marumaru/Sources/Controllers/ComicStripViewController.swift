//
//  ComicStripViewController.swift
//  Marumaru
//
//  Created by 이승기 on 2021/04/08.
//

import UIKit

import SwiftSoup
import Lottie
import Toast
import RxSwift
import RxCocoa
import RxGesture


protocol ComicStripViewDelegate: AnyObject {
    func didRecentWatchingEpisodeUpdated(_ episodeSN: String)
}

class ComicStripViewController: BaseViewController, ViewModelInjectable {
    
    
    // MARK: - Properties
    
    static let identifier = R.storyboard.comicStrip.comicStripStroyboard.identifier
    typealias ViewModel = ComicStripViewModel
    
    var viewModel: ViewModel
    weak var delegate: ComicStripViewDelegate?
    private var isSceneZoomed = false
    private var sceneDoubleTapGestureRecognizer = UITapGestureRecognizer()
    private var isStatusBarHidden: Bool = false {
        didSet {
            UIView.animate(withDuration: 0.2) {
                self.setNeedsStatusBarAppearanceUpdate()
            }
        }
    }
    
    
    // MARK: - UI
    
    @IBOutlet weak var appbarView: UIVisualEffectView!
    @IBOutlet weak var episodeTitleLabel: UILabel!
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var showEpisodeListButton: UIButton!
    @IBOutlet weak var nextEpisodeButton: UIButton!
    @IBOutlet weak var previousEpisodeButton: UIButton!
    @IBOutlet weak var bottomIndicatorView: UIView!
    @IBOutlet weak var appbarViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var bottomIndicatorViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var comicStripScrollView: ComicStripScrollView!
    override var prefersStatusBarHidden: Bool {
        return isStatusBarHidden
    }
    
    
    // MARK: - Initializers
    
    required init(_ viewModel: ViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        dismiss(animated: true)
    }
    
    required init?(_ coder: NSCoder, _ viewModel: ViewModel) {
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
    
    override func viewWillEnterForeground() {
        comicStripScrollView.resumeLoadingScenes()
    }

    
    // MARK: - Setups
    
    private func setup() {
        setupView()
        setupData()
    }
    
    private func setupData() {
        viewModel.renderCurrentEpisodeScenes()
    }
    
    private func setupView() {
        setupNavigationBar()
        setupBaseView()
        setupSceneScrollView()
        setupAppBarView()
        setupBottomIndicatorView()
    }
    
    private func setupNavigationBar() {
        navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    private func setupBaseView() {
        let edgePan = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(didSwipeEdgeOfScreen(_:)))
        edgePan.edges = .left
        view.addGestureRecognizer(edgePan)
    }
    
    private func setupSceneScrollView() {
        comicStripScrollView.contentInset = UIEdgeInsets.inset(top: compactAppbarHeight,
                                                               bottom: bottomIndicatorView.frame.height)
        comicStripScrollView.delegate = self
        comicStripScrollView.showsVerticalScrollIndicator = true
        comicStripScrollView.showsHorizontalScrollIndicator = false
    }
    
    private func setupAppBarView() {
        appbarView.layer.shadowColor = UIColor.black.cgColor
        appbarView.layer.shadowOpacity = 0.1
        appbarView.layer.shadowRadius = 20
        appbarView.layer.shadowOffset = .zero
    }
    
    private func setupBottomIndicatorView() {
        bottomIndicatorView.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        bottomIndicatorView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        bottomIndicatorView.layer.shadowColor = UIColor.black.cgColor
        bottomIndicatorView.layer.shadowOpacity = 0.1
        bottomIndicatorView.layer.shadowRadius = 20
        bottomIndicatorView.layer.shadowOffset = .zero
    }
    
    
    // MARK: - Constraints
    
    override func updateViewConstraints() {
        configureAppbarViewConstraints()
        configureBottomIndicatorViewConstraints()
        super.updateViewConstraints()
    }
    
    private func configureAppbarViewConstraints() {
        appbarViewHeightConstraint.constant = view.safeAreaInsets.top + compactAppbarHeight
    }
    
    private func configureBottomIndicatorViewConstraints() {
        bottomIndicatorViewHeightConstraint.constant = view.safeAreaInsets.bottom + compactAppbarHeight
    }
    
    
    // MARK: - Bind
    
    private func bind() {
        bindBackButton()
        bindEpisodeTitleLabel()
        bindNextEpisodeButton()
        bindPreviousEpisodeButton()
        bindShowEpisodeListButton()
        bindShowEpisodeListButton()
        bindComicStripScrollView()
        bindComicStripLoadingState()
        bindComicStripFailState()
        bindSceneSingleTapGesture()
        bindSceneDoubleTapGesture()
        bindSceneScrollView()
        bindToastMessage()
        bindRecentWatchingEpisode()
    }
    
    private func bindBackButton() {
        backButton.rx.tap
            .asDriver()
            .drive(with: self, onNext: { vc, _ in
                vc.navigationController?.popViewController(animated: true)
                vc.dismiss(animated: true)
            })
            .disposed(by: disposeBag)
    }
    
    private func bindEpisodeTitleLabel() {
        viewModel.episodeTitle
            .subscribe(with: self, onNext: { vc, title in
                vc.episodeTitleLabel.text = title
            })
            .disposed(by: disposeBag)
    }
    
    private func bindNextEpisodeButton() {
        nextEpisodeButton.rx.tap
            .asDriver()
            .drive(with: self, onNext: { vc, _  in
                vc.viewModel.renderNextEpisodeScenes()
            })
            .disposed(by: disposeBag)
    }
    
    private func bindPreviousEpisodeButton() {
        previousEpisodeButton.rx.tap
            .asDriver()
            .drive(with: self, onNext: { vc, _ in
                vc.viewModel.renderPreviousEpisodeScenes()
            })
            .disposed(by: disposeBag)
    }
    
    private func bindShowEpisodeListButton() {
        showEpisodeListButton.rx.tap
            .asDriver()
            .drive(with: self, onNext: { vc, _ in
                vc.presentComicEpisodePopoverVC()
            })
            .disposed(by: disposeBag)
    }
    
    private func bindComicStripScrollView() {
        viewModel.comicStripScenes
            .subscribe(with: self, onNext: { vc, scenes in
                vc.comicStripScrollView.setScenes(scenes)
                vc.viewModel.saveToWatchHistory()
            })
            .disposed(by: disposeBag)
    }
    
    private func bindComicStripLoadingState() {
        viewModel.isLoadingScenes
            .subscribe(with: self, onNext: { vc, isLoading in
                if isLoading {
                    vc.comicStripScrollView.disableScrollView()
                    vc.view.playRandomCatLottie()
                    vc.disableIndicatorButtons()
                } else {
                    vc.comicStripScrollView.enableScrollView()
                    vc.view.stopLottie()
                    vc.enableIndicatorButtons()
                }
            })
            .disposed(by: disposeBag)
    }
    
    private func bindComicStripFailState() {
        viewModel.failToLoadingScenes
            .subscribe(with: self, onNext: { vc, isFailed in
                if isFailed {
                    vc.view.makeNoticeLabel("message.serverError".localized())
                } else {
                    vc.view.removeNoticeLabels()
                }
            })
            .disposed(by: disposeBag)
    }
    
    private func bindSceneSingleTapGesture() {
        let sceneTapGestureRocognizer = UITapGestureRecognizer()
        sceneTapGestureRocognizer.numberOfTapsRequired = 1
        sceneTapGestureRocognizer.require(toFail: sceneDoubleTapGestureRecognizer)
        comicStripScrollView.rx
            .gesture(sceneTapGestureRocognizer)
            .when(.recognized)
            .bind(with: self, onNext: { vc, _ in
                if vc.appbarView.alpha == 0 {
                    vc.showNavigationBar()
                } else {
                    vc.hideNavigationBar()
                }
            })
            .disposed(by: disposeBag)
    }
    
    private func bindSceneDoubleTapGesture() {
        sceneDoubleTapGestureRecognizer = UITapGestureRecognizer()
        sceneDoubleTapGestureRecognizer.numberOfTapsRequired = 2
        comicStripScrollView.addGestureRecognizer(sceneDoubleTapGestureRecognizer)
        comicStripScrollView.rx
            .gesture(sceneDoubleTapGestureRecognizer)
            .when(.recognized)
            .subscribe(with: self, onNext: { vc, recognizer in
                let tapPoint = recognizer.location(in: vc.comicStripScrollView.contentView)
                vc.zoom(point: tapPoint)
            })
            .disposed(by: disposeBag)
    }
    
    private func bindSceneScrollView() {
        comicStripScrollView.rx.contentOffset
            .observe(on: MainScheduler.asyncInstance)
            .bind(with: self, onNext: { vc, offset in
                let overPanThreshold: CGFloat = 50
                // reached the top
                if offset.y < -(overPanThreshold + overPanThreshold) {
                    vc.showNavigationBar()
                }
                
                // reached the bottom
                if offset.y > vc.comicStripScrollView.contentSize.height - vc.view.frame.height + overPanThreshold + vc.bottomIndicatorView.frame.height {
                    vc.showNavigationBar()
                }
            })
            .disposed(by: disposeBag)
        
        comicStripScrollView.rx.panGesture()
            .when(.began)
            .subscribe(with: self, onNext: { vc, _ in
                vc.hideNavigationBar()
            })
            .disposed(by: disposeBag)
    }
    
    private func bindToastMessage() {
        viewModel.makeToast
            .subscribe(with: self, onNext: { vc, message in
                vc.view.makeToast(message)
            })
            .disposed(by: disposeBag)
    }
    
    private func bindRecentWatchingEpisode() {
        viewModel.updateRentWatchingEpisode
            .subscribe(with: self, onNext: { vc, episodeSN in
                vc.delegate?.didRecentWatchingEpisodeUpdated(episodeSN)
            })
            .disposed(by: disposeBag)
    }
    
    
    // MARK: - Methods
    
    private func presentComicEpisodePopoverVC() {
        let storyboard = UIStoryboard(name: R.storyboard.popOverComicEpisode.name, bundle: nil)
        let comicEpisodePopOverVC = storyboard.instantiateViewController(identifier: PopOverComicEpisodeViewController.identifier,
                                                                         creator: { [weak self] coder -> PopOverComicEpisodeViewController in
            let dumpVC = PopOverComicEpisodeViewController(.init("", []))
            guard let self = self else { return dumpVC }
            let viewModel = PopOverComicEpisodeViewModel(self.viewModel.serialNumber,
                                                         self.viewModel.comicEpisodes)
            return .init(coder, viewModel) ?? dumpVC
        })
        
        comicEpisodePopOverVC.modalPresentationStyle = .popover
        comicEpisodePopOverVC.preferredContentSize = CGSize(width: 200, height: 300)
        comicEpisodePopOverVC.popoverPresentationController?.permittedArrowDirections = .down
        comicEpisodePopOverVC.popoverPresentationController?.sourceRect = showEpisodeListButton.bounds
        comicEpisodePopOverVC.popoverPresentationController?.sourceView = showEpisodeListButton
        comicEpisodePopOverVC.presentationController?.delegate = self
        comicEpisodePopOverVC.delegate = self
        present(comicEpisodePopOverVC, animated: true, completion: nil)
    }
    
    @objc
    private func didSwipeEdgeOfScreen(_ sender: UIScreenEdgePanGestureRecognizer) {
        dismiss(animated: true)
    }
}


// MARK: - Extensions

extension ComicStripViewController {
    func zoom(point: CGPoint) {
        if isSceneZoomed {
            // zoom out
            comicStripScrollView.zoom(to: CGRect(x: point.x,
                                            y: point.y,
                                            width: self.view.frame.width,
                                            height: self.view.frame.height),
                                 animated: true)
            isSceneZoomed = false
        } else {
            // zoom in
            hideNavigationBar()
            comicStripScrollView.zoom(to: CGRect(x: point.x,
                                            y: point.y,
                                            width: self.view.frame.width / 2,
                                            height: self.view.frame.height / 2),
                                 animated: true)
            isSceneZoomed = true
        }
    }
}

extension ComicStripViewController {
    private func enableIndicatorButtons() {
        toggleIndicatorButtons(true)
    }
    
    private func disableIndicatorButtons() {
        toggleIndicatorButtons(false)
    }
    
    private func toggleIndicatorButtons(_ state: Bool) {
        previousEpisodeButton.isEnabled = state
        showEpisodeListButton.isEnabled = state
        nextEpisodeButton.isEnabled = state
    }
}

extension ComicStripViewController {
    private func showNavigationBar() {
        if appbarView.alpha == 0 {
            appbarView.startFadeInAnimation(duration: 0.2)
            bottomIndicatorView.startFadeInAnimation(duration: 0.2)
            isStatusBarHidden = false
        }
    }
    
    private func hideNavigationBar() {
        if appbarView.alpha == 1 {
            appbarView.startFadeOutAnimation(duration: 0.2)
            bottomIndicatorView.startFadeOutAnimation(duration: 0.2)
            isStatusBarHidden = true
        }
    }
}

extension ComicStripViewController: UIScrollViewDelegate {
    // Set scene scrollview zoomable
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return self.comicStripScrollView.contentView
    }
}

extension UIViewController: UIPopoverPresentationControllerDelegate {
    public func adaptivePresentationStyle(for controller: UIPresentationController,
                                          traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        return .none
    }
}

extension ComicStripViewController: PopOverComicEpisodeViewDelegate {
    func didEpisodeSelected(_ episode: EpisodeItem) {
        viewModel.renderComicStripScenes(episode)
    }
}
