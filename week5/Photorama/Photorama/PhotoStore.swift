//
//  PhotoStore.swift
//  Photorama
//
//  Created by 임성훈 on 2017. 7. 29..
//  Copyright © 2017년 임성훈. All rights reserved.
//

import UIKit

enum ImageResult {
    case success(UIImage)
    case failure(Error)
}

enum PhotoError: Error {
    case imageCreationError
    case invalidData
}

class PhotoStore {
    let session: URLSession = {
        let config = URLSessionConfiguration.default
        return URLSession(configuration: config)
    }()
    
    func fetchRecentPhotos(completion: @escaping (PhotosResult) -> Void) {
        guard let url = FlickrAPI.recentPhotosURL() else { return }
        
        let request = URLRequest(url: url)
        let task = session.dataTask(with: request) {
            (data, response, error) -> () in
            if let response = response as? HTTPURLResponse {
                print("StatusCode: \(response.statusCode)")
                print("HeaderField: \(response.allHeaderFields)")
            }
            
            let result = self.processRecentPhotosRequest(data: data, error: error)
            
            completion(result)
        }
        
        task.resume()
    }
    
    func processRecentPhotosRequest(data: Data?, error: Error?) -> PhotosResult {
        guard let jsonData = data else {
            guard let error = error else {
                return .failure(FlickrError.unexpectedError)
            }
            return .failure(error)
        }
        
        return FlickrAPI.photosFromJSONData(jsonData)
    }
    
    func fetchImageFor(photo: Photo, completion: @escaping (ImageResult) -> Void) {
        let photoURL = photo.remoteURL
        let request = URLRequest(url: photoURL)
        let task = session.dataTask(with: request) {
            [unowned self] (data, response, error) -> () in
            let result = self.processImageRequest(data: data, error: error)
            
            if case let .success(image) = result {
                photo.image = image
            }
            
            completion(result)
        }
        task.resume()
    }
    
    func processImageRequest(data: Data?, error: Error?) -> ImageResult {
        guard let imageData = data, let image = UIImage(data: imageData) else {
            if data == nil {
                return .failure(PhotoError.invalidData)
            } else {
                return .failure(PhotoError.imageCreationError)
            }
        }
        
        return .success(image)
    }
}