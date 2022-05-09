import UIKit
import AVKit

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
 
    var videoAsset : AVURLAsset?
    var videoUrl: URL?
    var tempVideoUrl: URL?
    var playerItem : AVPlayerItem?
    var player : AVPlayer?
    var playerViewController: AVPlayerViewController?
    let imagePickerController = UIImagePickerController()
    var selectionMenuName: String?
    var tempVideoAsset : AVURLAsset?
    
    
    @IBOutlet weak var trimStatus: UILabel!
    @IBOutlet weak var trimView: UIStackView!
    @IBOutlet weak var mergeView: UIStackView!
    @IBOutlet weak var statusMergeLabel: UILabel!
    @IBOutlet weak var sliderStartOutput: UILabel!
    @IBOutlet weak var sliderEndOutput: UILabel!
    @IBOutlet weak var sliderStartOutlet: UISlider!
    @IBOutlet weak var sliderEndOutlet: UISlider!
    @IBOutlet weak var videoView: UIScrollView!
    @IBOutlet weak var selectionMergeMenu: UIStackView!
    @IBOutlet weak var selectionVideoMenu: UIStackView!
    @IBOutlet weak var buttonView: UIStackView!
    @IBOutlet weak var btnAddVideo: UIButton!
    @IBOutlet weak var btnMergeView: UIButton!
    @IBOutlet weak var btnTrimView: UIButton!
    @IBAction func toggleSelection(_ sender: Any) {
        selectionVideoMenu.isHidden = !selectionVideoMenu.isHidden
    }
    
    private func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
    tempVideoUrl =  info["UIImagePickerControllerMediaURL"] as? URL
    imagePickerController.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func btnVideoSelection(_ sender: UIButton) {
        let title = sender.titleLabel!.text
        if (title == "Select From Library..."){
            selectionMenuName = "select"
            selectionVideoMenu.isHidden = true
            imagePickerController.sourceType = .photoLibrary
            imagePickerController.delegate = self
            imagePickerController.mediaTypes = ["public.movie"]
            present(imagePickerController, animated: true, completion: nil)
            videoUrl = tempVideoUrl
           // loadVideo()
        }else{
            selectionVideoMenu.isHidden = true
            buttonView.isHidden = false
            videoUrl = URL (fileURLWithPath: Bundle.main.path(forResource: title!, ofType: "mp4")!)
            loadVideo()
            btnAddVideo.isHidden = false
            statusMergeLabel.text = ""
        }
    }
    
    @IBAction func toggleMergeView(_ sender: Any) {
        trimView.isHidden = true
        mergeView.isHidden = !mergeView.isHidden
        self.btnTrimView.backgroundColor = UIColor.white
        if(mergeView.isHidden == false) {
            self.btnMergeView.backgroundColor = UIColor.lightGray
            
        }else {
            self.btnMergeView.backgroundColor = UIColor.white
        }
    }
    
    @IBAction func toggleTrimView(_ sender: Any) {
        mergeView.isHidden = true
        trimView.isHidden = !trimView.isHidden
        sliderStartOutput.text = ""
        sliderEndOutput.text = ""
        self.btnMergeView.backgroundColor = UIColor.white
        if(trimView.isHidden == false) {
            self.btnTrimView.backgroundColor = UIColor.lightGray
            
        }else {
            self.btnTrimView.backgroundColor = UIColor.white
        }
    }
    
    @IBAction func toggleMergeMenu(_ sender: Any) {
        selectionMergeMenu.isHidden = !selectionMergeMenu.isHidden
    }
    

    @IBAction func btnMergeSelection(_ sender: UIButton) {
    
    let title = sender.titleLabel!.text
        if (title == "Select From Library..."){
            selectionMenuName = "merge"
            selectionMergeMenu.isHidden = true
            imagePickerController.sourceType = .photoLibrary
            imagePickerController.delegate = self
            imagePickerController.mediaTypes = ["public.movie"]
            present(imagePickerController, animated: true, completion: nil)
            
            //mergeVideo(videoUrl2: tempVideoUrl!)
        }else{
            selectionMergeMenu.isHidden = true
            let videoUrl2 = URL (fileURLWithPath: Bundle.main.path(forResource: title!, ofType: "mp4")!)
            mergeVideo(videoUrl2: videoUrl2)
            
        }
    }
    
    func mergeVideo(videoUrl2: URL ){
        statusMergeLabel.text = ""
        let videoAsset2 =  AVURLAsset(url: videoUrl2)

        let composition = AVMutableComposition()
        let videoTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)
        let videoAssetTrack1 = player?.currentItem?.asset.tracks(withMediaType: .video).first!
        let videoAssetTrack2 = videoAsset2.tracks(withMediaType: .video).first!
        let audioTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)
        let audioTest1 = videoAsset!.tracks(withMediaType: .audio)
        let audioTest2 = videoAsset2.tracks(withMediaType: .audio)
        let timeRange1 = CMTimeRangeMake(start: CMTime.zero, duration: videoAsset!.duration)
        let timeRange2 = CMTimeRangeMake(start: CMTime.zero, duration: videoAsset2.duration)
        
        var errorFlag = false
        
        if !audioTest1.isEmpty {
            let audioAssetTrack1 = videoAsset!.tracks(withMediaType: .audio).first!
            do {
                try audioTrack?.insertTimeRange(timeRange1, of: audioAssetTrack1, at: CMTime.zero)
            } catch {
                print("audio merge failed")
                errorFlag = true
                return
            }
        }
        
        else if (!audioTest2.isEmpty) {
            let audioAssetTrack2 = videoAsset2.tracks(withMediaType: .audio).first!
            do {
                try audioTrack?.insertTimeRange(timeRange2, of: audioAssetTrack2, at: videoAsset!.duration)
            } catch {
                print("audio merge failed")
                errorFlag = true
                return
            }
        }
    
        do{
            try videoTrack?.insertTimeRange(timeRange1, of: videoAssetTrack1!, at: CMTime.zero)
        } catch {
            print("video merge failed")
            errorFlag = true
            return
        }
        
        do{
            try videoTrack?.insertTimeRange(timeRange2, of: videoAssetTrack2, at: videoAsset!.duration)
        } catch {
            print("video merge failed")
            errorFlag = true
            return
        }
        
        if (!errorFlag){
            let compositeItem = AVPlayerItem(asset: composition)
            player?.replaceCurrentItem(with: compositeItem)
            statusMergeLabel.text = "Merge Successful"
            btnAddVideo.isHidden = true
        } else{
            statusMergeLabel.text = "Merge Unsuccessful"
        }
    }
    
    @IBAction func sliderTrimStart(_ sender: Any) {
       if let duration = player?.currentItem?.duration{
            let totalSeconds = CMTimeGetSeconds(duration) * Double(sliderStartOutlet.value)
            let seekTime = CMTimeMakeWithSeconds(totalSeconds, preferredTimescale: 1)
            player?.seek(to: seekTime)
           //let timeRange = CMTimeRangeMake(start: CMTime.zero, duration: videoAsset.duration)
           
        //start: CMTimeMakeWithSeconds(totalSeconds, preferredTimescale: 1), duration:
           let minutes = String(format: "%02d", Int(totalSeconds) / 60 )
           let seconds = String(format: "%02d", Int(totalSeconds) % 60 )
            sliderStartOutput.text = "\(minutes):\(seconds)"
        }
        
    }
    
    @IBAction func sliderTrimEnd(_ sender: Any) {
        if let duration = player?.currentItem?.duration{
            let totalSeconds = CMTimeGetSeconds(duration) * Double(sliderEndOutlet.value)
            let seekTime = CMTimeMakeWithSeconds(totalSeconds, preferredTimescale: 1)
            player?.seek(to: seekTime)
            
            let minutes = String(format: "%02d", Int(totalSeconds) / 60 )
            let seconds = String(format: "%02d", Int(totalSeconds) % 60 )
            sliderEndOutput.text = "\(minutes):\(seconds)"
         }
    }
    
    @IBAction func trimPreview(_ sender: UIButton) {
        trimStatus.text = ""
        let duration = player?.currentItem?.duration
        let startTotalSeconds = CMTimeGetSeconds(duration!) * Double(sliderStartOutlet.value)
        let startSeekTime = CMTimeMakeWithSeconds(startTotalSeconds, preferredTimescale: 1)
        let endTotalSeconds = CMTimeGetSeconds(duration!) * Double(sliderEndOutlet.value)
        let endSeekTime = CMTimeMakeWithSeconds(endTotalSeconds, preferredTimescale: 1)
        
        if(startSeekTime  < endSeekTime && (startSeekTime != CMTime.zero && endSeekTime != player?.currentItem?.duration)){

            player?.seek(to: startSeekTime)
            player?.currentItem?.forwardPlaybackEndTime = endSeekTime
            player?.play()
            player?.currentItem?.forwardPlaybackEndTime = (player?.currentItem?.duration)!
        }
        
        else{
            trimStatus.text = "Error: Invalid Seek Times"
        }
    }
    
    
    
    func loadVideo(){
        videoAsset = AVURLAsset(url: videoUrl!)
        playerItem = AVPlayerItem(asset: videoAsset!)
        player = AVPlayer(playerItem: playerItem)
        
        playerViewController = AVPlayerViewController()
        playerViewController?.videoGravity = .resizeAspectFill
        playerViewController?.view.frame = videoView.bounds
        playerViewController?.player = player
        self.addChild(playerViewController!)
        videoView.addSubview(playerViewController!.view)
        //playerViewController?.player?.play()
    }
}
