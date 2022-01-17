//
//  PermissionsManager.swift
//  V1NewVodone
//
//  Created by blur on 2020/8/30.
//  Copyright © 2020 Jeejio. All rights reserved.
//

import Photos
import AVFoundation

public enum PermissionStatus: Int {
    case notDetermined
    case notAvailable
    case denied
    case authorized

    public init(rawValue: Int) {
        switch rawValue {
        case 0:
            self = .notDetermined
        case 1:
            self = .notAvailable
        case 2:
            self = .denied
        case 3, 4:
            self = .authorized
        default:
            self = .notAvailable
        }
    }

    func isAuthorized() -> Bool {
        return self == .authorized
    }

    var permissionStatusString: String {
        switch self {
        case .notDetermined:
            return "notDetermined"
        case .notAvailable:
            return "notAvailable"
        case .denied:
            return "denied"
        case .authorized:
            return "authorized"
        }
    }
}

public enum PermissionType: String {
    case camera
    case photos

    func isNecessary() -> Bool {
        return false
    }
}

public typealias PermissionStatusResponse = (PermissionStatus) -> Void

public protocol PermissionsManagerInterface {
    func fetchStatus(for permission: PermissionType, with complete: @escaping PermissionStatusResponse)

    func request(permisson: PermissionType, with complete: @escaping PermissionStatusResponse)

    func status(for permission: PermissionType) -> PermissionStatus
}

public protocol PermissionInterface {
    func fetchStatus(with complete: @escaping PermissionStatusResponse)

    func request(with complete: @escaping PermissionStatusResponse)

    var status: PermissionStatus { get }
}

class PermissionsManager: PermissionsManagerInterface {
    static let shared = PermissionsManager()

    private init() {}

    func fetchStatus(for permission: PermissionType, with complete: @escaping PermissionStatusResponse) {
        let manager = self.manager(for: permission)
        manager.fetchStatus { (status) in
            DispatchQueue.main.async {
                complete(status)
            }
        }
    }

    func request(permisson: PermissionType, with complete: @escaping PermissionStatusResponse) {
        let manager = self.manager(for: permisson)
        manager.request { (status) in
            DispatchQueue.main.async {
                complete(status)
            }
        }
    }

    func status(for permission: PermissionType) -> PermissionStatus {
        let manager = self.manager(for: permission)
        return manager.status
    }

    func isAuthorized(for permission: PermissionType) -> Bool {
        let status = self.status(for: permission)
        return status.isAuthorized()
    }

    private lazy var cameraPermission = CameraPermission()
    private lazy var photosPermission = PhotosPermission()

    private func manager(for permission: PermissionType) -> PermissionInterface {
        switch permission {
        case .camera:
            return self.cameraPermission
        case .photos:
            return self.photosPermission
        }
    }
}

class CameraPermission: PermissionInterface {
    var status: PermissionStatus {
        let status = AVCaptureDevice.authorizationStatus(for: AVMediaType.video)
        return PermissionStatus(rawValue: status.rawValue)
    }

    func fetchStatus(with complete: @escaping PermissionStatusResponse) {
        complete(self.status)
    }

    func request(with complete: @escaping PermissionStatusResponse) {
        AVCaptureDevice.requestAccess(for: AVMediaType.video) { (_) in
            complete(self.status)
        }
    }
}

class PhotosPermission: PermissionInterface {
    var status: PermissionStatus {
        let status = PHPhotoLibrary.authorizationStatus()
        return PermissionStatus(rawValue: status.rawValue)
    }

    func fetchStatus(with complete: @escaping PermissionStatusResponse) {
        complete(self.status)
    }

    func request(with complete: @escaping PermissionStatusResponse) {
        PHPhotoLibrary.requestAuthorization { (status) in
            let status = PermissionStatus(rawValue: status.rawValue)
            complete(status)
        }
    }
}
