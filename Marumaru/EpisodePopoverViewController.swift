//
//  EpisodePopoverViewController.swift
//  Marumaru
//
//  Created by 이승기 on 2021/05/08.
//

import UIKit

protocol SelectItemDelegate {
    func loadSelectedEpisode(_ episode: Episode)
}

class EpisodePopoverViewController: UIViewController {
    
    var selectItemDelegate: SelectItemDelegate?
    
    var episodeArr = Array<Episode>()
    
    @IBOutlet weak var episodePopoverTableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        initDesign()
        initInstance()
    }
    
    func initDesign(){
        episodePopoverTableView.separatorInset = UIEdgeInsets(top: 0, left: 15, bottom: 0, right: 15)
    }
    
    func initInstance(){
        episodePopoverTableView.delegate = self
        episodePopoverTableView.dataSource = self
    }

}

extension EpisodePopoverViewController: UITableViewDelegate, UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return episodeArr.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if episodeArr.count <= indexPath.row{
            return UITableViewCell()
        }
        
        
        let episodeCell = tableView.dequeueReusableCell(withIdentifier: "popoverEpisodeCell") as! MangaEpisodePopoverCell
        
        episodeCell.episodeTitleLabel.text = episodeArr[indexPath.row].episodeTitle
        
        return episodeCell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if episodeArr.count > indexPath.row{
            selectItemDelegate?.loadSelectedEpisode(episodeArr[indexPath.row])
            dismiss(animated: true, completion: nil)
        }
    }
}
