//
//  MainViewController.swift
//  Flicks
//
//  Created by Darrell Shi on 5/4/16.
//  Copyright © 2016 Darrell Shi. All rights reserved.
//

import UIKit
import AFNetworking
import BFRadialWaveHUD

class MainViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!
    var endpoint: String?
    var refreshControl: UIRefreshControl!
    var hud: BFRadialWaveHUD?
    var loadingIndicator: InfiniteScrollActivityView?
    
    var movies: [NSDictionary]?
    var filteredMovies: [NSDictionary]?
    
    var isMoreDataLoading = false
    var page = 2
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        searchBar.delegate = self
        
        hud = BFRadialWaveHUD.init(view: self.view, fullScreen: true, circles: 30, circleColor: UIColor.whiteColor(), mode: BFRadialWaveHUDMode.Default, strokeWidth: 1.5)
        hud!.show()
        
        refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(MainViewController.onRefresh), forControlEvents: UIControlEvents.ValueChanged)
        tableView.insertSubview(refreshControl, atIndex: 0)
        
        setupLoadingIndicator()
        
        networkRequest()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    private func setupLoadingIndicator() {
        let frame = CGRectMake(0, tableView.contentSize.height, tableView.bounds.size.width, InfiniteScrollActivityView.defaultHeight)
        loadingIndicator = InfiniteScrollActivityView(frame: frame)
        loadingIndicator!.hidden = true
        tableView.addSubview(loadingIndicator!)
    }
    
    private func networkRequest() {
        let apiKey = "a07e22bc18f5cb106bfe4cc1f83ad8ed"
        let url = NSURL(string:"https://api.themoviedb.org/3/movie/\(endpoint!)?api_key=\(apiKey)")
        let request = NSURLRequest(URL: url!)
        let session = NSURLSession(
            configuration: NSURLSessionConfiguration.defaultSessionConfiguration(),
            delegate:nil,
            delegateQueue:NSOperationQueue.mainQueue()
        )
        
        let task : NSURLSessionDataTask = session.dataTaskWithRequest(request,
                                                                      completionHandler: { (dataOrNil, response, error) in
                                                                        if let data = dataOrNil {
                                                                            if let responseDictionary = try! NSJSONSerialization.JSONObjectWithData(
                                                                                data, options:[]) as? NSDictionary {
                                                                                //                            NSLog("response: \(responseDictionary)")
                                                                                self.movies = responseDictionary["results"] as? [NSDictionary]
                                                                                self.filteredMovies = self.movies
                                                                                self.tableView.reloadData()
                                                                                self.hud?.dismiss()
                                                                                self.refreshControl.endRefreshing()
                                                                            }
                                                                        } else {
                                                                            print("network error")
                                                                        }
        });
        task.resume()
    }
    
    func onRefresh() {
        networkRequest()
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if(segue.identifier == "showDetail") {
            let cell = sender as! UITableViewCell
            let indexPath = tableView.indexPathForCell(cell)
            let detailView = segue.destinationViewController as! DetailViewController
            detailView.movie = filteredMovies![indexPath!.row]
        }
    }
}

extension MainViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let movies = filteredMovies {
            return movies.count
        }
        return 0
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("MovieCell", forIndexPath: indexPath) as! MovieCell
        if let filteredMovies = filteredMovies {
            let movie = filteredMovies[indexPath.row]
            let title = movie["title"] as? String
            cell.titleLabel.text = title
            let overview = movie["overview"] as? String
            cell.overviewLabel.text = overview
            if let rate = movie["vote_average"] as? Float {
                cell.rateLabel.text = String(format: "%.1f", rate)
            }
            
            if let posterUrl = movie["poster_path"] as? String {
                let baseUrl = "https://image.tmdb.org/t/p/w500"
                let picUrl_str = baseUrl + posterUrl
                let picUrl = NSURL(string: picUrl_str)
                let imageRequest = NSURLRequest(URL: picUrl!)
                
                cell.posterImageView.setImageWithURLRequest(imageRequest, placeholderImage: nil,
                                                            success: {(imageRequest, imageResponse, image) -> Void in
                                                                if imageResponse != nil {
                                                                    cell.posterImageView.alpha = 0.0
                                                                    cell.posterImageView.image = image
                                                                    UIView.animateWithDuration(1, animations: { () -> Void in
                                                                        cell.posterImageView.alpha = 1.0
                                                                    })
                                                                } else {
                                                                    cell.posterImageView.image = image
                                                                }
                    }, failure: { (imageRequest, imageResponse, error) -> Void in
                        // do something for the failure condition
                })
            }
        }
        cell.selectionStyle = .None
        let backgroundView = UIView()
        backgroundView.backgroundColor = UIColor.redColor()
        cell.selectedBackgroundView = backgroundView
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: false)
    }
}

extension MainViewController: UISearchBarDelegate {
    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
        if let searchText = searchBar.text {
            if searchText == "" {
                filteredMovies = movies
            } else {
                filteredMovies = movies?.filter({(movieTemp: NSDictionary) -> Bool in
                    let movieTitle = movieTemp["title"] as! String
                    return movieTitle.rangeOfString(searchText, options: .CaseInsensitiveSearch) != nil
                })
            }
        }
        tableView.reloadData()
    }
    
    func searchBarTextDidBeginEditing(searchBar: UISearchBar) {
        searchBar.showsCancelButton = true
    }
    
    func searchBarCancelButtonClicked(searchBar: UISearchBar) {
        searchBar.showsCancelButton = false
        searchBar.text = ""
        searchBar.resignFirstResponder()
        filteredMovies = movies
        tableView.reloadData()
    }
}

extension MainViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(scrollView: UIScrollView) {
        if !isMoreDataLoading {
            let scrollViewContentHeight = tableView.contentSize.height
            let scrollOffsetThreshold = scrollViewContentHeight - tableView.bounds.size.height
            
            if scrollView.contentOffset.y > scrollOffsetThreshold && tableView.dragging {
                isMoreDataLoading = true
                
                loadingIndicator?.startAnimating()
                loadMoreData()
            }
        }
    }
    
    private func loadMoreData() {
        let session = NSURLSession(
            configuration: NSURLSessionConfiguration.defaultSessionConfiguration(),
            delegate:nil,
            delegateQueue:NSOperationQueue.mainQueue()
        )
        
        let apiKey = "a07e22bc18f5cb106bfe4cc1f83ad8ed"
        let url = NSURL(string:"https://api.themoviedb.org/3/movie/\(endpoint!)?api_key=\(apiKey)&page=\(page)")
        let request = NSURLRequest(URL: url!)
        let task : NSURLSessionDataTask = session.dataTaskWithRequest(request,
                                                                      completionHandler: { (data, response, error) in
                                                                        if let data = data {
                                                                            if let responseDictionary = try! NSJSONSerialization.JSONObjectWithData(
                                                                                data, options:[]) as? NSDictionary {
                                                                                let newMovies = responseDictionary["results"] as? [NSDictionary]
                                                                                if let newMovies = newMovies {
                                                                                    self.movies?.appendContentsOf(newMovies)
                                                                                }
                                                                                self.filteredMovies = self.movies
                                                                                self.tableView.reloadData()
                                                                            }
                                                                        } else {
                                                                            print("network error")
                                                                        }
                                                                        
                                                                        self.isMoreDataLoading = false
                                                                        self.page += 1
                                                                        self.loadingIndicator?.stopAnimating()
        });
        task.resume()
    }
}