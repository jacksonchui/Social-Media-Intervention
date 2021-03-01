//
//  TimerIntervalUpdateService.swift
//  Social-Intervention
//
//  Created by Jackson Chui on 2/28/21.
//

import Foundation

internal class TimerIntervalUpdateService {
    
    private(set) var timer: Timer?
    private(set) var timeInterval: TimeInterval
    private(set) var repeats: Bool
    private(set) var onEachInterval: ((Timer) -> Void)?
    
    init(withTimeInterval: TimeInterval, repeats: Bool) {
        self.timeInterval = withTimeInterval
        self.repeats = repeats
    }
    
    func completeWith(onEachInterval: @escaping (Timer) -> Void) {
        self.onEachInterval = onEachInterval
    }
    
    func start() {
        if timer != nil { stop() }
        timer = Timer.scheduledTimer(withTimeInterval: timeInterval,
                                     repeats: repeats,
                                     block: onEachInterval ?? { _ in })
    }
    
    func stop() {
        timer?.invalidate()
        timer = nil
    }
}
