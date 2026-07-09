; PRG header — load at $1201 (JSW-Tape layout)

basic_start = $1200

    *= basic_start - 1
    !word basic_start + 1
    !word basic_end
    !word $0a
    !byte $9e
    !text "4621"
    !byte 0
basic_end
    !word 0
