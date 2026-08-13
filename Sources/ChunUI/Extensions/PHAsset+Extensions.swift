import Photos

extension PHAsset {
    /// Retrieve the filename of a photo from the photos library using information from `PHAsset`
    /// 
    var originalFilename: String? {
        let resources = PHAssetResource.assetResources(for: self)
        return resources.first?.originalFilename
    }
}
