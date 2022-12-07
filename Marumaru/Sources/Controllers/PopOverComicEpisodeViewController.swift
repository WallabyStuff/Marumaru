//
//  ComicEpisodePopOverViewController.swift
//  Marumaru
//
//  Created by 이승기 on 2021/05/08.
//

import UIKit

import RxSwift
import RxCocoa

protocol PopOverComicEpisodeViewDelegate: AnyObject {
  func didEpisodeSelected(_ selectedEpisode: EpisodeItem)
}

class PopOverComicEpisodeViewController: BaseViewController, ViewModelInjectable {
  
  // MARK: - Properties
  
  static let identifier = R.storyboard.popOverComicEpisode.popOverComicEpisodeStoryboard.identifier
  typealias ViewModel = PopOverComicEpisodeViewModel
  
  var viewModel: PopOverComicEpisodeViewModel
  weak var delegate: PopOverComicEpisodeViewDelegate?
  
  
  // MARK: - UI
  
  @IBOutlet weak var episodeTableView: UITableView!
  
  
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
  
  override func viewDidAppear(_ animated: Bool) {
    scrollToCurrentEpisode()
  }
  
  
  // MARK: - Setups
  
  private func setup() {
    setupView()
  }
  
  private func setupView() {
    setupEpisodeTableView()
  }
  
  private func setupEpisodeTableView() {
    registerEpisodeTableCell()
    episodeTableView.separatorInset = UIEdgeInsets.leftAndRight(16)
    episodeTableView.tableFooterView = UIView()
  }
  
  private func registerEpisodeTableCell() {
    let nibName = UINib(nibName: R.nib.popOverComicEpisodeTableCell.name,
                        bundle: nil)
    episodeTableView.register(nibName, forCellReuseIdentifier: PopOverComicEpisodeTableCell.identifier)
  }
  
  
  // MARK: - Bind
  
  private func bind() {
    bindEpisodeTableView()
    bindEpisodeTableItemSelected()
  }
  
  private func bindEpisodeTableView() {
    viewModel.episodes
      .bind(to: episodeTableView.rx.items(cellIdentifier: PopOverComicEpisodeTableCell.identifier,
                                          cellType: PopOverComicEpisodeTableCell.self)) { [weak self] _, episodeItem, cell in
        guard let self = self else { return }
        cell.configure(with: episodeItem, currentSN: self.viewModel.currentEpisodeSN)
      }.disposed(by: disposeBag)
  }
  
  private func bindEpisodeTableItemSelected() {
    episodeTableView.rx.itemSelected
      .asDriver()
      .drive(with: self, onNext: { vc, indexPath in
        let selectedEpisode = vc.viewModel.cellItemForRow(at: indexPath)
        vc.delegate?.didEpisodeSelected(selectedEpisode)
        vc.dismiss(animated: true, completion: nil)
      }).disposed(by: disposeBag)
  }
  
  
  // MARK: - Method
  
  private func scrollToCurrentEpisode() {
    if let index = viewModel.currentEpisodeIndex {
      let indexPath = IndexPath(row: index, section: 0)
      episodeTableView.scrollToRow(at: indexPath, at: .middle, animated: true)
    }
  }
}
