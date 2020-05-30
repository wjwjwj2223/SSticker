//
//  ViewController.swift
//  SStickDemo
//
//  Created by 王杰 on 2020/5/28.
//  Copyright © 2020 王杰. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    let btn = UIButton()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
    }
    
    func setupViews() {
        view.addSubview(btn)
        btn.center = self.view.center
        btn.bounds = CGRect(x: 0, y: 0, width: 30, height: 60)
        btn.setTitle("Test", for: .normal)
        btn.setTitleColor(.black, for: .normal)
        btn.setTitleColor(.red, for: .normal)
        btn.addTarget(self, action: #selector(btnClicked), for: .touchUpInside)
    }
    
    @objc func btnClicked() {
        self.present(StickerViewController(), animated: true, completion: nil)
    }
}
