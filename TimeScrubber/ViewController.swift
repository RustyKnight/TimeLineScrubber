//
//  ViewController.swift
//  TimeScrubber
//
//  Created by Shane Whitehead on 10/4/19.
//  Copyright © 2019 Shane Whitehead. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UIScrollViewDelegate {

	@IBOutlet weak var scrollView: UIScrollView!
	@IBOutlet weak var timeLine: TimeLineView!
	
	override func viewDidLoad() {
		super.viewDidLoad()
		scrollView.delegate = self
	}
	
	override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()
		timeLine.offset = scrollView.bounds.width / 2
	}
	
	func set(xOffset: CGFloat, animated: Bool = true, then: (() -> Void)? = nil) {
		var contentOffset = scrollView.contentOffset
		contentOffset.x = xOffset
		
		let stuffToDo = {
			self.scrollView.bounds = CGRect(x: contentOffset.x, y: contentOffset.y,
																			width: self.scrollView.bounds.size.width,
																			height: self.scrollView.bounds.size.height);
		}
		
		guard animated else {
			stuffToDo()
			then?()
			return
		}
		UIView.animate(withDuration: 0.3, delay: 0.0, options: [.curveEaseInOut], animations: {
			stuffToDo()
		}) { (completed) in
			then?()
		}
	}


	@IBAction func minus(_ sender: Any) {
		let contentOffset = scrollView.contentOffset
		var currentTime = timeLine.timeInterval(forOffset: contentOffset.x)
		currentTime -= 3600.0
		let xOffset = timeLine.offset(forTimeInterval: currentTime)
		set(xOffset: xOffset, animated: true)
	}
	
	@IBAction func plus(_ sender: Any) {
		let contentOffset = scrollView.contentOffset
		var currentTime = timeLine.timeInterval(forOffset: contentOffset.x)
		currentTime += 3600.0
		let xOffset = timeLine.offset(forTimeInterval: currentTime)
		set(xOffset: xOffset, animated: true)
	}
	
	var isDragging: Bool = false
	
	func timeDidChange() {
		let contentOffset = scrollView.contentOffset
		let currentTime = timeLine.timeInterval(forOffset: contentOffset.x)
		print("{\(currentTime)}")
	}
	
	func scrollViewDidScroll(_ scrollView: UIScrollView) {
		guard isDragging else { return }
		timeDidChange()
	}
	
	func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
		isDragging = true
	}
	
	func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
		isDragging = false
	}
	
	func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView) {
	}
	
	func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
		timeDidChange()
	}

	func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
		timeDidChange()
	}
}

