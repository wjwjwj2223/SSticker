//
//  ResourceDownloader.swift
//  SStickDemo
//
//  Created by 王杰 on 2020/5/29.
//  Copyright © 2020 王杰. All rights reserved.
//

import Foundation
import SDWebImage

let stickerWriteQueue = DispatchQueue(label: "stickerWriteQueue")

private let downloader: SDWebImageDownloader = {
    let configuration = URLSessionConfiguration.default
    if !FileManager.default.fileExists(atPath: StickerStickerOriginPath) {
        try? FileManager.default.createDirectory(atPath: StickerStickerOriginPath, withIntermediateDirectories: true, attributes: [:])
    }
    if !FileManager.default.fileExists(atPath: StickerStickerGeneratePath) {
        try? FileManager.default.createDirectory(atPath: StickerStickerGeneratePath, withIntermediateDirectories: true, attributes: [:])
    }
    if !FileManager.default.fileExists(atPath: StickerStickerPreViewPath) {
        try? FileManager.default.createDirectory(atPath: StickerStickerPreViewPath, withIntermediateDirectories: true, attributes: [:])
    }
    return SDWebImageDownloader.shared
}()

func downloadResourceWith(_ url: URL, completion: ((_ origin: String, _ filePath: String) ->Void)? = nil ) {
    let destinationPath = StickerStickerOriginPath + "/" + url.absoluteString.md5TGS
    if FileManager.default.fileExists(atPath: destinationPath) {
        completion?(url.absoluteString, destinationPath)
    }
    downloader.downloadImage(with: url, options: [.continueInBackground], progress: nil) { (_, data, _, _) in
        if let d = data {
            stickerWriteQueue.async {
                try? d.write(to: URL(fileURLWithPath: destinationPath))
                completion?(url.absoluteString, destinationPath)
            }
        }
    }
}
