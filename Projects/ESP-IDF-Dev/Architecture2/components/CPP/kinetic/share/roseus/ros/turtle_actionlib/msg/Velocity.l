;; Auto-generated. Do not edit!


(when (boundp 'turtle_actionlib::Velocity)
  (if (not (find-package "TURTLE_ACTIONLIB"))
    (make-package "TURTLE_ACTIONLIB"))
  (shadow 'Velocity (find-package "TURTLE_ACTIONLIB")))
(unless (find-package "TURTLE_ACTIONLIB::VELOCITY")
  (make-package "TURTLE_ACTIONLIB::VELOCITY"))

(in-package "ROS")
;;//! \htmlinclude Velocity.msg.html


(defclass turtle_actionlib::Velocity
  :super ros::object
  :slots (_linear _angular ))

(defmethod turtle_actionlib::Velocity
  (:init
   (&key
    ((:linear __linear) 0.0)
    ((:angular __angular) 0.0)
    )
   (send-super :init)
   (setq _linear (float __linear))
   (setq _angular (float __angular))
   self)
  (:linear
   (&optional __linear)
   (if __linear (setq _linear __linear)) _linear)
  (:angular
   (&optional __angular)
   (if __angular (setq _angular __angular)) _angular)
  (:serialization-length
   ()
   (+
    ;; float32 _linear
    4
    ;; float32 _angular
    4
    ))
  (:serialize
   (&optional strm)
   (let ((s (if strm strm
              (make-string-output-stream (send self :serialization-length)))))
     ;; float32 _linear
       (sys::poke _linear (send s :buffer) (send s :count) :float) (incf (stream-count s) 4)
     ;; float32 _angular
       (sys::poke _angular (send s :buffer) (send s :count) :float) (incf (stream-count s) 4)
     ;;
     (if (null strm) (get-output-stream-string s))))
  (:deserialize
   (buf &optional (ptr- 0))
   ;; float32 _linear
     (setq _linear (sys::peek buf ptr- :float)) (incf ptr- 4)
   ;; float32 _angular
     (setq _angular (sys::peek buf ptr- :float)) (incf ptr- 4)
   ;;
   self)
  )

(setf (get turtle_actionlib::Velocity :md5sum-) "9d5c2dcd348ac8f76ce2a4307bd63a13")
(setf (get turtle_actionlib::Velocity :datatype-) "turtle_actionlib/Velocity")
(setf (get turtle_actionlib::Velocity :definition-)
      "# Copied from turtlesim https://github.com/ros/ros_tutorials/blob/f7da7779e82dcc3977b2c220a843cd86dd269832/turtlesim/msg/Velocity.msg. We had to copy this into this package since it has been replaced with geometry_msgs/Twist there and comforming to Twist requires to change code, which I doubt worth time it takes. So if you think it is, please go ahead make a patch.

float32 linear
float32 angular

")



(provide :turtle_actionlib/Velocity "9d5c2dcd348ac8f76ce2a4307bd63a13")


