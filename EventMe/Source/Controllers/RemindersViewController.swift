//
//  RemindersViewController.swift
//  EventMe
//
//  Created by Radislav Crechet on 6/21/17.
//  Copyright © 2017 RubyGarage. All rights reserved.
//

import UIKit
import EventKit

class RemindersViewController: UITableViewController {
    @IBOutlet var segmentedControl: UISegmentedControl!
    @IBOutlet var addButton: UIBarButtonItem!

    private let toReminderSegueIdentifier = "ToReminder"
    private var incompletedReminders: [EKReminder]?
    private var completedReminders: [EKReminder]?
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureReminderManager()
        registerNotifications()
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let reminderViewController = segue.destination as! ReminderViewController

        if let indexPath = tableView.indexPathForSelectedRow {
            reminderViewController.reminder = reminder(atIndexPath: indexPath)
        }
    }
    
    // MARK: - Configuration
    
    private func configureReminderManager() {
        if ReminderManager.shared.isAccessGranted {
            addButton.isEnabled = true
            fetchReminders()
        } else {
            ReminderManager.shared.requestAccess { [unowned self] granted in
                if granted {
                    self.addButton.isEnabled = true
                    self.fetchReminders()
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
        fetchReminders()
    }

    private func fetchReminders() {
        ReminderManager.shared.fetchReminders { [unowned self] reminders in
            DispatchQueue.main.async {
                self.incompletedReminders = reminders?.filter { $0.isCompleted == false }
                self.completedReminders = reminders?.filter { $0.isCompleted == true }
                self.tableView.reloadData()
            }
        }
    }

    private func changeReminder(atIndexPath indexPath: IndexPath) {
        let reminder = self.reminder(atIndexPath: indexPath)!
        reminder.isCompleted = !reminder.isCompleted
        ReminderManager.shared.saveReminder(reminder)
    }

    private func removeReminder(atIndexPath indexPath: IndexPath) {
        let reminder = self.reminder(atIndexPath: indexPath)!
        ReminderManager.shared.removeReminder(reminder)
    }

    private func reminder(atIndexPath indexPath: IndexPath) -> EKReminder? {
        var reminder: EKReminder?

        if self.segmentedControl.selectedSegmentIndex == 0 {
            reminder = self.incompletedReminders?[indexPath.row]
        } else {
            reminder = self.completedReminders?[indexPath.row]
        }

        return reminder
    }

    // MARK: - Actions

    @IBAction func segmentedControlDidChangeValud(_ sender: UISegmentedControl) {
        tableView.reloadData()
    }
    
    @IBAction func addButtonPressed(_ sender: UIBarButtonItem) {
        performSegue(withIdentifier: toReminderSegueIdentifier, sender: self)
    }
    
    // MARK: - UITableViewDataSource
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if segmentedControl.selectedSegmentIndex == 0 {
            return incompletedReminders?.count ?? 0
        } else {
            return completedReminders?.count ?? 0
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)

        if let reminder = self.reminder(atIndexPath: indexPath) {
            cell.textLabel?.text = reminder.title
            
            if let date = reminder.alarms?.first?.absoluteDate {
                let dateFormatter = DateFormatter()
                dateFormatter.dateStyle = .medium
                dateFormatter.doesRelativeDateFormatting = true
                dateFormatter.timeStyle = .short
                cell.detailTextLabel?.text = dateFormatter.string(from: date)
            }
        }

        return cell
    }
    
    // MARK: - UITableViewDelegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: toReminderSegueIdentifier, sender: self)
    }
    
    override func tableView(_ tableView: UITableView,
                            leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
        let completeActionHandler: UIContextualAction.Handler = { action, view, completion in
            self.changeReminder(atIndexPath: indexPath)
            completion(true)
        }
        
        let title = segmentedControl.selectedSegmentIndex == 0 ? "Complete" : "Uncomplete"
        let completeAction = UIContextualAction(style: .destructive, title: title, handler: completeActionHandler)
        completeAction.backgroundColor = navigationController?.navigationBar.barTintColor
        return UISwipeActionsConfiguration(actions: [completeAction])
    }
    
    override func tableView(_ tableView: UITableView,
                            trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
        let deleteActionHandler: UIContextualAction.Handler = { action, view, completion in
            self.removeReminder(atIndexPath: indexPath)
            completion(true)
        }
        
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete", handler: deleteActionHandler)
        return UISwipeActionsConfiguration(actions: [deleteAction])
    }
}
