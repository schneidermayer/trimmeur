import Foundation
import ServiceManagement

protocol AutoStartManaging {
    var isEnabled: Bool { get }
    func setEnabled(_ enabled: Bool) throws
}

struct AutoStartManager: AutoStartManaging {
    var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled || SMAppService.mainApp.status == .requiresApproval
    }

    func setEnabled(_ enabled: Bool) throws {
        if enabled {
            if SMAppService.mainApp.status != .enabled {
                try SMAppService.mainApp.register()
            }
        } else if SMAppService.mainApp.status == .enabled || SMAppService.mainApp.status == .requiresApproval {
            try SMAppService.mainApp.unregister()
        }
    }
}
