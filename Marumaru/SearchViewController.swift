//
//  SearchViewController.swift
//  Marumaru
//
//  Created by 이승기 on 2021/04/12.
//

import UIKit

import Lottie
import Hero
import RxSwift
import RxCocoa

class SearchViewController: UIViewController {
    
    // MARK: - Declarations
    var disposeBag = DisposeBag()
    var networkHandler = NetworkHandler()
    
    var searchResultMangaArr: [MangaInfo] = []
    var loadingSearchAnimView = LoadingView()
    var isSearching = false
    
    @IBOutlet weak var appbarView: UIView!
    @IBOutlet weak var searchTextField: UITextField!
    @IBOutlet weak var searchResultMangaTableView: UITableView!
    @IBOutlet weak var noResultsLabel: UILabel!
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var searchResultPlaceholderLabel: UILabel!
    
    // MARK: - LifeCycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initView()
        initInstance()
        initEventListener()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        
        focusToSearchTextField()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
    }
    
    // MARK: - Overrides
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .darkContent
    }
    
    // MARK: - Initializations
    func initView() {
        // hero enable
        self.hero.isEnabled = true
        
        // appbarView
        appbarView.hero.id = "appbar"
        appbarView.layer.cornerRadius = 40
        appbarView.layer.maskedCorners = CACornerMask([.layerMaxXMaxYCorner, .layerMinXMaxYCorner])
        
        // search TextField
        searchTextField.layer.cornerRadius = 15
        searchTextField.layer.borderWidth = 2
        searchTextField.layer.borderColor = ColorSet.accentColor?.cgColor
        
        // Add padding to search textfield
        let paddingView = UIView(frame: CGRect(x: 0,
                                               y: 0,
                                               width: 15,
                                               height: self.searchTextField.frame.height))
        searchTextField.leftView = paddingView
        searchTextField.leftViewMode = .always
        
        // Textfield keyboard return type to search
        searchTextField.returnKeyType = .search
        searchTextField.delegate = self
        
        // back Button
        backButton.hero.id = "appbarButton"
        backButton.imageEdgeInsets(with: 10)
        backButton.layer.masksToBounds = true
        backButton.layer.cornerRadius = 13
        
        // search loading AnimView
        loadingSearchAnimView = LoadingView(name: "loading_cat_radial",
                                            frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        view.addSubview(self.loadingSearchAnimView)
        loadingSearchAnimView.setConstraint(width: 100, targetView: view)
        
        // result manga Tableview
        searchResultMangaTableView.contentInset = UIEdgeInsets(top: 60,
                                                               left: 0,
                                                               bottom: 40,
                                                               right: 0)
    }
    
    func initInstance() {
        /// Network Handler
        networkHandler = NetworkHandler()
        
        // result manga TableView
        let searchResultMangaTableCellNib = UINib(nibName: "MangaThumbnailTableViewCell", bundle: nil)
        searchResultMangaTableView.register(searchResultMangaTableCellNib, forCellReuseIdentifier: "mangaThumbnailTableCell")
        searchResultMangaTableView.delegate = self
        searchResultMangaTableView.dataSource = self
        searchResultMangaTableView.keyboardDismissMode = .onDrag
    }
    
    func initEventListener() {
        // back Button Action
        backButton.rx.tap
            .asDriver()
            .drive(onNext: { [weak self] in
                self?.dismiss(animated: true)
            })
            .disposed(by: disposeBag)
    }
    
    // MARK: - Methods
    func setSearchResult(title: String) {
        
        searchResultMangaArr.removeAll()
        searchResultMangaTableView.reloadData()
        noResultsLabel.isHidden = true
        searchResultPlaceholderLabel.isHidden = true
        loadingSearchAnimView.play()
        isSearching = true
        view.endEditing(true)
        
        if title.count < 1 {
            loadingSearchAnimView.stop()
            noResultsLabel.isHidden = false
            self.view.makeToast("최소 한 글자 이상의 단어로 검색해주세요")
            
            return
        }
        
        DispatchQueue.global(qos: .background).async { [weak self] in
            guard let self = self else { return }
            
            self.networkHandler.getSearchResult(title: title) { [weak self] result in
                guard let self = self else { return }
                
                do {
                    let result = try result.get()
                    self.searchResultMangaArr = result
                    
                    DispatchQueue.main.async {
                        self.loadingSearchAnimView.stop()
                        self.reloadResultTableView()
                    }
                } catch {
                    // failure state
                    DispatchQueue.main.async {
                        self.searchResultPlaceholderLabel.isHidden = false
                        self.loadingSearchAnimView.stop()
                    }
                }
            }
        }
    }
    
    func focusToSearchTextField() {
        // focus to search textField and show up the keyboard
        if searchResultMangaArr.count == 0 {
            searchTextField.becomeFirstResponder()
        }
    }
    
    func reloadResultTableView() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            self.searchResultMangaTableView.reloadData()
            self.isSearching = false
            
            if self.searchResultMangaArr.count == 0 {
                self.noResultsLabel.isHidden = false
            } else {
                self.noResultsLabel.isHidden = true
            }
        }
    }
    
    private func presentEpisdoeVC(_ mangaInfo: MangaInfo) {
        guard let episodeVC = storyboard?.instantiateViewController(identifier: "MangaEpisodeStoryboard") as? MangaEpisodeViewController else { return }
        
        episodeVC.modalPresentationStyle = .fullScreen
        episodeVC.currentManga = mangaInfo
        
        present(episodeVC, animated: true, completion: nil)
    }
}

// MARK: - Extensions
extension SearchViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        // Seach action on keyboard
        if let title = textField.text?.trimmingCharacters(in: .whitespaces) {
            if isSearching {
                self.view.makeToast("please wait for searching")
                return true
            }
            
            setSearchResult(title: title)
        }
        
        return true
    }
}

extension SearchViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchResultMangaArr.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "mangaThumbnailTableCell") as? MangaThumbnailTableCell else { return UITableViewCell() }
        
        if indexPath.row > searchResultMangaArr.count - 1 {
            return UITableViewCell()
        }
        
        cell.titleLabel.text = searchResultMangaArr[indexPath.row].title
        cell.thumbnailImagePlaceholderLabel.text = searchResultMangaArr[indexPath.row].title
        cell.authorLabel.text = searchResultMangaArr[indexPath.row].author
        cell.updateCycleLabel.text = searchResultMangaArr[indexPath.row].updateCycle
        
        if !searchResultMangaArr[indexPath.row].updateCycle.contains("미분류") {
            cell.setUpdateCycleLabelBackgroundTint()
        }
        
        if let previewImageUrl = searchResultMangaArr[indexPath.row].thumbnailImageURL,
           let url = URL(string: previewImageUrl) {
            
            let token = networkHandler.getImage(url) { [weak self] result in
                DispatchQueue.global(qos: .background).async { [weak self] in
                    do {
                        let result = try result.get()
                        DispatchQueue.main.async { [weak self] in
                            guard let self = self else { return }

                            // image loaded
                            cell.thumbnailImageView.image = result.imageCache.image
                            cell.thumbnailImagePlaceholderLabel.isHidden = true
                            cell.thumbnailImageBaseView.setThumbnailShadow(with: result.imageCache.averageColor.cgColor)
                            self.searchResultMangaArr[indexPath.row].thumbnailImage = result.imageCache.image

                            if result.animate {
                                cell.thumbnailImageView.startFadeInAnim(duration: 0.5)
                            }
                        }
                    } catch {
                        DispatchQueue.main.async {
                            cell.thumbnailImagePlaceholderLabel.isHidden = false
                        }
                    }
                }
            }

            cell.onReuse = { [weak self] in
                if let token = token {
                    self?.networkHandler.cancelLoadImage(token)
                }
            }
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let manga = searchResultMangaArr[indexPath.row]
        
        let mangaInfo = MangaInfo(title: manga.title,
                                  author: manga.author,
                                  updateCycle: manga.updateCycle,
                                  thumbnailImage: manga.thumbnailImage,
                                  thumbnailImageURL: manga.thumbnailImageURL,
                                  mangaSN: manga.mangaSN)
        
        presentEpisdoeVC(mangaInfo)
    }
}

extension SearchViewController: UIScrollViewDelegate {
    func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView) {
        self.view.endEditing(true)
    }
}
