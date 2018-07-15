// Auto-generated. Do not edit!

// (in-package control_msgs.msg)


"use strict";

const _serializer = _ros_msg_utils.Serialize;
const _arraySerializer = _serializer.Array;
const _deserializer = _ros_msg_utils.Deserialize;
const _arrayDeserializer = _deserializer.Array;
const _finder = _ros_msg_utils.Find;
const _getByteLength = _ros_msg_utils.getByteLength;
let trajectory_msgs = _finder('trajectory_msgs');
let std_msgs = _finder('std_msgs');

//-----------------------------------------------------------

class JointTrajectoryControllerState {
  constructor(initObj={}) {
    if (initObj === null) {
      // initObj === null is a special case for deserialization where we don't initialize fields
      this.header = null;
      this.joint_names = null;
      this.desired = null;
      this.actual = null;
      this.error = null;
    }
    else {
      if (initObj.hasOwnProperty('header')) {
        this.header = initObj.header
      }
      else {
        this.header = new std_msgs.msg.Header();
      }
      if (initObj.hasOwnProperty('joint_names')) {
        this.joint_names = initObj.joint_names
      }
      else {
        this.joint_names = [];
      }
      if (initObj.hasOwnProperty('desired')) {
        this.desired = initObj.desired
      }
      else {
        this.desired = new trajectory_msgs.msg.JointTrajectoryPoint();
      }
      if (initObj.hasOwnProperty('actual')) {
        this.actual = initObj.actual
      }
      else {
        this.actual = new trajectory_msgs.msg.JointTrajectoryPoint();
      }
      if (initObj.hasOwnProperty('error')) {
        this.error = initObj.error
      }
      else {
        this.error = new trajectory_msgs.msg.JointTrajectoryPoint();
      }
    }
  }

  static serialize(obj, buffer, bufferOffset) {
    // Serializes a message object of type JointTrajectoryControllerState
    // Serialize message field [header]
    bufferOffset = std_msgs.msg.Header.serialize(obj.header, buffer, bufferOffset);
    // Serialize message field [joint_names]
    bufferOffset = _arraySerializer.string(obj.joint_names, buffer, bufferOffset, null);
    // Serialize message field [desired]
    bufferOffset = trajectory_msgs.msg.JointTrajectoryPoint.serialize(obj.desired, buffer, bufferOffset);
    // Serialize message field [actual]
    bufferOffset = trajectory_msgs.msg.JointTrajectoryPoint.serialize(obj.actual, buffer, bufferOffset);
    // Serialize message field [error]
    bufferOffset = trajectory_msgs.msg.JointTrajectoryPoint.serialize(obj.error, buffer, bufferOffset);
    return bufferOffset;
  }

  static deserialize(buffer, bufferOffset=[0]) {
    //deserializes a message object of type JointTrajectoryControllerState
    let len;
    let data = new JointTrajectoryControllerState(null);
    // Deserialize message field [header]
    data.header = std_msgs.msg.Header.deserialize(buffer, bufferOffset);
    // Deserialize message field [joint_names]
    data.joint_names = _arrayDeserializer.string(buffer, bufferOffset, null)
    // Deserialize message field [desired]
    data.desired = trajectory_msgs.msg.JointTrajectoryPoint.deserialize(buffer, bufferOffset);
    // Deserialize message field [actual]
    data.actual = trajectory_msgs.msg.JointTrajectoryPoint.deserialize(buffer, bufferOffset);
    // Deserialize message field [error]
    data.error = trajectory_msgs.msg.JointTrajectoryPoint.deserialize(buffer, bufferOffset);
    return data;
  }

  static getMessageSize(object) {
    let length = 0;
    length += std_msgs.msg.Header.getMessageSize(object.header);
    object.joint_names.forEach((val) => {
      length += 4 + val.length;
    });
    length += trajectory_msgs.msg.JointTrajectoryPoint.getMessageSize(object.desired);
    length += trajectory_msgs.msg.JointTrajectoryPoint.getMessageSize(object.actual);
    length += trajectory_msgs.msg.JointTrajectoryPoint.getMessageSize(object.error);
    return length + 4;
  }

  static datatype() {
    // Returns string type for a message object
    return 'control_msgs/JointTrajectoryControllerState';
  }

  static md5sum() {
    //Returns md5sum for a message object
    return '10817c60c2486ef6b33e97dcd87f4474';
  }

  static messageDefinition() {
    // Returns full string definition for message
    return `
    Header header
    string[] joint_names
    trajectory_msgs/JointTrajectoryPoint desired
    trajectory_msgs/JointTrajectoryPoint actual
    trajectory_msgs/JointTrajectoryPoint error  # Redundant, but useful
    
    ================================================================================
    MSG: std_msgs/Header
    # Standard metadata for higher-level stamped data types.
    # This is generally used to communicate timestamped data 
    # in a particular coordinate frame.
    # 
    # sequence ID: consecutively increasing ID 
    uint32 seq
    #Two-integer timestamp that is expressed as:
    # * stamp.sec: seconds (stamp_secs) since epoch (in Python the variable is called 'secs')
    # * stamp.nsec: nanoseconds since stamp_secs (in Python the variable is called 'nsecs')
    # time-handling sugar is provided by the client library
    time stamp
    #Frame this data is associated with
    # 0: no frame
    # 1: global frame
    string frame_id
    
    ================================================================================
    MSG: trajectory_msgs/JointTrajectoryPoint
    # Each trajectory point specifies either positions[, velocities[, accelerations]]
    # or positions[, effort] for the trajectory to be executed.
    # All specified values are in the same order as the joint names in JointTrajectory.msg
    
    float64[] positions
    float64[] velocities
    float64[] accelerations
    float64[] effort
    duration time_from_start
    
    `;
  }

  static Resolve(msg) {
    // deep-construct a valid message object instance of whatever was passed in
    if (typeof msg !== 'object' || msg === null) {
      msg = {};
    }
    const resolved = new JointTrajectoryControllerState(null);
    if (msg.header !== undefined) {
      resolved.header = std_msgs.msg.Header.Resolve(msg.header)
    }
    else {
      resolved.header = new std_msgs.msg.Header()
    }

    if (msg.joint_names !== undefined) {
      resolved.joint_names = msg.joint_names;
    }
    else {
      resolved.joint_names = []
    }

    if (msg.desired !== undefined) {
      resolved.desired = trajectory_msgs.msg.JointTrajectoryPoint.Resolve(msg.desired)
    }
    else {
      resolved.desired = new trajectory_msgs.msg.JointTrajectoryPoint()
    }

    if (msg.actual !== undefined) {
      resolved.actual = trajectory_msgs.msg.JointTrajectoryPoint.Resolve(msg.actual)
    }
    else {
      resolved.actual = new trajectory_msgs.msg.JointTrajectoryPoint()
    }

    if (msg.error !== undefined) {
      resolved.error = trajectory_msgs.msg.JointTrajectoryPoint.Resolve(msg.error)
    }
    else {
      resolved.error = new trajectory_msgs.msg.JointTrajectoryPoint()
    }

    return resolved;
    }
};

module.exports = JointTrajectoryControllerState;
