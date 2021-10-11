//
//  StickerViewController.swift
//  Sticker
//
//  Created by Purkylin King on 2020/5/26.
//  Copyright © 2020 Purkylin King. All rights reserved.
//

import UIKit

class StickerViewController: UIViewController {
    
    lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = .init(width: 80, height: 80)
        let node = UICollectionView(frame: .zero, collectionViewLayout: layout)
        return node
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .white
        StickerResource.shared.loadData()
        setupViews()
    }
    
    func setupViews() {
        let btn = UIButton(frame: CGRect(x: 10, y: 50, width: 100, height: 60))
        btn.setTitle("back", for: .normal)
        btn.addTarget(self, action: #selector(StickerViewController.dismis), for: .touchUpInside)
        btn.setTitleColor(.black, for: .normal)
        self.view.addSubview(btn)
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.frame = CGRect(x: 0, y: 100, width: view.bounds.width, height: view.bounds.height / 2)
        collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        collectionView.register(StickerCell.self, forCellWithReuseIdentifier: "StickerCellNode")
        self.view.addSubview(self.collectionView)
    }
    
    @objc func dismis() {
        self.dismiss(animated: true, completion: nil)
    }
}

extension StickerViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return StickerResource.shared.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "StickerCellNode", for: indexPath) as! StickerCell
        let path = StickerResource.shared.urls[indexPath.row]
        cell.update(path)
        return cell
    }
}


class StickerResource {
    static var shared = StickerResource()
    
    private init() { }
    
    public var urls = [String]()
    
    var count: Int {
        return urls.count
    }
    
    public func loadData() {
//        let paths = Bundle.main.paths(forResourcesOfType: "", inDirectory: "cache")
//        guard paths.count > 0 else {
//            fatalError("Can't load tgs files")
//        }
        self.urls = [
            "https://secretfile.blob.core.windows.net/emojitgs/Cat2O/Cat2O.tgs",
            "https://secretfile.blob.core.windows.net/emojitgs/PaulOctopus/2_765673509304140441.tgs",
            "https://secretfile.blob.core.windows.net/emojitgs/PaulOctopus/2_765673509304140442.tgs",
            "https://secretfile.blob.core.windows.net/emojitgs/PaulOctopus/2_765673509304140443.tgs",
            "https://secretfile.blob.core.windows.net/emojitgs/PaulOctopus/2_765673509304140439.tgs"
        ]
//        self.urls = ["https://secretapp.azureedge.net/emojitgs/secret2/bt.gif",
//        "https://secretapp.azureedge.net/emojitest/tgs_test1/2_1391391008142393345.tgs"]
        self.urls = self.urls + self.urls + self.urls + self.urls + self.urls + self.urls + self.urls + self.urls + self.urls + self.urls + self.urls + self.urls + self.urls + self.urls + self.urls + self.urls
        
    }
}
