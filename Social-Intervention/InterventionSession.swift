//
//  InterventionSession.swift
//  Social-Intervention
//
//  Created by Jackson Chui on 3/10/21.
//

import Foundation

public class InterventionSession {
    
    private(set) var service: ConditionService
    private(set) var interval: TimeInterval
    
    public typealias StartCompletion = (ConditionPeriodError) -> Void
    
    public init (for service: ConditionService, updatingEvery interval: TimeInterval) {
        self.service = service
        self.interval = interval
    }
    
    public func start(completion: @escaping StartCompletion) {
        service.start { result in
            switch result {
                case let .failure(error):
                    completion(error)
                case .success:
                    print("Unknown default")
            }
        }
    }
    
}
