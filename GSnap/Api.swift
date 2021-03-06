//
//  Api.swift
//  GSnap
//
//  Created by Munesada Yohei on 2019/02/05.
//  Copyright © 2019 Munesada Yohei. All rights reserved.
//

import Alamofire

// ログイン処理後のコールバック
typealias LoginCallback = (String?) -> Void

// タイムライン取得後のコールバック
typealias TimelineCallback = (String?, [Post]?) -> Void

// APIのエンドポイント.
let apiRoot = "http://gsnap.yoheim.tech"

// Apiクラス.
class Api {

    // ログインAPI.
    static func login(id: String, password: String, callback: @escaping(LoginCallback)) {
        
        // URLを作成する.
        let url = apiRoot + "/api/login"
        
        // 送信データを作成する.
        let params = [
            "login_id" : id,
            "password" : password
        ]
        
        // POSTでAPIコールする.
        let request = Alamofire.request(url, method: .post, parameters: params, encoding: JSONEncoding.default)
        
        // 結果をJSONで受け取る.
        request.responseJSON { responseData in
            
            // ネットワーク切断など、失敗した場合.
            if responseData.result.isFailure {
                print("エラーだよ. \(String(describing: responseData.error))")
                callback("エラーが発生しました")
                return
            }
            
            // ステータスコードを取得する.
            guard let statusCode = responseData.response?.statusCode else {
                return
            }
            
            // サーバーからのレスポンスを受け取る.
            guard let data = responseData.result.value as? [String : Any] else {
                return
            }
            
            // 失敗した場合.
            if statusCode != 200 {
                if let message = data["message"] as? String {
                    callback(message)
                }
                return
            }
            
            // 成功した場合は、ユーザーIDとAPIトークンを保存する.
            if let userId = data["id"] as? Int {
                UserDefaults.standard.set(userId, forKey: "userId")
            }
            if let apiToken = data["api_token"] as? String {
                UserDefaults.standard.set(apiToken, forKey: "apiToken")
            }
            
            // 完了.
            callback(nil)
            
        }
    }
    
    // タイムライン取得API.
    static func getTimeline(callback: @escaping(TimelineCallback)) {
        
        // APIトークンがない場合には、エラー.
        guard let apiToken = UserDefaults.standard.string(forKey: "apiToken") else {
            callback("ログインが必要です", nil)
            return
        }
        
        // URLを作成します.
        let url = apiRoot + "/api/posts?api_token=" + apiToken
        
        // GET通信でリクエストを送信します.
        let request = Alamofire.request(url)
        
        // 値をJSON形式で取得します.
        request.responseData { (responseData) in

            // ネットワーク切断など、失敗した場合.
            if responseData.result.isFailure {
                print("エラーだよ. \(String(describing: responseData.error))")
                callback("エラーが発生しました", nil)
                return
            }
            
            // ステータスコードを取得する.
            guard let statusCode = responseData.response?.statusCode else {
                return
            }
            
            // 失敗した場合.
            if statusCode != 200 {
                callback("サーバーでエラーが発生しました", nil)
                return
            }

            // サーバーからのレスポンスを受け取る.
            guard let data = responseData.result.value else {
                return
            }

            // Postの配列に変換して、返却する.
            do {
                let posts = try JSONDecoder().decode([Post].self, from: data)
                callback(nil, posts)
            
            } catch {
                // 変換でエラーが発生した時.
                print(error.localizedDescription)
            }
            
        }
    }
}
