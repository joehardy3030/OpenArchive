//
//  ChateauGPTViewController.swift
//  Breaze
//
//  Created by Joseph Hardy on 12/2/23
//  Copyright © 2023 Carquinez. All rights reserved.
//

import UIKit
//import SwiftyJSON
import Alamofire

@available(iOS 13.0, *)
class ChateauGPTViewController: ArchiveSuperViewController {
    // UI Components
    
    //var streamCompletionResponses = [ChateauGPTStreamCompletionResponse]()
    var displayText = String()
    
    let introTextView: UITextView = {
        let textView = UITextView()
        textView.isEditable = false
        return textView
    }()
    
    let inputTextField: UITextField = {
        let textField = UITextField()
        textField.borderStyle = .roundedRect
        return textField
    }()
    
    let sendButton: UIButton = {
        let button = UIButton()
        button.setTitle("Send", for: .normal)
        button.backgroundColor = .blue
        if #available(iOS 16.0, *) {
            button.addTarget(self, action: #selector(sendRequest), for: .touchUpInside)
        } else {
            // Fallback on earlier versions
        }
        return button
    }()
    
    let responseTextView: UITextView = {
        let textView = UITextView()
        textView.isEditable = false
        return textView
    }()
    
    let activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.hidesWhenStopped = true
        return indicator
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        view.addSubview(introTextView)
        view.addSubview(inputTextField)
        view.addSubview(sendButton)
        view.addSubview(responseTextView)
        view.addSubview(activityIndicator)
        
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        introTextView.translatesAutoresizingMaskIntoConstraints = false
        inputTextField.translatesAutoresizingMaskIntoConstraints = false
        sendButton.translatesAutoresizingMaskIntoConstraints = false
        responseTextView.translatesAutoresizingMaskIntoConstraints = false
        
        introTextView.font = UIFont.systemFont(ofSize: 16)
        
        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        
        // Constraints for inputTextField
        NSLayoutConstraint.activate([
            introTextView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            introTextView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            introTextView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            introTextView.heightAnchor.constraint(equalToConstant: 55)
        ])
        
        // Constraints for inputTextField
        NSLayoutConstraint.activate([
            inputTextField.topAnchor.constraint(equalTo: introTextView.bottomAnchor, constant: 15),
            inputTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            inputTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            inputTextField.heightAnchor.constraint(equalToConstant: 40)
        ])
        
        // Constraints for sendButton
        NSLayoutConstraint.activate([
            sendButton.topAnchor.constraint(equalTo: inputTextField.bottomAnchor, constant: 15),
            sendButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            sendButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            sendButton.heightAnchor.constraint(equalToConstant: 50)
        ])
        
        // Constraints for responseTextView
        NSLayoutConstraint.activate([
            responseTextView.topAnchor.constraint(equalTo: sendButton.bottomAnchor, constant: 15),
            responseTextView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            responseTextView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            responseTextView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -125)
        ])
        
        introTextView.text = "Ask any question you want about the Grateful Dead and their music."
    }
    
    @available(iOS 16.0, *)
    @objc private func sendRequest() {
        guard let prompt = inputTextField.text, !prompt.isEmpty else { return }
        //activityIndicator.startAnimating()
        self.displayText = ""
        view.endEditing(true)
        getChatGPTStreamResponse(prompt: prompt).responseStreamString {[weak self] stream in
            guard let self = self else { return }
            switch stream.event{
            case .stream(let response):
                switch response {
                case .success(let string):
                    print("Raw Stream Response: \(stream)")
                    let streamResponse = self.parseStringData(string)
                    streamResponse.forEach { newMessageResponse in
                        guard let messageContent = newMessageResponse.choices.first?.delta.content else {
                            return
                        }
                        //self.streamCompletionResponses.append(newMessageResponse)
                        self.displayText = self.displayText + messageContent
                        DispatchQueue.main.async {
                            //   self.activityIndicator.stopAnimating()
                            self.responseTextView.text = self.displayText
                        }
                    }
                case .failure(_):
                    print("Something failed")
                }
            case .complete(_):
                print("COMPLETE")
            }
        }
    }
    
    
    private func getChatGPTResponse(prompt: String, completion: @escaping (String) -> Void) {
        let url = "https://api.openai.com/v1/chat/completions"
        
        /*
         guard let API_key = ProcessInfo.processInfo.environment["OPENAI_API_KEY"] else {
         completion("No API key")
         return
         }
         */
        let API_key = ""

        let headers: HTTPHeaders = [
            "Authorization": "Bearer " + API_key,
            "Content-Type": "application/json"
        ]
        let content = prompt + "Resond in JSON format."
        
        let parameters: [String: Any] = ["model": "gpt-4o",
                                         "messages": [["role": "system", "content": "You tell people about the Grateful Dead. You know a lot about the band, and the various shows they played. You can help the user identify which shows to listen to if they have a particular song they want to hear or vibe they want to listen to. Please use MM-DD-YYYY format when listing dates."], ["role": "user", "content": content]],
                                         "temperature": 0.7]
        
        AF.request(url, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers)
            .responseDecodable(of: ChateauGPTModel.self) { response in
                switch response.result {
                case .success(let chatGPTResponse):
                    if let choice = chatGPTResponse.choices?.first,
                       let content = choice.message?.content {
                        print(content)
                        completion(content)
                    } else {
                        completion("Failed to parse response")
                    }
                    
                case .failure(let error):
                    completion("Error: \(error.localizedDescription)")
                }
            }
    }
    
    private func getChatGPTStreamResponse(prompt: String) -> DataStreamRequest {
        let url = "https://api.openai.com/v1/chat/completions"
        
        let API_key = ""
        print(API_key)
        
        let headers: HTTPHeaders = [
            "Authorization": "Bearer \(API_key)",
            "Content-Type": "application/json"
        ]
        //let content = prompt + "Resond in JSON format."
        let content = prompt + "Please write all dates in YYYY-mm-dd format."
        
        let parameters = ChateauGPTParameters(model: "gpt-4o",
                                              messages: [ChateauGPTMessage(role: "assistant", content: "You tell people about the Grateful Dead. You know a lot about the band, and the various shows they played. You can help the user identify which shows to listen to if they have a particular song they want to hear or vibe they want to listen to."),
                                                         ChateauGPTMessage(role: "user", content: content)],
                                              temperature: 0.7,
                                              stream: true)
        return AF.streamRequest(url, method: .post, parameters: parameters, encoder: .json, headers: headers)
    }
    
    @available(iOS 16.0, *)
    func parseStringData(_ data: String) -> [ChateauGPTStreamCompletionResponse] {
        let responseStrings = data.split(separator: "data:").map({$0.trimmingCharacters(in: .whitespacesAndNewlines)}).filter({!$0.isEmpty})
        let jsonDecoder = JSONDecoder()
        
        return responseStrings.compactMap { jsonString in
            guard let jsonData = jsonString.data(using: .utf8) else {
                return nil
            }
            do {
                let streamResponse = try jsonDecoder.decode(ChateauGPTStreamCompletionResponse?.self, from: jsonData)
                return streamResponse
            } catch {
                // Handle the error, for example, by logging it or returning nil
                print("Error decoding JSON: \(error)")
                return nil
            }
        }
    }
    
}



