///|
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
      #|49.85% : contains-string
      #|56.2% : contains-complex-key
      #|60.550000000000004% : contains-array
      #|29.15% : contains-table
    ),
  )
}
