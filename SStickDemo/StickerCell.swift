//
//  StickerCell.swift
//  Sticker
//
//  Created by Purkylin King on 2020/5/26.
//  Copyright © 2020 Purkylin King. All rights reserved.
//

import UIKit
import SSticker

class StickerCell: UICollectionViewCell {
    
    private let render = StickerAnimatedImageView(frame: .zero)
    private var cacheData: Data?
    let queue = DispatchQueue(label: "StickerCellNode")
    
    deinit {
        print("StickerCell  --------  deinit")
    }
    
    override init(frame: CGRect) {
        super.init(frame: .zero)
        print("StickerCell -------- init")
        render.translatesAutoresizingMaskIntoConstraints = false
        self.contentView.addSubview(render)
        render.leftAnchor.constraint(equalTo: self.contentView.leftAnchor).isActive
         = true
        render.rightAnchor.constraint(equalTo: self.contentView.rightAnchor).isActive = true
        render.topAnchor.constraint(equalTo: self.contentView.topAnchor).isActive = true
        render.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor).isActive = true
    }
    
    func update(_ path: String) {
        self.render.setSecretAnimation(URL(string: path)!, CGSize(width: 160, height: 160))
    }
    
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
