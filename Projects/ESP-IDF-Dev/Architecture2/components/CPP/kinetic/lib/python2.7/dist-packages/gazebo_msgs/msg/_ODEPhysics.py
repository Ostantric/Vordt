# This Python file uses the following encoding: utf-8
"""autogenerated by genpy from gazebo_msgs/ODEPhysics.msg. Do not edit."""
import sys
python3 = True if sys.hexversion > 0x03000000 else False
import genpy
import struct


class ODEPhysics(genpy.Message):
  _md5sum = "667d56ddbd547918c32d1934503dc335"
  _type = "gazebo_msgs/ODEPhysics"
  _has_header = False #flag to mark the presence of a Header object
  _full_text = """bool auto_disable_bodies           # enable auto disabling of bodies, default false
uint32 sor_pgs_precon_iters        # preconditioning inner iterations when uisng projected Gauss Seidel
uint32 sor_pgs_iters               # inner iterations when uisng projected Gauss Seidel
float64 sor_pgs_w                  # relaxation parameter when using projected Gauss Seidel, 1 = no relaxation
float64 sor_pgs_rms_error_tol      # rms error tolerance before stopping inner iterations
float64 contact_surface_layer      # contact "dead-band" width
float64 contact_max_correcting_vel # contact maximum correction velocity
float64 cfm                        # global constraint force mixing
float64 erp                        # global error reduction parameter
uint32 max_contacts                # maximum contact joints between two geoms
"""
  __slots__ = ['auto_disable_bodies','sor_pgs_precon_iters','sor_pgs_iters','sor_pgs_w','sor_pgs_rms_error_tol','contact_surface_layer','contact_max_correcting_vel','cfm','erp','max_contacts']
  _slot_types = ['bool','uint32','uint32','float64','float64','float64','float64','float64','float64','uint32']

  def __init__(self, *args, **kwds):
    """
    Constructor. Any message fields that are implicitly/explicitly
    set to None will be assigned a default value. The recommend
    use is keyword arguments as this is more robust to future message
    changes.  You cannot mix in-order arguments and keyword arguments.

    The available fields are:
       auto_disable_bodies,sor_pgs_precon_iters,sor_pgs_iters,sor_pgs_w,sor_pgs_rms_error_tol,contact_surface_layer,contact_max_correcting_vel,cfm,erp,max_contacts

    :param args: complete set of field values, in .msg order
    :param kwds: use keyword arguments corresponding to message field names
    to set specific fields.
    """
    if args or kwds:
      super(ODEPhysics, self).__init__(*args, **kwds)
      #message fields cannot be None, assign default values for those that are
      if self.auto_disable_bodies is None:
        self.auto_disable_bodies = False
      if self.sor_pgs_precon_iters is None:
        self.sor_pgs_precon_iters = 0
      if self.sor_pgs_iters is None:
        self.sor_pgs_iters = 0
      if self.sor_pgs_w is None:
        self.sor_pgs_w = 0.
      if self.sor_pgs_rms_error_tol is None:
        self.sor_pgs_rms_error_tol = 0.
      if self.contact_surface_layer is None:
        self.contact_surface_layer = 0.
      if self.contact_max_correcting_vel is None:
        self.contact_max_correcting_vel = 0.
      if self.cfm is None:
        self.cfm = 0.
      if self.erp is None:
        self.erp = 0.
      if self.max_contacts is None:
        self.max_contacts = 0
    else:
      self.auto_disable_bodies = False
      self.sor_pgs_precon_iters = 0
      self.sor_pgs_iters = 0
      self.sor_pgs_w = 0.
      self.sor_pgs_rms_error_tol = 0.
      self.contact_surface_layer = 0.
      self.contact_max_correcting_vel = 0.
      self.cfm = 0.
      self.erp = 0.
      self.max_contacts = 0

  def _get_types(self):
    """
    internal API method
    """
    return self._slot_types

  def serialize(self, buff):
    """
    serialize message into buffer
    :param buff: buffer, ``StringIO``
    """
    try:
      _x = self
      buff.write(_get_struct_B2I6dI().pack(_x.auto_disable_bodies, _x.sor_pgs_precon_iters, _x.sor_pgs_iters, _x.sor_pgs_w, _x.sor_pgs_rms_error_tol, _x.contact_surface_layer, _x.contact_max_correcting_vel, _x.cfm, _x.erp, _x.max_contacts))
    except struct.error as se: self._check_types(struct.error("%s: '%s' when writing '%s'" % (type(se), str(se), str(locals().get('_x', self)))))
    except TypeError as te: self._check_types(ValueError("%s: '%s' when writing '%s'" % (type(te), str(te), str(locals().get('_x', self)))))

  def deserialize(self, str):
    """
    unpack serialized message in str into this message instance
    :param str: byte array of serialized message, ``str``
    """
    try:
      end = 0
      _x = self
      start = end
      end += 61
      (_x.auto_disable_bodies, _x.sor_pgs_precon_iters, _x.sor_pgs_iters, _x.sor_pgs_w, _x.sor_pgs_rms_error_tol, _x.contact_surface_layer, _x.contact_max_correcting_vel, _x.cfm, _x.erp, _x.max_contacts,) = _get_struct_B2I6dI().unpack(str[start:end])
      self.auto_disable_bodies = bool(self.auto_disable_bodies)
      return self
    except struct.error as e:
      raise genpy.DeserializationError(e) #most likely buffer underfill


  def serialize_numpy(self, buff, numpy):
    """
    serialize message with numpy array types into buffer
    :param buff: buffer, ``StringIO``
    :param numpy: numpy python module
    """
    try:
      _x = self
      buff.write(_get_struct_B2I6dI().pack(_x.auto_disable_bodies, _x.sor_pgs_precon_iters, _x.sor_pgs_iters, _x.sor_pgs_w, _x.sor_pgs_rms_error_tol, _x.contact_surface_layer, _x.contact_max_correcting_vel, _x.cfm, _x.erp, _x.max_contacts))
    except struct.error as se: self._check_types(struct.error("%s: '%s' when writing '%s'" % (type(se), str(se), str(locals().get('_x', self)))))
    except TypeError as te: self._check_types(ValueError("%s: '%s' when writing '%s'" % (type(te), str(te), str(locals().get('_x', self)))))

  def deserialize_numpy(self, str, numpy):
    """
    unpack serialized message in str into this message instance using numpy for array types
    :param str: byte array of serialized message, ``str``
    :param numpy: numpy python module
    """
    try:
      end = 0
      _x = self
      start = end
      end += 61
      (_x.auto_disable_bodies, _x.sor_pgs_precon_iters, _x.sor_pgs_iters, _x.sor_pgs_w, _x.sor_pgs_rms_error_tol, _x.contact_surface_layer, _x.contact_max_correcting_vel, _x.cfm, _x.erp, _x.max_contacts,) = _get_struct_B2I6dI().unpack(str[start:end])
      self.auto_disable_bodies = bool(self.auto_disable_bodies)
      return self
    except struct.error as e:
      raise genpy.DeserializationError(e) #most likely buffer underfill

_struct_I = genpy.struct_I
def _get_struct_I():
    global _struct_I
    return _struct_I
_struct_B2I6dI = None
def _get_struct_B2I6dI():
    global _struct_B2I6dI
    if _struct_B2I6dI is None:
        _struct_B2I6dI = struct.Struct("<B2I6dI")
    return _struct_B2I6dI
