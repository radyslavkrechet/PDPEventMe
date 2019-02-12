//
//  ReminderViewController.swift
//  EventMe
//
//  Created by Radislav Crechet on 6/21/17.
//  Copyright © 2017 RubyGarage. All rights reserved.
//

import UIKit
import EventKit

class ReminderViewController: UITableViewController, UITextFieldDelegate {
    @IBOutlet var doneButton: UIBarButtonItem!
    @IBOutlet var titleTextField: UITextField!
    @IBOutlet var remindSwitch: UISwitch!
    @IBOutlet var alarmDateTextField: UITextField!

    var reminder: EKReminder!
    
    private var datePicker: UIDatePicker!
    
    private var date: Date {
        let calendar = Calendar.current
        
        var date = calendar.date(byAdding: .hour, value: 1, to: Date())!
        date = calendar.date(byAdding: .minute, value: -calendar.component(.minute, from: date), to: date)!
        
        return date
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        configureUserInterface()
    }
    
    // MARK: - Configuration
    
    private func configureUserInterface() {
        datePicker = UIDatePicker()
        datePicker.addTarget(self, action: #selector(datePickerValueDidChange), for: .valueChanged)
        alarmDateTextField.inputView = datePicker
        
        if let reminder = reminder {
            titleTextField.text = reminder.title
            remindSwitch.isOn = reminder.hasAlarms
            
            if reminder.hasAlarms {
                let date = reminder.alarms!.first!.absoluteDate!
                datePicker.date = date
                alarmDateTextField.isEnabled = true
                updateAlarmDateTextField(withDate: date)
            }
        } else {
            datePicker.date = date
            createReminder()
        }
    }
    
    private func updateAlarmDateTextField(withDate date: Date) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        alarmDateTextField.text = dateFormatter.string(from: date)
    }

    private func dateComponents(from date: Date) -> DateComponents {
        return Calendar.current.dateComponents([.minute, .hour, .day, .month, .year], from: date)
    }

    private func createReminder() {
        reminder = ReminderManager.shared.createReminder()
    }

    private func changeReminder(title: String) {
        reminder.title = title
    }

    private func addAlarmToReminder(_ date: Date) {
        let alarm = EKAlarm(absoluteDate: date)

        reminder.addAlarm(alarm)
        reminder.dueDateComponents = dateComponents(from: date)
    }

    private func changeAlarmOfReminder(_ date: Date) {
        guard let alarm = reminder.alarms?.first else {
            return
        }

        alarm.absoluteDate = date
        reminder.dueDateComponents = dateComponents(from: date)
    }

    private func removeAlarmFromReminder() {
        guard let alarm = reminder.alarms?.first else {
            return
        }

        reminder.removeAlarm(alarm)
        reminder.dueDateComponents = nil
    }

    private func saveReminder() {
        ReminderManager.shared.saveReminder(reminder)
    }
    
    // MARK: - Actions
    
    @IBAction func doneButtonPressed(_ sender: UIBarButtonItem) {
        saveReminder()
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func remindSwitchValueDidChange(_ sender: UISwitch) {
        alarmDateTextField.isEnabled = sender.isOn
        
        if sender.isOn {
            let date = self.date
            datePicker.date = date
            updateAlarmDateTextField(withDate: date)
            addAlarmToReminder(date)
        } else {
            alarmDateTextField.text = nil
            removeAlarmFromReminder()
        }
        
        doneButton.isEnabled = reminder.hasChanges && !titleTextField.text!.isEmpty
    }
    
    @objc func datePickerValueDidChange() {
        let date = datePicker.date
        updateAlarmDateTextField(withDate: date)
        changeAlarmOfReminder(date)
        
        doneButton.isEnabled = reminder.hasChanges && !titleTextField.text!.isEmpty
    }
    
    // MARK: - UITextFieldDelegate
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        if textField == titleTextField {
            changeReminder(title: textField.text!)
            doneButton.isEnabled = reminder.hasChanges && !textField.text!.isEmpty
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        
        return true
    }
}
