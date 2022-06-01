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
    typealias ViewModel = ComicEpisodePopOverViewModel
    
    @IBOutlet weak var episodeTableView: UITableView!
    
    static let identifier = R.storyboard.popOverComicEpisode.popOverComicEpisodeStoryboard.identifier
    weak var delegate: PopOverComicEpisodeViewDelegate?
    var viewModel: ComicEpisodePopOverViewModel
    
    
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
        episodeTableView.separatorInset = UIEdgeInsets(top: 0, left: 15, bottom: 0, right: 15)
        episodeTableView.tableFooterView = UIView()
        
        let nibName = UINib(nibName: R.nib.popOverComicEpisodeTableCell.identifier,
                            bundle: nil)
        episodeTableView.register(nibName, forCellReuseIdentifier: PopOverComicEpisodeTableCell.identifier)
        
        episodeTableView.rx.itemSelected
            .asDriver()
            .drive(with: self, onNext: { vc, indexPath in
                let selectedEpisode = vc.viewModel.cellItemForRow(at: indexPath)
                vc.delegate?.didEpisodeSelected(selectedEpisode)
                vc.dismiss(animated: true, completion: nil)
            }).disposed(by: disposeBag)
    }

    
    // MARK: - Bind
    
    private func bind() {
        bindEpisodeTableView()
    }
    
    private func bindEpisodeTableView() {
        viewModel.episodesObservable
            .bind(to: episodeTableView.rx.items(cellIdentifier: PopOverComicEpisodeTableCell.identifier,
                                                cellType: PopOverComicEpisodeTableCell.self)) { _, episode, cell in
                cell.episodeTitleLabel.text = episode.title
                
                if episode.episodeSN == self.viewModel.currentEpisodeSN {
                    cell.setHighlighted()
                } else {
                    cell.setUnHighlighted()
                }
            }.disposed(by: disposeBag)
    }

    
    private func scrollToCurrentEpisode() {
        if let index = viewModel.currentEpisodeIndex {
            let indexPath = IndexPath(row: index, section: 0)
            episodeTableView.scrollToRow(at: indexPath, at: .middle, animated: true)
        }
    }
}
