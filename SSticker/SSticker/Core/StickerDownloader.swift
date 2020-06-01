//
//  ResourceDownloader.swift
//  SStickDemo
//
//  Created by 王杰 on 2020/5/29.
//  Copyright © 2020 王杰. All rights reserved.
//

import Foundation
import Alamofire


private let DownlaodSessionManager: Session = {
    let configuration = URLSessionConfiguration.default
    if !FileManager.default.fileExists(atPath: StickerStickerOriginPath) {
        try? FileManager.default.createDirectory(atPath: StickerStickerOriginPath, withIntermediateDirectories: true, attributes: [:])
    }
    if !FileManager.default.fileExists(atPath: StickerStickerGeneratePath) {
        try? FileManager.default.createDirectory(atPath: StickerStickerGeneratePath, withIntermediateDirectories: true, attributes: [:])
    }
    return Session(
        configuration: configuration
    )
}()

func downloadResourceWith(_ url: URL, completion: ((_ origin: String, _ filePath: String) ->Void)? = nil ) {
    let destinationPath = StickerStickerOriginPath + "/" + url.absoluteString.md5TGS
    if FileManager.default.fileExists(atPath: destinationPath) {
        completion?(url.absoluteString, destinationPath)
    }
    let request = DownlaodSessionManager.download(url, interceptor: nil) { (url, resp) -> (destinationURL: URL, options: DownloadRequest.Options) in
        return (URL(fileURLWithPath: destinationPath) , .createIntermediateDirectories)
    }
    request.response { (resp) in
        guard let file = resp.fileURL else {return}
        completion?(url.absoluteString, file.path)
    }
}
