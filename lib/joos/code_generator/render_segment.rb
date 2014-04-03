
# Code to compile SSA Segments into x86 assembly

class Joos::CodeGenerator
  protected

  # Render a Segment into x86 assembly.
  # @param segment [Joos::SSA::Segment]
  # @return [Array<String>]
  def render_segment_x86 segment
    # TODO: method parameters
    @allocator = RegisterAllocator.new

    ['call __exception']
  end

  private
end
