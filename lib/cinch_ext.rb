#!/usr/bin/env ruby
#encoding: UTF-8
module CinchExt
  CONTROL_CODES = {
    :bold => "\002",
    :underline => "\037",
    :reversed => "\026",
    :normal => "\017",
    :ctcp => "\001",
    :colour => "\003",
  }
end
