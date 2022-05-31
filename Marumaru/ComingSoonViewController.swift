//
//  ComingSoonViewController.swift
//  Marumaru
//
//  Created by 이승기 on 2022/05/29.
//

import UIKit

class ComingSoonViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = R.color.backgroundWhite()!
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        view.playLottie(animation: .general(.comming_soon), size: .init(width: 240, height: 240))
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        view.stopLottie()
    }
}
