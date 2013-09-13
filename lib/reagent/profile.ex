#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#                    Version 2, December 2004
#
#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#   TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION
#
#  0. You just DO WHAT THE FUCK YOU WANT TO.

defmodule Reagent.Profile do
  def start do
    :eprof.start
    :eprof.start_profiling [Process.self]
  end

  def stop do
    :eprof.stop_profiling()
    :eprof.log('procs.profile')
    :eprof.analyze(:procs)
    :eprof.log('total.profile')
    :eprof.analyze(:total)
  end
end
