import Testing
import Foundation
@testable import RcloneGUI

@Suite("SchedulerViewModel Tests")
struct SchedulerViewModelTests {
    @Test("ScheduledTask — default init")
    func taskDefaultInit() {
        let task = ScheduledTask(profileId: UUID(), profileName: "Test", interval: 3600)
        #expect(task.profileName == "Test")
        #expect(task.interval == 3600)
        #expect(task.enabled == true)
        #expect(task.lastRun == nil)
        #expect(task.nextRun != nil)
    }

    @Test("ScheduledTask — interval label minutes")
    func intervalLabelMinutes() {
        L10n.locale = "en"
        let task = ScheduledTask(profileId: UUID(), profileName: "T", interval: 1800)
        #expect(task.intervalLabel.contains("30"))
    }

    @Test("ScheduledTask — interval label hours")
    func intervalLabelHours() {
        L10n.locale = "en"
        let task = ScheduledTask(profileId: UUID(), profileName: "T", interval: 7200)
        #expect(task.intervalLabel.contains("2"))
    }

    @Test("ScheduledTask — interval label days")
    func intervalLabelDays() {
        L10n.locale = "en"
        let task = ScheduledTask(profileId: UUID(), profileName: "T", interval: 172800)
        #expect(task.intervalLabel.contains("2"))
    }

    @Test("Add and remove task")
    func addRemoveTask() {
        let vm = SchedulerViewModel()
        vm.tasks = []
        let task = ScheduledTask(profileId: UUID(), profileName: "Backup", interval: 3600)
        vm.addTask(task)
        #expect(vm.tasks.count == 1)
        vm.removeTask(id: task.id)
        #expect(vm.tasks.isEmpty)
    }

    @Test("Toggle task enabled")
    func toggleTask() {
        let vm = SchedulerViewModel()
        vm.tasks = []
        let task = ScheduledTask(profileId: UUID(), profileName: "Sync", interval: 600)
        vm.addTask(task)
        #expect(vm.tasks[0].enabled == true)
        vm.toggleTask(id: task.id)
        #expect(vm.tasks[0].enabled == false)
        vm.toggleTask(id: task.id)
        #expect(vm.tasks[0].enabled == true)
    }
}
