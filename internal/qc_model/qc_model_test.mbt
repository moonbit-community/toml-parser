// TODO: fix round-trip mismatch for exponent-like bare keys (e.g. "-2e-6492")

///|
#cfg(false)
test "quickcheck simple document roundtrip" {
  inspect(
    @qc.quick_check_silence(
      @qc.forall_shrink(
        simple_document_gen(),
        shrink_simple_document,
        roundtrip_property,
      ),
      max_success=2000,
      max_size=12,
    ),
    content=(
      #|+++ [2000/0/2000] Ok, passed!
      #|44.4% : contains-string
      #|52.55% : contains-complex-key
      #|33.15% : contains-negative-exponent-like-key
      #|36.7% : contains-datetime
      #|22.05% : contains-fractional-datetime
      #|21.05% : contains-datetime-array
      #|61% : contains-array
      #|29.15% : contains-table
    ),
  )
}
