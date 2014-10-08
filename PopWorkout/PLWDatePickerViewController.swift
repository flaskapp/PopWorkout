//
//  PLWDatePickerViewController.swift
//  PopWorkout
//
//  Created by ogawa on 2014/10/07.
//  Copyright (c) 2014年 Flask LLP. All rights reserved.
//

import UIKit

class PLWDatePickerViewController: UIViewController {
    @IBOutlet var contentView:UIView!
    @IBOutlet var datePicker:UIDatePicker!
    @IBOutlet var backgroundImageView:UIImageView!
    @IBOutlet var bottomConstraint:NSLayoutConstraint!

    var selectedDate:NSDate = NSDate()
    var parentImage:UIImage?
    var completionBlock:((selectedDate:NSDate) -> ())?
    
    override func loadView() {
        super.loadView()
        datePicker.date = selectedDate;
//        if parentImage != nil {
//            backgroundImageView.image = parentImage!
//        }
        
//        bottomConstraint.constant += contentView.frame.size.height
//
//        UIView.animateWithDuration(1.0,
//            delay: 0.0,
//            usingSpringWithDamping: 0.5,
//            initialSpringVelocity: 0.1,
//            options: UIViewAnimationOptions(0),
//            animations: {
//                self.bottomConstraint.constant -= self.contentView.frame.size.height
//                self.view.layoutIfNeeded()
//            },
//            completion: nil)
    }
    
    class func show(parent:UIViewController, date:NSDate?, completion:((selectedDate:NSDate) -> ())) {
        let storyboard:UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let controller:PLWDatePickerViewController = storyboard.instantiateViewControllerWithIdentifier("DatePickerViewController") as PLWDatePickerViewController
        
        if date != nil {
            controller.selectedDate = date!
        }
        controller.completionBlock = completion
        
//        UIGraphicsBeginImageContextWithOptions(parent.view.frame.size, false, 0);
//        parent.view.drawViewHierarchyInRect(CGRect(origin: CGPointZero, size: parent.view.frame.size), afterScreenUpdates: true)
//        var fromFullImage:UIImage = UIGraphicsGetImageFromCurrentImageContext()
//        UIGraphicsEndImageContext();
//        controller.parentImage = fromFullImage;
        
//        var blur = UIBlurEffect(style: UIBlurEffectStyle.Light)
//        var effectView = UIVisualEffectView(effect: blur)
//        effectView.frame = CGRect(origin: CGPointZero, size: parent.view.frame.size)
//        effectView.setTranslatesAutoresizingMaskIntoConstraints(false)
//        parent.view.addSubview(effectView)

        parent.presentViewController(controller, animated: true) { () -> Void in
            //controller.backgroundImageView.image = fromFullImage
        }
        //parent.presentViewController(controller, animated: true, completion:nil)
    }

    @IBAction func ok() {
        if completionBlock != nil {
            completionBlock!(selectedDate:self.datePicker.date)
        }
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
//    //MARK: UIViewControllerTransitioningDelegate implements
//    
//    func animationControllerForPresentedController(presented: UIViewController, presentingController presenting: UIViewController, sourceController source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
//        isDismiss = false
//        return self
//    }
//    
//    func animationControllerForDismissedController(dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
//        isDismiss = true
//        return self
//    }
//    
//    // MARK: UIViewControllerAnimatedTransitioning implements
//    
//    func transitionDuration(transitionContext: UIViewControllerContextTransitioning) -> NSTimeInterval {
//        return 0.3
//    }
//    
//    func animateTransition(transitionContext: UIViewControllerContextTransitioning) {
//        if isDismiss {
//            
//        }
//    }
//    
//    func animateForPresented(transitionContext:UIViewControllerContextTransitioning) {
//        let fromVC:UIViewController = transitionContext.viewControllerForKey(UITransitionContextFromViewControllerKey)!
//        let toVC:UIViewController = transitionContext.viewControllerForKey(UITransitionContextToViewControllerKey)!
//        let containerView:UIView = transitionContext.containerView()
//        let initialFrameFromVC:CGRect = transitionContext.initialFrameForViewController(fromVC);
//    
//        let screenBounds = UIScreen.mainScreen().bounds
//        
//    CGRect screenBounds = [[UIScreen mainScreen] bounds];
//    CGRect mainRect = toVC.mainView.frame;
//    CGFloat originaiY = mainRect.origin.y;
//    mainRect.origin.y = screenBounds.size.height;
//    toVC.mainView.frame = mainRect;
//    
//    [containerView addSubview:toVC.view];
//    mainRect.origin.y = originaiY;
//    toVC.view.alpha = 0.2;
//    
//    [UIView animateWithDuration:[self transitionDuration:nil]
//    animations:^{
//    toVC.view.frame = initialFrameFromVC;
//    toVC.view.alpha = 1.0;
//    toVC.mainView.frame = mainRect;
//    } completion:^(BOOL finished) {
//    [transitionContext completeTransition:YES];
//    }];
//    
//    }
    
//    func animateForDismissed:(transitionContext:UIViewControllerContextTransitioning) {
//        let fromVC = [transitionContext viewControllerForKey: UITransitionContextFromViewControllerKey];
//    UIViewController *toVC = [transitionContext viewControllerForKey: UITransitionContextToViewControllerKey];
//    
//    CGRect screenBounds = [[UIScreen mainScreen] bounds];
//    CGRect mainRect = fromVC.mainView.frame;
//    mainRect.origin.y = screenBounds.size.height;
//    [UIView animateWithDuration:0.3
//    delay:0
//    options:UIViewAnimationOptionCurveEaseInOut
//    animations:^{
//    fromVC.mainView.frame = mainRect;
//    toVC.view.alpha = 1.0;
//    } completion:^(BOOL finished) {
//    [transitionContext completeTransition:YES];
//    }];
//    }

}
