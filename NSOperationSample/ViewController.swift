//
//  ViewController.swift
//  NSOperationSample
//
//  Created by Tadashi on 2017/09/13.
//  Copyright © 2017 UBUNIFU Incorporated. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

	let rss = "http://www.eigo-kikinagashi.jp/rss/index.rss"
	var queue : OperationQueue!
	var timer : Timer?
	var urls = [String]()
	var number : Int!

	@IBOutlet weak var remaining: UILabel!
	@IBOutlet weak var label: UILabel!
	@IBOutlet weak var start: UIButton!
	@IBAction func start(_ sender: Any) {
		let button = sender as! UIButton
		if self.urls.count != 0 {
			self.urls = []
			self.queue.cancelAllOperations()
			button.setTitle("START", for: .normal)
		} else {
			let parser = XMLParser(contentsOf: URL(string: self.rss)!)
			parser?.delegate = self
			parser?.parse()
			button.setTitle("CANCEL", for: .normal)
		}
	}

	override func viewDidLoad() {
		super.viewDidLoad()
		self.queue = OperationQueue.init()
		self.label.text = rss
		self.remaining.text = ""
	}

	func checkComplete() {
	
		self.remaining.text = String("\(self.urls.count)/\(self.number!)")
		if self.urls.count != 0 && self.queue.operationCount < 6 {
			let op = DLOperation()
			let path = self.urls[0]
			self.urls.remove(at: 0)
			op.initWithPath(path: path)
			op.addObserver(self, forKeyPath: "isFinished", options: .new, context: nil)
			self.queue.addOperation(op)
		} else {
			if self.urls.count == 0  {
				self.timer?.invalidate()
				self.timer = nil
			}
		}
	}

	override func observeValue(forKeyPath keyPath: String?,
		of object: Any?,
		change: [NSKeyValueChangeKey: Any]?,
		context: UnsafeMutableRawPointer?) {
		
		if keyPath == "isFinished" {
		}
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}
}

class DLOperation: Operation {

	var path : String!
	var request : URLRequest!
	var session : URLSession!

	func initWithPath(path: String) {
		self.isFinished = false
		self.path = path
	}

	override func start() {
		self.isExecuting = true
		self.request = URLRequest.init(url: URL(string: path)!)
		let task = URLSession.shared.dataTask(with: request,
			completionHandler: { data, response, error in
			if error != nil {
				print(error!)
				self.isFinished = true
				self.isExecuting = false
				return
			}
			let dir = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first! as String
			let file = (URL(string: self.path)?.lastPathComponent)!
			let savePath = dir + "/" + file
			try! data?.write(to: URL(fileURLWithPath: savePath))
			self.isFinished = true
			self.isExecuting = false
		})
		task.resume()
	}

	private var _executing : Bool = false
	override var isExecuting : Bool {
		get { return _executing }
		set {
			guard _executing != newValue else { return }
			willChangeValue(forKey: "isExecuting")
			_executing = newValue
			didChangeValue(forKey: "isExecuting")
		}
	}

	private var _finished : Bool = false
	override var isFinished : Bool {
		get { return _finished }
		set {
			guard _finished != newValue else { return }
			willChangeValue(forKey: "isFinished")
			_finished = newValue
			didChangeValue(forKey: "isFinished")
		}
	}
}

extension ViewController: XMLParserDelegate {

	func parserDidStartDocument(_ parser: XMLParser) {
	}

    func parser(_: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String]) {
		if elementName == "enclosure" {
			self.urls.append(attributeDict["url"]!)
		}
    }

    func parser(_: XMLParser, foundCharacters string: String) {
    }

	func parser(_: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
    }

    func parserDidEndDocument(_ parser: XMLParser) {
        if self.timer == nil {
			self.timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(self.checkComplete), userInfo: nil, repeats: true)
		}
		self.number = self.urls.count
    }

    func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error) {
    }

	func parser(_: XMLParser, foundComment: String) {
	}

	func parser(_: XMLParser, foundCDATA: Data) {
	}
}
