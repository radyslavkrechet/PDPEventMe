//
//  EventsViewController.swift
//  EventMe
//
//  Created by Radislav Crechet on 6/21/17.
//  Copyright © 2017 RubyGarage. All rights reserved.
//

import UIKit
import EventKit

class EventsViewController: UITableViewController {
    @IBOutlet var addButton: UIBarButtonItem!

    private let toEventSegueIdentifier = "ToEvent"
    private var events: [EKEvent]?
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureEventManager()
        registerNotifications()
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let eventViewController = segue.destination as! EventViewController

        if let indexPath = tableView.indexPathForSelectedRow {
            eventViewController.event = events![indexPath.row]
        }
    }
    
    // MARK: - Configuration
    
    private func configureEventManager() {
        if EventManager.shared.isAccessGranted {
            addButton.isEnabled = true
            fetchEvents()
        } else {
            EventManager.shared.requestAccess { [unowned self] granted in
                if granted {
                    self.addButton.isEnabled = true
                    self.fetchEvents()
                }
            }
        }
    }
    
    private func registerNotifications() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(eventStoreDidChange),
                                               name: .EKEventStoreChanged,
                                               object: nil)
    }
    
    @objc func eventStoreDidChange() {
        fetchEvents()
    }

    private func fetchEvents() {
        EventManager.shared.fetchEvents { [unowned self] events in
            DispatchQueue.main.async {
                self.events = events
                self.tableView.reloadData()
            }
        }
    }

    private func removeEvent(atIndexPath indexPath: IndexPath) {
        let event = events![indexPath.row]
        EventManager.shared.removeEvent(event)
    }

    // MARK: - Actions
    
    @IBAction func addButtonPressed(_ sender: UIBarButtonItem) {
        performSegue(withIdentifier: toEventSegueIdentifier, sender: self)
    }
    
    // MARK: - UITableViewDataSource
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return events?.count ?? 0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)
        
        if let event = events?[indexPath.row] {
            cell.textLabel?.text = event.title
            
            let calendar = Calendar.current
            let components: Set<Calendar.Component> = [.day, .month, .year]
            
            let startDateComponents = calendar.dateComponents(components, from: event.startDate!)
            let endDateComponents = calendar.dateComponents(components, from: event.endDate!)
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .medium
            dateFormatter.doesRelativeDateFormatting = startDateComponents == endDateComponents
            
            let startDate = dateFormatter.string(from: event.startDate!)
            let endDate = dateFormatter.string(from: event.endDate!)
            
            if event.isAllDay {
                if startDateComponents == endDateComponents {
                    cell.detailTextLabel?.text = "\(startDate) in all day"
                } else {
                    cell.detailTextLabel?.text = "From \(startDate) to \(endDate)"
                }
            } else {
                let timeFormatter = DateFormatter()
                timeFormatter.timeStyle = .short
                
                let startTime = timeFormatter.string(from: event.startDate!)
                let endTime = timeFormatter.string(from: event.endDate!)
                
                if startDateComponents == endDateComponents {
                    cell.detailTextLabel?.text = "\(startDate) from \(startTime) to \(endTime)"
                } else {
                    cell.detailTextLabel?.text = "From \(startDate), \(startTime) to \(endDate), \(endTime)"
                }
            }
        }
        
        return cell
    }
    
    // MARK: - UITableViewDelegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: toEventSegueIdentifier, sender: self)
    }
    
    override func tableView(_ tableView: UITableView,
                            trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
        let deleteActionHandler: UIContextualAction.Handler = { action, view, completion in
            self.removeEvent(atIndexPath: indexPath)
            completion(true)
        }
        
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete", handler: deleteActionHandler)
        return UISwipeActionsConfiguration(actions: [deleteAction])
    }
}
