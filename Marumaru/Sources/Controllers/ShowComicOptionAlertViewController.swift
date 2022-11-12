//
//  ShowComicOptionAlertViewController.swift
//  Marumaru
//
//  Created by 이승기 on 2022/06/09.
//

import UIKit

import RxSwift
import RxCocoa

protocol ShowComicOptionAlertViewDelegate: AnyObject {
  func didTapShowComicStripButton(_ comicEpisode: ComicEpisode)
  func didTapShowComicDetailButton(_ comicInfo: ComicInfo)
}

class ShowComicOptionAlertViewController: BaseViewController, ViewModelInjectable {
  
  
  // MARK: - Properties
  
  static let identifier = R.storyboard.showComicOption.showComicOptionStoryboard.identifier
  typealias ViewModel = ShowComicOptionAlertViewModel
  
  var viewModel: ShowComicOptionAlertViewModel
  weak var delegate: ShowComicOptionAlertViewDelegate?
  
  
  // MARK: - UI
  
  @IBOutlet weak var episodeTitleLabel: UILabel!
  @IBOutlet weak var showComicStripButton: UIButton!
  @IBOutlet weak var showComicDetailButton: UIButton!
  @IBOutlet weak var closeButton: UIButton!
  
  
  // MARK: - Initializers
  
  required init(_ viewModel: ShowComicOptionAlertViewModel) {
    self.viewModel = viewModel
    super.init(nibName: nil, bundle: nil)
  }
  
  required init?(_ coder: NSCoder, _ viewModel: ShowComicOptionAlertViewModel) {
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
  
  
  // MARK: - Setups
  
  private func setup() {
    setupView()
  }
  
  private func setupView() {
    setupEpisodeTitleLabel()
  }
  
  private func setupEpisodeTitleLabel() {
    episodeTitleLabel.text = viewModel.episodeTitle
  }
  
  
  // MARK: - Binds
  
  private func bind() {
    bindCloseButton()
    bindShowComicStirpButton()
    bindShowComicDetailButton()
  }
  
  private func bindCloseButton() {
    closeButton.rx.tap
      .asDriver()
      .drive(with: self, onNext: { vc, _ in
        vc.dismiss(animated: true)
      })
      .disposed(by: disposeBag)
  }
  
  private func bindShowComicStirpButton() {
    showComicStripButton.rx.tap
      .asDriver()
      .drive(with: self, onNext: { vc, _ in
        vc.viewModel.showComicStripAction()
      })
      .disposed(by: disposeBag)
    
    viewModel.presentComicStripVC
      .subscribe(with: self, onNext: { vc, comicEpisode in
        vc.presentComicStripVC(comicEpisode)
      })
      .disposed(by: disposeBag)
  }
  
  private func bindShowComicDetailButton() {
    showComicDetailButton.rx.tap
      .asDriver()
      .drive(with: self, onNext: { vc, _ in
        vc.viewModel.showComicDetailAction()
      })
      .disposed(by: disposeBag)
    
    viewModel.presentComicDetailVC
      .subscribe(with: self, onNext: { vc, comicInfo in
        vc.presentComicDetailVC(comicInfo)
      })
      .disposed(by: disposeBag)
  }
  
  
  // MARK: - Methods
  
  private func presentComicStripVC(_ comicEpisode: ComicEpisode) {
    dismiss(animated: true) {
      self.delegate?.didTapShowComicStripButton(comicEpisode)
    }
  }
  
  private func presentComicDetailVC(_ comicInfo: ComicInfo) {
    dismiss(animated: true) {
      self.delegate?.didTapShowComicDetailButton(comicInfo)
    }
  }
}
