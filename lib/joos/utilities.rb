require 'joos/version'

##
# Misc. utility methods used by the compiler.
module Joos::Utilities
  extend self

  ##
  # Figure out how many CPU cores are available on the host system
  #
  # Since figuring this value out will vary depending on the platform,
  # this method is not always dependable. It has been tested to work
  # on OS X and the Linux environment provided by the university.
  #
  # @example
  #
  #   Joos::Utilities.number_of_cpu_cores # => 8  # my laptop
  #   Joos::Utilities.number_of_cpu_cores # => 48 # a beast machine
  #
  # @return [Fixnum]
  def number_of_cpu_cores
    @cpus ||= (if system('which nproc')
                 `nproc`
               else
                 `sysctl hw.ncpu | awk '{print $2}'`
               end).to_i
  end

  def os
    `uname -s`.chomp
  end

  def darwin?
    os == 'Darwin'
  end

  def linux?
    os == 'Linux'
  end

end
