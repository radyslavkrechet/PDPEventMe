//
//  EventsManager.swift
//  EventMe
//
//  Created by Radislav Crechet on 6/21/17.
//  Copyright © 2017 RubyGarage. All rights reserved.
//

import Foundation
import EventKit

class EventManager {
    typealias RequestAccessCompletion = (_ granted: Bool) -> Void
    typealias EventsCompletion = (_ events: [EKEvent]?) -> Void

    static let shared = EventManager()
    
    private let store = EKEventStore()
    
    var isAccessGranted: Bool {
        return EKEventStore.authorizationStatus(for: .event) == .authorized
    }
    
    private lazy var calendar: EKCalendar? = {
        return self.store.calendars(for: .event).filter{ $0.title == "EventMe" }.first
    }()
    
    // MARK: - Lifecycle
    
    private init() {}
    
    // MARK: - Work With Reminders
    
    func requestAccess(_ completion: @escaping RequestAccessCompletion) {
        store.requestAccess(to: .event) { granted, error in
            completion(granted)
        }
    }
    
    func fetchEvents(_ completion: @escaping EventsCompletion) {
        guard isAccessGranted,
            let calendar = calendar else {
                
                completion(nil)
                return
        }

        let date = Date()
        let currentCalendar = Calendar.current
        let start = currentCalendar.date(byAdding: .month, value: -1, to: date)!
        let end = currentCalendar.date(byAdding: .month, value: 1, to: date)!
        
        let predicate = store.predicateForEvents(withStart: start, end: end, calendars: [calendar])
        completion(store.events(matching: predicate))
    }
    
    func createEvent() -> EKEvent? {
        guard isAccessGranted else {
            return nil
        }
        
        let event = EKEvent(eventStore: store)
        event.calendar = calendar
        
        return event
    }
    
    func saveEvent(_ event: EKEvent) {
        guard isAccessGranted else {
            return
        }
        
        try! store.save(event, span: EKSpan.thisEvent, commit: true)
    }
    
    func removeEvent(_ event: EKEvent) {
        guard isAccessGranted else {
            return
        }
        
        try! store.remove(event, span: EKSpan.thisEvent, commit: true)
    }
}
