//
//  ReminderManager.swift
//  EventMe
//
//  Created by Radislav Crechet on 6/21/17.
//  Copyright © 2017 RubyGarage. All rights reserved.
//

import Foundation
import EventKit

class ReminderManager {
    typealias RequestAccessCompletion = (_ granted: Bool) -> Void
    typealias RemindersCompletion = (_ reminders: [EKReminder]?) -> Void

    static let shared = ReminderManager()
    
    private let store = EKEventStore()
    
    var isAccessGranted: Bool {
        return EKEventStore.authorizationStatus(for: .reminder) == .authorized
    }
    
    private lazy var calendar: EKCalendar? = {
        return self.store.calendars(for: .reminder).filter{ $0.title == "EventMe" }.first
    }()
    
    // MARK: - Lifecycle
    
    private init() {}
    
    // MARK: - Work With Reminders
    
    func requestAccess(_ completion: @escaping RequestAccessCompletion) {
        store.requestAccess(to: .reminder) { granted, error in
            completion(granted)
        }
    }
    
    func fetchReminders(_ completion: @escaping RemindersCompletion) {
        guard isAccessGranted,
            let calendar = calendar else {
                
                completion(nil)
                return
        }
        
        let predicate = store.predicateForReminders(in: [calendar])
        store.fetchReminders(matching: predicate) { reminders in
            completion(reminders)
        }
    }
    
    func createReminder() -> EKReminder? {
        guard isAccessGranted else {
            return nil
        }
        
        let reminder = EKReminder(eventStore: store)
        reminder.calendar = calendar
        
        return reminder
    }
    
    func saveReminder(_ reminder: EKReminder) {
        guard isAccessGranted else {
            return
        }
        
        try! store.save(reminder, commit: true)
    }
    
    func removeReminder(_ reminder: EKReminder) {
        guard isAccessGranted else {
            return
        }
        
        try! store.remove(reminder, commit: true)
    }
}
