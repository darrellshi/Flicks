//
//  DetailViewController.swift
//  Flicks
//
//  Created by Darrell Shi on 5/4/16.
//  Copyright © 2016 Darrell Shi. All rights reserved.
//

import UIKit

class DetailViewController: UIViewController {
    var movie: NSDictionary?
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var posterImageView: UIImageView!
    @IBOutlet weak var highResPosterImageView: UIImageView!
    @IBOutlet weak var releaseDateLabel: UILabel!
    @IBOutlet weak var overviewLabel: UILabel!
    
    @IBOutlet weak var infoViewHeightContraint: NSLayoutConstraint!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var infoView: UIView!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        infoView.frame.origin.y = 667
        scrollView.contentSize = CGSize(width: scrollView.frame.size.width, height: infoView.frame.origin.y + 200)
        
        if let movie = movie {
            let title = movie["title"] as? String
            titleLabel.text = title
            
            let releaseDate = movie["release_date"] as? String
            releaseDateLabel.text = releaseDate
            
            let overview = movie["overview"] as? String
            overviewLabel.text = overview
            overviewLabel.sizeToFit()
            let contentHeight = overviewLabel.frame.origin.y + overviewLabel.bounds.size.height + 20
            infoViewHeightContraint.constant = contentHeight
            let backgroundView = UIView(frame: CGRect(origin: CGPoint(x: 0, y: 0), size: CGSize(width: UIScreen.mainScreen().bounds.width, height: contentHeight + 200)))
            backgroundView.backgroundColor = UIColor.blackColor()
            infoView.addSubview(backgroundView)
            infoView.sendSubviewToBack(backgroundView)
            
            if let posterUrl = movie["poster_path"] as? String {
                let smallImageRequest = NSURLRequest(URL: NSURL(string: "https://image.tmdb.org/t/p/w45" + posterUrl)!)
                let largeImageRequest = NSURLRequest(URL: NSURL(string: "https://image.tmdb.org/t/p/original" + posterUrl)!)
                
                posterImageView.setImageWithURLRequest(
                    smallImageRequest,
                    placeholderImage: nil,
                    success: { (smallImageRequest, smallImageResponse, smallImage) -> Void in
                        // smallImageResponse will be nil if the smallImage is already available in cache
                        
                        self.posterImageView.image = smallImage
                        self.posterImageView.alpha = 0
                        UIView.animateWithDuration(0.3, animations: { () -> Void in
                            self.posterImageView.alpha = 1
                            }, completion: { (sucess) -> Void in
                                self.highResPosterImageView.setImageWithURLRequest(largeImageRequest, placeholderImage: smallImage, success: {
                                    (largeImageRequest, largeImageResponse, largeImage) -> Void in
                                    self.highResPosterImageView.image = largeImage
                                    UIView.animateWithDuration(0.5, animations: {()-> Void in
                                        self.highResPosterImageView.alpha = 1
                                    })
                                    }, failure: { (request, response, error) -> Void in
                                        // posterView stays either on the low resilution image or just blank
                                })
                        })
                    },
                    failure: { (request, response, error) -> Void in
                        // try to set the large image
                        self.highResPosterImageView.setImageWithURLRequest(largeImageRequest, placeholderImage: nil, success: {
                            (largeImageRequest, largeImageResponse, largeImage) -> Void in
                            self.highResPosterImageView.image = largeImage
                            UIView.animateWithDuration(1, animations: {()-> Void in
                                self.highResPosterImageView.alpha = 1
                            })
                            }, failure: { (request, response, error) -> Void in
                                // posterView stays either on the low resilution image or just blank
                        })
                })
            }
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

}
