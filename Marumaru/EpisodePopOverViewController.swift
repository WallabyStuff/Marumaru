//
//  EpisodePopoverViewController.swift
//  Marumaru
//
//  Created by 이승기 on 2021/05/08.
//

import UIKit

import RxSwift
import RxCocoa

@objc protocol EpisodePopOverViewDelegate: AnyObject {
    @objc optional func didEpisodeSelected(_ serialNumber: String)
}

class EpisodePopOverViewController: UIViewController {
    
    // MARK: - Declarations
    @IBOutlet weak var episodeTableView: UITableView!
    
    weak var delegate: EpisodePopOverViewDelegate?
    private var viewModel: EpisodePopOverViewModel
    private var disposeBag = DisposeBag()
    
    init?(
        coder: NSCoder,
        viewModel: EpisodePopOverViewModel
    ) {
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
    
    override func viewDidAppear(_ animated: Bool) {
        scrollToCurrentEpisode()
    }
    
    // MARK: - Setup
    private func setup() {
        setupView()
    }
    
    // MARK: - Setup View
    private func setupView() {
        setupEpisodeTableView()
    }
    
    private func setupEpisodeTableView() {
        episodeTableView.separatorInset = UIEdgeInsets(top: 0, left: 15, bottom: 0, right: 15)
        episodeTableView.tableFooterView = UIView()
        
        episodeTableView.delegate = self
        episodeTableView.dataSource = self
    }
    
    // MARK: - Bind
    private func bind() {
        setupEpisodeTableViewCell()
    }
    
    private func setupEpisodeTableViewCell() {
        episodeTableView.rx.itemSelected
            .asDriver()
            .drive(with: self, onNext: { vc, indexPath in
                let selectedEpisode = vc.viewModel.cellItemForRow(at: indexPath)
                vc.delegate?.didEpisodeSelected?(selectedEpisode.serialNumber)
                vc.dismiss(animated: true, completion: nil)
            }).disposed(by: disposeBag)
    }
    
    private func scrollToCurrentEpisode() {
        if let index = viewModel.currentEpisodeIndex {
            let indexPath = IndexPath(row: index, section: 0)
            episodeTableView.scrollToRow(at: indexPath, at: .middle, animated: true)
        }
    }
}

// MARK: - Extensions
extension EpisodePopOverViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.numberOfRowsInSection(section)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let episodeCell = tableView.dequeueReusableCell(withIdentifier: "popoverEpisodeCell") as? PopOverEpisodeCell else { return UITableViewCell() }
        
        let episode = viewModel.cellItemForRow(at: indexPath)
        episodeCell.episodeTitleLabel.text = episode.title
        
        if episode.serialNumber == viewModel.serialNumber {
            episodeCell.episodeTitleLabel.textColor = R.color.accentGreen()
            episodeCell.contentView.backgroundColor = R.color.accentBlueLightest()
        } else {
            episodeCell.episodeTitleLabel.textColor = R.color.textBlack()
            episodeCell.contentView.backgroundColor = R.color.backgroundWhite()
        }
        
        return episodeCell
    }
}
