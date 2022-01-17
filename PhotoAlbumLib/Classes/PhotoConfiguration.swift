//
//  PhotoConfiguration.swift
//  wutong
//
//  Created by Jeejio on 2021/12/23.
//

import Foundation
import UIKit

public class PhotoConfiguration: NSObject {
    /// Default is 9 / 默认最大可选9张图片
    public var maxImagesCount = 9
    /// Default is 50 * 1024 * 1024 b
    public var maxImageByte = 50.0 * 1024 * 1024
    /// The minimum count photos user must pick, Default is 0
    /// 最小照片必选张数,默认是0
    public var minImagesCount = 0
    /// 是否允许裁剪，默认为false
    public var allowCrop = false
    /// Photo sorting method, the preview interface is not affected by this parameter. Defaults to true.
    public var sortAscending = true
    /// If set to false, gif and livephoto cannot be selected either. Defaults to true.
    public var allowSelectImage = true
    public var allowSelectVideo = true
    
    /// Allow select Gif, it only controls whether it is displayed in Gif form.
    /// If value is false, the Gif logo is not displayed. Defaults to true.
    public var allowSelectGif = true
    /// Allow select full image. Defaults to true.
    public var allowSelectOriginal = true
    /// Default is NO / 默认为NO，为YES时可以多选视频/gif/图片，和照片共享最大可选张数maxImagesCount的限制
    public var allowPickingMultipleVideo = false
    
    /// In single selection mode, whether to display the selection button. Defaults to false.
    public var showSelectBtnWhenSingleSelect = false
    
    public var statusBarStyle: UIStatusBarStyle = .lightContent
    
    /// Allow select LivePhoto, it only controls whether it is displayed in LivePhoto form.
    /// If value is false, the LivePhoto logo is not displayed. Defaults to false.
    public var allowSelectLivePhoto = false
    /// Display the index of the selected photos. Defaults to true.
    public var showSelectedIndex = true
    /// Allow to choose the maximum duration of the video. Defaults to 1200.
    public var maxSelectVideoDuration: Int = 1200
    /// Allow to choose the minimum duration of the video. Defaults to 0.
    public var minSelectVideoDuration: Int = 0
    /// Overlay a mask layer on top of the selected photos. Defaults to true.
    public var showSelectedMask = true
    /// Overlay a mask layer above the cells that cannot be selected. Defaults to true.
    public var showInvalidMask = true
    /// The column count when iPhone is in portait mode. Defaults to 4.
    public var columnCount: Int = 4
    /// Allow access to the preview large image interface (That is, whether to allow access to the large image interface after clicking the thumbnail image). Defaults to true.
    public var allowPreviewPhotos = true
    /// Default is NO, if set YES, the picker Will the callback.
    /// 默认为NO，如果设置为YES, 选择器将会先callback 再自己dismiss
    public var autoCallbacksFirst = false
    
    public var showPreviewButtonInAlbum = true
    /// After selecting a image/video in the thumbnail interface, enter the editing interface directly. Defaults to false.
    /// - discussion: Editing image is only valid when allowEditImage is true and maxSelectCount is 1.
    public var editAfterSelectThumbnailImage = false
    /// Display the selected photos at the bottom of the preview large photos interface. Defaults to false.
    public var showPreviewSelectPhotoBar = false
    /// Show the image captured by the camera is displayed on the camera button inside the album. Defaults to false.
    public var showCaptureImageOnTakePhotoBtn = false
    
    private var pri_allowTakePhoto = true
    /// Allow taking photos in the camera (Need allowSelectImage to be true). Defaults to true.
    public var allowTakePhoto: Bool {
        get {
            return pri_allowTakePhoto && allowSelectImage
        }
        set {
            pri_allowTakePhoto = newValue
        }
    }
    
    private var pri_allowRecordVideo = true
    /// Allow recording in the camera (Need allowSelectVideo to be true). Defaults to true.
    public var allowRecordVideo: Bool {
        get {
            return pri_allowRecordVideo && allowSelectVideo
        }
        set {
            pri_allowRecordVideo = newValue
        }
    }
    
    private var pri_maxVideoSelectCount = 0
    /// A count for video max selection. Defaults to 0.
    /// - warning: Only valid in mix selection mode. (i.e. allowMixSelect = true)
    public var maxVideoSelectCount: Int {
        get {
            if pri_maxVideoSelectCount <= 0 {
                return maxImagesCount
            } else {
                return max(minVideoSelectCount, min(pri_maxVideoSelectCount, maxImagesCount))
            }
        }
        set {
            pri_maxVideoSelectCount = newValue
        }
    }
    
    private var pri_minVideoSelectCount = 0
    /// A count for video min selection. Defaults to 0.
    /// - warning: Only valid in mix selection mode. (i.e. allowMixSelect = true)
    public var minVideoSelectCount: Int {
        get {
            return min(maxImagesCount, max(pri_minVideoSelectCount, 0))
        }
        set {
            pri_minVideoSelectCount = newValue
        }
    }
    
    /// Allow framework fetch photos when callback. Defaults to true.
    public var shouldAnialysisAsset = true
    private var pri_allowEditImage = true
    public var allowEditImage: Bool {
        get {
            return pri_allowEditImage && shouldAnialysisAsset
        }
        set {
            pri_allowEditImage = newValue
        }
    }
    
    private var pri_allowEditVideo = false
    public var allowEditVideo: Bool {
        get {
            return pri_allowEditVideo && shouldAnialysisAsset
        }
        set {
            pri_allowEditVideo = newValue
        }
    }
    
    /// A color for navigation bar spinner.
    public var navBarColor = UIColor.white
    
    /// A color for navigation bar in preview interface.
    public var navBarColorOfPreviewVC = RGB(46, 47, 51)
    
    /// A color for Navigation bar text.
    public var navTitleColor = UIColor.black
        
    /// The background color of the title view when the frame style is embedAlbumList.
    public var navEmbedTitleViewBgColor = RGB(216, 216, 216)
    
    /// A color for background in album list.
    public var albumListBgColor = UIColor.white
    
    /// A color for album list title label.
    public var albumListTitleColor = UIColor.black
    
    /// A color for album list count label.
    public var albumListCountColor = UIColor.black
    
    /// A color for album list separator.
    public var separatorColor = UIColor(hexString: "#EDEDED")
    
    /// A color for background in thumbnail interface.
    public var thumbnailBgColor = UIColor.white
    
    /// A color for background in bottom tool view.
    public var bottomToolViewBgColor = UIColor.white
    
    /// A color for background in bottom tool view in preview interface.
    public var bottomToolViewBgColorOfPreviewVC = RGB(46, 47, 51)
    
    /// The normal state title color of bottom tool view buttons.
    public var bottomToolViewBtnNormalTitleColor = UIColor.black
        
    /// The disable state title color of bottom tool view buttons.
    public var bottomToolViewBtnDisableTitleColor = RGB(193, 197, 204)
        
    /// The normal state background color of bottom tool view buttons.
    public var bottomToolViewBtnNormalBgColor = UIColor(hexString: "#5A90FB")
        
    /// The disable state background color of bottom tool view buttons.
    public var bottomToolViewBtnDisableBgColor = RGB(193, 197, 204)
                
    /// Mask layer color of selected cell.
    public var selectedMaskColor = UIColor.black.withAlphaComponent(0.5)
        
    /// Mask layer color of the cell that cannot be selected.
    public var invalidMaskColor = UIColor.black.withAlphaComponent(0.5)
    
    /// The background color of selected cell index label.
    public var indexLabelBgColor = UIColor(hexString: "#5A90FB")
    
    /// 聊天配置
    public func chatConfiguration() {
        allowSelectGif = true
        allowPickingMultipleVideo = true
        allowCrop = false
        maxImagesCount = 9
        allowPreviewPhotos = true
        allowSelectVideo = allowCrop ? false : true
        showPreviewSelectPhotoBar = false
        autoCallbacksFirst = true
    }
    /// 扫码配置
    public func codeConfiguration() {
        allowSelectGif = false
        allowPickingMultipleVideo = false
        allowCrop = false
        maxImagesCount = 1
        allowPreviewPhotos = false
        allowSelectVideo = false
        showPreviewSelectPhotoBar = false
        autoCallbacksFirst = false
    }
    /// 头像配置
    public func headConfiguration() {
        allowSelectGif = false
        allowPickingMultipleVideo = false
        allowCrop = true
        maxImagesCount = 1
        allowPreviewPhotos = true
        allowSelectVideo = allowCrop ? false : true
        showPreviewSelectPhotoBar = false
        autoCallbacksFirst = false
    }
}
