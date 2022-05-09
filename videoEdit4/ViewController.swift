import UIKit
import AVKit

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
 
    //Original video. A lot of layers to make it work
    var videoAsset : AVURLAsset?    //The actual video/in the app, holds the tracks
    var videoUrl: URL?              //Used to create the videoAsset
    var playerItem : AVPlayerItem?  //This takes the asset and allows it to be
                                    //loaded in the player
    
    //Temporary videos used when modifying video
    var tempVideoUrl: URL?
    var tempVideoAsset : AVURLAsset?
    
    //Video player
    var player : AVPlayer?
    var playerViewController: AVPlayerViewController?
    
    //used to select video from device (does not load videos correctly)
    let imagePickerController = UIImagePickerController()
    //used for conditional statements to select the correct menu
    var selectionMenuName: String?
    
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
    
    //Toggles the video selection menu
    @IBAction func toggleSelection(_ sender: Any) {
        selectionVideoMenu.isHidden = !selectionVideoMenu.isHidden
    }
    
    //Delegate for the imagePickerController (Does not load the video correctly)
    private func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
    tempVideoUrl =  info["UIImagePickerControllerMediaURL"] as? URL
    imagePickerController.dismiss(animated: true, completion: nil)
    }
    
    //loads the video selected and calls the imagePickerController
    //to enter the device photo library
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
    
    //Toggles the correct view and hides the other when the merge button is selected
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
    
    //Toggles the correct view when and hides the other when the trim button is selected
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
    
    //Opens a menu to allow user to select the 2nd video to merge
    @IBAction func toggleMergeMenu(_ sender: Any) {
        selectionMergeMenu.isHidden = !selectionMergeMenu.isHidden
    }
    

    //Adds the video selected to a temporary variable and calls the mergeVideo function
    //(and opens the imagePickerController if selected)
    
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
    
    //Combines the 2 video assets into a AVMutableComposition and loads the player with
    //the new video asset
    func mergeVideo(videoUrl2: URL ){
        statusMergeLabel.text = ""
        let videoAsset2 =  AVURLAsset(url: videoUrl2)
        
        let composition = AVMutableComposition()
        
        //Creates the video and audio tracks on the AVMutableComposition
        let videoTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)
        let audioTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)
        
        //Create the video tracks from the 2 videos
        let videoAssetTrack1 = player?.currentItem?.asset.tracks(withMediaType: .video).first!
        let videoAssetTrack2 = videoAsset2.tracks(withMediaType: .video).first!

        //Creates the time ranges based on the 2 video assets
        let timeRange1 = CMTimeRangeMake(start: CMTime.zero, duration: videoAsset!.duration)
        let timeRange2 = CMTimeRangeMake(start: CMTime.zero, duration: videoAsset2.duration)
        
        //Error flag to display error/success messages
        var errorFlag = false

        //Tests for audio tracks and adds then if they exist
        let audioTest1 = videoAsset!.tracks(withMediaType: .audio)
        let audioTest2 = videoAsset2.tracks(withMediaType: .audio)
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
    
        //Adds the video tracks to the composition based on the time ranges
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
        
        //Updates the player and the error/success messages
        if (!errorFlag){
            let compositeItem = AVPlayerItem(asset: composition)
            player?.replaceCurrentItem(with: compositeItem)
            statusMergeLabel.text = "Merge Successful"
            //Hides the add video button because you can only merge 2 videos at a time
            btnAddVideo.isHidden = true
        } else{
            statusMergeLabel.text = "Merge Unsuccessful"
        }
    }
    
    //Gets the trimming start time from the slider and sets the variables for preview
    @IBAction func sliderTrimStart(_ sender: Any) {
       if let duration = player?.currentItem?.duration{
            let totalSeconds = CMTimeGetSeconds(duration) * Double(sliderStartOutlet.value)
            let seekTime = CMTimeMakeWithSeconds(totalSeconds, preferredTimescale: 1)
            player?.seek(to: seekTime)
           
           let minutes = String(format: "%02d", Int(totalSeconds) / 60 )
           let seconds = String(format: "%02d", Int(totalSeconds) % 60 )
           sliderStartOutput.text = "\(minutes):\(seconds)"
           
           //Below code was going to be used to export
           //let timeRange = CMTimeRangeMake(start: CMTime.zero, duration: videoAsset.duration)
        }
        
    }
    
    //Gets the trimming end time from the slider and sets the variables for preview
    //CMTime is needed for the player, while time in seconds is used for
    //conversion to and from slider
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
    
    //Sets the start and time for the player and plays the video
    @IBAction func trimPreview(_ sender: UIButton) {
        trimStatus.text = ""
        let duration = player?.currentItem?.duration
        let startTotalSeconds = CMTimeGetSeconds(duration!) * Double(sliderStartOutlet.value)
        let startSeekTime = CMTimeMakeWithSeconds(startTotalSeconds, preferredTimescale: 1)
        let endTotalSeconds = CMTimeGetSeconds(duration!) * Double(sliderEndOutlet.value)
        let endSeekTime = CMTimeMakeWithSeconds(endTotalSeconds, preferredTimescale: 1)
        
        //Only plays if valid times are used, otherwise displays and error
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
    
    //Loads the player
    func loadVideo(){
        videoAsset = AVURLAsset(url: videoUrl!)
        playerItem = AVPlayerItem(asset: videoAsset!)
        player = AVPlayer(playerItem: playerItem)
        
        //Creates the player and controller
        //resizes it based on the bounds of the view
        //loads the controller into the view and then loads the player
        playerViewController = AVPlayerViewController()
        playerViewController?.videoGravity = .resizeAspectFill
        playerViewController?.view.frame = videoView.bounds
        playerViewController?.player = player
        self.addChild(playerViewController!)
        videoView.addSubview(playerViewController!.view)
        //playerViewController?.player?.play()
    }
}
