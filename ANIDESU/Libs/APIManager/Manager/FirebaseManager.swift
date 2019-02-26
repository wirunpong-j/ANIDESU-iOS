//
//  FirebaseManager.swift
//  ANIDESU
//
//  Created by Wirunpong Jaingamlertwong on 24/2/2562 BE.
//  Copyright © 2562 Wirunpong Jaingamlertwong. All rights reserved.
//

import Foundation
import FirebaseAuth
import FirebaseStorage
import FirebaseDatabase
import FirebaseFirestore

class FirebaseManager {
    
//    func createPost(message: String, onSuccess: @escaping () -> (), onFailure: @escaping (Error) -> ()) {
//        let db = Firestore.firestore()
//        let router = FirestoreRouter.createPost(message: message)
//
//        db.collection(router.path).addDocument(data: router.parameters!) { (error) in
//            if let error = error {
//                onFailure(error)
//            } else {
//                onSuccess()
//            }
//        }
//    }
    
    func fetchAllPost(completion: @escaping ([PostResponse]) -> (), onFailure: @escaping (BaseError) -> ()) {
        let db = Firestore.firestore()
        let router = FirestoreRouter.fetchAllPost
        
        db.collection(router.path).getDocuments { (allData, error) in
            if let error = error {
                onFailure(BaseError(message: error.localizedDescription))
            } else {
                var allPost = [PostResponse]()
                
                if let allData = allData, !allData.isEmpty {
                    for data in allData.documents {
                        let jsonData = try! JSONSerialization.data(withJSONObject: data.data())
                        let post = try! JSONDecoder().decode(PostResponse.self, from: jsonData)
                        post.key = data.documentID
                        
                        self.getUserInfo(uid: post.uid!, completion: { (userResponse) in
                            post.user = userResponse
                            allPost.append(post)

                            if allPost.count == allData.count {
                                allPost = allPost.sorted(by: { $0.date! > $1.date! })
                                completion(allPost)
                            }
                        }, onFailure: { (error) in
                            onFailure(BaseError(message: error.localizedDescription))
                        })
                    }
                } else {
                    completion(allPost)
                }
            }
        }
    }
    
    func getUserInfo(uid: String, completion: @escaping (UserResponse) -> (), onFailure: @escaping (BaseError) -> ()) {
        let db = Firestore.firestore()
        let router = FirestoreRouter.fetchUserData(uid: uid)
        print("|-------------------------------------------------")
        print("REQUEST: \(router.path)")
        print("-------------------------------------------------|")
        
        db.document(router.path).getDocument { (snapshot, error) in
            if let error = error {
                onFailure(BaseError(message: error.localizedDescription))
            } else {
                self.showLog(path: router.path, data: snapshot?.data())
                let jsonData = try! JSONSerialization.data(withJSONObject: snapshot!.data())
                let userResponse = try! JSONDecoder().decode(UserResponse.self, from: jsonData)
                
                completion(userResponse)
            }
        }
    }
    
    func showLog(path: String, data: [String: Any]?) {
        print("|-------------------------------------------------")
        print("RESPONSE: \(path)")
        if let pretty = try? JSONSerialization.data(withJSONObject: data, options: .prettyPrinted) {
            if let string = String(data: pretty, encoding: .utf8) {
                print("JSON: \(string)")
            }
        } else {
            print("ERROR: Couldn't create json object from returned data")
        }
        print("-------------------------------------------------|")
    }
}
