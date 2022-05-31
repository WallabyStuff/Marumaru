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

class ComicStripViewController: BaseViewController, ViewModelInjectable {
    
    
    // MARK: - Properties
    
    typealias ViewModel = ComicStripViewModel
    
    @IBOutlet weak var appbarView: UIVisualEffectView!
    @IBOutlet weak var episodeTitleLabel: UILabel!
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var showEpisodeListButton: UIButton!
    @IBOutlet weak var nextEpisodeButton: UIButton!
    @IBOutlet weak var previousEpisodeButton: UIButton!
    @IBOutlet weak var bottomIndicatorView: UIView!
    @IBOutlet weak var appbarViewHieghtConstraint: NSLayoutConstraint!
    
    static let identifier = R.storyboard.comicStrip.comicStripStroyboard.identifier
    var viewModel: ViewModel
    private var cellHeightDictionary: NSMutableDictionary = [:]
    private let safeAreaInsets = UIApplication.shared.windows[0].safeAreaInsets
    private var isSceneZoomed = false
    private var sceneScrollView = FlexibleSceneScrollView()
    private var sceneDoubleTapGestureRecognizer = UITapGestureRecognizer()
    
    
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

    
    // MARK: - Setups
    
    private func setup() {
        setupData()
        setupView()
    }
    
    private func setupData() {
        viewModel.renderCurrentEpisodeScenes()
    }
    
    private func setupView() {
        setupSceneScrollView()
        setupBottomIndicatorView()
        setupPreviousEpisodeButton()
        setupShowEpisodeListButton()
        setupNextEpisodeButton()
    }
    
    private func setupSceneScrollView() {
        sceneScrollView = FlexibleSceneScrollView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height))
        sceneScrollView.minimumZoomScale = 1
        sceneScrollView.maximumZoomScale = 3
        sceneScrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: bottomIndicatorView.frame.height, right: 0)
        view.insertSubview(sceneScrollView, at: 0)
        sceneScrollView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        sceneScrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        sceneScrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        sceneScrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        sceneScrollView.delegate = self
    }
    
    private func setupBottomIndicatorView() {
        bottomIndicatorView.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        bottomIndicatorView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
    }
    
    private func setupNextEpisodeButton() {
        nextEpisodeButton.imageEdgeInsets(with: 8)
    }
    
    private func setupPreviousEpisodeButton() {
        previousEpisodeButton.imageEdgeInsets(with: 8)
    }
    
    private func setupShowEpisodeListButton() {
        showEpisodeListButton.imageEdgeInsets(with: 8)
    }
    
    
    // MARK: - Constraints
    
    override func updateViewConstraints() {
        super.updateViewConstraints()
        configureAppbarViewConstraints()
    }
    
    private func configureAppbarViewConstraints() {
        appbarViewHieghtConstraint.constant = view.safeAreaInsets.top + compactAppbarHeight
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
        viewModel.comicStripScenesObservable
            .subscribe(with: self, onNext: { vc, scenes in
                vc.sceneScrollView.sceneArr = scenes
                vc.sceneScrollView.reloadData()
                vc.viewModel.saveToWatchHistory()
            })
            .disposed(by: disposeBag)
    }
    
    private func bindComicStripLoadingState() {
        viewModel.isLoadingScenes
            .subscribe(with: self, onNext: { vc, isLoading in
                if isLoading {
                    vc.view.playRandomCatLottie()
                    vc.disableIndicatorButtons()
                    vc.sceneScrollView.clearAndReloadData()
                } else {
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
        sceneScrollView.rx
            .gesture(sceneTapGestureRocognizer)
            .when(.recognized)
            .subscribe(with: self, onNext: { vc, _ in
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
        sceneScrollView.addGestureRecognizer(sceneDoubleTapGestureRecognizer)
        sceneScrollView.rx
            .gesture(sceneDoubleTapGestureRecognizer)
            .when(.recognized)
            .subscribe(with: self, onNext: { vc, recognizer in
                let tapPoint = recognizer.location(in: vc.sceneScrollView.contentView)
                vc.zoom(point: tapPoint)
            })
            .disposed(by: disposeBag)
    }
    
    private func bindSceneScrollView() {
        sceneScrollView.rx.contentOffset
            .subscribe(with: self, onNext: { vc, offset in
                let overPanThreshold: CGFloat = 50
                // reached the top
                if offset.y < -(overPanThreshold + overPanThreshold) {
                    vc.showNavigationBar()
                }
                
                // reached the bottom
                if offset.y > vc.sceneScrollView.contentSize.height - vc.view.frame.height + overPanThreshold + vc.bottomIndicatorView.frame.height {
                    vc.showNavigationBar()
                }
            })
            .disposed(by: disposeBag)
        
        sceneScrollView.rx.panGesture()
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
    
    
    // MARK: - Methods
    
    private func presentComicEpisodePopoverVC() {
        let storyboard = UIStoryboard(name: R.storyboard.popOverComicEpisode.name, bundle: nil)
        let comicEpisodePopOverVC = storyboard.instantiateViewController(identifier: PopOverComicEpisodeViewController.identifier,
                                                                         creator: { [weak self] coder -> PopOverComicEpisodeViewController in
            let dumpVC = PopOverComicEpisodeViewController(.init("", []))
            guard let self = self else { return dumpVC }
            let viewModel = ComicEpisodePopOverViewModel(self.viewModel.serialNumber,
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
}


// MARK: - Extensions

extension ComicStripViewController {
    func zoom(point: CGPoint) {
        if isSceneZoomed {
            // zoom out
            sceneScrollView.zoom(to: CGRect(x: point.x,
                                            y: point.y,
                                            width: self.view.frame.width,
                                            height: self.view.frame.height),
                                 animated: true)
            isSceneZoomed = false
        } else {
            // zoom in
            hideNavigationBar()
            sceneScrollView.zoom(to: CGRect(x: point.x,
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
        return self.sceneScrollView.contentView
    }
}

extension UIViewController: UIPopoverPresentationControllerDelegate {
    public func adaptivePresentationStyle(for controller: UIPresentationController,
                                          traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        return .none
    }
}

extension ComicStripViewController: PopOverComicEpisodeViewDelegate {
    func didEpisodeSelected(_ episode: Episode) {
        viewModel.renderComicStripScenes(episode)
    }
}
