//
//  TimeLineView.swift
//  TimeScrubber
//
//  Created by Shane Whitehead on 10/4/19.
//  Copyright © 2019 Shane Whitehead. All rights reserved.
//

import UIKit

class TimeLineView: UIView {
	
	// Scale
	// 5, 15, 30, 60 mins
	// 60 / 5 = 12 * 24 = 288 slots
	// 60 / 15 = 4 * 24 = 96 slots
	// 60 / 30 = 2 * 24 = 48 slots
	// 60 / 1 = 1 * 24 = 24 slots
	
	enum TimeScale {
		case five
		case fifteen
		case thirty
		case sixty

		var minutes: Int {
			switch self {
			case .five: return 5
			case .fifteen: return 15
			case .thirty: return 30
			case .sixty: return 60
			}
		}
		
		fileprivate static let order: [TimeScale] = [.five, .fifteen, .thirty, .sixty]
		
		// Gets the next time scale based on the scale factor,
		// where 1.0 is the current scale, < 1 are items to the left
		// and > 1 are items to the right of the current element
		func next(scaledBy scale: CGFloat) -> TimeScale {
			// Where in the list is the current element
			let index = TimeScale.order.firstIndex(of: self)!
			// What is the distance between the slots
			let range = (100.0 / Double(TimeScale.order.count + 1)) / 100.0
			// Adjust the scale to so 1 == 0
			let adjusted = 1.0 - scale
			// Distance from the current value
			let offset: CGFloat = adjusted / CGFloat(range)
			// Our new index, range checked
			let newIndex = min(TimeScale.order.count - 1, max(0, index + Int(offset)))
			return TimeScale.order[newIndex]
		}
	}

	var timeScale: TimeScale = .sixty

	var numberOfSlots: Int {
		// This probably a thousand and one fancy pancy ways you could calculate
		// this, but I used pen and paper ...
		switch timeScale {
		case .five: return 288
		case .fifteen: return 96
		case .thirty: return 48
		case .sixty: return 24
		}
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
		return gap * 1.5
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
	
	var currentScale: TimeScale = .sixty
	
	@objc func pinched(_ gesture: UIPinchGestureRecognizer) {
		switch gesture.state {
		case .began: currentScale = timeScale
		case .changed:
			let pinchScale = gesture.scale
			timeScale = currentScale.next(scaledBy: pinchScale)
			setNeedsDisplay()
			invalidateIntrinsicContentSize()
			setNeedsUpdateConstraints()
			setNeedsLayout()
			break
		default: break
		}
	}
	
	fileprivate var secondsInDay: TimeInterval {
		return 86400.0
	}
	
	fileprivate var startOfDay: Date {
		let calendar = Calendar.current
		return calendar.startOfDay(for: Date())
	}
	
	fileprivate var endOfDay: Date {
		var components = DateComponents()
		components.day = 1
		components.second = -1
		let calendar = Calendar.current
		return calendar.date(byAdding: components, to: startOfDay)!
	}

	func offset(forTimeInterval timeInterval: TimeInterval) -> CGFloat {
		let range = distanceBetweenMajorTicks * CGFloat(numberOfSlots)
		let percentOfDay = min(1.0, max(0.0, timeInterval / secondsInDay))
		let point = range * CGFloat(percentOfDay)
		let result = point
		return result
	}
	
	func timeInterval(forOffset position: CGFloat) -> TimeInterval {
		let range = distanceBetweenMajorTicks * CGFloat(numberOfSlots)
		let percent = min(1.0, max(0.0, position / range))
		let time = secondsInDay * Double(percent)
		return time
	}

	override func draw(_ rect: CGRect) {
		guard let ctx = UIGraphicsGetCurrentContext() else { return }
		
		// This is minimum permissible height
		let allHeight = textSize.height + spacer + tickHeight + lineHeight
		// This should then center the content within the view, preventing it from been
		// put of the edge of the view ;)
		let yOffset = max(spacer, bounds.midY - (allHeight / 2))
		
		let textYPos = yOffset
		let tickYPos = textYPos + textSize.height + spacer
		let lineYPos = tickYPos + tickHeight
		
		let tickTimeDistance = 5
		let tickDistance = distanceBetweenMajorTicks

		ctx.setLineCap(.round)
		ctx.setLineWidth(lineHeight)
		ctx.setStrokeColor(majorTickColor.cgColor)

		ctx.beginPath()
		let spacing = offset
		ctx.move(to: CGPoint(x: spacing, y: lineYPos))
		ctx.addLine(to: CGPoint(x: bounds.width - spacing, y: lineYPos))
		ctx.strokePath()

		let calendar = Calendar.current
		var date = self.startOfDay

		// End of day, so we can stop painting sub ticks...
		let endOfDay = self.endOfDay
		
		// The amount of seconds
		var duration = 0.0
		
		var xPos = offset
		let fontAttributes: [NSAttributedString.Key : Any] = [
			NSAttributedString.Key.font: font,
			NSAttributedString.Key.foregroundColor: textColor,
			]
		for _ in 0...numberOfSlots {
			let text = durationFormatter.string(from: duration)!
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
			
			var tickTime = date
			date = calendar.date(byAdding: .minute, value: timeScale.minutes, to: date)!
			// Could use seconds since start of day I guess :P
			duration += Double(timeScale.minutes * 60)

			if tickTime <= endOfDay {
				// This is used to calculate the number of sub ticks we need to paint, and therefore
				// the amount of spacingneeded
				let toTime = calendar.dateComponents([.hour, .minute, .day, .month, .year], from: date)
				let fromTime = calendar.dateComponents([.hour, .minute, .day, .month, .year], from: tickTime)
				
				let steps = calendar.dateComponents([.minute], from: fromTime, to: toTime).minute! / tickTimeDistance

				let tickXStep = tickDistance / CGFloat(steps)
				var tickXPos = xPos + tickXStep

				// Advance one tick, otherwise we're painting the current major tick position again
				// And it's possible that we don't need to paint any sub ticks
				tickTime = calendar.date(byAdding: .minute, value: tickTimeDistance, to: tickTime)!
				while tickTime < date {
					tickTime = calendar.date(byAdding: .minute, value: tickTimeDistance, to: tickTime)!
					ctx.setStrokeColor(minorTickColor.cgColor)
					ctx.beginPath()
					ctx.move(to: CGPoint(x: tickXPos, y: tickYPos + (tickHeight / 2)))
					ctx.addLine(to: CGPoint(x: tickXPos, y: tickYPos + tickHeight))
					ctx.strokePath()
					tickXPos += tickXStep
				}
			}

			xPos += tickDistance
		}
	}
	
}
