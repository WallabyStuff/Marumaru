//
//  SearchComicViewController.swift
//  Marumaru
//
//  Created by 이승기 on 2021/04/12.
//

import UIKit

import Lottie
import Hero
import RxSwift
import RxCocoa

class SearchComicViewController: UIViewController, ViewModelInjectable {
        
    
    // MARK: - Properties
    
    typealias ViewModel = SearchComicViewModel
    
    @IBOutlet weak var appbarView: UIView!
    @IBOutlet weak var searchTextField: UITextField!
    @IBOutlet weak var searchResultTableView: UITableView!
    @IBOutlet weak var backButton: UIButton!
    
    static let identifier = R.storyboard.searchComic.searchComicStoryboard.identifier
    var viewModel: ViewModel
    var disposeBag = DisposeBag()
    private var searchLoadingAnimationView = LottieAnimationView()
    private var isSearching = false
    private var searchResultPlaceholderLabel = StickyPlaceholderLabel()
    
    
    // MARK: - Initializers
    
    required init(_ viewModel: SearchComicViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        dismiss(animated: true)
    }
    
    required init?(_ coder: NSCoder, _ viewModel: SearchComicViewModel) {
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
        super.viewDidAppear(true)
        focusSearchTextField()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
    }
    
    
    // MARK: - Overrides
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .darkContent
    }
    
    
    // MARK: - Setup
    
    private func setup() {
        setupView()
    }
    
    private func setupView() {
        setupHero()
        setupAppbarView()
        setupSearchTextField()
        setupBackButton()
        setupSearchResultTableView()
    }
    
    private func setupHero() {
        self.hero.isEnabled = true
    }
    
    private func setupAppbarView() {
        appbarView.hero.id = "appbar"
        appbarView.layer.cornerRadius = 24
        appbarView.layer.maskedCorners = CACornerMask([.layerMaxXMaxYCorner, .layerMinXMaxYCorner])
    }
    
    private func setupSearchTextField() {
        searchTextField.layer.cornerRadius = 16
        searchTextField.layer.borderWidth = 2
        searchTextField.layer.borderColor = R.color.accentGreen()?.cgColor
        
        let paddingView = UIView(frame: CGRect(x: 0,
                                               y: 0,
                                               width: 15,
                                               height: searchTextField.frame.height))
        searchTextField.leftView = paddingView
        searchTextField.leftViewMode = .always
        
        searchTextField.returnKeyType = .search
        searchTextField.delegate = self
        searchTextField.becomeFirstResponder()
    }
    
    private func setupBackButton() {
        backButton.hero.id = "appbarButton"
        backButton.imageEdgeInsets(with: 10)
        backButton.layer.masksToBounds = true
        backButton.layer.cornerRadius = 12
    }
    
    private func setupSearchResultTableView() {
        let nibName = UINib(nibName: SearchResultComicTableCell.identifier, bundle: nil)
        searchResultTableView.register(nibName, forCellReuseIdentifier: SearchResultComicTableCell.identifier)
        searchResultTableView.delegate = self
        searchResultTableView.dataSource = self
        searchResultTableView.keyboardDismissMode = .onDrag
        
        searchResultTableView.contentInset = UIEdgeInsets(top: 56,
                                                               left: 0,
                                                               bottom: 40,
                                                               right: 0)
        
        viewModel.reloadSearchResultTableView = { [weak self] in
            self?.searchResultTableView.reloadData()
        }
    }
    
    
    // MARK: - Bind
    
    private func bind() {
        bindBackButton()
        bindSearchResultCell()
        bindSearchResultTableViewScroll()
    }
    
    private func bindBackButton() {
        backButton.rx.tap
            .asDriver()
            .drive(onNext: { [weak self] in
                self?.dismiss(animated: true, completion: nil)
            }).disposed(by: disposeBag)
    }
    
    private func bindSearchResultCell() {
        searchResultTableView.rx.itemSelected
            .asDriver()
            .drive(with: self, onNext: { vc, indexPath in
                let comicInfo = vc.viewModel.cellItemForRow(at: indexPath)
                vc.presentComicDetailVC(comicInfo)
            }).disposed(by: disposeBag)
    }
    
    private func bindSearchResultTableViewScroll() {
        searchResultTableView.rx.willBeginDragging
            .asDriver()
            .drive(onNext: { [weak self] in
                self?.view.endEditing(true)
            }).disposed(by: disposeBag)
    }
    
    
    // MARK: - Methods
    
    private func setSearchResult(title: String) {
        if title.count < 1 {
            searchLoadingAnimationView.stop()
            self.view.makeToast("최소 한 글자 이상의 단어로 검색해주세요")
            return
        }
        
        isSearching = true
        playSearchLoadingAnimation()
        searchResultPlaceholderLabel.detatchLabel()
        view.endEditing(true)
        
        viewModel.getSearchResult(title)
            .subscribe(with: self, onError: { vc, error in
                if let error = error as? SearchViewError {
                    vc.searchResultPlaceholderLabel.attatchLabel(text: error.message, to: vc.view)
                }
            }, onDisposed: { vc in
                vc.searchLoadingAnimationView.stop()
                vc.isSearching = false
            }).disposed(by: disposeBag)
    }
    
    private func presentComicDetailVC(_ comicInfo: ComicInfo) {
        let storyboard = UIStoryboard(name: R.storyboard.comicDetail.name, bundle: nil)
        let comicDetailVC = storyboard.instantiateViewController(identifier: ComicDetailViewController.identifier,
                                                             creator: { coder -> ComicDetailViewController in
            let viewModel = ComicDetailViewModel()
            return .init(coder, viewModel) ?? ComicDetailViewController(.init())
        })
        
        comicDetailVC.modalPresentationStyle = .fullScreen
        comicDetailVC.currentComic = comicInfo
        present(comicDetailVC, animated: true, completion: nil)
    }
    
    private func playSearchLoadingAnimation() {
        searchLoadingAnimationView.play(name: "loading_cat_radial",
                                        size: CGSize(width: 100, height: 100),
                                        to: view)
    }
    
    private func focusSearchTextField() {
        searchTextField.becomeFirstResponder()
    }
}


// MARK: - Extensions

extension SearchComicViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        // Seach action on keyboard
        if let title = textField.text?.trimmingCharacters(in: .whitespaces) {
            if isSearching {
                self.view.makeToast("검색중입니다.")
                return true
            } else {
                setSearchResult(title: title)
            }
        }
        
        return true
    }
}

extension SearchComicViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.numberOfRowsIn(section: 0)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let searchResultCell = tableView.dequeueReusableCell(withIdentifier: SearchResultComicTableCell.identifier) as? SearchResultComicTableCell else { return UITableViewCell() }
        
        let comicInfo = viewModel.cellItemForRow(at: indexPath)
        
        searchResultCell.titleLabel.text = comicInfo.title
        searchResultCell.thumbnailImagePlaceholderLabel.text = comicInfo.title
        searchResultCell.descriptionLabel.text = comicInfo.author.isEmpty ? "작가정보 없음" : comicInfo.author
        searchResultCell.updateCycleLabel.text = comicInfo.updateCycle
        
        if comicInfo.updateCycle.contains("미분류") {
            searchResultCell.updateCycleLabel.setBackgroundHighlight(with: R.color.accentGray() ?? .clear,
                                                                     textColor: R.color.textWhite() ?? .black)
        } else {
            searchResultCell.updateCycleLabel.setBackgroundHighlight(with: R.color.accentBlue() ?? .clear,
                                                                     textColor: R.color.textWhite() ?? .black)
        }
        
        if let thumbnailImageUrl = comicInfo.thumbnailImageURL {
            let token = viewModel.requestImage(thumbnailImageUrl) { result in
                do {
                    let resultImage = try result.get()
                    DispatchQueue.main.async {
                        searchResultCell.thumbnailImagePlaceholderLabel.isHidden = true
                        searchResultCell.thumbnailImageView.image = resultImage.imageCache.image
                        searchResultCell.thumbnailImageBaseView.setThumbnailShadow(with: resultImage.imageCache.averageColor.cgColor)
                        
                        if resultImage.animate {
                            searchResultCell.thumbnailImageView.startFadeInAnimation(duration: 0.3)
                        }
                    }
                } catch {
                    DispatchQueue.main.async {
                        searchResultCell.thumbnailImagePlaceholderLabel.isHidden = false
                    }
                }
            }
            
            searchResultCell.onReuse = { [weak self] in
                if let token = token {
                    self?.viewModel.cancelImageRequest(token)
                }
            }
        }
        
        return searchResultCell
    }
}
