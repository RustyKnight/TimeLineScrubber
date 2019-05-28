//
//  TimeLineView.swift
//  TimeScrubber
//
//  Created by Shane Whitehead on 10/4/19.
//  Copyright © 2019 Shane Whitehead. All rights reserved.
//

import UIKit

extension TimeInterval {
	static let day: TimeInterval = hour * 24
	static let hour: TimeInterval = minute * 60
	static let minute: TimeInterval = 60
}

class TimeLineView: UIView {

	// This represents the smallets unit displayed, like 1 minute, 30 seconds, what ever
	var timeScale: TimeInterval = .hour //15 * TimeInterval.minute
	// This represents the start of the timeline
	var from: TimeInterval = 8 * TimeInterval.hour // Start of day
	// This represents the amount of time covered by the timeline
	// the end time is startInterval + duration
	var duration: TimeInterval = 4 * TimeInterval.hour // 24 hours

	// How many "visual" slots are displayed.  This is based on the duration and the timeScale
	var numberOfSlots: Int {
		return Int((duration / timeScale).rounded())
	}

	var font: UIFont = UIFont.systemFont(ofSize: 12.0) {
		didSet {
			invalidateIntrinsicContentSize()
			setNeedsUpdateConstraints()
			setNeedsLayout()
			setNeedsDisplay()
		}
	}
	
	var majorTickColor: UIColor = UIColor.black {
		didSet {
			setNeedsDisplay()
		}
	}
	
	var minorTickColor: UIColor = UIColor.darkGray {
		didSet {
			setNeedsDisplay()
		}
	}
	
	var textColor: UIColor = UIColor.black {
		didSet {
			setNeedsDisplay()
		}
	}
	
	// Do we want control over the timeline color?
	
	var textSize: CGSize {
		let size: CGSize = "00:00".size(withAttributes: [.font: font])
		return size
	}

	var offset: CGFloat = 0 {
		didSet {
			invalidateIntrinsicContentSize()
			setNeedsUpdateConstraints()
			setNeedsLayout()
			setNeedsDisplay()
		}
	}

	var gap: CGFloat {
		return textSize.width
	}

	// Use duration instead of time to format the string
	// as it allows for "24"
	var durationFormatter: DateComponentsFormatter = {
		let formatter = DateComponentsFormatter()
		formatter.unitsStyle = .positional
		formatter.allowedUnits = [.hour, .minute]
		formatter.zeroFormattingBehavior = [.pad]
		return formatter
	}()
	
	// The amount of empty space between elements
	var spacer: CGFloat = 4
	// Do we want control over the tick stroke thickness?
	// Do we want control over the tick height?
	let tickHeight: CGFloat = 8
	// Do we want control over the timeline stroke thickness?
	let lineHeight: CGFloat = 1
	
	var distanceBetweenMajorTicks: CGFloat {
		// This is a crazy scaling process, where by, when the time scale is below
		// one hour, we want to increase the distance between points
		// by a factor of 4, basse on the time scale, so that at
		// 1 miniute, it's scaled by 4 and 1 hour is scale by 1
		let interval = max(60.0, min(timeScale, TimeInterval.hour))
		let range = interval / TimeInterval.hour
		let multipler = max(1, 4.0 - (4.0 * range))

		return gap * CGFloat(multipler)
	}
	
	var pinchGesture: UIPinchGestureRecognizer!

	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		commonInit()
	}

	override init(frame: CGRect) {
		super.init(frame: frame)
		commonInit()
	}

	init() {
		super.init(frame: CGRect.zero)
		commonInit()
	}

	func commonInit() {
		translatesAutoresizingMaskIntoConstraints = false
		backgroundColor = UIColor.red
		
		pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(pinched(_:)))
		addGestureRecognizer(pinchGesture)
	}

	override class var requiresConstraintBasedLayout: Bool {
		return true
	}

	override var intrinsicContentSize: CGSize {
		let width = (offset * 2) + (distanceBetweenMajorTicks * CGFloat(numberOfSlots))
		let height = max(44, spacer + textSize.height + spacer + tickHeight + lineHeight + spacer)
		return CGSize(width: width, height: height)
	}
	
	var currentScale: TimeInterval = .hour
	
	@objc func pinched(_ gesture: UIPinchGestureRecognizer) {
		switch gesture.state {
		case .began: currentScale = timeScale
		case .changed:
			let pinchScale = gesture.scale
			let value = (currentScale * Double(pinchScale)).rounded()
			timeScale = min(max(value, TimeInterval.minute), duration)
			setNeedsDisplay()
			invalidateIntrinsicContentSize()
			setNeedsUpdateConstraints()
			setNeedsLayout()
			break
		default: break
		}
	}
	
//	fileprivate var secondsInDay: TimeInterval {
//		return 86400.0
//	}
	
	fileprivate var startOfTimeLine: Date {
		let calendar = Calendar.current
		let startOfDay = calendar.startOfDay(for: Date())

		var components = DateComponents()
		components.second = Int(from.rounded())
		return calendar.date(byAdding: components, to: startOfDay)!
	}
	
	fileprivate var endOfTimeLine: Date {
		var components = DateComponents()
		components.second = Int(duration.rounded())
		let calendar = Calendar.current
		return calendar.date(byAdding: components, to: startOfTimeLine)!
	}

	func offset(forTimeInterval timeInterval: TimeInterval) -> CGFloat {
		let range = distanceBetweenMajorTicks * CGFloat(numberOfSlots)
		let percentOfDay = min(1.0, max(0.0, timeInterval / duration))
		let point = range * CGFloat(percentOfDay)
		let result = point
		return result
	}
	
	func timeInterval(forOffset position: CGFloat) -> TimeInterval {
		let range = distanceBetweenMajorTicks * CGFloat(numberOfSlots)
		let percent = min(1.0, max(0.0, position / range))
		let time = duration * Double(percent)
		return time
	}

	override func draw(_ rect: CGRect) {
		guard let ctx = UIGraphicsGetCurrentContext() else { return }

		//!! Need to include a height/spacer element for events!!
		
		// This is minimum permissible height
		let allHeight = textSize.height + spacer + tickHeight + lineHeight
		// This should then center the content within the view, preventing it from been
		// put of the edge of the view ;)
		let yOffset = max(spacer, bounds.midY - (allHeight / 2))
		
		let lineYPos = yOffset
		let tickYPos = lineYPos
		let textYPos = tickYPos + tickHeight + spacer

		let tickDistance = distanceBetweenMajorTicks

		ctx.setLineCap(.round)
		ctx.setLineWidth(lineHeight)
		ctx.setStrokeColor(majorTickColor.cgColor)

		ctx.beginPath()
		let spacing = offset
		ctx.move(to: CGPoint(x: spacing, y: lineYPos))
		ctx.addLine(to: CGPoint(x: bounds.width - spacing, y: lineYPos))
		ctx.strokePath()
		
		var xPos = offset
		let fontAttributes: [NSAttributedString.Key : Any] = [
			NSAttributedString.Key.font: font,
			NSAttributedString.Key.foregroundColor: textColor,
			]
		
		var tickTime = from
		for _ in 0...numberOfSlots {
			let text = durationFormatter.string(from: tickTime)!
			tickTime += timeScale
			//timeFormatter.string(from: date)
			let size = (text as NSString).size(withAttributes: fontAttributes)
			let textXPos = xPos - (size.width / 2)
			let textRect = CGRect(x: textXPos, y: textYPos, width: size.width, height: size.height)
			(text as NSString).draw(in: textRect, withAttributes: fontAttributes)
			
			ctx.setStrokeColor(majorTickColor.cgColor)
			ctx.beginPath()
			ctx.move(to: CGPoint(x: xPos, y: tickYPos))
			ctx.addLine(to: CGPoint(x: xPos, y: tickYPos + tickHeight))
			ctx.strokePath()
			
//			var tickTime = date
//			date = calendar.date(byAdding: .minute, value: timeScale.minutes, to: date)!
//			// Could use seconds since start of day I guess :P
//			duration += Double(timeScale.minutes * 60)
//
//			if tickTime <= endOfDay {
//				// This is used to calculate the number of sub ticks we need to paint, and therefore
//				// the amount of spacingneeded
//				let toTime = calendar.dateComponents([.hour, .minute, .day, .month, .year], from: date)
//				let fromTime = calendar.dateComponents([.hour, .minute, .day, .month, .year], from: tickTime)
//
//				let steps = calendar.dateComponents([.minute], from: fromTime, to: toTime).minute! / tickTimeDistance
//
//				let tickXStep = tickDistance / CGFloat(steps)
//				var tickXPos = xPos + tickXStep
//
//				// Advance one tick, otherwise we're painting the current major tick position again
//				// And it's possible that we don't need to paint any sub ticks
//				tickTime = calendar.date(byAdding: .minute, value: tickTimeDistance, to: tickTime)!
//				while tickTime < date {
//					tickTime = calendar.date(byAdding: .minute, value: tickTimeDistance, to: tickTime)!
//					ctx.setStrokeColor(minorTickColor.cgColor)
//					ctx.beginPath()
//					ctx.move(to: CGPoint(x: tickXPos, y: tickYPos + (tickHeight / 2)))
//					ctx.addLine(to: CGPoint(x: tickXPos, y: tickYPos + tickHeight))
//					ctx.strokePath()
//					tickXPos += tickXStep
//				}
//			}

			xPos += tickDistance
		}
	}
	
}
